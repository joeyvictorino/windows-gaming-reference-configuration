# Microsoft-native architecture

WGRC intentionally minimizes its private control plane.

The project uses public Microsoft components for the jobs those components were designed to perform.

## Windows Package Manager

Application desired state lives in WinGet Configuration files using DSC v3 document format.

Primary configuration:

```text
.config/configuration.winget
```

Optional Microsoft Office configuration:

```text
.config/office.winget
```

WGRC enables the configuration components through Microsoft's own `winget configure --enable` switch during Apply, then invokes:

```text
winget configure validate
winget configure
winget configure test
```

instead of maintaining a custom package installer framework.

Microsoft documents WinGet Configuration as a reliable, repeatable way to define packages and machine state.

## Local Group Policy

ADMX-backed settings use **LGPO.exe** from the Microsoft Security Compliance Toolkit.

WGRC does not redistribute LGPO.exe.

On first Apply it:

1. downloads `LGPO.zip` from the official `download.microsoft.com` URL published for Microsoft's Security Compliance Toolkit
2. extracts the Microsoft LGPO binary
3. validates Authenticode signature status
4. verifies the signer identifies Microsoft Corporation
5. records SHA-256/provenance under `%ProgramData%\WGRC\MicrosoftTools`
6. uses LGPO text input to configure supported local policy

WGRC also asks LGPO to take a complete pre-change Local Group Policy backup.

## Why not Microsoft.Windows/Registry DSC?

DSC v3 includes a native `Microsoft.Windows/Registry` resource, but Microsoft currently labels that resource a **proof-of-concept** and explicitly says not to use it in production.

WGRC therefore does not use that resource as its policy engine.

Windows preferences that are not Group Policy are changed directly and backed up individually. That is a deliberately small exception rather than a generic "registry tweak engine."

## Effective policy

WGRC records `gpresult` before and after Apply.

That provides a Windows-native effective-policy artifact rather than assuming that a registry write necessarily represents final policy state.

## Security and system health

WGRC uses built-in Windows surfaces:

- `Confirm-SecureBootUEFI`
- `Get-Tpm`
- `Get-MpComputerStatus`
- `Get-NetFirewallProfile`
- `Get-BitLockerVolume`
- `Win32_DeviceGuard`
- `Get-PnpDevice`
- `Get-WinEvent` against `Microsoft-Windows-WHEA-Logger`
- `dsregcmd /status`

No third-party "system health" suite is required.

## Logging

Elevated mutation operations receive:

- correlation ID
- PowerShell transcript
- JSON state manifest
- policy backup
- package export
- effective-policy report

The result is deliberately closer to a controlled Windows change than a one-shot tweak script.
