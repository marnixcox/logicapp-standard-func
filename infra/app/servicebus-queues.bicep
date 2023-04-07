/* Parameters */
param serviceBusQueuesNames array = []
param serviceBusTopicNames array = []
param serviceBusName string

var abbreviations = loadJsonContent('../abbreviations.json')

resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' existing = {
  name: serviceBusName
  scope: resourceGroup()
} 
// Service Bus Queues
resource serviceBusQueues 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = [for queueName in serviceBusQueuesNames: {
  parent: serviceBus
  name: '${abbreviations.serviceBusNamespacesQueues}${queueName}'
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}]

// Service Bus Topics
resource serviceBusTopic 'Microsoft.ServiceBus/namespaces/topics@2022-01-01-preview' =  [for i in range(0,  length(serviceBusTopicNames)): {
  parent: serviceBus
  name: '${abbreviations.serviceBusNamespacesTopics}${serviceBusTopicNames[i].topicName}'
  properties: {
  }
}]

// Service Bus Subscriptions
module serviceBusSubscription 'servicebus-subscriptions.bicep' =  [for topic in serviceBusTopicNames: {
  name: topic.topicName
  params: {
    topicName: '${abbreviations.serviceBusNamespacesTopics}${topic.topicName}'
    serviceBusName: serviceBusName
    subscriptions: topic.subscriptions
  }
  dependsOn:  [
    serviceBusTopic
  ]
}]
