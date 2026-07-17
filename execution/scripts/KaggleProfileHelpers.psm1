Set-StrictMode -Version Latest

function Get-ProjectRoot {
    return Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
}

function Get-DefaultRegistryPath {
    $projectRoot = Get-ProjectRoot
    $localPath = Join-Path $projectRoot "data\kaggle-account-registry.local.json"
    if (Test-Path -LiteralPath $localPath) {
        return $localPath
    }

    return Join-Path $projectRoot "data\kaggle-account-registry.example.json"
}

function Get-DefaultStatusPath {
    $projectRoot = Get-ProjectRoot
    return Join-Path $projectRoot "data\kaggle-account-status.local.json"
}

function Get-DefaultJobHistoryPath {
    $projectRoot = Get-ProjectRoot
    return Join-Path $projectRoot "data\kaggle-job-history.local.jsonl"
}

function Expand-EnvPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [Environment]::ExpandEnvironmentVariables($Path)
}

function Read-JsonFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        $Data
    )

    $parent = Split-Path $Path -Parent
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    $Data | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Path
}

function Add-JsonLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        $Data
    )

    $parent = Split-Path $Path -Parent
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    ($Data | ConvertTo-Json -Depth 20 -Compress) | Add-Content -LiteralPath $Path
}

function Get-RegistryConfig {
    param(
        [string]$RegistryPath = $(Get-DefaultRegistryPath)
    )

    $registry = Read-JsonFile -Path $RegistryPath
    if ($null -eq $registry) {
        return $null
    }

    return $registry
}

function Get-ProfileRoot {
    param(
        [string]$RegistryPath = $(Get-DefaultRegistryPath)
    )

    $registry = Get-RegistryConfig -RegistryPath $RegistryPath
    if ($null -ne $registry -and $registry.PSObject.Properties.Name -contains "credential_root" -and $registry.credential_root) {
        return (Expand-EnvPath -Path $registry.credential_root)
    }

    return Join-Path $env:USERPROFILE ".kaggle-profiles"
}

function New-ProfileEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Alias,
        [Parameter(Mandatory = $true)]
        [string]$ProfileDir,
        [string]$KaggleUsername,
        [string[]]$AllowedCompute,
        [string]$DefaultCompute,
        [string[]]$IntendedUse,
        [string]$RegistryPath
    )

    $credentialFiles = @()
    if (Test-Path -LiteralPath $ProfileDir) {
        $credentialFiles = Get-ChildItem -LiteralPath $ProfileDir -File | Where-Object {
            $_.Name -in @("credentials.json", "access_token", "kaggle.json")
        }
    }
    $credentialFileNames = @()
    foreach ($file in @($credentialFiles)) {
        if ($null -ne $file -and $file.PSObject.Properties.Name -contains "Name") {
            $credentialFileNames += $file.Name
        }
    }

    [pscustomobject]@{
        alias            = $Alias
        kaggle_username  = $KaggleUsername
        profile_dir      = $ProfileDir
        registry_path    = $RegistryPath
        allowed_compute  = $AllowedCompute
        default_compute  = $DefaultCompute
        intended_use     = $IntendedUse
        credential_files = $credentialFileNames
        exists           = (Test-Path -LiteralPath $ProfileDir)
    }
}

function Get-KaggleProfileEntries {
    param(
        [string]$RegistryPath = $(Get-DefaultRegistryPath)
    )

    $registry = Get-RegistryConfig -RegistryPath $RegistryPath
    if ($null -ne $registry -and $registry.PSObject.Properties.Name -contains "accounts" -and $registry.accounts) {
        $entries = @()
        foreach ($account in $registry.accounts) {
            $profileDir = if ($account.profile_dir) {
                Expand-EnvPath -Path $account.profile_dir
            }
            else {
                Join-Path (Get-ProfileRoot -RegistryPath $RegistryPath) $account.alias
            }

            $entries += New-ProfileEntry `
                -Alias $account.alias `
                -ProfileDir $profileDir `
                -KaggleUsername $account.kaggle_username `
                -AllowedCompute $account.allowed_compute `
                -DefaultCompute $account.default_compute `
                -IntendedUse $account.intended_use `
                -RegistryPath $RegistryPath
        }

        return $entries
    }

    $profileRoot = Get-ProfileRoot -RegistryPath $RegistryPath
    if (-not (Test-Path -LiteralPath $profileRoot)) {
        return @()
    }

    return @(Get-ChildItem -LiteralPath $profileRoot -Directory | Sort-Object Name | ForEach-Object {
        New-ProfileEntry `
            -Alias $_.Name `
            -ProfileDir $_.FullName `
            -RegistryPath $RegistryPath
    })
}

function Get-KaggleProfileEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Alias,
        [string]$RegistryPath = $(Get-DefaultRegistryPath)
    )

    $entry = Get-KaggleProfileEntries -RegistryPath $RegistryPath | Where-Object { $_.alias -eq $Alias }
    if ($null -eq $entry) {
        throw "Kaggle profile alias not found: $Alias"
    }

    return $entry
}

function Get-KernelMetadata {
    param(
        [Parameter(Mandatory = $true)]
        [string]$KernelPath
    )

    $metadataPath = Join-Path $KernelPath "kernel-metadata.json"
    if (-not (Test-Path -LiteralPath $metadataPath)) {
        throw "kernel-metadata.json not found in $KernelPath"
    }

    return (Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json)
}

function Resolve-KernelRef {
    param(
        [string]$KernelRef,
        [string]$KernelPath
    )

    if ($KernelRef) {
        return $KernelRef
    }

    if (-not $KernelPath) {
        throw "Provide either -KernelRef or -KernelPath."
    }

    $metadata = Get-KernelMetadata -KernelPath $KernelPath
    if (-not $metadata.id) {
        throw "Kernel metadata in $KernelPath does not contain an id field."
    }

    return $metadata.id
}

function Get-KernelSlugFromRef {
    param(
        [Parameter(Mandatory = $true)]
        [string]$KernelRef
    )

    $parts = $KernelRef.Split("/")
    if ($parts.Length -lt 2) {
        throw "Invalid kernel ref: $KernelRef"
    }

    return $parts[1]
}

function Get-DefaultKernelOutputDir {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Alias,
        [Parameter(Mandatory = $true)]
        [string]$KernelRef
    )

    $projectRoot = Get-ProjectRoot
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $slug = Get-KernelSlugFromRef -KernelRef $KernelRef
    return Join-Path $projectRoot ("execution\run-output\{0}\{1}\{2}" -f $Alias, $slug, $timestamp)
}

function Get-ActiveCredentialFiles {
    $activeDir = Join-Path $env:USERPROFILE ".kaggle"
    if (-not (Test-Path -LiteralPath $activeDir)) {
        return @()
    }

    return @(Get-ChildItem -LiteralPath $activeDir -File | Where-Object {
        $_.Name -in @("credentials.json", "access_token", "kaggle.json")
    })
}

function Test-ProfileMatchesActiveCredentials {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProfileDir
    )

    $activeFiles = @(Get-ActiveCredentialFiles)
    if ($activeFiles.Count -eq 0) {
        return $false
    }

    $profileFiles = @(Get-ChildItem -LiteralPath $ProfileDir -File | Where-Object {
        $_.Name -in @("credentials.json", "access_token", "kaggle.json")
    })

    if ($profileFiles.Count -ne $activeFiles.Count) {
        return $false
    }

    foreach ($file in $profileFiles) {
        $activeFile = $activeFiles | Where-Object { $_.Name -eq $file.Name } | Select-Object -First 1
        if ($null -eq $activeFile) {
            return $false
        }

        $profileHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
        $activeHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $activeFile.FullName).Hash
        if ($profileHash -ne $activeHash) {
            return $false
        }
    }

    return $true
}

Export-ModuleMember -Function `
    Add-JsonLine, `
    Expand-EnvPath, `
    Get-ActiveCredentialFiles, `
    Get-DefaultJobHistoryPath, `
    Get-DefaultRegistryPath, `
    Get-DefaultStatusPath, `
    Get-KaggleProfileEntries, `
    Get-KaggleProfileEntry, `
    Get-DefaultKernelOutputDir, `
    Get-KernelMetadata, `
    Get-KernelSlugFromRef, `
    Get-ProfileRoot, `
    Get-ProjectRoot, `
    Read-JsonFile, `
    Resolve-KernelRef, `
    Test-ProfileMatchesActiveCredentials, `
    Write-JsonFile
