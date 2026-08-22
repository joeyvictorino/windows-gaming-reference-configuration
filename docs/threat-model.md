# Threat model

WGRC changes a Windows gaming PC and `Apply` / `Restore` can run elevated.

The repository is therefore treated as privileged configuration code.

## Threat: malicious or replaced Microsoft policy tool

Mitigations:

- LGPO is downloaded from the fixed official `download.microsoft.com` URL used by Microsoft's Security Compliance Toolkit
- WGRC extracts the tool into a temporary directory
- LGPO must have a **Valid** Authenticode signature
- the signing certificate subject must identify Microsoft Corporation
- the file version company must identify Microsoft
- SHA-256 and source URL are recorded in `provenance.json`
- unsigned/unexpected LGPO is rejected

## Threat: malicious package source or replaced installer

Mitigations:

- WinGet Configuration / WinGet are used for package acquisition
- Microsoft Store source is used for Xbox gaming dependencies
- WGRC never enables WinGet installer-hash override
- WGRC never retries with `--ignore-security-hash`
- a hash mismatch is treated as safe failure

## Threat: remote code execution through bootstrap convenience

Mitigations:

- no `irm | iex`
- no `Invoke-Expression`
- no downloaded PowerShell scripts are executed
- Microsoft LGPO is a downloaded binary with Authenticode verification, not piped content

## Threat: corporate/managed-device policy conflict

Mitigations:

- detect domain/Entra join state through `dsregcmd`/CIM
- refuse Apply by default
- explicit administrator override required

## Threat: Xbox / Game Pass breakage

Mitigations:

- Store preserved
- Gaming Services preserved/repaired
- Xbox Identity Provider preserved/repaired
- Game Bar preserved/repaired
- no blanket AppX removal
- compatibility matrix required before v1

## Threat: "performance" changes that degrade reliability/security

Mitigations:

- no default HPET/timer/network/core-parking recipes
- no default security-control disable
- performance claims require A/B evidence
- WHEA and PnP health are part of Verify

## Threat: privacy leakage in public issue diagnostics

Mitigations:

`Collect` excludes by default:

- username
- device serial/UUID
- IP addresses
- account identifiers
- recovery keys
- credentials/tokens
- launcher command paths
- raw event-log XML

Users are told to review the ZIP before posting it.

## Threat: configuration drift

Mitigations:

- Audit before Apply
- Plan before Apply
- WinGet desired state
- explicit policy state
- backups
- gpresult evidence
- Verify
- repeatable Restore/Apply release gate
