# Kaggle Auth Checklist

Use this before any remote compute work.

## Current State

- Kaggle CLI is installed.
- Local config directory exists at `C:\Users\THINKPAD\.kaggle`.
- Authentication is not configured yet.

## Manual Authentication Options

### Option 1: OAuth

Run:

```powershell
kaggle auth login
```

This should open a browser-based authorization flow and cache credentials locally.

### Option 2: API Token

1. Open Kaggle account settings.
2. Generate a new API token.
3. Store it using a Kaggle-supported local credential method.

Do not place the token anywhere inside this repo.

## Verification

After authentication, run:

```powershell
python -m kaggle kernels list --mine
```

Expected result: a list of Christian's Kaggle notebooks/kernels, or an empty authenticated list.

If it still says authentication is required, the credential was not picked up by the CLI.
