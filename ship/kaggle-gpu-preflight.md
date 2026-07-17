# Kaggle GPU Preflight

Use this before launching a meaningful GPU job.

## Required Metadata

For project experiments, request T4 x2 with:

```json
"machine_shape": "NvidiaTeslaT4"
```

Do not pass generic `--accelerator gpu` for experiment runs, because it can override metadata and allocate P100.

## Run The Probe

```powershell
python -m kaggle kernels push -p D:\projects\personal\kaggle-agent-compute\execution\gpu-probe-kernel -t 180
python -m kaggle kernels status lehoangnam/kaggle-agent-compute-gpu-probe
python -m kaggle kernels output lehoangnam/kaggle-agent-compute-gpu-probe -p D:\projects\personal\kaggle-agent-compute\execution\gpu-probe-output -o
```

## Check The Result

Open:

```text
D:\projects\personal\kaggle-agent-compute\execution\gpu-probe-output\gpu_probe_result.json
```

Confirm:

- `status` is `ok`
- `nvidia_smi.ok` is `true`
- `torch.imported` is `true` if the workload needs PyTorch
- `torch.cuda_available` is `true` if the workload needs PyTorch CUDA
- `torch.device_count` is `2`
- both devices are `Tesla T4`
- logs do not show framework/GPU compatibility warnings that matter for the job

## Verified Result

After setting `machine_shape` to `NvidiaTeslaT4`, the probe received:

```text
Tesla T4
Tesla T4
```

PyTorch reported:

```text
torch.cuda.is_available(): true
device_count: 2
```

## Earlier Failure

The first generic GPU probe received:

```text
Tesla P100-PCIE-16GB
```

That is not the desired experiment shape and caused PyTorch compatibility problems.
