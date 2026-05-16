# Requires -RunAsAdministrator

# --- 1. ADMIN & OS VERSION DETECTION ---
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script MUST be run as an Administrator."
    exit
}

$OSVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
Write-Host "Detected Windows Version: $OSVersion" -ForegroundColor Cyan

# --- 2. DYNAMIC AZURE CONFIGURATION ---
if ($OSVersion -eq "25H2") {
    $baseUrl = "https://upwkintune.blob.core.windows.net/languagepacks-25h2/"
    $sasToken = "?si=rl&spr=https&sv=2025-11-05&sr=c&sig=W%2BtTSa99kUkkbgUIAvXVs5lCXFgoNzkEnr3O0APG8Sk%3D"
} 
elseif ($OSVersion -eq "24H2") {
    $baseUrl = "https://upwkintune.blob.core.windows.net/langaugepacks-24h2/"
    $sasToken = "?si=rl&spr=https&sv=2025-11-05&sr=c&sig=Bsz%2B8JeNqrRZIkBmJf54XVNxgW8PNzAdWM2Bgc3kqB0%3D"
} 
else {
    Write-Error "Unsupported OS Version ($OSVersion). Script targeted for 24H2/25H2."
    exit
}

# --- 3. UPDATED USER & LANGUAGE MAP ---
$UserMap = @{
    "User_English" = "en-US"
    "User_Spanish" = "es-ES"
    "User_Italian" = "it-IT"
    "User_Russian" = "ru-RU"
    "User_Japanese"= "ja-JP"
    "User_Chinese" = "zh-CN"
}

$downloadPath = "C:\Temp\LanguagePacks-$OSVersion"
if (-not (Test-Path $downloadPath)) { 
    New-Item -Path $downloadPath -ItemType Directory -Force | Out-Null 
}

# --- 4. DOWNLOAD AND INSTALL LOF COMPONENTS ---
foreach ($Lang in $UserMap.Values) {
    $langLower = $Lang.ToLower()
    
    $coreCab = "Microsoft-Windows-Client-Language-Pack_x64_$langLower.cab"
    $basicCab = "Microsoft-Windows-LanguageFeatures-Basic-$langLower-Package~31bf3856ad364e35~amd64~~.cab"
    
    $FilesToInstall = @($coreCab, $basicCab)

    Write-Host "--- Processing Language: $Lang ---" -ForegroundColor Cyan
    foreach ($FileName in $FilesToInstall) {
        $localPath = Join-Path $downloadPath $FileName
        
        # Pull from Azure if file missing or corrupted
        if (-not (Test-Path $localPath) -or (Get-Item $localPath).Length -lt 100kb) {
            try {
                $url = "$($baseUrl)$($FileName)$($sasToken)"
                Write-Host "Downloading $FileName from Azure..."
                Invoke-WebRequest -Uri $url -OutFile $localPath -UseBasicParsing
            } catch { 
                Write-Host "Download failed for $FileName. Verify it is uploaded to your $OSVersion container." -ForegroundColor Red
                continue 
            }
        }

        # Execution block
        try {
            Write-Host "Installing $FileName..."
            Add-WindowsPackage -Online -PackagePath $localPath -NoRestart -ErrorAction Stop
            Write-Host "Successfully installed $FileName" -ForegroundColor Green
        } catch { 
            Write-Host "Installation skipped/failed for $FileName : $_" -ForegroundColor Yellow 
        }
    }
}

# --- 5. CREATE KIOSK ACCOUNTS ---
foreach ($Username in $UserMap.Keys) {
    if (-not (Get-LocalUser -Name $Username -ErrorAction SilentlyContinue)) {
        Write-Host "Creating account: $Username"
        $Password = ConvertTo-SecureString " " -AsPlainText -Force 
        New-LocalUser -Name $Username -Password $Password -Description "Kiosk Account for $($UserMap[$Username])"
        Add-LocalGroupMember -Group "Users" -Member $Username
        Set-LocalUser -Name $Username -PasswordNeverExpires $true
    }
}

# --- 6. FORCE LOGON SCREEN USER LIST ENUMERATION ---
Write-Host "Configuring logon screen for local account mapping..." -ForegroundColor Cyan
$RegUI = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\UserEnumeration"
$RegSys = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System"

if (-not (Test-Path $RegUI)) { New-Item $RegUI -Force | Out-Null }
Set-ItemProperty -Path $RegUI -Name "EnumerateLocalUsers" -Value 1
Set-ItemProperty -Path $RegSys -Name "DontDisplayLastUserName" -Value 0
Set-ItemProperty -Path $RegSys -Name "DontDisplayLockedUserId" -Value 3
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LimitBlankPasswordUse" -Value 0

# --- 7. CREATE PER-USER LOGON APPLICATION SCRIPT ---
# This dynamic script handles OS localization AND applies the unique Edge restriction policy per user
$LogonScript = @"
`$UserMap = @{
    'User_English' = 'en-US'; 'User_Spanish' = 'es-ES'; 'User_Italian' = 'it-IT'
    'User_Russian' = 'ru-RU'; 'User_Japanese' = 'ja-JP'; 'User_Chinese' = 'zh-CN'
}
`$Name = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]

if (`$UserMap.ContainsKey(`$Name)) {
    `$L = `$UserMap[`$Name]
    
    # Apply OS parameters
    Set-WinUserLanguageList -LanguageList `$L -Force
    Set-WinUILanguageOverride -Language `$L
    
    # Apply User-Specific locked Edge browser policy
    `$EdgePolicyPath = "HKCU:\Software\Policies\Microsoft\Edge"
    if (-not (Test-Path `$EdgePolicyPath)) { New-Item `$EdgePolicyPath -Force | Out-Null }
    Set-ItemProperty -Path `$EdgePolicyPath -Name "DefinePreferredLanguages" -Value `$L
}
"@
$LogonScript | Out-File -FilePath "C:\ProgramData\SetUserLanguage.ps1" -Force -Encoding UTF8

# Bind the execution script to user initialization block
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "LanguageSetup" -Value "powershell.exe -ExecutionPolicy Bypass -File C:\ProgramData\SetUserLanguage.ps1"

Write-Host "--- Script Execution Concluded ---" -ForegroundColor Black -BackgroundColor Green
Write-Host "Please remember to upload the Chinese (zh-cn) and Japanese (ja-jp) packages to your storage blob, then execute a clean reboot."
