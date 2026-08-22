# Relationship to Microsoft security baselines

WGRC is **not** a replacement for the Microsoft Windows security baseline.

Microsoft publishes Windows security baselines and tooling through the Security Compliance Toolkit (SCT). The same toolkit contains:

- Windows 11 security baseline packages
- Policy Analyzer
- LGPO
- Microsoft 365 Apps baseline
- Microsoft Edge baseline

WGRC uses the SCT's LGPO utility as its local-policy mechanism because it is a Microsoft tool designed for local Group Policy work.

## Why WGRC does not blindly apply the entire security baseline

A Microsoft security baseline is built for broad enterprise security management, not specifically for a personal gaming appliance.

WGRC therefore:

- preserves Windows security defaults
- does not weaken Defender/SmartScreen/Firewall/servicing
- uses the security baseline as a comparison/reference point
- applies only gaming/quiet/privacy policy that is in project scope
- separately tests game/launcher/anti-cheat compatibility

The professional answer is not "security baseline bad" or "apply every baseline setting to everything."

The answer is to understand the role of each baseline and test the intended workload.

## Policy Analyzer

For deeper review, maintainers can use Microsoft's Policy Analyzer to compare:

- Microsoft Windows 11 25H2 baseline
- WGRC local policy
- current local machine policy

That comparison is intentionally an engineering/maintainer workflow, not a prerequisite for somebody who just wants to play games.
