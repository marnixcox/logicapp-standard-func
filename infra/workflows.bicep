@description('The location used for all deployed resources')
param location string

@description('Tags that will be applied to all resources')
param tags object = {}

@description('Abbreviations for Azure resource naming')
param abbrs object

@description('Unique token for resource naming')
param resourceToken string

@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

param name string = '${abbrs.logicWorkflows}${resourceToken}-${environmentName}'
param applicationInsightsConnectionString string
param storageAccountName string
param appPlanName string
param appPlanResourceGroup string
param logicAppIdentity string
param appsettings object

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' existing = {
  name: appPlanName
  scope: resourceGroup(appPlanResourceGroup)
}

var coreAppSettings = {
  APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsightsConnectionString
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: 'dotnet'
  WEBSITE_CONTENTSHARE: name
  APP_KIND: 'workflowApp'
  AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(resourceId('Microsoft.Storage/storageAccounts', storageAccountName), '2015-05-01-preview').key1}'
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(resourceId('Microsoft.Storage/storageAccounts', storageAccountName), '2015-05-01-preview').key1}'
}

module logicapp 'br/public:avm/res/web/site:0.19.0' = {
  name: '${deployment().name}-${name}'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': 'workflows' })
    kind: 'functionapp,workflowapp'
    serverFarmResourceId: appServicePlan.id
    siteConfig: {
      alwaysOn: true
      netFrameworkVersion: 'v8.0'
    }
    managedIdentities: {
      userAssignedResourceIds: [
        logicAppIdentity
      ]
    }
    keyVaultAccessIdentityResourceId: logicAppIdentity
    configs: [
      {
        name: 'appsettings'
        properties: union(coreAppSettings, appsettings)
      }
    ]
  }
}

// Outputs for use by other modules
output logicAppName string = name
