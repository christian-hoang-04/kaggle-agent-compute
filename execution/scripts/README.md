# Scripts

PowerShell helpers for local Kaggle credential profile management.

These scripts copy credential files between:

- active Kaggle CLI directory: `%USERPROFILE%\.kaggle`
- profile storage directory: `%USERPROFILE%\.kaggle-profiles\<alias>`

They do not store secrets in this repo.

## Save Current Login As A Profile

After Christian manually logs into one Kaggle account:

```powershell
.\Save-KaggleProfile.ps1 -Alias primary
```

## Activate A Saved Profile

```powershell
.\Use-KaggleProfile.ps1 -Alias primary
python -m kaggle kernels list --mine
```

The activation script backs up existing active Kaggle credential files before replacing them.

## List Saved Profiles

```powershell
.\Get-KaggleProfiles.ps1
```

This shows the saved aliases, their profile directories, and whether a saved profile currently matches the active `%USERPROFILE%\.kaggle` credentials.

## Run Kaggle CLI With An Isolated Profile

```powershell
.\Invoke-KaggleWithProfile.ps1 -Alias primary kernels list --mine
```

This is the safer path for multi-account work on one machine.
It sets `KAGGLE_CONFIG_DIR` only for the current process, so separate terminals or background jobs can use different Kaggle accounts without overwriting `%USERPROFILE%\.kaggle`.

## Capture Account Status And Notebook Quota

```powershell
.\Update-KaggleAccountStatus.ps1
Get-Content ..\..\data\kaggle-account-status.local.json
```

This writes a local status snapshot with:

- observed Kaggle username
- notebook GPU/TPU quota from the Kaggle API
- placeholder/manual Benchmarks spend values

## Record Benchmarks Spend Manually

```powershell
.\Set-KaggleBenchmarkSpendObservation.ps1 -Alias primary -RemainingMonthlyUsd 76 -RemainingDailyUsd 8.5 -Notes "Observed in Benchmarks UI"
```

Use this until Kaggle exposes a stable supported API for Benchmarks spend/quota.

To clear a mistaken manual Benchmarks observation:

```powershell
.\Set-KaggleBenchmarkSpendObservation.ps1 -Alias primary -Clear
```

## Submit A Kernel Job

```powershell
.\Submit-KaggleKernelJob.ps1 -Alias primary -KernelPath D:\projects\personal\kaggle-agent-compute\execution\smoke-kernel -TimeoutSeconds 120
```

This pushes the kernel using the selected profile and appends a submit event to `data\kaggle-job-history.local.jsonl`.

## Check Kernel Status

```powershell
.\Get-KaggleKernelJobStatus.ps1 -Alias primary -KernelPath D:\projects\personal\kaggle-agent-compute\execution\smoke-kernel
```

To also capture the current log stream snapshot:

```powershell
.\Get-KaggleKernelJobStatus.ps1 -Alias primary -KernelPath D:\projects\personal\kaggle-agent-compute\execution\smoke-kernel -IncludeLogs
```

## Fetch Kernel Output

```powershell
.\Get-KaggleKernelJobOutput.ps1 -Alias primary -KernelPath D:\projects\personal\kaggle-agent-compute\execution\smoke-kernel -Force
```

If `-OutputPath` is omitted, the script writes into:

```text
execution\run-output\<alias>\<kernel-slug>\<timestamp>\
```

## Review Local Job History

```powershell
.\Get-KaggleJobHistory.ps1
.\Get-KaggleJobHistory.ps1 -Alias primary
```

## Build PyTorch MNIST Baseline Kernels

```powershell
.\Build-PyTorchMnistBaselines.ps1
```

This regenerates the CPU and GPU `run_baseline.py` files from `../templates/pytorch_mnist_baseline.py.tpl`.

The generated scripts are committed as self-contained Kaggle kernel entrypoints. Do not replace them with imports from a shared module unless the Kaggle packaging flow is changed to upload and import multiple files reliably.
