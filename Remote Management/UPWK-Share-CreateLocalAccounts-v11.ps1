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

# --- 3. PRODUCTION USER & LANGUAGE MAP (CLEAN PROFILES) ---
$UserMap = @{
    "English"    = "en-US"
    "Spanish"    = "es-ES"
    "Italian"    = "it-IT"
    "Russian"    = "ru-RU"
    "Japanese"   = "ja-JP"
    "Chinese"    = "zh-CN"
    "Vietnamese" = "vi-VN"
}

$downloadPath = "C:\Temp\LanguagePacks-$OSVersion"
if (-not (Test-Path $downloadPath)) { 
    New-Item -Path $downloadPath -ItemType Directory -Force | Out-Null 
}

# --- 4. DOWNLOAD AND INSTALL LOF COMPONENTS ---
foreach ($Lang in $UserMap.Values) {
    $langLower = $Lang.ToLower()
    
    # Adaptive check for Vietnamese LIP framework
    if ($langLower -eq "vi-vn") {
        $coreCab = "Microsoft-Windows-Lip-Language-Pack_x64_vi-vn.cab"
    } else {
        $coreCab = "Microsoft-Windows-Client-Language-Pack_x64_$langLower.cab"
    }
    
    $basicCab = "Microsoft-Windows-LanguageFeatures-Basic-$langLower-Package~31bf3856ad364e35~amd64~~.cab"
    $FilesToInstall = @($coreCab, $basicCab)

    Write-Host "--- Processing Language: $Lang ---" -ForegroundColor Cyan
    foreach ($FileName in $FilesToInstall) {
        $localPath = Join-Path $downloadPath $FileName
        
        if (-not (Test-Path $localPath) -or (Get-Item $localPath).Length -lt 100kb) {
            try {
                $url = "$($baseUrl)$($FileName)$($sasToken)"
                Write-Host "Downloading $FileName from Azure..."
                Invoke-WebRequest -Uri $url -OutFile $localPath -UseBasicParsing
            } catch { 
                Write-Host "Download failed for $FileName. Verify file presence on Azure Storage." -ForegroundColor Red
                continue 
            }
        }

        try {
            Write-Host "Installing $FileName..."
            Add-WindowsPackage -Online -PackagePath $localPath -NoRestart -ErrorAction Stop
            Write-Host "Successfully installed $FileName" -ForegroundColor Green
        } catch { 
            Write-Host "Installation skipped/failed for $FileName : $_" -ForegroundColor Yellow 
        }
    }
}

# --- 5. CREATE PRODUCTION ACCOUNTS (TRUE BLANK PASSWORD) ---
foreach ($Username in $UserMap.Keys) {
    if (-not (Get-LocalUser -Name $Username -ErrorAction SilentlyContinue)) {
        Write-Host "Creating passwordless account: $Username"
        
        # Instantiating a clean SecureString object creates an authentic, 100% blank system password
        $Password = New-Object System.Security.SecureString 
        
        $user = New-LocalUser -Name $Username -Password $Password -Description "Kiosk Account for $($UserMap[$Username])"
        Add-LocalGroupMember -Group "Users" -Member $Username
        Set-LocalUser -Name $Username -PasswordNeverExpires $true
    }
}

# --- 6. FORCE LOGON SCREEN USER LIST & EDGE OVERRIDES (HKLM) ---
Write-Host "Configuring logon screen and Edge global policy overrides..." -ForegroundColor Cyan
$RegUI = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\UserEnumeration"
$RegSys = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
$RegEdgeBase = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

if (-not (Test-Path $RegUI)) { New-Item $RegUI -Force | Out-Null }
if (-not (Test-Path $RegEdgeBase)) { New-Item $RegEdgeBase -Force | Out-Null }

Set-ItemProperty -Path $RegUI -Name "EnumerateLocalUsers" -Value 1
Set-ItemProperty -Path $RegSys -Name "DontDisplayLastUserName" -Value 0
Set-ItemProperty -Path $RegSys -Name "DontDisplayLockedUserId" -Value 3
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LimitBlankPasswordUse" -Value 0
Set-ItemProperty -Path $RegEdgeBase -Name "CloudUserPolicyOverridesCloudProfile" -Value 1

# --- 7. CREATE PER-USER LOGON APPLICATION SCRIPT (WITH AUTO-LOGGING) ---
$LogonScript = @"
if (-not (Test-Path "C:\Temp")) { New-Item -Path "C:\Temp" -ItemType Directory -Force | Out-Null }

Start-Transcript -Path "C:\Temp\LogonLanguageSetup.log" -Append -Force
try {
    `$UserMap = @{
        'English' = 'en-US'; 'Spanish' = 'es-ES'; 'Italian' = 'it-IT'
        'Russian' = 'ru-RU'; 'Japanese' = 'ja-JP'; 'Chinese' = 'zh-CN'; 'Vietnamese' = 'vi-VN'
    }
    `$Name = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]

    if (`$UserMap.ContainsKey(`$Name)) {
        `$L = `$UserMap[`$Name]
        Write-Host "Applying settings for context user: `$Name -> Layout: `$L"
        
        # Apply Windows Native OS Settings
        Set-WinUserLanguageList -LanguageList `$L -Force
        Set-WinUILanguageOverride -Language `$L
        
        # Apply User-Specific Edge Localization Policies
        `$EdgeUserPath = "HKCU:\Software\Policies\Microsoft\Edge"
        if (-not (Test-Path `$EdgeUserPath)) { New-Item `$EdgeUserPath -Force | Out-Null }
        
        Set-ItemProperty -Path `$EdgeUserPath -Name "DefinePreferredLanguages" -Value `$L
        Set-ItemProperty -Path `$EdgeUserPath -Name "ApplicationLocaleValue" -Value `$L
    }
} catch {
    Write-Error "Logon application step failure trace: `$_"
} finally {
    Stop-Transcript
}
"@
$LogonScript | Out-File -FilePath "C:\ProgramData\SetUserLanguage.ps1" -Force -Encoding UTF8

# Bind execution script to user logon sequence
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "LanguageSetup" -Value "powershell.exe -ExecutionPolicy Bypass -File C:\ProgramData\SetUserLanguage.ps1"

Write-Host "--- Production Configuration Completed ---" -ForegroundColor Black -BackgroundColor Green
Write-Host "Please execute a complete system RESTART to load changes."
