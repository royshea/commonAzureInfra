using 'main.bicep'

param location = 'westus3'
param namePrefix = 'hobby'
param storageAccountName = 'sthobbyshared'
param appServicePlanSku = 'B1'

param tags = {
  project: 'shared'
  managedBy: 'bicep'
  lastValidated: '2026-02-23'
}

param openaiDeployments = [
  {
    name: 'gpt-5-nano'
    modelName: 'gpt-5-nano'
    modelVersion: '2025-08-07'
    skuName: 'GlobalStandard'
    capacity: 8
  }
]

// Email receivers are passed via pipeline secret to keep PII out of the public repo.
// Deploy with: --parameters actionGroupEmailReceivers='[{"name":"owner","emailAddress":"<your-email>"}]'
param actionGroupEmailReceivers = []

// SMS receivers are passed via pipeline secret to keep PII out of the public repo.
// Deploy with: --parameters actionGroupSmsReceivers='[{"name":"owner","countryCode":"1","phoneNumber":"<your-number>"}]'
param actionGroupSmsReceivers = []
