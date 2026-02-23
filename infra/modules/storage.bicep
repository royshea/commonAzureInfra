// module-version: 1.0

@description('Name of the storage account (3-24 chars, lowercase alphanumeric)')
param name string

@description('Azure region for the storage account')
param location string

@description('Tags to apply to the resource')
param tags object = {}

@description('Storage account SKU')
param skuName string = 'Standard_LRS'

@description('List of blob container names to create')
param blobContainers array = []

@description('List of table names to create')
param tableNames array = []

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: skuName
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = [
  for containerName in blobContainers: {
    parent: blobService
    name: containerName
  }
]

resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource tables 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-05-01' = [
  for tableName in tableNames: {
    parent: tableService
    name: tableName
  }
]

@description('Resource ID of the storage account')
output id string = storageAccount.id

@description('Name of the storage account')
output storageAccountName string = storageAccount.name
