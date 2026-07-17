# 2026-06-28 Multi-Account Credential Policy

## What Was Discussed

Christian is considering how agents should manage multiple Kaggle accounts as remote compute resources. One idea was storing account emails and passwords in a sheet so agents can log in and manage resources automatically.

## Recommendation

Do not store Kaggle emails and passwords in a sheet.

A spreadsheet of reusable passwords is too fragile:

- it is easy to leak or accidentally commit
- it encourages browser-login automation instead of API-based automation
- it makes account recovery and rotation harder
- it may conflict with platform security expectations

## Preferred Direction

Use official Kaggle authentication per account, then let agents use cached credentials or explicit API/OAuth tokens.

Preferred account model:

- one local credential profile per Kaggle account
- credentials stored outside the repo
- project stores only non-secret account aliases, capability notes, and usage records
- agents select a profile based on workload needs
- agents never print, commit, or copy secrets into project files

## Acceptable Local Metadata

This project may store non-secret metadata such as:

- account alias, not password
- Kaggle username if Christian allows it
- available resource type: CPU, GPU, TPU
- intended use: smoke tests, model training, dataset work, etc.
- notes about quota state if manually observed
- last successful run identifier

## Boundary

Agents must not automate account use in a way designed to bypass Kaggle limits, evade enforcement, or violate Kaggle rules.

Multiple accounts should be treated as Christian-controlled credentials/resources, not as a quota-evasion mechanism.

## Next Actions

- Design a local account registry that contains no secrets.
- Decide where secrets should live on this Windows machine.
- Build profile-aware Kaggle commands after the credential storage approach is settled.
