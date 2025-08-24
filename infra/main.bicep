targetScope = 'subscription'

@minLength(1)
@maxLength(3)
@description('Name of the environment that can be used as part of naming resource convention')
@allowed([
  'dev', 'tst', 'acc', 'prd'
])
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the user or app to assign application roles')
param principalId string = ''

@description('Type of the user or app to assign application roles')
@allowed(['User', 'ServicePrincipal'])
param principalType string = 'User'

@description('Unique token for resource naming')
param resourceToken string = toLower(uniqueString(subscription().id, environmentName, location))

// The principal parameters are available for role assignments if needed in the future
// Currently, the application uses managed identity for secure access

// Tags that should be applied to all resources.
// 
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
}

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${resourceToken}-${environmentName}'
  location: location
  tags: tags
}

module resources 'resources.bicep' = {
  scope: rg
  name: 'resources'
  params: {
    location: location
    tags: tags
    environmentName: environmentName
    resourceToken: resourceToken
  }
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name

