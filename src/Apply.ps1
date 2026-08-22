param(
    [string]$Root=(Split-Path $PSScriptRoot -Parent),
    [switch]$AllowManagedDevice
)
Import-Module (Join-Path $PSScriptRoot 'WGRC.Core.psm1') -Force
Invoke-WgrcApply -Root $Root -AllowManagedDevice:$AllowManagedDevice
