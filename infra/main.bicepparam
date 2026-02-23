using 'main.bicep'

param location = 'westus3'
param resourceGroupName = 'rg-shared-platform'
param namePrefix = 'hobby'
param storageAccountName = 'sthobbyshared'
param appServicePlanSku = 'B1'

param openaiDeployments = [
  {
    name: 'gpt-5-nano'
    modelName: 'gpt-5-nano'
    modelVersion: '2025-08-07'
    skuName: 'GlobalStandard'
    capacity: 8
  }
]
