# ArdyLabConfig - Sample 1
# Deploys 3 * Win2016
# 1 = PrimaryDC
# 2 = FileServer
# 3 = SQL Server 2012

@{
    AllNodes = @(
        @{
            NodeName                    = '*'
            DomainName                  = 'ArdySamples.lab'
            AdminName                   = 'Administrator'
            AdminPassword               = 'P@ssw0rd'
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true

            VHDTemplate    = 'C:\VM\VHD Templates\Win2012_Base-Nov2016.vhdx'
        }

        @{
            NodeName       = 'S1-DC01'
            Role           = 'PrimaryDC'
            ProcessorCount = 2
            MaximumMemory  = 4GB
            IP4Addr        = '192.168.66.11/24'                        
        } 

        @{
            NodeName       = 'S1-FS01'
            Role           = 'DomainMember','FileServer'
            AddToAdminGroup = 'Install Accounts'
            ProcessorCount = 2
            MaximumMemory  = 8GB
            IP4Addr        = '192.168.66.12/24'
        } 

        @{
            NodeName       = 'S1-SQL01'
            Role           = 'DomainMember','SQLServer'
            AddToAdminGroup = 'Install Accounts'
            DomainOu       = 'OU=EPM Servers, OU=Lab Servers'
            ProcessorCount = 2
            MaximumMemory  = 8GB
            IP4Addr        = '192.168.66.13/24'
            VHDTemplate    = 'C:\VM\VHD Templates\Win2016_Base.vhdx'
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
                        Name                            = 'Lab Users'
                        Path                            = ''
                        Description                     = 'Lab User Accounts'
                        ProtectedFromAccidentalDeletion = $true
                        Ensure                          = 'Present'
                    }

                    @{
                        Name                            = 'Lab Service Accounts'
                        Path                            = 'OU=Lab Users'
                        Description                     = 'Lab Service Accounts'
                        ProtectedFromAccidentalDeletion = $true
                        Ensure                          = 'Present'
                    }

                    @{
                        Name                            = 'Lab Servers'
                        Path                            = ''
                        Description                     = 'Lab Servers'
                        ProtectedFromAccidentalDeletion = $true
                        Ensure                          = 'Present'
                    }                    
                )

                AdGroups = @(
                    @{
                        GroupName       = 'Install Accounts'
                        GroupScope      = 'Global'
                        Category        = 'Security'
                        Description     = 'Group will be added to Local Administrators group of each server'
                        Path            = 'OU=Lab Users'
                        IncludeMemebers = 'lab_install'
                        DisplayName     = 'Install Accounts'
                        Ensure          = 'Present'                                    
                    }

                    @{
                        GroupName       = 'Service Accounts'
                        GroupScope      = 'Global'
                        Category        = 'Security'
                        Description     = 'Group will be added to Local Administrators group of each server'
                        Path            = 'OU=Lab Users'
                        IncludeMemebers = 'lab_service','sql_service'
                        DisplayName     = 'Service Accounts'
                        Ensure          = 'Present'
                    }
                )

                AdUsers = @(
                    @{
                        Description          = 'Use to install EPM and related software'
                        UserName             = 'lab_install'
                        Password             = 'P@ssw0rd'
                        GivenName            = ''
                        Surname              = ''
                        DisplayName          = 'lab_install'
                        PasswordNeverExpires = $true
                        Enabled              = $true
                        Path                 = 'OU=Lab Users'
                        Ensure               = 'Present'
                    }

                    @{
                        Description          = 'Use to launch Generic Lab Services'
                        UserName             = 'lab_service'
                        Password             = 'P@ssw0rd'
                        GivenName            = ''
                        Surname              = ''
                        DisplayName          = 'lab_service'
                        PasswordNeverExpires = $true
                        Enabled              = $true
                        Path                 = 'OU=Lab Service Accounts, OU=Lab Users'
                        Ensure               = 'Present'
                    }

                    @{
                        Description          = 'Use to launch SQL Services'
                        UserName             = 'SQL_service'
                        Password             = 'P@ssw0rd'
                        GivenName            = ''
                        Surname              = ''
                        DisplayName          = 'SQL_service'
                        PasswordNeverExpires = $true
                        Enabled              = $true
                        Path                 = 'OU=Lab Service Accounts, OU=Lab Users'
                        Ensure               = 'Present'
                    }
                    @{
                        Description          = 'Sample User'
                        UserName             = 'JoeBlack'
                        Password             = 'P@ssw0rd'
                        GivenName            = 'Joe'
                        Surname              = 'Black'
                        DisplayName          = 'Joe Black'
                        PasswordNeverExpires = $true
                        Enabled              = $true
                        Path                 = 'OU=Lab Users'
                        Ensure               = 'Present'
                    }
                )
            }                    
        }

        SQLServer = @{
            Net35Source = @{ 
                Path = '\\S1-FS01\WinSources\Sources\sxs'
            }                    

            Setup = @{
                Path = '\\S1-FS01\SQLInstall'
                Credential = @{
                    Username = 'lab_install'
                    Password = 'P@ssw0rd'
                }
                Instance = 'MSSQLSERVER'
                Features = 'SQLENGINE,IS,SSMS,ADV_SSMS'
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
                    ShareName   = 'SQLInstall'
                    Path        = 'C:\VM\VHD Templates\SQL2012R2_Install.vhdx'
                    DiskNumber  = 1
                    ControllerParams = @{ControllerType = 'SCSI'
                                         ControllerNumber = 0
                                         ControllerLocation = 1}
                }

                @{
                    DriveLetter = 'T'
                    ShareName   = 'Win2012Sources'
                    Path        = 'C:\VM\VHD Templates\Win2012-16_Sources.vhdx'
                    DiskNumber  = 2
                    ControllerParams = @{ControllerType = 'SCSI'
                                         ControllerNumber = 0
                                         ControllerLocation = 2}
                }
            )
        }                
    }
      
    LabConfig = @{
        VSwitch  = @{
            Name    = 'LabInt'
            Type    = 'Internal'
            IP4Addr = '192.168.66.2/24'
        }                    

        DnsServer  = @{ # will be removed in future release and IP4Addr grabed from node.where{role = PrimaryDC}                   
            IP4Addr = '192.168.66.11'
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
