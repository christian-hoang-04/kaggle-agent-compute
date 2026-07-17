$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$templatePath = Join-Path $projectRoot "templates\pytorch_mnist_baseline.py.tpl"
$template = Get-Content -Raw -LiteralPath $templatePath

$targets = @(
    @{
        Path = Join-Path $projectRoot "baseline-pytorch-mnist-cpu\run_baseline.py"
        RunMode = "cpu"
        ResultFile = "baseline_result_cpu.json"
        RequireT4x2 = "False"
    },
    @{
        Path = Join-Path $projectRoot "baseline-pytorch-mnist-gpu\run_baseline.py"
        RunMode = "gpu"
        ResultFile = "baseline_result_gpu.json"
        RequireT4x2 = "True"
    }
)

foreach ($target in $targets) {
    $content = $template.
        Replace("__RUN_MODE__", $target.RunMode).
        Replace("__RESULT_FILE__", $target.ResultFile).
        Replace("__REQUIRE_T4X2__", $target.RequireT4x2)

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($target.Path, $content, $utf8NoBom)
    Write-Host "Wrote $($target.Path)"
}
