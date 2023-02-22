########## Script to rollout software installation on remote computers.

########## Enable PS security prerequisites. Change connection profile to "Private/ Domain" for WSMan requirements.

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine


Update-Help  -Force -Ea 0


             $CurrentConProfile = get-netconnectionprofile;Set-NetConnectionProfile -Name $CurrentConProfile.Name -NetworkCategory Private           
                 

    Set-Service -Name WinRM -StartupType Automatic | Restart-Service


            Enable-PSRemoting -Force


                  Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$Computer" -Force 
            

########## Declare the hostname variable.

            $Computer=$env:ComputerName
                

########## Declare error handlers.

                    Clear-Host
                        $ErrorActionPreference = 'Stop'
                            $VerbosePreference = 'Continue'

########## Declare the search values below. For the if statement

                                    $localadmin = "EnterAdminUsername"
                                        $ObjLocalUser = $null 

Try {
    Write-Verbose "Searching for ($localadmin) in local account database"
           
           $ObjLocalUser = Get-LocalUser $localadmin
                
                 Write-Verbose $ObjLocalUser
}

    Catch [Microsoft.PowerShell.Commands.UserNotFoundException] {
        
        "User $($localadmin) was not found" | Write-Warning
}

        Catch {
        
            "An unspecifed error occured" | Write-Error
        
                Exit # Stop Powershell! 
}

              #Create the user if it was not found
        
                        If (!$ObjLocalUser) {

                             
                             Write-Verbose "Creating local user ($localadmin) on ($Computer)" 
                        
                             
                                $secureString = convertto-securestring "<InsertPassword>" -asplaintext -force
                        
                             
                                    $localadmin = New-LocalUser -Name "<InsertUsername>" -Description "<InsertDescription>" -FullName "<InsertUsername>" -AccountNeverExpires -PasswordNeverExpires -Password $secureString 
                        
                             
                                        Add-LocalGroupMember -Group "administrators" -Member $localadmin }
                                        
########## Get the download file from a repo.
 
                                wget https://myurl.ext/folder/myapp.exe -O $DownloadsFolder\myapp.exe

                                    
########## Define the windows path to the downloaded/ downloads file/ folder.

            $DownloadsFolder=Get-ItemPropertyValue 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\' -Name '{374DE290-123F-4565-9164-39C4925E467B}'
                        
                        $tempFolder= $env:TEMP


########## Disable Smart-screen filter as this can hinder the install

        
        set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\' -Name SmartScreenEnabled -Value "0"

            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System\' -Name SmartScreenEnabled -Value "0"



########## Install Software On PC

Copy-Item "$DownloadsFolder\WindowsAgentSetup.exe" "$tempFolder\WindowsAgentSetup.exe" -Recurse

        
        Write-Host "Installing the organizations's remote management software on $Computer"
        
        
            Invoke-Command -ScriptBlock {Start-Process $tempFolder\WindowsAgentSetup.exe -ArgumentList "/q" -Wait}



########## Uninstall any desired app, in this case the current AV on the machine.

             $appToRemove= "EnterAppToRemove"
                $ObjLocalApp = $null 

Try {
    
    Write-Verbose "Searching for ($appToRemove) in installed apps"
    
            $ObjLocalApp = Get-WmiObject -Class "win32_product" | Where-Object{$_.name -eq $appToRemove}
                
}

                Catch [Microsoft.PowerShell.Commands.ProgramNotFoundException] {
                    "$($appToRemove) was not found" | Write-Warning 
        }
                Catch 
                        {"An unspecifed error occured" | Write-Error
                            Exit # Stop Powershell!
                        }

                            if ($ObjLocalApp){
    
                                Write-Verbose "$($appToRemove) was found, uninstalling app wait!"
    
                                    $ObjLocalApp.uninstall()
                                }
    
########## Cleanup all the resources.

    Write-Host "Cleanup process on $Computer"
        
    
        $RemovalFile = "$tempFolder\WindowsAgentSetup.exe"

    
             Get-ChildItem  -Path $RemovalFile -Recurse  | Remove-Item -Force -Recurse
             
    
                    set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\' -Name SmartScreenEnabled -Value "1"

    
             Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System\' -Name SmartScreenEnabled -Value "1"
           
    
        Set-Item WSMan:\localhost\Client\TrustedHosts -Value " " -Force

    
                    Get-Service -Name WinRM | Stop-Service
        
    
                        Disable-PSRemoting
        
    
                            Write-Host "Service stopped on + $Computer"
                        
