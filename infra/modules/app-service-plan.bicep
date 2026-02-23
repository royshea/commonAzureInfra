// module-version: 1.0

@description('Name of the App Service Plan')
param name string

@description('Azure region for the plan')
param location string

@description('Tags to apply to the resource')
param tags object = {}

@description('SKU name (e.g., B1, B2, S1)')
param skuName string = 'B1'

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: name
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: skuName
  }
  properties: {
    reserved: true // Required for Linux
  }
}

@description('Resource ID of the App Service Plan')
output id string = plan.id

@description('Name of the App Service Plan')
output planName string = plan.name
