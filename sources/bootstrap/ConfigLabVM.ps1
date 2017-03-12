# 

# If running PowerShell v4, remove the version folder from the Modules that were injected during build
if ($PSVersionTable.PSVersion.Major -eq 4)
{
    # As this is PS v4 the only Modules in the \Program Files\WindowsPowerShell\Modules are those that have been injected during build
    # No need to worry about multiple versions (being lazy!) - Assuming that only one version will be injected at build time...    
    
    Write-Output "Applying fixes for PowerShell v4..."
    $modCollection = (ls "$env:SystemDrive\Program Files\WindowsPowerShell\Modules").FullName

    foreach ($modPath in $modCollection)
    {
        $modName = ($modPath -split '\\')[-1]        

        Write-Output "Checking paths for module '$modName'"
        
        # Lazy! checking if result matches 0.0.0.0 version naming
        # Will return False if *any* path returned not a match
        # Not an issue as should only ever be 1 version of a Module injected during build
        if ((Get-ChildItem -Path $modPath).Name -match '\d*.\d*.\d*.\d*' -eq $true  )
        {
            Write-Output " ...Fixing path names for the module '$modName'"
            Copy-Item -Path "$modPath\*\*" -Destination $modPath -Recurse
        }
    }

    # Enable PSRemoting
    Enable-PSRemoting -Force

}
elseif ($PSVersionTable.PSVersion.Major -gt 4)
{
    "PowerShell v$($PSVersionTable.PSVersion.Major) - no need to fix module paths or run 'Enable-PSRemoting'"
}

#schtasks.exe /Create /SC ONSTART /TN "\Microsoft\Windows\Desired State Configuration\DSCRestartBootTask" /RU System /F /TR "PowerShell.exe -NonInt -Command 'Invoke-CimMethod -Namespace root/Microsoft/Windows/DesiredStateConfiguration -ClassName MSFT_DSCLocalConfigurationManager -MethodName PerformRequiredConfigurationChecks -Arguments @{ flags = [System.uint32]1}'"

schtasks.exe /Create /SC ONSTART /TN "\Microsoft\Windows\Desired State Configuration\DSCRestartBootTask" /RU System /F /TR "PowerShell.exe -Command 'Start-DscConfiguration -UseExisting -Wait -Force -Verbose'"


