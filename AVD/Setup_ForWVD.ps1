<# Date: 30/06/2021
Version: 0.0.10
Author: Mawanda Hlophoyi
Prerequisites: Powershell  (Az Module, AD module, ), Domain Join Workstation, Access to the internet, Local administration privileges .
Assumptions: WVD domain groups created
Title: This script prepares the WVD environment, 
        Joins the azure storage to AD, 
        Setup the FSLogix profile, mount the file share and setup the necessary permissions.
        Deploy the Azure Virtual Desktop resources.
Note: This script has been tested with PS version 7.1.3, check your computers' PS version for compatibility before executing the script.
#>

#Install Prerequisites
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser #Enable execution of PS scripts.

Install-module Az -force #Required module.
Install-module ActiveDirectory -force #Required module.

[System.Version]$global:PsVer = "0.0" # Default value
#Validate PS version
function ValidatePSVersion
{
    [System.Version]$minVer = "4.0"
        Log-Info "Verifying the PowerShell version to run the script...”
            if ($PSVersionTable.PSVersion){
                $global:PsVer = $PSVersionTable.PSVersion}
    If ($global:PsVer -lt $minVer)
                    {
                        Log-Error "PowerShell version $minVer, or higher is required. Current PowerShell version is $global:PsVer. Downloading Powershell v7.1.3"   
wget -uri https://www.microsoft.com/en-us/download/confirmation.aspx?id=54616 -OutFile $DownloadsFolder\W2K12-KB3191565-x64.msu -Verbose
wget -uri https://github.com/PowerShell/PowerShell/releases/download/v7.1.3/PowerShell-7.1.3-win-x64.msi -OutFile $DownloadsFolder\PowerShell-7.1.3-win-x64.msi -Verbose 
        
    Invoke-Command -ScriptBlock {Start-Process "$DownloadsFolder\W2K12-KB3191565-x64.msu" -ArgumentList "/q" -Wait} #Install WMF5
    Invoke-Command -ScriptBlock {Start-Process "$DownloadsFolder\PowerShell-7.1.3-win-x64.msi" -ArgumentList "/q" -Wait} #Install Powershell version 7.1.3
    <#exit 1;.#>    }
    else    { Log-Success "[OK]`n"}
}

#Domain Join the machine if not part of the domain.
    Set-Timezone "South Africa Standard Time" #Set Timezone to +2   
    Get-WmiObject -class Win32_computerSystem.PartOfDomain 
    $DomainName = Read-Host -Prompt "Enter your domain name"
    $Admin = Read-Host -Prompt "Enter your domain admin account"
    add-computer -DomainName $DomainName -Credential $Admin -force #Join the machine to the domain.
    Restart-Computer -ComputerName $env:COMPUTERNAME  #Reboot

#Declare the downloads folder, this is default reg key for all Windows machines
$DownloadsFolder=Get-ItemPropertyValue 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\' -Name '{374DE290-123F-4565-9164-39C4925E467B}'

#Download the AzFilesHybrid archive to the user downloads folder.
wget -uri https://github.com/Azure-Samples/azure-files-samples/releases/download/v0.2.4/AzFilesHybrid.zip -OutFile $DownloadsFolder\AzFilesHybrid.zip
Expand-Archive -LiteralPath $DownloadsFolder\AzFilesHybrid.zip 

Set-location -LiteralPath ./AzFilesHybrid
.\CopyToPSPath.ps1 
Import-Module -Name AzFilesHybrid #Import the downloaded module into PS session

$SubscriptionId = Read-Host -Prompt "Enter your SubscriptionId"
$ResourceGroupName = Read-Host -Prompt "Enter your resource group name"
$StorageAccountName = Read-Host -Prompt "Enter your storage account name"

Connect-AzAccount -Subscription $SubscriptionId #connect to your azure account.
Select-azsubscription -SubscriptionId $SubscriptionId

#wget -uri https://www.microsoft.com/en-us/download/confirmation.aspx?id=45520
#Get-ADDomainController -DomainName contosolab.local -ForceDiscover -Discover -service ADWS

#Create AD Group for AVD
New-ADGroup -AVD-Users

# make changes to how the below command is ran, save top file
Get-ADOrganizationalUnit -Filter 'Name -like "AVD"' -Server <ServerName.FullyQualifiedDomainName> | Select-Object DistinguishedName #Paste Output in OUD name field

Join-AzStorageAccountForAuth -ResourceGroupName $ResourceGroupName `
 -StorageAccountName $StorageAccountName `
 -DomainAccountType "ComputerAccount" `
 -OrganizationalUnitDistinguishedName "OU=OUName,DC=Domain,DC=Suffix,DC=Suffix" #Ensure to put in an OU with less GPO interference

#Download the FSLogix setup/ archive to the user downloads folder.
wget -Uri "https://aka.ms/fslogix_download" -OutFile $DownloadsFolder\fslogix.zip
    Expand-Archive -LiteralPath $DownloadsFolder\fslogix.zip

    Invoke-Command -ScriptBlock {Start-Process "$DownloadsFolder\x64\Release\FSLogixAppsSetup.exe" -ArgumentList "/q" -Wait} #Install FSLogixAppsSetup
    Invoke-Command -ScriptBlock {Start-Process "$DownloadsFolder\Release\FSLogixAppsRuleEditorSetup.exe" -ArgumentList "/q" -Wait} #Install FSLogixAppsRuleEditorSetup
    Invoke-Command -ScriptBlock {Start-Process "$DownloadsFolder\x64\Release\FSLogixAppsJavaRuleEditorSetup.exe" -ArgumentList "/q" -Wait} #FSLogixAppsJavaRuleEditorSetup

#New-Item 'HKLM:\SOFTWARE\FSLogix\Profiles'
    New-ItemProperty 'HKLM:\SOFTWARE\FSLogix\Profiles' -PropertyType "DWord" -name "Enabled" -Value "1"
    New-ItemProperty 'HKLM:\SOFTWARE\FSLogix\Profiles' -PropertyType "MultiString" -name "VHDLocations" -Value "//StorageAccountName.file.core.windows.net/ShareName" #set the  azure storage account location for the roaming profiles.
    New-ItemProperty 'HKLM:\SOFTWARE\FSLogix\Profiles' -PropertyType "DWord" -name "FlipFlopProfileDirectoryName" -Value "1" #append the username next to the SID
    New-ItemProperty 'HKLM:\SOFTWARE\FSLogix\Profiles' -PropertyType "DWord" -name "DeleteLocalProfileWhenVHDShouldApply" -Value "1"

#Remove the Everyone, Administrator, Users groups from being included in the FSLogix Azure File Share
    Remove-LocalGroupMember -Group "FSLogix Profile Include List" -Member "Everyone", "Administrator", "Users"
    Remove-LocalGroupMember -Group "FSLogix ODFC Include List" -Member "Everyone", "Administrator", "Users"

#Search AD for AVD group names
Get-AzADGroup -SearchString "AVD" | Format-Table

#Add the WVD Onprem AD group to the FSLogix profile list groups.
    Add-LocalGroupMember -Member "WVDUsersGroup" -Group "FSLogix Profile Include List"
    Add-LocalGroupMember -Member "WVDUsersGroup" -Group "FSLogix ODFC Include List"

#Silently mount the FSLogix file share to apply the NTFS permissions.
CMD /c net use W: \\<storageAccount>.file.core.windows.net\<fileShare> "xxx-xxx-xxx-xxxx" /user:Azure\<storageAccount> 

#Update the NTFS permissions of the Azure FileShare.

icacls W: /remove "Authenticated Users"
icacls W: /remove "Builtin\Users"

Get-Acl -Path W: | Select-Object Owner
icacls W: /grant ("ReplaceWithOutputFromAbove" + ':(OI)(CI)(IO)M')

icacls W: /grant ("AVDUsersGroup" + ':(F)')
icacls W: /grant ("AVDAdminGroup" + ':(F)')

#Remove Mounted storage, for security reasons, it is not recommended to leave your storage account mounted using a key.
net use W: /DELETE

#Setting up hostpool
$HostPoolName = Read-Host -Prompt "Create a host pool name"
$AppGroupName = Read-Host -Prompt "Create an application group name 'Dekstop/RemoteApp'"
$WorkSpaceName = Read-Host -Prompt "Create a workspace for your Azure Virtual Desktop app groups"
#New host pool group with meta-data in UK South.
New-AzWvdHostPool -ResourceGroupName $ResourceGroupName `
 -Name $HostPoolName `
 -Location 'uksouth' `
 -HostPoolType 'Pooled' `
 -LoadBalancerType 'DepthFirst' `
 -RegistrationTokenOperation 'Update' `
 -ExpirationTime $((get-date).ToUniversalTime().AddDays(27).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')) `
 -Description 'Host Pool' `
 -FriendlyName 'WVD Host Pool' `
 -PreferredAppGroupType Desktop `
 -MaxSessionLimit 10
 
#New Desktop Application Group
New-AzWvdApplicationGroup -ResourceGroupName $ResourceGroupName `
-Name $AppGroupName `
-Location "UK South" `
-FriendlyName "DesktopGroup" `
-Description "WVD Desktop App Group" `
-HostPoolArmPath "/subscriptions/$SubscriptionId/resourcegroups/$ResourceGroupName/providers/Microsoft.DesktopVirtualization/hostPools/$HostPoolName" `
-ApplicationGroupType "Desktop"
#New Workspace
New-AzWvdWorkspace -ResourceGroupName $ResourceGroupName `
-Name $WorkSpaceName `
-Location 'UK South' `
-FriendlyName 'AVD App Group Workspace' `
-ApplicationGroupReference "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.DesktopVirtualization/applicationGroups/$AppGroupName"
#Search for deployed application groups, copy the name to the role assignment - resourcename
Get-AzWvdApplicationGroup -ResourceGroupName $resourcegroupname | Select-Object | Format-List Name, Location

#Search for Azure Virtual Desktop groups in your AD, copy the object ID
$objectID = Get-AzADGroup -SearchString "AVD" | Select-Object objectID

#Add Azure Active Directory user groups to the default desktop app group for the host pool:
New-AzRoleAssignment -objectId $objectID -ResourceGroupName $ResourceGroupName `
-RoleDefinitionName "Desktop Virtualization User" `
-ResourceName $AppGroupName `
-ResourceType 'Microsoft.DesktopVirtualization/applicationGroups'

<#For manual installation of the AVD hosts refer to https://docs.microsoft.com/en-us/azure/virtual-desktop/create-host-pools-powershell#register-the-virtual-machines-to-the-azure-virtual-desktop-host-pool 

I'm keeping this for now

TokenRegistration = New-AzWvdRegistrationInfo -ResourceGroupName $ResourceGroupName -HostPoolName $hostpoolname -ExpirationTime $((get-date).ToUniversalTime().AddHours(720).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))

$token = Get-AzWvdRegistrationInfo -ResourceGroupName $resourcegroupname -HostPoolName $HostPoolName #Export registration key for use later.
#>