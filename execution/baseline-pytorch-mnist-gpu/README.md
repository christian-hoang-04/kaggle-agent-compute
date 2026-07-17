# PyTorch MNIST GPU Baseline

Script-kernel wrapper around the MNIST example from:

```text
https://github.com/pytorch/examples
```

This is intentionally tiny:

- downloads MNIST
- trains 5 batches on the Kaggle GPU if CUDA works
- evaluates 2 test batches
- writes `baseline_result_gpu.json`

Target project accelerator is T4 x2. The Kaggle SDK documents the T4 machine shape as `NvidiaTeslaT4`, which is used in `kernel-metadata.json`.
