<# Date: 14/03/2022
Version: 0.0.2
Author: Mawanda.Mlalandle@Outlook.com
Title:  This script install Azure Point-To-Site (P2S) vpn agent, more on log P2S @ "https://docs.microsoft.com/en-us/azure/virtual-wan/certificates-point-to-site"
Repository: https://github.com/blaqvikin/PowerShell 
#>

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser #Enable execution of PS scripts.

#Sets the default Windows Downloads dir
$DownloadsFolder=Get-ItemPropertyValue 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\' -Name '{374DE290-123F-4565-9164-39C4925E467B}'

    #Downloaded files dir,
$vpnFolder = New-Item -Path c:\temp\vpn -ItemType Directory -Force

   Invoke-WebRequest -UseBasicParsing -uri "<DownloadURL>" `
   -OutFile $vpnFolder\<DownloadedFilename>.zip

#cd -Path $vpnFolder #Change into dir

Expand-Archive $vpnFolder\<DownloadedFilename>.zip -DestinationPath C:\temp\vpn\ #Extract the archive

$secureString = convertto-securestring '<CertififcatePassword>' -AsPlainText -force #Password for the client certificate, also ensure the password is enclsoed in single quotes

   Import-PfxCertificate -FilePath $vpnFolder\WindowsAmd64\<CertificateName>.pfx -CertStoreLocation Cert:\CurrentUser\My -Password $secureString #Import the child cert with password,

#Read-Host -Prompt "On the following prompt please select YES to install the VPN agent, press ENTER to continue"

   # Execute the VpnProfileSetup.ps1 script
cd $vpnFolder\WindowsPowershell

.\VpnProfileSetup.ps1

Start-Sleep -Seconds 3 #Wait 3 seconds for other processes to complete

Remove-Item -Path $vpnFolder -Recurse #Remove the folder and all its contents.