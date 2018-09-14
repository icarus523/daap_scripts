..\_common\azure_verify_login.ps1

Remove-AzureRmResourceGroup -Name PROD-DVSOLGR-paas

# Manually remove the AzureRmADApplication
$appDisplayName = "DVS.Server"
$azureAdApplication_list = Get-AzureRmADApplication -DisplayNameStartWith $appDisplayName

foreach ($azureAdApp in $azureAdApplication_list) {
    Remove-AzureRmADApplication -ApplicationId $azureAdApp.ApplicationId
}
