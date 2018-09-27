<#
.SYNOPSIS
    Downloads the files in the $certsprod_dir, $deployitems_dir and $scripts_dir to their corresponding directory in the olgrscripts blob storage. 
#>
# change the following to your respective directories. 
$dl_directory = "C:\Users\Public\" # Change Me

$download_filename = "DAAP 1.1.zip"
$blob_container_name = "source"

..\_common\azure_verify_login.ps1

$subscriptionId = "bb1dd1e3-b731-4239-a1a0-fa1a52457b46"

# select subscription
Write-Host "Selecting subscription '$subscriptionId'";
Select-AzureRmSubscription -SubscriptionID $subscriptionId;

$ResourceGroupName = "Olgr-Scripts"
$StorageAccountName = "olgrscripts"
$accountKey = Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
$blobstorage_olgrscripts_accountKey = $accountKey[0].Value
$blobstorageContext_olgrscripts = New-AzureStorageContext -ConnectionString "DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$blobstorage_olgrscripts_accountKey"

$blob_container_contents = Get-AzureStorageBlob -Container $blob_container_name -Context $blobstorageContext_olgrscripts

if (-Not [string]::IsNullOrEmpty($blob_container_contents)) {
    Get-AzureStorageBlobContent -Container $blob_container_name -Blob $download_filename -Destination $dl_directory -Context $blobstorageContext_olgrscripts
}
