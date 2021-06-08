<# Date: 22/12/2020
Version: 0.0.5
Author: Mawanda Hlophoyi
Prerequisites: Powershell  (Az Module, AD module, ), Domain Join Workstation, Access to the internet, Local administration privileges .
Assumptions: WVD domain groups created
Title: This script prepares the WVD environment, joins the azure storage into onprem AD, setup the FSLogix profile, mount the file share and setup the necessary permissions.
#>

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

#Declare the downloads folder, this is default reg key for all Windows machines
$DownloadsFolder=Get-ItemPropertyValue 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\' -Name '{374DE290-123F-4565-9164-39C4925E467B}'

#Download the AzFilesHybrid archive to the user downloads folder.

wget -uri https://github.com/Azure-Samples/azure-files-samples/releases/download/v0.2.3/AzFilesHybrid.zip -OutFile $DownloadsFolder\AzFilesHybrid.zip

Expand-Archive -LiteralPath $DownloadsFolder\AzFilesHybrid.zip -DestinationPath "C:\temp\"

Set-Location -Path "C:\temp\" #Change location to the temp dir

.\CopyToPSPath.ps1 

Import-Module -Name AzFilesHybrid #Import the downloaded module into PS

$SubscriptionId = "MySubscription ID"
$ResourceGroupName = "MyResourceGroup"
$StorageAccountName = "MyStorageAccountName"

Connect-AzAccount -Subscription $SubscriptionId #connect to your azure account.

Select-AzSubscription -SubscriptionId $SubscriptionId 

Join-AzStorageAccountForAuth
        -ResourceGroupName $ResourceGroupName,
        -StorageAccountName $StorageAccountName,
        -DomainAccountType "ComputerAccount",
        -OrganizationalUnitDistinguishedName "OU=OUName,DC=Domain,DC=Suffix,DC=Suffix",
        -EncryptionType "AES256"

#Download the FSLogix setup/ archive to the user downloads folder.

wget -Uri "https://aka.ms/fslogix_download" -OutFile $DownloadsFolder\fslogix.zip

    Expand-Archive -LiteralPath $DownloadsFolder\fslogix.zip -DestinationPath "C:\temp\"

Invoke-Command -ScriptBlock {Start-Process "C:\temp\x64\Release\FSLogixAppsSetup.exe" -ArgumentList "/q" -Wait} #Install FSLogixAppsSetup

    Invoke-Command -ScriptBlock {Start-Process "C:\temp\x64\Release\FSLogixAppsRuleEditorSetup.exe" -ArgumentList "/q" -Wait} #Install FSLogixAppsRuleEditorSetup

        Invoke-Command -ScriptBlock {Start-Process "C:\temp\x64\Release\FSLogixAppsJavaRuleEditorSetup.exe" -ArgumentList "/q" -Wait} #FSLogixAppsJavaRuleEditorSetup

#Domain Join the machine if not part of the domain.

    add-computer -domainname YourDomainName -Credential YourDomainName\DomainAccount -force

#New-Item 'HKLM:\SOFTWARE\FSLogix\Profiles'

New-ItemProperty 'HKLM:\SOFTWARE\FSLogix\Profiles' -PropertyType "DWord" -name "Enabled" -Value "1"

    New-ItemProperty 'HKLM:\SOFTWARE\FSLogix\Profiles' -PropertyType "MultiString" -name "VHDLocations" -Value "FileStorageLocation" #set the  azure storage account location for the roaming profiles.

        New-ItemProperty 'HKLM:\SOFTWARE\FSLogix\Profiles' -PropertyType "DWord" -name "FlipFlopProfileDirectoryName" -Value "1" #append the username next to the SID

New-ItemProperty 'HKLM:\SOFTWARE\FSLogix\Profiles' -PropertyType "DWord" -name "DeleteLocalProfileWhenVHDShouldApply" -Value "1"

#Remove the Everyone, Administrator, Users groups from being included in the FSLogix Azure File Share

Remove-LocalGroupMember -Group "FSLogix Profile Include List" -Member "Everyone", "Administrator", "Users"

    Remove-LocalGroupMember -Group "FSLogix ODFC Include List" -Member "Everyone", "Administrator", "Users"

#Add the WVD Onprem AD group to the FSLogix profile list groups.

Add-LocalGroupMember -Member "TestScript" -Group "FSLogix Profile Include List"

    Add-LocalGroupMember -Member "testScript" -Group "FSLogix ODFC Include List"

#Silently mount the FSLogix file share to apply the NTFS permissions.

CMD /c net use R: \\storageAccount.file.core.windows.net\fileShare theStorageAccountKey /user:Azure\storageAccount

#Update the NTFS permissions.

CMD /c icacls R: /remove "Authenticated Users"
CMD /c icacls R: /remove "Builtin\Users"
CMD /c icacls R: /grant "Creator Owner":(OI)(CI)(IO)(M)
CMD /c icacls R: /grant "WVD Group":(F)
CMD /c icacls R: /grant "WVD Admin Group":(F)

#Set-up is completed.
