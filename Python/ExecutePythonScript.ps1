$Ips = Get-Content C:\Powershell\DemoThreeIps.txt #Get all IP's to execute the script on.

foreach ($IP in $Ips) {

  $variableArg = 5 #Arguements to pass to the below command and incremented by 1 per iteration.
  $staticArg = 5
  $stringArg = "helloworld"
  Invoke-Command "python c:\scripts\myscript.py" -ArgumentList $staticArg $variableArg=$variableArg+1 $stringArg #This will be execute per iteration of the IP. 
  
  Write-Host "Ran on $IP and incremented count by $scriptargs"
}