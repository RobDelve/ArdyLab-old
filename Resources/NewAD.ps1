#requires -Version 4 -Modules PSDesiredStateConfiguration
configuration NewADDS             
{             
  param             
  (             
    [Parameter(Mandatory)]             
    [pscredential]$safemodeAdministratorCred,             
    [Parameter(Mandatory)]            
    [pscredential]$domainCred    
  )             
            
  Import-DscResource -ModuleName PSDesiredStateConfiguration
  Import-DscResource -ModuleName xActiveDirectory             
            
  Node $AllNodes.Where{
    $_.Role -eq 'Primary DC'
  }.Nodename             
  {                                                    
    WindowsFeature ADDSInstall             
    {             
      Ensure = 'Present'             
      Name = 'AD-Domain-Services'             
    }            
            
    # Optional GUI tools            
    WindowsFeature ADDSTools            
    {             
      Ensure = 'Present'             
      Name = 'RSAT-ADDS'             
    }            
            
    # No slash at end of folder paths            
    xADDomain FirstDC             
    {             
      DomainName = $Node.DomainName             
      DomainAdministratorCredential = $domainCred             
      SafemodeAdministratorPassword = $safemodeAdministratorCred                      
      DependsOn = '[WindowsFeature]ADDSInstall'          
    }
  }             
}            
            
           
NewADDS -ConfigurationData .\Config\LabConfig.psd1 `
-safemodeAdministratorCred (Get-Credential -UserName '(Password Only)' `
-Message 'New Domain Safe Mode Administrator Password') `
-domainCred (Get-Credential -UserName administrator `
-Message 'New Domain Admin Credential') -OutputPath .\MOF\NewADDS       
            
            
# Build the domain            
Start-DscConfiguration -Wait -Force -Path .\MOF\NewADDS -Verbose -Credential (Get-Credential)