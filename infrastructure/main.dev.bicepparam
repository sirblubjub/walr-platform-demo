using 'main.bicep'

param environmentName =  'dev'

param tags = {
  Environment: 'dev'
  Solution: 'walr-platform-demo'
  Location: 'uksouth'
  ManagedBy: 'bicep'
  Owner: 'platform-team'
}
