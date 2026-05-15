# Requires -RunAsAdministrator
#Required users
# English, Chinese-Simplified, Spanish, Vietnamese, Russian, Japanesse,
# Preferred username should be name of language, the admin account is English

# --- 1. ADMIN & OS VERSION DETECTION ---
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script MUST be run as an Administrator."
    exit
}

$OSVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
Write-Host "Detected Windows Version: $OSVersion" -ForegroundColor Cyan

# --- 2. DYNAMIC AZURE CONFIGURATION ---
# Assigning URLs and Tokens based on detected OS version
if ($OSVersion -eq "25H2") {
    $baseUrl = "https://upwkintune.blob.core.windows.net/languagepacks-25h2/"
    $sasToken = "?si=rl&spr=https&sv=2025-11-05&sr=c&sig=W%2BtTSa99kUkkbgUIAvXVs5lCXFgoNzkEnr3O0APG8Sk%3D"
} 
elseif ($OSVersion -eq "24H2") {
    # Note: URL contains the typo 'langaugepacks' as provided in your 24H2 string
    $baseUrl = "https://upwkintune.blob.core.windows.net/langaugepacks-24h2/"
    $sasToken = "?si=rl&spr=https&sv=2025-11-05&sr=c&sig=Bsz%2B8JeNqrRZIkBmJf54XVNxgW8PNzAdWM2Bgc3kqB0%3D"
} 
else {
    Write-Error "Unsupported OS Version ($OSVersion). This script is configured for 24H2 and 25H2 only."
    exit
}

# --- 3. DEFINE MAPPING & PATHS ---
$UserMap = @{
    "User_English" = "en-US"; "User_Spanish" = "es-ES"; "User_French"  = "fr-FR"
    "User_Italian" = "it-IT"; "User_Russian" = "ru-RU"; "User_German"  = "de-DE"
}

$downloadPath = "C:\Temp\LanguagePacks-$OSVersion"
if (-not (Test-Path $downloadPath)) { 
    New-Item -Path $downloadPath -ItemType Directory -Force | Out-Null 
}

# --- 4. INSTALL LANGUAGE COMPONENTS ---
foreach ($Lang in $UserMap.Values) {
    $langLower = $Lang.ToLower()
    
    # Filename patterns matching your directory listings [cite: 264-277, 751-886]
    $coreCab = "Microsoft-Windows-Client-Language-Pack_x64_$langLower.cab"
    $basicCab = "Microsoft-Windows-LanguageFeatures-Basic-$langLower-Package~31bf3856ad364e35~amd64~~.cab"
    
    $FilesToInstall = @($coreCab, $basicCab)

    Write-Host "--- Processing Language: $Lang ---" -ForegroundColor Cyan
    foreach ($FileName in $FilesToInstall) {
        $localPath = Join-Path $downloadPath $FileName
        
        # Authenticated download using version-specific SAS [cite: 1472-1518]
        if (-not (Test-Path $localPath) -or (Get-Item $localPath).Length -lt 100kb) {
            try {
                $url = "$($baseUrl)$($FileName)$($sasToken)"
                Write-Host "Downloading $FileName from Azure..."
                Invoke-WebRequest -Uri $url -OutFile $localPath -UseBasicParsing
            } catch { 
                Write-Host "Download failed for $FileName. Verify file exists in $baseUrl" -ForegroundColor Red
                continue 
            }
        }

        # System installation
        try {
            Write-Host "Installing $FileName..."
            # Add-WindowsPackage provides the most reliable installation for offline .cab files
            Add-WindowsPackage -Online -PackagePath $localPath -NoRestart -ErrorAction Stop
            Write-Host "Successfully installed $FileName" -ForegroundColor Green
        } catch { 
            Write-Host "Installation failed/skipped for $FileName : $_" -ForegroundColor Yellow 
        }
    }
}

# --- 5. CREATE USERS & LOGON UI CONFIG ---
foreach ($Username in $UserMap.Keys) {
    if (-not (Get-LocalUser -Name $Username -ErrorAction SilentlyContinue)) {
        Write-Host "Creating kiosk account: $Username"
        $Password = ConvertTo-SecureString " " -AsPlainText -Force # Single space password for Entra compatibility
        New-LocalUser -Name $Username -Password $Password -Description "Kiosk Account for $($UserMap[$Username])"
        Add-LocalGroupMember -Group "Users" -Member $Username
        Set-LocalUser -Name $Username -PasswordNeverExpires $true
    }
}

# Force account enumeration to show icons on the Entra logon screen
Write-Host "Configuring logon screen icons..." -ForegroundColor Cyan
$RegUI = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\UserEnumeration"
$RegSys = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System"

if (-not (Test-Path $RegUI)) { New-Item $RegUI -Force | Out-Null }
Set-ItemProperty -Path $RegUI -Name "EnumerateLocalUsers" -Value 1
Set-ItemProperty -Path $RegSys -Name "DontDisplayLastUserName" -Value 0
Set-ItemProperty -Path $RegSys -Name "DontDisplayLockedUserId" -Value 3
# Allow blank/space passwords for physical console login
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LimitBlankPasswordUse" -Value 0

# --- 6. LOGON LANGUAGE TRIGGER ---
$LogonScript = @"
`$UserMap = @{
    'User_English' = 'en-US'; 'User_Spanish' = 'es-ES'; 'User_French'  = 'fr-FR'
    'User_Italian' = 'it-IT'; 'User_Russian' = 'ru-RU'; 'User_German'  = 'de-DE'
}
`$Name = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
if (`$UserMap.ContainsKey(`$Name)) {
    `$L = `$UserMap[`$Name]
    Set-WinUserLanguageList -LanguageList `$L -Force
    Set-WinUILanguageOverride -Language `$L
}
"@
$LogonScript | Out-File -FilePath "C:\ProgramData\SetUserLanguage.ps1" -Force -Encoding UTF8

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "LanguageSetup" -Value "powershell.exe -ExecutionPolicy Bypass -File C:\ProgramData\SetUserLanguage.ps1"

Write-Host "--- Setup Complete for $OSVersion ---" -ForegroundColor Black -BackgroundColor Green
Write-Host "Please RESTART Windows to see the account list and apply changes."
