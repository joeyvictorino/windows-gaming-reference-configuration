# Diagnostics

WGRC includes a privacy-minimized support bundle.

```powershell
.\WindowsGamingReference.ps1 Collect
```

The resulting ZIP contains structured state useful for GitHub issue triage.

## Included

- WGRC version
- Windows edition/release/build
- hardware model, CPU, RAM and GPU names
- BIOS version
- Secure Boot/TPM status
- Defender/Firewall state
- BitLocker protection state, but no recovery material
- Device Guard/VBS status
- PnP problems
- WHEA event summary since boot
- WGRC policy compliance
- WGRC package presence
- Xbox gaming-substrate presence
- targeted launcher auto-start names
- pending reboot
- WinGet version/info

## Excluded by default

- username
- email address
- Microsoft account identifiers
- device serial number
- hardware UUID
- IP addresses
- browser history
- saved credentials
- authentication tokens
- BitLocker recovery keys
- game-account details
- launcher command-line paths
- raw WHEA event XML

The bundle includes a privacy notice. Review it before uploading to a public issue.

This is a support artifact, not forensic collection.
