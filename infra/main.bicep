targetScope = 'subscription'

@description('Azure region for all resources')
param location string = 'westus3'

@description('Name of the shared resource group')
param resourceGroupName string = 'rg-shared-platform'

@description('Name prefix for resources')
param namePrefix string = 'hobby'

@description('Storage account name (3-24 chars, lowercase alphanumeric)')
param storageAccountName string = 'st${namePrefix}shared'

@description('Blob containers to create in the shared storage account (project-specific containers should be created in each project\'s own infra)')
param blobContainers array = []

@description('Tables to create in the shared storage account (project-specific tables should be created in each project\'s own infra)')
param tableNames array = []

@description('App Service Plan SKU')
param appServicePlanSku string = 'B1'

@description('Azure OpenAI model deployments')
param openaiDeployments array = []

@description('Tags applied to all resources')
param tags object = {
  project: 'shared'
  managedBy: 'bicep'
}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module logAnalytics 'modules/log-analytics.bicep' = {
  scope: rg
  name: 'log-analytics'
  params: {
    name: 'law-${namePrefix}'
    location: location
    tags: tags
  }
}

module storage 'modules/storage.bicep' = {
  scope: rg
  name: 'storage'
  params: {
    name: storageAccountName
    location: location
    tags: tags
    blobContainers: blobContainers
    tableNames: tableNames
  }
}

module appServicePlan 'modules/app-service-plan.bicep' = {
  scope: rg
  name: 'app-service-plan'
  params: {
    name: 'asp-${namePrefix}'
    location: location
    tags: tags
    skuName: appServicePlanSku
  }
}

module openai 'modules/openai.bicep' = {
  scope: rg
  name: 'openai'
  params: {
    name: 'aoai-${namePrefix}'
    location: location
    tags: tags
    deployments: openaiDeployments
  }
}

module appInsights 'modules/app-insights.bicep' = {
  scope: rg
  name: 'app-insights'
  params: {
    name: 'appi-${namePrefix}'
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
  }
}

@description('Resource group name')
output resourceGroupName string = rg.name

@description('Storage account name')
output storageAccountName string = storage.outputs.storageAccountName

@description('App Service Plan resource ID')
output appServicePlanId string = appServicePlan.outputs.id

@description('OpenAI endpoint')
output openaiEndpoint string = openai.outputs.endpoint

@description('OpenAI resource ID')
output openaiId string = openai.outputs.id

@description('Storage account resource ID')
output storageAccountId string = storage.outputs.id

@description('Log Analytics workspace ID')
output logAnalyticsWorkspaceId string = logAnalytics.outputs.id

@description('Application Insights connection string')
output appInsightsConnectionString string = appInsights.outputs.connectionString

@description('Application Insights resource ID')
output appInsightsId string = appInsights.outputs.id
