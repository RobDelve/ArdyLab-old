#requires -Version 4.0

<#
    .Synopsis
    DSC Resource to Configure common PreReqs for an EPM Server

    .Description
    
#>
Configuration LabPreReqEPM
{
  param             
  (  
    [Parameter()]
    [string]
    $dummy         
  )

  Import-DscResource -ModuleName xSystemSecurity, PSDesiredStateConfiguration

  xUac DisableUAC
  {
    Setting = 'NeverNotifyAndDisableAll'
  }

  xIEEsc DisableAdminUsers
  {
    UserRole = 'Administrators'
    IsEnabled = $false
  }

}