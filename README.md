**# README #

ArdyLab - Draft Readme

### How do I get set up? ###

* Copy the **'ArdyLab'** folder to **'C:\Program Files\WindowsPowerShell\Modules\ArdyLab'**
* Launch PowerShell console
* Run **Setup-ArdyLab**
* Create New/Edit **LabConfig.psd1** in **'C:\ProgramData\ArdyLab\LabResources\ConfigurationData'**
* Run **Initialize-ArdyLab -InstallModules**
* Run **Set-ArdyLabVMHost -RunNow -ConfigFile *LabConfig.psd1***
* *Reboot machine if Hyper-V was installed/updated*
* Run **New-ArdyLabNodeMOF -ConfigFile *LabConfig.psd1***
* Run **Start-ArdyLabBuild -RunNow -ConfigFile *LabConfig.psd1***
* Start the VM's



contact: rob.delve@infratects.com
