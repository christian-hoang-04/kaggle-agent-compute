# Data

This folder contains small source notes, manifests, schemas, and inspection artifacts for the Kaggle agent compute project.

Use it for:

- Kaggle dataset source lists
- local manifests for remote jobs
- expected input/output schemas
- lightweight inspection outputs
- metadata that describes where canonical data lives
- small supporting resources under `data/resources/` when they belong to this infrastructure project

Large-file rules:

- Prefer Kaggle-hosted datasets or external canonical sources over local copies.
- Do not commit raw large datasets.
- Preserve manifests, source URLs or Kaggle slugs, checksums when useful, and cleanup notes.
- Record whether an archive is safe to delete after extraction.
