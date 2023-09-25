param synapseWorkspaceName string
param location string = resourceGroup().location
param sqlAdministratorLogin string = 'sqladminuser'
param storageAccountName string
param storageAccountType string
param nodeSize string
param sparkPoolMinNodeCount int
param sparkPoolMaxNodeCount int
param sparkPoolDelayInMinutes int
param sparkVersion string
param defaultDataLakeStorageFilesystemName string  = 'tempdata'
param startIpaddress string = '0.0.0.0'
param endIpAddress string = '255.255.255.255'
param workspaceExists bool


var storageBlobDataContributorRoleID = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var storageRoleUniqueId = guid(resourceId('Microsoft.Storage/storageAccounts', synapseWorkspaceName), storageAccountType)

resource datalakegen2 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  kind: 'StorageV2'
  location: location
  properties:{
    minimumTlsVersion: 'TLS1_2'
    isHnsEnabled: true
    supportsHttpsTrafficOnly: true
    encryption: {
        services: {
            file: {
                keyType: 'Account'
                enabled: true
            }
            blob: {
                keyType: 'Account'
                enabled: true
            }
        }
        keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
  sku: {
    name: storageAccountType
  }
}

resource blob 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  parent: datalakegen2
  name:  'default'
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  parent: blob
  name: defaultDataLakeStorageFilesystemName
  properties: {
    publicAccess: 'None'
  }
}    

resource synapse 'Microsoft.Synapse/workspaces@2021-06-01' = if (!workspaceExists) {
  name: synapseWorkspaceName
  location: location
  properties: {
    sqlAdministratorLogin: sqlAdministratorLogin
    defaultDataLakeStorage:{
#disable-next-line no-hardcoded-env-urls
      accountUrl: 'https://${datalakegen2.name}.dfs.core.windows.net'
      filesystem: defaultDataLakeStorageFilesystemName
    }
  }
  identity:{
    type:'SystemAssigned'
  }
}

resource synapseRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: storageRoleUniqueId
  scope: datalakegen2
  properties:{
    principalId: synapse.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleID)
  }
}

resource sparkpool 'Microsoft.Synapse/workspaces/bigDataPools@2021-06-01' = {
  name: sparkPoolName
  location: location
  parent: synapse
  properties:{
    nodeSize: nodeSize
    nodeSizeFamily: 'MemoryOptimized'
    autoScale:{
      enabled: true
      minNodeCount: sparkPoolMinNodeCount
      maxNodeCount: sparkPoolMaxNodeCount
    }
    autoPause:{
      enabled: true
      delayInMinutes: sparkPoolDelayInMinutes
    }
    sparkVersion: sparkVersion
  }
}

resource allowazure4synapse 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  name: 'AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
  parent: synapse
}

resource synapseFirewall 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  name: 'allowAll'
  properties: {
    endIpAddress: endIpAddress
    startIpAddress: startIpaddress
  }
  parent: synapse
}
