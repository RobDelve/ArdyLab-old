<#
	.Synopsis
	DSC Resource to Create & Configure a Hyper-V Virtual Switch on the localhost.

	.Description
	Uses the DSC Module 'xHyper-v' to create a Virtual Switch.
	Uses the DSC Module 'xNetworking' to configure the Virtual Switch
#>
Configuration LabPrepareHyperV
{
    param             
    (  
        [Parameter(Mandatory)]
        [string]
        $VSwitchName,
                   
        [Parameter(Mandatory)]
        [ipaddress]
        $VSwitchIP4Address,
        
        [Parameter(Mandatory)]
        [int]
        $VSwitchIP4PrefixLength          
    )

	Import-DscResource -ModuleName PSDesiredStateConfiguration
	Import-DscResource -ModuleName xDismFeature
	Import-DscResource -ModuleName xHyper-V
	Import-DscResource -ModuleName xNetworking

	xDismFeature InstallHyperV-All 
	{
		Name = 'Microsoft-Hyper-V'
		Ensure = 'Present'
	}
	
	xVMSwitch $VSwitchName
	{
		Name = $VSwitchName
		Ensure = 'Present'
		Type = 'Internal'
	}

	xNetConnectionProfile $VSwitchName
	{
		InterfaceAlias = "vEthernet ($VSwitchName)"
		NetworkCategory = 'Private'		
		DependsOn = "[xVMSwitch]$VSwitchName"
	}

	xIPAddress $VSwitchName
	{
		IPAddress = $VSwitchIP4Address
        PrefixLength = $VSwitchIP4PrefixLength
		InterfaceAlias = "vEthernet ($VSwitchName)"		
		AddressFamily = 'IPV4'
		DependsOn = "[xVMSwitch]$VSwitchName"
	}

	xDhcpClient $VSwitchName
	{
		State = 'Disabled'
		InterfaceAlias = "vEthernet ($VSwitchName)"
		AddressFamily = 'IPV4'
		DependsOn = "[xVMSwitch]$VSwitchName"
	}

}