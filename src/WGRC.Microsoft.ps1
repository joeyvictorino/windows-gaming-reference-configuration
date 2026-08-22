Set-StrictMode -Version Latest

function Get-WgrcExpandedPath {
    param([Parameter(Mandatory)][string]$Path)
    [Environment]::ExpandEnvironmentVariables($Path)
}

function Test-WgrcMicrosoftSignedBinary {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return $false }

    try {
        $signature = Get-AuthenticodeSignature -FilePath $Path -ErrorAction Stop
        if ($signature.Status -ne 'Valid' -or -not $signature.SignerCertificate) { return $false }

        $subject = [string]$signature.SignerCertificate.Subject
        $company = [string](Get-Item -LiteralPath $Path).VersionInfo.CompanyName

        return (($subject -match 'Microsoft Corporation') -and
                ($company -match 'Microsoft'))
    } catch {
        return $false
    }
}

function Get-WgrcLgpoExe {
    param([Parameter(Mandatory)]$Defaults)

    $toolRoot = Get-WgrcExpandedPath $Defaults.ToolRoot
    $candidate = Join-Path $toolRoot 'LGPO\LGPO.exe'

    if ((Test-Path -LiteralPath $candidate) -and
        (Test-WgrcMicrosoftSignedBinary -Path $candidate)) {
        return $candidate
    }

    return $null
}

function Initialize-WgrcMicrosoftPolicyTools {
    param([Parameter(Mandatory)]$Defaults)

    $existing = Get-WgrcLgpoExe -Defaults $Defaults
    if ($existing) { return $existing }

    $downloadUri = [Uri]$Defaults.LgpoDownloadUrl
    if ($downloadUri.Scheme -ne 'https' -or $downloadUri.Host -ne 'download.microsoft.com') {
        throw 'WGRC LGPO source must be the pinned official download.microsoft.com HTTPS host.'
    }

    $toolRoot = Get-WgrcExpandedPath $Defaults.ToolRoot
    $targetDir = Join-Path $toolRoot 'LGPO'
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

    $tempRoot = Join-Path $env:TEMP ("WGRC-LGPO-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    $zipPath = Join-Path $tempRoot 'LGPO.zip'

    try {
        Write-Host 'Acquiring Microsoft LGPO from the official Microsoft Download Center...' -ForegroundColor Cyan

        $downloaded = $false
        if (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue) {
            try {
                Start-BitsTransfer -Source $Defaults.LgpoDownloadUrl -Destination $zipPath -ErrorAction Stop
                $downloaded = $true
            } catch {
                Write-Verbose 'BITS transfer failed; falling back to Invoke-WebRequest against the same Microsoft URL.'
            }
        }

        if (-not $downloaded) {
            Invoke-WebRequest -Uri $Defaults.LgpoDownloadUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
        }

        $zipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
        Expand-Archive -Path $zipPath -DestinationPath $tempRoot -Force

        $candidate = Get-ChildItem -Path $tempRoot -Recurse -Filter 'LGPO.exe' -File |
            Select-Object -First 1

        if (-not $candidate) {
            throw 'LGPO.exe was not present in the Microsoft archive.'
        }

        if (-not (Test-WgrcMicrosoftSignedBinary -Path $candidate.FullName)) {
            throw 'LGPO.exe did not validate as a Microsoft-signed binary.'
        }

        $target = Join-Path $targetDir 'LGPO.exe'
        Copy-Item -LiteralPath $candidate.FullName -Destination $target -Force

        if (-not (Test-WgrcMicrosoftSignedBinary -Path $target)) {
            throw 'Copied LGPO.exe failed Microsoft signature validation.'
        }

        $exeHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
        $signature = Get-AuthenticodeSignature -FilePath $target
        [pscustomobject]@{
            Source = $Defaults.LgpoDownloadUrl
            Acquired = (Get-Date).ToString('o')
            ArchiveSHA256 = $zipHash
            LGPOSHA256 = $exeHash
            SignatureStatus = [string]$signature.Status
            SignerSubject = if ($signature.SignerCertificate) { [string]$signature.SignerCertificate.Subject } else { $null }
            SignerThumbprint = if ($signature.SignerCertificate) { [string]$signature.SignerCertificate.Thumbprint } else { $null }
        } | ConvertTo-Json | Set-Content -Path (Join-Path $targetDir 'provenance.json') -Encoding UTF8

        return $target
    }
    finally {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function ConvertTo-WgrcLgpoAction {
    param(
        [Parameter(Mandatory)][string]$Type,
        [Parameter(Mandatory)]$Value
    )

    switch ($Type) {
        'DWord' { return "DWORD:$Value" }
        'QWord' { return "QWORD:$Value" }
        'String' {
            $escaped = ([string]$Value).Replace('\','\\').Replace("`r",'\r').Replace("`n",'\n')
            return "SZ:$escaped"
        }
        default { throw "Unsupported LGPO registry value type: $Type" }
    }
}

function New-WgrcLgpoApplyText {
    param(
        [Parameter(Mandatory)]$Policies,
        [Parameter(Mandatory)]$Platform
    )

    $lines = [System.Collections.Generic.List[string]]::new()

    foreach ($policy in $Policies) {
        if ($policy.Mechanism -ne 'LGPO') { continue }
        if (-not (Test-WgrcPolicySupported -Policy $policy -Platform $Platform)) { continue }

        $lines.Add($(if ($policy.Scope -eq 'Machine') { 'Computer' } else { 'User' }))
        $lines.Add([string]$policy.Key)
        $lines.Add([string]$policy.ValueName)
        $lines.Add((ConvertTo-WgrcLgpoAction -Type $policy.Type -Value $policy.Desired))
        $lines.Add('')
    }

    return ($lines -join "`r`n")
}

function New-WgrcLgpoRestoreText {
    param([Parameter(Mandatory)]$BackupPolicies)

    $lines = [System.Collections.Generic.List[string]]::new()

    foreach ($entry in $BackupPolicies) {
        if ($entry.Mechanism -ne 'LGPO') { continue }

        $lines.Add($(if ($entry.Scope -eq 'Machine') { 'Computer' } else { 'User' }))
        $lines.Add([string]$entry.Key)
        $lines.Add([string]$entry.ValueName)

        if ($entry.ValueExists) {
            $type = switch ([string]$entry.Kind) {
                'DWord' { 'DWord' }
                'QWord' { 'QWord' }
                default { 'String' }
            }
            $lines.Add((ConvertTo-WgrcLgpoAction -Type $type -Value $entry.Value))
        } else {
            $lines.Add('DELETE')
        }

        $lines.Add('')
    }

    return ($lines -join "`r`n")
}

function Invoke-WgrcLgpoText {
    param(
        [Parameter(Mandatory)][string]$LgpoExe,
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string]$FileName
    )

    $path = Join-Path $WorkingDirectory $FileName
    # LGPO supports Unicode text with BOM. PowerShell "Unicode" is UTF-16LE with BOM.
    Set-Content -Path $path -Value $Text -Encoding Unicode

    & $LgpoExe /q /t $path
    if ($LASTEXITCODE -ne 0) {
        throw "Microsoft LGPO failed with exit code $LASTEXITCODE."
    }

    return $path
}

function Backup-WgrcLocalPolicy {
    param(
        [Parameter(Mandatory)][string]$LgpoExe,
        [Parameter(Mandatory)][string]$Destination
    )

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    & $LgpoExe /b $Destination /n 'WGRC Pre-Apply Local Policy'
    if ($LASTEXITCODE -ne 0) {
        throw "LGPO local-policy backup failed with exit code $LASTEXITCODE."
    }
}

function Get-WgrcJoinState {
    $cs = Get-CimInstance Win32_ComputerSystem
    $raw = ''
    try { $raw = (& "$env:SystemRoot\System32\dsregcmd.exe" /status 2>$null | Out-String) } catch {}

    function Read-DsregBool([string]$Name) {
        if ($raw -match "(?im)^\s*$([regex]::Escape($Name))\s*:\s*(YES|NO)\s*$") {
            return ($Matches[1] -eq 'YES')
        }
        return $null
    }

    $azureAd = Read-DsregBool 'AzureAdJoined'
    $domain = if ($cs.PartOfDomain) { $true } else { Read-DsregBool 'DomainJoined' }
    $workplace = Read-DsregBool 'WorkplaceJoined'

    [pscustomobject]@{
        DomainJoined = $domain
        AzureAdJoined = $azureAd
        WorkplaceJoined = $workplace
        ManagedDevice = (($domain -eq $true) -or ($azureAd -eq $true))
    }
}

function Get-WgrcDeviceGuardState {
    try {
        $dg = Get-CimInstance -Namespace 'root\Microsoft\Windows\DeviceGuard' -ClassName Win32_DeviceGuard -ErrorAction Stop
        return [pscustomobject]@{
            VirtualizationBasedSecurityStatus = $dg.VirtualizationBasedSecurityStatus
            SecurityServicesConfigured = @($dg.SecurityServicesConfigured)
            SecurityServicesRunning = @($dg.SecurityServicesRunning)
        }
    } catch {
        return $null
    }
}

function Get-WgrcBitLockerState {
    try {
        $volume = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
        return [pscustomobject]@{
            MountPoint = $volume.MountPoint
            VolumeStatus = [string]$volume.VolumeStatus
            ProtectionStatus = [string]$volume.ProtectionStatus
            EncryptionMethod = [string]$volume.EncryptionMethod
        }
    } catch {
        return $null
    }
}

function Get-WgrcPnpProblems {
    try {
        return @(
            Get-PnpDevice -PresentOnly -ErrorAction Stop |
            Where-Object { $_.Status -ne 'OK' } |
            Select-Object Class, FriendlyName, Status, Problem
        )
    } catch {
        return @()
    }
}

function Get-WgrcWheaSummary {
    try {
        $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        $events = @(
            Get-WinEvent -FilterHashtable @{
                LogName='System'
                ProviderName='Microsoft-Windows-WHEA-Logger'
                StartTime=$boot
            } -ErrorAction Stop
        )

        return @(
            $events |
            Group-Object Id |
            ForEach-Object {
                [pscustomobject]@{
                    EventId = [int]$_.Name
                    Count = $_.Count
                    FirstSeen = ($_.Group | Sort-Object TimeCreated | Select-Object -First 1).TimeCreated
                    LastSeen = ($_.Group | Sort-Object TimeCreated -Descending | Select-Object -First 1).TimeCreated
                }
            }
        )
    } catch {
        return @()
    }
}

function Export-WgrcGpResult {
    param([Parameter(Mandatory)][string]$Destination)
    try {
        & "$env:SystemRoot\System32\gpresult.exe" /h $Destination /f | Out-Null
    } catch {}
}
