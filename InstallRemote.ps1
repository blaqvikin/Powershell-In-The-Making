########## Enable PS security prerequisites ##########

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

Set-Service -Name WinRM -StartupType Automatic | Restart-Service

Enable-PSRemoting -Force -SkipNetworkProfileCheck

#Set-PSSessionConfiguration -Name InstallRemote.ps1 -NoServiceRestart
#Set-PSSessionConfiguration -ShowSecurityDescriptorUI -Name Microsoft.PowerShell

########## Declare the hostname ##########

$Computer=$env:ComputerName

########## Define the windows path to the downloaded file ##########

$execFolder=Get-ItemPropertyValue 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\' -Name '{374DE290-123F-4565-9164-39C4925E467B}'

########## Install Software On PC ##########

New-Item -ItemType directory -Path "\\$Computer\c$\temp\1510WindowsAgentSetup"

    Copy-Item "$execFolder\1510WindowsAgentSetup*.exe" "\\$Computer\c$\temp\1510WindowsAgentSetup" -Recurse

    Write-Host "Installing Netsurit's Ncentral remote software on $Computer"

    Invoke-Command -ComputerName $Computer -ScriptBlock {Start-Process "c:\temp\1510WindowsAgentSetup\1510WindowsAgentSetupx86.exe" -ArgumentList "/q" -Wait} 
    
########## Cleanup all the resources ##########

    Write-Host "Removing Temporary files on $Computer"
    $RemovalPath = "\\$Computer\c$\temp\1510WindowsAgentSetup"
    Get-ChildItem  -Path $RemovalPath -Recurse  | Remove-Item -Force -Recurse
    Remove-Item $RemovalPath -Force -Recurse
    Disable-PSRemoting
