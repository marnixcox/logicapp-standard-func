metadata description = 'Creates or updates a secret in an Azure Key Vault.'

@description('Name of the secret to create or update')
param name string

@description('Tags that will be applied to the secret')
param tags object = {}

@description('The name of the Key Vault where the secret will be stored')
param keyVaultName string

param contentType string = 'string'

@description('The value of the secret. Provide only derived values like blob storage access, but do not hard code any secrets in your templates')
@secure()
param secretValue string

param enabled bool = true
param exp int = 0
param nbf int = 0

// Create or update the secret in the Key Vault
resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: name
  tags: tags
  parent: keyVault
  properties: {
    attributes: {
      enabled: enabled
      exp: exp
      nbf: nbf
    }
    contentType: contentType
    value: secretValue
  }
}

// Reference existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}
