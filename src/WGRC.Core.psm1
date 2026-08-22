Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'WGRC.Microsoft.ps1')

function Write-WgrcHeading {
    param([Parameter(Mandatory)][string]$Text)
    Write-Host ''
    Write-Host "== $Text ==" -ForegroundColor Cyan
}

function Test-WgrcAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-WgrcAdministrator {
    if (-not (Test-WgrcAdministrator)) {
        throw 'This command requires an elevated PowerShell session.'
    }
}

function Get-WgrcConfig {
    param([Parameter(Mandatory)][string]$Root)

    return @{
        Defaults = Import-PowerShellDataFile (Join-Path $Root 'configuration\defaults.psd1')
        PolicyData = Import-PowerShellDataFile (Join-Path $Root 'configuration\policies.psd1')
        PackageData = Import-PowerShellDataFile (Join-Path $Root 'configuration\packages.psd1')
        LauncherData = Import-PowerShellDataFile (Join-Path $Root 'configuration\launchers.psd1')
    }
}

function Get-WgrcPlatform {
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $gpus = @(
        Get-CimInstance Win32_VideoController |
        Select-Object Name, DriverVersion, CurrentHorizontalResolution,
            CurrentVerticalResolution, CurrentRefreshRate
    )
    $bios = Get-CimInstance Win32_BIOS
    $currentVersion = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'

    $secureBoot = $null
    try { $secureBoot = [bool](Confirm-SecureBootUEFI -ErrorAction Stop) } catch {}

    $tpm = $null
    try { $tpm = Get-Tpm -ErrorAction Stop } catch {}

    return [pscustomobject]@{
        Caption = $os.Caption
        Version = $os.Version
        Build = [int]$currentVersion.CurrentBuildNumber
        DisplayVersion = $currentVersion.DisplayVersion
        Edition = $currentVersion.EditionID
        Manufacturer = $cs.Manufacturer
        Model = $cs.Model
        SystemFamily = $cs.SystemFamily
        SystemSKU = $cs.SystemSKUNumber
        CPU = $cpu.Name
        RAMGB = [math]::Round($cs.TotalPhysicalMemory / 1GB)
        GPUs = $gpus
        BIOS = $bios.SMBIOSBIOSVersion
        LastBootUpTime = $os.LastBootUpTime
        SecureBoot = $secureBoot
        TpmPresent = if ($tpm) { [bool]$tpm.TpmPresent } else { $null }
        TpmReady = if ($tpm) { [bool]$tpm.TpmReady } else { $null }
    }
}

function Test-WgrcSupportedPlatform {
    param(
        [Parameter(Mandatory)]$Platform,
        [Parameter(Mandatory)]$Defaults
    )

    return (
        ($Platform.Caption -like '*Windows 11*') -and
        ($Platform.DisplayVersion -eq $Defaults.SupportedDisplayVersion) -and
        ($Platform.Build -ge [int]$Defaults.MinimumBuild)
    )
}

function Test-WgrcPolicySupported {
    param(
        [Parameter(Mandatory)]$Policy,
        [Parameter(Mandatory)]$Platform
    )

    return (
        ($Policy.Editions -contains $Platform.Edition) -and
        ($Platform.Build -ge [int]$Policy.MinBuild)
    )
}

function Get-WgrcRegistryPath {
    param([Parameter(Mandatory)]$Policy)

    if ($Policy.Scope -eq 'Machine') {
        return "Registry::HKEY_LOCAL_MACHINE\$($Policy.Key)"
    }

    return "Registry::HKEY_CURRENT_USER\$($Policy.Key)"
}

function Get-WgrcRegistryState {
    param([Parameter(Mandatory)]$Policy)

    $path = Get-WgrcRegistryPath -Policy $Policy
    $keyExists = Test-Path $path
    $valueExists = $false
    $value = $null
    $kind = $null

    if ($keyExists) {
        try {
            $key = Get-Item $path -ErrorAction Stop
            $value = $key.GetValue(
                $Policy.ValueName,
                $null,
                [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
            )

            if ($null -ne $value) {
                $valueExists = $true
                $kind = $key.GetValueKind($Policy.ValueName).ToString()
            }
        } catch {}
    }

    return [pscustomobject]@{
        KeyExists = $keyExists
        ValueExists = $valueExists
        Value = $value
        Kind = $kind
        Compliant = ($valueExists -and ([string]$value -eq [string]$Policy.Desired))
    }
}

function Set-WgrcPreference {
    param([Parameter(Mandatory)]$Policy)

    if ($Policy.Mechanism -ne 'Preference') {
        throw "Set-WgrcPreference received non-preference setting: $($Policy.Id)"
    }

    $path = Get-WgrcRegistryPath -Policy $Policy
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }

    $propertyType = switch ($Policy.Type) {
        'DWord' { 'DWord' }
        'QWord' { 'QWord' }
        default { 'String' }
    }

    New-ItemProperty -Path $path -Name $Policy.ValueName -Value $Policy.Desired `
        -PropertyType $propertyType -Force | Out-Null
}

function Restore-WgrcPreferenceState {
    param([Parameter(Mandatory)]$Entry)

    $path = if ($Entry.Scope -eq 'Machine') {
        "Registry::HKEY_LOCAL_MACHINE\$($Entry.Key)"
    } else {
        "Registry::HKEY_CURRENT_USER\$($Entry.Key)"
    }

    if ($Entry.ValueExists) {
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }

        $type = switch ([string]$Entry.Kind) {
            'DWord' { 'DWord' }
            'QWord' { 'QWord' }
            'ExpandString' { 'ExpandString' }
            'MultiString' { 'MultiString' }
            default { 'String' }
        }

        New-ItemProperty -Path $path -Name $Entry.ValueName -Value $Entry.Value `
            -PropertyType $type -Force | Out-Null
    }
    elseif (Test-Path $path) {
        Remove-ItemProperty -Path $path -Name $Entry.ValueName -ErrorAction SilentlyContinue
    }
}

function Get-WgrcPackageInstalled {
    param([Parameter(Mandatory)]$Package)

    if ($Package.ContainsKey('DetectionAppxPattern')) {
        return (@(
            Get-AppxPackage -Name $Package.DetectionAppxPattern -ErrorAction SilentlyContinue
        ).Count -gt 0)
    }

    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        return $false
    }

    $output = & winget.exe list --id $Package.Id --exact `
        --accept-source-agreements --disable-interactivity 2>$null | Out-String

    return (($LASTEXITCODE -eq 0) -and
            ($output -match [regex]::Escape($Package.Id)))
}

function Get-WgrcMicrosoftGamingSubstrateState {
    param([Parameter(Mandatory)]$Substrate)

    foreach ($item in $Substrate) {
        $present = @(
            Get-AppxPackage -Name $item.AppxPattern -ErrorAction SilentlyContinue
        ).Count -gt 0

        if (-not $present -and (Test-WgrcAdministrator)) {
            $present = @(
                Get-AppxPackage -AllUsers -Name $item.AppxPattern -ErrorAction SilentlyContinue
            ).Count -gt 0
        }

        [pscustomobject]@{
            Name = $item.Name
            Id = $item.Id
            Present = $present
            Required = [bool]$item.RequiredForReady
        }
    }
}

function Install-WgrcMicrosoftStorePackage {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name
    )

    Write-Host "Ensuring Microsoft Store package: $Name [$Id]"

    & winget.exe install --id $Id --exact --source msstore `
        --accept-source-agreements --accept-package-agreements `
        --disable-interactivity --silent

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "$Name failed to install through Microsoft Store/WinGet. Exit code: $LASTEXITCODE"
        return $false
    }

    return $true
}

function Initialize-WgrcWinGetConfiguration {
    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        throw 'Windows Package Manager (WinGet/App Installer) is required.'
    }

    # Microsoft exposes configuration-component enablement directly on winget.
    # This is the supported bootstrap for the WinGet Configuration processor.
    & winget.exe configure --enable | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "WinGet Configuration components could not be enabled. Exit code: $LASTEXITCODE"
    }
}

function Test-WgrcWinGetConfiguration {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        return $false
    }

    & winget.exe configure show -f $Path --disable-interactivity | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Invoke-WgrcWinGetConfiguration {
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$Optional
    )

    if (-not (Test-WgrcWinGetConfiguration -Path $Path)) {
        if ($Optional) {
            Write-Warning "Optional WinGet configuration failed resolution: $Path"
            return $false
        }
        throw "WinGet configuration failed resolution: $Path"
    }

    Write-Host "Applying WinGet Configuration: $Path" -ForegroundColor Cyan

    & winget.exe configure -f $Path `
        --accept-configuration-agreements `
        --disable-interactivity

    if ($LASTEXITCODE -ne 0) {
        if ($Optional) {
            Write-Warning "Optional WinGet Configuration returned exit code $LASTEXITCODE."
            return $false
        }

        Write-Warning "WinGet Configuration returned exit code $LASTEXITCODE. No package-integrity bypass will be attempted."
        return $false
    }

    return $true
}

function Test-WgrcWinGetDesiredState {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        return $null
    }

    & winget.exe configure test -f $Path --accept-configuration-agreements --disable-interactivity | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Get-WgrcLauncherRunEntries {
    param([Parameter(Mandatory)]$LauncherData)

    $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    if (-not (Test-Path $path)) { return @() }

    $properties = Get-ItemProperty $path
    $results = @()

    foreach ($property in $properties.PSObject.Properties) {
        if ($property.Name -like 'PS*') { continue }

        $value = [string]$property.Value

        foreach ($launcher in $LauncherData.AutoStartMatchers) {
            $matched = $false

            foreach ($pattern in $launcher.Patterns) {
                if ($value.IndexOf($pattern, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $matched = $true
                    break
                }
            }

            if ($matched) {
                $results += [pscustomobject]@{
                    Launcher = $launcher.Name
                    ValueName = $property.Name
                    ValueData = $value
                }
                break
            }
        }
    }

    return $results
}

function Disable-WgrcLauncherUiAutoStart {
    param([Parameter(Mandatory)]$LauncherData)

    $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    $entries = @(Get-WgrcLauncherRunEntries -LauncherData $LauncherData)

    foreach ($entry in $entries) {
        Write-Host "Disabling launcher UI auto-start: $($entry.Launcher) [$($entry.ValueName)]"
        Remove-ItemProperty -Path $path -Name $entry.ValueName -ErrorAction Stop
    }
}

function Restore-WgrcLauncherRunEntries {
    param([Parameter(Mandatory)]$Backup)

    $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }

    foreach ($entry in $Backup.LauncherRunEntries) {
        New-ItemProperty -Path $path -Name $entry.ValueName `
            -Value $entry.ValueData -PropertyType String -Force | Out-Null
    }
}

function Get-WgrcPendingReboot {
    foreach ($path in @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    )) {
        if (Test-Path $path) { return $true }
    }

    try {
        $sessionManager = Get-ItemProperty `
            'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' `
            -Name PendingFileRenameOperations -ErrorAction Stop

        if ($sessionManager.PendingFileRenameOperations) { return $true }
    } catch {}

    return $false
}

function Get-WgrcSecurityState {
    $defender = $null
    try {
        $status = Get-MpComputerStatus -ErrorAction Stop
        $defender = [pscustomobject]@{
            AntivirusEnabled = [bool]$status.AntivirusEnabled
            RealTimeProtectionEnabled = [bool]$status.RealTimeProtectionEnabled
            AntispywareEnabled = [bool]$status.AntispywareEnabled
        }
    } catch {}

    $firewall = @()
    try {
        $firewall = @(
            Get-NetFirewallProfile -ErrorAction Stop |
            Select-Object Name, Enabled
        )
    } catch {}

    return [pscustomobject]@{
        Defender = $defender
        Firewall = $firewall
    }
}

function Start-WgrcTranscript {
    param(
        [Parameter(Mandatory)]$Defaults,
        [Parameter(Mandatory)][string]$Operation,
        [Parameter(Mandatory)][string]$CorrelationId
    )

    try {
        $logRoot = Get-WgrcExpandedPath $Defaults.LogRoot
        New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
        $path = Join-Path $logRoot (
            "{0}-{1}-{2}.log" -f
            (Get-Date -Format 'yyyyMMdd-HHmmss'),
            $Operation,
            $CorrelationId
        )
        Start-Transcript -Path $path -Force | Out-Null
        return $path
    } catch {
        return $null
    }
}

function Stop-WgrcTranscriptSafe {
    param([string]$TranscriptPath)
    if ($TranscriptPath) {
        try { Stop-Transcript | Out-Null } catch {}
    }
}

function New-WgrcBackup {
    param(
        [Parameter(Mandatory)]$Config,
        [Parameter(Mandatory)]$Platform,
        [Parameter(Mandatory)][string]$LgpoExe,
        [Parameter(Mandatory)][string]$CorrelationId
    )

    $backupRoot = Get-WgrcExpandedPath $Config.Defaults.BackupRoot
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null

    $directory = Join-Path $backupRoot (
        "{0}-{1}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'), $CorrelationId
    )
    New-Item -ItemType Directory -Path $directory -Force | Out-Null

    $policyStates = @()
    foreach ($policy in $Config.PolicyData.Policies) {
        if (-not (Test-WgrcPolicySupported -Policy $policy -Platform $Platform)) { continue }

        $state = Get-WgrcRegistryState -Policy $policy
        $policyStates += [pscustomobject]@{
            Id = $policy.Id
            Mechanism = $policy.Mechanism
            Scope = $policy.Scope
            Key = $policy.Key
            ValueName = $policy.ValueName
            ValueExists = $state.ValueExists
            Value = $state.Value
            Kind = $state.Kind
        }
    }

    $launcherEntries = @(Get-WgrcLauncherRunEntries -LauncherData $Config.LauncherData)

    $packageStates = @()
    foreach ($package in $Config.PackageData.Packages) {
        $packageStates += [pscustomobject]@{
            Id = $package.Id
            Name = $package.Name
            Source = $package.Source
            InstalledBefore = [bool](Get-WgrcPackageInstalled -Package $package)
        }
    }

    $localPolicyBackup = Join-Path $directory 'LocalPolicy'
    Backup-WgrcLocalPolicy -LgpoExe $LgpoExe -Destination $localPolicyBackup

    Export-WgrcGpResult -Destination (Join-Path $directory 'gpresult-before.html')

    try {
        & winget.exe export -o (Join-Path $directory 'winget-before.json') `
            --include-versions --accept-source-agreements | Out-Null
    } catch {}

    $lgpoHash = (Get-FileHash -LiteralPath $LgpoExe -Algorithm SHA256).Hash

    $backup = [pscustomobject]@{
        Schema = 2
        ProjectVersion = $Config.Defaults.Version
        CorrelationId = $CorrelationId
        Created = (Get-Date).ToString('o')
        PolicyBackend = 'Microsoft Security Compliance Toolkit / LGPO'
        LgpoSHA256 = $lgpoHash
        Platform = $Platform
        Policies = $policyStates
        LauncherRunEntries = $launcherEntries
        Packages = $packageStates
        LocalPolicyBackup = $localPolicyBackup
    }

    $stateFile = Join-Path $directory 'state.json'
    $backup | ConvertTo-Json -Depth 10 | Set-Content -Path $stateFile -Encoding UTF8

    return $stateFile
}

function Get-WgrcLatestBackup {
    param([Parameter(Mandatory)]$Defaults)

    $backupRoot = Get-WgrcExpandedPath $Defaults.BackupRoot
    if (-not (Test-Path $backupRoot)) { return $null }

    $candidate = Get-ChildItem -Path $backupRoot -Directory |
        Sort-Object Name -Descending |
        Select-Object -First 1

    if (-not $candidate) { return $null }

    $stateFile = Join-Path $candidate.FullName 'state.json'
    if (Test-Path $stateFile) { return $stateFile }

    return $null
}

function Get-WgrcPlaynitePath {
    foreach ($candidate in @(
        (Join-Path $env:LOCALAPPDATA 'Playnite\Playnite.FullscreenApp.exe'),
        (Join-Path $env:LOCALAPPDATA 'Playnite\Playnite.DesktopApp.exe'),
        (Join-Path $env:ProgramFiles 'Playnite\Playnite.FullscreenApp.exe'),
        (Join-Path $env:ProgramFiles 'Playnite\Playnite.DesktopApp.exe')
    )) {
        if (Test-Path $candidate) { return $candidate }
    }

    return $null
}

function Write-WgrcPlatform {
    param([Parameter(Mandatory)]$Platform)

    Write-WgrcHeading 'Platform'
    Write-Host ("OS             {0}" -f $Platform.Caption)
    Write-Host ("Release        {0} build {1}" -f $Platform.DisplayVersion, $Platform.Build)
    Write-Host ("Edition        {0}" -f $Platform.Edition)
    Write-Host ("System         {0} {1}" -f $Platform.Manufacturer, $Platform.Model)
    Write-Host ("SKU            {0}" -f $Platform.SystemSKU)
    Write-Host ("CPU            {0}" -f $Platform.CPU)
    Write-Host ("RAM            {0} GB" -f $Platform.RAMGB)

    foreach ($gpu in $Platform.GPUs) {
        Write-Host ("GPU            {0}" -f $gpu.Name)
        if ($gpu.CurrentHorizontalResolution) {
            Write-Host (
                "Display        {0}x{1} @ {2} Hz" -f
                $gpu.CurrentHorizontalResolution,
                $gpu.CurrentVerticalResolution,
                $gpu.CurrentRefreshRate
            )
        }
    }

    Write-Host ("BIOS           {0}" -f $Platform.BIOS)

    $secureBootText = if ($null -eq $Platform.SecureBoot) {
        'Unknown'
    } elseif ($Platform.SecureBoot) {
        'On'
    } else {
        'OFF'
    }
    Write-Host ("Secure Boot    {0}" -f $secureBootText)
}

function Invoke-WgrcMicrosoftTools {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Root)

    Assert-WgrcAdministrator
    $config = Get-WgrcConfig -Root $Root
    $path = Initialize-WgrcMicrosoftPolicyTools -Defaults $config.Defaults
    Write-Host "Microsoft LGPO ready: $path" -ForegroundColor Green
    return $path
}

function Invoke-WgrcAudit {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Root)

    $config = Get-WgrcConfig -Root $Root
    $platform = Get-WgrcPlatform
    $join = Get-WgrcJoinState

    Write-Host "Windows Gaming Reference Configuration $($config.Defaults.Version)" -ForegroundColor Green
    Write-WgrcPlatform -Platform $platform

    Write-WgrcHeading 'Microsoft-native control plane'
    $lgpo = Get-WgrcLgpoExe -Defaults $config.Defaults
    Write-Host ("{0,-5} Microsoft Security Compliance Toolkit / LGPO" -f $(if ($lgpo) { 'PASS' } else { 'INFO' })) `
        -ForegroundColor $(if ($lgpo) { 'Green' } else { 'Gray' })

    if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
        Write-Host 'PASS  Windows Package Manager / WinGet' -ForegroundColor Green
        Write-Host ("      {0}" -f (& winget.exe --version))
    } else {
        Write-Host 'WARN  Windows Package Manager / WinGet unavailable' -ForegroundColor Yellow
    }

    Write-WgrcHeading 'Management state'
    Write-Host ("Domain joined   {0}" -f $join.DomainJoined)
    Write-Host ("Entra joined    {0}" -f $join.AzureAdJoined)
    Write-Host ("Workplace       {0}" -f $join.WorkplaceJoined)
    if ($join.ManagedDevice) {
        Write-Host 'WARN  Managed device detected. Apply refuses by default.' -ForegroundColor Yellow
    }

    Write-WgrcHeading 'Policy / preferences'
    foreach ($policy in $config.PolicyData.Policies) {
        if (-not (Test-WgrcPolicySupported -Policy $policy -Platform $platform)) {
            Write-Host ("SKIP  {0}" -f $policy.Name) -ForegroundColor DarkGray
            continue
        }

        $state = Get-WgrcRegistryState -Policy $policy
        if ($state.Compliant) {
            Write-Host ("PASS  [{0}] {1}" -f $policy.Mechanism, $policy.Name) -ForegroundColor Green
        } else {
            Write-Host ("WARN  [{0}] {1}" -f $policy.Mechanism, $policy.Name) -ForegroundColor Yellow
        }
    }

    Write-WgrcHeading 'Applications'
    foreach ($package in $config.PackageData.Packages) {
        $present = Get-WgrcPackageInstalled -Package $package
        if ($present) {
            Write-Host ("PASS  {0}" -f $package.Name) -ForegroundColor Green
        } elseif ($package.RequiredForReady) {
            Write-Host ("WARN  {0}" -f $package.Name) -ForegroundColor Yellow
        } else {
            Write-Host ("INFO  {0}" -f $package.Name) -ForegroundColor Gray
        }
    }

    Write-WgrcHeading 'Microsoft gaming substrate'
    foreach ($item in Get-WgrcMicrosoftGamingSubstrateState -Substrate $config.PackageData.MicrosoftGamingSubstrate) {
        if ($item.Present) {
            Write-Host ("PASS  {0}" -f $item.Name) -ForegroundColor Green
        } else {
            Write-Host ("WARN  {0}" -f $item.Name) -ForegroundColor Yellow
        }
    }

    Write-WgrcHeading 'Windows health'
    $security = Get-WgrcSecurityState
    $bitlocker = Get-WgrcBitLockerState
    $deviceGuard = Get-WgrcDeviceGuardState
    $pnp = @(Get-WgrcPnpProblems)
    $whea = @(Get-WgrcWheaSummary)

    if ($platform.SecureBoot -eq $true) {
        Write-Host 'PASS  Secure Boot' -ForegroundColor Green
    } elseif ($platform.SecureBoot -eq $false) {
        Write-Host 'WARN  Secure Boot is off' -ForegroundColor Yellow
    }

    if ($platform.TpmReady -eq $true) {
        Write-Host 'PASS  TPM ready' -ForegroundColor Green
    } elseif ($platform.TpmPresent -eq $true) {
        Write-Host 'WARN  TPM present but not ready' -ForegroundColor Yellow
    }

    if ($security.Defender -and $security.Defender.RealTimeProtectionEnabled) {
        Write-Host 'PASS  Defender real-time protection' -ForegroundColor Green
    }

    if ($security.Firewall.Count -gt 0) {
        $disabled = @($security.Firewall | Where-Object { -not $_.Enabled })
        if ($disabled.Count -eq 0) {
            Write-Host 'PASS  Windows Firewall profiles' -ForegroundColor Green
        } else {
            Write-Host 'WARN  One or more Firewall profiles are disabled' -ForegroundColor Yellow
        }
    }

    if ($bitlocker) {
        Write-Host ("INFO  System volume protection: {0}, {1}" -f $bitlocker.ProtectionStatus, $bitlocker.EncryptionMethod)
    }

    if ($deviceGuard) {
        Write-Host ("INFO  VBS status code: {0}" -f $deviceGuard.VirtualizationBasedSecurityStatus)
    }

    if ($pnp.Count -eq 0) {
        Write-Host 'PASS  No present PnP devices reporting non-OK status' -ForegroundColor Green
    } else {
        Write-Host ("WARN  {0} present PnP device(s) report a problem" -f $pnp.Count) -ForegroundColor Yellow
    }

    if ($whea.Count -eq 0) {
        Write-Host 'PASS  No WHEA events since boot' -ForegroundColor Green
    } else {
        Write-Host ("WARN  WHEA events recorded since boot: {0} group(s)" -f $whea.Count) -ForegroundColor Yellow
    }

    Write-WgrcHeading 'Launcher UI auto-start'
    $entries = @(Get-WgrcLauncherRunEntries -LauncherData $config.LauncherData)
    if ($entries.Count -eq 0) {
        Write-Host 'PASS  No targeted game-launcher UI entries in HKCU Run' -ForegroundColor Green
    } else {
        foreach ($entry in $entries) {
            Write-Host ("WARN  {0}: {1}" -f $entry.Launcher, $entry.ValueName) -ForegroundColor Yellow
        }
    }

    Write-Host ''
    Write-Host 'Audit made no configuration changes.' -ForegroundColor Green
}

function Invoke-WgrcPlan {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Root)

    $config = Get-WgrcConfig -Root $Root
    $platform = Get-WgrcPlatform
    $join = Get-WgrcJoinState

    Write-Host 'WGRC PLAN - NO CONFIGURATION CHANGES' -ForegroundColor Green
    Write-WgrcPlatform -Platform $platform

    Write-WgrcHeading 'Control plane'
    if (Get-WgrcLgpoExe -Defaults $config.Defaults) {
        Write-Host 'PASS  Microsoft LGPO already present and Microsoft-signed' -ForegroundColor Green
    } else {
        Write-Host 'PLAN  Acquire LGPO from official Microsoft Download Center and validate Authenticode signature' -ForegroundColor Yellow
    }
    Write-Host 'PLAN  Use LGPO for ADMX-backed local policy'
    Write-Host 'PLAN  Use WinGet Configuration / DSC v3 for application desired state'
    Write-Host 'PLAN  Use direct Windows preferences only for settings that are not Group Policy'

    if ($join.ManagedDevice) {
        Write-Host 'BLOCK Apply: managed/domain/Entra-joined system detected unless -AllowManagedDevice is explicit' -ForegroundColor Red
    }

    Write-WgrcHeading 'Policy / preference changes'
    foreach ($policy in $config.PolicyData.Policies) {
        if (-not (Test-WgrcPolicySupported -Policy $policy -Platform $platform)) {
            Write-Host ("SKIP  [{0}] {1}" -f $policy.Id, $policy.Name) -ForegroundColor DarkGray
            continue
        }

        $state = Get-WgrcRegistryState -Policy $policy
        if ($state.Compliant) {
            Write-Host ("PASS  [{0}] already desired" -f $policy.Id) -ForegroundColor Green
        } else {
            $current = if ($state.ValueExists) { [string]$state.Value } else { '<not configured>' }
            Write-Host (
                "PLAN  [{0}/{1}] {2} -> {3}" -f
                $policy.Id, $policy.Mechanism, $current, $policy.Desired
            ) -ForegroundColor Yellow
            Write-Host ("      {0}" -f $policy.Reason) -ForegroundColor DarkGray
        }
    }

    Write-WgrcHeading 'WinGet desired state'
    $configPath = Join-Path $Root '.config\configuration.winget'
    if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
        & winget.exe configure show -f $configPath --disable-interactivity
    } else {
        Write-Host 'WARN  WinGet unavailable' -ForegroundColor Yellow
    }

    Write-WgrcHeading 'Microsoft Store gaming substrate'
    foreach ($item in Get-WgrcMicrosoftGamingSubstrateState -Substrate $config.PackageData.MicrosoftGamingSubstrate) {
        if ($item.Present) {
            Write-Host ("PASS  {0}" -f $item.Name) -ForegroundColor Green
        } else {
            Write-Host ("PLAN  repair/install {0} through Microsoft Store/WinGet" -f $item.Name) -ForegroundColor Yellow
        }
    }

    $xbox = $config.PackageData.Packages | Where-Object { $_.Name -eq 'Xbox app' } | Select-Object -First 1
    if ($xbox -and -not (Get-WgrcPackageInstalled -Package $xbox)) {
        Write-Host 'PLAN  install Xbox app through Microsoft Store/WinGet' -ForegroundColor Yellow
    }

    Write-WgrcHeading 'Launcher startup'
    $entries = @(Get-WgrcLauncherRunEntries -LauncherData $config.LauncherData)
    if ($entries.Count -eq 0) {
        Write-Host 'PASS  none targeted'
    } else {
        foreach ($entry in $entries) {
            Write-Host ("PLAN  disable UI auto-start for {0}: {1}" -f $entry.Launcher, $entry.ValueName) -ForegroundColor Yellow
        }
    }

    Write-WgrcHeading 'Explicit non-actions'
    Write-Host 'NO core AppX removal. NO service massacre. NO Defender/SmartScreen/Firewall disable.'
    Write-Host 'NO timer/network folklore. NO firmware automation. NO default-app hash forging.'
    Write-Host 'NO shell patching. NO package-integrity bypass.'

    Write-Host ''
    Write-Host 'Plan made no configuration changes.' -ForegroundColor Green
}

function Invoke-WgrcApply {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Root,
        [switch]$AllowManagedDevice
    )

    Assert-WgrcAdministrator

    $config = Get-WgrcConfig -Root $Root
    $platform = Get-WgrcPlatform
    $join = Get-WgrcJoinState

    if (-not (Test-WgrcSupportedPlatform -Platform $platform -Defaults $config.Defaults)) {
        throw "WGRC $($config.Defaults.Version) Apply targets Windows 11 25H2 build $($config.Defaults.MinimumBuild)+."
    }

    if ($join.ManagedDevice -and -not $AllowManagedDevice) {
        throw 'WGRC detected a domain/Entra-joined device. Refusing to apply local policy by default. Use -AllowManagedDevice only when you own the policy conflict risk.'
    }

    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        throw 'Windows Package Manager (WinGet/App Installer) is required.'
    }

    $correlationId = [Guid]::NewGuid().ToString('N').Substring(0, 12)
    $transcript = Start-WgrcTranscript -Defaults $config.Defaults -Operation 'Apply' -CorrelationId $correlationId

    try {
        Write-Host "WGRC Apply $($config.Defaults.Version) [$correlationId]" -ForegroundColor Green

        $lgpo = Initialize-WgrcMicrosoftPolicyTools -Defaults $config.Defaults
        $backupPath = New-WgrcBackup -Config $config -Platform $platform `
            -LgpoExe $lgpo -CorrelationId $correlationId

        $backupDirectory = Split-Path $backupPath -Parent
        Write-Host "State backup: $backupPath"

        Write-WgrcHeading 'Microsoft Local Group Policy'
        $lgpoText = New-WgrcLgpoApplyText -Policies $config.PolicyData.Policies -Platform $platform
        [void](Invoke-WgrcLgpoText -LgpoExe $lgpo -Text $lgpoText `
            -WorkingDirectory $backupDirectory -FileName 'wgrc-apply.lgpo.txt')

        Write-WgrcHeading 'Windows preferences'
        foreach ($policy in $config.PolicyData.Policies) {
            if ($policy.Mechanism -ne 'Preference') { continue }
            if (-not (Test-WgrcPolicySupported -Policy $policy -Platform $platform)) { continue }

            $state = Get-WgrcRegistryState -Policy $policy
            if ($state.Compliant) {
                Write-Host ("PASS  {0}" -f $policy.Name) -ForegroundColor Green
            } else {
                Set-WgrcPreference -Policy $policy
                Write-Host ("SET   {0}" -f $policy.Name) -ForegroundColor Yellow
            }
        }

        try {
            gpupdate.exe /target:computer /force | Out-Null
            gpupdate.exe /target:user /force | Out-Null
        } catch {}

        Write-WgrcHeading 'WinGet Configuration'
        Initialize-WgrcWinGetConfiguration
        $configurationPath = Join-Path $Root '.config\configuration.winget'
        $configOk = Invoke-WgrcWinGetConfiguration -Path $configurationPath

        Write-WgrcHeading 'Xbox / Microsoft Store'
        foreach ($item in Get-WgrcMicrosoftGamingSubstrateState -Substrate $config.PackageData.MicrosoftGamingSubstrate) {
            if ($item.Present) {
                Write-Host ("PASS  {0}" -f $item.Name) -ForegroundColor Green
            } else {
                [void](Install-WgrcMicrosoftStorePackage -Id $item.Id -Name $item.Name)
            }
        }

        $xbox = $config.PackageData.Packages |
            Where-Object { $_.Name -eq 'Xbox app' } |
            Select-Object -First 1

        if ($xbox -and -not (Get-WgrcPackageInstalled -Package $xbox)) {
            [void](Install-WgrcMicrosoftStorePackage -Id $xbox.Id -Name $xbox.Name)
        }

        Write-WgrcHeading 'Microsoft Office'
        $officePath = Join-Path $Root '.config\office.winget'
        $officeOk = Invoke-WgrcWinGetConfiguration -Path $officePath -Optional

        Write-WgrcHeading 'Launcher UI startup'
        Disable-WgrcLauncherUiAutoStart -LauncherData $config.LauncherData

        Export-WgrcGpResult -Destination (Join-Path $backupDirectory 'gpresult-after.html')

        $added = @()
        $backup = Get-Content $backupPath -Raw | ConvertFrom-Json
        foreach ($package in $config.PackageData.Packages) {
            $before = $backup.Packages |
                Where-Object { $_.Id -eq $package.Id } |
                Select-Object -First 1

            if ($before -and -not $before.InstalledBefore -and
                (Get-WgrcPackageInstalled -Package $package)) {
                $added += $package.Id
            }
        }

        [pscustomobject]@{
            Applied = (Get-Date).ToString('o')
            CorrelationId = $correlationId
            PolicyBackend = 'Microsoft Security Compliance Toolkit / LGPO'
            PackageBackend = 'Windows Package Manager / WinGet Configuration'
            GamingConfigurationSucceeded = $configOk
            OfficeConfigurationSucceeded = $officeOk
            InstalledByThisApply = $added
            Backup = $backupPath
        } | ConvertTo-Json -Depth 6 |
            Set-Content (Join-Path $backupDirectory 'apply.json') -Encoding UTF8

        Write-WgrcHeading 'Postcondition verification'
        $verification = Invoke-WgrcVerify -Root $Root
        if (-not $verification.ReadyToGame) {
            throw "WGRC Apply completed configuration but failed its gaming-readiness postcondition. Restore is available at: $backupPath"
        }

        Write-WgrcHeading 'Complete'
        Write-Host 'WGRC completed the supported configuration pass and immediate verification.' -ForegroundColor Green
        Write-Host 'Reboot once, complete documented first-run user choices, then run Verify again.'
        Write-Host 'No firmware, protected file-association, taskbar, GPU-clock or hidden Lenovo API changes were made.'
    }
    finally {
        Stop-WgrcTranscriptSafe -TranscriptPath $transcript
    }
}

function Invoke-WgrcVerify {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Root)

    $config = Get-WgrcConfig -Root $Root
    $platform = Get-WgrcPlatform
    $join = Get-WgrcJoinState

    $blockingFailures = 0
    $warnings = 0

    Write-Host "WGRC Verification $($config.Defaults.Version)" -ForegroundColor Green
    Write-WgrcPlatform -Platform $platform

    Write-WgrcHeading 'Platform'
    if (Test-WgrcSupportedPlatform -Platform $platform -Defaults $config.Defaults) {
        Write-Host 'PASS  Supported Windows 11 25H2 target' -ForegroundColor Green
    } else {
        Write-Host 'FAIL  Unsupported v0.1 Windows target' -ForegroundColor Red
        $blockingFailures++
    }

    if ($join.ManagedDevice) {
        Write-Host 'WARN  Managed/domain/Entra-joined device' -ForegroundColor Yellow
        $warnings++
    }

    Write-WgrcHeading 'Microsoft-native control plane'
    $lgpo = Get-WgrcLgpoExe -Defaults $config.Defaults
    if ($lgpo) {
        Write-Host 'PASS  Microsoft-signed LGPO present' -ForegroundColor Green
    } else {
        Write-Host 'WARN  Microsoft LGPO tool cache not present' -ForegroundColor Yellow
        $warnings++
    }

    $configurationPath = Join-Path $Root '.config\configuration.winget'
    $wingetState = Test-WgrcWinGetDesiredState -Path $configurationPath
    if ($wingetState -eq $true) {
        Write-Host 'PASS  WinGet Configuration desired state' -ForegroundColor Green
    } elseif ($wingetState -eq $false) {
        Write-Host 'WARN  WinGet Configuration reports drift/noncompliance' -ForegroundColor Yellow
        $warnings++
    }

    Write-WgrcHeading 'Policy / preferences'
    foreach ($policy in $config.PolicyData.Policies) {
        if (-not (Test-WgrcPolicySupported -Policy $policy -Platform $platform)) { continue }

        if ((Get-WgrcRegistryState -Policy $policy).Compliant) {
            Write-Host ("PASS  [{0}] {1}" -f $policy.Mechanism, $policy.Name) -ForegroundColor Green
        } else {
            Write-Host ("WARN  [{0}] {1}" -f $policy.Mechanism, $policy.Name) -ForegroundColor Yellow
            $warnings++
        }
    }

    Write-WgrcHeading 'Applications'
    foreach ($package in $config.PackageData.Packages) {
        $present = Get-WgrcPackageInstalled -Package $package

        if ($present) {
            Write-Host ("PASS  {0}" -f $package.Name) -ForegroundColor Green
        }
        elseif ($package.RequiredForReady) {
            Write-Host ("FAIL  {0}" -f $package.Name) -ForegroundColor Red
            $blockingFailures++
        }
        else {
            Write-Host ("INFO  Optional: {0} not detected" -f $package.Name) -ForegroundColor Gray
        }
    }

    Write-WgrcHeading 'Microsoft gaming substrate'
    foreach ($item in Get-WgrcMicrosoftGamingSubstrateState -Substrate $config.PackageData.MicrosoftGamingSubstrate) {
        if ($item.Present) {
            Write-Host ("PASS  {0}" -f $item.Name) -ForegroundColor Green
        } else {
            Write-Host ("FAIL  {0}" -f $item.Name) -ForegroundColor Red
            $blockingFailures++
        }
    }

    Write-WgrcHeading 'Security / reliability'
    $security = Get-WgrcSecurityState
    $bitlocker = Get-WgrcBitLockerState
    $deviceGuard = Get-WgrcDeviceGuardState
    $pnp = @(Get-WgrcPnpProblems)
    $whea = @(Get-WgrcWheaSummary)

    if ($platform.SecureBoot -eq $true) {
        Write-Host 'PASS  Secure Boot' -ForegroundColor Green
    } elseif ($platform.SecureBoot -eq $false) {
        Write-Host 'WARN  Secure Boot is off' -ForegroundColor Yellow
        $warnings++
    } else {
        Write-Host 'INFO  Secure Boot state unavailable' -ForegroundColor Gray
    }

    if ($platform.TpmReady -eq $true) {
        Write-Host 'PASS  TPM ready' -ForegroundColor Green
    } elseif ($platform.TpmPresent -eq $true) {
        Write-Host 'WARN  TPM present but not ready' -ForegroundColor Yellow
        $warnings++
    }

    if ($security.Defender) {
        if ($security.Defender.RealTimeProtectionEnabled) {
            Write-Host 'PASS  Defender real-time protection' -ForegroundColor Green
        } else {
            Write-Host 'WARN  Defender real-time protection off' -ForegroundColor Yellow
            $warnings++
        }
    }

    if ($security.Firewall.Count -gt 0) {
        $disabled = @($security.Firewall | Where-Object { -not $_.Enabled })
        if ($disabled.Count -eq 0) {
            Write-Host 'PASS  Windows Firewall profiles' -ForegroundColor Green
        } else {
            Write-Host 'WARN  One or more Firewall profiles disabled' -ForegroundColor Yellow
            $warnings++
        }
    }

    if ($bitlocker) {
        Write-Host ("INFO  System volume protection: {0}, {1}" -f $bitlocker.ProtectionStatus, $bitlocker.EncryptionMethod)
    }

    if ($deviceGuard) {
        Write-Host ("INFO  VBS status code: {0}" -f $deviceGuard.VirtualizationBasedSecurityStatus)
    }

    if ($pnp.Count -eq 0) {
        Write-Host 'PASS  Present PnP devices healthy' -ForegroundColor Green
    } else {
        Write-Host ("WARN  {0} present PnP device(s) report a problem" -f $pnp.Count) -ForegroundColor Yellow
        $warnings++
    }

    if ($whea.Count -eq 0) {
        Write-Host 'PASS  No WHEA events since boot' -ForegroundColor Green
    } else {
        Write-Host ("WARN  WHEA event groups since boot: {0}" -f $whea.Count) -ForegroundColor Yellow
        $warnings++
    }

    if (Get-WgrcPendingReboot) {
        Write-Host 'WARN  Pending Windows reboot' -ForegroundColor Yellow
        $warnings++
    } else {
        Write-Host 'PASS  No pending reboot' -ForegroundColor Green
    }

    Write-WgrcHeading 'Launcher startup'
    $entries = @(Get-WgrcLauncherRunEntries -LauncherData $config.LauncherData)
    if ($entries.Count -eq 0) {
        Write-Host 'PASS  No targeted launcher UI auto-start' -ForegroundColor Green
    } else {
        foreach ($entry in $entries) {
            Write-Host ("WARN  {0} still auto-starts" -f $entry.Launcher) -ForegroundColor Yellow
            $warnings++
        }
    }

    Write-WgrcHeading 'Display'
    $refresh = ($platform.GPUs | Measure-Object -Property CurrentRefreshRate -Maximum).Maximum
    if ($refresh -and [int]$refresh -ge 120) {
        Write-Host ("PASS  High-refresh display: {0} Hz" -f $refresh) -ForegroundColor Green
    } elseif ($refresh) {
        Write-Host ("WARN  Current reported refresh: {0} Hz" -f $refresh) -ForegroundColor Yellow
        $warnings++
    } else {
        Write-Host 'INFO  Refresh rate unavailable from WMI' -ForegroundColor Gray
    }

    Write-WgrcHeading 'Result'
    if ($blockingFailures -gt 0) {
        Write-Host (
            "NOT READY: {0} blocking failure(s), {1} warning(s)" -f
            $blockingFailures, $warnings
        ) -ForegroundColor Red
    }
    elseif ($warnings -gt 0) {
        Write-Host (
            "READY TO GAME, REFERENCE WARNINGS REMAIN: {0}" -f $warnings
        ) -ForegroundColor Yellow
    }
    else {
        Write-Host 'READY TO GAME - REFERENCE PASS' -ForegroundColor Green
    }

    return [pscustomobject]@{
        BlockingFailures = $blockingFailures
        Warnings = $warnings
        ReadyToGame = ($blockingFailures -eq 0)
        ReferencePass = (($blockingFailures -eq 0) -and ($warnings -eq 0))
    }
}

function Invoke-WgrcRestore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Root,
        [string]$BackupPath,
        [switch]$RestorePackages
    )

    Assert-WgrcAdministrator

    $config = Get-WgrcConfig -Root $Root
    if (-not $BackupPath) {
        $BackupPath = Get-WgrcLatestBackup -Defaults $config.Defaults
    }

    if (-not $BackupPath -or -not (Test-Path $BackupPath)) {
        throw 'No WGRC backup found. Supply -BackupPath explicitly if needed.'
    }

    $backup = Get-Content $BackupPath -Raw | ConvertFrom-Json
    $correlationId = [Guid]::NewGuid().ToString('N').Substring(0, 12)
    $transcript = Start-WgrcTranscript -Defaults $config.Defaults -Operation 'Restore' -CorrelationId $correlationId

    try {
        Write-Host "WGRC Restore [$correlationId]" -ForegroundColor Yellow
        Write-Host "Source state: $BackupPath"

        $lgpo = $null
        try {
            $lgpo = Initialize-WgrcMicrosoftPolicyTools -Defaults $config.Defaults
        } catch {
            Write-Warning 'Microsoft LGPO could not be initialized. Restore will fall back to direct saved registry state.'
        }

        if ($lgpo) {
            Write-WgrcHeading 'Restore Local Group Policy'
            $restoreText = New-WgrcLgpoRestoreText -BackupPolicies $backup.Policies
            [void](Invoke-WgrcLgpoText -LgpoExe $lgpo -Text $restoreText `
                -WorkingDirectory (Split-Path $BackupPath -Parent) `
                -FileName 'wgrc-restore.lgpo.txt')
        } else {
            foreach ($entry in $backup.Policies) {
                if ($entry.Mechanism -eq 'LGPO') {
                    Restore-WgrcPreferenceState -Entry $entry
                }
            }
        }

        Write-WgrcHeading 'Restore Windows preferences'
        foreach ($entry in $backup.Policies) {
            if ($entry.Mechanism -eq 'Preference') {
                Restore-WgrcPreferenceState -Entry $entry
            }
        }

        Restore-WgrcLauncherRunEntries -Backup $backup

        try {
            gpupdate.exe /target:computer /force | Out-Null
            gpupdate.exe /target:user /force | Out-Null
        } catch {}

        if ($RestorePackages) {
            Write-WgrcHeading 'Package rollback'
            $applyPath = Join-Path (Split-Path $BackupPath -Parent) 'apply.json'

            if (Test-Path $applyPath) {
                $apply = Get-Content $applyPath -Raw | ConvertFrom-Json

                foreach ($id in $apply.InstalledByThisApply) {
                    $before = $backup.Packages |
                        Where-Object { $_.Id -eq $id } |
                        Select-Object -First 1

                    if ($before -and -not $before.InstalledBefore) {
                        Write-Host "Uninstalling package installed by WGRC: $id"

                        & winget.exe uninstall --id $id --exact `
                            --silent --disable-interactivity

                        if ($LASTEXITCODE -ne 0) {
                            Write-Warning "Could not uninstall $id automatically."
                        }
                    }
                }
            } else {
                Write-Warning 'No apply.json manifest found; package rollback skipped.'
            }
        }

        Write-Host 'WGRC configuration/startup state restored.' -ForegroundColor Green
        if (-not $RestorePackages) {
            Write-Host 'Applications were left in place. Use -RestorePackages only when you want additive app rollback.'
        }
    }
    finally {
        Stop-WgrcTranscriptSafe -TranscriptPath $transcript
    }
}

function Invoke-WgrcGames {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Root)

    $config = Get-WgrcConfig -Root $Root
    $platform = Get-WgrcPlatform

    Write-Host 'WGRC Games readiness check - NO CONFIGURATION CHANGES' -ForegroundColor Green

    if (Get-WgrcPendingReboot) {
        Write-Warning 'Windows has a pending reboot.'
    }

    $refresh = ($platform.GPUs | Measure-Object -Property CurrentRefreshRate -Maximum).Maximum
    if ($refresh -and [int]$refresh -lt 120) {
        Write-Warning "Current reported refresh is $refresh Hz. Verify the intended gaming refresh rate."
    }

    if ($platform.SecureBoot -eq $false) {
        Write-Warning 'Secure Boot is off. Some anti-cheat configurations may require it.'
    }

    if ($platform.Manufacturer -match 'LENOVO' -and
        ($platform.Model -match '83AG' -or $platform.SystemSKU -match '^83AG')) {
        Write-Host 'Lenovo Legion 9 detected: use Lenovo-supported Performance mode while plugged in.' -ForegroundColor Cyan
    }

    $playnite = Get-WgrcPlaynitePath
    if (-not $playnite) {
        Write-Warning 'Playnite executable not found. Run Apply or install Playnite.'
        return
    }

    Write-Host 'Opening Games (Playnite)...'
    Start-Process -FilePath $playnite
}

function Invoke-WgrcCollect {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Root,
        [string]$OutputPath
    )

    $config = Get-WgrcConfig -Root $Root
    $platform = Get-WgrcPlatform
    $join = Get-WgrcJoinState
    $security = Get-WgrcSecurityState
    $bitlocker = Get-WgrcBitLockerState
    $deviceGuard = Get-WgrcDeviceGuardState
    $pnp = @(Get-WgrcPnpProblems)
    $whea = @(Get-WgrcWheaSummary)

    $temp = Join-Path $env:TEMP ("WGRC-Diagnostics-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $temp -Force | Out-Null

    try {
        $policyState = @()
        foreach ($policy in $config.PolicyData.Policies) {
            if (-not (Test-WgrcPolicySupported -Policy $policy -Platform $platform)) { continue }
            $state = Get-WgrcRegistryState -Policy $policy
            $policyState += [pscustomobject]@{
                Id = $policy.Id
                Mechanism = $policy.Mechanism
                Compliant = $state.Compliant
            }
        }

        $packageState = @()
        foreach ($package in $config.PackageData.Packages) {
            $packageState += [pscustomobject]@{
                Name = $package.Name
                Id = $package.Id
                Present = [bool](Get-WgrcPackageInstalled -Package $package)
            }
        }

        $substrate = @(Get-WgrcMicrosoftGamingSubstrateState -Substrate $config.PackageData.MicrosoftGamingSubstrate)
        $launcherNames = @(
            Get-WgrcLauncherRunEntries -LauncherData $config.LauncherData |
            Select-Object Launcher, ValueName
        )

        # Deliberately exclude username, serial number, UUID, IP addresses,
        # launcher command paths, recovery keys and account identifiers.
        $sanitizedPlatform = [pscustomobject]@{
            OS = $platform.Caption
            DisplayVersion = $platform.DisplayVersion
            Build = $platform.Build
            Edition = $platform.Edition
            Manufacturer = $platform.Manufacturer
            Model = $platform.Model
            CPU = $platform.CPU
            RAMGB = $platform.RAMGB
            GPUs = $platform.GPUs
            BIOS = $platform.BIOS
            SecureBoot = $platform.SecureBoot
            TpmPresent = $platform.TpmPresent
            TpmReady = $platform.TpmReady
        }

        [pscustomobject]@{
            ProjectVersion = $config.Defaults.Version
            Collected = (Get-Date).ToString('o')
            Platform = $sanitizedPlatform
            JoinState = $join
            Security = $security
            BitLocker = $bitlocker
            DeviceGuard = $deviceGuard
            PnpProblems = $pnp
            WheaSummary = $whea
            Policies = $policyState
            Packages = $packageState
            MicrosoftGamingSubstrate = $substrate
            LauncherAutoStart = $launcherNames
            PendingReboot = Get-WgrcPendingReboot
        } | ConvertTo-Json -Depth 12 |
            Set-Content -Path (Join-Path $temp 'summary.json') -Encoding UTF8

        if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
            (& winget.exe --info | Out-String) |
                Set-Content -Path (Join-Path $temp 'winget-info.txt') -Encoding UTF8
        }

        @'
WGRC diagnostic bundles are privacy-minimized by default.

Not collected:
- username
- email/account identifiers
- device serial number
- UUID
- IP addresses
- BitLocker recovery material
- launcher command paths
- browser history
- game credentials/tokens
- raw event-log XML

Review summary.json before attaching this ZIP to a public issue.
'@ | Set-Content -Path (Join-Path $temp 'PRIVACY.txt') -Encoding UTF8

        if (-not $OutputPath) {
            $OutputPath = Join-Path (Get-Location) (
                "WGRC-Diagnostics-{0}.zip" -f (Get-Date -Format 'yyyyMMdd-HHmmss')
            )
        }

        Compress-Archive -Path (Join-Path $temp '*') -DestinationPath $OutputPath -Force
        Write-Host "Diagnostic bundle: $OutputPath" -ForegroundColor Green
        return $OutputPath
    }
    finally {
        Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Export-ModuleMember -Function `
    Invoke-WgrcAudit, `
    Invoke-WgrcPlan, `
    Invoke-WgrcApply, `
    Invoke-WgrcVerify, `
    Invoke-WgrcRestore, `
    Invoke-WgrcGames, `
    Invoke-WgrcCollect, `
    Invoke-WgrcMicrosoftTools


