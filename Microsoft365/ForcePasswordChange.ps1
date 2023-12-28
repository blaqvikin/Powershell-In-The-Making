<#
Required Modules:
- Microsoft Azure AD

Description:
- Force accounts to change the password

Required Permission
- User Access Administrator or any equivalent of in AAD
#>
# Install the required module
Install-Module AzureAD | import-module AzureAD

# Connect to Azure AD
Connect-AzureAD

# Import users from CSV
$Users = Import-Csv -Path ./accounts.csv

# Loop through and set users to change password on next login
ForEach ($User in $Users)
{
    # Retrieve the user identifier (either Object ID or User Principal Name)
    $UserPrincipalName = $User.UserIdentifier

    # Set the user to change password on next login
    Set-AzureADUser -ObjectId $UserPrincipalName -PasswordPolicies "DisablePasswordExpiration"
}

# Disconnect from Azure AD
Disconnect-AzureAD
