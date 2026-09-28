#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputDirectory,
    [Parameter(Mandatory = $true)]
    [string]$ModulePath,
    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory
)

$ErrorActionPreference = "Stop"
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$inputDirectory = (Resolve-Path $InputDirectory).Path
$modulePath = (Resolve-Path $ModulePath).Path
$versionLine = Get-Content (Join-Path $repositoryRoot "beacon\version.properties") |
    Where-Object { $_.StartsWith("beacon.version=") }
if ($versionLine.Count -ne 1) {
    throw "Expected exactly one beacon.version entry."
}
$version = $versionLine.Substring("beacon.version=".Length)
if ($version -notmatch '^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$') {
    throw "Invalid Beacon version '$version'."
}
$msiVersion = ($version -split '-', 2)[0]

$requiredFiles = @(
    "LICENSE",
    "BEACON-METADATA.json",
    "net\OpenTelemetry.AutoInstrumentation.StartupHook.dll",
    "win-x64\OpenTelemetry.AutoInstrumentation.Native.dll"
)
foreach ($relativePath in $requiredFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $inputDirectory $relativePath) -PathType Leaf)) {
        throw "Input directory is missing '$relativePath'."
    }
}

$stagingDirectory = Join-Path ([System.IO.Path]::GetTempPath()) "beacon-dotnet-msi-$([guid]::NewGuid().ToString('N'))"
$payloadDirectory = Join-Path $stagingDirectory "payload"
$buildDirectory = Join-Path $stagingDirectory "build"
New-Item -ItemType Directory -Path $payloadDirectory, $buildDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$outputDirectory = (Resolve-Path $OutputDirectory).Path

try {
    Copy-Item -Path (Join-Path $inputDirectory "*") -Destination $payloadDirectory -Recurse -Force
    Copy-Item -LiteralPath $modulePath -Destination (Join-Path $payloadDirectory "OpenTelemetry.DotNet.Auto.psm1") -Force
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "beacon-dotnet.cmd") -Destination $payloadDirectory -Force
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "beacon-dotnet.ps1") -Destination $payloadDirectory -Force
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "uninstall.ps1") -Destination $payloadDirectory -Force

    dotnet build (Join-Path $PSScriptRoot "Beacon.DotNet.Installer.wixproj") `
        --configuration Release `
        --output $buildDirectory `
        -p:PayloadDir=$payloadDirectory `
        -p:ProductVersion=$msiVersion `
        -p:PackageVersion=$version
    if ($LASTEXITCODE -ne 0) {
        throw "WiX build failed with exit code $LASTEXITCODE."
    }

    $msiFiles = @(Get-ChildItem -Path $buildDirectory -Filter "*.msi" -File)
    if ($msiFiles.Count -ne 1) {
        throw "Expected exactly one MSI, found $($msiFiles.Count)."
    }
    $msi = $msiFiles[0]
    $destination = Join-Path $outputDirectory $msi.Name
    Copy-Item -LiteralPath $msi.FullName -Destination $destination -Force
    Write-Output $destination
}
finally {
    if (Test-Path -LiteralPath $stagingDirectory) {
        Remove-Item -LiteralPath $stagingDirectory -Recurse -Force
    }
}
