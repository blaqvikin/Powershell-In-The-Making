# Define variables with clear descriptions
$languageTag = "he-IL"  # Language code for Hebrew (Israel) (Replace with desired language code)
$downloadUrl = "URL"  # Update download URL for your language
$downloadPath = "C:\Temp\LanguagePackFiles"  # Temporary download location

# Function to check if Hebrew LXP is installed
function Is-LxpInstalled {
  Get-Language | ? {$_.LanguagePacks -match 'LXP' -and $_.LanguageId -match 'he-IL'} #I need to work on this part to validate if this match is invalid then install 
}

# Check if Hebrew LXP is already installed
if (Is-LxpInstalled) {
  Write-Host "Hebrew Language Experience Pack is already installed."
  exit 0  # Exit with success code (0)
}

# Check if the download path exists
if (-not (Test-Path $downloadPath)) {
  Write-Host "The download path $downloadPath does not exist. Creating it..."
# Create temporary download directory (ignore errors if it exists)
New-Item -Path $downloadPath -ItemType Directory -ErrorAction SilentlyContinue
}

# Download the LXP zip file
Invoke-WebRequest -Uri $downloadUrl -UseBasicParsing -OutFile "$downloadPath\LanguageExperiencePack.zip"

Write-Host "Downloading Hebrew Language Experience Pack..."

# Extract the downloaded zip file
Expand-Archive -LiteralPath "$downloadPath\LanguageExperiencePack.zip" -DestinationPath $downloadPath -Force

# Set execution path
Set-Location -Path $downloadPath

# Install the LXP for Windows 11
Add-AppProvisionedPackage -Online -PackagePath "C:\Temp\LanguagePackFiles\LanguageExperiencePack.he-IL.Neutral.appx" -LicensePath "C:\Temp\LanguagePackFiles\License.xml"

Write-Host "Installing Hebrew Language Experience Pack..."

# Install additional language features (consider compatibility and testing thoroughly)
# These paths are based on the downloadPath and might need adjustments based on your download location

# Language features
Add-WindowsPackage -Online -PackagePath "$downloadPath\Microsoft-Windows-Client-Language-Pack_x64_he-il.cab"

# Basic language features
Add-WindowsPackage -Online -PackagePath "$downloadPath\Microsoft-Windows-LanguageFeatures-Basic-he-il-Package~31bf3856ad364e35~amd64~~.cab"

# Fonts
Add-WindowsPackage -Online -PackagePath "$downloadPath\Microsoft-Windows-LanguageFeatures-Fonts-Hebr-Package~31bf3856ad364e35~amd64~~.cab"

# Text-to-Speech
Add-WindowsPackage -Online -PackagePath "$downloadPath\Microsoft-Windows-LanguageFeatures-TextToSpeech-he-il-Package~31bf3856ad364e35~amd64~~.cab"

# Set Hebrew as the system language
Set-SystemPreferredUILanguage $languageTag

Write-Host "Finished installing Hebrew Language Experience Pack and features."

# Optional steps (not recommended for production):
# - Disable Language Pack Cleanup (consider security implications)

exit 0  # Exit with success code (0)
