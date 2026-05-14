targetScope = 'resourceGroup'

param location string = resourceGroup().location
param environmentName string
param tags object

// AKS
module aks 'br/public:avm/res/container-service/managed-cluster:0.13.1' = {
  name: 'aks'
  params: {
    name: 'aks-${environmentName}'
    location: location
    tags: tags
    primaryAgentPoolProfiles: [
      {
        name: 'systempool'
        count: 1
        vmSize: 'Standard_B2s'
        mode: 'System'
      }
    ]
    managedIdentities: {
      systemAssigned: true
    }
    enableKeyvaultSecretsProvider: true
  }
}

// ACR
module acr 'br/public:avm/res/container-registry/registry:0.12.1' = {
  name: 'acr'
  params: {
    name: 'acr${environmentName}${uniqueString(resourceGroup().id)}'
    location: location
    tags: tags
    acrSku: 'Basic'
    acrAdminUserEnabled: false
    roleAssignments: [
      {
        principalId: aks.outputs.kubeletIdentityObjectId!
        roleDefinitionIdOrName: 'AcrPull'
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

// Key Vault
module keyvault 'br/public:avm/res/key-vault/vault:0.13.3' = {
  name: 'keyvault'
  params: {
    name: 'kv-${environmentName}-${uniqueString(resourceGroup().id)}'
    location: location
    tags: tags
    enableRbacAuthorization: true
    enableSoftDelete: true
    roleAssignments: [
      {
        principalId: aks.outputs.kubeletIdentityObjectId!
        roleDefinitionIdOrName: 'Key Vault Secrets User'
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

// Service Bus
module servicebus 'br/public:avm/res/service-bus/namespace:0.16.1' = {
  name: 'servicebus'
  params: {
    name: 'sb-${environmentName}-${uniqueString(resourceGroup().id)}'
    location: location
    tags: tags
    skuObject: {
      name: 'Standard'
    }
    queues: [
      {
        name: 'survey-responses'
        maxDeliveryCount: 5
      }
    ]
    roleAssignments: [
      {
        principalId: aks.outputs.kubeletIdentityObjectId!
        roleDefinitionIdOrName: 'Azure Service Bus Data Sender'
        principalType: 'ServicePrincipal'
      }
      {
        principalId: aks.outputs.kubeletIdentityObjectId!
        roleDefinitionIdOrName: 'Azure Service Bus Data Receiver'
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

// Cosmos DB
module cosmosdb 'br/public:avm/res/document-db/database-account:0.19.0' = {
  name: 'cosmosdb'
  params: {
    name: 'cosmos-${environmentName}-${uniqueString(resourceGroup().id)}'
    location: location
    tags: tags
    sqlDatabases: [
      {
        name: 'surveydb'
        containers: [
          {
            name: 'responses'
            paths: ['/surveyId']
          }
        ]
      }
    ]
    roleAssignments: [
      {
        principalId: aks.outputs.kubeletIdentityObjectId!
        roleDefinitionIdOrName: 'Cosmos DB Built-in Data Contributor'
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

// Outputs
output aksName string = aks.outputs.name
output acrLoginServer string = acr.outputs.loginServer
output keyVaultName string = keyvault.outputs.name
output serviceBusNamespaceName string = servicebus.outputs.name
output cosmosAccountName string = cosmosdb.outputs.name
