# 2026-06-28 GPU Probe Success

## What Was Done

Created and ran a private Kaggle GPU probe kernel.

Kernel:

```text
lehoangnam/kaggle-agent-compute-gpu-probe
```

URL:

```text
https://www.kaggle.com/code/lehoangnam/kaggle-agent-compute-gpu-probe
```

## Commands Used

```powershell
python -m kaggle kernels push -p D:\projects\personal\kaggle-agent-compute\execution\gpu-probe-kernel -t 180 --accelerator gpu
python -m kaggle kernels status lehoangnam/kaggle-agent-compute-gpu-probe
python -m kaggle kernels output lehoangnam/kaggle-agent-compute-gpu-probe -p D:\projects\personal\kaggle-agent-compute\execution\gpu-probe-output -o
```

## Result

Kaggle completed the GPU run successfully.

Downloaded artifacts:

- `execution/gpu-probe-output/gpu_probe_result.json`
- `execution/gpu-probe-output/kaggle-agent-compute-gpu-probe.log`

## Device Observed

The run received:

```text
Tesla P100-PCIE-16GB
```

Key facts:

- `nvidia-smi` worked.
- Driver version: `580.159.04`.
- CUDA version from `nvidia-smi`: `13.0`.
- PyTorch imported successfully.
- PyTorch version: `2.10.0+cu128`.
- PyTorch CUDA version: `12.8`.
- `torch.cuda.is_available()` returned `true`.
- Device count: `1`.
- Device memory: `17059545088` bytes.
- Compute capability: `6.0`.

## Important Compatibility Note

The Kaggle image's default PyTorch emitted warnings that Tesla P100 compute capability `sm_60` is not compatible with the installed PyTorch build.

The installed PyTorch build reports supported CUDA capabilities:

```text
sm_70 sm_75 sm_80 sm_86 sm_90 sm_100 sm_120
```

Implication:

- GPU provisioning works.
- Simple GPU availability checks pass.
- Future PyTorch workloads may need a compatible PyTorch build, a different Kaggle accelerator allocation, or a framework/version choice that supports P100.
- Agents must not assume that a successful GPU allocation means the default ML framework is compatible.

## Decision

GPU is validated as available for agent-started Kaggle runs.

Future GPU jobs should include an environment probe phase before running expensive training or inference.

## Next Actions

- Add a reusable GPU preflight checklist to `ship/`.
- For PyTorch-heavy work, test the actual model stack on the allocated Kaggle GPU before launching a long run.
- Consider adding a framework-specific probe for PyTorch, TensorFlow, and JAX if those become common.
