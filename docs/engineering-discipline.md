# Engineering discipline

WGRC is a hobby project, but it uses a serious operational standard.

The approach is influenced by the habits that matter in high-consequence Windows response work, including the GHOST/DART style of disciplined execution. It does not reproduce Microsoft internal tooling or private procedures.

## 1. Establish ground truth

`Audit` exists before `Apply`.

The project does not make a change merely because a setting appears in a list.

## 2. Separate observation from mutation

`Audit`, `Plan` and `Verify` do not configure the machine.

An operator should be able to understand state and proposed changes before elevation is necessary.

## 3. Scope narrowly

WGRC is for a gaming PC.

It does not attempt to become:

- an enterprise security baseline
- a privacy-hardening distro
- a developer bootstrap
- a server baseline
- a Windows replacement shell
- a benchmarking toolkit

Narrow scope is a reliability feature.

## 4. Preserve rollback before mutation

Before Apply:

- Local Group Policy is backed up through Microsoft LGPO
- target values are captured individually
- launcher startup state is captured
- relevant package state is captured
- WinGet inventory is exported
- gpresult is captured

Rollback is part of the design, not a README footnote.

## 5. Fail safe

Examples:

- unsupported Windows release: stop
- managed Windows device: stop by default
- invalid LGPO Authenticode signature: stop
- invalid WinGet Configuration: stop
- package hash mismatch: do not bypass
- unavailable optional Office package: warn, do not corrupt gaming state

## 6. Preserve dependencies

A component is not "bloat" because its purpose is invisible.

WGRC preserves:

- Store
- Gaming Services
- GameInput
- WebView2
- Game Bar infrastructure
- Windows Update
- Windows Error Reporting
- Windows security components
- vendor services needed by game launchers

## 7. Record intent and outcome

Each policy declares:

- ID
- mechanism
- scope
- supported editions/build
- desired state
- reason
- performance claim
- source

The operation has a correlation ID and transcript.

## 8. Verify the postcondition

"PowerShell exited zero" is not the acceptance criterion.

WGRC verifies:

- required apps
- Xbox gaming substrate
- policy state
- launcher startup
- Secure Boot/TPM state
- Defender/Firewall
- PnP health
- WHEA
- pending reboot
- high-refresh state

## 9. Distinguish readiness from perfection

`READY TO GAME` means there is no blocking gaming dependency failure.

`REFERENCE PASS` is stricter and requires zero WGRC warnings.

That distinction prevents a cosmetic or security warning from being misrepresented as a broken game stack.

## 10. No hidden expertise

The author's Microsoft background explains the engineering preferences. It is not used as an authority shortcut.

Every public default should survive scrutiny on its own documentation and behavior.
