param(
    [string]$RegistryPath = "",
    [string]$StatusPath = "",
    [string]$Alias = ""
)

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "KaggleProfileHelpers.psm1") -Force

if (-not $RegistryPath) {
    $RegistryPath = Get-DefaultRegistryPath
}

if (-not $StatusPath) {
    $StatusPath = Get-DefaultStatusPath
}

$entries = @(Get-KaggleProfileEntries -RegistryPath $RegistryPath)
if ($Alias) {
    $entries = @($entries | Where-Object { $_.alias -eq $Alias })
}

if ($entries.Count -eq 0) {
    throw "No Kaggle profiles found to update."
}

$existingStatus = Read-JsonFile -Path $StatusPath
$existingByAlias = @{}
if ($null -ne $existingStatus -and $existingStatus.PSObject.Properties.Name -contains "accounts") {
    foreach ($account in $existingStatus.accounts) {
        $existingByAlias[$account.alias] = $account
    }
}

$runtimeScript = Join-Path $PSScriptRoot "kaggle_profile_runtime.py"
$updatedAccounts = @()

foreach ($entry in $entries) {
    $snapshotJson = & python $runtimeScript snapshot --config-dir $entry.profile_dir
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to capture Kaggle snapshot for alias '$($entry.alias)'."
    }

    $snapshot = $snapshotJson | ConvertFrom-Json
    $existing = $existingByAlias[$entry.alias]

    $benchmarkSpend = $null
    if ($null -ne $existing -and $existing.PSObject.Properties.Name -contains "benchmark_spend") {
        $benchmarkSpend = $existing.benchmark_spend
    }
    if ($null -eq $benchmarkSpend) {
        $benchmarkSpend = [pscustomobject]@{
            status                 = "unknown"
            remaining_monthly_usd  = $null
            remaining_daily_usd    = $null
            last_observed_utc      = $null
            source                 = $null
            notes                  = $null
        }
    }

    $updatedAccounts += [pscustomobject]@{
        alias             = $entry.alias
        registry_username = $entry.kaggle_username
        observed_username = $snapshot.observed_username
        profile_dir       = $entry.profile_dir
        auth_ok           = $snapshot.auth_ok
        credential_files  = $entry.credential_files
        notebook_quota    = $snapshot.notebook_quota
        benchmark_spend   = $benchmarkSpend
        updated_at_utc    = (Get-Date).ToUniversalTime().ToString("o")
    }
}

$statusDocument = [pscustomobject]@{
    version        = 1
    registry_path  = $RegistryPath
    updated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    accounts       = $updatedAccounts
}

Write-JsonFile -Path $StatusPath -Data $statusDocument
Write-Host "Wrote Kaggle account status to $StatusPath"
