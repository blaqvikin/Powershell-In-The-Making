@("User_English", "User_Spanish", "User_French", "User_Italian", "User_Russian", "User_German", "User_Vietnamese") | ForEach-Object {
    if (Get-LocalUser -Name $_ -ErrorAction SilentlyContinue) {
        Remove-LocalUser -Name $_
        Write-Host "Removed legacy account: $_" -ForegroundColor Yellow
    }
}
