// module-version: 1.0

@description('Name of the Log Analytics workspace')
param name string

@description('Azure region for the workspace')
param location string

@description('Tags to apply to the resource')
param tags object = {}

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

@description('Resource ID of the Log Analytics workspace')
output id string = workspace.id

@description('Name of the Log Analytics workspace')
output workspaceName string = workspace.name
