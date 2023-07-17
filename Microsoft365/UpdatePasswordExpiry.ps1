<#
Required Modules:
- Microsoft Graph

Description:
- Update the password never expires flag

Required Permission
- User Access Administrator or any equivalent of in AAD
#>

# Install the required module
Install-Module Microsoft.Graph

# Connect to Microsoft Graph API
Connect-MgGraph -Scopes "User.Read.All"

# Read users and export to CSV
Get-MgUser -All | Select-Object UserPrincipalName, PasswordNeverExpires | Export-Csv -Path "accounts.csv" -NoTypeInformation

# Import from CSV
$Accounts = Import-Csv -Path "accounts.csv"

# Loop through and update password never expires flag
ForEach ($Account in $Accounts)
{
    # Retrieve the user principal name and password never expires flag
    $UserPrincipalName = $Account.UserPrincipalName
    $PasswordNeverExpires = $Account.PasswordNeverExpires

    # Update the user's password never expires flag
    Set-MgUser -UserPrincipalName $UserPrincipalName -PasswordProfile @{"PasswordNeverExpires" = $PasswordNeverExpires}
}
