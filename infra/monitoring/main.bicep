targetScope = 'resourceGroup'

@description('Azure region for the monitoring resources.')
param location string

@description('Globally unique Log Analytics workspace name.')
param workspaceName string

@description('Action group name for SQL on-call notifications.')
param actionGroupName string

@description('Approved operational mailbox for alert notifications.')
param operatorEmail string

@description('Workspace retention in days. Set this to the approved policy.')
@minValue(30)
@maxValue(730)
param retentionInDays int = 90

@description('Resource tags applied to monitoring resources.')
param tags object = {
  service: 'azure-sql'
  managedBy: 'bicep'
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'SQLOnCall'
    enabled: true
    emailReceivers: [
      {
        name: 'SQL-on-call'
        emailAddress: operatorEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

output workspaceId string = workspace.id
output workspaceCustomerId string = workspace.properties.customerId
output actionGroupId string = actionGroup.id
