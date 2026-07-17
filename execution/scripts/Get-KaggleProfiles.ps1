param(
    [string]$RegistryPath = "",
    [switch]$AsJson
)

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "KaggleProfileHelpers.psm1") -Force

if (-not $RegistryPath) {
    $RegistryPath = Get-DefaultRegistryPath
}

$entries = @(Get-KaggleProfileEntries -RegistryPath $RegistryPath | ForEach-Object {
    [pscustomobject]@{
        alias            = $_.alias
        kaggle_username  = $_.kaggle_username
        profile_dir      = $_.profile_dir
        credential_files = ($_.credential_files -join ", ")
        is_active        = if ($_.exists) { Test-ProfileMatchesActiveCredentials -ProfileDir $_.profile_dir } else { $false }
        exists           = $_.exists
        registry_path    = $_.registry_path
    }
})

if ($AsJson) {
    $entries | ConvertTo-Json -Depth 10
    exit 0
}

$entries | Select-Object alias, kaggle_username, is_active, exists, credential_files, profile_dir | Format-Table -AutoSize -Wrap
