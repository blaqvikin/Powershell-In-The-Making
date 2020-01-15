########## Script to rollout software installation on remote computers.

########## Enable PS security prerequisites.

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

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

        $localadmin = "nservice"
            $ObjLocalUser = $null 

Try {
    Write-Verbose "Searching for $($localadmin) in LocalUser DataBase"
        $ObjLocalUser = Get-LocalUser $localadmin
            Write-Verbose "User $($localadmin) was found"
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
                             Write-Verbose "Creating User $($localadmin)" 
                                $secureString = convertto-securestring "Vd*Jp7.xT@P>" -asplaintext -force
                                    $localacc = New-LocalUser -Name $localadmin -Password $secureString -AccountNeverExpires -Description "Organization's local admin" 
                                        Add-LocalGroupMember -Group "administrators" -Member $localadmin }
 
 
########## Define the windows path to the downloaded/ downloads file/ folder. Next download and place the temp file to the desired folder below.

wget http://102.133.239.132/1510WindowsAgentSetup.exe -O $DownloadsFolder\1510WindowsAgentSetup.exe

$DownloadsFolder=Get-ItemPropertyValue 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\' -Name '{374DE290-123F-4565-9164-39C4925E467B}'


########## Disable Smart-screen filter as this hinders the WinAgentInstall

        set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\' -Name SmartScreenEnabled -Value "0"

            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System\' -Name SmartScreenEnabled -Value "0"


########## Install Software On PC

New-Item -ItemType directory -Path "\\$Computer\c$\temp\1510WindowsAgentSetup"

    Copy-Item "$DownloadsFolder\1510WindowsAgentSetup*.exe" "\\$Computer\c$\temp\1510WindowsAgentSetup" -Recurse

        Write-Host "Installing the Organizations's Ncentral remote software on $Computer"
        
            Invoke-Command -ComputerName $Computer -ScriptBlock {Start-Process $DownloadsFolder\1510WindowsAgentSetup.exe -ArgumentList "/q" -Wait} 


    
########## Cleanup all the resources.

    Write-Host "Removing Temporary files on $Computer"
        
        $RemovalPath = "\\$Computer\c$\temp\1510WindowsAgentSetup"

             Get-ChildItem  -Path $RemovalPath -Recurse  | Remove-Item -Force -Recurse
    
    Remove-Item $RemovalPath -Force -Recurse
        
        Set-Item WSMan:\localhost\Client\TrustedHosts -Value " " -Force

                Get-Service -Name WinRM | Stop-Service
        
                    Disable-PSRemoting
        
                        Write-Host "Service stopped on + $Computer"
               
                    set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\' -Name SmartScreenEnabled -Value "1"

            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System\' -Name SmartScreenEnabled -Value "1"
            
            Exit-PSSession
