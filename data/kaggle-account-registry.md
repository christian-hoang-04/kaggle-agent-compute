# Kaggle Account Registry

The account registry is non-secret project metadata.

Use it to track which Kaggle accounts exist and what they are meant for. Do not store passwords, tokens, OAuth blobs, cookies, recovery codes, or private account notes here.

## Files

- `kaggle-account-registry.example.json`: safe example format.
- `kaggle-account-registry.local.json`: optional local working copy. This should stay uncommitted if the project becomes a git repo.

## Secret Location

Kaggle credential profiles should live outside this repo:

```text
%USERPROFILE%\.kaggle-profiles\
  primary\
    credentials.json
  account-two\
    credentials.json
```

The active Kaggle CLI credential directory remains:

```text
%USERPROFILE%\.kaggle\
```

## Profile Rule

Agents may switch between already-authenticated profiles, but should not handle passwords.

Christian should authenticate each account manually once, then save that active credential state into a named profile using the scripts in `execution/scripts/`.
