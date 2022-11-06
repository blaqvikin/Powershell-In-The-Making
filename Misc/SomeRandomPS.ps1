get-help, get-command, get-module, get-member, get-psdrive, -whatif,

get-aduser -filter & -resultpagesize $null |? lockedout

search-adaccount -accountdisabled -useronly

search-adaccount -lockedout -useronly | fl

(search-adaccount -lockedout -useronly | fl).count

get-service | ? status -eq "running" | select description

Get-ScheduledTask | ? {$_.TaskName -eq ‘PushLaunch’} | Start-ScheduledTask