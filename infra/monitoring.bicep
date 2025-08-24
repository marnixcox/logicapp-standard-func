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

// Monitor application with Azure Monitor
module monitoring 'br/public:avm/ptn/azd/monitoring:0.1.0' = {
  name: 'monitoring'
  params: {
    logAnalyticsName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}-${environmentName}'
    applicationInsightsName: '${abbrs.insightsComponents}${resourceToken}-${environmentName}'
    applicationInsightsDashboardName: '${abbrs.portalDashboards}${resourceToken}-${environmentName}'
    location: location
    tags: tags
  }
}

// Outputs for use by other modules
@description('Application Insights resource ID')
output applicationInsightsResourceId string = monitoring.outputs.applicationInsightsResourceId

@description('Application Insights connection string')
output applicationInsightsConnectionString string = monitoring.outputs.applicationInsightsConnectionString

@description('Application Insights instrumentation key')
output applicationInsightsInstrumentationKey string = monitoring.outputs.applicationInsightsInstrumentationKey

@description('Log Analytics workspace resource ID')
output logAnalyticsWorkspaceResourceId string = monitoring.outputs.logAnalyticsWorkspaceResourceId

@description('Log Analytics workspace name')
output logAnalyticsWorkspaceName string = monitoring.outputs.logAnalyticsWorkspaceName
