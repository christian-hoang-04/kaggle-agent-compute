# 2026-06-28 GPU Autonomy Policy

## What Was Discussed

Christian clarified that agents do not need explicit approval before using Kaggle GPU. The intended use case involves frequent GPU work, and Christian wants agents to choose compute based on the workload rather than stopping for permission each time.

## Decision Made

Agents may use Kaggle GPU without asking Christian first when the workload reasonably needs GPU.

Default compute policy:

- Use CPU for lightweight checks, file validation, metadata operations, tiny smoke tests, and work that does not benefit meaningfully from acceleration.
- Use GPU when the task involves model training, inference, embedding generation, large tensor workloads, audio/model experiments, or any job where GPU materially changes feasibility or runtime.
- Use TPU only after a specific project need is identified, because TPU workflows usually require more deliberate framework and data-shape choices.

## Non-Negotiable Boundary

Agents must still respect Kaggle's terms, quotas, credential rules, and platform limits.

Do not design automation to bypass limits, evade enforcement, abuse multiple accounts, or hide resource usage. Multiple accounts, if used, should be handled as explicit credentials/resources under Christian's control and within Kaggle's allowed usage.

## Practical Rule For Future Agents

Before starting a remote run, decide and record:

- why CPU or GPU was selected
- expected runtime class: smoke, short, medium, or long
- input sources
- output artifacts to fetch
- kernel slug or run identifier

For quick experiments, this can be recorded in a run log under `execution/`. For meaningful workflow changes, record a discussion note.

## Next Actions

- Add GPU support to the next smoke workflow.
- Build a small GPU probe that checks accelerator availability and records device details.
- Keep CPU smoke as the cheapest health check.
