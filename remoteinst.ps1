########## Get the exe download off the site, in this case an IIS site off an azure server, this could be the clients website or an organizations repo for client nms exe's ##########

##wget http://serverIP/filename##

########## Declare the hostname ##########

$Computer=$env:ComputerName


########## Enable PS security prerequisites ##########

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

    Set-Service -Name WinRM -StartupType Automatic | Restart-Service

        Enable-PSRemoting -Force

            Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$Computer" -Force 

                
########## Declare error handlers ##########

Clear-Host
$ErrorActionPreference = 'Stop'
    $VerbosePreference = 'Continue'

########## Declare the search values below ##########

        $localadmin = "localadmin20"
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
                            Write-Verbose "Creating User $($localadmin)" #(Example)
                                $secureString = convertto-securestring "N3t5ur!tis5tr0nG" -asplaintext -force
                                    $localacc = New-LocalUser -Name $localadmin -Password $secureString -AccountNeverExpires -Description "Organization's local admin" 
                                        Add-LocalGroupMember -Group "administrators" -Member $localadmin }
 
 #Enter-PSSession -ComputerName $Computer -Credential "$Computer\$localacc" -Authentication Negotiate        

########## Define the windows path to the downloaded/ downloads file/ folder ##########

$DownloadsFolder=Get-ItemPropertyValue 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\' -Name '{374DE290-123F-4565-9164-39C4925E467B}'


########## Install Software On PC ##########

New-Item -ItemType directory -Path "\\$Computer\c$\temp\1510WindowsAgentSetup"

    Copy-Item "$DownloadsFolder\1510WindowsAgentSetup*.exe" "\\$Computer\c$\temp\1510WindowsAgentSetup" -Recurse

        Write-Host "Installing the Organizations's Ncentral remote software on $Computer"
        
            Invoke-Command -ComputerName $Computer -ScriptBlock {Start-Process "c:\temp\1510WindowsAgentSetup\1510WindowsAgentSetup" -ArgumentList "/q" -Wait} 


    
########## Cleanup all the resources ##########

    Write-Host "Removing Temporary files on $Computer"
        $RemovalPath = "\\$Computer\c$\temp\1510WindowsAgentSetup"
             Get-ChildItem  -Path $RemovalPath -Recurse  | Remove-Item -Force -Recurse
    Remove-Item $RemovalPath -Force -Recurse

        Disable-PSRemoting

            Get-Service -Name WinRM | Stop-Service

                Write-Host "Service stopped on + $Computer"

                       Set-Item WSMan:\localhost\Client\TrustedHosts -Value " " -Force
            
            Exit-PSSession
