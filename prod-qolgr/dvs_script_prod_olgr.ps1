<#
.Synopsis
  Windows setup script for the Dvs.Server VM
#>

<#
.Synopsis
  Grant logon as a service right to azureuser.
  Taken from: http://stackoverflow.com/a/21235462/2631967

  This is required so the Dvs.Server app can run under the service account.
#>
function SetRunAsServiceRights([string] $username) {
	$tempPath = [System.IO.Path]::GetTempPath()
	$import = Join-Path -Path $tempPath -ChildPath "import.inf"
	if(Test-Path $import) { Remove-Item -Path $import -Force }
	$export = Join-Path -Path $tempPath -ChildPath "export.inf"
	if(Test-Path $export) { Remove-Item -Path $export -Force }
	$secedt = Join-Path -Path $tempPath -ChildPath "secedt.sdb"
	if(Test-Path $secedt) { Remove-Item -Path $secedt -Force }

	try {
		Write-Host ("Granting SeServiceLogonRight to user account: {0}." -f $username)
		$sid = ((New-Object System.Security.Principal.NTAccount($username)).Translate([System.Security.Principal.SecurityIdentifier])).Value
		secedit /export /cfg $export
		$sids = (Select-String $export -Pattern "SeServiceLogonRight").Line
		foreach ($line in @("[Unicode]", "Unicode=yes", "[System Access]", "[Event Audit]", "[Registry Values]", "[Version]", "signature=`"`$CHICAGO$`"", "Revision=1", "[Profile Description]", "Description=GrantLogOnAsAService security template", "[Privilege Rights]", "SeServiceLogonRight = *$sids,*$sid")){
		  Add-Content $import $line
		}
		secedit /import /db $secedt /cfg $import
		secedit /configure /db $secedt
		gpupdate /force
		Remove-Item -Path $import -Force
		Remove-Item -Path $export -Force
		Remove-Item -Path $secedt -Force
	} catch {
		Write-Host ("Failed to grant SeServiceLogonRight to user account: {0}." -f $username)
		$error[0]
	}
}

<#
.Synopsis
  JA This function is used to verify the hash of downloaded programs against known hashes.
#>
function VerifyFileHash([string] $FileName, [string] $ExpectedFileHash) {
    $FilePath = $FileName
    Write-Output "Verifying hash..."
    if (!(Test-Path $FilePath)) { 
        throw "No file found matching name $FileName" 
    }
    $FileHash = (Get-FileHash $FilePath -Algorithm SHA256).Hash

    if ($ExpectedFileHash -ine $FileHash) {
        throw "Hash mismatch on file, check you have the correct file name and that the provided hash is valid
        Expected Hash: $ExpectedFileHash
        Actual Hash: $FileHash"
    }

    Write-Output "$FileName hash matches: $FileHash"​​
}


$transcriptFile = "c:\Logs\customscript_transcript_$((Get-Date).ToString("yyyyMMdd_HHmmss")).txt"
New-Item -ItemType Directory -Force -Path c:\Logs
Start-Transcript $transcriptFile -IncludeInvocationHeader

try {
    $localTmpDir = "C:\tmp"
    mkdir $localTmpDir
    
    # This approach is a lot faster than installing the module from the powershell gallery
    Write-Host "Downloading and installing AzureRM msi..."
    $powershellMsiWebUrl = 'https://github.com/Azure/azure-powershell/releases/download/v6.0.1-May2018/Azure-Cmdlets-6.0.1.19644-x64.msi'
    $powershellMsiPath = "$localTmpDir\azurerm.msi"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    (New-Object System.Net.WebClient).DownloadFile($powershellMsiWebUrl, $powershellMsiPath)
    
    VerifyFileHash "$localTmpDir\azurerm.msi" "4FF5A84A6F68A41DC0BDD2F64454794E81306748F6CDF04A90F9484BEF14786C"

    Start-Process msiexec.exe -Wait -ArgumentList "/I $powershellMsiPath /quiet"
    
    if (-not (Get-Module AzureRM)) {
        Import-Module AzureRM
    }
    
    Write-Host "AzureRM modules imported"

    # Must be disabled to prevent prompts during script run; is also unnecessary for us
    Disable-AzureRmDataCollection

    # Define account storage access
    $storageAccountName = "olgrscripts"
    $storageAccountKey = "aCZ6A1ivWjWyLSzkbysQi6nlYpypQglCRe5FnLIghaP6z/kGG8Cpal82P5l74GJrq3ll9LG1KoDAVsnQ9CHWEg=="
    $ctx = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
    $deployItemsContainerName = "deployitems"
    $certsContainerName  = "certsprod"
    $dvsServiceAccountUsername = "$env:COMPUTERNAME\azureuser"
    $dvsServiceAccountPassword = "1234567890abcd!"    

    # Import RNG device certs into trusted root store
    Write-Host "Installing certificates from container $certsContainerName to trusted root"
    $certBlobs = Get-AzureStorageBlob -Container $certsContainerName -Context $ctx
    foreach ($certBlob in $certBlobs) {
        $certName = $certBlob.Name
        Write-Host "Downloading and installing cert $certName"
        Get-AzureStorageBlobContent -Blob $certName -Container $certsContainerName -Context $ctx -Destination $localTmpDir -Force
        (Get-ChildItem -Path "$localTmpDir\$certName") | Import-Certificate -CertStoreLocation cert:\LocalMachine\Root
        (Get-ChildItem -Path "$localTmpDir\$certName") | Import-Certificate -CertStoreLocation cert:\LocalMachine\My # DVS looks up the olgr public cert from My rather than Root
    }
    Write-Host "Trusted root certificates installed"

    # Import DVS.Server private key
    $privateKeyContainer = "scripts"
    $privateKeyCert = "dvs_certificate.pfx" # case sensitive
    $certPassword = "pelikan"

    Write-Host "Installing DVS.Server private key..."
    Get-AzureStorageBlobContent -Blob $privateKeyCert -Container $privateKeyContainer -Context $ctx -Destination $localTmpDir -Force
    # We need to install the cert using the .NET approach otherwise we have no way to set ACLs on the private key after import...
    $certs = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection;
    $certs.Import("$localTmpDir\$privateKeyCert", $certPassword, "Exportable,MachineKeySet,PersistKeySet");

    foreach ($cert in $certs) {
        $store = new-object System.Security.Cryptography.X509Certificates.X509Store("My","LocalMachine")
        $store.open("MaxAllowed")
        $store.add($cert)
        $store.close()
        
        $store = new-object System.Security.Cryptography.X509Certificates.X509Store("Root","LocalMachine")
        $store.open("MaxAllowed")
        $store.add($cert)
        $store.close()
    }

    Write-Host "DVS.Server private key installed"

    Write-Host "OLGR public cert installed"
    # Install/configure DVS
    $dvsZipFileName = "DVS.Server.zip" # case sensitive
    $dvsInstallPath = "C:\DVS.Server\"

    Write-Host "Installing DVS.Server..."
    SetRunAsServiceRights $dvsServiceAccountUsername
    Get-AzureStorageBlobContent -Blob $dvsZipFileName -Container $deployItemsContainerName -Context $ctx -Destination $localTmpDir
    Expand-Archive "$localTmpDir\$dvsZipFileName" -DestinationPath $dvsInstallPath
    cd $dvsInstallPath
    cd "DVS.Server\Release"
    .\DVS.Server.exe install -username:$dvsServiceAccountUsername -password:$dvsServiceAccountPassword
    Start-Service "DVS Server"
    Write-Host "DVS.Server installed and started"
  
    # Install & Configure OMS (run these last because some MSIs install in the background after starting the setup process)
    Write-Host "Installing OMS component..."
    Get-AzureStorageBlobContent -Blob "MMASetup-AMD64.exe" -Container $deployItemsContainerName -Context $ctx -Destination $localTmpDir
    cd $localTmpDir
    VerifyFileHash "$localTmpDir\MMASetup-AMD64.exe" "E6100B7EE0545C45EA8D867C4A7F4F9D1B84BAF24550F757DE218970E2449FAE"
    
    .\MMASetup-AMD64.exe /C:"setup.exe /qn ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_ID=757ad048-0ed4-4b75-9368-01523571f1eb OPINSIGHTS_WORKSPACE_KEY=Umt76yn53pg0Yu1DPkinY74sLZCxzfDUKTRJEFD+/Ob5ef5Z7RRfmGww6QJ1K2Iyor2mLxZ7REUvL2auaB1IdQ== AcceptEndUserLicenseAgreement=1"

    Write-Host "Completed successfully"
}
finally {
    Stop-Transcript
}