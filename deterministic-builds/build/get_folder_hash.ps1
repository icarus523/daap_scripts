<#
 .SYNOPSIS
    Generates a folder hash for all files in the specified folder

 .DESCRIPTION
    Writes the hashes of all files in the specified folder to a report and hashes the report to provide the final "folder hash"

 .PARAMETER folderToHash
    The path of the folder to be hashed
#>
param(
 [Parameter(Mandatory=$True)]
 [string]
 $folderToHash
)

$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

$reportFilePath = "c:\build\folder_hash_report_$((Get-Date).ToString("yyyyMMdd_HHmmss")).txt"
$hashes = @()
$files = Get-ChildItem -Path $folderToHash -Recurse -File

New-Item $reportFilePath -ItemType File -Force

foreach($file in $files) {
    if ($file.Extension -imatch "config") { continue; }
    $fileHash = (Get-FileHash -Algorithm SHA256 -Path $file.FullName).Hash
    $filePath = $file.FullName
    $hashes += "$fileHash $filePath"
}

$hashes | Out-File -FilePath $reportFilePath -Append -Force
$folderHash = (Get-FileHash -Algorithm SHA256 -Path $reportFilePath).Hash
Write-Output "Hash of folder report file: $folderHash"
&$reportFilePath 
