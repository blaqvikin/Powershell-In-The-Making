# Detect and remove the Windows Mail app
$MailApp = Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -like "*microsoft.windowscommunicationsapps*" }

if ($MailApp) {
    Write-Output "Windows Mail app detected. Proceeding with removal."
    try {
        # Attempt to remove the Windows Mail app
        $MailApp | Remove-AppxPackage -AllUsers -ErrorAction Stop
        Write-Output "Windows Mail app successfully removed."
    } catch {
        Write-Output "Failed to remove Windows Mail app. Error: $_"
        exit 1 # Return non-zero exit code if removal fails
    }
} else {
    Write-Output "Windows Mail app not found. No action needed."
    exit 0
}
