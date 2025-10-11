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

@description('Logic app indentity for access')
param logicAppIdentity string

@description('Function app indentity for access')
param functionAppIdentity string

@description('Log Analytics workspace Resource id')
param logAnalyticsWorkspaceResourceId string

// Storage Account for Logic Apps and Function Apps
module storage 'br/public:avm/res/storage/storage-account:0.26.0' = {
  name: 'storage'
  params: {
    name: replace('${abbrs.keyVaultVaults}${resourceToken}${environmentName}', '-', '')
    location: location
    tags: tags
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceResourceId
      }
    ]
    publicNetworkAccess: 'Enabled'
    roleAssignments: [
      {
        principalId: logicAppIdentity
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Blob Data Contributor'
      }
      {
        principalId: functionAppIdentity
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Blob Data Contributor'
      }
    ]
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Outputs for use by other modules
@description('Storage Account resource ID')
output storageAccountId string = storage.outputs.resourceId

@description('Storage Account name')
output storageAccountName string = storage.outputs.name
