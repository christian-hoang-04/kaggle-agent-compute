from datetime import datetime, timezone
from pathlib import Path
import json
import platform
import subprocess
import sys
import time

import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
from torch.optim.lr_scheduler import StepLR
from torchvision import datasets, transforms


RUN_MODE = "__RUN_MODE__"
RESULT_FILE = "__RESULT_FILE__"
REQUIRE_T4X2 = __REQUIRE_T4X2__


class Net(nn.Module):
    def __init__(self):
        super().__init__()
        self.conv1 = nn.Conv2d(1, 32, 3, 1)
        self.conv2 = nn.Conv2d(32, 64, 3, 1)
        self.dropout1 = nn.Dropout(0.25)
        self.dropout2 = nn.Dropout(0.5)
        self.fc1 = nn.Linear(9216, 128)
        self.fc2 = nn.Linear(128, 10)

    def forward(self, x):
        x = self.conv1(x)
        x = F.relu(x)
        x = self.conv2(x)
        x = F.relu(x)
        x = F.max_pool2d(x, 2)
        x = self.dropout1(x)
        x = torch.flatten(x, 1)
        x = self.fc1(x)
        x = F.relu(x)
        x = self.dropout2(x)
        x = self.fc2(x)
        return F.log_softmax(x, dim=1)


def run_command(args):
    try:
        completed = subprocess.run(args, capture_output=True, text=True, timeout=30)
        return {
            "ok": completed.returncode == 0,
            "returncode": completed.returncode,
            "stdout": completed.stdout.strip(),
            "stderr": completed.stderr.strip(),
        }
    except Exception as exc:
        return {"ok": False, "error": repr(exc)}


def collect_torch_info():
    device_names = []
    if torch.cuda.is_available():
        device_names = [torch.cuda.get_device_name(i) for i in range(torch.cuda.device_count())]

    return {
        "version": torch.__version__,
        "cuda_available": torch.cuda.is_available(),
        "cuda_version": torch.version.cuda,
        "device_count": torch.cuda.device_count(),
        "devices": device_names,
    }


def validate_accelerator(torch_info):
    if not REQUIRE_T4X2:
        return {"ok": True, "reason": "not_required"}

    devices = torch_info["devices"]
    ok = torch_info["cuda_available"] and len(devices) == 2 and all(name == "Tesla T4" for name in devices)
    return {
        "ok": ok,
        "expected": ["Tesla T4", "Tesla T4"],
        "actual": devices,
    }


def train_and_eval(device, use_data_parallel):
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,)),
    ])
    train_dataset = datasets.MNIST("../data", train=True, download=True, transform=transform)
    test_dataset = datasets.MNIST("../data", train=False, transform=transform)

    uses_cuda = device.type == "cuda"
    train_loader = torch.utils.data.DataLoader(
        train_dataset,
        batch_size=64,
        shuffle=True,
        num_workers=1 if uses_cuda else 0,
        pin_memory=uses_cuda,
    )
    test_loader = torch.utils.data.DataLoader(
        test_dataset,
        batch_size=1000,
        num_workers=1 if uses_cuda else 0,
        pin_memory=uses_cuda,
    )

    model = Net().to(device)
    if use_data_parallel:
        model = nn.DataParallel(model)

    optimizer = optim.Adadelta(model.parameters(), lr=1.0)
    scheduler = StepLR(optimizer, step_size=1, gamma=0.7)

    model.train()
    train_losses = []
    for batch_idx, (data, target) in enumerate(train_loader):
        data, target = data.to(device), target.to(device)
        optimizer.zero_grad()
        output = model(data)
        loss = F.nll_loss(output, target)
        loss.backward()
        optimizer.step()
        train_losses.append(float(loss.item()))
        if batch_idx >= 4:
            break
    scheduler.step()

    model.eval()
    correct = 0
    seen = 0
    test_loss = 0.0
    with torch.no_grad():
        for batch_idx, (data, target) in enumerate(test_loader):
            data, target = data.to(device), target.to(device)
            output = model(data)
            test_loss += F.nll_loss(output, target, reduction="sum").item()
            pred = output.argmax(dim=1, keepdim=True)
            correct += pred.eq(target.view_as(pred)).sum().item()
            seen += len(data)
            if batch_idx >= 1:
                break

    return {
        "train_batches": len(train_losses),
        "train_losses": train_losses,
        "test_seen": seen,
        "test_loss": test_loss / seen if seen else None,
        "test_correct": correct,
        "test_accuracy": correct / seen if seen else None,
    }


def main():
    started = time.perf_counter()
    torch.manual_seed(1)

    torch_info = collect_torch_info()
    accelerator_check = validate_accelerator(torch_info)
    if REQUIRE_T4X2 and not accelerator_check["ok"]:
        result = {
            "status": "wrong_accelerator",
            "mode": RUN_MODE,
            "utc_time": datetime.now(timezone.utc).isoformat(),
            "torch": torch_info,
            "accelerator_check": accelerator_check,
            "nvidia_smi": run_command(["nvidia-smi"]),
        }
        Path(RESULT_FILE).write_text(json.dumps(result, indent=2), encoding="utf-8")
        print(json.dumps(result, indent=2))
        raise SystemExit(2)

    device = torch.device("cuda" if RUN_MODE == "gpu" and torch.cuda.is_available() else "cpu")
    use_data_parallel = device.type == "cuda" and torch.cuda.device_count() > 1
    metrics = train_and_eval(device, use_data_parallel)
    effective_mode = "gpu" if RUN_MODE == "gpu" and device.type == "cuda" else device.type

    result = {
        "status": "ok",
        "mode": effective_mode if effective_mode == RUN_MODE else f"{RUN_MODE}_requested_but_{effective_mode}_used",
        "source_repo": "https://github.com/pytorch/examples",
        "source_example": "mnist",
        "utc_time": datetime.now(timezone.utc).isoformat(),
        "duration_seconds": round(time.perf_counter() - started, 3),
        "device": str(device),
        "use_data_parallel": use_data_parallel,
        "python": sys.version,
        "platform": platform.platform(),
        "torch": torch_info,
        "accelerator_check": accelerator_check,
        "nvidia_smi": run_command(["nvidia-smi"]),
        **metrics,
    }
    Path(RESULT_FILE).write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
