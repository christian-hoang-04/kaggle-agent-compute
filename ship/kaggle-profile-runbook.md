# Kaggle Profile Runbook

This runbook is for managing multiple already-authenticated Kaggle accounts without storing passwords in project files.

## Add A New Account

1. Log out or switch account in the browser if needed.
2. Run Kaggle OAuth login manually:

```powershell
kaggle auth login
```

3. Save the active credential files as a profile:

```powershell
cd D:\projects\personal\kaggle-agent-compute\execution\scripts
.\Save-KaggleProfile.ps1 -Alias account-name
```

Use a simple alias such as `primary`, `gpu-a`, or `dataset-a`.

## Use An Existing Account

```powershell
cd D:\projects\personal\kaggle-agent-compute\execution\scripts
.\Use-KaggleProfile.ps1 -Alias account-name
python -m kaggle kernels list --mine
```

## Registry

Copy the example registry if a local working registry is useful:

```powershell
Copy-Item D:\projects\personal\kaggle-agent-compute\data\kaggle-account-registry.example.json D:\projects\personal\kaggle-agent-compute\data\kaggle-account-registry.local.json
```

Only store non-secret metadata in the registry.

## Compute Selection

Agents may choose CPU or GPU based on workload needs:

- CPU: smoke tests, file checks, metadata probes, tiny scripts.
- GPU: model training, model inference, embeddings, audio/model experiments, tensor-heavy work.

Do not use these profiles to bypass Kaggle limits or platform rules.
