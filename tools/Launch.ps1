param(
    [switch]$CheckOnly,
    [string]$Batch,
    [string]$LogFile
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$command = Get-Command matlab.exe -ErrorAction SilentlyContinue
if ($command) {
    $matlabExecutable = $command.Source
} else {
    $matlabExecutable = Get-ChildItem -Path "$env:ProgramFiles\MATLAB\*\bin\matlab.exe" -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $matlabExecutable) {
    if ($CheckOnly -or $Batch) { throw 'MATLAB is not found.' }
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show('MATLAB is not found. Open launch_app.m in MATLAB and press Run.','RocketLab')
    exit 1
}
# R2026b does not ship Java. Keep any explicit user setting; otherwise reuse an
# installed MATLAB JRE for this child process. No machine/user settings change.
if (-not $env:MATLAB_JAVA -and -not $env:JAVA_HOME -and -not (Get-Command java.exe -ErrorAction SilentlyContinue)) {
    $javaRuntime = Get-ChildItem -Path "$env:ProgramFiles\MATLAB\*\sys\java\jre\win64\jre" -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'bin\server\jvm.dll') } |
        Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
    if ($javaRuntime) { $env:MATLAB_JAVA = $javaRuntime }
}
if ($CheckOnly) {
    [pscustomobject]@{Matlab=$matlabExecutable; Java=$env:MATLAB_JAVA; Project=$projectRoot} | ConvertTo-Json
    exit 0
}
$arguments = @('-sd', ('"' + $projectRoot + '"'))
if ($LogFile) {
    $arguments += @('-logfile', ('"' + $LogFile + '"'))
}
if ($Batch) {
    $arguments += @('-batch', ('"' + $Batch + '"'))
    $process = Start-Process -FilePath $matlabExecutable -WorkingDirectory $projectRoot -WindowStyle Hidden -ArgumentList $arguments -PassThru -Wait
    exit $process.ExitCode
}
$arguments += @('-r', '"launch_app;"')
Start-Process -FilePath $matlabExecutable -WorkingDirectory $projectRoot -WindowStyle Hidden -ArgumentList $arguments
