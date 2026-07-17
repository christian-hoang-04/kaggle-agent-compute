param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z0-9_-]+$')]
    [string]$Alias
)

$ErrorActionPreference = "Stop"

$activeDir = Join-Path $env:USERPROFILE ".kaggle"
$profileRoot = Join-Path $env:USERPROFILE ".kaggle-profiles"
$profileDir = Join-Path $profileRoot $Alias
$backupRoot = Join-Path $env:USERPROFILE ".kaggle-profile-backups"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $backupRoot $timestamp

if (-not (Test-Path -LiteralPath $profileDir)) {
    throw "Kaggle profile not found: $profileDir"
}

$profileFiles = Get-ChildItem -LiteralPath $profileDir -File | Where-Object {
    $_.Name -in @("credentials.json", "access_token", "kaggle.json")
}

if ($profileFiles.Count -eq 0) {
    throw "No supported Kaggle credential files found in $profileDir"
}

if (Test-Path -LiteralPath $activeDir) {
    $activeFiles = Get-ChildItem -LiteralPath $activeDir -File | Where-Object {
        $_.Name -in @("credentials.json", "access_token", "kaggle.json")
    }

    if ($activeFiles.Count -gt 0) {
        New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

        foreach ($file in $activeFiles) {
            Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $backupDir $file.Name) -Force
        }

        Write-Host "Backed up previous active Kaggle credentials to $backupDir"
    }
}

New-Item -ItemType Directory -Force -Path $activeDir | Out-Null

foreach ($file in $profileFiles) {
    Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $activeDir $file.Name) -Force
}

Write-Host "Activated Kaggle profile '$Alias' from $profileDir"
Write-Host "Copied files: $($profileFiles.Name -join ', ')"
Write-Host "Verify with: python -m kaggle kernels list --mine"
