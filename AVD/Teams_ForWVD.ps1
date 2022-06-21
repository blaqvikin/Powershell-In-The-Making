<#
Title: Install Azure Virtual Desktop Apps (Teams etc)
Version: 0.0.4
Prerequisite: Familiarity with Powershell
Author: Mawanda Hlophoyi
Credit: Johan De Ridder

Note: This script prepares the necessary Outlook registry keys for optimal performance for Office on AVD platform.
        Removes any current Onedrive for personal installation.
            Install Teams, OneDrive For Business, along with some apps for Teams for VDI
                Sets timezone to RSA (+2)
                    Joins the machine to the domain.
#>

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser #Enable execution of PS scripts.

# Mount the default user registry hive
    reg load HKU\TempDefault C:\Users\Default\NTUSER.DAT

#Must be executed with default registry hive mounted.
    reg add HKU\TempDefault\SOFTWARE\Policies\Microsoft\office\16.0\common /v InsiderSlabBehavior /t REG_DWORD /d 2 /f

# Set Outlook's Cached Exchange Mode behavior
# Must be executed with default registry hive mounted.

    reg add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v enable /t REG_DWORD /d 1 /f
    reg add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v syncwindowsetting /t REG_DWORD /d 1 /f
    reg add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v CalendarSyncWindowSetting /t REG_DWORD /d 1 /f
    reg add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v CalendarSyncWindowSettingMonths /t REG_DWORD /d 1 /f

# Unmount the default user registry hive
    reg unload HKEY_USERS\.DEFAULT

#Setup Microsoft Teams environment to be optimized for WVD/VDI
    REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Teams" /v "IsWVDEnvironment" /t REG_DWORD /d 1 /f

#When users connect from an unsupported endpoint, disable fallback mode.
    REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Teams" /v "DisableFallback" /t REG_DWORD /d 1 /f

# Set the Office Update UI behavior.
    reg add HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate /v hideupdatenotifications /t REG_DWORD /d 1 /f
    reg add HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate /v hideenabledisableupdates /t REG_DWORD /d 1 /f

#Prepare Azure Virtual Desktop apps, OneDrive, Teams, VisualC ++, Remote WebRTC

$DownloadsFolder=Get-ItemPropertyValue 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\' -Name '{374DE290-123F-4565-9164-39C4925E467B}'

   #wget -uri https://go.microsoft.com/fwlink/?linkid=844652 -OutFile $DownloadsFolder\OneDrive.exe -Verbose #Download OneDrive

    wget -uri https://aka.ms/vs/16/release/vc_redist.x64.exe -OutFile $DownloadsFolder\VisualC64.exe -Verbose #Download Visual C++

    wget -uri https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt -OutFile $DownloadsFolder\RemoteDesktopWebRTC.msi -Verbose  #Download Remote WebRTC

    wget -uri "https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true" -OutFile $DownloadsFolder\Teams.msi -Verbose #Download Teams
       
#Invoke-Command -ScriptBlock {Start-Process "C:\temp\OneDrive.exe" -ArgumentList "/q /alluser"} #Install OneDrive

    Invoke-Command -ScriptBlock {Start-Process $DownloadsFolder\VisualC64.exe -ArgumentList "/q /norestart"} #Install Visual C++

    Invoke-Command -ScriptBlock {Start-Process $DownloadsFolder\RemoteDesktopWebRTC.msi -ArgumentList "/q /norestart"} #Install Remote WebRTC

    Invoke-Command -ScriptBlock {Start-Process $DownloadsFolder\Teams.msi -ArgumentList "/l*v $DownloadsFolder\teams.log ALLUSER=1 /q /norestart"} #install Teams for VDI

#Set the AllUsersInstall registry value ###############
    REG ADD "HKLM\Software\Microsoft\OneDrive" /v "AllUsersInstall" /t REG_DWORD /d 1 /reg:64 /f

#Configure OneDrive to start at sign in for all users:
    REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDrive /t REG_SZ /d "C:\Program Files\Microsoft OneDrive\OneDrive.exe /background" /f

#Enable Silently configure user account
    REG ADD "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v "SilentAccountConfig" /t REG_DWORD /d 1 /f
                
#Copy your tenant ID for the step below
    REG ADD "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v "KFMSilentOptIn" /t REG_SZ /d "xxx-xxx-xxx-xxxx" /f # Enter Your own Tenant ID

#Domain Join the machine if not part of the domain.
    Set-Timezone "South Africa Standard Time" #Set Timezone to +2
    
    $DoaminName = Read-Host -Prompt "Enter your domain name"
    
    $Admin = Read-Host -Prompt "Enter your domain admin account"

    add-computer -DomainName $DoaminName -Credential $Admin -force #Join the machine to the domain.
    
    Restart-Computer -ComputerName $env:COMPUTERNAME # Reboot