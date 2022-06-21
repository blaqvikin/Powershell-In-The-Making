# Name of subscription

$SubscriptionName = “f1888c79-2863-42c3-b807-4e6f0b01e749”

# Name of storage account (where VMs will be deployed)

$StorageAccount = “developmentupload”

function Provision-VM( [string]$VmName ) {

    Start-Job -ArgumentList $VmName {

        param($VmName)

$Location = “Copy the Location property you get from Get-AzureStorageAccount”

$InstanceSize = “A5” # You can use any other instance, such as Large, A6, and so on

$AdminUsername = “UserName” # Write the name of the administrator account in the new VM

$Password = “Password”      # Write the password of the administrator account in the new VM

$Image = “/subscriptions/f1888c79-2863-42c3-b807-4e6f0b01e749/resourceGroups/Norbet-ID-RG/providers/Microsoft.Compute/galleries/Nortbert_ID_SL_Gallery/images/Norbert-ID-SL-ImageDef/versions/0.0.1"

# You can list your own images using the following command:

# Get-AzureVMImage | Where-Object {$_.PublisherName -eq “User” }

        New-AzureVMConfig -Name $VmName -ImageName $Image -InstanceSize $InstanceSize |

            Add-AzureProvisioningConfig -Windows -Password $Password -AdminUsername $AdminUsername|

            New-AzureVM -Location $Location -ServiceName “$VmName” -Verbose

    }

}

# Set the proper storage – you might remove this line if you have only one storage in the subscription

Set-AzureSubscription -SubscriptionName $SubscriptionName -CurrentStorageAccount $StorageAccount

# Select the subscription – this line is fundamental if you have access to multiple subscription

# You might remove this line if you have only one subscription

Select-AzureSubscription -SubscriptionName $SubscriptionName

# Every line in the following list provisions one VM using the name specified in the argument

# You can change the number of lines – use a unique name for every VM – don’t reuse names

# already used in other VMs already deployed

Provision-VM “test10”

Provision-VM “test11”

Provision-VM “test12”

Provision-VM “test13”

Provision-VM “test14”

Provision-VM “test15”

Provision-VM “test16”

Provision-VM “test17”

Provision-VM “test18”

Provision-VM “test19”

Provision-VM “test20”

# Wait for all to complete

While (Get-Job -State “Running”) {

    Get-Job -State “Completed” | Receive-Job

    Start-Sleep1

}

# Display output from all jobs

Get-Job | Receive-Job

# Cleanup of jobs

Remove-Job *

# Displays batch completed

echo “Provisioning VM Completed”