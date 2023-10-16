<# Date: 16/10/2023
Version: 0.0.1
Author: Mawanda Hlophoyi
Prerequisites:
Download Transferetto module and import
Title and description:
    This script creates a secure variable to store the credentials to access the sFTP site, this can be used for any remote connections such as connect-pssession wher you are connecting via WinRM.
    This follows up by connecting to the sFTP and listing files that have a name like/ contains "2" and end with ".csv".
    Finally these are downloaded to the local server/ machine and those files are subsequently merged and given a header. 
Thanks to https://github.com/EvotecIT for the script#>

Install-Module -Name Transferetto -AllowClobber -Force | Import-Module Transferetto.psd1 #Download and import the module

# Variables to use
$sFTPSourceFolder = '/inetpub/wwwroot/' # Set the FTP path/ directory
$sFTPDestinationFolder = "<YourDestinationFolder>" # Set Export Directory
$sFTPServer = '<YourIPaddress>'
$Credentials = Get-Credential #Write this into memory.

# Store password in a vault
$SecretFile = 'H:\Scripts\secretfile.txt' #This is the secret file that will contain the hash of the credentials
$Credentials | Export-CliXml -Path $SecretFile
$CredentialVault = $SecretFile
$FileCredential = Import-Clixml -Path $CredentialVault #This imports and decrypts the file

# Connect to SFTP Server
$SftpClient = Connect-SFTP -Server $sFTPServer -Credential $FileCredential

# Get All Files in '/sFTPSourceFolder' for Export, only return files that have a name that is like 2023 and has a .csv as an extension
$Export_Files = Get-SFTPList -SftpClient $SftpClient -Path $sFTPSourceFolder | Where-Object { $_.IsDirectory -eq $false -and $_.Name -like "2*.csv"}

# Download Each File
ForEach ($RemoteFile in $Export_Files) {

    Receive-SFTPFile -SftpClient $SftpClient -RemotePath $RemoteFile.FullName -LocalPath "$sFTPDestinationFolder\$($RemoteFile.Name)"
}

# Disconnect
Disconnect-FTP -Client $Client
# Change directory 
Set-Location -Path $sFTPDestinationFolder

# Copy the download csv files into an archive for storage
Copy-Item -Path $sFTPDestinationFolder\*.csv -Destination 'c:\magento\archive'
# Concatenate all CSV files into a single file
Get-ChildItem -Filter *.csv | ForEach-Object { Get-Content $_ -Raw } | Set-Content -Path outcombined.csv

# Create the header line in a new output CSV file
"Date,Time,Order #,Line #,Item #,Item Name,Units,Value/Unit,Total,Freight,Tax,Adjustments,First Name,Last Name,Customer Number,Customer Group" | Set-Content -Path out.csv

# Append data from outcombined.csv to out.csv, excluding the header line
Get-Content outcombined.csv | Where-Object { $_ -notmatch "Date,Time,Order #,Line #,Item #,Item Name,Units,Value/Unit,Total,Freight,Tax,Adjustments,First Name,Last Name,Customer Number,Customer Group" } | Add-Content -Path out.csv

# Rename output CSV files based on the date (assuming the current date format is used)
$DateSuffix = Get-Date -Format "yyyyMMdd"
$NewFileName = "c:\magento\out_$DateSuffix.csv"
Rename-Item -Path "c:\magento\outcombined.csv" -NewName $NewFileName
