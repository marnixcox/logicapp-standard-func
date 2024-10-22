/* Parameters */
param name string
param location string = resourceGroup().location
param tags object
param applicationInsightsInstrumentationKey string
param logicAppAdditionalAppSettings array = []
param storageAccountName string
param keyVaultName string 
param appPlanName string 
param appPlanResourceGroup string

var logicAppCoreAppSettings = [
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: 'node'
  }
  {
    name: 'WEBSITE_NODE_DEFAULT_VERSION'
    value: '~18'
  }
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(resourceId('Microsoft.Storage/storageAccounts', storageAccountName), '2015-05-01-preview').key1}'
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(resourceId('Microsoft.Storage/storageAccounts', storageAccountName), '2015-05-01-preview').key1}'
  }
  {
    name: 'WEBSITE_CONTENTSHARE'
    value: name
  }
  {
    name: 'AzureFunctionsJobHost__extensionBundle__id'
    value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
  }
  {
    name: 'AzureFunctionsJobHost__extensionBundle__version'
    value: '[1.*, 2.0.0)'
  }
  {
    name: 'APP_KIND'
    value: 'workflowApp'
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: applicationInsightsInstrumentationKey
  }
  {
    name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
    value: '~2'
  }
  {
    name: 'WORKFLOWS_SUBSCRIPTION_ID'
    value: subscription().subscriptionId
  }
  {
    name: 'WORKFLOWS_LOCATION_NAME'
    value: location
  }
  {
    name: 'WORKFLOWS_RESOURCE_GROUP_NAME'
    value: resourceGroup().name
  }
  
]
var logicAppSettings = length(logicAppAdditionalAppSettings) == 0 ? logicAppCoreAppSettings : concat(logicAppCoreAppSettings,logicAppAdditionalAppSettings)

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' existing = {
  name: appPlanName
  scope: resourceGroup(appPlanResourceGroup)
} 

resource logicApp 'Microsoft.Web/sites@2021-02-01' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': 'workflows' })
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    siteConfig: {
      appSettings: logicAppSettings
      use32BitWorkerProcess: false 
      vnetRouteAllEnabled: true 
      publicNetworkAccess: 'Enabled'
      alwaysOn: true
      netFrameworkVersion: 'v6.0'
    }
    serverFarmId: appServicePlan.id
    clientAffinityEnabled: false
  }
} 

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
}

@description('This is the built-in Key Vault Secret User role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#key-vault-secrets-user')
resource keyVaultSecretUserRoleRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '4633458b-17de-408a-b874-0445c86b69e6'
}

@description('Grant the workflow identity with key vault secret user role permissions over the key vault. This allows reading secret contents')
resource keyVaultSecretUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  scope: keyVault
  name: guid(resourceGroup().id, logicApp.id, keyVaultSecretUserRoleRoleDefinition.id)
  properties: {
    roleDefinitionId: keyVaultSecretUserRoleRoleDefinition.id
    principalId: logicApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
 
/* Outputs */
output logicAppManagedIdentityId string = logicApp.identity.principalId
output logicAppName string = name
output logicappApiV string = logicApp.apiVersion
output logicappId string = logicApp.id
