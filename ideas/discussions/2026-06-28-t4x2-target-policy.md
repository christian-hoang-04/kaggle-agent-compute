# 2026-06-28 T4x2 Target Policy

## What Was Discussed

Christian clarified that experiments should use Kaggle T4 x2. Other accelerator configurations do not need to be considered for the main experiment workflow.

## Decision Made

Target accelerator for experiments:

```text
T4 x2
```

Agents should use T4 x2 for experiment kernels whenever possible.

## Practical Rule

- CPU is still fine for small smoke checks, metadata checks, credential checks, and cheap validation.
- T4 x2 is the target for real experiments.
- Other GPU shapes, such as the P100 observed in the first probe, should not be treated as acceptable for the main experiment path.
- If Kaggle allocates a non-T4 shape, record it and avoid using that run as evidence for real experiment compatibility.

## Implication

The GPU probe remains useful, but its acceptance criteria should shift:

- old: any working CUDA GPU is useful
- new: T4 x2 is the desired experiment shape

Future scripts should make the requested machine shape explicit if the Kaggle CLI/API supports it reliably.
