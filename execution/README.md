# Execution

This folder will contain the work that makes Kaggle usable as agent-accessible compute:

- API probes
- notebook templates
- exploratory benchmark notebooks
- local orchestration scripts
- smoke-test workflows
- run logs and small generated artifacts
- implementation notes

Keep runnable scripts thin and put reusable behavior behind a clear module boundary when the project grows.

Likely future entrypoints:

- `probe`: check local Kaggle API setup and account visibility.
- `smoke`: submit or run a tiny remote job and fetch a small artifact.
- `submit`: package and send a real job.
- `status`: inspect remote run state.
- `fetch`: download selected outputs.

Current entrypoints under `execution/scripts/`:

- `Get-KaggleProfiles.ps1`
- `Invoke-KaggleWithProfile.ps1`
- `Update-KaggleAccountStatus.ps1`
- `Submit-KaggleKernelJob.ps1`
- `Get-KaggleKernelJobStatus.ps1`
- `Get-KaggleKernelJobOutput.ps1`
- `Get-KaggleJobHistory.ps1`

Current notebook area:

- `execution/notebooks/videoqa-benchmark-implementation.ipynb` - exploratory notebook moved out of a temporary root folder.
