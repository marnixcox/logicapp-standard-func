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

module functions '../corelocal/host/functions.bicep' = {
  name: '${serviceName}-dotnet'
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

output SERVICE_FUNCTIONS_IDENTITY_PRINCIPAL_ID string = functions.outputs.identityPrincipalId
output SERVICE_FUNCTIONS_NAME string = functions.outputs.name
output SERVICE_FUNCTIONS_URI string = functions.outputs.uri
