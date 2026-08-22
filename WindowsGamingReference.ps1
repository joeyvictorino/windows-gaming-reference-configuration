[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Audit','Plan','Apply','Verify','Restore','Games','Collect','MicrosoftTools','Help')]
    [string]$Command = 'Help',

    [string]$BackupPath,
    [string]$OutputPath,
    [switch]$RestorePackages,
    [switch]$AllowManagedDevice
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'src\WGRC.Core.psm1') -Force

switch ($Command) {
    'Audit' {
        Invoke-WgrcAudit -Root $PSScriptRoot
    }
    'Plan' {
        Invoke-WgrcPlan -Root $PSScriptRoot
    }
    'Apply' {
        if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
            $wingetText = (& winget.exe --version).Trim()
            try {
                $wingetVersion = [version]($wingetText.TrimStart('v'))
            }
            catch {
                throw "WGRC could not parse the installed WinGet version: $wingetText"
            }

            if ($wingetVersion -ge [version]'1.29.0' -and
                $wingetVersion -lt [version]'1.30.0') {
                throw "WGRC blocks WinGet $wingetText because WinGet 1.29 has a known DSC v3 configuration regression. Install the known-good WinGet 1.28.240 with: Repair-WinGetPackageManager -Version '1.28.240' -Force"
            }
        }

        Invoke-WgrcApply -Root $PSScriptRoot -AllowManagedDevice:$AllowManagedDevice
    }
    'Verify' {
        Invoke-WgrcVerify -Root $PSScriptRoot
    }
    'Restore' {
        Invoke-WgrcRestore -Root $PSScriptRoot -BackupPath $BackupPath `
            -RestorePackages:$RestorePackages
    }
    'Games' {
        Invoke-WgrcGames -Root $PSScriptRoot
    }
    'Collect' {
        Invoke-WgrcCollect -Root $PSScriptRoot -OutputPath $OutputPath
    }
    'MicrosoftTools' {
        Invoke-WgrcMicrosoftTools -Root $PSScriptRoot
    }
    default {
@'
Windows Gaming Reference Configuration

Read / inspect:
  .\WindowsGamingReference.ps1 Audit
  .\WindowsGamingReference.ps1 Plan
  .\WindowsGamingReference.ps1 Verify

Configure:
  .\WindowsGamingReference.ps1 Apply

Restore:
  .\WindowsGamingReference.ps1 Restore
  .\WindowsGamingReference.ps1 Restore -RestorePackages

Gaming:
  .\WindowsGamingReference.ps1 Games

Support:
  .\WindowsGamingReference.ps1 Collect
  .\WindowsGamingReference.ps1 Collect -OutputPath .\WGRC-Diagnostics.zip

Microsoft policy tooling:
  .\WindowsGamingReference.ps1 MicrosoftTools

Apply refuses domain/Entra-joined systems by default.
The explicit -AllowManagedDevice override exists for administrators who own the conflict risk.
'@ | Write-Host
    }
}
