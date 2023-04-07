@description('Location for all resources.')
param location string = resourceGroup().location

param vnetName string
param subNetName string
param subnetPrefix string
param networkSecurityGroup string
param routeTable string
@allowed([
  'serverFarms'
   ''
])
param delegations string = ''

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing =  {
  name: vnetName
} 

resource subnetServerFarms 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' =  {
  name: subNetName
  parent: vnet
  properties: {
    addressPrefix: subnetPrefix
    networkSecurityGroup: {
      id: resourceId('Microsoft.Network/networkSecurityGroups', networkSecurityGroup)
    }
    routeTable: {
      id: resourceId('Microsoft.Network/routeTables', routeTable)
    }
    delegations: delegations == 'serverFarms' ? [
      {
           name: 'Microsoft.Web.serverFarms'
           properties: {
             serviceName: 'Microsoft.Web/serverFarms'
           }
           type: 'Microsoft.Network/virtualNetworks/subnets/delegations'

      } 
   ] : null
   privateEndpointNetworkPolicies: 'Disabled'
   privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

