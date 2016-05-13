Write-Host (get-date -f T) ":Script Started" -ForegroundColor Cyan

$pathVHDTemplate = 'C:\VM\Virtual Hard Disks\Templates\Win2012_Base.vhdx'
##$pathVHDTemplate = 'C:\VM\Virtual Hard Disks\Win2012_Template.vhdx'
$path = $pwd
$pathConfigData = "$path\Config\LabConfig.psd1"

## Create Virtual Machines
$pathMOF = "$path\MOF\NewVM"


. $("$path\resources\newvm.ps1")

Write-Host (get-date -f T) ":Creating MOF's based on '$pathConfigData'" -ForegroundColor Green
NewVM -ConfigurationData $pathConfigData -VHDParentPath $pathVHDTemplate -OutputPath $pathMOF | Out-Null

Write-Host (get-date -f T) ":Run DSC with each MOF in '$pathMOF'" -ForegroundColor Green
Start-DscConfiguration -Path $pathMOF -Wait -Force #-Verbose

## Generate & Inject unattend.xml to each Virtual Machine
[xml]$template = Get-Content "$pwd\Resources\Unattend-template.xml"

# Get the data we need from $pathConfigData - TODO: Find a tidier method
$configData = Invoke-Expression "DATA { $(Get-Content -Path $pathConfigData -Raw)}"

foreach ($vmnode in $configData.AllNodes)
{
  [string]$name = $vmnode.NodeName
  [string]$Ip4Addr = $vmnode.IP4Addr
  if ((Get-VM -Name $Name).State -eq 'Off')
  {
    Write-Host (get-date -f T) ":Mounting VHD for '$Name' and injecting the unattend.xml" -ForegroundColor Green
    [xml]$unattendFile = $template
    $unattendFile.unattend.settings.component[1].ComputerName = $Name
    $unattendFile.unattend.settings.component[2].Interfaces.Interface.UnicastIpAddresses.IpAddress.'#text' = $Ip4Addr
  
    Mount-VHD -path $(Join-Path -Path $((Get-VMHost).VirtualHardDiskPath) -ChildPath "$Name\$Name`_C.vhdx") –PassThru | Get-Disk | Get-Partition | Get-Volume -OutVariable MountedDrive | Out-Null
  
    $outfile = $MountedDrive.Driveletter + ':\unattend.xml'
    $unattendFile.Save($outfile)
  
    Dismount-VHD -Path $(Join-Path -Path $((Get-VMHost).VirtualHardDiskPath) -ChildPath "$Name\$Name`_C.vhdx") | Out-Null
  
    Write-Host (get-date -f T) ":Starting the Virtual Machine '$Name'" -ForegroundColor Green
    Start-VM $Name
  
    # Wait for a bit to allow the VM to start and process local unattend.xml
    $count = 45
    While ($count -gt 0)
    {
  
      Write-Progress -Activity "Starting the Virtual Machine '$Name'" -SecondsRemaining $count
      Start-Sleep -Seconds 1
      $count -= 1
    }
  }
  else
  {
    Write-Host (get-date -f T) ":Skipped injecting 'unattend.xml' for VM '$Name'" -ForegroundColor DarkYellow
  }
}
Write-Host (get-date -f T) ":Script Completed" -ForegroundColor Cyan



