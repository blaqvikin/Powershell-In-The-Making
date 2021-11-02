Write-Host "script.ps1 args: ", ($args -join ', ')
$a = ($args -join ' ')
iex "python C:\script\script.py $a"  

