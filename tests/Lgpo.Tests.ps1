$root = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $root 'src\WGRC.Core.psm1') -Force

Describe 'LGPO policy serialization' {
    InModuleScope WGRC.Core {
        It 'serializes supported policy entries and excludes preference entries' {
            $policies = @(
                @{
                    Id='policy.example'
                    Mechanism='LGPO'
                    Scope='Machine'
                    Key='SOFTWARE\Policies\Vendor\Product'
                    ValueName='Enabled'
                    Type='DWord'
                    Desired=1
                    Editions=@('Enterprise')
                    MinBuild=26200
                },
                @{
                    Id='preference.example'
                    Mechanism='Preference'
                    Scope='User'
                    Key='SOFTWARE\Vendor\Product'
                    ValueName='Enabled'
                    Type='DWord'
                    Desired=1
                    Editions=@('Enterprise')
                    MinBuild=26200
                }
            )

            $platform = [pscustomobject]@{
                Edition='Enterprise'
                Build=26200
            }

            $text = New-WgrcLgpoApplyText -Policies $policies -Platform $platform

            $text | Should -Match 'Computer'
            $text | Should -Match 'SOFTWARE\\Policies\\Vendor\\Product'
            $text | Should -Match 'Enabled'
            $text | Should -Match 'DWORD:1'
            $text | Should -Not -Match 'SOFTWARE\\Vendor\\Product'
        }

        It 'uses DELETE to restore a previously Not Configured policy value' {
            $backup = @(
                [pscustomobject]@{
                    Mechanism='LGPO'
                    Scope='User'
                    Key='SOFTWARE\Policies\Vendor\Product'
                    ValueName='Example'
                    ValueExists=$false
                    Value=$null
                    Kind=$null
                }
            )

            $text = New-WgrcLgpoRestoreText -BackupPolicies $backup
            $text | Should -Match 'User'
            $text | Should -Match 'DELETE'
        }

        It 'restores a saved DWORD value rather than deleting it' {
            $backup = @(
                [pscustomobject]@{
                    Mechanism='LGPO'
                    Scope='Machine'
                    Key='SOFTWARE\Policies\Vendor\Product'
                    ValueName='Example'
                    ValueExists=$true
                    Value=0
                    Kind='DWord'
                }
            )

            $text = New-WgrcLgpoRestoreText -BackupPolicies $backup
            $text | Should -Match 'Computer'
            $text | Should -Match 'DWORD:0'
            $text | Should -Not -Match 'DELETE'
        }
    }
}
