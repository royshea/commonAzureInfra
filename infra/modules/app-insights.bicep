// module-version: 1.1

@description('Name of the Application Insights resource')
param name string

@description('Azure region')
param location string

@description('Tags to apply to the resource')
param tags object = {}

@description('Resource ID of the Log Analytics workspace to connect to')
param logAnalyticsWorkspaceId string

@description('Daily ingestion cap in GB (cost circuit-breaker). Default 0.1 GB = 100 MB, well within the 5 GB/month free tier.')
param dailyCapGb string = '0.1'

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

// Daily ingestion cap — prevents runaway costs from logging storms or misconfigured telemetry.
// The 5 GB/month free tier means ~166 MB/day. A 100 MB/day cap is conservative and safe.
#disable-next-line BCP081 // CurrentBillingFeatures API has no Bicep type definitions
resource dailyCap 'Microsoft.Insights/components/CurrentBillingFeatures@2015-05-01' = {
  parent: appInsights
  name: 'CurrentBillingFeatures'
  properties: {
    CurrentBillingFeatures: ['Basic']
    DataVolumeCap: {
      Cap: json(dailyCapGb)
      ResetTime: 0
      WarningThreshold: 80
    }
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
