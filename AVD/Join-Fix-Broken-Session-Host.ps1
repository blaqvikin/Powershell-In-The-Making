Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\RDInfraAgent\" -Name "IsRegistered" -Value "0" -Force
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\RDInfraAgent\" -Name "RegistrationToken" -Value "<AVDRegistrationKey>" -Force
Restart-Service RDAgentBootLoader
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\RDInfraAgent\" -Name "IsRegistered" -Value "1" -Force


