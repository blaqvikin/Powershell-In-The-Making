Install-Module AzureADPreview -AllowClobber -Force
Find the manual page: man Get-AzureADDirectory*
Optional: Connect-AzureAD
 Require to sign in on the Preview:  AzureADPreview\Connect-AzureAD
$grpUnifiedSetting = (Get-AzureADDirectorySetting | where -Property DisplayName -Value “Group.Unified” -EQ)

$Setting = $grpUnifiedSetting
 $grpUnifiedSetting.Values

$TemplateId = (Get-AzureADDirectorySettingTemplate | where { $_.DisplayName -eq “Group.Unified” }).Id

$Template = Get-AzureADDirectorySettingTemplate | where -Property Id -Value $TemplateId -EQ

$Setting = $Template.CreateDirectorySetting()

$Setting[“EnableMIPLabels”] = “True”

New-AzureADDirectorySetting -DirectorySetting $Setting
$Setting.Values

#Assuming you have installed ExchangeOnlineManagement
Connect-IPPSSession

Execute-AzureAdLabelSync
