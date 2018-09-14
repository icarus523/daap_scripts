<#
.SYNOPSIS
    Uploads files in the $certsprod_dir, $deployitems_dir and $scripts_dir to their corresponding directory in the olgrscripts blob storage. 
#>
# change the following to your respective directories. 
$certsprod_dir = "C:\Users\Public\Lotteries.DVS.AzureScripts\prod-qolgr\Storage_Blob_scripts_configuration\certsprod"
$deployitems_dir = "C:\Users\Public\Lotteries.DVS.AzureScripts\prod-qolgr\Storage_Blob_scripts_configuration\deployitems"
$scripts_dir = "C:\Users\Public\Lotteries.DVS.AzureScripts\prod-qolgr\Storage_Blob_scripts_configuration\scripts"

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

# upload contents of $scripts_dir to scripts
$containerNames = @("scripts", "deployitems", "certsprod");
if($containerNames.length) {
    foreach($containerName in $containerNames) {
        $container = Get-AzureStorageContainer -Name $containerName -Context $blobstorageContext_olgrscripts
        $container.CloudBlobContainer.Uri.AbsoluteUri
        
        if ($container) {
            $fileToUpload = Get-ChildItem $scripts_dir -Recurse -File
            
            foreach ($x in $fileToUpload) {
                $sourceFileRootDirectory = $scripts_dir
                
                $targetPath = ($x.fullname.Substring($sourceFileRootDirectory.Length + 1)).Replace("\", "/")
                
                Write-Host "Uploading $("\" + $x.fullname.Substring($sourceFileRootDirectory.Length + 1)) to $($container.CloudBlobContainer.Uri.AbsoluteUri + "/" + $targetPath)"
                Set-AzureStorageBlobContent -File $x.fullname -Container $container.Name -Blob $targetPath -Context $blobstorageContext_olgrscripts -Force:$Force | Out-Null
            }
        }
    }
}
