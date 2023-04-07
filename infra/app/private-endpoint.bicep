@description('Location for all resources.')
param location string = resourceGroup().location

param vnetName string
param vnetResourceGroup string
param subNetName string
param serviceId string

@allowed([
  'sites'
  'namespace'
  'vault'
  'blob'
  'table'
  'dfs'
])
param serviceType string
param privateEndpointName string 
param tags object

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing =  {
  name: vnetName
  scope: resourceGroup(vnetResourceGroup)
} 

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  parent: vnet
  name: subNetName
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: { 
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: serviceId
          groupIds: [
            serviceType
          ]
        }
      }
    ]
  }
}
