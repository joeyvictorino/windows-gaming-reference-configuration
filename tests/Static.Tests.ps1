$root = Split-Path $PSScriptRoot -Parent
$core = Get-Content (Join-Path $root 'src\WGRC.Core.psm1') -Raw
$ms = Get-Content (Join-Path $root 'src\WGRC.Microsoft.ps1') -Raw
$entry = Get-Content (Join-Path $root 'WindowsGamingReference.ps1') -Raw
$impl = "$core`n$ms`n$entry"

Describe 'Safety invariants' {
    It 'does not use Invoke-Expression' {
        $impl | Should -Not -Match '(?i)\bInvoke-Expression\b'
    }

    It 'does not use remote pipe-to-execute' {
        $impl | Should -Not -Match '(?i)\birm\b.*\|.*\biex\b'
        $impl | Should -Not -Match '(?i)Invoke-RestMethod.*\|.*Invoke-Expression'
        $impl | Should -Not -Match '(?i)Invoke-WebRequest.*\|.*Invoke-Expression'
    }

    It 'does not bypass WinGet installer integrity' {
        $impl | Should -Not -Match '(?i)--ignore-security-hash'
        $impl | Should -Not -Match '(?i)InstallerHashOverride'
    }

    It 'does not delete or disable arbitrary Windows services' {
        $impl | Should -Not -Match '(?i)\bRemove-Service\b'
        $impl | Should -Not -Match '(?i)\bsc(\.exe)?\s+delete\b'
        $impl | Should -Not -Match '(?i)\bSet-Service\b.*Disabled'
    }

    It 'does not remove AppX packages' {
        $impl | Should -Not -Match '(?i)Remove-AppxPackage'
    }

    It 'does not weaken Defender through known disable switches' {
        $impl | Should -Not -Match '(?i)DisableAntiSpyware'
        $impl | Should -Not -Match '(?i)DisableRealtimeMonitoring'
        $impl | Should -Not -Match '(?i)Set-MpPreference.*-(Disable|EnableNetworkProtection\s+0)'
    }

    It 'does not use timer or boot folklore' {
        $impl | Should -Not -Match '(?i)useplatformclock|disabledynamictick'
        $impl | Should -Not -Match '(?i)\bbcdedit\b'
    }

    It 'does not disable Windows optional features as a gaming optimization' {
        $impl | Should -Not -Match '(?i)Disable-WindowsOptionalFeature'
        $impl | Should -Not -Match '(?i)dism(\.exe)?\s+.*/Disable-Feature'
    }
}

Describe 'Microsoft-native invariants' {
    It 'uses Microsoft LGPO for local policy' {
        $impl | Should -Match 'Initialize-WgrcMicrosoftPolicyTools'
        $impl | Should -Match 'Invoke-WgrcLgpoText'
    }

    It 'validates Microsoft Authenticode before trusting LGPO' {
        $ms | Should -Match 'Get-AuthenticodeSignature'
        $ms | Should -Match 'Microsoft Corporation'
    }

    It 'uses the official Microsoft LGPO download host' {
        $defaults = Get-Content (Join-Path $root 'configuration\defaults.psd1') -Raw
        $defaults | Should -Match 'https://download\.microsoft\.com/'
    }

    It 'uses WinGet Configuration for app desired state' {
        $core | Should -Match 'winget\.exe configure'
    }

    It 'guards managed devices by default' {
        $core | Should -Match 'ManagedDevice'
        $core | Should -Match 'AllowManagedDevice'
    }

    It 'checks Windows-native health surfaces' {
        $ms | Should -Match 'Confirm-SecureBootUEFI'
        $ms | Should -Match 'Get-Tpm'
        $core | Should -Match 'Get-MpComputerStatus'
        $core | Should -Match 'Get-NetFirewallProfile'
        $ms | Should -Match 'Get-PnpDevice'
        $ms | Should -Match 'Microsoft-Windows-WHEA-Logger'
    }
}
