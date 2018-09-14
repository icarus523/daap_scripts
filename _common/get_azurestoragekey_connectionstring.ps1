<#
 .SYNOPSIS
    Gets a connection string for the provided azure storage account

 .DESCRIPTION
    Registers a machine as an octopus tentacle and will unregister any existing same-named tentacle.

 .PARAMETER ResourceGroupName
    The name of the project in Octopus

 .PARAMETER StorageAccountName
    The address/hostname of the machine to be registered as an octopus tentacle.

 .PARAMETER UseSecondary
    If this switch is set then the secondary account key will be returned
#>

param (
  [parameter(Mandatory=$True)]
  [string] $ResourceGroupName,
  [parameter(Mandatory=$True)]
  [string] $StorageAccountName,
  [switch] $UseSecondary
)

$accountKey = Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
if (!$accountKey) {
  Write-Host "Failed to get accountKey"
  return
}

if ($UseSecondary) {
  $key = $accountKey[1].Value
}
else {
  $key = $accountKey[0].Value
}

return "DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$key"