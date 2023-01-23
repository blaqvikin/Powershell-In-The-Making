########## Script to rollout software installation on remote computers.

########## Declare the hostname variable.

            $Computer=$env:ComputerName
                
########## Declare error handlers.
                             
        Write-Verbose "Creating local user on ($Computer)" 
                        
                             
            $secureString = convertto-securestring "<InsertPassword>" -asplaintext -force
                        
                             
                $localacc = New-LocalUser -Name "AutomationTestUser" -Description "Built by automation script" -FullName "AutomationTestUser" -AccountNeverExpires -PasswordNeverExpires -Password $secureString 
                        
                             
                        Add-LocalGroupMember -Group "administrators" -Member $localacc

        Write-Host "Done creating user $localadmin on $Computer"
