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
param privateEndpoint bool = false
param privateEndpointName string = ''
param vnetName string = ''
param subNetName string = ''
param vnetResourceGroup string = ''
param outBoundSubNetName string = ''

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
    runtimeName: 'dotnet'
    runtimeVersion: '6.0'
    kind: 'functionapp'
    storageAccountName: storageAccountName
    scmDoBuildDuringDeployment: false
    virtualNetworkSubnetId: (!(empty(vnetName))) ? subnet.id : ''
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = if (privateEndpoint)   {
  name: vnetName
  scope: resourceGroup(vnetResourceGroup)
} 

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = if (privateEndpoint) {
  parent: vnet
  name: outBoundSubNetName
}

module privateEndPoint 'private-endpoint.bicep' = if (privateEndpoint) {
  name: 'privateEndPoint'
  scope: resourceGroup()
  params: { 
    tags: tags
    serviceId: resourceId('Microsoft.Web/sites', name)
    serviceType: 'sites'
    location: location
    vnetName: vnetName
    vnetResourceGroup: vnetResourceGroup
    subNetName: subNetName
    privateEndpointName: privateEndpointName
  }
  dependsOn: [
    functions
  ]
}

output SERVICE_FUNCTIONS_IDENTITY_PRINCIPAL_ID string = functions.outputs.identityPrincipalId
output SERVICE_FUNCTIONS_NAME string = functions.outputs.name
output SERVICE_FUNCTIONS_URI string = functions.outputs.uri
