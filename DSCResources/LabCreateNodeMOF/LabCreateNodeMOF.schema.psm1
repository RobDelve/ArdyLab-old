<#
    .Synopsis
    ArdyLab DSC Resource to build a custom MOF for each Node specified in the ConfigurationData.

    .Description
    Run this to create the MOFs BEFORE building the VM's with 'LabBuildVM'
    .TODO
    Add logic + configuration for all Role types
    Add Error Checking and Verbose/Debug output
#>
Configuration LabCreateNodeMOF
{
    Import-DscResource -name LabDeployADDS
    Import-DscResource -name LabJoinDomain
    Import-DscResource -name LabConfigureLocalGroup
    Import-DscResource -name LabDeployFileServer
    Import-DscResource -Name LabDeploySQL
    
    $script:DomainOUs = $ConfigurationData.Roles.PrimaryDC.DomainConfig.AdOUs
    $script:DomainUsers = $ConfigurationData.Roles.PrimaryDC.DomainConfig.AdUsers
    $script:DomainGroups = $ConfigurationData.Roles.PrimaryDC.DomainConfig.AdGroups
    
    $script:DnsIpAddress = $ConfigurationData.LabConfig.DnsServer.IP4Addr

    $script:MountVHDs = $ConfigurationData.Roles.FileServer.MountVHD
    $script:Net35Source = $ConfigurationData.Roles.SQLServer.Net35Source
    $script:SQLSetup = $ConfigurationData.Roles.SQLServer.Setup

    node $AllNodes.NodeName
    {   
        # Populate local variables that will be used below...

        # Create credential object for DomainAdmin
        $domainAdminName = "$(($node.DomainName -split '\.')[0])\$($ConfigurationData.Roles.PrimaryDC.DomainConfig.Credentials.DomainAdminName)"
        $domainAdminPassword = ConvertTo-SecureString -String $ConfigurationData.Roles.PrimaryDC.DomainConfig.Credentials.DomainAdminPassword -AsPlainText -Force
        $domainAdminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $domainAdminName, $domainAdminPassword

        # Create credential object for SQLInstall
        $sqlInstallName = "$(($node.DomainName -split '\.')[0])\$($SQLSetup.Credential.UserName)"
        $sqlInstallPassword = ConvertTo-SecureString -String $SQLSetup.Credential.Password -AsPlainText -Force
        $sqlInstallCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $sqlInstallName, $sqlInstallPassword

        # Populate $DomainOU
        if ($node.DomainOU -notlike "") 
        {
            $DomainOU = "$($node.DomainOU),DC=$(($node.DomainName -split '\.')[0]),DC=$(($node.DomainName -split '\.')[1])"
        }
        else
        {
            $DomainOU = $null
        }

        # Process the specificed Role(s) of this node in turn
        foreach ($role in $node.Role)
        {
            switch($role)
            {
                'PrimaryDC'
                {
                    # Custom Composite Resources to Install & Configure ADDS
                    LabDeployADDS $node.NodeName
                    {
                        DomainName = $node.DomainName
                        DomainAdmin = $domainAdminCredential
                        SafeModeAdmin = $domainAdminCredential
                        DomainOUs = @($DomainOUs)
                        DomainUsers = @($DomainUsers)
                        DomainGroups = @($DomainGroups)
                    }

                    # TBI
                    #LabConfigureDNS $node.NodeName
                    #{
                    #    
                    #}
                }

                'DomainMember'
                {
                    # Join a Domain         
                    LabJoinDomain $node.NodeName
                    {
                        NodeName = $node.NodeName
                        DomainName = $node.DomainName
                        JoinOU = $DomainOU # Fix This!!! - suspect fault in format
                        DomainJoinCredential = $domainAdminCredential
                        DnsIPAddress = $DnsIpAddress
                    }
                }

                'FileServer'
                {                
                    LabDeployFileServer $node.NodeName
                    {
                        MountVHD = $MountVHDs
                    }
                    

                    File CreateFolder 
                    {
                        Type = 'Directory'
                        DestinationPath = 'C:\SHARED'
                        Ensure = "Present"
                    }
                }

                'SQLServer'
                {
                    LabDeploySQL $node.NodeName
                    {
                       SxsPath = $Net35Source.Path
                       SourcePath = $SQLSetup.Path
                       SetupCredential = $sqlInstallCredential
                       Instance = $SQLSetup.Instance
                       Features = $SQLSetup.Features
                       SecurityMode = $SQLSetup.SecurityMode
                       SAPassword = $domainAdminCredential
                    }
                     
                }

                'EPMServer'
                {


                }
            }

        } #END Foreach $role    

        
        # Add any entries in the $node.AddtoAdminGroup to the Local 'Administrators' group of this node
        if ($node.AddToAdminGroup)
        {
            LabConfigureLocalGroup $node.NodeName
            {
                GroupName = 'Administrators'
                DomainName = $node.DomainName
                MembersToInclude = $node.AddToAdminGroup
                Credential = $domainAdminCredential
            }
        }     
    }

}