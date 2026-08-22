# Windows Gaming Reference Configuration

**A Microsoft-native Windows 11 reference configuration for a purpose-built PC gaming system.**

WGRC is my personal answer to a simple question:

> What would I want Windows to look like if the machine existed primarily to play PC games, and I cared as much about supportability, recovery, security and operational discipline as I did about performance?

This repository documents the configuration I use as a starting point on my personal Lenovo Legion 9 16IRX8 with an Intel Core i9-13980HX and NVIDIA GeForce RTX 4090 Laptop GPU.

I previously worked at Microsoft, including as a member of the Microsoft Detection and Response Team (DART). That background influences the operating standard here: establish ground truth before mutation, scope changes narrowly, preserve rollback, fail safe, record what changed, and prove the postcondition.

This is the fun end of that discipline. It is a gaming PC, not an incident.

**This is a personal project. It is not an official Microsoft configuration, security baseline, product recommendation, or endorsement. It contains no proprietary Microsoft code, internal tooling, unpublished policy, confidential material, or non-public Microsoft documentation.**

Everything in WGRC is built from public Windows interfaces, public Microsoft tooling and public vendor packages.

## Design target

The reference machine has a deliberately narrow purpose:

**PC gaming + Discord + Microsoft 365 + normal web use.**

It is not a development workstation, AI workstation, DFIR workstation, homelab host, emulator box, benchmark appliance, or general-purpose tweak collection.

The desired experience is:

> **Sign in. See a quiet Windows desktop. Open Games. Pick a game. Play.**

I genuinely use Steam, Xbox / Game Pass, Ubisoft Connect, EA app, Epic Games Launcher and Battle.net. All six stay functional.

Playnite is the normal front door. Storefronts remain installed as supported backend dependencies rather than defining the experience of the PC.

## Microsoft-native by design

WGRC deliberately prefers Windows' own management and diagnostic surfaces.

| Need | WGRC mechanism |
|---|---|
| Operating system | Windows 11 25H2 |
| Orchestration | Inbox Windows PowerShell-compatible code |
| Application desired state | **Windows Package Manager, WinGet Configuration + DSC v3** |
| Microsoft gaming dependencies | **WinGet + Microsoft Store source** |
| Local policy | **Microsoft Security Compliance Toolkit / LGPO.exe** |
| Effective policy evidence | **gpresult** |
| Security health | Defender, Firewall, TPM, Secure Boot, BitLocker and Device Guard |
| Device health | Plug and Play PowerShell |
| Hardware reliability | Windows Event Log / WHEA-Logger |
| Package inventory | WinGet |
| Operation evidence | PowerShell transcript + structured JSON |
| Support bundle | Native PowerShell + Compress-Archive |

WGRC downloads `LGPO.exe` only from the official Microsoft Download Center URL configured in the repository. It verifies the binary's Microsoft Authenticode signature and records SHA-256/signing provenance before use.

WGRC does **not** use `Microsoft.Windows/Registry` DSC as its production policy engine. Microsoft currently documents that DSC v3 resource as proof-of-concept and says not to use it in production. ADMX-backed policy therefore flows through Microsoft's Security Compliance Toolkit / LGPO path.

## Core engineering rules

**Microsoft-supported mechanisms over registry folklore.**  
**Observation before mutation.**  
**Desired state over blind scripting.**  
**Game compatibility over process-count screenshots.**  
**Reversibility over aggression.**  
**Fail safe over "make it work somehow."**  
**Measurement over placebo.**  
**Curation over feature count.**

If Windows already performs a job well, WGRC uses Windows.

A third-party application earns permanent residence only when it closes a real capability gap:

- **mpv** for lightweight, configurable, high-quality media playback
- **7-Zip** for serious archive handling
- **Everything** for near-instant filename/path search
- **Microsoft PowerToys** for Run, Peek and PowerRename
- **Playnite** for one coherent game library across six ecosystems

## Absolutely no Windows advertising

WGRC's policy is:

> **No Windows promotional or advertising surface unless suppressing it would require breaking or patching a supported dependency.**

The reference policy disables, where the Windows edition supports it:

- Microsoft consumer experiences
- cloud-optimized consumer content
- cloud consumer-account-state content
- Windows Spotlight promotional surfaces
- Windows welcome promotion
- suggestions in Settings and notification surfaces
- third-party suggestions
- tailored experiences driven by diagnostic data
- Windows tips
- Windows Advertising ID
- Widgets/news
- Start Recommended content
- personalized website recommendations in Start
- account-related Start nags
- Search highlights
- web content in Windows Search

The bundled Microsoft Edge policy also suppresses:

- Microsoft content/feed on New Tab
- Shopping Assistant, coupon and price-comparison surfaces
- feature recommendation banners
- default top-site tiles
- first-run promotion

WGRC does not patch Steam, EA, Ubisoft, Epic, Battle.net, Xbox or Discord binaries, certificates, DNS or network traffic to remove commercial content. Their UI clients simply do not launch with Windows, and Playnite is the normal game-library experience.

Compatibility wins over ad-blocking hacks.

## Commands

### Observe

```powershell
.\WindowsGamingReference.ps1 Audit
.\WindowsGamingReference.ps1 Plan
.\WindowsGamingReference.ps1 Verify
```

`Audit` establishes current state. `Plan` shows exactly what would change. `Verify` checks the postcondition.

### Configure

```powershell
.\WindowsGamingReference.ps1 Apply
```

Apply requires elevation and refuses domain/Entra-joined machines by default.

Administrators who deliberately own that policy-conflict risk can override:

```powershell
.\WindowsGamingReference.ps1 Apply -AllowManagedDevice
```

### Restore

```powershell
.\WindowsGamingReference.ps1 Restore
```

Optional additive app rollback:

```powershell
.\WindowsGamingReference.ps1 Restore -RestorePackages
```

### Games

```powershell
.\WindowsGamingReference.ps1 Games
```

Performs a lightweight readiness check and opens Playnite. It does not dynamically "optimize" Windows every time you play.

### Microsoft policy tooling

```powershell
.\WindowsGamingReference.ps1 MicrosoftTools
```

Acquires Microsoft's LGPO utility from Microsoft's official Download Center, validates its Authenticode signature and records provenance under `%ProgramData%\WGRC\MicrosoftTools`.

Apply does this automatically when needed.

### Privacy-minimized support bundle

```powershell
.\WindowsGamingReference.ps1 Collect
```

or:

```powershell
.\WindowsGamingReference.ps1 Collect -OutputPath .\WGRC-Diagnostics.zip
```

The public support bundle excludes usernames, serial numbers, UUIDs, IP addresses, recovery material, account identifiers, launcher command paths and credentials by design.

## Apply sequence

```text
PREFLIGHT
→ MANAGEMENT-STATE CHECK
→ MICROSOFT TOOL VERIFICATION
→ STATE BACKUP
→ LOCAL GROUP POLICY
→ WINDOWS PREFERENCES
→ GPUPDATE
→ WINGET CONFIGURATION
→ MICROSOFT STORE GAMING SUBSTRATE
→ MICROSOFT OFFICE
→ LAUNCHER UI STARTUP CLEANUP
→ EFFECTIVE-POLICY SNAPSHOT
→ POSTCONDITION VERIFY
```

Before mutation WGRC records:

- Windows build and edition
- hardware state
- exact target policy/preference prior state
- targeted launcher startup state
- package state
- complete Local Group Policy backup through LGPO
- `gpresult` before state
- `winget export` package inventory
- LGPO SHA-256 and signer provenance
- operation correlation ID

Mutation operations also receive a PowerShell transcript.

## Application model

### Daily layer

- 7-Zip
- mpv
- Everything
- Microsoft PowerToys
- Playnite
- Discord
- Steam
- Xbox
- Ubisoft Connect
- EA app
- Epic Games Launcher
- Battle.net
- Microsoft 365
- required OEM hardware controls
- required GPU driver/control stack

### Launcher UIs do not start with Windows

WGRC targets known current-user `Run` entries for Steam, Discord, Ubisoft Connect, EA app UI, Epic and Battle.net.

It does **not** indiscriminately disable vendor services.

### Microsoft gaming substrate is protected

WGRC preserves/verifies:

- Microsoft Store
- Gaming Services
- Xbox Identity Provider
- Xbox Game Bar infrastructure
- GameInput
- WebView2
- DirectX
- Windows Update
- Bluetooth/HID/controller support

Removing gaming substrate for a prettier Apps list is considered a defect.

### Commissioning tools are not product features

WGRC does not install HWiNFO, MSI Afterburner/RTSS, OCCT, 3DMark, Cinebench or WizTree by default. They are useful when tuning or troubleshooting, not as permanent desktop furniture.

## Things WGRC will not do

WGRC does not, by default:

- disable Microsoft Defender
- disable SmartScreen
- disable Windows Firewall
- disable UAC
- disable Windows Update
- remove Microsoft Store, Gaming Services, Xbox Identity Provider, Game Bar or WebView2
- disable the page file
- remove arbitrary services to lower process count
- apply HPET or dynamic-tick hacks
- run permanent timer-resolution utilities
- apply generic TCP/Nagle/network "latency" recipes
- globally disable core parking or Intel E-cores
- install Process Lasso, ISLC, RAM cleaners, game boosters, registry cleaners or driver-updater utilities
- run remote code through `irm | iex`
- bypass WinGet package hashes
- silently trust downloaded executables
- modify UEFI/firmware automatically
- forge protected Windows default-app hashes
- patch Start or Explorer
- require a modified Windows ISO
- recommend Tiny11, AtlasOS, ReviOS, AME or similar Windows forks
- claim FPS gains without repeatable data

## Security is a gaming compatibility feature

The reference posture prefers UEFI, Secure Boot, TPM 2.0, Defender, SmartScreen, Firewall and supported Windows servicing.

WGRC reports VBS/Device Guard state but does not disable those protections as a generic FPS tweak.

WGRC also reports PnP problems, WHEA events since boot, pending reboot and high-refresh state where Windows exposes it.

A machine producing hardware errors is not "optimized."

## Managed Windows is out of bounds by default

WGRC checks Windows join state through Microsoft `dsregcmd` and CIM.

If the device is domain joined or Entra joined, Apply refuses by default. A personal gaming project should not silently compete with an employer's or school's policy.

## Performance claims

The first performance requirement is:

> **No repeatable gaming regression.**

A valid result may be:

> Average FPS unchanged. 1% lows unchanged. Login is quieter, advertising surfaces are gone, six launchers still work, Xbox/Game Pass still works, and Windows remains fully serviceable.

That is a success.

Any positive FPS claim must include raw methodology and results under `benchmarks/`.

## v1 release gate

`1.0` does not exist until a clean Windows 11 25H2 system passes this sequence twice:

```text
STOCK
→ Audit
→ Plan
→ Apply
→ reboot
→ Verify
→ six-ecosystem compatibility matrix
→ DX11 / DX12 / Vulkan / controller / HDR / VRR checks
→ representative anti-cheat checks
→ benchmark suite
→ Restore
→ reboot
→ repeat
```

Release requires all six launchers, Store/Gaming Services, Windows Update and Windows security to remain healthy, with no WGRC-introduced PnP problems and no repeatable gaming-performance regression.

## Reference machine

Initial development and validation target:

- Lenovo Legion 9 16IRX8 / 83AG
- Intel Core i9-13980HX
- NVIDIA GeForce RTX 4090 Laptop GPU, 16 GB
- 3200 × 2000 Mini LED, 165 Hz
- Windows 11 Enterprise 25H2

Lenovo-specific behavior is isolated under `hardware/lenovo-legion-9-16irx8/`. The generic configuration does not call undocumented Lenovo embedded-controller or hidden firmware APIs.

## Repository map

```text
.config/
    configuration.winget
    office.winget

configuration/
    defaults.psd1
    policies.psd1
    packages.psd1
    launchers.psd1

src/
    WGRC.Core.psm1
    WGRC.Microsoft.ps1
    Audit.ps1
    Plan.ps1
    Apply.ps1
    Verify.ps1
    Restore.ps1
    Games.ps1
    Collect.ps1
    MicrosoftTools.ps1

hardware/
    lenovo-legion-9-16irx8/

docs/
benchmarks/
tests/
.github/
```

## Documentation

- [Engineering discipline](docs/engineering-discipline.md)
- [Microsoft-native architecture](docs/microsoft-native.md)
- [Security baseline relationship](docs/security-baseline.md)
- [Philosophy](docs/philosophy.md)
- [Supported Windows](docs/supported-windows.md)
- [Gaming compatibility](docs/compatibility.md)
- [No Advertising](docs/no-advertising.md)
- [Privacy](docs/privacy.md)
- [Gaming settings](docs/gaming-settings.md)
- [First-run commissioning](docs/first-run.md)
- [Rollback](docs/rollback.md)
- [Threat model](docs/threat-model.md)
- [Diagnostics](docs/diagnostics.md)
- [Release integrity](docs/release-integrity.md)
- [Application curation](docs/applications.md)
- [Performance](docs/performance.md)
- [Limitations](docs/limitations.md)
- [FAQ](docs/reddit-faq.md)

## Trust

Do not run WGRC because it has a GitHub URL or because the author once worked at Microsoft.

Read `Plan`. Read `configuration/policies.psd1`. Read the WinGet Configuration. Verify release integrity. Understand the tradeoffs.

That is the standard this project is trying to encourage.

**Current version: `0.1`**

MIT licensed.
