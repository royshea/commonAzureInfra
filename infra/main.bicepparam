using 'main.bicep'

param location = 'westus2'
param resourceGroupName = 'rg-shared-platform'
param namePrefix = 'hobby'
param storageAccountName = 'sthobbyshared'
param appServicePlanSku = 'B1'

param blobContainers = [
  'recipes'
]

param tableNames = [
  'sensorreadings'
  'conversations'
  'messages'
]

param openaiDeployments = [
  {
    name: 'gpt-4o-mini'
    modelName: 'gpt-4o-mini'
    modelVersion: '2024-07-18'
    skuName: 'GlobalStandard'
    capacity: 8
  }
]
