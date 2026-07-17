[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z0-9_-]+$')]
    [string]$Alias,
    [string]$KernelRef = "",
    [string]$KernelPath = "",
    [string]$OutputPath = "",
    [string]$FilePattern = "",
    [string]$HistoryPath = "",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "KaggleProfileHelpers.psm1") -Force

if (-not $HistoryPath) {
    $HistoryPath = Get-DefaultJobHistoryPath
}

$entry = Get-KaggleProfileEntry -Alias $Alias
$resolvedKernelRef = Resolve-KernelRef -KernelRef $KernelRef -KernelPath $KernelPath

if (-not $OutputPath) {
    $OutputPath = Get-DefaultKernelOutputDir -Alias $Alias -KernelRef $resolvedKernelRef
}

New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null

$args = @("kernels", "output", $resolvedKernelRef, "-p", $OutputPath)
if ($Force) {
    $args += "-o"
}
if ($FilePattern) {
    $args += @("--file-pattern", $FilePattern)
}

$previousConfigDir = $env:KAGGLE_CONFIG_DIR
$previousPythonIoEncoding = $env:PYTHONIOENCODING
$previousPythonUtf8 = $env:PYTHONUTF8
$env:KAGGLE_CONFIG_DIR = $entry.profile_dir
$env:PYTHONIOENCODING = "utf-8"
$env:PYTHONUTF8 = "1"

try {
    $output = & python -X utf8 -m kaggle @args 2>&1
    $exitCode = $LASTEXITCODE

    $record = [pscustomobject]@{
        recorded_at_utc = (Get-Date).ToUniversalTime().ToString("o")
        event_type      = "fetch_output"
        alias           = $Alias
        kernel_ref      = $resolvedKernelRef
        output_path     = $OutputPath
        file_pattern    = $FilePattern
        exit_code       = $exitCode
        cli_output      = (($output | Out-String).Trim())
    }
    Add-JsonLine -Path $HistoryPath -Data $record

    $output
    exit $exitCode
}
finally {
    if ($null -eq $previousConfigDir) {
        Remove-Item Env:KAGGLE_CONFIG_DIR -ErrorAction SilentlyContinue
    }
    else {
        $env:KAGGLE_CONFIG_DIR = $previousConfigDir
    }
    if ($null -eq $previousPythonIoEncoding) {
        Remove-Item Env:PYTHONIOENCODING -ErrorAction SilentlyContinue
    }
    else {
        $env:PYTHONIOENCODING = $previousPythonIoEncoding
    }
    if ($null -eq $previousPythonUtf8) {
        Remove-Item Env:PYTHONUTF8 -ErrorAction SilentlyContinue
    }
    else {
        $env:PYTHONUTF8 = $previousPythonUtf8
    }
}
