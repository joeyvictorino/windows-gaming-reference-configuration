# FAQ / anticipated technical critique

## "Another debloat script?"

No.

WGRC does not optimize for the fewest processes, delete arbitrary AppX packages or disable a list of services copied from another machine.

`Audit` establishes state, `Plan` shows proposed changes, `Apply` uses supported mechanisms, and `Verify` tests the postcondition.

## "Why LGPO instead of hundreds of reg.exe commands?"

The settings classified as policy are ADMX-backed Windows/Edge policies.

WGRC uses Microsoft's **Local Group Policy Object Utility (LGPO.exe)** from the Security Compliance Toolkit to apply them and back up Local Group Policy first.

The registry is still how many policy settings are ultimately represented, but the project uses Microsoft's policy-management tool instead of pretending raw registry mutation is a configuration-management strategy.

## "Why not put all settings in DSC?"

Application desired state is in WinGet Configuration / DSC v3.

Microsoft currently marks the native DSC v3 `Microsoft.Windows/Registry` resource as proof-of-concept and says not to use it in production, so WGRC does not make that resource its policy engine.

## "Why download an EXE during Apply?"

WGRC does not redistribute Microsoft's LGPO binary.

It downloads the official Security Compliance Toolkit archive from the pinned `download.microsoft.com` host, requires a valid Microsoft Authenticode signature and records binary/archive SHA-256 plus signer information before use.

You can acquire it separately first with:

```powershell
.\WindowsGamingReference.ps1 MicrosoftTools
```

## "Why not Tiny11, AtlasOS, ReviOS, AME or LTSC?"

The target is a mainstream, serviceable Windows gaming system with broad launcher, Store, driver and anti-cheat compatibility.

WGRC configures Windows instead of replacing it with a custom Windows distribution.

## "Why is Defender still on?"

Disabling Defender is not a universal gaming optimization.

A security change that matters to a particular workload belongs in a controlled experiment with measured evidence, not the default reference state.

## "Why keep Store, Xbox components, Game Bar and WebView2?"

Because modern Windows games and launchers depend on that substrate.

Removing dependencies to make Installed Apps look shorter is contrary to the project goal.

## "Why not disable 150 services?"

Because service/process count is not a performance metric.

Modern Windows services are trigger-started, shared and dependency-sensitive. WGRC changes behavior only when there is a specific problem to solve.

## "Why Required diagnostic data instead of zero telemetry?"

Because the project prefers supported Windows policy, servicing and supportability over deleting diagnostic services or maintaining endpoint blocklists.

## "Why Windows Error Reporting?"

Because crashes are operational data.

WGRC keeps WER functional while restricting unsolicited additional data rather than destroying the diagnostic path.

## "Why Playnite?"

The reference machine genuinely uses Steam, Xbox, Ubisoft, EA, Epic and Battle.net. One library solves a real product-experience problem.

## "Why doesn't Games kill every background process before launch?"

Because that would turn a simple game launcher into a resident optimizer with hidden side effects.

WGRC commissions Windows into a good steady state. `Games` verifies a few obvious readiness conditions and opens Playnite.

## "What FPS gain do I get?"

No universal number is claimed.

The first release requirement is **no repeatable performance regression**. If a future change has a positive performance claim, raw runs and methodology belong in the repository.

## "Why mention Microsoft/DART?"

It explains the operating philosophy, not authority.

The repository explicitly contains no confidential Microsoft material or internal tooling. Every default is expected to stand on public documentation, observable behavior and its own rollback path.
