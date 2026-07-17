# 2026-06-28 Profile Management Scaffold

## What Was Done

Added the first local profile-management scaffold for using multiple Kaggle accounts without putting passwords in a spreadsheet or project file.

## Files Added

- `data/kaggle-account-registry.example.json`
- `data/kaggle-account-registry.md`
- `execution/scripts/Save-KaggleProfile.ps1`
- `execution/scripts/Use-KaggleProfile.ps1`
- `execution/scripts/README.md`
- `ship/kaggle-profile-runbook.md`

## Design

Secrets stay outside the repo under:

```text
%USERPROFILE%\.kaggle-profiles\<alias>\
```

The active Kaggle CLI directory remains:

```text
%USERPROFILE%\.kaggle\
```

Agents can switch between saved profiles by copying credential files from a profile into the active Kaggle CLI directory. The switch script backs up the previous active credentials first.

## Supported Credential Files

The scripts currently recognize:

- `credentials.json`
- `access_token`
- `kaggle.json`

This covers the OAuth credential file observed on Christian's machine and the token-file styles mentioned by the Kaggle CLI.

## Next Actions

- Add the next Kaggle account by logging in manually and saving it under a new alias.
- Add a GPU probe kernel after profile management is confirmed.

## Verification

After the scaffold was created:

- saved the current authenticated Kaggle login as `primary`
- stored the profile at `%USERPROFILE%\.kaggle-profiles\primary`
- confirmed the profile contains `credentials.json`
- activated `primary` using `Use-KaggleProfile.ps1`
- created an automatic backup under `%USERPROFILE%\.kaggle-profile-backups`
- verified the active profile with `python -m kaggle kernels list --mine`

The verified account is visible as Kaggle user `lehoangnam`.
