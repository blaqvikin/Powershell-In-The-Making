Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser #Enable execution of PS scripts.

    #Declare the downloads folder, this is default reg key for all Windows machines
$DownloadsFolder=Get-ItemPropertyValue 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\' -Name '{374DE290-123F-4565-9164-39C4925E467B}'

   Invoke-WebRequest -uri "https://mydownloadsite.com" `
   -OutFile $DownloadsFolder\ArchiveFolder.zip
    
   Expand-Archive $DownloadsFolder\ArchiveFolder.zip #Extract the zip file

$secureString = convertto-securestring "CertificatePassword" -AsPlainText -force

   Import-PfxCertificate -FilePath $DownloadsFolder\ArchiveFolder\Generic\ChildCert.pfx `
   -CertStoreLocation Cert:\CurrentUser\My -Password $secureString #Import the child cert with password

   Invoke-Command -ScriptBlock {Start-Process $DownloadsFolder\ArchiveFolder\Generic\WindowsAmd6\VpnClientSetupAmd64.exe} #Install the VPN client software.