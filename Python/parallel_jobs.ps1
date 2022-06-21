# Get the script directory
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

# Start 5 background jobs
For ($i=1; $i -le 5; $i++) {
    $ScriptBlock = {
      Param (
             [string] [Parameter(Mandatory=$true)] $increment,
             [string] [Parameter(Mandatory=$true)] $path
      )
      $variableArgument = [int]$increment + 1
      iex "python $path\\script.py fixedArgument1 $variableArgument fixedArgument3"
    }
    Start-Job $ScriptBlock -ArgumentList $i, $scriptPath
}

# Monitor the jobs each second
While((Get-Job | Where-Object {$_.State -ne "Completed"}).Count -gt 0)
{    
    Write-Host "Monitoring jobs..."    
    # Print results
    Get-Job | Where-Object {$_.State -eq "Completed"} | Receive-Job
    Start-Sleep -Seconds 1
}   

# Print results 
Get-Job | Where-Object {$_.State -eq "Completed"} | Receive-Job

Write-Host "The End."

