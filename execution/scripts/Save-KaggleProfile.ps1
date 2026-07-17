param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z0-9_-]+$')]
    [string]$Alias
)

$ErrorActionPreference = "Stop"

$activeDir = Join-Path $env:USERPROFILE ".kaggle"
$profileRoot = Join-Path $env:USERPROFILE ".kaggle-profiles"
$profileDir = Join-Path $profileRoot $Alias

if (-not (Test-Path -LiteralPath $activeDir)) {
    throw "Active Kaggle directory not found: $activeDir"
}

$credentialFiles = Get-ChildItem -LiteralPath $activeDir -File | Where-Object {
    $_.Name -in @("credentials.json", "access_token", "kaggle.json")
}

if ($credentialFiles.Count -eq 0) {
    throw "No supported Kaggle credential files found in $activeDir"
}

New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

foreach ($file in $credentialFiles) {
    Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $profileDir $file.Name) -Force
}

Write-Host "Saved Kaggle credential profile '$Alias' to $profileDir"
Write-Host "Stored files: $($credentialFiles.Name -join ', ')"
