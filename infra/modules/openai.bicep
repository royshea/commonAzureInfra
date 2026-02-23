// module-version: 1.0

@description('Name of the Azure OpenAI resource')
param name string

@description('Azure region for the resource')
param location string

@description('Tags to apply to the resource')
param tags object = {}

@description('SKU name')
param skuName string = 'S0'

@description('Model deployments to create')
param deployments array = []

resource openai 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: name
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: skuName
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    customSubDomainName: name
    disableLocalAuth: true
  }
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = [
  for dep in deployments: {
    parent: openai
    name: dep.name
    sku: {
      name: dep.skuName
      capacity: dep.capacity
    }
    properties: {
      model: {
        format: 'OpenAI'
        name: dep.modelName
        version: dep.modelVersion
      }
    }
  }
]

@description('Resource ID of the OpenAI resource')
output id string = openai.id

@description('Endpoint URL')
output endpoint string = openai.properties.endpoint

@description('Name of the OpenAI resource')
output openaiName string = openai.name
