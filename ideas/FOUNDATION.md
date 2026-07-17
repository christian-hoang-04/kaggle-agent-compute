# Foundation: Kaggle Agent Compute

## Purpose

Build a practical way for Christian's coding/research agents to use Kaggle as remote compute when the local machine is too small for experiments.

The project should discover the safest useful workflow first, then turn it into reusable tooling only after the manual path is understood.

## Why It Matters

Christian's local machine has limited compute. Kaggle can provide notebook environments with CPUs, GPUs, TPUs, datasets, persistent notebooks, and public/private kernel workflows. If agents can prepare, launch, monitor, and retrieve Kaggle runs reliably, Christian can run heavier experiments without depending on a larger local workstation.

## Non-Negotiables

- Respect Kaggle's terms, quotas, credential rules, and competition/dataset policies. Do not design automation that bypasses platform limits.
- Treat Kaggle API credentials as secrets. Never commit tokens, cookies, account identifiers beyond what Christian explicitly allows, or downloaded private data.
- Prefer reproducible, reviewable runs: every remote execution should have a clear input manifest, notebook/script version, environment assumptions, and saved outputs.
- Keep the local machine as the control plane and Kaggle as the compute plane.
- Start with a small smoke workflow before attempting large jobs.
- Agents may choose CPU or GPU based on workload needs without asking Christian each time, but must still respect Kaggle's terms, quotas, and platform limits.

## Current Direction

- Investigate the Kaggle API and notebook workflow as the first integration surface.
- Define a minimal agent workflow: prepare job locally, upload/sync to Kaggle, run remotely, monitor status, fetch outputs, record evidence.
- Keep execution experiments lightweight until the platform constraints are known.

## Main Process

- Use `ideas/discussions/` for design decisions, platform findings, credential assumptions, and workflow tradeoffs.
- Use `data/` for small manifests, dataset source notes, local metadata, and inspection summaries. Do not store large downloaded datasets unless Christian explicitly chooses that.
- Use `execution/` for probes, scripts, notebook templates, API experiments, and local control-plane code.
- Keep runnable entrypoints thin: `probe`, `smoke`, `submit`, `status`, `fetch` are likely boundaries, but not settled yet.
- Before any large Kaggle run, prove a tiny end-to-end smoke run: create/upload job, execute, retrieve a small artifact, and record logs.
- Preserve enough evidence to debug agent behavior later: commands issued, Kaggle resource identifiers, notebook version, output manifest, logs, and failure reasons.
- Promote a minimal validated workflow into `ship/` only when it can be reused safely by future agents.
- Record structure changes in dated discussion records.

## Constraints

- Kaggle compute is quota-bound and policy-bound; the workflow must accept limits rather than trying to hide them.
- Network access and credentials may vary by agent environment.
- Some Kaggle resources are public, some are private, and some competition data has special terms. Future agents must check the source before moving data.
- This project is personal infrastructure unless Christian later connects it to a specific research or team project.

## Settled Decisions

- Project location: `D:\projects\personal\kaggle-agent-compute`, because this is personal leverage infrastructure.
- Project shape: use the standard `ideas/`, `data/`, `execution/`, and `ship/` structure.
- First target: establish a safe manual-to-scripted Kaggle notebook workflow before building a larger automation layer.
- Compute policy: CPU is the default for lightweight validation; GPU is allowed without extra approval when it materially helps the workload.
- Target experiment accelerator: use Kaggle T4 x2 for experiments; other GPU shapes are not the intended target.

## Change Rule

Do not casually edit this file.

If an agent thinks this foundation should change, discuss the change deeply with Christian first. After Christian agrees, update this file deliberately and record the reason in `ideas/discussions/`.
