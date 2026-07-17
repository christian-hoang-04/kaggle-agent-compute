# 2026-06-29 One-Machine Multi-Account Limitations

Audience: internal/personal

## Summary

This session reviewed the current `kaggle-agent-compute` repo and the installed Kaggle CLI to clarify what one Windows machine can realistically do with multiple legitimate Kaggle accounts.

The existing repo already supports safe local credential profile storage and manual profile switching. The main unresolved limitation is that the current activation flow copies one selected profile into `%USERPROFILE%\.kaggle`, which makes the active account global for that Windows user session.

## Decisions

- Treat the existing profile-switching scripts as valid for sequential account use.
- Do not treat the current `%USERPROFILE%\.kaggle` copy-based flow as safe for concurrent multi-account runs.
- Prefer per-process credential isolation using `KAGGLE_CONFIG_DIR` for any future parallel control-plane work.
- Keep credentials outside the repo and continue storing only non-secret aliases and account metadata in project files.

## Findings

- The repo already documents the non-evasion boundary in `ideas/FOUNDATION.md` and `ideas/discussions/2026-06-28-multi-account-credential-policy.md`.
- `execution/scripts/Use-KaggleProfile.ps1` activates a profile by copying credential files into `%USERPROFILE%\.kaggle`, so two concurrent jobs that both rely on the default config path can race and overwrite each other's active identity.
- The installed Kaggle client supports `KAGGLE_CONFIG_DIR`, which means separate processes can point at separate credential directories without mutating the shared default config directory.
- The active local Kaggle CLI account on this machine authenticated successfully as `lehoangnam` and listed recent kernels.
- `%USERPROFILE%\.kaggle-profiles` currently contains only one saved profile: `primary`.
- The installed Kaggle CLI exposes a `quota` command, but the current local client version fails when parsing the returned accelerator quota response. The failure is in local client parsing, not in basic authentication.

## Open Questions

- Should future profile-aware commands wrap every Kaggle CLI invocation with an explicit `KAGGLE_CONFIG_DIR` instead of copying files into `%USERPROFILE%\.kaggle`?
- Should the project add a small launcher that maps account aliases to config directories and job logs for safer parallel submission/monitoring?
- How much quota and accelerator information should be recorded locally if the CLI quota command remains broken in the currently installed package version?

## Next Actions

- Add a profile-aware execution path that uses `KAGGLE_CONFIG_DIR` per process.
- Keep the copy-based activation script for manual compatibility, but treat it as sequential-only.
- Verify current Kaggle platform-side notebook/GPU quota wording from official docs before turning any quota assumptions into repo policy or automation.
