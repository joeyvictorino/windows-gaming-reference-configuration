@{
    Packages = @(
        @{ Id='7zip.7zip'; Name='7-Zip'; Source='winget'; Tier='Core'; RequiredForReady=$true; Reason='Focused archive support.' },
        @{ Id='shinchiro.mpv'; Name='mpv'; Source='winget'; Tier='Core'; RequiredForReady=$true; Reason='Lightweight high-quality media playback.' },
        @{ Id='voidtools.Everything'; Name='Everything'; Source='winget'; Tier='Core'; RequiredForReady=$true; Reason='Near-instant local filename search.' },
        @{ Id='Microsoft.PowerToys'; Name='Microsoft PowerToys'; Source='winget'; Tier='Core'; RequiredForReady=$true; Reason='Run, Peek and PowerRename QoL layer.' },
        @{ Id='Playnite.Playnite'; Name='Playnite'; Source='winget'; Tier='Gaming'; RequiredForReady=$true; Reason='Unified front end for game libraries.' },
        @{ Id='Discord.Discord'; Name='Discord'; Source='winget'; Tier='Gaming'; RequiredForReady=$true; Reason='Gaming communications.' },
        @{ Id='Valve.Steam'; Name='Steam'; Source='winget'; Tier='Launcher'; RequiredForReady=$true; Reason='Steam ecosystem.' },
        @{ Id='ElectronicArts.EADesktop'; Name='EA app'; Source='winget'; Tier='Launcher'; RequiredForReady=$true; Reason='EA ecosystem.' },
        @{ Id='EpicGames.EpicGamesLauncher'; Name='Epic Games Launcher'; Source='winget'; Tier='Launcher'; RequiredForReady=$true; Reason='Epic ecosystem.' },
        @{ Id='Ubisoft.Connect'; Name='Ubisoft Connect'; Source='winget'; Tier='Launcher'; RequiredForReady=$true; Reason='Ubisoft ecosystem. Never bypass WinGet hash failures.' },
        @{ Id='Blizzard.BattleNet'; Name='Battle.net'; Source='winget'; Tier='Launcher'; RequiredForReady=$true; Reason='Battle.net ecosystem.' },
        @{ Id='9MV0B5HZVK9Z'; Name='Xbox app'; Source='msstore'; Tier='Launcher'; RequiredForReady=$true; DetectionAppxPattern='*GamingApp*'; Reason='Xbox / Game Pass ecosystem.' },
        @{ Id='Microsoft.Office'; Name='Microsoft 365 / Office'; Source='winget'; Tier='Productivity'; RequiredForReady=$false; Reason='Reference-machine productivity requirement; not a gaming readiness blocker.' }
    )

    MicrosoftGamingSubstrate = @(
        @{ Id='9MWPM2CQNLHN'; Name='Gaming Services'; Source='msstore'; AppxPattern='*GamingServices*'; RequiredForReady=$true },
        @{ Id='9WZDNCRD1HKW'; Name='Xbox Identity Provider'; Source='msstore'; AppxPattern='*XboxIdentityProvider*'; RequiredForReady=$true },
        @{ Id='9NZKPSTSNW4P'; Name='Xbox Game Bar'; Source='msstore'; AppxPattern='*XboxGamingOverlay*'; RequiredForReady=$true }
    )
}
