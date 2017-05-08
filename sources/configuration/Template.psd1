# ArdyLabConfig - Templates

@{
    AllNodes = @(
        @{
            NodeName                    = '*'
            DomainName                  = 'ArdySamples.lab'
            DomainOu                    = 'OU=Lab Servers'
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
            AddToAdminGroup = 'Install Accounts'           
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
                    ShareName   = 'SQL2012Install'
                    Path        = 'C:\VM\VHD Templates\SQL2012R2_Install.vhdx'
                    DiskNumber  = 1
                    ControllerParams = @{ControllerType = 'SCSI'
                                         ControllerNumber = 0
                                         ControllerLocation = 1}
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

        DnsServer  = @{
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
