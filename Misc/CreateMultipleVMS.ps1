function Provision-AzVM {
    param (
        $VMName
    )

## VM Account
# Credentials for Local Admin account you created in the sysprepped (generalized) vhd image
$VMLocalAdminUser = "ID-Master-Admin"
$VMLocalAdminSecurePassword = ConvertTo-SecureString "Di55i(ultP@D" -AsPlainText -Force
## Azure Account
$LocationName = "West Europe"
$ResourceGroupName = "Norbet-ID-RG"
# This a Premium_LRS storage account.
# It is required in order to run a client VM with efficiency and high performance.
$StorageAccount = "idvmslstorage"

## VM
$OSDiskName = "VMOSDisk"
$ComputerName = "ID-SL-VM-00"
$OSDiskUri = "https://idvmslstorage.blob.core.windows.net/disks/VMOSDisk.vhd" #VM ID needs to be changed.
$SourceImageUri = Set-AzVMSourceImage -VM $VMName -Id "/subscriptions/f1888c79-2863-42c3-b807-4e6f0b01e749/resourceGroups/Norbet-ID-RG/providers/Microsoft.Compute/galleries/Nortbert_ID_SL_Gallery/images/Norbert-ID-SL-ImageDef/versions/0.0.1"
$VMName = "ID-SL-VM-00"
# Modern hardware environment with fast disk, high IOPs performance.
# Required to run a client VM with efficiency and performance
$VMSize = "Standard_B2s"
$OSDiskCaching = "ReadWrite"
$OSCreateOption = "FromImage"

## Networking
$DNSNameLabel = "idsolution01" # mydnsname.westus.cloudapp.azure.com
$NetworkName = "Norbet-ID-RG-vnet"
$NICName = "ID-SL-VM-Nic0"
$PublicIPAddressName = "ID-SL-VM-Pup0"
$SubnetName = "default"
$SubnetAddressPrefix = "172.17.0.0/24"
$VnetAddressPrefix = "172.17.0.0/16"

$SingleSubnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
$Vnet = New-AzVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName -Location $LocationName -AddressPrefix $VnetAddressPrefix -Subnet $SingleSubnet
$PIP = New-AzPublicIpAddress -Name $PublicIPAddressName -DomainNameLabel $DNSNameLabel -ResourceGroupName $ResourceGroupName -Location $LocationName -AllocationMethod Dynamic
$NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $LocationName -SubnetId $Vnet.Subnets[0].Id -PublicIpAddressId $PIP.Id

$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $Credential
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -SourceImageUri $SourceImageUri -Caching $OSDiskCaching -CreateOption $OSCreateOption -Windows

New-AzVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $VirtualMachine -Verbose

}
$VMCount = @(
    "SL00"
    "SL01"
    "SL02"
)
foreach ($VM in $VMCount) {
    Provision-AzVM -VMName $VMCount
    
}