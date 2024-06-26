metadata name = 'Network Manager Security Admin Configuration Rule Collections'
metadata description = '''This module deploys an Network Manager Security Admin Configuration Rule Collection.
A security admin configuration contains a set of rule collections. Each rule collection contains one or more security admin rules. Security admin rules allows enforcing security policy criteria that matches the conditions set. Warning: A rule collection without rule will cause a deployment configuration for security admin goal state in network manager to fail.'''
metadata owner = 'Azure/module-maintainers'

@sys.description('Conditional. The name of the parent network manager. Required if the template is used in a standalone deployment.')
param networkManagerName string

@sys.description('Conditional. The name of the parent security admin configuration. Required if the template is used in a standalone deployment.')
param securityAdminConfigurationName string

@maxLength(64)
@sys.description('Required. The name of the admin rule collection.')
param name string

@maxLength(500)
@sys.description('Optional. A description of the admin rule collection.')
param description string = ''

@sys.description('Required. List of network groups for configuration. An admin rule collection must be associated to at least one network group.')
param appliesToGroups array

@sys.description('Optional. List of rules for the admin rules collection. Security admin rules allows enforcing security policy criteria that matches the conditions set. Warning: A rule collection without rule will cause a deployment configuration for security admin goal state in network manager to fail.')
param rules array

resource networkManager 'Microsoft.Network/networkManagers@2023-04-01' existing = {
  name: networkManagerName

  resource securityAdminConfiguration 'securityAdminConfigurations@2023-04-01' existing = {
    name: securityAdminConfigurationName
  }
}

resource ruleCollection 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections@2023-04-01' = {
  name: name
  parent: networkManager::securityAdminConfiguration
  properties: {
    description: description
    appliesToGroups: appliesToGroups
  }
}

module securityAdminConfigurations_rules 'rule/main.bicep' = [for (rule, index) in rules: {
  name: '${uniqueString(deployment().name)}-RuleCollections-Rules-${index}'
  params: {
    networkManagerName: networkManager.name
    securityAdminConfigurationName: securityAdminConfigurationName
    ruleCollectionName: ruleCollection.name
    name: rule.name
    access: rule.access
    description: contains(rule, 'description') ? rule.description : ''
    destinationPortRanges: contains(rule, 'destinationPortRanges') ? rule.destinationPortRanges : []
    destinations: contains(rule, 'destinations') ? rule.destinations : []
    direction: rule.direction
    priority: rule.priority
    protocol: rule.protocol
    sourcePortRanges: contains(rule, 'sourcePortRanges') ? rule.sourcePortRanges : []
    sources: contains(rule, 'sources') ? rule.sources : []
  }
}]

@sys.description('The name of the deployed admin rule collection.')
output name string = ruleCollection.name

@sys.description('The resource ID of the deployed admin rule collection.')
output resourceId string = ruleCollection.id

@sys.description('The resource group the admin rule collection was deployed into.')
output resourceGroupName string = resourceGroup().name
