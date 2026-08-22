Describe 'Policy metadata' {

    BeforeAll {
        $script:Root = Split-Path $PSScriptRoot -Parent
        $script:PolicyData = Import-PowerShellDataFile (
            Join-Path $script:Root 'configuration\policies.psd1'
        )
        $script:Policies = @($script:PolicyData.Policies)
    }

    It 'contains a meaningful curated set' {
        $script:Policies.Count | Should -BeGreaterThan 20
    }

    It 'contains only unique IDs' {
        $ids = @($script:Policies | ForEach-Object { $_.Id })
        @($ids | Select-Object -Unique).Count | Should -Be $ids.Count
    }

    It 'gives every policy complete metadata' {
        foreach ($policy in $script:Policies) {

            $policy.Mechanism |
                Should -BeIn @('LGPO','Preference') `
                -Because "$($policy.Id) must declare its mechanism"

            [string]::IsNullOrWhiteSpace([string]$policy.Source) |
                Should -BeFalse `
                -Because "$($policy.Id) must declare a public source"

            [string]::IsNullOrWhiteSpace([string]$policy.Reason) |
                Should -BeFalse `
                -Because "$($policy.Id) must explain why it exists"

            $policy.ContainsKey('PerformanceClaim') |
                Should -BeTrue `
                -Because "$($policy.Id) must make its performance claim explicit"

            @($policy.Editions).Count |
                Should -BeGreaterThan 0 `
                -Because "$($policy.Id) must declare supported editions"

            [string]::IsNullOrWhiteSpace([string]$policy.Key) |
                Should -BeFalse `
                -Because "$($policy.Id) must declare a state path"

            [string]::IsNullOrWhiteSpace([string]$policy.ValueName) |
                Should -BeFalse `
                -Because "$($policy.Id) must declare a value name"

            if ($policy.Mechanism -eq 'LGPO') {
                $policy.Key |
                    Should -Match '^SOFTWARE\\Policies\\' `
                    -Because "$($policy.Id) is declared as policy-backed"
            }
        }
    }

    It 'uses direct preferences only for the intentionally small preference set' {
        $preferences = @(
            $script:Policies |
            Where-Object { $_.Mechanism -eq 'Preference' }
        )

        @($preferences | ForEach-Object { $_.Id }) |
            Should -Contain 'gaming.game-mode'

        @($preferences | ForEach-Object { $_.Id }) |
            Should -Contain 'qol.file-extensions'

        $preferences.Count | Should -Be 2
    }
}
