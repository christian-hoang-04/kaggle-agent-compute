# Kaggle Smoke Runbook

This is the first validated reusable workflow for agent-controlled Kaggle compute.

## Preconditions

- Kaggle CLI is installed in the active Python environment.
- Christian is authenticated with Kaggle locally.
- Networked Kaggle CLI commands are allowed by the active agent environment.

Verify:

```powershell
python -m kaggle --version
python -m kaggle kernels list --mine
```

## Push And Run

```powershell
python -m kaggle kernels push -p D:\projects\personal\kaggle-agent-compute\execution\smoke-kernel -t 120
```

This pushes and runs:

```text
lehoangnam/kaggle-agent-compute-smoke
```

The kernel is private, CPU-only, TPU disabled, GPU disabled, and notebook internet disabled.

## Check Status

```powershell
python -m kaggle kernels status lehoangnam/kaggle-agent-compute-smoke
```

Expected successful terminal state:

```text
KernelWorkerStatus.COMPLETE
```

## Fetch Output

```powershell
python -m kaggle kernels output lehoangnam/kaggle-agent-compute-smoke -p D:\projects\personal\kaggle-agent-compute\execution\smoke-output -o
```

Expected local files:

- `agent_smoke_result.json`
- `kaggle-agent-compute-smoke.log`

## Safety Rule

Do not modify this runbook into a GPU or long-running workflow without recording a new discussion note first.
