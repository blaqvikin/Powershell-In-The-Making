//deploying an app service free

@allowed([
  'F1'
  'B1'
])
param planSKUtypes string = 'F1' //type of plan, default to F1

param APPplanName string = 'FreeLinuxPlan' //name of the app service plan

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: APPplanName
  location: location //resource group location
  sku: {
    name: planSKUtypes
  }
}
//App/web site name
param appServiceName string = 'bicepDevDemoApp'

resource appServiceApp 'Microsoft.Web/sites@2021-03-01' = {
location:location //resource group location
name: appServiceName
kind: 
  properties: {
    httpsOnly: true
    serverFarmId: appServicePlan.id
  }
}
