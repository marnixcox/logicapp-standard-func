param functionAppName string
param location string = resourceGroup().location
param tags object 
param keyVaultName string

module keyVaultSecret '../core/security/keyvault-secret.bicep' = {
  name: 'keyvault-secret'
  params: {
    keyVaultName: keyVaultName
    name: 'FunctionAppKey'
    secretValue: listkeys('${resourceId('Microsoft.Web/sites', functionAppName)}/host/default/','2021-02-01').masterKey
  }
  dependsOn: [
    
   ]
}

