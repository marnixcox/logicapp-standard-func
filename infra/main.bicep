targetScope = 'subscription'

@minLength(1)
@maxLength(64)
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


// Service Bus 
@description('Name of queues to configure in the service bus')
param serviceBusQueuesNames array = []
@description('Name of topics/subscriptions to configure in the service bus')
param serviceBusTopicNames array = []
@description('Resource group where service bus is hosted')
param serviceBusResourceGroup string = '$rg-${environmentName}-${resourceToken}-hub'
@description('Service Bus subscription')


// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param apiManagementName string = ''
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
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}-${resourceToken}'
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
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${environmentName}-${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${environmentName}-${resourceToken}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${environmentName}-${resourceToken}'
  }
}

// Keyvault
module keyVault './corelocal/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${environmentName}-${resourceToken}'
    location: location
    tags: tags
    principalId: principalId 
  }
}

// Storage for Azure Functions
module storage './corelocal/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${environmentName}${resourceToken}'
    location: location
    tags: tags  
  }
}

// App Service Plan for Azure Functions
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${environmentName}-${abbrs.webSitesFunctions}${resourceToken}'
    location: location
    kind: 'app'   
    tags: tags
    sku: {
      name: 'Y1'
      tier: 'Dynamic'
    }
  }
  dependsOn: [ storage ]
}

// Azure Functions
module functions './app/functions.bicep' = {
  name: 'functions'
  scope: rg
  params: {
    name: !empty(functionsName) ? functionsName : '${abbrs.webSitesFunctions}${environmentName}-${resourceToken}'
    location: location
    tags: tags
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    appServicePlanId: appServicePlan.outputs.id
    keyVaultName: keyVault.outputs.name
    storageAccountName: storage.outputs.name 
    appSettings:  {
      }
    }
    dependsOn:[
      keyVault
      storage
      appServicePlan
      monitoring
    ]
  }

  // Functions access to Key Vault
module functionsKeyVaultAccess './core/security/keyvault-access.bicep' = {
  name: 'functions-keyvault-access'
  scope: rg
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: functions.outputs.SERVICE_FUNCTIONS_IDENTITY_PRINCIPAL_ID
  }
  dependsOn: [
    workflows
    keyVault
   ]
}

// Logic App Standard Workflows
module workflows './app/workflows.bicep' = {
  name: 'workflows'
  scope: rg
  params: {
    name: !empty(functionsName) ? functionsName : '${abbrs.logicWorkflows}${environmentName}-${resourceToken}'
    environmentName: environmentName
    location: location
    applicationInsightsInstrumentationKey: monitoring.outputs.applicationInsightsConnectionString
    storageAccountName: storage.outputs.name
    appPlanName: '${abbrs.webServerFarms}${environmentName}-${abbrs.logicWorkflows}${resourceToken}' 
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
    ]
  }
  dependsOn: [
    keyVault
    storage
    monitoring
  ]
}

// Logic App Standard Workflows access to Key Vault
module workflowsKeyVaultAccess './core/security/keyvault-access.bicep' = {
  name: 'logic-keyvault-access'
  scope: rg
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: workflows.outputs.logicAppManagedIdentityId
  }
  dependsOn: [
    workflows
    keyVault
   ]
}

// App outputs
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name
