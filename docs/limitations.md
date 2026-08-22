# Limitations

WGRC intentionally leaves these manual/vendor-managed:

- UEFI Secure Boot
- OEM thermal/performance modes
- MUX/Advanced Optimus
- protected default-app associations
- taskbar pin layout
- game-launcher authentication
- Playnite library authentication
- PowerToys module selection
- per-game GPU settings
- overclock/undervolt

Vendor installer manifests can temporarily fail WinGet hash validation. WGRC treats that as a safe failure and never uses `--ignore-security-hash`.

Some No Ads policies are edition-specific. WGRC prints `SKIP` instead of forcing unsupported equivalents.
