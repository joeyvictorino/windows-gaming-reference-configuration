param([string]$Root=(Split-Path $PSScriptRoot -Parent))
Import-Module (Join-Path $PSScriptRoot 'WGRC.Core.psm1') -Force
Invoke-WgrcMicrosoftTools -Root $Root
