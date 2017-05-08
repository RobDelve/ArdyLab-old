#requires -Version 4.0
<#
    .Synopsis
    ArdyLab DSC Resource to install & Configure Microsoft SQL Server and Net 3.5.

    .Description
    blah, blah
    
    .TODO
    Add Error Checking and Verbose/Debug output
#>
Configuration LabDeployOracle
{
  param             
  ( 
    [Parameter(Mandatory)]             
    [string]
    $SourcePath,

    [Parameter(Mandatory)]             
    [pscredential]
    $SetupCredential,

    [Parameter()]             
    [string]
    $Instance = 'MSSQLSERVER',

    [Parameter()]             
    [string]
    $Features = 'SQLENGINE, SSMS, ADV_SSMS',

    [Parameter()]             
    [string]
    $ResponseFile,

    [Parameter()]             
    [pscredential]
    $SAPassword
  )

  Import-DscResource -ModuleName PSDesiredStateConfiguration
     
  Script DeployOracle
  {
    GetScript = {
      # do nothing for now
    }
    TestScript = {
      # just return $false for now - forces 'SetScript' to run everytime
      $false
    }
    SetScript = 
    {
      Write-Verbose -Message "Starting Oracle setup.exe with Response File '$using:ResponseFile'."
     # Start-Process -FilePath "$($)"
    } 
  }
}