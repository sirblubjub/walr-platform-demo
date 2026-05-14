using 'main.bicep'

param environmentName =  'Dev'

param tags = {
  Environment: 'Dev'
  Solution: 'Walr-Platform-Demo'
  Location: 'UkSouth'
  ManagedBy: 'Bicep'
  Owner: 'Platform-Team'
}
