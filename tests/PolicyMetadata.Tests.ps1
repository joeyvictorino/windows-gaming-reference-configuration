$root = Split-Path $PSScriptRoot -Parent
$data = Import-PowerShellDataFile (Join-Path $root 'configuration\policies.psd1')

Describe 'Policy metadata' {
    It 'contains a meaningful curated set' {
        @($data.Policies).Count | Should -BeGreaterThan 20
    }

    It 'contains only unique IDs' {
        $ids = @($data.Policies | ForEach-Object Id)
        @($ids | Select-Object -Unique).Count | Should -Be $ids.Count
    }

    foreach ($policy in $data.Policies) {
        Context $policy.Id {
            It 'declares a Microsoft-native mechanism' {
                $policy.Mechanism | Should -BeIn @('LGPO','Preference')
            }

            It 'has a primary source or native Settings reference' {
                [string]::IsNullOrWhiteSpace([string]$policy.Source) | Should -BeFalse
            }

            It 'has a reason' {
                [string]::IsNullOrWhiteSpace([string]$policy.Reason) | Should -BeFalse
            }

            It 'declares a performance claim' {
                $policy.ContainsKey('PerformanceClaim') | Should -BeTrue
            }

            It 'declares supported editions' {
                @($policy.Editions).Count | Should -BeGreaterThan 0
            }

            It 'has an explicit state target' {
                [string]::IsNullOrWhiteSpace([string]$policy.Key) | Should -BeFalse
                [string]::IsNullOrWhiteSpace([string]$policy.ValueName) | Should -BeFalse
            }

            if ($policy.Mechanism -eq 'LGPO') {
                It 'is explicitly a policy-backed setting' {
                    # Most policy values live under SOFTWARE\Policies. Some Windows
                    # policy-backed paths vary, but all WGRC LGPO entries currently use Policies.
                    $policy.Key | Should -Match '^SOFTWARE\\Policies\\'
                }
            }
        }
    }

    It 'uses direct preferences only for the intentionally small preference set' {
        $preferences = @($data.Policies | Where-Object Mechanism -eq 'Preference')
        @($preferences.Id) | Should -Contain 'gaming.game-mode'
        @($preferences.Id) | Should -Contain 'qol.file-extensions'
        $preferences.Count | Should -Be 2
    }
}
