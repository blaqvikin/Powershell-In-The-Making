$UserAccount = "YourUserAccount"
$UserPassword = ConvertTo-SecureString -String "YourPassword" -AsPlainText -Force

$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserAccount, $UserPassword

Connect-AzAccount -Credential $Credential 

$RecoveryServicesVault = Get-AzRecoveryServicesVault -ResourceGroupName "MigrateStaging-RG" -Name "CLOUD-HYPERV-MIGRATE-MIGRATEVAULT-1369848866"

$VaultSettings = Set-AzRecoveryServicesAsrVaultContext -Vault $RecoveryServicesVault

$SaveFilePath = "/home/groot/Desktop" #Location for the output (json) of the below command.

$VaultJobs = Get-AzRecoveryServicesAsrJob | Where-Object {$_.TargetObjectType -ccontains "ProtectionEntity"} | Format-Table JobType, DisplayName, State, StateDescription, StartTime, EndTime, TargetObjectName, TargetObjectType, TargetObjectId  -AutoSize |Out-File $SaveFilePath/Jobs.json
