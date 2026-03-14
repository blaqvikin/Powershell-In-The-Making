# Active Directory Structure Deployment Script - Version 2 (abc.local)
# Creates OUs, users, computers, and security groups in abc.local

$Domain = "abc.local"
$RootDN = "DC=abc,DC=local"

# Create main Corp OU
Write-Host "Creating main Corp OU..." -ForegroundColor Green
try {
    New-ADOrganizationalUnit -Name "Corp" -Path $RootDN -ErrorAction Stop
    Write-Host "Created: OU=Corp,$RootDN"
} catch {
    Write-Host "Corp OU already exists or error: $_"
}

# Define OUs to create under Corp (prefixed with ABC- to avoid name collisions on migration)
$OUs = @(
    "OU=ABC-Sales,OU=Corp,$RootDN",
    "OU=ABC-Engineering,OU=Corp,$RootDN",
    "OU=ABC-Finance,OU=Corp,$RootDN",
    "OU=ABC-HR,OU=Corp,$RootDN",
    "OU=ABC-Marketing,OU=Corp,$RootDN",
    "OU=ABC-IT,OU=Corp,$RootDN",
    "OU=ABC-Operations,OU=Corp,$RootDN",
    "OU=ABC-Legal,OU=Corp,$RootDN",
    "OU=ABC-Support,OU=Corp,$RootDN",
    "OU=ABC-Disabled Users,OU=Corp,$RootDN"
)

# Create OUs
Write-Host "Creating OUs under Corp for $Domain..." -ForegroundColor Green
foreach ($OU in $OUs) {
    try {
        New-ADOrganizationalUnit -Name ($OU -split ',')[0].Replace('OU=','') -Path ($OU -split ',',2)[1] -ErrorAction Stop
        Write-Host "Created: $OU"
    } catch {
        Write-Host "OU already exists or error: $_"
    }
}

# List of fictitious English (US) names
$FictitiousNames = @(
    "John Doe",
    "Jane Smith",
    "Michael Johnson",
    "Emily Davis",
    "David Wilson",
    "Sarah Brown",
    "Christopher Miller",
    "Jessica Garcia",
    "Matthew Martinez",
    "Ashley Rodriguez",
    "Joshua Lee",
    "Amanda Gonzalez",
    "Daniel Perez",
    "Olivia Taylor",
    "Andrew Anderson",
    "Sophia Thomas",
    "James Jackson",
    "Isabella White",
    "William Harris",
    "Mia Martin"
)

# Create Active Users (20) with fictitious names, sAMAccountName as firstlast_ABC
Write-Host "`nCreating 20 active users with fictitious names (sAMAccountName suffix _ABC)..." -ForegroundColor Green
$UserOUs = @("ABC-Sales","ABC-Engineering","ABC-Finance","ABC-HR","ABC-Marketing","ABC-IT","ABC-Operations","ABC-Legal","ABC-Support")
foreach ($i in 0..19) {
    $OUIndex = $i % $UserOUs.Count
    $OU = $UserOUs[$OUIndex]
    $FullName = $FictitiousNames[$i]
    $FirstName = $FullName.Split()[0]
    $LastName = $FullName.Split()[1]
    $Sam = "$($FirstName.ToLower())$($LastName.ToLower())_ABC"
    $UserPrincipal = "$Sam@$Domain"
    $UserPath = "OU=$OU,OU=Corp,$RootDN"
    
    try {
        New-ADUser -Name $FullName -GivenName $FirstName -Surname $LastName -SamAccountName $Sam -UserPrincipalName $UserPrincipal `
            -Path $UserPath -AccountPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force) `
            -Enabled $true -ErrorAction Stop
        Write-Host "Created active user: $Sam ($FullName)"
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