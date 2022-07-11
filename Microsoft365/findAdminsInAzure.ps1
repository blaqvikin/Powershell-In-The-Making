$admin = get-azureaddirectoryrole | where{$_.displayname -like "administrator"}

get-azureaddirectoryMember -objectId $admin.objectId