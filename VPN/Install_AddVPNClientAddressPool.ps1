$VPNClientAddressPool = "172.16.201.0/24"
$RG = "<ResourceGroupName>" #Enter the name of the resource group name
$Location = "EastUS" #Enter the location of the resource group name
$GWName = "<VirtualNetworkGatwayName" #The name of the vNET Gw
$GWIPName = "VNet1GWpip" #Name of the vNET Gw

#Deploy the configuration
$Gateway = Get-AzVirtualNetworkGateway -ResourceGroupName $RG -Name $GWName
Set-AzVirtualNetworkGateway -VirtualNetworkGateway $Gateway -VpnClientAddressPool $VPNClientAddressPool