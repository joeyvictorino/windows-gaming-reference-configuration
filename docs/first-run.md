# First-run finishing checklist

WGRC automates only choices that can be changed through stable, supported mechanisms.

After `Apply` and one reboot:

1. Run `.\WindowsGamingReference.ps1 Verify`.
2. If Secure Boot is reported off, confirm BitLocker/device-encryption recovery-key access and enable Secure Boot through the system firmware. WGRC never automates firmware.
3. Set the panel to its intended high refresh rate.
4. Verify Windows Graphics settings:
   - Game Mode on
   - Hardware-accelerated GPU scheduling according to the current supported/default state for the GPU
   - Optimizations for windowed games enabled unless a specific game needs an exception
5. Verify VRR/G-SYNC/FreeSync through the GPU vendor's supported control surface.
6. Set **mpv** as the default video player in Settings > Apps > Default apps.
7. Open PowerToys and retain the reference modules you actually use:
   - PowerToys Run
   - Peek
   - PowerRename
8. Open Playnite, authenticate/import:
   - Steam
   - Xbox / Game Pass
   - Ubisoft Connect
   - EA app
   - Epic Games Launcher
   - Battle.net
9. Configure Playnite around games rather than storefronts. Recommended top-level views:
   - Installed
   - Recently Played
   - Favorites
   - All Games
10. Pin Playnite as **Games** if desired.
11. Disable marketing/store notifications inside third-party launchers where each launcher exposes a normal user setting. WGRC does not patch proprietary clients.
12. On a gaming laptop, use the OEM-supported Performance mode while plugged in.
13. Launch one game from each ecosystem before declaring the machine commissioned.

The intended result is: sign in to a quiet native Windows desktop, open **Games**, pick a title, play.
