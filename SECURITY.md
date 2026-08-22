# Security Policy

WGRC is privileged configuration code.

`Audit`, `Plan`, `Verify` and `Games` do not configure Windows.

`Apply`, `Restore` and `MicrosoftTools` can require elevation.

## Supply-chain rules

WGRC:

- does not use `Invoke-Expression`
- does not use `irm | iex`
- does not execute downloaded PowerShell scripts
- uses WinGet / Microsoft Store for application acquisition
- never uses WinGet package-hash override
- does not disable WinGet security controls
- treats installer hash mismatch as safe failure
- does not redistribute Microsoft's LGPO utility

## Microsoft LGPO trust

When LGPO is required WGRC:

1. requires HTTPS
2. requires the host to be exactly `download.microsoft.com`
3. downloads the official Security Compliance Toolkit LGPO archive
4. extracts the tool in a temporary directory
5. requires a Valid Authenticode signature
6. requires the signer to identify Microsoft Corporation
7. requires the file CompanyName to identify Microsoft
8. records archive SHA-256, binary SHA-256, signer subject and certificate thumbprint
9. copies the validated binary into `%ProgramData%\WGRC\MicrosoftTools`

Unexpected/unsigned policy tooling is rejected.

## Windows security invariants

Default WGRC does not:

- disable Defender
- disable SmartScreen
- disable Firewall
- disable UAC
- disable Windows Update
- remove Store/Gaming Services/Game Bar/WebView2
- disable Secure Boot/TPM/VBS
- delete Windows services
- modify boot timers
- disable cores
- disable pagefile

## Managed devices

Apply refuses domain/Entra-joined systems unless the administrator explicitly passes `-AllowManagedDevice`.

## Diagnostics privacy

`Collect` is designed for public issue triage and excludes credentials, tokens, recovery keys, usernames, serial/UUID, IP addresses and launcher command paths.

Users should still review the bundle before uploading it.

## Reporting a vulnerability

Use a private GitHub Security Advisory when disclosure would expose an unsafe code path or trust weakness.

Include:

- WGRC version/commit
- Windows build
- affected command
- expected behavior
- observed behavior
- reproduction steps

Do not include secrets.
