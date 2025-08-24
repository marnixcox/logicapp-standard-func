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

@description('Log Analytics workspace Resource id')
param logAnalyticsWorkspaceResourceId string

@description('Function app name')
param name string = '${abbrs.webSitesFunctions}${resourceToken}-${environmentName}'

@description('Storage account to store content')
param storageAccountName string

@description('Key vault to store function app access key')
param keyVaultName string

@description('Function app indentity')
param userAssignedIdentity string

@description('Application insights connection')
param applicationInsightsConnectionString string

@description('Function app settings')
param appsettings object

module functionAppPlan 'br/public:avm/res/web/serverfarm:0.5.0' = {
  name: 'functionAppPlan'
  params: {
    name: '${abbrs.webServerFarms}${abbrs.webSitesFunctions}${resourceToken}-${environmentName}'
    location: location
    skuName: 'B1'
    skuCapacity: 1
    reserved: false
    tags: tags
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceResourceId
      }
    ]
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
    functionApp
  ]
}

var coreAppSettings = {
  APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsightsConnectionString
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
  WEBSITE_CONTENTSHARE: name
  APP_KIND: 'functionApp'
  AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(resourceId('Microsoft.Storage/storageAccounts', storageAccountName), '2015-05-01-preview').key1}'
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(resourceId('Microsoft.Storage/storageAccounts', storageAccountName), '2015-05-01-preview').key1}'
}

module functionApp 'br/public:avm/res/web/site:0.19.0' = {
  name: '${deployment().name}-${name}'
  params: {
    name: name
    tags: union(tags, { 'azd-service-name': 'functions' })
    kind: 'functionapp'
    serverFarmResourceId: functionAppPlan.outputs.resourceId
    siteConfig: {
      alwaysOn: true
      netFrameworkVersion: 'v8.0'
    }
    managedIdentities: {
      userAssignedResourceIds: [
        userAssignedIdentity
      ]
    }
    diagnosticSettings: [
      { workspaceResourceId: logAnalyticsWorkspaceResourceId }
    ]
    keyVaultAccessIdentityResourceId: userAssignedIdentity
    configs: [
      {
        name: 'appsettings'
        properties: union(coreAppSettings, appsettings)
      }
    ]
  }
}

// Outputs for use by other modules
output FunctionAppName string = functionApp.outputs.name
