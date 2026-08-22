# Supported Windows

WGRC `0.1` targets **Windows 11 25H2 x64, build 26200+**.

The reference configuration is deliberately not a moving target. A Windows feature release must be reviewed and validated before it becomes a supported WGRC target.

## Edition behavior

WGRC detects:

- Core / Home
- Professional
- Enterprise
- Education
- N variants where policy metadata includes them

Every policy entry declares supported editions and a minimum build.

Unsupported policy is reported as `SKIP`. WGRC does not emulate Enterprise-only settings on Home/Pro through undocumented hacks.

The strongest No Ads policy surface is available on Enterprise/Education because Microsoft exposes more policy there.

## Managed devices

WGRC checks Windows join state with Microsoft `dsregcmd` and CIM.

If the machine is domain joined or Entra joined, `Apply` refuses by default.

This is not because WGRC cannot write local policy. It is because local hobby configuration should not silently compete with organization policy.

The explicit `-AllowManagedDevice` override exists for administrators who understand and own that conflict.

## Out of scope for 0.1

- Windows 10
- Windows 11 releases older than 25H2
- Windows 11 26H1 as a target for this reference platform
- Windows Server
- modified Windows images
- LTSC as the recommended general-purpose gaming base

WGRC does not convert Windows editions or modify licensing.
