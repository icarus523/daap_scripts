<#
.Synopsis
  Windows setup script for the Dvs.Server VM
#>
Install-PackageProvider -Name NuGet -Force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
if (-not (Get-Module -ListAvailable -Name AzureRM)) {
    Install-Module AzureRM
}

if (-not (Get-Module AzureRM)) {
    Import-Module AzureRM
}

Disable-AzureRmDataCollection

# Configure firewall rules
netsh advfirewall firewall add rule name="Allow Octopus Port 10933" dir=in action=allow protocol=TCP localport=10933
netsh advfirewall firewall add rule name="Allow RDP Port 3389" dir=in action=allow protocol=TCP localport=3389
netsh advfirewall firewall add rule name="Allow RDP Port 443" dir=in action=allow protocol=TCP localport=443

# Define account storage access
$storageAccountName = "tattsgroupscripts"
$storageAccountKey = "aDf7F5TPiMmm7DUIUDnmdDe+W74R+3Ew5IcBoDOWR/1bisgI6ZRWxkPiRyALZYydB5aKKtsdYFKV9O7aWXIirQ=="
$localTmpDir = "C:\tmp"
$scriptsContainer  = "scripts"
$deployItemsContainer  = "deployitems"
$ctx = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# Create tmp directory
mkdir $localTmpDir

# Import TattsRngCert
$rngCertsContainer = "certsdev"

# Import RNG device certs into trusted root store
Write-Host "Installing certificates from container $rngCertsContainer to trusted root"
$certBlobs = Get-AzureStorageBlob -Container $rngCertsContainer -Context $ctx
foreach ($certBlob in $certBlobs) {
    $certName = $certBlob.Name
    Write-Host "Downloading and installing cert $certName"
	Get-AzureStorageBlobContent -Blob $certName -Container $rngCertsContainer -Context $ctx -Destination $localTmpDir -Force
	(Get-ChildItem -Path "$localTmpDir\$certName") | Import-Certificate -CertStoreLocation cert:\LocalMachine\Root
}

# Install octopus tentacle
$tentacleMsi = "Octopus.Tentacle.3.12.4-x64.msi"
$source = "https://download.octopusdeploy.com/octopus/$tentacleMsi"
$destination = "$localTmpDir\$tentacleMsi"
Invoke-WebRequest $source -OutFile $destination
cd $localTmpDir
Start-Process -FilePath msiexec -ArgumentList /i, $tentacleMsi, /quiet -Wait

# Configure Octopus
cd "C:\Program Files\Octopus Deploy\Tentacle"
.\Tentacle.exe create-instance --instance "Tentacle" --config "C:\Octopus\Tentacle.config" --console
.\Tentacle.exe new-certificate --instance "Tentacle" --if-blank --console
.\Tentacle.exe configure --instance "Tentacle" --reset-trust --console
.\Tentacle.exe configure --instance "Tentacle" --home "C:\Octopus" --app "C:\Octopus\Applications" --port "10933" --noListen "False" --console
.\Tentacle.exe configure --instance "Tentacle" --trust "1B41EF0234A549DC1C9E107B5C180DABFBF8745D" --console
.\Tentacle.exe service --instance "Tentacle" --install --start --console

# Configure OMS (run these last because some MSIs install in the background after starting the setup process)
$blobName = "MMASetup-AMD64.exe"
Get-AzureStorageBlobContent -Blob $blobName -Container $deployItemsContainer -Destination $localTmpDir -Context $ctx
cd $localTmpDir
.\MMASetup-AMD64.exe /C:"setup.exe /qn ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_ID=757ad048-0ed4-4b75-9368-01523571f1eb OPINSIGHTS_WORKSPACE_KEY=Umt76yn53pg0Yu1DPkinY74sLZCxzfDUKTRJEFD+/Ob5ef5Z7RRfmGww6QJ1K2Iyor2mLxZ7REUvL2auaB1IdQ== AcceptEndUserLicenseAgreement=1"

<#
.Synopsis
  Grant logon as a service right to azureuser.
  Taken from: http://stackoverflow.com/a/21235462/2631967

  This is required so the Dvs.Server app can run under the service account.
#>
$username = "$env:COMPUTERNAME\azureuser"

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
