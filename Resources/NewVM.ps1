#requires -Version 4
#requires -runasadministrator

# Rob Delve - May 2016

Configuration NewVM {
  param (
    [string]$VHDParentPath
  )
  
  Import-DscResource -ModuleName PSDesiredStateConfiguration
  Import-DscResource -module xHyper-V
  
  $VSwitchName = $ConfigurationData.VSwitch.name
    
  File VMPath
  {
    Ensure = 'Present'
    Type = 'Directory'
    DestinationPath = $((Get-VMHost).VirtualMachinePath)
  }

  xVMSwitch 'VSwitch' {
    Name = $VSwitchName
    Ensure = 'Present'
    Type = 'Internal'
  }

  foreach ($VM in $ConfigurationData.AllNodes)
  {
    $VMName = $VM.NodeName

    File "VHDPath_$VMName"
    {
      Ensure = 'Present'
      Type = 'Directory'
      DestinationPath = Join-Path -Path $((Get-VMHost).VirtualHardDiskPath) -ChildPath $VMName
    }
    
    xVHD "DiffVHD_$VMName" {
      Ensure = 'Present'
      Name = "$VMName`_C"
      Path = Join-Path -Path $((Get-VMHost).VirtualHardDiskPath) -ChildPath $VMName
      ParentPath = $VHDParentPath
      Generation = 'vhdx'
      DependsOn = "[File]VHDPath_$VMName"
    }
    xVMHyperV "CreateVM_$VMName" {
      Name = $VMName
      SwitchName = $VSwitchName
      Path = $((Get-VMHost).VirtualMachinePath)
      VhdPath = Join-Path -Path $((Get-VMHost).VirtualHardDiskPath) -ChildPath "$VMName\$VMName`_C.vhdx"
      ProcessorCount = $VM.ProcessorCount
      MaximumMemory = $VM.MaximumMemory
      MinimumMemory = 512MB
      RestartIfNeeded = $true
      DependsOn = "[xVHD]DiffVHD_$VMName", '[xVMSwitch]VSwitch', '[File]VMPath'
      # State = 'Running'
      Generation = 2
    }
  }
}

