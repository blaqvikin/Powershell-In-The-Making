<#
Title: Find Highly Privileged Roles in EntraID
Description: This script will find all highly privileged roles in EntraID.
Author: Mawanda Hlophoyi
Timestamp: 2024-07-30
#>

# Install the required module
Install-Module AzureADPreview -Force

# Connect to Azure AD
Connect-AzureAD

# Define privileged roles
$PrivilegedRoles = @(
    "Privileged Role Administrator",
    "User Administrator",
    "Security Administrator",
    "Application Administrator",
    "Exchange Administrator",
    "SharePoint Administrator",
    "Cloud Application Administrator",
    "Intune Administrator"
)

# Loop through each privileged role
foreach ($PrivilegedRole in $PrivilegedRoles) {
    # Get the role object
    $role = Get-AzureADDirectoryRole | Where-Object {$_.DisplayName -eq $PrivilegedRole}
    
    if ($role) {
        Write-Host "Members of $PrivilegedRole role:"
        Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId | Format-Table DisplayName, UserPrincipalName
    } else {
        Write-Host "Role '$PrivilegedRole' not found."
    }
}