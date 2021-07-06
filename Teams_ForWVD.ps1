<#
Title: Install Azure Virtual Desktop Apps (Teams etc)
Version: 0.0.2
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
reg unload HKU\TempDefault

    # Set the Office Update UI behavior.
        reg add HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate /v hideupdatenotifications /t REG_DWORD /d 1 /f
            reg add HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate /v hideenabledisableupdates /t REG_DWORD /d 1 /f

#Uninstall any existing OneDrive per-user installations 
        $appToRemove= "Onedrive"
                $ObjLocalApp = $null 

Try {   
    Write-Verbose "Searching for ($appToRemove) in installed apps"
    
            $ObjLocalApp = Get-WmiObject -Class "win32_product" | Where-Object{$_.name -eq $appToRemove}               
}
    Catch [Microsoft.PowerShell.Commands.ProgramNotFoundException] {
           "$($appToRemove) was not found" | Write-Warning 
        }
            Catch 
                {"An unspecifed error occured" | Write-Error
                    Exit # Stop Powershell!
        }
    if ($ObjLocalApp)
        {
                 Write-Verbose "$($appToRemove) was found, uninstalling app wait!"
                              $ObjLocalApp.uninstall()
}

#Prepare Azure Virtual Desktop apps

$DownloadsFolder=Get-ItemPropertyValue 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\' -Name '{374DE290-123F-4565-9164-39C4925E467B}'

   wget -uri https://go.microsoft.com/fwlink/?linkid=84465 -OutFile $DownloadsFolder\OneDrive.exe -Verbose #Download OneDrive

    wget -uri https://aka.ms/vs/16/release/vc_redist.x64.exe -OutFile $DownloadsFolder\VisualC64.exe -Verbose #Download Visual C++

      wget -uri https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt -OutFile $DownloadsFolder\RemoteDesktopWebRTC.msi -Verbose  #Download Remote WebRTC

        wget -uri "https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true" -OutFile $DownloadsFolder\Teams.exe -Verbose #Download Teams
  
 Move-Item $DownloadsFolder\OneDrive.exe, $DownloadsFolder\VisualC64.exe, $DownloadsFolder\RemoteDesktopWebRTC.msi, $DownloadsFolder\Teams.exe -Force -Destination C:\temp #Move files to temp for execution
      
   Invoke-Command -ScriptBlock {Start-Process "C:\temp\OneDrive.exe" -ArgumentList "/q /alluser"} #Install OneDrive

      Invoke-Command -ScriptBlock {Start-Process "C:\temp\VisualC64.exe" -ArgumentList "/q"} #Install Visual C++

         Invoke-Command -ScriptBlock {Start-Process "C:\temp\RemoteDesktopWebRTC.msi" -ArgumentList "/q"} #Install Remote WebRTC

            Invoke-Command -ScriptBlock {Start-Process "msiexec.exe /i "c:\temp\teams\Teams_windows_x64.msi" /l*v c:\temp\teams\teams.log ALLUSER=1 /quiet /norestart"} #install Teams for VDI

        #Set timezone to +2
    set-timezone "South Africa Standard Time"

#Set the AllUsersInstall registry value ###############
                REG ADD "HKLM\Software\Microsoft\OneDrive" /v "AllUsersInstall" /t REG_DWORD /d 1 /reg:64 /f

        #Configure OneDrive to start at sign in for all users:
                REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDrive /t REG_SZ /d "C:\Program Files\Microsoft OneDrive\OneDrive.exe /background" /f

#Enable Silently configure user account
                REG ADD "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v "SilentAccountConfig" /t REG_DWORD /d 1 /f
                
        Get-AzTenant #Copy your tenant ID for the step below
        
            #Change Tenant ID
        
                REG ADD "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v "KFMSilentOptIn" /t REG_SZ /d "xxx-xxx-xxx-xxxx" /f # Enter Your own Tenant ID
        
            #Microsoft Teams Installation Optimized for WVD
                REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Teams" /v "IsWVDEnvironment" /t REG_DWORD /d 1 /f
                    
            #If a client is unable to use Media Optimizatons, what will happen.
                REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Teams" /v "DisableFallback" /t REG_DWORD /d 1 /f

    C:\Program Files (x86)\Teams Installer\Teams.exe #launch teams

    #Domain Join the machine if not part of the domain.
$DoaminName = Read-Host -Prompt "Enter your domain name"
    
    $DomainAdmin = Read-Host -Prompt "Enter your domain admin account"

 add-computer -DomainName $DoaminName -Credential $DomainAdmin -force #Join the machine to the domain.