/* Parameters */
param environmentName string
param name string
param location string = resourceGroup().location
param tags object
param applicationInsightsInstrumentationKey string
param logicAppAdditionalAppSettings array = []
param storageAccountName string
param privateEndpoint bool = false
param vnetName string = ''
param appPlanName string = ''
param subNetName string = ''
param vnetResourceGroup string = ''
param logicAppOutBoundSubNetName string = ''
param privateEndpointName string = ''

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
    value: '~12'
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

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appPlanName 
  location: location
  tags: tags
  sku: {
    name: 'WS1'
    tier: 'WorkflowStandard'
  }
  properties: {}
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
      use32BitWorkerProcess: true 
      vnetRouteAllEnabled: true 
      publicNetworkAccess: 'Enabled'
    }
    serverFarmId: appServicePlan.id
    clientAffinityEnabled: false
    virtualNetworkSubnetId: (!(empty(vnetName))) ? subnet.id : null
  }
} 

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = if (privateEndpoint)  {
  name: vnetName
  scope: resourceGroup(vnetResourceGroup)
} 

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = if (privateEndpoint) {
  parent: vnet
  name: logicAppOutBoundSubNetName
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
    logicApp
  ]
}
 
/* Outputs */
output logicAppManagedIdentityId string = logicApp.identity.principalId
output logicAppName string = name
