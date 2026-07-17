[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z0-9_-]+$')]
    [string]$Alias,
    [string]$RegistryPath = "",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$KaggleArgs
)

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "KaggleProfileHelpers.psm1") -Force

if (-not $RegistryPath) {
    $RegistryPath = Get-DefaultRegistryPath
}

$entry = Get-KaggleProfileEntry -Alias $Alias -RegistryPath $RegistryPath
if (-not $entry.exists) {
    throw "Kaggle profile directory does not exist: $($entry.profile_dir)"
}

if ($KaggleArgs.Count -eq 0) {
    throw "Provide a Kaggle CLI command after the alias. Example: .\\Invoke-KaggleWithProfile.ps1 -Alias primary kernels list --mine"
}

$previousConfigDir = $env:KAGGLE_CONFIG_DIR
$env:KAGGLE_CONFIG_DIR = $entry.profile_dir

try {
    Write-Host "Using Kaggle profile '$Alias' with KAGGLE_CONFIG_DIR=$($entry.profile_dir)"
    & python -m kaggle @KaggleArgs
    exit $LASTEXITCODE
}
finally {
    if ($null -eq $previousConfigDir) {
        Remove-Item Env:KAGGLE_CONFIG_DIR -ErrorAction SilentlyContinue
    }
    else {
        $env:KAGGLE_CONFIG_DIR = $previousConfigDir
    }
}
