/* Parameters */
param topicName string
param serviceBusName string
param subscriptions array 

// Service Bus Namespace
resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: serviceBusName
}

resource serviceBusTopic 'Microsoft.ServiceBus/namespaces/topics@2022-01-01-preview' existing = {
  parent: serviceBus
  name: topicName
}

resource serviceBusTopicSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-01-01-preview' = [for i in range(0,  length(subscriptions)): {
  parent: serviceBusTopic
  name: '${subscriptions[i].subscriptionName}'
  properties: {
    deadLetteringOnMessageExpiration: true
    defaultMessageTimeToLive: ''
    lockDuration: 'PT1M'
    maxDeliveryCount: 10
  }
}] 

resource serviceBusTopicSubscriptionRule 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2021-06-01-preview' = [for i in range(0,  length(subscriptions)): {
  parent: serviceBusTopicSubscription[i]
  name:  '${subscriptions[i].subscriptionName}'
  properties: {
    action: {}
    filterType: 'SqlFilter'
    sqlFilter: {
      sqlExpression: '${subscriptions[i].sqlExpression}'
      compatibilityLevel: 20
    }
  }
}]



