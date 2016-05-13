#requires -Version 4
configuration NewADUser
{
  param             
  (              
    [Parameter(Mandatory)]            
    [pscredential]$NewADUserCred         
  ) 

  Import-DscResource -ModuleName xActiveDirectory
  
  $AllUsers = (Get-Content -Path .\LabConfig.psd1 |
    Out-String |
  Invoke-Expression).AllUsers
  
  Node $AllNodes.Where{
    $_.Role -eq 'Primary DC'
  }.Nodename           
  {
    foreach ($user in $AllUsers)
    {
      xADUser $user.UserName 
      { 
        DomainName = $Node.DomainName 
        #DomainAdministratorCredential = $domaincred 
        UserName = $user.UserName 
        Password = $NewADUserCred
        UserPrincipalName = $user.UserName + '@'+ $Node.DomainName
        GivenName = $user.UserName
        Surname = $user.Surname
        #CommonName = $user.CommonName
        DisplayName = $user.DisplayName
        PasswordNeverExpires = $user.PasswordNeverExpires
        Enabled = $user.Enabled
        #Path = $user.Path                               
        Ensure = 'Present'     
      }
    }
  }
}


NewADUser -ConfigurationData .\LabConfig.psd1 -NewADUserCred (Get-Credential -Message 'Password for ALL new EPM Users' -UserName '(Password Only)') -Verbose
Start-DscConfiguration -Wait -Force -Path .\NewADUser -Verbose -Credential (Get-Credential administrator@epm.lab)