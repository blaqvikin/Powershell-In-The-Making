$Ips = Get-Content ips.txt 
$arg2 = 2
foreach ($Ip in $Ips) {
    Write-Host $Ip, "arg1", $arg2, "arg3" 
    Invoke-Command -ComputerName $Ip -FilePath "c:\script\script.ps1" -ThrottleLimit 300 -ArgumentList "arg1", $arg2, "arg3"  
    $arg2 = $arg2 + 1  
}