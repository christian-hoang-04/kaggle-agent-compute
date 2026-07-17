# 2026-06-29 Kernel Orchestration Layer

Audience: internal/personal

## Summary

Built the next control-plane layer on top of profile isolation:

- alias-aware kernel submit
- alias-aware kernel status
- alias-aware kernel output fetch
- append-only local job history

This turns the repo from credential helpers into a usable multi-account Kaggle kernel workflow.

## Decisions

- Keep orchestration scoped to Kaggle kernels first, because that matches the current validated notebook/script workflow and Kaggle CLI surface already in use here.
- Require an explicit account alias for orchestration commands.
- Allow either `-KernelPath` or `-KernelRef` for status/fetch commands.
- Keep a local append-only JSONL ledger instead of trying to infer all history from Kaggle later.

## What Was Implemented

- `execution/scripts/Submit-KaggleKernelJob.ps1`
  Submits a kernel from a local folder with an explicit account alias and records the result locally.
- `execution/scripts/Get-KaggleKernelJobStatus.ps1`
  Checks kernel status and can optionally capture the current logs snapshot.
- `execution/scripts/Get-KaggleKernelJobOutput.ps1`
  Downloads output files for a kernel using an explicit account alias.
- `execution/scripts/Get-KaggleJobHistory.ps1`
  Reads the local append-only ledger for recent submit/status/fetch events.
- `data/kaggle-job-history.md`
  Documents the local job-history file family.

## Validation

- `Submit-KaggleKernelJob.ps1` succeeded in `-DryRun` mode against `execution/smoke-kernel`.
- `Get-KaggleKernelJobStatus.ps1 -Alias primary -KernelPath execution/smoke-kernel` returned `KernelWorkerStatus.COMPLETE`.
- `Get-KaggleKernelJobOutput.ps1 -Alias primary -KernelPath execution/smoke-kernel` downloaded the expected smoke output successfully.
- `Get-KaggleJobHistory.ps1` read the locally recorded events successfully.
- `Update-KaggleAccountStatus.ps1 -Alias primary` produced a live local account snapshot with notebook quota data.
- The current `primary` snapshot recorded:
  - GPU: `0.68h` used, `29.32h` remaining, `30.0h` total
  - TPU: `0.0h` used, `20.0h` remaining, `20.0h` total
  - refresh time: `2026-07-04T00:00:00`

## Current Result

The project now has a working phase-2 control plane for Kaggle kernel operations on one machine:

- profile isolation per process using `KAGGLE_CONFIG_DIR`
- alias-aware kernel submit/status/fetch commands
- automatic notebook quota snapshotting
- manual Benchmarks spend tracking
- local append-only job history

The remaining unvalidated part is true parallel multi-account use with more than one saved profile. The current machine still only has one saved profile alias: `primary`.

## Open Questions

- Whether submit should later support automatic account selection based on quota state.
- Whether output fetch should also record downloaded file manifests, not just destination directories and CLI output.
- Whether a future orchestration layer should group status/fetch operations by benchmark/test campaign instead of only by kernel ref.

## Next Actions

- Save more Kaggle accounts into `%USERPROFILE%\.kaggle-profiles`.
- Create `data/kaggle-account-registry.local.json` when multiple aliases exist.
- Run a true multi-account smoke test with at least two saved aliases to confirm simultaneous control-plane isolation in practice.
