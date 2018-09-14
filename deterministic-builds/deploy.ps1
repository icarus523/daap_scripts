$subscriptionId = "6401edaa-7d66-458e-9cac-04389b15bace"
$resourceGroupName = "DeterministicBuilds"
$resourceGroupLocation = "Australia East"
$deploymentName = $resourceGroupName

$vmTemplateFilePath = "template.json"
$vmParametersFilePath = "parameters.json"

..\_common\azure_verify_login.ps1
..\_common\azure_deploy_template.ps1 $subscriptionId $resourceGroupName $resourceGroupLocation $deploymentName

$rdpFilePath = "$PSScriptRoot\build_machine.rdp"
Get-AzureRmRemoteDesktopFile -ResourceGroupName $resourceGroupName -Name "build" -LocalPath $rdpFilePath -Launch