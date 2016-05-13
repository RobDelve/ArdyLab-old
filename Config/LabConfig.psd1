#requires -Version 1
# LabConfig
@{
  AllNodes = @(             
    @{
      NodeName       = 'WAYNE-DC01'
      Role           = 'Primary DC'
      DomainName     = 'epm.lab'
      ProcessorCount = 1
      MaximumMemory  = 2GB
      IP4Addr        = '192.168.66.10/24'
    }, 

    @{
      NodeName       = 'WAYNE-SQL01'
      Role           = 'SQL'
      DomainName     = 'epm.lab'
      ProcessorCount = 2
      MaximumMemory  = 2GB
      IP4Addr        = '192.168.66.15/24'
    }, 
        
    @{
      NodeName       = 'WAYNE-EPMWeb01'
      Role           = 'EPM Web'
      DomainName     = 'epm.lab'
      ProcessorCount = 2
      MaximumMemory  = 8GB
      IP4Addr        = '192.168.66.20/24'
    }, 
    
    @{
      NodeName       = 'WAYNE-EPMApp01'
      Role           = 'EPM App'
      DomainName     = 'epm.lab'
      ProcessorCount = 2
      MaximumMemory  = 6GB
      IP4Addr        = '192.168.66.30/24'
    }       
  )
  VSwitch  = @(
    @{
      Name    = 'LabInt'
      Type    = 'Internal'
      IP4Addr = '192.168.66.1/24'
    }
  )
  AllUsers = @(             
    @{
      Role                 = 'EPM Install'
      UserName             = 'epm_install'
      CommonName           = ''
      GivenName            = ''
      Surname              = ''
      DisplayName          = 'EPM Installer'
      PasswordNeverExpires = $true
      Enabled              = $true
      Path                 = ''
    }, 

    @{
      Role                 = 'EPM Service'
      UserName             = 'epm_service'
      CommonName           = ''
      GivenName            = ''
      Surname              = ''
      DisplayName          = 'EPM Service'
      PasswordNeverExpires = $true
      Enabled              = $true
      Path                 = ''
    }, 
    
    @{
      Role                 = 'EPM LDAP'
      UserName             = 'epm_ldap'
      CommonName           = ''
      GivenName            = ''
      Surname              = ''
      DisplayName          = 'EPM LDAP'
      PasswordNeverExpires = $true
      Enabled              = $true
      Path                 = ''
    }
  )
}