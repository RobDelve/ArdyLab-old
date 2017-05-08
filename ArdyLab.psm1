#requires -Version 4.0 -Modules CimCmdlets, PowerShellGet, PSDesiredStateConfiguration
# TODO - LOTS!!!


## Install-ArdyLab
## Initialize-ArdyLab
### Uninstall-ArdyLab
## Clear-ArdyLabFiles
## Set-ArdyLabVMHost
## New-ArdyLabNodeMOF
## Start-ArdyLabBuild

function Install-ArdyLab
{
  [CmdletBinding()]
  Param()
  $sourcesPath = "$env:ProgramFiles\WindowsPowerShell\Modules\ArdyLab\sources"
  $LabRootPath = "$env:ProgramData\ArdyLab"
  $LabResourcesPath = "$LabRootPath\LabResources"
  $templatePath = "$LabRootPath\LabResources\Templates"
  $ChildPath = @(
    'ConfigurationData'
    'Data'
    'Data\Bootstrap'
    'Data\Unattend'
    'GeneratedMOFs'
    'GeneratedMOFs\ToBeInjected'
    'Templates'
  )

  Write-Verbose -Message "Creating ArdyLab Resource folders in '$LabRootPath'"
    
  function _newFolder
  {
    param
    (
      [parameter(mandatory)][string]$Path,
      [parameter(mandatory)][string]$Name
    )
    
    try 
    {
      $null = New-Item -Path $Path -Name $Name -ItemType Directory -ErrorAction Stop
      Write-Verbose -Message "Created folder '$Path\$Name'"
    }
    catch 
    {
      Write-Warning -Message "Folder '$Path\$Name' already exists"
    }
  }

  function _copyFolder
  {
    param
    (
      [parameter(mandatory)][string]$Path,
      [parameter(mandatory)][string]$Destination
    )
    
    try 
    {
      $null = Copy-Item -Path $Path -Destination $Destination -Recurse -ErrorAction Stop
      Write-Verbose -Message "Copied folder contents '$Path' to '$Destination'"
    }
    catch 
    {
      Write-Warning -Message "File '$(($Path -split '\\')[-1])' already exists in '$Destination'"
    }
  }

  # Create parent folders
  _newFolder -Path $env:ProgramData -Name ($LabRootPath -split '\\')[-1]
  _newFolder -Path $LabRootPath -Name ($LabResourcesPath -split '\\')[-1]

  # Create child folders
  foreach ($_path in $ChildPath)
  {
    _newFolder -Path $LabResourcesPath -Name $_path
  }
    
  # Copy Template files to LabResources folders
  _copyFolder -Path "$sourcesPath\LCM\*" -Destination "$LabResourcesPath\Templates"
  _copyFolder -Path "$sourcesPath\Unattend\*" -Destination "$LabResourcesPath\Templates"
  _copyFolder -Path "$sourcesPath\configuration\*" -Destination "$LabResourcesPath\ConfigurationData"
  _copyFolder -Path "$sourcesPath\bootstrap\*" -Destination "$LabResourcesPath\Data\Bootstrap"
  _copyFolder -Path "$templatePath\localhost.meta.mof" -Destination "$LabResourcesPath\GeneratedMOFs\ToBeInjected\"
}

function Initialize-ArdyLab
{
  [CmdletBinding()]
  Param
  (   
    [parameter()]
    [switch]
    $InstallModules
  )

  $LabRootPath = "$env:ProgramData\ArdyLab"

  Write-Verbose -Message "Set 'WSMan:\localhost\MaxEnvelopeSizekb' = 4096"
  Set-Item -Path WSMan:\localhost\MaxEnvelopeSizekb -Value 4096
    
  # Install required DSC modules from PSGallery
  if ($InstallModules)
  {
    $modules = 'xDismFeature', 'xHyper-V', 'xActiveDirectory', 'xNetworking', 'xComputerManagement', 'xSQLServer', 'xSystemSecurity', 'xStorage','xSmbShare'
    Write-Verbose -Message "Installing required modules from the 'PSGallery'"
    Install-Module -Name $modules -Verbose -Force
  }    
}

function Clear-ArdyLabFiles
{  
  [CmdletBinding()]
  Param()

  ## Tidy up =~ Install-ArdyLab
  $LabRootPath = "$env:ProgramData\ArdyLab"

  $unattendPath = Join-Path -Path $LabRootPath -ChildPath 'LabResources\Data\Unattend\'
  $mofPath = Join-Path -Path $LabRootPath -ChildPath 'LabResources\GeneratedMOFs\'
  $templatePath = Join-Path -Path $LabRootPath -ChildPath 'LabResources\Templates\'

  Write-Verbose -Message 'Cleaning up the ArdyLab generated files.'
  Write-Verbose -Message "Removing generated 'unattend.xml' and 'MOF' files."
  Remove-Item -Path "$unattendPath\*" -Verbose
  Remove-Item -Path $mofPath\* -Include '*.mof' -Verbose
  Remove-Item -Path "$mofPath\ToBeInjected\*" -Verbose

  Write-Verbose -Message "Copying the 'localhost.meta.mof' from the Template '$templatePath'"
  Copy-Item -Path "$templatePath\localhost.meta.mof" -Destination "$mofPath\ToBeInjected\" -Force -Verbose
}

function Set-ArdyLabVMHost
{
  [CmdletBinding()]
  Param
  (   
    [parameter()]
    [switch]
    $RunNow
  )   

  DynamicParam 
  {
    $attributes = 
    New-Object -TypeName System.Management.Automation.ParameterAttribute
    $attributes.ParameterSetName = '__AllParameterSets'
    $attributes.Mandatory = $true
    $attributeCollection = 
    New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
    $attributeCollection.Add($attributes)
    $_Values = 
    (Get-ChildItem -Path "$env:ProgramData\ArdyLab\LabResources\ConfigurationData").name       
    $ValidateSet = 
    New-Object -TypeName System.Management.Automation.ValidateSetAttribute -ArgumentList ($_Values)
    $attributeCollection.Add($ValidateSet)
    $dynParam1 = 
    New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList (
    'ConfigFile', [string], $attributeCollection)
    $paramDictionary = 
    New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
    $paramDictionary.Add('ConfigFile', $dynParam1)
        
    return $paramDictionary 
  }

  Begin
  {
    Import-Module "C:\Program Files\WindowsPowerShell\Modules\ArdyLab\LabSetVMHost.ps1" -Force -NoClobber -Scope Local
  }
  
  Process
  {
    $LabRootPath = "$env:ProgramData\ArdyLab"
    $ConfigFile = 
    "$LabRootPath\LabResources\ConfigurationData\$($PSBoundParameters.ConfigFile)"
    
    ###
    $ConfigData = Get-Content $ConfigFile | ConvertFrom-Json | ConvertPSObjectToHashtable

    $mofPath = 
    Join-Path -Path $LabRootPath -ChildPath 'LabResources\GeneratedMOFs\'
        
    Write-Verbose -Message 'Generating the required MOF.'
    $mofFile = LabSetVMHost -ConfigurationData $ConfigData -OutputPath $mofPath
    
    Write-Verbose -Message "Created file '$mofFile'."
    
    # Run the DSC configuration now?
    if ($RunNow)
    {
      Write-Verbose -Message 'Executing the generated MOF.'
      Start-DscConfiguration -Path $mofPath -Wait
    
      Remove-DscConfigurationDocument -Stage Current, Pending -Verbose
    }
  }
  
  End
  {
    
  }
}

function New-ArdyLabNodeMOF
{
  [CmdletBinding()]
  Param()

  DynamicParam 
  {
    $attributes = 
    New-Object -TypeName System.Management.Automation.ParameterAttribute
    $attributes.ParameterSetName = '__AllParameterSets'
    $attributes.Mandatory = $true
    $attributeCollection = 
    New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
    $attributeCollection.Add($attributes)
    $_Values = 
    (Get-ChildItem -Path "$env:ProgramData\ArdyLab\LabResources\ConfigurationData").name       
    $ValidateSet = 
    New-Object -TypeName System.Management.Automation.ValidateSetAttribute -ArgumentList ($_Values)
    $attributeCollection.Add($ValidateSet)
    $dynParam1 = 
    New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList (
    'ConfigFile', [string], $attributeCollection)
    $paramDictionary = 
    New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
    $paramDictionary.Add('ConfigFile', $dynParam1)
        
    return $paramDictionary 
  }

  Begin
  {
    Import-Module "C:\Program Files\WindowsPowerShell\Modules\ArdyLab\LabCreateNodeMOF.ps1" -Force -NoClobber -Scope Local
  }

  Process
  {
    $LabRootPath = "$env:ProgramData\ArdyLab"
    $ConfigFile = "$LabRootPath\LabResources\ConfigurationData\$($PSBoundParameters.ConfigFile)"
    
    ###
    $ConfigData = Get-Content $ConfigFile | ConvertFrom-Json | ConvertPSObjectToHashtable
        
    $mofPath = Join-Path -Path $LabRootPath -ChildPath 'LabResources\GeneratedMOFs\'

    Write-Verbose -Message 'Generating a custom MOF for each VM, that will be injected during VM creation'
    $mofFile = LabCreateNodeMOF -ConfigurationData $ConfigData -OutputPath $mofPath\ToBeInjected\

    foreach ($file in $mofFile)
    {
      Write-Verbose -Message "Created file '$file'."
    }
  }
}

function Start-ArdyLabBuild
{
  [CmdletBinding()]
  Param
  (   
    [parameter()]
    [switch]
    $RunNow
  )

  DynamicParam 
  {
    $attributes = 
    New-Object -TypeName System.Management.Automation.ParameterAttribute
    $attributes.ParameterSetName = '__AllParameterSets'
    $attributes.Mandatory = $true
    $attributeCollection = 
    New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
    $attributeCollection.Add($attributes)
    $_Values = 
    (Get-ChildItem -Path "$env:ProgramData\ArdyLab\LabResources\ConfigurationData").name       
    $ValidateSet = 
    New-Object -TypeName System.Management.Automation.ValidateSetAttribute -ArgumentList ($_Values)
    $attributeCollection.Add($ValidateSet)
    $dynParam1 = 
    New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList (
    'ConfigFile', [string], $attributeCollection)
    $paramDictionary = 
    New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
    $paramDictionary.Add('ConfigFile', $dynParam1)
        
    return $paramDictionary 
  }

  Begin
  {
    Import-Module "C:\Program Files\WindowsPowerShell\Modules\ArdyLab\LabBuildVM.ps1" -Force -NoClobber -Scope Local
  }

  Process
  {
    $LabRootPath = "$env:ProgramData\ArdyLab"
    $ConfigFile = "$LabRootPath\LabResources\ConfigurationData\$($PSBoundParameters.ConfigFile)"
        
    $mofPath = Join-Path -Path $LabRootPath -ChildPath 'LabResources\GeneratedMOFs\'    

    Write-Verbose -Message 'Generating a MOF that can be run on the Hyper-V host computer to create the required VMs'
    $mofFile = LabBuildVM -ConfigurationData $ConfigFile -OutputPath $mofPath
        
    Write-Verbose -Message "Created file '$mofFile'."

    # Run the DSC configuration now?
    if ($RunNow)
    {
      Write-Verbose -Message 'Executing the generated MOF.'
      Start-DscConfiguration -Path $mofPath -Wait

      Remove-DscConfigurationDocument -Stage Current, Pending -Verbose
    }    
  }
}

function Invoke-ArdyLabDscRemote
{
  [CmdletBinding()]
  Param()

  DynamicParam 
  {
    $attributes = 
    New-Object -TypeName System.Management.Automation.ParameterAttribute
    $attributes.ParameterSetName = '__AllParameterSets'
    $attributes.Mandatory = $true
    $attributeCollection = 
    New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
    $attributeCollection.Add($attributes)
    $_Values = 
    (Get-ChildItem -Path "$env:ProgramData\ArdyLab\LabResources\ConfigurationData").name       
    $ValidateSet = 
    New-Object -TypeName System.Management.Automation.ValidateSetAttribute -ArgumentList ($_Values)
    $attributeCollection.Add($ValidateSet)
    $dynParam1 = 
    New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList (
    'ConfigFile', [string], $attributeCollection)
    $paramDictionary = 
    New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
    $paramDictionary.Add('ConfigFile', $dynParam1)
        
    return $paramDictionary 
  }

  Process
  {
    $LabRootPath = "$env:ProgramData\ArdyLab"
    $ConfigFile = "$LabRootPath\LabResources\ConfigurationData\$($PSBoundParameters.ConfigFile)"
        
    #$fullConfigFile = Resolve-Path  $ConfigFile
    $configData = Invoke-Expression -Command "DATA { $(Get-Content -Path $($ConfigFile) -Raw)}"
    $remoteVM = @()

    foreach ($node in ($configData.AllNodes).where{
        $_.NodeName -ne '*' 
    })
    {
      $remoteVM += @{
        Name = $node.NodeName
        IP   = ($node.IP4Addr -split '/')[0]
      }
    }

    # update to set cred for each node in $remoteVM
    $credAdminName = ($configData.AllNodes).where{
      $_.NodeName -eq '*' 
    }.AdminName
    $credAdminPw = ConvertTo-SecureString -String ($configData.AllNodes).where{
      $_.NodeName -eq '*' 
    }.AdminPassword -AsPlainText -Force
    $credAdmin = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $credAdminName, $credAdminPw

    # Use CimSession for compatibility with linux nodes
    $sessions = New-CimSession -ComputerName $remoteVM.IP -Credential $credAdmin

    Start-DscConfiguration -CimSession $sessions -UseExisting -Wait -Verbose -Force

    #Invoke-CimMethod -CimSession $sessions -Verbose -Namespace root/Microsoft/Windows/DesiredStateConfiguration -ClassName MSFT_DSCLocalConfigurationManager -MethodName PerformRequiredConfigurationChecks -Arg @{
    #  Flags = [uint32]3
    #}
  }
}

function ConvertPSObjectToHashtable
{
# Credit:: Dave Wyatt
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process
    {
        if ($null -eq $InputObject) { return $null }

        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
        {
            $collection = @(
                foreach ($object in $InputObject) { ConvertPSObjectToHashtable $object }
            )

            Write-Output -NoEnumerate $collection
        }
        elseif ($InputObject -is [psobject])
        {
            $hash = @{}

            foreach ($property in $InputObject.PSObject.Properties)
            {
                $hash[$property.Name] = ConvertPSObjectToHashtable $property.Value
            }

            $hash
        }
        else
        {
            $InputObject
        }
    }
}

