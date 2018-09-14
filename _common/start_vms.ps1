<#
 .SYNOPSIS
    Starts Azure VMs (if not already started)

 .PARAMETER vmNames
    The list of vm names to be started.
#>

param(
 [Parameter(Mandatory=$True)]
 [string[]]
 $vmNames
)

$ErrorActionPreference = "Stop"

Write-Host "Getting list of vms from azure..."
$vms = Get-AzureRmVM
if ($vms.Count -eq 0) {
	Write-Host "No VMs found"
	exit
}

Write-Host "Parsing deallocated vms..."
$deallocatedVms = @()
$vms | Select-String -Pattern "VM Deallocated" | ForEach {
	$splitValues = $_.Line.split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)
	
	if ($vmNames -notcontains $splitValues[2]) {return} # return in a foreach is actually a continue (wtf?)
	
	$deallocatedVm = New-Object -TypeName PSObject
	$deallocatedVm | Add-Member -Name 'ResourceGroup' -MemberType Noteproperty -Value $splitValues[1]
	$deallocatedVm | Add-Member -Name 'VMname' -MemberType Noteproperty -Value $splitValues[2]
	$deallocatedVms += $deallocatedVm
}

Write-Host
if ($deallocatedVms.Count -eq 0) {	
	Write-Host "All VMs already online"
}
else{
	ForEach	($offlineVm in $deallocatedVms) {	
		Write-Host "Starting VM $offlineVm"
		Start-AzureRmVM -ResourceGroupName $offlineVm.ResourceGroup -Name $offlineVm.VMname
	}
}