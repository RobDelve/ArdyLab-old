<#
    .Synopsis
    ArdyLab DSC Resource to build a custom MOF for the computer 'locaclhost' that will create.

    .Description
   Run this to create a MOF to build VM's
   Run after you have completed 'LabBuildRoleMofs' as will inject each custom MOF to the correct VHD file during build.
    .TODO
    Add Error Checking and Verbose/Debug output
    Update to work with VmWare + accept a switch to specify which 'LabBuildVm***' to run.
#>
Configuration LabBuildVM
{    
    Import-DscResource -Name LabBuildVM_HyperV
    Import-DscResource -name LabCreateUnattendFile    

    node localhost
    {
        ## ArdyLab Resource that Installs Hyper-V Features on the LocalHost and Configure an 'Internal' vSwitch
        
        # Create a custom Unattend.xml then build a new VM and inject necessary files ready for 1st boot
        foreach ($vm in $AllNodes.where{$_.NodeName -ne '*'})
        {
            # ArdyLab Resource to Create a customised 'unattend.xml' for the node specified
            # Get the global Admin Name & Password to use as default values
            $GlobaladminName = ($AllNodes.where{$_.NodeName -eq '*'}).AdminName
            $GlobaladminPassword = ($AllNodes.where{$_.NodeName -eq '*'}).AdminPassword

            # Check each node for a AdminName / AdminPassword
            if ($vm.AdminName -ne $null) 
                { $_adminName = $vm.AdminName } 
            else
                { $_adminName = $GlobaladminName }

            if ($vm.AdminPassword -ne $null) 
                { $_adminPassword = $vm.AdminPassword } 
            else 
                { $_adminPassword = $GlobaladminPassword }

            # Populate the collection of files to be copied to the VHD of this node
            $CopyToVHD = @(
                            @{
                                Label = 'Unattend';
                                Source = Join-Path -Path $($ConfigurationData.LabConfig.FilePaths.Unattend.OutputFolder) -ChildPath "$($vm.NodeName)_unattend.xml";
                                Destination = 'unattend.xml';
                                Type = 'File'
                            },

                            @{
                                Label = 'NodeMof';
                                Source = Join-Path -Path $($ConfigurationData.LabConfig.FilePaths.GeneratedMOFs.RoleMOFs) -ChildPath "$($vm.NodeName).mof";
                                Destination = '\windows\system32\Configuration\Pending.mof';
                                Type = 'File'
                            },

                            @{
                                Label = 'NodeLcmMof';
                                Source = Join-Path -Path $($ConfigurationData.LabConfig.FilePaths.GeneratedMOFs.RoleMOFs) -ChildPath "localhost.meta.mof";
                                Destination = '\windows\system32\Configuration\metaconfig.mof';
                                Type = 'File'
                            },

                            @{
                                Label = 'AutoRun';
                                Source = $ConfigurationData.LabConfig.FilePaths.ToCopy.BootstrapFolder;
                                Destination = '\ArdyLab\';
                                Type = 'Directory'
                            }
                        )
            $modToCopy = @('xActiveDirectory','xComputerManagement','xDismFeature','xNetworking','xSQLServer','xSystemSecurity','xSmbShare','xStorage')
            $modCollection = @()
            
            foreach ($modName in $modToCopy)
            {
                $CopyToVHD += @{
                    Label = "$modName";
                    Source = "C:\Program Files\WindowsPowerShell\Modules\$modName\";
                    Destination = "\Program Files\WindowsPowerShell\Modules\$modName\"
                    Type = 'Directory'
                }
            }
                          

            LabCreateUnattendFile "$($vm.NodeName)_UnattendFile"
            {
                NodeName = $vm.NodeName
                IP4Addr = $vm.Ip4Addr
                AdminName = $_adminName
                AdminPassword = $_adminPassword
            }

            # ArdyLab Resource to Create a Hyper-V Virtual Machine for the specified node and inject required files to the VHDX that is created
            LabBuildVM_HyperV "$($vm.NodeName)"
            {
                NodeName = $vm.NodeName
                VSwitchName = $ConfigurationData.LabConfig.VSwitch.Name
                VHDTemplate = $vm.VHDTemplate                                              
                ProcessorCount = $vm.ProcessorCount
                MaximumMemory = $vm.MaximumMemory
                CopyToVHD = $CopyToVHD
            }

            # Check if we need to attach any additonal VHD(x) files to this VM
            # Having to use workaround as xHyper-V/xVMHyperV only allows to attach a single VHD(x)
            if ($vm.AttachVHD)
            {
                # Attach the VHD(x) on the Hyper-V host to this VM


            }
        }
    }
}
