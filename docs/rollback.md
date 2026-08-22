# Rollback

Rollback is created before mutation.

Default backup location:

```text
%ProgramData%\WGRC\Backups\<timestamp>-<correlation-id>\
```

## Captured before Apply

WGRC records:

- structured `state.json`
- exact targeted policy/preference prior state
- targeted launcher `Run` entries
- presence of WGRC-managed applications
- complete Local Group Policy backup through Microsoft LGPO
- `gpresult-before.html`
- `winget-before.json`
- LGPO SHA-256
- Windows/hardware state
- operation correlation ID

After policy application WGRC also records `gpresult-after.html`.

## Configuration restore

```powershell
.\WindowsGamingReference.ps1 Restore
```

By default WGRC selects the newest backup.

To choose one:

```powershell
.\WindowsGamingReference.ps1 Restore `
  -BackupPath 'C:\ProgramData\WGRC\Backups\<backup>\state.json'
```

### Policy restore

Preferred restore path:

1. initialize/verify Microsoft LGPO
2. generate LGPO text representing the exact previous state of every WGRC policy
3. restore previous values
4. issue `DELETE` for settings that were previously Not Configured
5. refresh Group Policy

The complete pre-change LGPO backup is retained as an additional recovery/evidence artifact.

If Microsoft LGPO cannot be initialized during Restore, WGRC falls back to the individually saved registry state. Apply itself does not use that fallback.

## Preference restore

Non-policy Windows preferences such as Game Mode/file-extension display are restored from their exact pre-change state.

## Launcher startup restore

Targeted `HKCU\...\Run` entries removed by Apply are recreated from the backup.

A launcher may also recreate its own startup setting after it is manually launched. WGRC does not attempt to fight a vendor application continuously.

## Package rollback

Normal Restore leaves applications installed because uninstall can alter user data/state.

Explicit additive rollback:

```powershell
.\WindowsGamingReference.ps1 Restore -RestorePackages
```

This removes ordinary packages that:

- were absent before that Apply
- were installed by that Apply
- are listed in the Apply manifest

WGRC does not automatically remove Microsoft gaming substrate during rollback.
