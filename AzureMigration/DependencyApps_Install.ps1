<# Date: 30/06/2021
Version: 0.0.1
Author: Mawanda Hlophoyi
Title:  This script install Azure Log Analytics agent, more on log WP @ "https://docs.microsoft.com/en-us/azure/azure-monitor/agents/gateway"
        Installs service map, more on service map @ "https://docs.microsoft.com/en-us/azure/azure-monitor/vm/service-map
#>
$SoftwareLocation = mkdir "c:\temp\migration\"

#Download the required files
wget "https://go.microsoft.com/fwlink/?LinkId=828603" -OutFile $SoftwareLocation\MMASetup-AMD64.exe -UseBasicParsing
wget "https://aka.ms/dependencyagentwindows" -OutFile $SoftwareLocation\serviceMap.exe -UseBasicParsing
wget "https://developmentupload.blob.core.windows.net/client-dev/migrationvms.txt?sv=2020-10-02&si=RL-2022-Policy&sr=b&sig=XFOvjVDxd1dSb6dJemeqcF035c9BBykFsn7IH3%2FGOqQ%3D" -OutFile $SoftwareLocation\migrationvms.txt -UseBasicParsing

$MigrationVMs = Get-Content $SoftwareLocation\migrationvms.txt #Machine IPs, based on Azure Migrate Assessment

Set-Location -LiteralPath $SoftwareLocation

#Extract the exe file, this importat as the install command in the loop will fail if the below is not ran.
./MMASetup-AMD64.exe /c /t:c:\temp\migration

ForEach ($VM in $MigrationVMs)
{
    Invoke-Command -ScriptBlock {Start-Process .\Setup.exe /'qn NOAPM=1 ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=0 OPINSIGHTS_WORKSPACE_ID="<WorkspaceID>" OPINSIGHTS_WORKSPACE_KEY="<WorkspaceKey>" AcceptEndUserLicenseAgreement=1'}
    Invoke-Command -ScriptBlock {Start-Process $SoftwareLocation\serviceMap.exe /S}
}
