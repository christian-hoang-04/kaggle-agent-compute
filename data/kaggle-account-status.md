# Kaggle Account Status

This file family stores non-secret per-account status snapshots.

## Files

- `kaggle-account-status.example.json`: safe example structure.
- `kaggle-account-status.local.json`: live local snapshot written by `execution/scripts/Update-KaggleAccountStatus.ps1`.

## Purpose

Use the status snapshot to keep operational account state separate from the account registry:

- notebook quota observations
- last verified username
- credential file presence
- manually observed Benchmarks spend values

The registry answers "which accounts exist?" The status file answers "what is their current usable state?"

## Current Boundary

- Notebook GPU/TPU quota can be fetched automatically through the Kaggle API from an authenticated profile.
- Benchmarks dollar/spend state should currently be treated as manually observed unless Kaggle exposes a stable supported API for it.
- Do not store secrets here.
