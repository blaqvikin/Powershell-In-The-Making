########## Script to rollout software installation on remote computers.

#Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine

$CurrentConProfile = get-netconnectionprofile 
Set-NetConnectionProfile -Name $CurrentConProfile.Name -NetworkCategory Private           
                 
Set-Service -Name WinRM -StartupType Automatic | Restart-Service
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "10.6.0.*" -Concatenate 

#Create temp on c drive
#mkdir c:\temp\

#Declare variables
$LocalC='c:\'
$ExecFolder='C:\temp\'
$Computer=$env:ComputerName

#wget "http://www.inputdirector.com/downloads/InputDirector.v2.0.1.zip" -UseBasicParsing -OutFile $ExecFolder\InputDirector.v2.0.1.zip #Download Input Director
#Expand Input Director Install
#Expand-Archive C:\temp\InputDirector.v2.0.1.zip -Force

#Start-Process "$ExecFolder\InputDirector.v2.0.1\InputDirector.v2.0.1.build139.Setup.exe" -ArgumentList "/ACCEPTEULA" #Install Input Director

#Download automation scripts folder
wget "https://csb1003200193460ff3.blob.core.windows.net/vmscripts/AppsToInstall.zip?si=ScriptAccessPolicy&sv=2020-08-04&sr=b&sig=3P%2Fu59w0KCJXKQ8ogf9DpVs2thKkazASF%2BqsLbztn7A%3D" -UseBasicParsing -OutFile $ExecFolder\AppsToInstall.zip

Expand-Archive C:\temp\AppsToInstall.zip -Force

#Create ID experiment account
#$secureString = convertto-securestring "Buenosdiasatodos1" -asplaintext -force                                              
#$localacc = New-LocalUser -Name "idexperiment" -Description "Input Director Admin Account" -FullName "idexperiment" -AccountNeverExpires -PasswordNeverExpires -Password $secureString 
#Add-LocalGroupMember -Group "administrators" -Member $localacc

#Disable Lock screen, Enable Auto Logon 
reg import $ExecFolder\AppsToInstall\AppsToInstall\DisableLockScreen.reg #Disable lockscreen
reg import $ExecFolder\AppsToInstall\AppsToInstall\Disable_Privacy_settings_experience_on_user_logon.reg #Disable Privacy Experience

#Create Auto-Login Entry
New-ItemProperty 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -PropertyType "String" -Name "DefaultPassword" -Value "Buenosdiasatodos1"
New-ItemProperty 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -PropertyType "String" -Name "DefaultUsername" -Value "idexperiment"
New-ItemProperty 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -PropertyType "String" -Name "AutoAdminLogon" -Value "1"

#Disable Sleep and Hibernation
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name "HibernateEnabledDefault" -Value "0" #Disable hibernation
Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowPowerSleep' -Name "value" -Value "0" #Disable Sleep and Power

#Enable auto-logon
Start-Process "c:\temp\AppsToInstall\AppsToInstall\Autologon.exe" -ArgumentList "/accepteula","idexperiment","localhost","Buenosdiasatodos1"

#Download Chrome Default Profile 
wget "https://csb1003200193460ff3.blob.core.windows.net/vmscripts/Default.zip?si=ScriptAccessPolicy&sv=2020-08-04&sr=b&sig=5CeEX%2B706Xy%2F4hAum0ks9e6jGPPP6a4Ejxk1L68bS8U%3D" -OutFile $LocalC\Default.zip
taskkill /F /IM Google*
Expand-Archive -DestinationPath "C:\Users\idexperiment\AppData\Local\Google\Chrome\User Data\" -Path c:\Default.zip -Force
reg import $ExecFolder\AppsToInstall\AppsToInstall\ChromeProfile.reg

#Download Phantom extension.
wget "https://csb1003200193460ff3.blob.core.windows.net/vmscripts/Phantom.zip?si=ScriptAccessPolicy&sv=2020-08-04&sr=b&sig=SIdRfvsmXtdEHgK8nrJ2%2B5evGBN76HwrVzy7ZwAZrCs%3D" -OutFile $LocalC\Phantom.zip

#Download Set Wallet script
wget "https://csb1003200193460ff3.blob.core.windows.net/vmscripts/SetWallet.zip?si=ScriptAccessPolicy&sv=2020-08-04&sr=b&sig=UgpuetmbN9ttRZUHr5Y%2FL4Fsrq%2Fhi5Sgdn9mqZJiFSA%3D" -OutFile $LocalC\SetWallet.zip

Expand-Archive -Force C:\Phantom.zip #unzip to extensions folder. This location has been whitelisted on the AV
Expand-Archive -Force C:\SetWallet.zip #unzip to script folder. This location has been whitelisted on the AV

#Reboot the machine, auto login script will log the machine ON automatically.

Stop-Computer -ComputerName $Computer -Force