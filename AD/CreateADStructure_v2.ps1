# Active Directory Structure Deployment Script - Version 2 (abc.local)
# Creates OUs, users, computers, and security groups in abc.local

$Domain = "abc.local"
$RootDN = "DC=abc,DC=local"

# Define OUs to create (prefixed with ABC- to avoid name collisions on migration)
$OUs = @(
    "OU=ABC-Sales,DC=abc,DC=local",
    "OU=ABC-Engineering,DC=abc,DC=local",
    "OU=ABC-Finance,DC=abc,DC=local",
    "OU=ABC-HR,DC=abc,DC=local",
    "OU=ABC-Marketing,DC=abc,DC=local",
    "OU=ABC-IT,DC=abc,DC=local",
    "OU=ABC-Operations,DC=abc,DC=local",
    "OU=ABC-Legal,DC=abc,DC=local",
    "OU=ABC-Support,DC=abc,DC=local",
    "OU=ABC-Disabled Users,DC=abc,DC=local"
)

# Create OUs
Write-Host "Creating OUs for $Domain..." -ForegroundColor Green
foreach ($OU in $OUs) {
    try {
        New-ADOrganizationalUnit -Name ($OU -split ',')[0].Replace('OU=','') -Path ($OU -split ',',2)[1] -ErrorAction Stop
        Write-Host "Created: $OU"
    } catch {
        Write-Host "OU already exists or error: $_"
    }
}

# Create Active Users (20) with an _ABC suffix for sAMAccountName to avoid duplicates
Write-Host "`nCreating 20 active users (sAMAccountName suffix _ABC)..." -ForegroundColor Green
$UserOUs = @("ABC-Sales","ABC-Engineering","ABC-Finance","ABC-HR","ABC-Marketing","ABC-IT","ABC-Operations","ABC-Legal","ABC-Support")
$UserCount = 1
foreach ($i in 1..20) {
    $OUIndex = ($i - 1) % $UserOUs.Count
    $OU = $UserOUs[$OUIndex]
    $UserBase = "user$($UserCount)"
    $Sam = "$UserBase`_ABC"
    $UserPrincipal = "$Sam@$Domain"
    $UserPath = "OU=$OU,DC=abc,DC=local"
    
    try {
        New-ADUser -Name $UserBase -SamAccountName $Sam -UserPrincipalName $UserPrincipal `
            -Path $UserPath -AccountPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force) `
            -Enabled $true -ErrorAction Stop
        Write-Host "Created active user: $Sam"
    } catch {
        Write-Host "Error creating user $Sam : $_"
    }
    $UserCount++
}

# Create Disabled Users (7) with suffix
Write-Host "`nCreating 7 disabled users (sAMAccountName suffix _ABC)..." -ForegroundColor Green
foreach ($i in 1..7) {
    $UserBase = "disabled.user$i"
    $Sam = "$UserBase`_ABC"
    $UserPrincipal = "$Sam@$Domain"
    $UserPath = "OU=ABC-Disabled Users,DC=abc,DC=local"
    
    try {
        New-ADUser -Name $UserBase -SamAccountName $Sam -UserPrincipalName $UserPrincipal `
            -Path $UserPath -AccountPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force) `
            -Enabled $false -ErrorAction Stop
        Write-Host "Created disabled user: $Sam"
    } catch {
        Write-Host "Error creating user $Sam : $_"
    }
}

# Create Computer Objects (20) with an ABC marker in the name
Write-Host "`nCreating 20 computer objects (ABC marker)..." -ForegroundColor Green
foreach ($i in 1..20) {
    $ComputerName = "PC-MIGR-ABC-$($i.ToString('D3'))"
    $OUIndex = ($i - 1) % $UserOUs.Count
    $ComputerPath = "OU=$($UserOUs[$OUIndex]),DC=abc,DC=local"
    
    try {
        New-ADComputer -Name $ComputerName -Path $ComputerPath -ErrorAction Stop
        Write-Host "Created computer: $ComputerName"
    } catch {
        Write-Host "Error creating computer $ComputerName : $_"
    }
}

# Create Security Groups (10) prefixed with ABC- to prevent name collisions
Write-Host "`nCreating 10 security groups (prefixed ABC-)..." -ForegroundColor Green
$GroupNames = @("ABC-SG-Sales-Team","ABC-SG-Engineering-Team","ABC-SG-Finance-Team","ABC-SG-HR-Team",
                "ABC-SG-Marketing-Team","ABC-SG-IT-Admins","ABC-SG-Ops-Team","ABC-SG-Legal-Team",
                "ABC-SG-Support-Team","ABC-SG-All-Users")

foreach ($Group in $GroupNames) {
    try {
        New-ADGroup -Name $Group -SamAccountName $Group -GroupCategory Security `
            -GroupScope Global -Path "DC=abc,DC=local" -ErrorAction Stop
        Write-Host "Created security group: $Group"
    } catch {
        Write-Host "Error creating group $Group : $_"
    }
}

Write-Host "`nDeployment Complete for $Domain!" -ForegroundColor Green
