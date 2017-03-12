<#
    .Synopsis
    ArdyLab DSC Resource to Build FileServer on a node.

    .Description
    blah, blah
    
    .TODO
    Add Error Checking and Verbose/Debug output
#>
Configuration LabDeployFileServer
{
    param             
    ( 
        [Parameter(Mandatory)]             
        [psobject]
        $MountVHD       
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName xStorage
    Import-DscResource -ModuleName xSmbShare
        
    foreach ($VHD in $MountVHD)
    {                     
        xDisk $VHD.ShareName
        {
            DriveLetter = $VHD.DriveLetter
            DiskNumber = $VHD.DiskNumber
        }
    
        
        xSmbShare $VHD.ShareName
        {
            Name = $VHD.ShareName
            Path = "$($VHD.DriveLetter):\"
    
        }
    }
}