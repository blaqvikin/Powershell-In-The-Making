########## Script to rollout software installation on remote computers.

$ExecFolder='C:\temp\AppsToInstall\AppsToInstall\'

Set-Location $ExecFolder

reg import .\DisableLockScreen.reg #Disable lockscreen
reg import .\Disable_Privacy_settings_experience_on_user_logon.reg #Disable Privacy Experience

#Enable auto-logon
Start-Process ".\Autologon.exe" -ArgumentList "/accepteula","idexperiment","id-sl-vm-000","Buenosdiasatodos1"

$LocalC='c:\'

Set-Location $LocalC

#Download Phantom extension.
wget "https://csb1003200193460ff3.blob.core.windows.net/vmscripts/Phantom.zip?si=ScriptAccessPolicy&sv=2020-08-04&sr=b&sig=SIdRfvsmXtdEHgK8nrJ2%2B5evGBN76HwrVzy7ZwAZrCs%3D" -OutFile $LocalC\Phantom.zip

#Download Set Wallet script
wget "https://csb1003200193460ff3.blob.core.windows.net/vmscripts/SetWallet.zip?si=ScriptAccessPolicy&sv=2020-08-04&sr=b&sig=UgpuetmbN9ttRZUHr5Y%2FL4Fsrq%2Fhi5Sgdn9mqZJiFSA%3D" -OutFile $LocalC\SetWallet.zip

#Reboot the machine, auto login script will log the machine ON automatically.
$Computer=$env:ComputerName

Stop-Computer -ComputerName $Computer -Force