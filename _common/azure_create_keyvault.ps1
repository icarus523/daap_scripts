<#
 .SYNOPSIS
    Creates and configures a key vault ready for encrypting VM disks

 .PARAMETER resourceGroupName
    The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

 .PARAMETER resourceGroupLocation
    Optional, a resource group location. If specified, will try to create a new resource group in this location. If not specified, assumes resource group is existing.

 .PARAMETER keyVaultName
    The name of the key vault (existing or to be created).
#>

param(
 [Parameter(Mandatory=$True)]
 [string]
 $resourceGroupName,

 [string]
 $resourceGroupLocation,

 [Parameter(Mandatory=$True)]
 [string]
 $keyVaultName
)

$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

Write-Host "Resource Group: $resourceGroupName"
Write-Host "Location      : $resourceGroupLocation"
Write-Host "Key Vault Name: $keyVaultName"
$appDisplayName = "DVS.Server"

## Initialize the azure AD application if required
$azureAdApplication = Get-AzureRmADApplication -DisplayNameStartWith $appDisplayName
$aadClientSecret = "itisasecret"; # use [Guid]::NewGuid().ToString() for randomish secret

if (!$azureAdApplication) {
    Write-Host "Azure AD application not configured, creating..."
    $aadClientSecret = ConvertTo-SecureString $aadClientSecret -AsPlainText -Force
    $azureAdApplication = New-AzureRmADApplication -DisplayName $appDisplayName -HomePage "https://$appDisplayName" -IdentifierUris "https://$appDisplayName" -Password $aadClientSecret
    $servicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $azureAdApplication.ApplicationId
}
else {
    $servicePrincipal = Get-AzureRmADServicePrincipal -SPN $azureAdApplication.ApplicationId
}

$aadClientID = $servicePrincipal.ApplicationId

# Create/Configure key vault for drive encryption
$keyVault = Get-AzureRmKeyVault -VaultName $keyVaultName
if (!$keyVault){
    Write-Host "Azure key vault named $keyVaultName did not exist, creating..."
    $keyVault = New-AzureRmKeyVault -VaultName $keyVaultName -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation
}

$keyVaultUrl = $keyVault.VaultUri
$keyVaultResourceId = $keyVault.ResourceId

Set-AzureRmKeyVaultAccessPolicy -VaultName $keyVaultName -ServicePrincipalName $aadClientID -PermissionsToKeys 'WrapKey' -PermissionsToSecrets 'Set' -ResourceGroupName $resourceGroupName
Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -ResourceGroupName $ResourceGroupName -EnabledForDiskEncryption

$outputPath = "$PSScriptRoot\\$keyVaultName.txt"
[System.IO.File]::WriteAllText($outputPath, "The following details will be needed for deploying/securing the DVS VM`n", [System.Text.Encoding]::ASCII)
[System.IO.File]::AppendAllText($outputPath, "aadClientID: $aadClientID`n", [System.Text.Encoding]::ASCII)
[System.IO.File]::AppendAllText($outputPath, "aadClientSecret: $aadClientSecret`n", [System.Text.Encoding]::ASCII)
[System.IO.File]::AppendAllText($outputPath, "keyVaultUrl: $keyVaultUrl`n", [System.Text.Encoding]::ASCII)
[System.IO.File]::AppendAllText($outputPath, "keyVaultResourceId: $keyVaultResourceId`n", [System.Text.Encoding]::ASCII)
notepad $outputPath

# Return values from function
$props = @{}
$props.AADClientID = $aadClientID
$props.AADClientSecret = $aadClientSecret
$props.KeyVaultUrl = $keyVaultUrl
$props.KeyVaultResourceId = $keyVaultResourceId

$return_object = New-Object -TypeName PSObject -Prop $props
$return_object