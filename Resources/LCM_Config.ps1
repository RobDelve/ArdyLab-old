[DSCLocalConfigurationManager()]
configuration LCMConfig {
  
  Node $AllNodes.Nodename
  {
    Settings
    {
      AllowModuleOverwrite = $true
      ConfigurationMode = 'ApplyAndMonitor'
      RefreshMode = 'Push'
      ActionAfterReboot = 'ContinueConfiguration'
      RebootNodeIfNeeded = $true
    }  
  }

}