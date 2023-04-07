param apimName string
param apimResourceGroup string
param logicAppStandardName string
param workflowName string
param logicAppResourceGroup string
param logicAppSubscription string

//Logic App Backend

resource logicAppStandard 'Microsoft.Web/sites@2021-02-01' existing = {
  name: logicAppStandardName
   scope: resourceGroup(logicAppSubscription, logicAppResourceGroup)
}

var url =  listCallbackUrl('${logicAppStandard.id}/hostruntime/runtime/webhooks/workflow/api/management/workflows/${workflowName}/triggers/manual', '2018-11-01')

resource resLogicAppBackend 'Microsoft.ApiManagement/service/backends@2021-08-01' = {
  name: '${apimName}/${workflowName}' 
  properties: {
    description: workflowName 
    title: null
    protocol: 'http'
   url: url.basePath ?? 'https://localhost'
   credentials: {
    query: {
      sig: [
        '{{${workflowName}-sig}}'
      ]
      sv: [
        url.queries.sv ?? ''
      ]
      'api-version': [
        '2022-05-01'
      ]
      sp: [
        url.queries.sp ?? ''
      ]
    }
  }
  
  
  }
  dependsOn:[
    resLogicAppSignatureNamedValue
]

}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.apimanagement/2021-08-01/service/namedvalues?tabs=bicep
resource resLogicAppSignatureNamedValue 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = {
  name: '${apimName}/${workflowName}-sig'
  properties: {
    displayName: '${workflowName}-sig'
    secret: true
    tags: [
    ]
    value: url.queries.sig ?? ''
  }
}


