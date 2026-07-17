# PyTorch MNIST Baseline Report

Source:

```text
https://github.com/pytorch/examples
```

Result:

- CPU script-kernel baseline works.
- GPU script-kernel baseline works after setting `machine_shape` to `NvidiaTeslaT4`.
- GPU baseline validates T4 x2 before training and uses PyTorch `DataParallel` when both T4s are present.
- Basecode does not need to be converted to a notebook.

## CPU

Kernel:

```text
lehoangnam/kaggle-agent-baseline-pytorch-mnist-cpu
```

Status:

```text
COMPLETE
```

Output:

```text
execution/baseline-pytorch-mnist-output/cpu/baseline_result_cpu.json
```

## GPU

Kernel:

```text
lehoangnam/kaggle-agent-baseline-pytorch-mnist-gpu
```

Status:

```text
COMPLETE
```

Output:

```text
execution/baseline-pytorch-mnist-output/gpu/baseline_result_gpu.json
```

Device:

```text
Tesla T4 x2
```

Result:

- `status`: `ok`
- `mode`: `gpu`
- `duration_seconds`: `11.133`
- `torch.cuda_available`: `true`
- `device_count`: `2`
- `devices`: `Tesla T4`, `Tesla T4`
- `use_data_parallel`: `true`
- `test_accuracy`: `0.532`

## Fix Applied

The first GPU attempt used generic `--accelerator gpu`, which allocated P100 and failed with a PyTorch CUDA compatibility error.

The fixed metadata uses:

```json
"machine_shape": "NvidiaTeslaT4"
```

Future experiment kernels should use this field and avoid overriding it with generic `--accelerator gpu`.

## Code Organization

The CPU and GPU script kernels are generated from:

```text
execution/templates/pytorch_mnist_baseline.py.tpl
```

Regenerate them with:

```powershell
execution\scripts\Build-PyTorchMnistBaselines.ps1
```

The generated files are intentionally self-contained because Kaggle script kernels submit the configured `code_file` as the script body.
