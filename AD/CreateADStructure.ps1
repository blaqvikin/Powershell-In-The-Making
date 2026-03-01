# Active Directory Structure Deployment Script
# Creates OUs, users, computers, and security groups in xyz.local

$Domain = "xyz.local"
$RootDN = "DC=xyz,DC=local"

# Define OUs to create
$OUs = @(
    "OU=Sales,DC=xyz,DC=local",
    "OU=Engineering,DC=xyz,DC=local",
    "OU=Finance,DC=xyz,DC=local",
    "OU=HR,DC=xyz,DC=local",
    "OU=Marketing,DC=xyz,DC=local",
    "OU=IT,DC=xyz,DC=local",
    "OU=Operations,DC=xyz,DC=local",
    "OU=Legal,DC=xyz,DC=local",
    "OU=Support,DC=xyz,DC=local",
    "OU=Disabled Users,DC=xyz,DC=local"
)

# Create OUs
Write-Host "Creating OUs..." -ForegroundColor Green
foreach ($OU in $OUs) {
    try {
        New-ADOrganizationalUnit -Name ($OU -split ',')[0].Replace('OU=','') -Path ($OU -split ',',2)[1] -ErrorAction Stop
        Write-Host "Created: $OU"
    } catch {
        Write-Host "OU already exists or error: $_"
    }
}

# Create Active Users (20)
Write-Host "`nCreating 20 active users..." -ForegroundColor Green
$UserOUs = @("Sales","Engineering","Finance","HR","Marketing","IT","Operations","Legal","Support")
$UserCount = 1
foreach ($i in 1..20) {
    $OUIndex = ($i - 1) % $UserOUs.Count
    $OU = $UserOUs[$OUIndex]
    $UserName = "user$($UserCount)"
    $UserPath = "OU=$OU,DC=xyz,DC=local"
    
    try {
        New-ADUser -Name $UserName -SamAccountName $UserName -UserPrincipalName "$UserName@$Domain" `
            -Path $UserPath -AccountPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force) `
            -Enabled $true -ErrorAction Stop
        Write-Host "Created active user: $UserName"
    } catch {
        Write-Host "Error creating user $UserName : $_"
    }
    $UserCount++
}

# Create Disabled Users (7)
Write-Host "`nCreating 7 disabled users..." -ForegroundColor Green
foreach ($i in 1..7) {
    $UserName = "disabled.user$i"
    $UserPath = "OU=Disabled Users,DC=xyz,DC=local"
    
    try {
        New-ADUser -Name $UserName -SamAccountName $UserName -UserPrincipalName "$UserName@$Domain" `
            -Path $UserPath -AccountPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force) `
            -Enabled $false -ErrorAction Stop
        Write-Host "Created disabled user: $UserName"
    } catch {
        Write-Host "Error creating user $UserName : $_"
    }
}

# Create Computer Objects (20)
Write-Host "`nCreating 20 computer objects..." -ForegroundColor Green
foreach ($i in 1..20) {
    $ComputerName = "PC-MIGR-$($i.ToString('D3'))"
    $OUIndex = ($i - 1) % $UserOUs.Count
    $ComputerPath = "OU=$($UserOUs[$OUIndex]),DC=xyz,DC=local"
    
    try {
        New-ADComputer -Name $ComputerName -Path $ComputerPath -ErrorAction Stop
        Write-Host "Created computer: $ComputerName"
    } catch {
        Write-Host "Error creating computer $ComputerName : $_"
    }
}

# Create Security Groups (10)
Write-Host "`nCreating 10 security groups..." -ForegroundColor Green
$GroupNames = @("SG-Sales-Team","SG-Engineering-Team","SG-Finance-Team","SG-HR-Team",
                "SG-Marketing-Team","SG-IT-Admins","SG-Ops-Team","SG-Legal-Team",
                "SG-Support-Team","SG-All-Users")

foreach ($Group in $GroupNames) {
    try {
        New-ADGroup -Name $Group -SamAccountName $Group -GroupCategory Security `
            -GroupScope Global -Path "DC=xyz,DC=local" -ErrorAction Stop
        Write-Host "Created security group: $Group"
    } catch {
        Write-Host "Error creating group $Group : $_"
    }
}

Write-Host "`nDeployment Complete!" -ForegroundColor Green