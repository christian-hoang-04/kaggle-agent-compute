# Kaggle Agent Compute

Project for exploring whether Christian's agents can use Kaggle notebooks as remote compute resources for workloads that are too large for the local machine.

```text
kaggle-agent-compute/
  ideas/
    FOUNDATION.md
    discussions/
  data/
  execution/
  ship/
```

Working rule:

- `ideas/` stores the project compass, decisions, risks, and future design discussions.
- `data/` stores local metadata, manifests, and small inspection artifacts, not large Kaggle datasets unless explicitly needed.
- `execution/` will contain scripts, notebook templates, API probes, and orchestration experiments.
- `ship/` will contain the smallest validated runnable workflow once there is one.

Current notable contents beyond the initial smoke path:

- `execution/notebooks/` - exploratory benchmark implementation notebooks that still belong to this project.

Start with [ideas/FOUNDATION.md](ideas/FOUNDATION.md) and the initial discussion record in [ideas/discussions/](ideas/discussions/).
