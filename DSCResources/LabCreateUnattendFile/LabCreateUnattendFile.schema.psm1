<#
    .Synopsis
    blah

    .Description
    blah, blah
#>
configuration LabCreateUnattendFile {
    Param 
    (
      [Parameter(Mandatory)]
      [string]
      $NodeName,

      [Parameter(Mandatory)]
      [string]
      $IP4Addr,
           
      [Parameter(Mandatory)]
      [string]
      $AdminName,

      [Parameter(Mandatory)]
      [string]
      $AdminPassword
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
   
    Script CreateUnattendFile
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
            [xml]$unattendFile = Get-Content -Path ( Convert-Path $using:ConfigurationData.LabConfig.FilePaths.Unattend.TemplateFile )
            
            ## FIX to find correct section by name, rather than index !!
            Write-Verbose -Message "Generating a custom 'unattend.xml' for '$using:NodeName'."
            $unattendFile.unattend.settings.component[0].ComputerName = $using:NodeName
            $unattendFile.unattend.settings.component[1].Interfaces.Interface.UnicastIpAddresses.IpAddress.'#text' = $using:Ip4Addr
            $unattendFile.unattend.settings.component[1].Interfaces.Interface.UnicastIpAddresses.IpAddress.'#text' = $using:Ip4Addr
            $unattendFile.unattend.settings.component[3].UserAccounts.AdministratorPassword.Value = $using:AdminPassword
            
            $unattendFile.unattend.settings.component[3].UserAccounts.LocalAccounts.LocalAccount.Name = $using:AdminName
            $unattendFile.unattend.settings.component[3].UserAccounts.LocalAccounts.LocalAccount.Password.Value = $using:AdminPassword
            $unattendFile.unattend.settings.component[3].UserAccounts.LocalAccounts.LocalAccount.DisplayName = $using:AdminName

            $unattendFile.unattend.settings.component[3].AutoLogon.Password.Value = $using:AdminPassword
            $unattendFile.unattend.settings.component[3].AutoLogon.Username = $using:AdminName


            $customUnattendFile = "$(Convert-Path $using:ConfigurationData.LabConfig.FilePaths.Unattend.OutputFolder)\$($using:NodeName)_unattend.xml"
            Write-Verbose -Message "Saving the generated 'unattend.xml' file as '$customUnattendFile'."      
            $unattendFile.Save($customUnattendFile)                
        } 
    }
}