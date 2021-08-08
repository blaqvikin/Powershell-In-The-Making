Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser #Enable execution of PS scripts.

    #Declare the downloads folder, this is default reg key for all Windows machines
$DownloadsFolder=Get-ItemPropertyValue 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\' -Name '{374DE290-123F-4565-9164-39C4925E467B}'

   Invoke-WebRequest -uri "https://demowvdsto.blob.core.windows.net/public/Fund-Prod-VNet-Gw.zip?sv=2020-04-08&si=RL-EOL-DEC&sr=b&sig=ODuFgTJhjI1vfvC1USY%2BZWBpJ%2FHf3DYVVR1szt2lBoQ%3D" `
   -OutFile $DownloadsFolder\Fund-Prod-VNet-Gw.zip
    
   Expand-Archive $DownloadsFolder\Fund-Prod-VNet-Gw.zip #Extract the zip file

   Import-Certificate -FilePath $DownloadsFolder\Fund-Prod-VNet-Gw\Fund-Prod-VNet-Gw\Generic\VpnServerRoot.cer `
   -CertStoreLocation Cert:\LocalMachine\CA  #Import the root certificate

$secureString = convertto-securestring "Fund1_K3y$" -AsPlainText -force

   Import-PfxCertificate -FilePath $DownloadsFolder\Fund-Prod-VNet-Gw\Fund-Prod-VNet-Gw\Generic\Fundchildcert.pfx `
   -CertStoreLocation Cert:\CurrentUser\My -Password $secureString #Import the child cert with password

   Invoke-Command -ScriptBlock {Start-Process $DownloadsFolder\Fund-Prod-VNet-Gw\Fund-Prod-VNet-Gw\WindowsAmd6\VpnClientSetupAmd64.exe} #Install the VPN client software.