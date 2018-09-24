# JA Previous subscriptionId: 
# $subscriptionId = "6401edaa-7d66-458e-9cac-04389b15bace"
$subscriptionId = "bb1dd1e3-b731-4239-a1a0-fa1a52457b46"
$resourceGroupName = "DeterministicBuilds"
$resourceGroupLocation = "Australia East"
$deploymentName = $resourceGroupName

$vmTemplateFilePath = "template.json"
$vmParametersFilePath = "parameters.json"

..\_common\azure_verify_login.ps1
..\_common\azure_deploy_template.ps1 $subscriptionId $resourceGroupName $resourceGroupLocation $deploymentName

# JA Tag resources
Set-AzureRmResourceGroup -Name $resourceGroupName -Tag @{Department="DJAG";businessowner="OLGR";"Business Unit"="OLGR";application="TATTS Lotto Verification";Environment="DEVEL";infoclassification="XXXXX"}

$rdpFilePath = "$PSScriptRoot\build_machine.rdp"
Get-AzureRmRemoteDesktopFile -ResourceGroupName $resourceGroupName -Name "build" -LocalPath $rdpFilePath -Launch