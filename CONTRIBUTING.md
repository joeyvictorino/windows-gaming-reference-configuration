# Contributing

WGRC is intentionally conservative.

A contribution should make a Windows gaming PC more coherent, supportable, compatible or measurably better without expanding the control plane unnecessarily.

## Required for a new default

Every default change must state:

1. concrete user problem
2. supported Microsoft/vendor mechanism
3. supported Windows editions/builds
4. current-state test
5. desired state
6. rollback
7. postcondition verification
8. primary public documentation
9. gaming compatibility impact
10. performance claim, defaulting to `None`

## Mechanism preference order

Prefer:

1. documented Windows policy through Microsoft LGPO / Group Policy
2. Windows Settings or documented Windows preference
3. WinGet Configuration / Microsoft Store
4. vendor-supported application setting
5. custom PowerShell only for orchestration, evidence and rollback

Avoid inventing a new framework when Windows already has one.

## Default changes will normally be rejected if they

- disable Windows services to reduce process count
- weaken security controls as a generic FPS optimization
- remove Store/Gaming Services/WebView2
- use HPET/timer/network folklore
- bypass package integrity
- patch Explorer/Start
- forge protected default-app hashes
- download/execute scripts from the internet
- add a permanent resident utility without a real capability gap
- convert a personal preference into a universal default

## Tests

```powershell
Invoke-Pester .\tests

Invoke-ScriptAnalyzer -Path . -Recurse `
  -Settings .\PSScriptAnalyzerSettings.psd1
```

CI also parses scripts with inbox Windows PowerShell and validates WinGet Configuration files on a Windows runner.

## Microsoft background

The repository may discuss the author's prior Microsoft/DART background as context for the operating standard.

Contributions must not include Microsoft confidential material, internal tools, unpublished procedures, customer data or proprietary code.
