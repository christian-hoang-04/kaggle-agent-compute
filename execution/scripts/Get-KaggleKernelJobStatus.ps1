[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z0-9_-]+$')]
    [string]$Alias,
    [string]$KernelRef = "",
    [string]$KernelPath = "",
    [string]$HistoryPath = "",
    [switch]$IncludeLogs
)

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "KaggleProfileHelpers.psm1") -Force

if (-not $HistoryPath) {
    $HistoryPath = Get-DefaultJobHistoryPath
}

$entry = Get-KaggleProfileEntry -Alias $Alias
$resolvedKernelRef = Resolve-KernelRef -KernelRef $KernelRef -KernelPath $KernelPath

$previousConfigDir = $env:KAGGLE_CONFIG_DIR
$previousPythonIoEncoding = $env:PYTHONIOENCODING
$previousPythonUtf8 = $env:PYTHONUTF8
$env:KAGGLE_CONFIG_DIR = $entry.profile_dir
$env:PYTHONIOENCODING = "utf-8"
$env:PYTHONUTF8 = "1"

try {
    $statusOutput = & python -X utf8 -m kaggle kernels status $resolvedKernelRef 2>&1
    $statusExit = $LASTEXITCODE

    $logsOutput = $null
    $logsExit = $null
    if ($IncludeLogs) {
        $logsOutput = & python -X utf8 -m kaggle kernels logs $resolvedKernelRef 2>&1
        $logsExit = $LASTEXITCODE
    }

    $record = [pscustomobject]@{
        recorded_at_utc = (Get-Date).ToUniversalTime().ToString("o")
        event_type      = "status"
        alias           = $Alias
        kernel_ref      = $resolvedKernelRef
        status_exit_code = $statusExit
        status_output   = (($statusOutput | Out-String).Trim())
        include_logs    = [bool]$IncludeLogs
    }
    if ($IncludeLogs) {
        $record | Add-Member -NotePropertyName logs_exit_code -NotePropertyValue $logsExit
        $record | Add-Member -NotePropertyName logs_output -NotePropertyValue (($logsOutput | Out-String).Trim())
    }

    Add-JsonLine -Path $HistoryPath -Data $record
    $record | ConvertTo-Json -Depth 10
    exit $statusExit
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
