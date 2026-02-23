// module-version: 1.0

@description('Name of the Application Insights resource')
param name string

@description('Azure region')
param location string

@description('Tags to apply to the resource')
param tags object = {}

@description('Resource ID of the Log Analytics workspace to connect to')
param logAnalyticsWorkspaceId string

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
    RetentionInDays: 30
  }
}

@description('Resource ID of the Application Insights resource')
output id string = appInsights.id

@description('Instrumentation key')
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('Connection string for Application Insights')
output connectionString string = appInsights.properties.ConnectionString

@description('Name of the Application Insights resource')
output appInsightsName string = appInsights.name
