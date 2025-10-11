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

@description('Logic App name')
param name string = '${abbrs.logicWorkflows}${resourceToken}-${environmentName}'

@description('Application Insights connection string')
param applicationInsightsConnectionString string

@description('Storage Account name for Logic Apps')
param storageAccountName string

@description('App Service Plan name for Logic Apps')
param appPlanName string

@description('Resource Group of the App Service Plan')
param appPlanResourceGroup string = resourceGroup().name

@description('User Assigned Managed Identity Resource ID for the Logic App')
param logicAppIdentity string

@description('Additional App Settings for the Logic App')
param appsettings object

// Reference existing App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' existing = {
  name: appPlanName
  scope: resourceGroup(appPlanResourceGroup)
}

// Core App Settings for the Logic App
var coreAppSettings = {
  APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsightsConnectionString
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: 'dotnet'
  WORKFLOWS_SUBSCRIPTION_ID: subscription().subscriptionId
  WORKFLOWS_RESOURCE_GROUP_NAME: resourceGroup().name
  WEBSITE_CONTENTSHARE: name
  APP_KIND: 'workflowApp'
  AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(resourceId('Microsoft.Storage/storageAccounts', storageAccountName), '2015-05-01-preview').key1}'
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(resourceId('Microsoft.Storage/storageAccounts', storageAccountName), '2015-05-01-preview').key1}'
}

// Logic App (Standard)
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
      systemAssigned: true
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
@description('Logic App Name')
output logicAppName string = name

@description('Logic App System Assigned Principal ID')
output logicAppPrincipalId string = logicapp.outputs.systemAssignedMIPrincipalId
