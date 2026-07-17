[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$HistoryPath = "",
    [string]$Alias = "",
    [string]$KernelRef = "",
    [switch]$AsJson
)

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "KaggleProfileHelpers.psm1") -Force

if (-not $HistoryPath) {
    $HistoryPath = Get-DefaultJobHistoryPath
}

if (-not (Test-Path -LiteralPath $HistoryPath)) {
    Write-Host "Job history file not found: $HistoryPath"
    exit 0
}

$items = @(Get-Content -LiteralPath $HistoryPath | Where-Object { $_.Trim() } | ForEach-Object {
    $_ | ConvertFrom-Json
})

if ($Alias) {
    $items = @($items | Where-Object { $_.alias -eq $Alias })
}

if ($KernelRef) {
    $items = @($items | Where-Object { $_.kernel_ref -eq $KernelRef })
}

if ($AsJson) {
    $items | ConvertTo-Json -Depth 20
    exit 0
}

$items | Select-Object recorded_at_utc, event_type, alias, kernel_ref, exit_code, status_exit_code, output_path | Format-Table -AutoSize -Wrap
