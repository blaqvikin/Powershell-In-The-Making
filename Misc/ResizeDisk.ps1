$VMname = $Env:ComputerName

Get-Partition -DiskNumber 0 -PartitionNumber 4 | Resize-Partition -Size 29GB

Stop-Computer $VMname

Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VMname | Start-AzVM -ResourceGroupName $ResourceGroupName `
-Name $vmName

# Variables
$DiskID = "/subscriptions/fec17e22-feb8-4716-b1e1-2a5c6899c539/resourceGroups/ID-SL-VM-Group/providers/Microsoft.Compute/disks/id-sl-vm-0_OsDisk_1_601392afd3044e80870dc0a2586aa60b"
$VMName = "id-sl-vm-0"
$DiskSizeGB = 29
$AzSubscription = "fec17e22-feb8-4716-b1e1-2a5c6899c539"
$AzTenantId = "43ee559a-139e-4cab-877d-f95dab67b1ef"
$OSType= "Windows"

# Provide your Azure admin credentials
Connect-AzAccount -SubscriptionId $AzSubscription -TenantId $AzTenantId

# VM to resize disk of
$VM = Get-AzVm | Where-Object {$_.Name -eq $VMName}

$resourceGroupName = $VM.ResourceGroupName

#$Disk = Get-AzDisk | Where-Object {$_.$DiskName -like $VMname}

$Disk = Get-AzDisk -ResourceGroupName $resourceGroupName `
           -DiskName $vm.StorageProfile.OsDisk.Name | Select-Object Name,OsType,DiskSizeGB,HyperVGeneration

$osDisk= Get-AzDisk -ResourceGroupName $ResourceGroupName `
           -DiskName $vm.StorageProfile.OsDisk.Name

           $osDisk.DiskSizeGB = "29"
#Update-AzDisk -ResourceGroupName $resourceGroupName `
#              -Disk $osDisk  `
 #             -DiskName $osDisk.Name

# Get VM/Disk generation from Disk
$HyperVGen = $Disk.HyperVGeneration

# Get Disk Name from Disk
$DiskName = $Disk.Name

# Create the snapshot
$snapshot =  New-AzSnapshotConfig `
    -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id `
    -Location "West Europe" `
    -CreateOption copy `
    -DiskSizeGB 30

    New-AzSnapshot `
-ResourceGroupName $ResourceGroupName `
-Snapshot $snapshot `
-SnapshotName $DiskName.Replace('OsDisk','OsSnap')



# Get SAS URI for the Managed disk
$SAS = Grant-AzDiskAccess -ResourceGroupName $resourceGroupName -DiskName $DiskName -Access 'Read' -DurationInSecond 600000;

#Provide the managed disk name
#$managedDiskName = "yourManagedDiskName" 

#Provide Shared Access Signature (SAS) expiry duration in seconds e.g. 3600.
$sasExpiryDuration = "3600"

#Provide storage account name where you want to copy the snapshot - the script will create a new one temporarily
$storageAccountName = "idl" + [system.guid]::NewGuid().tostring().replace('-','').substring(1,18)

#Name of the storage container where the downloaded snapshot will be stored
$storageContainerName = "isp"

#Provide the name of the VHD file to which snapshot will be copied.
$destinationVHDFileName = "$($VM.StorageProfile.OsDisk.Name).vhd"

#Generate the SAS for the managed disk
$sas = Grant-AzDiskAccess -ResourceGroupName $resourceGroupName -DiskName $DiskName -Access Read -DurationInSecond $sasExpiryDuration

#Create the context for the storage account which will be used to copy snapshot to the storage account 
#$StorageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName
#$container = $storageContainerName -Context $destinationContext
#$destinationContext = $storageAccountName.Context

$DestinationContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey "8XGcY+ZmkdmVK+I+d+rigJ1oJfVq+1XhdHUbH6Ih7xaThTSPqvOTm1O3a2WkYRylm2QSQ+8mJaGKGP5f1HU7fw=="

#Copy the snapshot to the storage account and wait for it to complete
Start-AzStorageBlobCopy -AbsoluteUri $SAS.AccessSAS -DestContainer $storageContainerName -DestBlob $destinationVHDFileName -DestContext $DestinationContext
while(($state = Get-AzStorageBlobCopyState -Context $Context -Blob $destinationVHDFileName -Container $storageContainerName).Status -ne "Success") { $state; Start-Sleep -Seconds 20 }
$state

# Revoke SAS token
Revoke-AzDiskAccess -ResourceGroupName $resourceGroupName -DiskName $DiskName

# Emtpy disk to get footer from
$emptydiskforfootername = "$($VM.StorageProfile.OsDisk.Name)-empty.vhd"

# Empty disk URI
#$EmptyDiskURI = $container.CloudBlobContainer.Uri.AbsoluteUri + "/" + $emptydiskforfooter

$diskConfig = New-AzDiskConfig `
    -Location $VM.Location `
    -CreateOption Empty `
    -DiskSizeGB $DiskSizeGB `
    -HyperVGeneration $HyperVGen

$dataDisk = New-AzDisk `
    -ResourceGroupName $resourceGroupName `
    -DiskName $emptydiskforfootername `
    -Disk $diskConfig

$VM = Add-AzVMDataDisk `
    -VM $VM `
    -Name $emptydiskforfootername `
    -CreateOption Attach `
    -ManagedDiskId $dataDisk.Id `
    -Lun 63

Update-AzVM -ResourceGroupName $resourceGroupName -VM $VM

$VM | Stop-AzVM -Force


# Get SAS token for the empty disk
$SAS = Grant-AzDiskAccess -ResourceGroupName $resourceGroupName -DiskName $emptydiskforfootername -Access 'Read' -DurationInSecond 600000;

# Copy the empty disk to blob storage
Start-AzStorageBlobCopy -AbsoluteUri $SAS.AccessSAS -DestContainer $storageContainerName -DestBlob $emptydiskforfootername -DestContext $destinationContext
while(($state = Get-AzStorageBlobCopyState -Context $destinationContext -Blob $emptydiskforfootername -Container $storageContainerName).Status -ne "Success") { $state; Start-Sleep -Seconds 20 }
$state

# Revoke SAS token
Revoke-AzDiskAccess -ResourceGroupName $resourceGroupName -DiskName $emptydiskforfootername

# Remove temp empty disk
Remove-AzVMDataDisk -VM $VM -DataDiskNames $emptydiskforfootername
Update-AzVM -ResourceGroupName $resourceGroupName -VM $VM

# Delete temp disk
Remove-AzDisk -ResourceGroupName $resourceGroupName -DiskName $emptydiskforfootername -Force;

# Get the blobs
$emptyDiskblob = Get-AzStorageBlob -Context $destinationContext -Container $storageContainerName -Blob $emptydiskforfootername
$osdisk = Get-AzStorageBlob -Context $destinationContext -Container $storageContainerName -Blob $destinationVHDFileName

$footer = New-Object -TypeName byte[] -ArgumentList 512
write-output "Get footer of empty disk"

$downloaded = $emptyDiskblob.ICloudBlob.DownloadRangeToByteArray($footer, 0, $emptyDiskblob.Length - 512, 512)

$osDisk.ICloudBlob.Resize($emptyDiskblob.Length)
$footerStream = New-Object -TypeName System.IO.MemoryStream -ArgumentList (,$footer)
write-output "Write footer of empty disk to OSDisk"
$osDisk.ICloudBlob.WritePages($footerStream, $emptyDiskblob.Length - 512)

Write-Output -InputObject "Removing empty disk blobs"
$emptyDiskblob | Remove-AzStorageBlob -Force


#Provide the name of the Managed Disk
$NewDiskName = "$DiskName" + "-new"

#Create the new disk with the same SKU as the current one
$accountType = $Disk.Sku.Name

# Get the new disk URI
$vhdUri = $osdisk.ICloudBlob.Uri.AbsoluteUri

# Specify the disk options
$diskConfig = New-AzDiskConfig -AccountType $accountType -Location $VM.location -DiskSizeGB $DiskSizeGB -SourceUri $vhdUri -CreateOption Import -StorageAccountId $StorageAccount.Id -HyperVGeneration $HyperVGen

#Create Managed disk
$NewManagedDisk = New-AzDisk -DiskName $NewDiskName -Disk $diskConfig -ResourceGroupName $resourceGroupName

$VM | Stop-AzVM -Force

# Set the VM configuration to point to the new disk  
Set-AzVMOSDisk -VM $VM -ManagedDiskId $NewManagedDisk.Id -Name $NewManagedDisk.Name

# Update the VM with the new OS disk
Update-AzVM -ResourceGroupName $resourceGroupName -VM $VM

$VM | Start-AzVM

start-sleep 180
# Please check the VM is running before proceeding with the below tidy-up steps

# Delete old Managed Disk
Remove-AzDisk -ResourceGroupName $resourceGroupName -DiskName $DiskName -Force;

# Delete old blob storage
$osdisk | Remove-AzStorageBlob -Force

# Delete temp storage account
$StorageAccount | Remove-AzStorageAccount -Force