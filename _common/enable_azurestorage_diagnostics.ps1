<#
 .SYNOPSIS
    Enabled diagnostics for an azure storage account

 .DESCRIPTION
    Enabled diagnostics for an azure storage account

 .PARAMETER ResourceGroupName
    The name of resource group the storage account lives under in Azure

 .PARAMETER StorageAccountName
    The name of the storage account

 .PARAMETER RetentionDays
    Number of days to retain diagnostics, defaults to 90
#>

param(
 [Parameter(Mandatory=$True)]
 [string]
 $resourceGroupName,

 [Parameter(Mandatory=$True)]
 [string]
 $storageAccountName,

 [int]
 $retentionDays = 90
)

$storageAccountKey = Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName
$storageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey[0].Value
Set-AzureStorageServiceLoggingProperty -Context $storageContext -ServiceType Blob -LoggingOperations All -RetentionDays $retentionDays

if ($? -eq $True) { Write-Output "Enabled diagnostic logging for $storageAccountName" }
else { Write-Output "Failed to enable diagnostics for $storageAccountName" }