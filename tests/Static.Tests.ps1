Describe 'WGRC static invariants' {

    BeforeAll {
        $script:Root = Split-Path $PSScriptRoot -Parent

        $script:Core = Get-Content (
            Join-Path $script:Root 'src\WGRC.Core.psm1'
        ) -Raw

        $script:Microsoft = Get-Content (
            Join-Path $script:Root 'src\WGRC.Microsoft.ps1'
        ) -Raw

        $script:Entry = Get-Content (
            Join-Path $script:Root 'WindowsGamingReference.ps1'
        ) -Raw

        $script:Implementation = @(
            $script:Core
            $script:Microsoft
            $script:Entry
        ) -join "`n"
    }

    Context 'Safety invariants' {

        It 'does not use Invoke-Expression' {
            $script:Implementation |
                Should -Not -Match '(?i)\bInvoke-Expression\b'
        }

        It 'does not use remote pipe-to-execute' {
            $script:Implementation |
                Should -Not -Match '(?i)\birm\b.*\|.*\biex\b'

            $script:Implementation |
                Should -Not -Match '(?i)Invoke-RestMethod.*\|.*Invoke-Expression'

            $script:Implementation |
                Should -Not -Match '(?i)Invoke-WebRequest.*\|.*Invoke-Expression'
        }

        It 'does not bypass WinGet installer integrity' {
            $script:Implementation |
                Should -Not -Match '(?i)--ignore-security-hash'

            $script:Implementation |
                Should -Not -Match '(?i)InstallerHashOverride'
        }

        It 'does not delete or disable arbitrary Windows services' {
            $script:Implementation |
                Should -Not -Match '(?i)\bRemove-Service\b'

            $script:Implementation |
                Should -Not -Match '(?i)\bsc(\.exe)?\s+delete\b'

            $script:Implementation |
                Should -Not -Match '(?i)\bSet-Service\b.*Disabled'
        }

        It 'does not remove AppX packages' {
            $script:Implementation |
                Should -Not -Match '(?i)Remove-AppxPackage'
        }

        It 'does not weaken Defender through known disable switches' {
            $script:Implementation |
                Should -Not -Match '(?i)DisableAntiSpyware'

            $script:Implementation |
                Should -Not -Match '(?i)DisableRealtimeMonitoring'
        }

        It 'does not use timer or boot folklore' {
            $script:Implementation |
                Should -Not -Match '(?i)useplatformclock|disabledynamictick'

            $script:Implementation |
                Should -Not -Match '(?i)\bbcdedit\b'
        }

        It 'does not disable optional Windows features as an optimization' {
            $script:Implementation |
                Should -Not -Match '(?i)Disable-WindowsOptionalFeature'

            $script:Implementation |
                Should -Not -Match '(?i)dism(\.exe)?\s+.*/Disable-Feature'
        }
    }

    Context 'Microsoft-native invariants' {

        It 'uses Microsoft LGPO for local policy' {
            $script:Implementation |
                Should -Match 'Initialize-WgrcMicrosoftPolicyTools'

            $script:Implementation |
                Should -Match 'Invoke-WgrcLgpoText'
        }

        It 'validates Microsoft Authenticode before trusting LGPO' {
            $script:Microsoft |
                Should -Match 'Get-AuthenticodeSignature'

            $script:Microsoft |
                Should -Match 'Microsoft Corporation'
        }

        It 'uses the official Microsoft LGPO download host' {
            $defaults = Get-Content (
                Join-Path $script:Root 'configuration\defaults.psd1'
            ) -Raw

            $defaults |
                Should -Match 'https://download\.microsoft\.com/'
        }

        It 'uses WinGet Configuration for application desired state' {
            $script:Core |
                Should -Match 'winget\.exe configure'
        }

        It 'guards managed devices by default' {
            $script:Core | Should -Match 'ManagedDevice'
            $script:Core | Should -Match 'AllowManagedDevice'
        }

        It 'checks Windows-native health surfaces' {
            $script:Core |
                Should -Match 'Get-MpComputerStatus'

            $script:Core |
                Should -Match 'Get-NetFirewallProfile'

            $script:Microsoft |
                Should -Match 'Get-PnpDevice'

            $script:Microsoft |
                Should -Match 'Microsoft-Windows-WHEA-Logger'
        }
    }
}
