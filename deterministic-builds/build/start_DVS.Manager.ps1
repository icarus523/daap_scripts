$transcriptFile = "c:\build\build_transcript__DVSManager_$((Get-Date).ToString("yyyyMMdd_HHmmss")).txt"

Start-Transcript $transcriptFile -IncludeInvocationHeader
try {
    .\deterministic_build.ps1 -BinariesZipFileName DVS.Manager.zip -SolutionFileName DVS.Manager.sln -RelativeBinReleasePath Dvs.Manager\bin\Release -BuildType msbuild
}
finally {
    Stop-Transcript #finally block will still run even when ctrl+c is hit... but not if the window is closed by the user :(
}

&$transcriptFile