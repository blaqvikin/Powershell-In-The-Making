<# Date: 14/03/2022
Version: 0.0.1
Author: MawandaH@inobits.com
Title:  This script install Azure Point-To-Site (P2S) vpn agent, more on log P2S @ "https://docs.microsoft.com/en-us/azure/virtual-wan/certificates-point-to-site"
Repository: https://github.com/blaqvikin/PowerShell 
#>

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser #Enable execution of PS scripts.

#Sets the default Windows Downloads dir
$DownloadsFolder=Get-ItemPropertyValue 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\' -Name '{374DE290-123F-4565-9164-39C4925E467B}'

    #Downloaded files dir,
$vpnFolder = New-Item -Path c:\temp\vpn -ItemType Directory -Force

   Invoke-WebRequest -uri "<source download>" `
   -OutFile $vpnFolder\<vpnDownloadFile>

#cd -Path $vpnFolder #Change into dir

Expand-Archive $vpnFolder\<vpnDownloadFile> -DestinationPath C:\temp\vpn\ #Extract the archive

$secureString = convertto-securestring "<exportedChildCertPassword>" -AsPlainText -force #Password for the client certificate

   Import-PfxCertificate -FilePath $vpnFolder\WindowsAmd64\<exportedChildCert> `
   -CertStoreLocation Cert:\CurrentUser\My -Password $secureString #Import the child cert with password

#Read-Host -Prompt "On the following prompt please select YES to install the VPN agent, press ENTER to continue"

   #Install vpnClientSetupAmd64
Invoke-Command -ScriptBlock {Start-Process $vpnFolder\WindowsAmd64\VpnClientSetupAmd64.exe}

Start-Sleep -Seconds 3 #Wait 3 seconds for other processes to complete

Remove-Item -Path $vpnFolder -Recurse #Remove the folder and all its contents.