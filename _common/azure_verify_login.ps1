# sign in if necessary
$loginRequired = $true
Try {
  Write-Host "Checking if already logged in session..."
  if (-Not [string]::IsNullOrEmpty($(Get-AzureRmContext).Account)) { 
	$loginRequired = $false 
	Write-Host "Existing session found"
  }
} Catch { }

if ($loginRequired) {
  Write-Host "No existing session found, logging in...";
  Login-AzureRmAccount;
}