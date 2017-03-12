# ArdyLabConfig
@{
    AllNodes = @(
        @{
            NodeName                    = '*'
            DomainName                  = 'test.lab'
            AdminName                   = 'Administrator'
            AdminPassword               = 'P@ssw0rd'
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
        }

        @{
            NodeName       = 'TEST-DC01'
            Role           = 'PrimaryDC','FileServer'
            ProcessorCount = 2
            MaximumMemory  = 4GB
            IP4Addr        = '192.168.66.101/24'
            VHDTemplate    = 'C:\VM\VHD Templates\Win2012_Base-Nov2016.vhdx'
            
        } 

        @{
            NodeName       = 'TEST-SQL01'
            Role           = 'DomainMember','SQLServer'
            AddToAdminGroup = 'epm_install','Install Accounts'
            ProcessorCount = 2
            MaximumMemory  = 8GB
            IP4Addr        = '192.168.66.102/24'
            VHDTemplate    = 'C:\VM\VHD Templates\Win2012_Base-Nov2016.vhdx'
        } 

        @{
            NodeName       = 'TEST-SVR01'
            Role           = 'DomainMember','EPMWeb'
            AddToAdminGroup = 'epm_install','Install Accounts'
            DomainOu       = 'OU=EPM Servers, OU=Lab Servers'
            ProcessorCount = 2
            MaximumMemory  = 16GB
            IP4Addr        = '192.168.66.103/24'
            VHDTemplate    = 'C:\VM\VHD Templates\Win2012_Base-Nov2016.vhdx'
        }
    )

    Roles = @{
        PrimaryDC = @{
            DomainConfig = @{
                Credentials = @{
                    DomainAdminName     = 'Administrator'
                    DomainAdminPassword = 'P@ssw0rd'
                }

                AdOUs = @(
                    @{
                        Name                            = 'LabUsers'
                        Path                            = ''
                        Description                     = 'Generic Lab User Accounts'
                        ProtectedFromAccidentalDeletion = $true
                        Ensure                          = 'Present'
                    }

                    @{
                        Name                            = 'EPMUsers'
                        Path                            = 'OU=LabUsers'
                        Description                     = 'EPM User Accounts'
                        ProtectedFromAccidentalDeletion = $true
                        Ensure                          = 'Present'
                    }

                    @{
                        Name                            = 'Lab Servers'
                        Path                            = ''
                        Description                     = 'Generic Lab Servers'
                        ProtectedFromAccidentalDeletion = $true
                        Ensure                          = 'Present'
                    }

                    @{
                        Name                            = 'EPM Servers'
                        Path                            = 'OU = Lab Servers'
                        Description                     = 'EPM Servers'
                        ProtectedFromAccidentalDeletion = $true
                        Ensure                          = 'Present'
                    }
                )

                AdGroups = @(
                    @{
                        Role            = 'LocalAdmin'
                        GroupName       = 'Install Accounts'
                        GroupScope      = 'Global'
                        Category        = 'Security'
                        Description     = 'Group will be added to Local Administrators group of each server'
                        Path            = 'OU=EPMUsers, OU=LabUsers'
                        IncludeMemebers = 'epm_install','epm_service'
                        DisplayName     = 'Install Accounts'
                        Ensure          = 'Present'                                    
                    }

                    @{
                        Role            = 'LocalAdmin'
                        GroupName       = 'SuperUsers'
                        GroupScope      = 'Global'
                        Category        = 'Security'
                        Description     = 'Group will be added to Local Administrators group of each server'
                        Path            = 'OU=LabUsers'
                        IncludeMemebers = 'epm_install','epm_service'
                        DisplayName     = 'SuperUsers'
                        Ensure          = 'Present'
                    }
                )

                AdUsers = @(
                    @{
                        Role                 = 'EPM Install','LocalAdmin'
                        Description          = 'Use to install EPM and related software'
                        UserName             = 'epm_install'
                        Password             = 'Hyp3r10n'
                        GivenName            = ''
                        Surname              = ''
                        DisplayName          = 'EPM Installer'
                        PasswordNeverExpires = $true
                        Enabled              = $true
                        Path                 = 'OU=LabUsers'
                        Ensure               = 'Present'
                    }

                    @{
                        Role                 = 'EPM Service'
                        Description          = 'Use to launch EPM services'
                        UserName             = 'epm_service'
                        Password             = 'Hyp3r10n'
                        GivenName            = ''
                        Surname              = ''
                        DisplayName          = 'EPM Service'
                        PasswordNeverExpires = $true
                        Enabled              = $true
                        Path                 = 'OU=LabUsers'
                        Ensure               = 'Present'
                    }

                    @{
                        Role                 = 'EPM LDAP'
                        Description          = 'Use to configure HSS for conections to this AD Domain'
                        UserName             = 'epm_ldap'
                        Password             = 'Hyp3r10n'
                        GivenName            = ''
                        Surname              = ''
                        DisplayName          = 'EPM LDAP'
                        PasswordNeverExpires = $true
                        Enabled              = $true
                        Path                 = 'OU=LabUsers'
                        Ensure               = 'Present'
                    }
                )
            }                    
        }

        SQLServer = @{
            Net35Source = @{ 
                Path = '\\TEST-DC01\Win2012Sources\Sources\sxs'
            }                    

            Setup = @{
                Path = '\\TEST-DC01\SQLInstall'
                Credential = @{
                    Username = 'epm_install'
                    Password = 'Hyp3r10n'
                }
                Instance = 'MSSQLSERVER'
                Features = 'SQLENGINE,Tools'
                SecurityMode = 'SQL'
                SaPassword = 'P@ssw0rd'
            }                    

            Databases = @(
                @{

                }
            )    
                
        }
                
        FileServer = @{
            MountVHD = @(
                @{
                    DriveLetter = 'S'
                    DiskNumber  = 1
                    ShareName   = 'SQLInstall'
                    Path        = 'C:\VM\VHD Templates\SQL2012R2_Install.vhdx'
                }

                @{
                    DriveLetter = 'T'
                    DiskNumber  = 2
                    ShareName   = 'Win2012Sources'
                    Path        = 'C:\VM\VHD Templates\Win2012_Sources.vhdx'
                }
            )
        }        
        
        EPMWeb = @(
            @{

            }
        )
        
        EPMApp = @(
            @{

            }
        )
    }
      
    LabConfig = @{
        VSwitch  = @{
            Name    = 'LabInt'
            Type    = 'Internal'
            IP4Addr = '192.168.66.2/24'
        }                    

        DnsServer  = @{ # will be removed in future release and IP4Addr grabed from node.where{role = PrimaryDC}                   
            IP4Addr = '192.168.66.101'
        }                    

        FilePaths = @{
            Unattend = @{
                TemplateFile = 'C:\ProgramData\ArdyLab\LabResources\Templates\Unattend-template.xml'
                OutputFolder = 'C:\ProgramData\ArdyLab\LabResources\Data\Unattend\'
            }                

            GeneratedMOFs = @{
                MOFs     = 'C:\ProgramData\ArdyLab\LabResources\GeneratedMOFs\'
                RoleMOFs = 'C:\ProgramData\ArdyLab\LabResources\GeneratedMOFs\ToBeInjected\'
            }                

            ToCopy = @{                
                BootstrapFolder = 'C:\ProgramData\ArdyLab\LabResources\Data\BootStrap\'
            }                
        }        
    }    
}
