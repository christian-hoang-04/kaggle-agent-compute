# 2026-06-28 Review, Reorganize, Validation

## What Was Requested

Christian asked to review and test everything again, then review and reorganize the code.

## Review Findings

The CPU and GPU PyTorch MNIST baselines duplicated almost all implementation code.

However, Kaggle script kernels submit the configured `code_file` as the script body, so a normal shared local Python module would not be safe unless the upload/import packaging flow is changed. The safer reorganization is source generation:

- keep a shared template as the source of truth
- generate self-contained CPU/GPU Kaggle script files from it

## Reorganization Done

Added:

```text
execution/templates/pytorch_mnist_baseline.py.tpl
execution/scripts/Build-PyTorchMnistBaselines.ps1
```

Regenerated:

```text
execution/baseline-pytorch-mnist-cpu/run_baseline.py
execution/baseline-pytorch-mnist-gpu/run_baseline.py
```

The GPU baseline now:

- validates that the allocated accelerator is T4 x2
- exits with `wrong_accelerator` if the devices are not exactly two Tesla T4s
- uses PyTorch `DataParallel` when both T4s are present
- writes accelerator validation details into the JSON result

## Regression Found And Fixed

The first version of `Build-PyTorchMnistBaselines.ps1` used:

```powershell
Set-Content -Encoding utf8
```

On this Windows PowerShell environment, that wrote a UTF-8 BOM. Kaggle then failed both generated Python scripts with:

```text
SyntaxError: invalid character '»' (U+00BB)
```

Fixed the generator by writing UTF-8 without BOM via:

```powershell
[System.Text.UTF8Encoding]($false)
```

Verified the generated Python files start with:

```text
66 72 6F
```

which is `fro`, not a BOM.

## Local Validation

Passed:

- Python compile check for generated CPU/GPU baseline scripts
- PowerShell parser check for `Build-PyTorchMnistBaselines.ps1`
- PowerShell parser check for profile save/switch scripts
- generator rerun
- compile check after regeneration

## Remote Kaggle Validation

Smoke kernel:

```text
lehoangnam/kaggle-agent-compute-smoke
```

Result:

```json
{
  "status": "ok",
  "message": "Kaggle remote smoke test completed."
}
```

CPU MNIST baseline:

```text
lehoangnam/kaggle-agent-baseline-pytorch-mnist-cpu
```

Result:

```json
{
  "status": "ok",
  "mode": "cpu",
  "duration_seconds": 6.622,
  "use_data_parallel": false,
  "test_accuracy": 0.428
}
```

GPU MNIST baseline:

```text
lehoangnam/kaggle-agent-baseline-pytorch-mnist-gpu
```

Result:

```json
{
  "status": "ok",
  "mode": "gpu",
  "duration_seconds": 11.133,
  "device": "cuda",
  "use_data_parallel": true,
  "torch": {
    "cuda_available": true,
    "device_count": 2,
    "devices": ["Tesla T4", "Tesla T4"]
  },
  "accelerator_check": {
    "ok": true
  },
  "test_accuracy": 0.532
}
```

## no-mistakes Status

The full `no-mistakes` gate could not run because:

- `no-mistakes` is not available on PATH in this shell
- `D:\projects\personal\kaggle-agent-compute` is not a git repository

Used direct local checks and remote Kaggle validation instead.

## Remaining Known Issue

Kaggle CLI output downloads still sometimes print a Windows `charmap` error when progress-bar characters are emitted.

The JSON artifacts download successfully despite that console-printing issue.
