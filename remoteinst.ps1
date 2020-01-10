########## Get the exe download off the site, in this case an IIS site off an azure server, this could be the clients website or an organizations repo for client nms exe's ##########

wget http://serverIP/filename

########## Enable PS security prerequisites ##########

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

Set-Service -Name WinRM -StartupType Automatic | Restart-Service

Enable-PSRemoting -Force -SkipNetworkProfileCheck


########## Declare the hostname ##########

$Computer=$env:ComputerName

########## Define the windows path to the downloaded file ##########

$execFolder=Get-ItemPropertyValue 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\' -Name '{374DE290-123F-4565-9164-39C4925E467B}'

########## Install Software On PC ##########

New-Item -ItemType directory -Path "\\$Computer\c$\temp\1510WindowsAgentSetup"

    Copy-Item "$execFolder\1510WindowsAgentSetup*.exe" "\\$Computer\c$\temp\1510WindowsAgentSetup" -Recurse

    Write-Host "Installing the Organizations's Ncentral remote software on $Computer"


    Invoke-CommandAs -ComputerName $Computer -ScriptBlock {Start-Process "c:\temp\1510WindowsAgentSetup\1510WindowsAgentSetupx86.exe" -ArgumentList "/q" -Wait} 

######### Create admin accounts for NMS #######

$password=N3t5ur!tis5tr0nG
New-LocalUser -Name "localadmin01" -Password $password -AccountNeverExpires -Description "Organization's local admin account for remote support" 
Add-LocalGroupMember -Group "administrators" -Member "localadmin01" 
    
########## Cleanup all the resources ##########

    Write-Host "Removing Temporary files on $Computer"
    $RemovalPath = "\\$Computer\c$\temp\1510WindowsAgentSetup"
    Get-ChildItem  -Path $RemovalPath -Recurse  | Remove-Item -Force -Recurse
    Remove-Item $RemovalPath -Force -Recurse
    Disable-PSRemoting
