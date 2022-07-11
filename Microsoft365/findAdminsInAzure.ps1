$admin = Get-AzureADDirectoryRole | where{$_.displayname -like "global administrator"}

Get-AzureADDirectoryRoleMember -objectId $admin.objectId