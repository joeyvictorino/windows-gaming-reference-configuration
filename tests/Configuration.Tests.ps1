Describe 'Gaming application desired state' {

    BeforeAll {
        $script:Root = Split-Path $PSScriptRoot -Parent
        $script:PackageData = Import-PowerShellDataFile (
            Join-Path $script:Root 'configuration\packages.psd1'
        )
        $script:PackageIds = @(
            $script:PackageData.Packages |
            ForEach-Object { $_.Id }
        )
        $script:ConfigText = Get-Content (
            Join-Path $script:Root '.config\configuration.winget'
        ) -Raw
    }

    It 'has unique package IDs' {
        @($script:PackageIds | Select-Object -Unique).Count |
            Should -Be $script:PackageIds.Count
    }

    It 'contains all six ecosystems' {
        $script:PackageIds | Should -Contain 'Valve.Steam'
        $script:PackageIds | Should -Contain '9MV0B5HZVK9Z'
        $script:PackageIds | Should -Contain 'Ubisoft.Connect'
        $script:PackageIds | Should -Contain 'ElectronicArts.EADesktop'
        $script:PackageIds | Should -Contain 'EpicGames.EpicGamesLauncher'
        $script:PackageIds | Should -Contain 'Blizzard.BattleNet'
    }

    It 'contains the curated front end and QoL layer' {
        $script:PackageIds | Should -Contain 'Playnite.Playnite'
        $script:PackageIds | Should -Contain 'shinchiro.mpv'
        $script:PackageIds | Should -Contain '7zip.7zip'
        $script:PackageIds | Should -Contain 'voidtools.Everything'
        $script:PackageIds | Should -Contain 'Microsoft.PowerToys'
    }

    It 'defines Microsoft gaming substrate separately' {
        @($script:PackageData.MicrosoftGamingSubstrate).Count |
            Should -BeGreaterOrEqual 3
    }

    It 'uses WinGet Configuration v3 for third-party desired state' {
        $script:ConfigText | Should -Match 'identifier:\s*dscv3'
        $script:ConfigText | Should -Match 'Microsoft\.WinGet/Package'
    }

    It 'does not use the proof-of-concept DSC registry resource' {
        $script:ConfigText | Should -Not -Match 'Microsoft\.Windows/Registry'
    }
}
