$profile=Import-PowerShellDataFile (Join-Path $PSScriptRoot 'profile.psd1')
$cs=Get-CimInstance Win32_ComputerSystem
$cpu=Get-CimInstance Win32_Processor|Select-Object -First 1
$gpus=@(Get-CimInstance Win32_VideoController)
Write-Host "Hardware profile: $($profile.Family)"
Write-Host "Manufacturer: $($cs.Manufacturer)"
Write-Host "Model/SKU: $($cs.Model) / $($cs.SystemSKUNumber)"
Write-Host "CPU: $($cpu.Name)"
$gpus|ForEach-Object{Write-Host "GPU: $($_.Name)"}
if($cs.Manufacturer -notmatch $profile.Manufacturer -or
   ($cs.Model -notmatch $profile.MachineTypePrefix -and $cs.SystemSKUNumber -notmatch "^$($profile.MachineTypePrefix)")){
    Write-Warning 'System does not match this hardware profile.'
}
