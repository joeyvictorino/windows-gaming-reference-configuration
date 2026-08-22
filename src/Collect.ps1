param(
    [string]$Root=(Split-Path $PSScriptRoot -Parent),
    [string]$OutputPath
)
Import-Module (Join-Path $PSScriptRoot 'WGRC.Core.psm1') -Force
Invoke-WgrcCollect -Root $Root -OutputPath $OutputPath
