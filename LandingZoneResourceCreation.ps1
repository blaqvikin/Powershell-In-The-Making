[CmdletBinding()]
Param(
    [string]$duration = "2",

    [string]$userID = "tenantRoot@rainkloud.xyz",

    [string]$TCKey,

    [string]$createdBy = "tenantRoot@rainkloud.xyz",

    [string]$resourceGroupName = "SAN-BaseInfra",

    [string]$Environment = "nonprod",

    [string]$SubscriptionName = "Rainkloud – MPN",

    [string]$BusinessUnit = "finance",

    [string]$Region = "South Africa North",

    [string]$Manager
)
    #Define tags
    $tags = @{"Duration"=$duration;"TCKey"=$TCKey;"CreatedOnDate"=$currentDate;"createdBy"=$createdBy;"BillingApplicationName"="Public Cloud Training";"Manager"=$Manager}
    
    #Connect to Azure
    Connect-AzAccount -SubscriptionName $SubscriptionName -TenantId "f1bab897-81b9-448a-b802-6358c197996f"
    
    #Set subscription context | SB-SBG-InfrastructureTest-NonProd | 88203e18-d026-411d-b6b1-9b2dd235a7ed
    Get-AzSubscription -SubscriptionName $SubscriptionName | Set-AzContext

    #Check if RG exists
    $resourceGroupName = "SAN-BaseInfra"

    if (-Not(Get-AzResourceGroup -Name $resourceGroupName -Location $Region)) {
      # Create resource group
    #  Set-AzContext -SubscriptionName "SandBoxSubscription-$userID"
      Write-Output "AZ context Set"
      New-AzResourceGroup -Name $resourceGroupName -Location $Region -Tag $tags
      Write-Output "Resource Group Created"    
      Start-Sleep -Seconds 15
      Write-Output "finished"

      # Variables to construct the vNET resource names
      $resourceGroupName = $resourceGroupName
      $AzureRegions = @("san", "saw", "weu", "neu")
      $SelectedRegion = $AzureRegions[0]
      $WorkloadType = @("app","db","web","sqlmi")
      $SelectedWorkload = $WorkloadType[0]
      $vNETPrefix = 'vnet'
      $SubnetPrefix = 'subn'
      $RouteTablePrefix = 'rtt'
      $RouteTableSuffix = 'default'
      $StorageAccountPrefix = 'sa'
      $kVaultPrefix = 'kv'
      $NSGPrefix = 'nsg'

      az pipelines show --name IpamReservationTool --org https://dev.azure.com/standardbank --project {AzureServiceCatalogue} --detect false


      # Import the Azure DevOps PowerShell module
      Import-Module Az.Pipelines

      # Trigger a new pipeline run
      $runId = Invoke-AzPipelinesRun -PipelineDefinitionId <pipeline_definition_id> -Parameters @{"BuildConfiguration" = "Debug"}

      # Wait for the pipeline run to complete
      Wait-AzPipelinesRun -RunId $runId

      # Get the output of the "Build" task
      $buildOutput = Get-AzPipelinesTaskOutput -RunId $runId -TaskId <task_id>

      # Print the output of the "Build" task
      Write-Host $buildOutput


      # Call the IPAM API
      #$CallIPAMAPIforAccessToekn = Get-AzAccessToken -ResourceUrl "" -TenantId ""
<#       $accessToken = ConvertTo-SecureString (Get-AzAccessToken -ResourceUrl api://bd2ee934-4cb2-41f3-a1f6-3aa3530961a0).Token -AsPlainText

      $engineClientId = 'bd2ee934-4cb2-41f3-a1f6-3aa3530961a0'
      $appName = 'Azure-IPAM-Engine-Script'
      $space = 'TestSpace'
      $block = 'TestBlock'

      $accessToken = ConvertTo-SecureString (Get-AzAccessToken -ResourceUrl api://$engineClientId).Token -AsPlainText

      $requestUrl = "https://$appName.azurewebsites.net/api/spaces/$space/blocks/$block/reservations"

      $body = @{
          'size' = 24
      } | ConvertTo-Json

      $headers = @{
        'Accept' = 'application/json'
        'Content-Type' = 'application/json'
      }

      $response = Invoke-RestMethod `
      -Method 'Post' `
      -Uri $requestUrl `
      -Authentication 'Bearer' `
      -Token $accessToken `
      -Headers $headers `
      -Body $body #>
      # Calling the Azure naming convention
      # Import the Invoke-RestMethod cmdlet
      # Import the Invoke-RestMethod cmdlet
# Import the Invoke-RestMethod cmdlet
Import-Module Invoke-RestMethod
# Import the Invoke-RestMethod cmdlet
Import-Module Invoke-RestMethod

# Set the Azure Naming Tool REST API endpoint
$apiUrl = "https://aznamingtool-sbsa.azurewebsites.net/api/ResourceComponents?admin=false"

# Set the HTTP request headers
$headers = @{
    Accept = "*/*"
    APIKey = "d160c281-73c8-4d33-9125-395f24498258"
}

# Invoke the Azure Naming Tool REST API
$response = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $headers

# Get the list of resource components
$resourceComponents = $response.Content

# Print the resource components
foreach ($resourceComponent in $resourceComponents) {
    Write-Host $resourceComponent.Name
}


# Get the list of resource components
$resourceComponents = Invoke-RestMethod -Uri "https://aznamingtool-sbsa.azurewebsites.net/api/ResourceComponents?admin=false" -Method Get -Headers @{ Accept = "*/*"; APIKey = "d160c281-73c8-4d33-9125-395f24498258" }.Content

# Construct the compliant name for the Azure virtual machine
$compliantName = "my-vm-{0}".Format($resourceComponents.First().Name)

# Print the compliant name
Write-Host $compliantName



      # Declare variables for network resource creation
      $vNETName = "${vNETPrefix}-${SelectedRegion}-${businessUnit}-${Environment}"
      $SubnetName = "${SubnetPrefix}-${Environment}-${businessUnit}"
      $RTTname = "${RouteTablePrefix}-${SelectedRegion}-${businessUnit}-${Environment}-${RouteTableSuffix}"

      # Create baseinfra vNET and default subnet
      $defaultSubnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix "172.17.0.0/24"
      $virtualNetwork = New-AzVirtualNetwork -Name $vNETName -ResourceGroupName $resourceGroupName -Location $Region -AddressPrefix "172.17.0.0/16" -Subnet $defaultSubnet | Out-Host

      # Create baseinfra route table naming convention
      $defaultRouteName = "${RouteTablePrefix}-${SelectedRegion}-${businessUnit}-${Environment}-${RouteTableSuffix}"

      # Deploy the new route table
      $newDefaultRoute = New-AzRouteConfig -name $defaultRouteName -AddressPrefix "0.0.0.0/0" -NextHopType VirtualAppliance -NextHopIpAddress "1.1.1.1"

      # Deploy the default route table and set the default route
      $routeTable = New-AzRouteTable -Name $RTTname -ResourceGroupName $resourceGroupName -Location $Region -Route $newDefaultRoute -Tag $tags

      # Get the virtual network with subnets
      $virtualNetwork = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vNETName

      # Iterate through the subnets and associate the route table
      foreach ($subnet in $virtualNetwork.Subnets) {
          $subnetConfig = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $virtualNetwork -Name $subnet.Name
          $subnetConfig.RouteTable = $routeTable
      }

      # Update the virtual network to apply the changes
      Set-AzVirtualNetwork -VirtualNetwork $virtualNetwork

      # Naming convention for the NSG
      $NSGname = "${NSGPrefix}-${SelectedRegion}-${businessUnit}-${Environment}-${SubnetPrefix}-${SelectedWorkload}"

      # Define two default rules, one for RDP and one for SSH, both rules allowing on-premises networks.
      $RDPrule = New-AzNetworkSecurityRuleConfig -Name "Allow-RDP-ALL" -Description "Allow-RDP-ALL" `
      -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix @("10.0.0.0/8", "172.17.0.0/16") -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389

      $SSHrule = New-AzNetworkSecurityRuleConfig -Name "Allow-SSH-ALL" -Description "Allow-SSH-ALL" `
      -Access Allow -Protocol Tcp -Direction Inbound -Priority 101 -SourceAddressPrefix `
      @("10.0.0.0/8","172.17.0.0/16") -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22
      
      # Deploy the NSG with the default rules above
      $defaultNSG = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $Region -Name `
      $NSGname -SecurityRules $RDPrule,$SSHrule

      # Create the Azure storage account naming convention
      $storage_account_name = "${StorageAccountPrefix}${SelectedRegion}${businessUnit}${environment}"

      # Create the storage account
      New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storage_account_name -Type "Standard_LRS" -Location $Region

      # Declare the key vault variable, kv naming convention
      $key_vault_name = "${kVaultPrefix}-${SelectedRegion}-${BusinessUnit}-${Environment}"

      # Create the key vault
      New-AzKeyVault -Name $key_vault_name -ResourceGroupName $resourceGroupName -Location $Region -Sku "Standard" -SoftDeleteRetentionInDays '7' -EnableRbacAuthorization -Tag $tags

    }
    # Remaining work
      #Peering to hub vNet
      #Ensure we don't have config drift
      #If sub is prod then this mgmt 
  #sa0115007@standardbank.onmicrosoft.com is used to create subs
  #Move sub to respective mgmt group based on zar, sbg, nonprod / prod
