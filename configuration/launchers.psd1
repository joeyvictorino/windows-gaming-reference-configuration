@{
    AutoStartMatchers = @(
        @{ Name='Steam'; Patterns=@('steam.exe') },
        @{ Name='Discord'; Patterns=@('discord.exe','\discord\update.exe','--processStart Discord.exe') },
        @{ Name='Epic Games Launcher'; Patterns=@('epicgameslauncher.exe') },
        @{ Name='Ubisoft Connect'; Patterns=@('ubisoftconnect.exe','upc.exe') },
        @{ Name='EA app UI'; Patterns=@('eadesktop.exe','ealauncher.exe') },
        @{ Name='Battle.net'; Patterns=@('battle.net.exe','battle.net launcher.exe') }
    )
}
