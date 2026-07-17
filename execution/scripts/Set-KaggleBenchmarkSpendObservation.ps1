param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z0-9_-]+$')]
    [string]$Alias,
    [switch]$Clear,
    [double]$RemainingMonthlyUsd = [double]::NaN,
    [double]$RemainingDailyUsd = [double]::NaN,
    [string]$Source = "manual",
    [string]$Notes = "",
    [string]$StatusPath = ""
)

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "KaggleProfileHelpers.psm1") -Force

if (-not $StatusPath) {
    $StatusPath = Get-DefaultStatusPath
}

$status = Read-JsonFile -Path $StatusPath
if ($null -eq $status) {
    throw "Status file not found: $StatusPath. Run .\\Update-KaggleAccountStatus.ps1 first."
}

$accounts = @($status.accounts)
$targetIndex = -1
for ($i = 0; $i -lt $accounts.Count; $i++) {
    if ($accounts[$i].alias -eq $Alias) {
        $targetIndex = $i
        break
    }
}

if ($targetIndex -lt 0) {
    throw "Alias not found in status file: $Alias"
}

$target = $accounts[$targetIndex]

if ($Clear) {
    $accounts[$targetIndex].benchmark_spend = [pscustomobject]@{
        status                = "unknown"
        remaining_monthly_usd = $null
        remaining_daily_usd   = $null
        last_observed_utc     = $null
        source                = $null
        notes                 = $null
    }
}
else {
    $monthlyValue = if ([double]::IsNaN($RemainingMonthlyUsd)) { $target.benchmark_spend.remaining_monthly_usd } else { $RemainingMonthlyUsd }
    $dailyValue = if ([double]::IsNaN($RemainingDailyUsd)) { $target.benchmark_spend.remaining_daily_usd } else { $RemainingDailyUsd }
    $noteValue = if ($Notes) { $Notes } else { $target.benchmark_spend.notes }

    $accounts[$targetIndex].benchmark_spend = [pscustomobject]@{
        status                = "manual"
        remaining_monthly_usd = $monthlyValue
        remaining_daily_usd   = $dailyValue
        last_observed_utc     = (Get-Date).ToUniversalTime().ToString("o")
        source                = $Source
        notes                 = $noteValue
    }
}

$status.updated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
$status.accounts = $accounts
Write-JsonFile -Path $StatusPath -Data $status
Write-Host "Updated benchmark spend observation for alias '$Alias' in $StatusPath"
