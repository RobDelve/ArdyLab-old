<#
    .Synopsis
    DSC Resource to Create Hyper-V Virtual Machines and required VHD file with custom 'unattend.xml' on the localhost

    .Description
    Uses the DSC Module 'xHyper-v' to create a VHD, add custom 'unattend.xml', then create a virtual machine.
#>
Configuration LabBuildVM_HyperV 
{
    param             
    (  
        [Parameter(Mandatory)]
        [string]
        $NodeName,

        [Parameter(Mandatory)]
        [string]
        $VSwitchName,
                
        [Parameter(Mandatory)]
        [string]
        $VHDTemplate,

        [Parameter(Mandatory)]
        [psobject]
        $CopyToVHD,

        [Parameter()]
        [string]
        $ProcessorCount = 2,

        [Parameter()]
        [string]
        $MaximumMemory = 2048MB            
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xHyper-V
    
    File CreateVHDPath
    {
        Ensure = 'Present'
        Type = 'Directory'
        DestinationPath = Join-Path -Path $((Get-VMHost).VirtualHardDiskPath) -ChildPath $NodeName
    }
    
    xVHD CreateDiffVHD
    {
        Ensure = 'Present'
        Name = "$($NodeName)_C"
        Path = Join-Path -Path $((Get-VMHost).VirtualHardDiskPath) -ChildPath $NodeName
        ParentPath = $VHDTemplate
        Generation = 'vhdx'
        DependsOn = '[File]CreateVHDPath'
    }
         
    xVhdFile CopyRequiredFiles
    {
        VhdPath = $(Join-Path -Path $((Get-VMHost).VirtualHardDiskPath) -ChildPath "$NodeName\$($NodeName)_C.vhdx")
        FileDirectory = 
            foreach($item in $CopyToVHD){@(       
                MSFT_xFileDirectory 
                {
                    SourcePath = $item.source
                    DestinationPath = $item.destination
                    Type = $item.type             
                })
            }
        DependsOn = '[xVHD]CreateDiffVHD'
    }                   

    # Build the VM
    xVMHyperV CreateVM
    {
        Name = $NodeName
        SwitchName = $VSwitchName
        Path = $((Get-VMHost).VirtualMachinePath)
        VhdPath = Join-Path -Path $((Get-VMHost).VirtualHardDiskPath) -ChildPath "$NodeName\$($NodeName)_C.vhdx"
        ProcessorCount = $ProcessorCount
        MaximumMemory = $MaximumMemory
        MinimumMemory = 512MB
        RestartIfNeeded = $true
        #State = 'Off'
        Generation = 2
        DependsOn = '[xVHD]CreateDiffVHD'
    }

     
}
