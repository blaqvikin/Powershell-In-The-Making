$admin = Get-AzureADDirectoryRole | Where-Object {$_.displayname -like "Something Administrator"}

Get-AzureADDirectoryRoleMember -objectId $admin.objectId