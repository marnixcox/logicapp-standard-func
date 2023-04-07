param apimName string
param apimResourceGroup string
param apiName string
param apiDescription string
param apiDefinition string
param apiDefinitionFormat string = 'openapi+json' 
param apiPolicy string
param apiVersion string = 'v1' 
param apiUrl string = 'https://localhost'
param subscriptionRequired bool = true

resource apiVersionSet 'Microsoft.ApiManagement/service/apiVersionSets@2021-08-01' = {
  name: '${apimName}/${apiName}'
  properties: {
     description: apiDescription
  displayName: apiName
  versioningScheme: 'Segment'
}
}

resource api 'Microsoft.ApiManagement/service/apis@2021-08-01' = {
  name: '${apimName}/${apiName}-${apiVersion}'
  properties: {
    apiVersion: apiVersion
    value: apiDefinition
    format: apiDefinitionFormat
    isCurrent: true
    path: apiName
    protocols: [
      'https'
    ]
    serviceUrl: apiUrl
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key' 
      query: 'api-key'
    }
    subscriptionRequired: subscriptionRequired
    apiVersionSetId: apiVersionSet.id
  }
  dependsOn: []
}

resource setApiPolicy 'Microsoft.ApiManagement/service/apis/policies@2020-12-01' =  {
  name: '${apimName}/${apiName}-${apiVersion}/policy'
  properties:{
    value: apiPolicy
    format: 'rawxml'
  }
  dependsOn:[
    api
]
}



