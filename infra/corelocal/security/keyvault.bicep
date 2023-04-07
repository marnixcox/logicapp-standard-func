param name string
param location string = resourceGroup().location
param tags object
param privateEndpoint bool = false
param vnetName string = ''
param vnetResourceGroup string = ''
param subNetName string = ''
param privateEndpointName string = ''

param principalId string = ''

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    accessPolicies: !empty(principalId) ? [
      {
        objectId: principalId
        permissions: { secrets: [ 'get', 'list' ] }
        tenantId: subscription().tenantId
      }
    ] : []
    publicNetworkAccess: privateEndpoint ? 'Disabled' : 'Enabled'
  }
}

module privateEndPoint '../../app/private-endpoint.bicep' = if (privateEndpoint == true) {
  name: 'privateEndPoint'
  scope: resourceGroup()
  params: {
    tags: tags
    serviceId: resourceId('Microsoft.KeyVault/vaults', name)
    serviceType: 'vault'
    subNetName: subNetName
    location: location
    vnetName: vnetName
    vnetResourceGroup: vnetResourceGroup
    privateEndpointName: privateEndpointName
  }
  dependsOn: [
    keyVault
  ]
}

output endpoint string = keyVault.properties.vaultUri
output name string = keyVault.name
