// module-version: 1.0

@description('Name of the Action Group resource')
param name string

@description('Tags to apply to the resource')
param tags object = {}

@description('Short name for the action group (max 12 characters)')
@maxLength(12)
param groupShortName string

@description('Email receivers: [{name, emailAddress}]')
param emailReceivers array = []

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: name
  location: 'global'
  tags: tags
  properties: {
    groupShortName: groupShortName
    enabled: true
    emailReceivers: [for receiver in emailReceivers: {
      name: receiver.name
      emailAddress: receiver.emailAddress
      useCommonAlertSchema: true
    }]
  }
}

@description('Resource ID of the Action Group')
output id string = actionGroup.id

@description('Name of the Action Group')
output name string = actionGroup.name
