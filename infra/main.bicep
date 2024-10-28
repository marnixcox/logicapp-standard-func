targetScope = 'subscription'

@minLength(1)
@maxLength(5)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Application
@description('Application name to be used in components')
param resourceToken string = toLower(uniqueString(subscription().id, environmentName, location))
@description('Application resource group')
param resourceGroupName string = ''

@description('Hub Application name to be used in components')
param hubResourceToken string = toLower(uniqueString(subscription().id, environmentName, location))

// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param applicationInsightsDashboardName string = ''
param applicationInsightsName string = ''
param appServicePlanName string = ''
param functionsName string = ''
param keyVaultName string = ''
param logAnalyticsName string = ''
param storageAccountName string = ''

@description('Id of the user or app to assign application roles')
param principalId string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${resourceToken}-${environmentName}'
  location: location
  tags: tags
}

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}-${environmentName}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}-${environmentName}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${resourceToken}-${environmentName}'
  }
}

// Keyvault
module keyVault './avm/key-vault/vault/main.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}-${environmentName}'
    location: location
    sku: 'standard'
    enablePurgeProtection: false
    tags: tags
  }
}

// Storage for Azure Functions and Logic Apps
module storage './core/storage/storage-account.bicep' = {
  name: 'storageaccount'
  scope: rg
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}${environmentName}'
    location: location
    tags: tags  
  }
}

// App Service Plan for Azure Functions
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${abbrs.webSitesFunctions}${resourceToken}-${environmentName}'
    location: location
    kind: 'app'   
    tags: tags
    sku: {
      name: 'Y1'
      tier: 'Dynamic'
    }
  }
  dependsOn: [ storage, keyVault ]
}

// Azure Functions
  module functions './app/functions.bicep' = {
    name: 'functions'
    scope: rg
    params: {
      name: !empty(functionsName) ? functionsName : '${abbrs.webSitesFunctions}${resourceToken}-${environmentName}'
      location: location
      appServicePlanId: appServicePlan.outputs.id
      storageAccountName: storage.outputs.name
      applicationInsightsName: monitoring.outputs.applicationInsightsName
      keyVaultName: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}-${environmentName}'
      tags: tags
      appSettings:{
      }
    }
    dependsOn: [
      appServicePlan
      storage
      monitoring
      keyVault
    ]
  }


// Logic App Standard Workflows
module workflows './app/workflows.bicep' = {
  name: 'workflows'
  scope: rg
  params: {
    name: '${abbrs.logicWorkflows}${resourceToken}-${environmentName}'
    location: location
    applicationInsightsInstrumentationKey: monitoring.outputs.applicationInsightsConnectionString
    storageAccountName: storage.outputs.name
    appPlanName: '${abbrs.webServerFarms}${abbrs.logicWorkflows}${hubResourceToken}-hub-${environmentName}' 
    appPlanResourceGroup: '${abbrs.resourcesResourceGroups}${hubResourceToken}-hub-${environmentName}'
    keyVaultName: '${abbrs.keyVaultVaults}${resourceToken}-${environmentName}'
    tags:  tags
    logicAppAdditionalAppSettings: [
      {
        name: 'FunctionAppKey'
        value: '@Microsoft.KeyVault(SecretUri=${keyVault.outputs.name}.vault.azure.net/secrets/FunctionAppKey)'
      }
      {
        name: 'FunctionAppName'
        value: functions.outputs.SERVICE_FUNCTIONS_NAME
      }
      {
        name: 'keyVault_VaultUri'
        value: keyVault.outputs.uri
      }
    ]
  }
  dependsOn: [
    keyVault
    storage
    monitoring
  ]
}

// App outputs
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name
