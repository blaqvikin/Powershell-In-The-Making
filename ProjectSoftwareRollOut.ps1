########## Script to rollout software installation on remote computers.

########## Enable PS security prerequisites. Change connection profile to "Private/ Domain" for WSMan requirements.

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine


#Update-Help  -Force -Ea 0


             $CurrentConProfile = get-netconnectionprofile;Set-NetConnectionProfile -Name $CurrentConProfile.Name -NetworkCategory Private           
                 

    Set-Service -Name WinRM -StartupType Automatic | Restart-Service


            Enable-PSRemoting -Force


                  Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$Computer" -Force 

########## Find the zeppelin extension in c drive                  
            
Get-ChildItem -Path C:\ -Include *.zeppelin -File -Recurse -ErrorAction SilentlyContinue

########## Get the download file from a repo.
 

                        wget https://deployremoteapps.azurewebsites.net/CybereasonSensor64.exe -O $DownloadsFolder\WindowsAgentSetup.exe
                    
                    wget https://deployremoteapps.azurewebsites.net/MBSetup.exe -O $DownloadsFolder\malwarebytes.exe
                                    
########## Define the windows path to the downloaded/ downloads file/ folder.

            $DownloadsFolder=Get-ItemPropertyValue 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\' -Name '{374DE290-123F-4565-9164-39C4925E467B}'
                        
                        $tempFolder= $env:TEMP


########## Disable Smart-screen filter as this can hinder the install

        
        set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\' -Name SmartScreenEnabled -Value "0"

            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System\' -Name SmartScreenEnabled -Value "0"



########## Install Software On PC

Copy-Item "$DownloadsFolder\WindowsAgentSetup.exe" "$tempFolder\WindowsAgentSetup.exe" -Recurse

        Copy-Item "$DownloadsFolder\malwarebytes.exe" "$tempFolder\malwarebytes.exe" -Recurse
        
            Write-Host "Installing the AV preventative software on $Computer"
        
        
                Invoke-Command -ScriptBlock {Start-Process $tempFolder\WindowsAgentSetup.exe -ArgumentList "/q" -Wait}
                    
                    Invoke-Command -ScriptBlock {Start-Process $tempFolder\malwarebytes.exe -ArgumentList "/q" -Wait}



   
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
                        
