param name string
param location string = resourceGroup().location
param tags object 

param allowedOrigins array = []
param applicationInsightsName string = ''
param appServicePlanId string
param appSettings object = {}
param keyVaultName string
param serviceName string = 'functions'
param storageAccountName string

module functions '../core/host/functions.bicep' = {
  name: '${serviceName}-dotnet-isolated'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    allowedOrigins: allowedOrigins
    alwaysOn: false
    appSettings: appSettings
    applicationInsightsName: applicationInsightsName
    appServicePlanId: appServicePlanId
    keyVaultName: keyVaultName
    runtimeName: 'dotnet-isolated'
    runtimeVersion: '8.0' 
    storageAccountName: storageAccountName
    scmDoBuildDuringDeployment: false
  }
}

module functionsKey './functions-key.bicep' = {
  name: 'functions-key'
  params: {
    functionAppName: name
    keyVaultName: keyVaultName
    tags: tags
  }
  dependsOn: [
    functions
  ]
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
}

@description('This is the built-in Key Vault Secret User role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#key-vault-secrets-user')
resource keyVaultSecretUserRoleRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '4633458b-17de-408a-b874-0445c86b69e6'
}

@description('Grant the function app identity with key vault secret user role permissions over the key vault. This allows reading secret contents')
resource keyVaultSecretUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  scope: keyVault
  name: guid(resourceGroup().id, functions.name, keyVaultSecretUserRoleRoleDefinition.id)
  properties: {
    roleDefinitionId: keyVaultSecretUserRoleRoleDefinition.id
    principalId: functions.outputs.identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output SERVICE_FUNCTIONS_IDENTITY_PRINCIPAL_ID string = functions.outputs.identityPrincipalId
output SERVICE_FUNCTIONS_NAME string = functions.outputs.name
output SERVICE_FUNCTIONS_URI string = functions.outputs.uri
