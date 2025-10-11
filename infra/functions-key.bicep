@description('Name of the Function App')
param functionAppName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Tags to be applied to all resources.')
param tags object 

@description()
param keyVaultName string

// Store the Function App master key in Key Vault
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



