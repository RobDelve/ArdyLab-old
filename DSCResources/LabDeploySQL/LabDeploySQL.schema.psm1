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
        $Features = 'SQLENGINE,Tools',

        [Parameter()]             
        [string]
        $SecurityMode = 'SQL',

        [Parameter()]             
        [pscredential]
        $SAPassword
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xSQLServer

    WindowsFeature InstallNET35
    {
        Name = 'NET-Framework-Core'
        Ensure = 'Present'
        Source =  $SxsPath
    }
     
    xSqlServerSetup InstallSQLServer
    {
        DependsOn = '[WindowsFeature]InstallNET35' 
        ForceReboot = $true
        SourcePath = $SourcePath
        SetupCredential = $SetupCredential 
        InstanceName = $Instance
        Features = $Features
        SQLSysAdminAccounts = $SetupCredential.UserName
        SecurityMode = $SecurityMode
        SAPwd = $SAPassword
        InstallSharedDir = "C:\Program Files\Microsoft SQL Server" 
        InstallSharedWOWDir = "C:\Program Files (x86)\Microsoft SQL Server" 
        InstanceDir = "C:\Program Files\Microsoft SQL Server" 
        InstallSQLDataDir = "C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data" 
        SQLUserDBDir = "C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data" 
        SQLUserDBLogDir = "C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data" 
        SQLTempDBDir = "C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data" 
        SQLTempDBLogDir = "C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data" 
        SQLBackupDir = "C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data" 
    }       
}