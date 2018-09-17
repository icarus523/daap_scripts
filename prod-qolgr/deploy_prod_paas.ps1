
# JA Previous subscriptionId: 
#$subscriptionId = "6401edaa-7d66-458e-9cac-04389b15bace"

# DJAG subscriptionId
$subscriptionId = "bb1dd1e3-b731-4239-a1a0-fa1a52457b46"
$resourceGroupName = "PROD-DVSOLGR-paas"
$resourceGroupLocation = "Australia East"
# JA keyVaultName has to be changed, as the original name is being used, and I cannot see it (to remove it) 
$keyVaultName = "DVSOLGR-PROD-keyvault2"
$blobTemplateFilePath = "..\_common\template_storageblob.json"
$busTemplateFilePath = "..\_common\template_servicebus.json"

$blob1ParametersFilePath = "blob-prd.json"
$blob2ParametersFilePath = "blob2-prd.json"
$busParametersFilePath = "sb-prd.json"

..\_common\azure_verify_login.ps1
..\_common\azure_deploy_template.ps1 $subscriptionId $resourceGroupName $resourceGroupLocation $resourceGroupName $blobTemplateFilePath $blob1ParametersFilePath
..\_common\azure_deploy_template.ps1 $subscriptionId $resourceGroupName $resourceGroupLocation $resourceGroupName $blobTemplateFilePath $blob2ParametersFilePath
..\_common\azure_deploy_template.ps1 $subscriptionId $resourceGroupName $resourceGroupLocation $resourceGroupName $busTemplateFilePath $busParametersFilePath
..\_common\azure_create_keyvault.ps1 $resourceGroupName $resourceGroupLocation $keyVaultName

# JA Tag resources
Set-AzureRmResourceGroup -Name $resourceGroupName -Tag @{Department="DJAG";businessowner="OLGR";"Business Unit"="OLGR";application="TATTS Lotto Verification";Environment="DEVEL";infoclassification="XXXXX"}

# These must match the values in the blob parameter files
# JA These have also been changed, as the script will error out indicating invalid template. 
$blob1Name = "dvsolgrblobprd2"
$blob2Name = "dvsolgrblob2prd2"
$serviceBusName = "dvsolgrsbprd2"
..\_common\enable_azurestorage_diagnostics.ps1 $resourceGroupName $blob1Name
..\_common\enable_azurestorage_diagnostics.ps1 $resourceGroupName $blob2Name
..\_common\get_paas_connection_strings.ps1 $resourceGroupName $blob1Name $blob2Name $serviceBusName