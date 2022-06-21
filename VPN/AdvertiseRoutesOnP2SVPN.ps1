$gw = Get-AzVirtualNetworkGateway -Name "<NameOfVirtualNetworkGateway>" -ResourceGroupName "<ResourceGroupName>"
Set-AzVirtualNetworkGateway -VirtualNetworkGateway $gw -CustomRoute <routeCIDRaddress>

#check route print to validate.