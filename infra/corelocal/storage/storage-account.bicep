param name string
param location string = resourceGroup().location
param tags object
param privateEndpoint bool = false
param vnetName string = ''
param vnetResourceGroup string = ''
param subNetName string = ''
param privateEndpointName string = ''
param allowBlobPublicAccess bool = false
param kind string = 'StorageV2'
param minimumTlsVersion string = 'TLS1_2'
param sku object = { name: 'Standard_LRS' }

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  sku: sku
  properties: {
    minimumTlsVersion: minimumTlsVersion
    allowBlobPublicAccess: allowBlobPublicAccess
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    publicNetworkAccess: privateEndpoint ? 'Disabled' : 'Enabled'
  }
}

var serviceTypes = [
  'blob'
  'table'
  'dfs'
]

module privateEndPoint '../../app/private-endpoint.bicep' =  [for service in serviceTypes: if (privateEndpoint) {
  name: 'privateEndPoint${service}'
  scope: resourceGroup()
  params: {
    tags: tags
    serviceId: resourceId('Microsoft.Storage/storageAccounts', name)
    serviceType: service
    subNetName: subNetName
    location: location
    vnetName: vnetName
    vnetResourceGroup: vnetResourceGroup
    privateEndpointName: '${privateEndpointName}-${service}'
  }
  dependsOn: [
    storage
  ]
}]

output name string = storage.name
