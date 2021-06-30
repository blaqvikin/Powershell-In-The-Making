<# Date: 30/06/2021
Version: 0.0.7
Author: Mawanda Hlophoyi
Prerequisites: Powershell  (Az Module, AD module, ), Domain Join Workstation, Access to the internet, Local administration privileges .
Assumptions: WVD domain groups created
Title: This script prepares the WVD environment, joins the azure storage into onprem AD, setup the FSLogix profile, mount the file share and setup the necessary permissions.
Note: This script has been tested with PS version 7.1.3, check your computers' PS version for compatibility before executing the script.
#>

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser #Enable execution of PS scripts.

#Domain Join the machine if not part of the domain.

    add-computer -domainname YourDomainName -Credential YourDomainName\DomainAccount -force

#Declare the downloads folder, this is default reg key for all Windows machines
$DownloadsFolder=Get-ItemPropertyValue 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\' -Name '{374DE290-123F-4565-9164-39C4925E467B}'

#Download Powershell version 7.1.3 
wget -uri https://github.com/PowerShell/PowerShell/releases/download/v7.1.3/PowerShell-7.1.3-win-x64.msi -OutFile $DownloadsFolder\PowerShell-7.1.3-win-x64.msi -Verbose | Move-Item .\PowerShell-7.1.3-win-x64.msi -Destination C:\temp 

    Invoke-Command -ScriptBlock {Start-Process "C:\temp\PowerShell-7.1.3-win-x64.msi" -ArgumentList "/q" -Wait} #Install Powershell version 7.1.3

#Download the AzFilesHybrid archive to the user downloads folder.

wget -uri https://github.com/Azure-Samples/azure-files-samples/releases/download/v0.2.3/AzFilesHybrid.zip -OutFile $DownloadsFolder\AzFilesHybrid.zip

Expand-Archive -LiteralPath $DownloadsFolder\AzFilesHybrid.zip -DestinationPath "C:\temp\"

Set-Location -Path "C:\temp\" #Change location to the temp dir

.\CopyToPSPath.ps1 

Import-Module -Name AzFilesHybrid #Import the downloaded module into PS

$SubscriptionId = Read-Host -Prompt "Key in your subscription ID"
$ResourceGroupName = Read-Host -Prompt "Key in your resource group name"
$StorageAccountName = Read-Host -Prompt "Key in your storage account name"

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

#New-Item 'HKLM:\SOFTWARE\FSLogix\Profiles'

New-ItemProperty 'HKLM:\SOFTWARE\FSLogix\Profiles' -PropertyType "DWord" -name "Enabled" -Value "1"

    New-ItemProperty 'HKLM:\SOFTWARE\FSLogix\Profiles' -PropertyType "MultiString" -name "VHDLocations" -Value "FileStorageLocation" #set the  azure storage account location for the roaming profiles.

        New-ItemProperty 'HKLM:\SOFTWARE\FSLogix\Profiles' -PropertyType "DWord" -name "FlipFlopProfileDirectoryName" -Value "1" #append the username next to the SID

New-ItemProperty 'HKLM:\SOFTWARE\FSLogix\Profiles' -PropertyType "DWord" -name "DeleteLocalProfileWhenVHDShouldApply" -Value "1"

#Remove the Everyone, Administrator, Users groups from being included in the FSLogix Azure File Share

Remove-LocalGroupMember -Group "FSLogix Profile Include List" -Member "Everyone", "Administrator", "Users"

    Remove-LocalGroupMember -Group "FSLogix ODFC Include List" -Member "Everyone", "Administrator", "Users"

#Add the WVD Onprem AD group to the FSLogix profile list groups.

Add-LocalGroupMember -Member "WVD Users Group" -Group "FSLogix Profile Include List"

    Add-LocalGroupMember -Member "WVD Users Group" -Group "FSLogix ODFC Include List"

#Silently mount the FSLogix file share to apply the NTFS permissions.

CMD /c net use W: \\storageAccount.file.core.windows.net\fileShare "xxx-xxx-xxx-xxxx" /user:Azure\storageAccount 

#Update the NTFS permissions of the Azure FileShare.

icacls W: /remove "Authenticated Users"
icacls W: /remove "Builtin\Users"

Get-Acl -Path W: | Select-Object Owner

icacls W: /grant ("ReplaceWithOutputFromAbove" + ':(OI)(CI)(IO)M')

icacls W: /grant ("WVD Users Group" + ':(F)')
icacls W: /grant ("WVD Admin Group" + ':(F)')

#Remove Mounted storage, for security reasons it is not recommended to leave your storage account mounted using a key.

net use W: /DELETE

#Setting up hostpool

$hostpoolname = Read-Host -Prompt "Create a host pool name"
$workspacename = Read-Host -Prompt "Create a workspace for your Azure Virtual Desktop app groups"

New-AzWvdHostPool -ResourceGroupName $ResourceGroupName -Name $hostpoolname -WorkspaceName $workspacename -HostPoolType Pooled -LoadBalancerType BreadthFirst -Location UK South -DesktopAppGroupName "DesktopGroup" -PreferredAppGroupType "Desktop"

#Token Registration
New-AzWvdRegistrationInfo -ResourceGroupName $ResourceGroupName -HostPoolName $hostpoolname -ExpirationTime $((get-date).ToUniversalTime().AddHours(720).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))

#Search for Azure Virtual Desktop groups in your AD, copy the object ID
Get-AzADGroup -SearchString "SearchPhrase" | Format-Table

#Add Azure Active Directory user groups to the default desktop app group for the host pool:
New-AzRoleAssignment -objectId "xxxx-zzzz-xxxx" -RoleDefinitionName "Desktop Virtualization User" -ResourceName $DesktopAppGroupName -ResourceGroupName $resourcegroupname -ResourceType 'Microsoft.DesktopVirtualization/applicationGroups'

#Export registration key for use later.

$token = Get-AzWvdRegistrationInfo -ResourceGroupName $resourcegroupname -HostPoolName $hostpoolname

#For manual installation of the AVD hosts refer to https://docs.microsoft.com/en-us/azure/virtual-desktop/create-host-pools-powershell#register-the-virtual-machines-to-the-azure-virtual-desktop-host-pool 