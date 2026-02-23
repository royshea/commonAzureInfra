// module-version: 1.0

@description('Principal ID of the managed identity to grant access')
param principalId string

@description('Resource ID of the Azure OpenAI account')
param openaiAccountId string

// Built-in role: Cognitive Services OpenAI User
var cognitiveServicesOpenAIUserRoleId = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'

resource openaiAccount 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = {
  name: last(split(openaiAccountId, '/'))
}

resource openaiRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(openaiAccountId, principalId, cognitiveServicesOpenAIUserRoleId)
  scope: openaiAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesOpenAIUserRoleId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
