$root = Split-Path $PSScriptRoot -Parent
$data = Import-PowerShellDataFile (Join-Path $root 'configuration\packages.psd1')
$ids = @($data.Packages | ForEach-Object Id)
$configText = Get-Content (Join-Path $root '.config\configuration.winget') -Raw

Describe 'Gaming application desired state' {
    It 'has unique package IDs' {
        @($ids | Select-Object -Unique).Count | Should -Be $ids.Count
    }

    It 'contains all six ecosystems' {
        $ids | Should -Contain 'Valve.Steam'
        $ids | Should -Contain '9MV0B5HZVK9Z'
        $ids | Should -Contain 'Ubisoft.Connect'
        $ids | Should -Contain 'ElectronicArts.EADesktop'
        $ids | Should -Contain 'EpicGames.EpicGamesLauncher'
        $ids | Should -Contain 'Blizzard.BattleNet'
    }

    It 'contains the curated front end and QoL layer' {
        $ids | Should -Contain 'Playnite.Playnite'
        $ids | Should -Contain 'shinchiro.mpv'
        $ids | Should -Contain '7zip.7zip'
        $ids | Should -Contain 'voidtools.Everything'
        $ids | Should -Contain 'Microsoft.PowerToys'
    }

    It 'defines Microsoft gaming substrate separately' {
        @($data.MicrosoftGamingSubstrate).Count | Should -BeGreaterOrEqual 3
    }

    It 'uses WinGet Configuration v3 for the third-party desired state' {
        $configText | Should -Match 'identifier:\s*dscv3'
        $configText | Should -Match 'Microsoft\.WinGet/Package'
    }

    It 'does not use the proof-of-concept DSC registry resource' {
        $configText | Should -Not -Match 'Microsoft\.Windows/Registry'
    }
}
