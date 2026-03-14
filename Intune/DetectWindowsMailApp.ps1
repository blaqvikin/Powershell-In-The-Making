# Detect the existence of the Windows Mail app
$MailApp = Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -like "*microsoft.windowscommunicationsapps*" }

if ($MailApp) {
    # Return a non-zero exit code to indicate non-compliance
    Write-Output "Windows Mail app detected."
    exit 1
} else {
    # Return a zero exit code to indicate compliance
    Write-Output "Windows Mail app not found."
    exit 0
}
