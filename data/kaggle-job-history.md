# Kaggle Job History

This file family stores local control-plane event history for Kaggle kernel jobs.

## Files

- `kaggle-job-history.local.jsonl`: append-only local event ledger written by the orchestration scripts.

## Event Types

- `submit`
- `status`
- `fetch_output`

## Purpose

Use the ledger to answer:

- which alias launched a kernel
- which local path was submitted
- when status was checked
- where output was downloaded
- what the last CLI response looked like

This is local operational evidence, not a source of truth for Kaggle itself.

Do not store secrets here.
