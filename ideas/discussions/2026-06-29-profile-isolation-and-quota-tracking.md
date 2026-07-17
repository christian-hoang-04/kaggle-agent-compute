# 2026-06-29 Profile Isolation And Quota Tracking

Audience: internal/personal

## Summary

Implemented the first profile-aware control-plane layer for `kaggle-agent-compute`.

The repo now supports two distinct operating modes:

- sequential profile activation through `%USERPROFILE%\.kaggle`
- per-process isolated Kaggle CLI execution through `KAGGLE_CONFIG_DIR`

It also now has a local account status snapshot that records notebook quota automatically and Benchmarks spend manually.

## Decisions

- Keep `Use-KaggleProfile.ps1` as the compatibility path for manual sequential switching.
- Add a new isolated launcher instead of changing the old activation script in place.
- Treat notebook quota and Benchmarks spend as separate account-state dimensions.
- Work around the current Kaggle SDK quota parsing bug locally instead of waiting on an upstream fix.

## What Was Implemented

- `execution/scripts/KaggleProfileHelpers.psm1`
  Shared helpers for registry loading, profile resolution, and status-file reads/writes.
- `execution/scripts/Invoke-KaggleWithProfile.ps1`
  Runs Kaggle CLI commands against a selected saved profile by setting `KAGGLE_CONFIG_DIR` for that process only.
- `execution/scripts/Get-KaggleProfiles.ps1`
  Lists saved aliases, profile directories, and whether a saved profile matches the active `%USERPROFILE%\.kaggle` credentials.
- `execution/scripts/kaggle_profile_runtime.py`
  Python runtime helper that authenticates with a selected config dir and captures notebook quota.
- `execution/scripts/Update-KaggleAccountStatus.ps1`
  Writes `data/kaggle-account-status.local.json` with observed username, credential presence, and notebook GPU/TPU quota.
- `execution/scripts/Set-KaggleBenchmarkSpendObservation.ps1`
  Stores manually observed Benchmarks dollar values in the local status file and supports clearing mistaken observations.
- `data/kaggle-account-status.md`
  Documents the status snapshot format and boundary.

## Validation

- `Get-KaggleProfiles.ps1` ran successfully against the current machine state.
- `Invoke-KaggleWithProfile.ps1 -Alias primary kernels list --mine --page-size 2` ran successfully.
- `Update-KaggleAccountStatus.ps1` produced a live local status snapshot for `primary`.
- The snapshot captured notebook quota successfully after applying the local timedelta parser patch:
  - GPU: `0.68h` used, `29.32h` remaining, `30.0h` total
  - TPU: `0.0h` used, `20.0h` remaining, `20.0h` total
  - refresh time: `2026-07-04T00:00:00`

## Open Questions

- Whether the registry should grow a local committed-or-uncommitted working copy once more than one profile exists.
- Whether a future `submit/status/fetch` orchestration layer should always require an alias rather than ever defaulting to the active `%USERPROFILE%\.kaggle`.
- Whether Benchmarks spend can be fetched through a supported API later, instead of being manually observed.

## Next Actions

- Save additional Kaggle accounts into `%USERPROFILE%\.kaggle-profiles\<alias>`.
- Optionally create `data/kaggle-account-registry.local.json` with aliases and intended-use metadata once there is more than one account.
- Use `Invoke-KaggleWithProfile.ps1` for any multi-account or parallel work on the same machine.
