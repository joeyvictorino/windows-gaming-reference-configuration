# Gaming settings

WGRC deliberately distinguishes between settings that are safe, generic defaults and settings that should remain hardware/workload dependent.

## Applied by WGRC

- Windows Game Mode: enabled

## Preserved

- Microsoft Store
- Gaming Services
- Xbox Identity Provider
- Xbox Game Bar infrastructure
- GameInput
- WebView2
- DirectX
- Windows Update
- Defender / SmartScreen / Firewall
- Bluetooth / HID/controller support

## Verify manually on a modern gaming PC

These remain under Windows/vendor-supported UI because forcing them through undocumented or brittle registry state is not appropriate for a public reference configuration:

- Hardware-accelerated GPU scheduling (HAGS)
- Optimizations for windowed games
- Variable refresh rate / G-SYNC / FreeSync
- HDR
- intended high refresh rate
- OEM laptop thermal/performance mode
- Advanced Optimus / MUX / dGPU mode
- per-game NVIDIA/AMD settings

The recommended starting point for a current high-end Windows 11 gaming PC is to use the operating system and GPU vendor defaults, then change one variable only when a game or repeatable benchmark gives a reason.

## Background capture

WGRC does not rip out Game Bar or Xbox gaming infrastructure.

If you do not use background gameplay recording, turn background capture off in the Windows Gaming settings. This keeps the feature available without deleting dependencies.

## HAGS and security

WGRC does not claim that HAGS, VBS/HVCI, or any other scheduler/security toggle has a universal gaming result.

If a setting is performance-sensitive on a particular system, benchmark it under the methodology in `benchmarks/methodology.md` and document the result rather than converting a machine-specific observation into a global default.
