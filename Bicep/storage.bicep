//Storage account names are not > than 24 chars, due to the function in "var strgAccname" the below values cater for the extra chars
@minLength(3)
@maxLength(19)
param stgrAccNamePrefix string 

//Allowed replication types
@allowed([
  'Standard_LRS'
])
param stgSkuType string = 'Standard_LRS'

// Allowed access tier
@allowed([
  'Cool'
])
param accessTIER string = 'Cool'

//Tags
param tags object = {
  Env: 'Dev'
}

//Variable to create a unique storage account anme
var uniqueId = uniqueString(resourceGroup().id,deployment().name)
var uniqueIdShort = take(uniqueId,5)
var stgrAccName = '${stgrAccNamePrefix}${uniqueIdShort}'

//Storage account location is read from the resource group location
param location string = resourceGroup().location

resource storageaccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: stgrAccName
    location: location
  kind: 'StorageV2'
    sku: {
    name: stgSkuType
  }
  tags:tags
  properties:{
    accessTier: accessTIER
    supportsHttpsTrafficOnly: true
  }  
}

output StorageAccountName string = storageaccount.name
