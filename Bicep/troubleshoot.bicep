@description('SKU for the storage account')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
parameter storageAccountType string = 'Standard_LRS'

@description('Prefix for storage name.')
param prefixName string

var storageAccountName = '${prefixName}${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: resourceGroup().location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {}
}

resource existingVNet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: 'doesnotexist'
}

output storageAccountName string = storageAccountName
output vnetResult object = existingVNet
