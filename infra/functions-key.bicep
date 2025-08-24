@description('The location used for all deployed resources')
param location string = resourceGroup().location

@description('Function app name')
param functionAppName string

@description('Tags that will be applied to all resources')
param tags object = {}

@description('Key vault to store function app access key')
param keyVaultName string

module keyVaultSecret 'keyvault-secret.bicep' = {
  name: 'keyvault-secret'
  params: {
    keyVaultName: keyVaultName
    name: 'FunctionAppKey'
    secretValue: listkeys('${resourceId('Microsoft.Web/sites', functionAppName)}/host/default/','2021-02-01').masterKey
  }
  dependsOn: [
   ]
}



