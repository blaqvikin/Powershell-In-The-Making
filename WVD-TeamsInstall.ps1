
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

       #####################################
          # Onedrive Uninstall and re-install #
       #####################################
         #############
         # Variables #
         #############

$Folder = 'c:\temp\Onedrive'
        $source = 'https://go.microsoft.com/fwlink/?linkid=844652'
                $destination = 'c:\temp\Onedrive\OneDriveSetup.exe'

##### Test to see if Folder exists ######
    if (Test-Path -Path $Folder) {
    ​​​​​
        "Path exists!"
            }​​​​​ else { ​​​​​
                MD c:\temp\Onedrive
}​​​​​

########## Download the Onedrive Setup file ############
    Invoke-WebRequest -Uri $source -OutFile $destination

########## Uninstall any existing OneDrive per-user installations ###########
        #c:\temp\Onedrive\OneDriveSetup.exe /uninstall

########## Set the AllUsersInstall registry value ###############
                REG ADD "HKLM\Software\Microsoft\OneDrive" /v "AllUsersInstall" /t REG_DWORD /d 1 /reg:64 /f
    #Install OneDrive in per-machine mode
                c:\temp\Onedrive\OneDriveSetup.exe /allusers
        #Configure OneDrive to start at sign in for all users:
                REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDrive /t REG_SZ /d "C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe /background" /f
#Enable Silently configure user account
                REG ADD "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v "SilentAccountConfig" /t REG_DWORD /d 1 /f
        #Redirect and move Windows known folders to OneDrive

            #Change Tenant ID
                REG ADD "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v "KFMSilentOptIn" /t REG_SZ /d "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" /f # Enter Your own Tenant ID
                #Microsoft Teams Installation Optimized for WVD
                REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Teams" /v "IsWVDEnvironment" /t REG_DWORD /d 1 /f

                # Create Temp\Teams Directory
                    MD c:\temp\Teams

#Download and Install Visual C++
        # Source file location
            $source = 'https://aka.ms/vs/16/release/vc_redist.x64.exe'
# Destination to save the file
                $destination = 'c:\temp\Teams\vc_redist.x64.exe'

                #Download the file
                Invoke-WebRequest -Uri $source -OutFile $destination
                    c:\temp\teams\VC_redist.x64.exe /install /quiet /norestart
#Download and Install Remote Desktop WebRTC Redirector Service
    $source = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt'
# Destination to save the file
        $destination = 'c:\temp\Teams\MsRdcWebRTCSvc_HostSetup_1.0.2006.11001_x64.msi'

#Download the file
Invoke-WebRequest -Uri $source -OutFile $destination
    msiexec.exe /i "c:\temp\teams\MsRdcWebRTCSvc_HostSetup_1.0.2006.11001_x64.msi" /quiet /norestart

    #Download and Install Microsoft Teams
        $source = 'https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true'

        # Destination to save the file
            $destination = 'c:\temp\Teams\Teams_windows_x64.msi'

#Download the file
Invoke-WebRequest -Uri $source -OutFile $destination
    msiexec.exe /i "c:\temp\teams\Teams_windows_x64.msi" /l*v c:\temp\teams\teams.log ALLUSER=1 /quiet /norestart
        set-timezone "South Africa Standard Time"
            C:\Program Files (x86)\Teams Installer\Teams.exe