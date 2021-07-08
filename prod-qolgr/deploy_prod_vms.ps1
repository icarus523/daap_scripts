# JA Previous subscriptionId: 
# $subscriptionId = "6401edaa-7d66-458e-9cac-04389b15bace"

$subscriptionId = "bb1dd1e3-b731-4239-a1a0-fa1a52457b46"
$resourceGroupName = "PROD-DVSOLGR-VMs"
$resourceGroupLocation = "Australia East"
$vmSqlTemplateFilePath="template_vm-SQL.json"
$dvsParametersFilePath = "vm-prd-SQL.json"

..\_common\azure_verify_login.ps1
..\_common\azure_deploy_template.ps1 $subscriptionId $resourceGroupName $resourceGroupLocation $resourceGroupName $vmSqlTemplateFilePath $dvsParametersFilePath

# JA Set Tags
Set-AzureRmResourceGroup -Name $resourceGroupName -Tag @{Department="DJAG";businessowner="OLGR";"Business Unit"="OLGR";application="TATTS Lotto Verification";Environment="DEVEL";infoclassification="XXXXX"}
