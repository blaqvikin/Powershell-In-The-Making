Get-ADDomainController -Filter * | Select-Object name, domain, forest, operationMasterRoles | Where-Object {$_.operationMasterRoles} | Format-Table -AutoSize

#netdom.exe query fsmo