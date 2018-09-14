<#
 .SYNOPSIS
    Updates octopus variables for storage accounts/service bus in the given environment

 .DESCRIPTION
    Deploys an Azure Resource Manager template

 .PARAMETER octopusEnvironment
    The environment the variable is scoped to.

 .PARAMETER blob1Name
    Name of the OLGR azure storage account to look up

 .PARAMETER blob2Name
    Name of the DVS azure storage account to look up

 .PARAMETER serviceBusName
    Azure service bus namespace to lookup and update
#>

param(
 [Parameter(Mandatory=$True)]
 [string]
 $resourceGroupName,

 [Parameter(Mandatory=$True)]
 [string]
 $blob1Name,

 [Parameter(Mandatory=$True)]
 [string]
 $blob2Name,

 [Parameter(Mandatory=$True)]
 [string]
 $serviceBusName
)

$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

$libraryVariableSetName = "DVS"
$isLibrarySetVariable = $True

$blob1ConnectionString = &$PSScriptRoot\get_azurestoragekey_connectionstring.ps1 $resourceGroupName $blob1Name
$blob2ConnectionString = &$PSScriptRoot\get_azurestoragekey_connectionstring.ps1 $resourceGroupName $blob2Name
$serviceBusConnectionString = (Get-AzureRmServiceBusKey -ResourceGroupName $resourceGroupName -Namespace $serviceBusName -Name RootManageSharedAccessKey).PrimaryConnectionString

# Write connection strings out to file and open the file
$outputPath = "$PSScriptRoot\\$resourceGroupName.txt"
[System.IO.File]::WriteAllText($outputPath, "Connection details for PAAS components`n", [System.Text.Encoding]::ASCII) # overwrite existing file
[System.IO.File]::AppendAllText($outputPath, "`n", [System.Text.Encoding]::ASCII)
[System.IO.File]::AppendAllText($outputPath, "Blob 1 Connection String     : $blob1ConnectionString`n", [System.Text.Encoding]::ASCII)
[System.IO.File]::AppendAllText($outputPath, "Blob 2 Connection String     : $blob2ConnectionString`n", [System.Text.Encoding]::ASCII)
[System.IO.File]::AppendAllText($outputPath, "Service Bus Connection String: $serviceBusConnectionString`n", [System.Text.Encoding]::ASCII)
notepad $outputPath

# Return values from function
$props = @{}
$props.Blob1ConnectionString = $blob1ConnectionString
$props.Blob2ConnectionString = $blob1ConnectionString
$props.ServiceBusConnectionString = $blob1ConnectionString

$return_object = New-Object -TypeName PSObject -Prop $props
$return_object