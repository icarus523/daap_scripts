$subscriptionId = "6401edaa-7d66-458e-9cac-04389b15bace"
$resourceGroupName = "PROD-DVSOLGR-paas"
$resourceGroupLocation = "Australia East"
$keyVaultName = "DVSOLGR-PROD-keyvault"
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

# These must match the values in the blob parameter files
$blob1Name = "dvsolgrblobprd"
$blob2Name = "dvsolgrblob2prd"
$serviceBusName = "dvsolgrsbprd"
..\_common\enable_azurestorage_diagnostics.ps1 $resourceGroupName $blob1Name
..\_common\enable_azurestorage_diagnostics.ps1 $resourceGroupName $blob2Name
..\_common\get_paas_connection_strings.ps1 $resourceGroupName $blob1Name $blob2Name $serviceBusName