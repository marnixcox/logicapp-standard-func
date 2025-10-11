@description('The location used for all deployed resources')
param location string = resourceGroup().location

@description('Tags that will be applied to all resources')
param tags object = {}

@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@description('Unique token for resource naming')
param resourceToken string = toLower(uniqueString(subscription().id, environmentName, location))

@description('Hub Application name to be used in components')
param hubResourceToken string = '${toLower(uniqueString(subscription().id, environmentName, location))}-hub'

var abbrs = loadJsonContent('./abbreviations.json')

// Monitor application with Azure Monitor
module monitoring './monitoring.bicep' = {
  name: '${deployment().name}-monitoring'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    environmentName: environmentName
    resourceToken: resourceToken
  }
}

// KeyVault 
module keyvault './keyvault.bicep' = {
  name: '${deployment().name}-keyvault'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    environmentName: environmentName
    resourceToken: resourceToken
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    functionsIdentity: functionsIdentity.outputs.principalId
    logicAppIdentity: logicIdentity.outputs.principalId
  }
}

// Storage for Azure Functions and Logic Apps 
module storage './storage.bicep' = {
  name: '${deployment().name}-storage'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    environmentName: environmentName
    resourceToken: resourceToken
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    logicAppIdentity: logicIdentity.outputs.principalId
    functionAppIdentity: functionsIdentity.outputs.principalId
  }
}

// User Assigned Identity for Logic App
module logicIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.2.1' = {
  name: 'logicIdentity'
  params: {
    name: '${abbrs.managedIdentityUserAssignedIdentities}${abbrs.logicWorkflows}${resourceToken}'
    location: location
  }
}

// Logic App Standard Workflows with shared plan
module workflows './workflows.bicep' = {
  name: '${deployment().name}-workflows'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    environmentName: environmentName
    resourceToken: resourceToken
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    appPlanName: '${abbrs.webServerFarms}${abbrs.logicWorkflows}${hubResourceToken}-${environmentName}'
    appPlanResourceGroup: '${abbrs.resourcesResourceGroups}${hubResourceToken}-${environmentName}'
    storageAccountName: storage.outputs.storageAccountName
    logicAppIdentity: logicIdentity.outputs.resourceId
    appsettings: {
      FUNCTIONAPP_KEY: '@Microsoft.KeyVault(SecretUri=${keyvault.outputs.keyVaultName}.vault.azure.net/secrets/FunctionAppKey)'
      FUNCTIONAPP_NAME: functions.outputs.FunctionAppName
    }
  }

  dependsOn: []
}

module functionsIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.2.1' = {
  name: 'functionsIdentity'
  params: {
    name: '${abbrs.managedIdentityUserAssignedIdentities}${abbrs.webSitesFunctions}${resourceToken}'
    location: location
  }
}

var functionEnvironmentSettings = {
  dev: {
    catServiceUrl: 'https://cat-fact.herokuapp.com/facts/'
    vehicleServiceUrl: 'https://vpic.nhtsa.dot.gov/api/vehicles/getallmakes'
  }
  tst: {
    catServiceUrl: 'https://cat-fact.herokuapp.com/facts/'
    vehicleServiceUrl: 'https://vpic.nhtsa.dot.gov/api/vehicles/getallmakes'
  }
  acc: {
    catServiceUrl: 'https://cat-fact.herokuapp.com/facts/'
    vehicleServiceUrl: 'https://vpic.nhtsa.dot.gov/api/vehicles/getallmakes'
  }
  prd: {
    catServiceUrl: 'https://cat-fact.herokuapp.com/facts/'
    vehicleServiceUrl: 'https://vpic.nhtsa.dot.gov/api/vehicles/getallmakes'
  }
}

// FunctionApp including plan
module functions './functions.bicep' = {
  name: '${deployment().name}-functions'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    environmentName: environmentName
    resourceToken: resourceToken
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    keyVaultName: keyvault.outputs.keyVaultName
    storageAccountName: storage.outputs.storageAccountName
    userAssignedIdentity: functionsIdentity.outputs.resourceId
    appsettings: {
      CatServiceUrl:  functionEnvironmentSettings[environmentName].catServiceUrl
      VehicleServiceUrl:  functionEnvironmentSettings[environmentName].vehicleServiceUrl
    }
  }
  dependsOn: []
}
