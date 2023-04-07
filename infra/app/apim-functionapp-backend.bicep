param apimName string
param apimResourceGroup string
param functionAppName string
param resourceGroupName string
param subscription string

//Function App Backend

resource functionApp 'Microsoft.Web/sites@2021-02-01' existing = {
  name: functionAppName
   scope: resourceGroup(subscription, resourceGroupName)
}

resource functionAppBackend 'Microsoft.ApiManagement/service/backends@2021-08-01' = {
  name: '${apimName}/${functionAppName}' 
  properties: {
    description: functionAppName 
    title: functionApp.properties.defaultHostName
    protocol: 'http'
    url: 'https://${functionApp.name}.azurewebsites.net/api'
    credentials: {
      header: {
        'x-functions-key': [
          '{{${functionApp.name}-api-key}}'
        ]
      }
    }
  }
  dependsOn:[
    functionAppSignatureNamedValue
]
}

resource functionAppSignatureNamedValue 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = {
  name: '${apimName}/${functionAppName}-api-key'
  properties: {
    displayName: '${functionApp.name}-api-key'
    secret: true
    tags: [
    ]
    value: listkeys('${functionApp.id}/host/default', '2016-08-01').functionKeys.default
  }
}


