<# Title: Custom Script Extension or Custom Alignment Script Extension
Description: This script is called via another script, the control script, this script executes several pieces of code to install/ uninstall some apps.
Assumptions: The uninstall codes are fixed and will need to be updated.
Author: Mawanda.Mlalandle@outlook.com
 #>
 Param
 (
     [Parameter(Mandatory=$true)][string]$CSEVersion
 )
 <# 
 Title: New update for version v0.0.4 
 Date: 05/June/2024
 Version: 0.0.4
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
Date: 07/June/2024
Updates:
--------
1. Fixed an issue with the Write-Log function, it was not being called. Supplied the correct syntax to -filepath.
2. Fixed an issue with the Flexera installation, there were unreadable characters causing the script to break at the Start-Process command.
3. Updated the Microsoft MDE onboarding script to the latest from the MDE team.
----------------------------------------------------------------------------------------
 Date: 05/June/2024
 Updates:
 --------
 1. Added the removal of the McAfee AV agent also known as Trelix
 2. Added a verification script, that collects the info regarding the McAfee AV and it's status.
 3. Updated the Microsoft Monitoring Agent removal code, from using static fields to using a dynamic app search and removal process.
 4. Added a function to store the Flexera agent installation status.
----------------------------------------------------------------------------------------
 #>
 # Script to install agents
 # Download the McAfee / Trellix cerification script
 $FlexeraAgent = "Flexnet Inventory Agent" #Install
 $CentrifyClient = "CentrifyAgentForWindows64.msi" #Install
 $ChefClient = "Chef.msi" #Uninstall
 $Rapid7Client = "Rapid7ForWindows.msi" #Uninstall
 $MMAAgent = "MMAAgent.exe" #Uninstall
 $Date = Get-Date
 
 #################################################################
 #Let's define some important variables to use later
 #################################################################
 
 # Create a directory to hold the agent files
 if (Test-Path C:\Windows\) {
     #"Folder already exits. Will use it"
 }
 else {
     new-item 'C:\Windows\' -ItemType directory -force
 }
 
 #Create Log File
 if (Test-Path C:\Windows\\Execution.log) {
     #"Log file already exists. Will use it"
 }
 else {
     new-item "C:\Windows\\Execution.log" -ItemType File -force
 }
 # Function to write to log
 function Write-Log {
     param (
         [string]$message
     )
     $Log = "C:\Windows\\Execution.log"
     $message | Out-File $Log -Append
 }
 # Define log file
 Write-Log -FilePath $Log "Starting run on $Date"
 Write-Log "CSE Version for this execution is $CSEVersion"

#########################################################################
 #Uninstall the McAfee/Trelix AV
 ########################################################################
 Write-Log "Now we remove McAfee at $Date"

 # Run a validation for the existence of the EndpointProductRemoval, if the file exists, we can assume that the McAfee AV has been removed else, remove it.
 $EndpointProductRemovalFileCheck = "C:\Windows\\EndpointProductRemoval.exe"
 $agentUninstallURL = "<URL>"
 $agentUninstallOutput = "C:\Windows\\EndpointProductRemoval.exe"
 
 # Check if the file exists and its last modified date
 if (Test-Path $EndpointProductRemovalFileCheck) {
     $lastModifiedDate = (Get-Item $EndpointProductRemovalFileCheck).LastWriteTime
 } else {
     $lastModifiedDate = (Get-Date).AddDays(-61) # Set a past date if the file does not exist
 }
 
 if (-Not (Test-Path $EndpointProductRemovalFileCheck) -or $lastModifiedDate -lt (Get-Date).AddDays(-60)) {
     # Remove the file if it exists and is older than 60 days, the McAfee team @RadhilR will advise you further on this.
     if (Test-Path $EndpointProductRemovalFileCheck) {
         Remove-Item $EndpointProductRemovalFileCheck -Force
         Write-Host "The old file has been removed." -ForegroundColor Cyan
     }
     # Download the new file from our Azure blob storage, the SAS token is only valid for 60 days from 24/05/2024
     Invoke-WebRequest -Uri $agentUninstallURL -OutFile $agentUninstallOutput
     Write-Host "The file is either missing or old, downloading the new version" -ForegroundColor Cyan
 }
 # Disable Smart-screen filter as this can hinder the install
 Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\' -Name SmartScreenEnabled -Value "0" -Force
 Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System\' -Name SmartScreenEnabled -Value "0" -Force
 Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object Publisher -Like * | Select-Object DisplayName, Publisher, DisplayVersion, InstallDate >> C:\Windows\\PreInstalledApps.txt
 
 # Start the removal of McAfee / Trellix
 Invoke-Command -ScriptBlock {Start-Process "C:\Windows\\EndpointProductRemoval.exe" -ArgumentList "--accepteula --ALL --NOREBOOT"} 
 Write-Host "Running the McAfee removal tool" -ForegroundColor DarkGreen >> $Log
 
 # Wait 5 seconds
 Start-Sleep -Seconds 30 
 Write-Host "Waiting 30 seconds for other processes to complete" -ForegroundColor DarkYellow >> $Log 
 
 # Enable Defender and smartscreen
 Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection' -Name ForceDefenderPassiveMode -Value "0"
 Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\' -Name SmartScreenEnabled -Value "1"
 Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System\' -Name SmartScreenEnabled -Value "1"
 
# Download the McAfee/Trelix AV removal verification script, this is used to store results and insert them into our custom script extension Azure SQL database records.
Write-Log "Now we process the McAfee removal verification script"
$McAfeeRemovalVerificationDownloadUrl = "<URL>"
$McAfeeRemovalVerificationDownloadedFile = "C:\Windows\\Get-ForceDefenderPassiveMode.ps1"

if (-Not(Test-Path $McAfeeRemovalVerificationDownloadedFile)) {
    Invoke-WebRequest -UseBasicParsing -Uri $McAfeeRemovalVerificationDownloadUrl -OutFile $McAfeeRemovalVerificationDownloadedFile
    Write-Host "Downloading the verification script" -ForegroundColor DarkGreen
} else {
    Write-Host "The verification script already exists, skipping download" -ForegroundColor Cyan >> $Log
}

 Write-Host "Downloading the verification Script" -ForegroundColor DarkGreen >> $Log
 Write-Host "We are done processing the McAfee removal process at $Date" >> $Log
  ########################################################################
 #Uninstall the Chef agent
 ########################################################################
 
 Write-Log "Processing of the Chef agent was started at $Date"
 $software = "Chef*";
 $installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like $software })
 
 If(!($installed)) 
 {
     "$software NOT installed." >> $Log
     Write-Log "Now we install the Chef Client"
     $msiargs = "/i c:\Windows\\$ChefClient /l*v c:\Windows\\CCmsilog.txt /qn /norestart" 
     $return = Start-Process msiexec -ArgumentList $msiargs -Wait -PassThru
     $ExitCode = $return.ExitCode
     if (@(0,3010) -contains $return.ExitCode)
     {
         Write-Log "Exit code is $ExitCode"
         Write-Log "Chef Client installed Successfully"
     }
     else 
     {
         Write-Log "Exit code is $ExitCode"
         Write-Log "Install of Chef Client failed. Please fix" 
     }
 } 
 else 
 {
   Write-Log "$software is already installed, Skipping install"
 }
 Write-Log "Processing of the Chef agent was completed at $Date"
 
########################################################################
# Install the Flexera agent
########################################################################

# Define a function to store Flexera installation status
function Get-FlexeraStatus {
    $flexeraStatus = wmic product get name | findstr /I "Flex"
    return $flexeraStatus.Trim()  # Remove leading/trailing whitespace
  }
  
  # Process the Flexera Agent for Windows
  Write-Log "Processing of the Flexera Agent for Windows was started at $Date"
  
  # Download URL and file paths
  $FlexeraAgentForWindowsDownloadUrl = "<URL>"
  $FlexeraAgentDownloadedFile = "C:\Windows\AzureCloudWindows.zip"
  $ExtractedFolder = "C:\Windows\"
  
  # Check if download file and extracted folder exist
  if (Test-Path $FlexeraAgentDownloadedFile) {
    Write-Log "Flexera download file and extracted folder already exist. Skipping download and extraction."
  } else {
    # Download and extract files if not found
    Write-Host "Downloading the Flexera Agent" -ForegroundColor DarkGreen
    Invoke-WebRequest -UseBasicParsing -Uri $FlexeraAgentForWindowsDownloadUrl -OutFile $FlexeraAgentDownloadedFile
  }
  # The file already exists due to prior execution, therefore continue with the code execution.  
    Write-Log "Extracting the downloaded zip file"
    Expand-Archive -Path $FlexeraAgentDownloadedFile -DestinationPath "C:\Windows\" -Force

  # Continue with Flexera processing
  Write-Log "Now we process Flexera"
  
  # Get Flexera status before installation
  $FlexeraStatusBefore = Get-FlexeraStatus
  
  # Check if software is installed
  $software = "FlexNet*"
  $installed = wmic product get name | findstr /I "Flex"
  
  if (-not $installed) {
    Write-Log "$software not installed."
    Write-Log "Now installing the Flexera Client"
  
    # Define install path and arguments
    $Flex_Exe_Path = "C:\Windows\\Azure Cloud Windows\"
    $msiargs = "/S /v/qn "
  
  Set-Location -Path $Flex_Exe_Path
    # Start the installation process
    $return = Start-Process -FilePath $Flex_Exe_Path\setup.exe -ArgumentList $msiargs -Wait -PassThru
    Start-Sleep 30
    $ExitCode = $return.ExitCode
  
    # Check the exit code to determine success or failure
    if (@(0, 3010) -contains $ExitCode) {
      Write-Log "Exit code is $ExitCode"
      Write-Log "Flexera Client installed successfully."
    } else {
      Write-Log "Exit code is $ExitCode"
      Write-Log "Installation of Flexera Client failed. Please fix."
    }
  } else {
    Write-Log "$software is already installed. Skipping install."
  }

  # Get Flexera status after installation
  $FlexeraStatusAfter = Get-FlexeraStatus
  
  # Store the Flexera installation statuses for later use, we are going to extract the results into a SQL database via the main control script of the CSE
  $FlexeraInstallationStatus = @{
    "Before" = $FlexeraStatusBefore
    "After" = $FlexeraStatusAfter
  }
  Write-Log "Processing of the Flexera Agent for Windows was completed at $Date"
  
  # I am keeping this for testing, later this will not be needed as the data will be in SQL database.
  Write-Host "Flexera Installation Status:"
  Write-Host "  Before: $($FlexeraInstallationStatus['Before'])"
  Write-Host "  After: $($FlexeraInstallationStatus['After'])"
  
##########################################################################
 #Uninstall Rapid 7
 ########################################################################
 Write-Log "Processing of the Rapid7 Agent for Windows was started at $Date"
 
 # Replace the name of the app as needed.
 $uninstallApp = "Rapid*" 
 
 # Check for application using registry
 $installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "*$uninstallApp*" } | Select-Object UninstallString)
 $uninstallString = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "*$uninstallApp*" } | Select-Object -ExpandProperty UninstallString
 
 Write-Host "UninstallString: $uninstallString"
 if ($uninstallString) {
     # Check if the uninstall string contains msiexec (for MSI installers)
     if ($uninstallString -match "msiexec") {
         # If it's an MSI uninstall string, add the silent uninstall arguments
         $silentUninstallString = "$uninstallString /quiet"
     } else {
         # Otherwise, just add the silent uninstall arguments directly
         $silentUninstallString = "$uninstallString /quiet"
     }
 
     # Execute the silent uninstall
     Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "$silentUninstallString" -Wait -NoNewWindow
 } else {
     Write-Warning "UninstallString not found for '$uninstallApp'"
 }
 Write-Log "Processing of the Rapid7 Agent for Windows was completed at $Date"
 
 ########################################################################
 #Uninstall the Microsoft Monitoring Agent
 ########################################################################
 Write-Log "Processing of the Microsoft Monitoring Agent for Windows was started at $Date"
 
 Write-Log "Checking Microsoft Monitoring Agent installation..."
 $softwareName = "Microsoft Monitoring Agent"
 # Check if the software is installed using wmic
 $installedSoftware = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE '%$softwareName%'"
 
 if ($installedSoftware) {
     Write-Host "$softwareName is installed. Proceeding with uninstallation." >> $Log
 
     # Uninstall the software using wmic
     foreach ($software in $installedSoftware) {
         $uninstallResult = $software.Uninstall()
 
         # Check the result of the uninstallation process
         if ($uninstallResult.ReturnValue -eq 0) {
             Write-Host "$softwareName was uninstalled successfully." >> $Log
         } else {
             Write-Warning "Failed to uninstall $softwareName. ReturnValue: $($uninstallResult.ReturnValue)" >> $Log
         }
     }
 } else {
     Write-Host "$softwareName is not installed." >> $Log
 } 
 Write-Log "Processing of the Microsoft Monitoring Agent for Windows was completed at $Date"
 
 ########################################################################
 #Uninstall Cybereason Sensor
 ########################################################################
 Write-Log "Processing of the Cybereason Agent for Windows was started at $Date"
 
 # Define the application name to be checked and uninstalled
 $softwareName = "Cybereason"
 
 $installedSoftware = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE '%$softwareName%'"
 
 if ($installedSoftware) {
     Write-Host "$softwareName is installed. Proceeding with uninstallation." >> $Log
 
     # Uninstall the software using wmic
     foreach ($software in $installedSoftware) {
         $uninstallResult = $software.Uninstall()
 
         # Check the result of the uninstallation process
         if ($uninstallResult.ReturnValue -eq 0) {
             Write-Host "$softwareName was uninstalled successfully." >> $Log
         } else {
             Write-Warning "Failed to uninstall $softwareName. ReturnValue: $($uninstallResult.ReturnValue)" >> $Log
         }
     }
 } else {
     Write-Log "$softwareName is not installed."
 }
 Write-Log "Processing of the Cybereason Agent for Windows was completed at $Date"
 
 ########################################################################
 #Uninstall Chef Infra Client
 ########################################################################
 Write-Log "Processing of the Chef Agent for Windows was started at $Date"
 
 # Define the application name to be checked and uninstalled
 $softwareName = "Chef"
 
 # Check if the software is installed using wmic
 $installedSoftware = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE '%$softwareName%'"
 
 if ($installedSoftware) {
     Write-Host "$softwareName is installed. Proceeding with uninstallation."
 
     # Uninstall the software using wmic
     foreach ($software in $installedSoftware) {
         $uninstallResult = $software.Uninstall()
 
         # Check the result of the uninstallation process
         if ($uninstallResult.ReturnValue -eq 0) {
             Write-Host "$softwareName was uninstalled successfully."
         } else {
             Write-Warning "Failed to uninstall $softwareName. ReturnValue: $($uninstallResult.ReturnValue)"
         }
     }
 } else {
     Write-Host "$softwareName is not installed."
 }
 Write-Log "Processing of the Chef Agent for Windows was completed at $Date"
 
 ########################################################################
 #Processing of the MDE onboarding
 ########################################################################
 # Now we do MDE Onboarding
 Write-Log "We can now do the MDE Onboarding at $Date"
 
 # Verify the OS name to apply the onboarding script, only 2019 and 2022 are supported.
 #$OSName = (Get-ComputerInfo).OSName
 $OsDistro = (Get-ComputerInfo).WindowsProductName
 Write-Host "OS version is $OsDistro" >> $Log
 
 $MDEAgentDownloadedFilePath = "<URL>"
 
 if ($OsDistro -like "*2019*" -or $OsDistro -like "*2022*") {
   # Check if the MDE agent file exists, we are querying the existence of this file as means to confirm onboarding, this is due to the new version of the onboarding script that was availed by the MDE team.
   if (!(Test-Path -LiteralPath $MDEAgentDownloadedFilePath)) {
     Write-Host "MDE agent file not found. Downloading..." >> $Log
 
     # Download the MDE agent
     $MDEAgentDownloadURL = "<URL>"
     Invoke-WebRequest -UseBasicParsing -Uri $MDEAgentDownloadURL -OutFile $MDEAgentDownloadedFilePath
 
     Write-Host "Downloaded MDE agent file." >> $Log
   } else {
     Write-Host "MDE agent file already exists. Assuming software might be installed." >> $Log
   }
   # Installation logic assuming the file exists now (downloaded or previously present)
   Write-Host "Installing MDE on $OSName" >> $Log
   Start-Process $MDEAgentDownloadedFilePath -Wait
   Write-Host "Installed the MDE onboard agent" >> $Log
 } else {
   Write-Host "The software is not supported on $OsDistro." >> $Log
   # I think we are done here, I'm not 100% happy with the code section above, but it works.
 }
 Write-Host "Processing of the MDE onboarding was completed at $Date" >> $Log
   #>
 #Now we clean up legacy Shared Image Gallery initiator if needed.
 "Now that machine is aligned, lets remove the runonce from Shared Image Gallery deployemnt if it still exists" >> $Log
 $KeyName = ''
 if ((Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Run).$KeyName)
 {
     Remove-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Run -Name $KeyName 
 }
 ##
 if (Test-Path C:\Windows\\Policy.installed)
 {
    Write-Log "Local Security Policy already installed"
 }
 else
 {
     Write-Log "Now we install the local security policy"
     start-process C:\Windows\\sbinst.cmd -Wait 
     New-Item -Path C:\Windows\\ -Name "CSE.installed" -ItemType "file" -Value "Policy installed on $date."
     "Policy installed" >> $Log    
     "Disable TLS 1.0" >> $Log
     New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server' -Force | Out-Null
     New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
     New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server' -name 'DisabledByDefault' -value 1 -PropertyType 'DWord' -Force | Out-Null
     New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client' -Force | Out-Null
     New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
     New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client' -name 'DisabledByDefault' -value 1 -PropertyType 'DWord' -Force | Out-Null
     Write-Host 'TLS 1.0 has been disabled.'
 
     "Disable TLS 1.1" >> $log
     New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server' -Force | Out-Null
     New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
     New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server' -name 'DisabledByDefault' -value 1 -PropertyType 'DWord' -Force | Out-Null
     New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client' -Force | Out-Null
     New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
     New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client' -name 'DisabledByDefault' -value 1 -PropertyType 'DWord' -Force | Out-Null
     Write-Host 'TLS 1.1 has been disabled.'
 
     "Enable TLS 1.2" >> $Log
     New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -Force | Out-Null
     New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -name 'Enabled' -value '1' -PropertyType 'DWord' -Force | Out-Null
     New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -name 'DisabledByDefault' -value 0 -PropertyType 'DWord' -Force | Out-Null
     New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -Force | Out-Null
     New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -name 'Enabled' -value '1' -PropertyType 'DWord' -Force | Out-Null
     New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -name 'DisabledByDefault' -value 0 -PropertyType 'DWord' -Force | Out-Null
     Write-Host 'TLS 1.2 has been enabled.'
 
     "Sending message to console" >> $Log
     $name = "Localhost"
     $msg = "Hello fellow Azurian.`
     Mandatory Bank Policy and Software has been installed which requires a reboot.`
     Please reboot this machine asap."
     Invoke-WmiMethod -Path Win32_Process -Name Create -ArgumentList "msg * $msg" -ComputerName $name
 }
 $EndDate = Get-Date
 Write-Log "Script run complete at $EndDate"
 