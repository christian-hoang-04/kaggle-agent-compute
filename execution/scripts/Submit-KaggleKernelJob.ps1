[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z0-9_-]+$')]
    [string]$Alias,
    [Parameter(Mandatory = $true)]
    [string]$KernelPath,
    [int]$TimeoutSeconds = 120,
    [string]$Accelerator = "",
    [string]$HistoryPath = "",
    [string]$Note = "",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "KaggleProfileHelpers.psm1") -Force

if (-not $HistoryPath) {
    $HistoryPath = Get-DefaultJobHistoryPath
}

$entry = Get-KaggleProfileEntry -Alias $Alias
if (-not $entry.exists) {
    throw "Kaggle profile directory does not exist: $($entry.profile_dir)"
}

$resolvedKernelPath = (Resolve-Path -LiteralPath $KernelPath).Path
$metadata = Get-KernelMetadata -KernelPath $resolvedKernelPath
$kernelRef = Resolve-KernelRef -KernelPath $resolvedKernelPath

$args = @("kernels", "push", "-p", $resolvedKernelPath, "-t", "$TimeoutSeconds")
if ($Accelerator) {
    $args += @("--accelerator", $Accelerator)
}

$historyEvent = [pscustomobject]@{
    recorded_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    event_type      = "submit"
    alias           = $Alias
    kernel_ref      = $kernelRef
    kernel_path     = $resolvedKernelPath
    timeout_seconds = $TimeoutSeconds
    accelerator     = if ($Accelerator) { $Accelerator } else { $metadata.machine_shape }
    note            = $Note
    dry_run         = [bool]$DryRun
}

if ($DryRun) {
    $historyEvent | ConvertTo-Json -Depth 10
    exit 0
}

$previousConfigDir = $env:KAGGLE_CONFIG_DIR
$previousPythonIoEncoding = $env:PYTHONIOENCODING
$previousPythonUtf8 = $env:PYTHONUTF8
$env:KAGGLE_CONFIG_DIR = $entry.profile_dir
$env:PYTHONIOENCODING = "utf-8"
$env:PYTHONUTF8 = "1"

try {
    Write-Host "Submitting $kernelRef with alias '$Alias' from $resolvedKernelPath"
    $output = & python -X utf8 -m kaggle @args 2>&1
    $exitCode = $LASTEXITCODE

    $historyEvent | Add-Member -NotePropertyName exit_code -NotePropertyValue $exitCode
    $historyEvent | Add-Member -NotePropertyName cli_output -NotePropertyValue (($output | Out-String).Trim())
    Add-JsonLine -Path $HistoryPath -Data $historyEvent

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
