<#
 .SYNOPSIS
    Takes a .NET source code zip file and extracts/compiles/hash & zips binaries

 .PARAMETER  ZipFileName
    The name of the zip file containing the source code
 
 .PARAMETER  ExpectedZipFileHash
    The name of the zip file containing the source code

 .PARAMETER SolutionFileName
    The name of the solution file to be compiled

 .PARAMETER RelativeBinReleasePath
    The binaries output path of the solution that are to be hashed
    This path is relative to the extracted zip path e.g. if the zip file was named "Lotteries.DVS.Server-1.0.1234.zip" then this value will be relative to c:\build\Lotteries.DVS.Server-1.0.1193\
#>
param(
 [Parameter(Mandatory=$True)]
 [string]
 $ZipFileName,

 [Parameter(Mandatory=$True)]
 [string]
 $ExpectedZipFileHash,

 [Parameter(Mandatory=$True)]
 [string]
 $BinariesZipFileName,

 [Parameter(Mandatory=$True)]
 [string]
 $SolutionFileName,

 [Parameter(Mandatory=$True)]
 [string]
 $RelativeBinReleasePath,

 [Parameter()]
 [ValidateSet('dotnet','msbuild')]
 [string]
 $BuildType = 'dotnet'
)

$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"
function Write-Separator() { Write-Output "======================= $(Get-Date -Format s) =======================" }

# User variables
$rootPath = "C:\build"
$zipFilePath = "$rootPath\$ZipFileName"
$zipFileNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($ZipFileName)
$extractPath = "$rootPath\$zipFileNameNoExt"
$releaseBinariesPath = "$extractPath\$RelativeBinReleasePath"

# Print function input
Write-Separator
Write-Output "Provided function parameters"
Write-Output "ZipFileName: $ZipFileName"
Write-Output "ExpectedZipFileHash: $ExpectedZipFileHash"
Write-Output "SolutionFileName: $SolutionFileName"
Write-Output "RelativeBinReleasePath: $RelativeBinReleasePath"
Write-Separator

# Verify zip hash
Write-Output "Verifying zip hash..."
if (!(Test-Path $zipFilePath)) { 
    throw "No zip file found matching name $ZipFileName" 
}
$zipFileHash = (Get-FileHash $zipFilePath -Algorithm SHA256).Hash

if ($ExpectedZipFileHash -ine $zipFileHash) {
    throw "Hash mismatch on zip file, check you have the correct zip file name and that the provided hash is valid
    Expected Hash: $ExpectedZipFileHash
    Actual Hash: $zipFileHash"
}
Write-Output "Zip file hash matches"

# Extract
Write-Separator
Write-Output "Extracting zip file contents..."
if (Test-Path $extractPath) { 
    Remove-Item -Recurse -Force $extractPath # remove old path if it exists, allow for multiple re-runs
}
New-Item -ItemType Directory -Force -Path $rootPath
Expand-Archive $zipFilePath -DestinationPath $rootPath

# Compile
$solutionFilePath = "$extractPath\$SolutionFileName"
$nugetExePath = "$rootPath\nuget.exe"

Write-Separator
if (!(Test-Path $nugetExePath)) {
    $sourceNugetExe = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
    Write-Output "Downloading nuget.exe from $sourceNugetExe"
    Invoke-WebRequest $sourceNugetExe -OutFile $nugetExePath
}

Write-Output "Restoring packages for solution $solutionFilePath"
&$nugetExePath restore "$solutionFilePath"

Write-Separator
Write-Output "Compiling solution file $solutionFilePath"

if ($BuildType -eq 'msbuild') {
    #http://stackoverflow.com/a/2124759/2631967
    #Set environment variables for Visual Studio Command Prompt to get access to msbuild at command line
    pushd "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\Tools"
    cmd /c "VsDevCmd.bat&set" |
    foreach {
      if ($_ -match "=") {
        $v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
      }
    }
    popd
    Write-Host "`nVisual Studio 2017 Command Prompt variables set."
    
    msbuild "$solutionFilePath" /p:Configuration=Release
}
elseif ($BuildType -eq 'dotnet') {
    dotnet build "$solutionFilePath" -c Release
}
else { 
    throw "Unknown build type specified: $BuildType"
}

if (!(Test-Path $releaseBinariesPath)) { 
    throw "Unable to hash folder as it does not exist: $releaseBinariesPath" 
}

# Hash build output
Write-Separator
Write-Output "Producing hash report of release binaries folder $releaseBinariesPath"
.\get_folder_hash.ps1 "$releaseBinariesPath"

# Zip build output
Write-Separator
Write-Output "Zipping binary output from $releaseBinariesPath"

$binariesZipPath = "$rootPath\$BinariesZipFileName"
Compress-Archive -Path $releaseBinariesPath -DestinationPath $binariesZipPath -Force