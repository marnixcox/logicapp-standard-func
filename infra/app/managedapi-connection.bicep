@description('Location for all resources.')
param location string = resourceGroup().location
param connectionname string
param connectionkind string
param getExisting bool

resource apiConnection1 'Microsoft.Web/connections@2018-07-01-preview' existing = if(getExisting) {
  name: connectionname
}

resource apiConnection2 'Microsoft.Web/connections@2018-07-01-preview' = if(!getExisting) {
  name: connectionname
  location: location
  kind: 'V2'  
  properties: {
    displayName: connectionname
    api: any({
      description: 'API connection ${connectionname}'
      id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/${connectionkind}'
    })    
    parameterValues: {          
    }
  }
}

output url string = (getExisting) ? apiConnection1.properties.connectionRuntimeUrl : apiConnection2.properties.connectionRuntimeUrl
