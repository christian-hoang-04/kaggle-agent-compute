# 2026-06-28 PyTorch MNIST Baseline

## What Was Done

Cloned a small real GitHub repo and tested it as Kaggle script kernels in CPU and GPU modes.

Source repo:

```text
https://github.com/pytorch/examples
```

Example used:

```text
mnist
```

Local clone:

```text
execution/external/pytorch-examples
```

Both wrappers use Kaggle script kernels, not notebooks. This proves basecode can be packaged as scripts.

## Kernels Created

CPU:

```text
lehoangnam/kaggle-agent-baseline-pytorch-mnist-cpu
```

GPU:

```text
lehoangnam/kaggle-agent-baseline-pytorch-mnist-gpu
```

## CPU Result

CPU run completed successfully.

Output:

```text
execution/baseline-pytorch-mnist-output/cpu/baseline_result_cpu.json
```

Key result:

```json
{
  "status": "ok",
  "mode": "cpu",
  "duration_seconds": 6.919,
  "device": "cpu",
  "train_batches": 5,
  "test_seen": 2000,
  "test_accuracy": 0.428
}
```

## Initial GPU Failure

The first GPU run used generic:

```powershell
--accelerator gpu
```

Kaggle allocated:

```text
Tesla P100-PCIE-16GB
```

The default Kaggle PyTorch build could see CUDA, but failed at execution time because P100 compute capability `sm_60` is unsupported by the installed PyTorch build.

Critical error:

```text
torch.AcceleratorError: CUDA error: no kernel image is available for execution on the device
```

## Fix

Inspected the installed Kaggle SDK and found the documented T4 machine-shape value:

```text
NvidiaTeslaT4
```

Updated GPU metadata:

```json
{
  "enable_gpu": "false",
  "machine_shape": "NvidiaTeslaT4"
}
```

Then pushed the GPU kernels without `--accelerator gpu`, so the metadata controlled machine selection.

## Fixed GPU Result

T4-requested GPU run completed successfully.

Output:

```text
execution/baseline-pytorch-mnist-output/gpu/baseline_result_gpu.json
```

Key result:

```json
{
  "status": "ok",
  "mode": "gpu",
  "duration_seconds": 4.513,
  "device": "cuda",
  "torch": {
    "version": "2.10.0+cu128",
    "cuda_available": true,
    "cuda_version": "12.8",
    "device_count": 2,
    "devices": ["Tesla T4", "Tesla T4"]
  },
  "train_batches": 5,
  "test_seen": 2000,
  "test_accuracy": 0.577
}
```

## Decision

For experiments, generic `--accelerator gpu` is not acceptable because it can allocate P100.

Use:

```json
"machine_shape": "NvidiaTeslaT4"
```

and verify that two Tesla T4 devices are present.

## Next Actions

- Use `machine_shape: NvidiaTeslaT4` in future GPU experiment metadata.
- Avoid `--accelerator gpu` for experiment runs unless any GPU is acceptable.
- Add a reusable T4x2 script-kernel template.
