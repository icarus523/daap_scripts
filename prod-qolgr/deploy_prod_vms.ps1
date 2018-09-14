$subscriptionId = "6401edaa-7d66-458e-9cac-04389b15bace"
$resourceGroupName = "PROD-DVSOLGR-VMs"
$resourceGroupLocation = "Australia East"
$vmSqlTemplateFilePath="template_vm-SQL.json"

$dvsParametersFilePath = "vm-prd-SQL.json"

..\_common\azure_verify_login.ps1
..\_common\azure_deploy_template.ps1 $subscriptionId $resourceGroupName $resourceGroupLocation $resourceGroupName $vmSqlTemplateFilePath $dvsParametersFilePath
