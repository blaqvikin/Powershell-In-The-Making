Get-ADDomainController -Filter * | Select-Object name, domain, forest, operationMasterRoles | Where-Object {$_.operationMasterRoles} | Format-Table -AutoSize

#netdom.exe query fsmo

Get-ADOptionalFeature -Identity "CN=Recycle Bin Feature,CN=Optional Features,CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,DC=mifa,DC=local" -Scope ForestOrConfigurationSet –Target "mifa.local"
