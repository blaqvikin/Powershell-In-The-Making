########## Script to rollout software installation on remote computers.

########## Enable PS security prerequisites. Change connection profile to "Private/ Domain" for WSMan requirements.

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force


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

########## Declare the search values below.

                                    $localadmin = "ph_admin"
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
                        
        
                                $secureString = convertto-securestring "3nterPassword!" -asplaintext -force
                        
        
                                    $localacc = New-LocalUser -Name $localadmin -Password $secureString -AccountNeverExpires -Description "Organization's local admin" 
        
                 
                                          Add-LocalGroupMember -Group "administrators" -Member $localadmin }

                                        
                                                                                
                                        
########## Get the download file from a repo.
 
                        #####President agent install
        
                                    wget https://deployremoteapps.azurewebsites.net/1016PresidentAgentSetup.exe -O $DownloadsFolder\1016PresidentAgentSetup.exe
                                    
                                    
########## Define the windows path to the downloaded/ downloads file/ folder.

        
            $DownloadsFolder=Get-ItemPropertyValue 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\' -Name '{374DE290-123F-4565-9164-39C4925E467B}'
        
                        
                        $tempFolder= $env:TEMP


########## Disable Smart-screen filter as this can hinder the install

        
        set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\' -Name SmartScreenEnabled -Value "0"

            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System\' -Name SmartScreenEnabled -Value "0"



########## Install Software On PC

Copy-Item "$DownloadsFolder\1016PresidentAgentSetup.exe" "$tempFolder\1016PresidentAgentSetup.exe" -Recurse

        
        Write-Host "Installing the organizations's remote management software on $Computer"
        
        
            Invoke-Command -ScriptBlock {Start-Process $tempFolder\1016PresidentAgentSetup.exe -ArgumentList "/q" -Wait} 


########## Rename the machine, before execution increment the 001 number
        
        
        Rename-Computer -ComputerName $Computer -NewName "PHCPTWS001"


                add-computer -domainname presidenthotel -Credential presidenthotel\Netsurit -force 


########## Enable BitLocker, change the secure string for each user

        
        $SecureString = ConvertTo-SecureString "864200" -AsPlainText -Force

           
               Enable-BitLocker -MountPoint "C:" -EncryptionMethod Aes256 –UsedSpaceOnly -Pin $SecureString    -TPMandPinProtector

  
########## Cleanup all the resources.

    Write-Host "Cleanup process on $Computer"

        
        $RemovalFile = "$tempFolder\1016PresidentAgentSetup.exe"

    
             Get-ChildItem  -Path $RemovalFile -Recurse  | Remove-Item -Force -Recurse
             
    
                    set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\' -Name SmartScreenEnabled -Value "1"


             Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System\' -Name SmartScreenEnabled -Value "1"
           

        Set-Item WSMan:\localhost\Client\TrustedHosts -Value " " -Force

           
                    Get-Service -Name WinRM | Stop-Service
        
           
                        Disable-PSRemoting
        
           
                            Write-Host "Service stopped on + $Computer"


########## Restart the machine

Write-Verbose "Restarting the machine"

    restart-computer $Computer

               
                      