param(
    [string]$Root=(Split-Path $PSScriptRoot -Parent),
    [string]$BackupPath,
    [switch]$RestorePackages
)
Import-Module (Join-Path $PSScriptRoot 'WGRC.Core.psm1') -Force
Invoke-WgrcRestore -Root $Root -BackupPath $BackupPath -RestorePackages:$RestorePackages
