#requires -Version 4.0
<#
    .Synopsis
    ArdyLab DSC Resource to install & Configure Microsoft SQL Server and Net 3.5.

    .Description
    blah, blah
    
    .TODO
    Add Error Checking and Verbose/Debug output
#>
Configuration LabDeploySQL
{
  param             
  (   
    [Parameter(Mandatory)]             
    [string]
    $SxsPath,

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
    $SecurityMode = 'SQL',

    [Parameter()]             
    [pscredential]
    $SAPassword
  )

  Import-DscResource -ModuleName xSQLServer, PSDesiredStateConfiguration

  WindowsFeature InstallNET35 
  {
    Name = 'NET-Framework-Core'
    Ensure = 'Present'
    Source = $SxsPath
  }
     
  xSqlServerSetup InstallSQLServer
  {
    InstanceName = $Instance
    Action = 'Install'
    
    ForceReboot = $true
    SourcePath = $SourcePath
    SetupCredential = $SetupCredential 
    
    Features = $Features
    SQLSysAdminAccounts = $SetupCredential.UserName
    SecurityMode = $SecurityMode
    SAPwd = $SAPassword
    SQLCollation = 'Latin1_General_CI_AS'
    InstallSharedDir = 'C:\Program Files\Microsoft SQL Server' 
    InstallSharedWOWDir = 'C:\Program Files (x86)\Microsoft SQL Server' 
    InstanceDir = 'C:\Program Files\Microsoft SQL Server' 
    InstallSQLDataDir = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data' 
    SQLUserDBDir = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data' 
    SQLUserDBLogDir = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data' 
    SQLTempDBDir = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data' 
    SQLTempDBLogDir = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data' 
    SQLBackupDir = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data' 

    DependsOn = '[WindowsFeature]InstallNET35' 
  }

  xSqlServerFirewall SQLFirewall
  {
    Ensure = 'Present'
    SourcePath = $SourcePath
    InstanceName = $Instance
    Features = $Features
    SourceCredential = $SetupCredential
      
    DependsOn = '[xSqlServerSetup]InstallSQLServer'
  }

  xSQLServerMemory SQLMemory
  {
      Ensure = "Present"
      SQLInstanceName = $Instance
      DynamicAlloc = $True
 
      DependsOn = '[xSqlServerSetup]InstallSQLServer' 
  }
  
#  xSQLServerMaxDop SQLMaxDrop
#  {
#      Ensure = "Present"
#      SQLInstanceName = $Instance
#      DynamicAlloc = $true
# 
#      DependsOn = '[xSqlServerSetup]InstallSQLServer'     
#  }

}