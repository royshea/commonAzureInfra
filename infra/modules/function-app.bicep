// module-version: 2.0

@description('Name of the Function App')
param name string

@description('Azure region')
param location string

@description('Resource ID of the App Service Plan to host this function app')
param appServicePlanId string

@description('Runtime stack (e.g., DOTNET-ISOLATED|8.0, PYTHON|3.13, NODE|20)')
param linuxFxVersion string

@description('Storage account name for Azure Functions runtime (identity-based connection)')
param storageAccountName string

@description('App settings (environment variables)')
param appSettings array = []

@description('Project name for tagging (used to identify which project owns this resource)')
param projectName string

@description('Additional tags to apply to the resource')
param tags object = {}

@description('Always On setting')
param alwaysOn bool = true

@description('CORS allowed origins (e.g., ["https://myapp.ambleramble.org", "http://localhost:5173"])')
param corsAllowedOrigins array = []

@description('Health check path (e.g., "/api/health")')
param healthCheckPath string = ''

var resourceTags = union(tags, {
  project: projectName
  managedBy: 'bicep'
})

var baseAppSettings = [
  {
    name: 'AzureWebJobsStorage__accountName'
    value: storageAccountName
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: contains(linuxFxVersion, 'DOTNET') ? 'dotnet-isolated' : contains(linuxFxVersion, 'PYTHON') ? 'python' : 'node'
  }
]

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: name
  location: location
  tags: resourceTags
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: alwaysOn
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      healthCheckPath: !empty(healthCheckPath) ? healthCheckPath : null
      cors: !empty(corsAllowedOrigins) ? {
        allowedOrigins: corsAllowedOrigins
      } : null
      appSettings: concat(baseAppSettings, appSettings)
    }
  }
}

@description('Default hostname of the function app')
output defaultHostname string = functionApp.properties.defaultHostName

@description('Resource ID of the function app')
output id string = functionApp.id

@description('Name of the function app')
output functionAppName string = functionApp.name

@description('Principal ID of the system-assigned managed identity')
output principalId string = functionApp.identity.principalId
