@description('The location used for all deployed resources')
param location string

@description('Tags that will be applied to all resources')
param tags object = {}

@description('Abbreviations for Azure resource naming')
param abbrs object

@description('Unique token for resource naming')
param resourceToken string

@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@description('Log Analytics workspace Resource id')
param logAnalyticsWorkspaceResourceId string

param logicAppIdentity string

param functionsIdentity string

module keyvault 'br/public:avm/res/key-vault/vault:0.13.1' = {
  name: 'keyvault'
  params: {
    name: '${abbrs.keyVaultVaults}${resourceToken}-${environmentName}'
    location: location
    sku: 'standard'
    enablePurgeProtection: false
    tags: tags
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceResourceId
      }
    ]
    roleAssignments: [
      { principalId: functionsIdentity, roleDefinitionIdOrName: 'Key Vault Secrets User' }
      { principalId: logicAppIdentity, roleDefinitionIdOrName: 'Key Vault Secrets User' }
    ]
  }
}

// Outputs for use by other modules
output keyVaultName string = keyvault.outputs.name
