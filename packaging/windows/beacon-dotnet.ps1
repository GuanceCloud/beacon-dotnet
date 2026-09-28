#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "help",
    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArguments
)

$ErrorActionPreference = "Stop"
$ServiceLocatorVariable = "OTEL_DOTNET_AUTO_INSTALL_DIR"
$ProductRegistryPath = "HKLM:\SOFTWARE\Beacon Observability\Beacon .NET"

function Show-Usage() {
    @"
Usage: beacon-dotnet <command> [arguments]

Commands:
  status                 Show installation status and version.
  version                Print the installed Beacon .NET version.
  run <command> [args]   Run an application with automatic instrumentation.
  uninstall              Remove Beacon .NET through Windows Installer.
  help                   Show this help text.
"@
}

function Get-InstallDirectory() {
    $installDir = [System.Environment]::GetEnvironmentVariable($ServiceLocatorVariable, [System.EnvironmentVariableTarget]::Machine)
    if (-not $installDir) {
        $installDir = $PSScriptRoot
    }

    return $installDir.TrimEnd("\")
}

function Get-InstalledMetadata() {
    $metadataPath = Join-Path (Get-InstallDirectory) "BEACON-METADATA.json"
    if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
        throw "Beacon .NET is not installed."
    }

    return Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
}

function Enable-CurrentProcessInstrumentation([string]$InstallDir) {
    $nativeX86 = Join-Path $InstallDir "win-x86\OpenTelemetry.AutoInstrumentation.Native.dll"
    $nativeX64 = Join-Path $InstallDir "win-x64\OpenTelemetry.AutoInstrumentation.Native.dll"

    $env:COR_ENABLE_PROFILING = "1"
    $env:COR_PROFILER = "{918728DD-259F-4A6A-AC2B-B85E1B658318}"
    $env:COR_PROFILER_PATH_32 = $nativeX86
    $env:COR_PROFILER_PATH_64 = $nativeX64
    $env:CORECLR_ENABLE_PROFILING = "1"
    $env:CORECLR_PROFILER = "{918728DD-259F-4A6A-AC2B-B85E1B658318}"
    $env:CORECLR_PROFILER_PATH_32 = $nativeX86
    $env:CORECLR_PROFILER_PATH_64 = $nativeX64
    $env:ASPNETCORE_HOSTINGSTARTUPASSEMBLIES = "OpenTelemetry.AutoInstrumentation.AspNetCoreBootstrapper"
    $env:DOTNET_STARTUP_HOOKS = Join-Path $InstallDir "net\OpenTelemetry.AutoInstrumentation.StartupHook.dll"
    $env:OTEL_DOTNET_AUTO_HOME = $InstallDir
}

function Test-IsAdministrator() {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Uninstall() {
    if (-not (Test-IsAdministrator)) {
        $arguments = @(
            "-NoLogo",
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-File", "`"$PSCommandPath`"",
            "uninstall"
        )
        $process = Start-Process powershell.exe -Verb RunAs -Wait -PassThru -ArgumentList $arguments
        exit $process.ExitCode
    }

    $productCode = (Get-ItemProperty -LiteralPath $ProductRegistryPath -Name ProductCode -ErrorAction Stop).ProductCode
    $process = Start-Process msiexec.exe -Wait -PassThru -ArgumentList @(
        "/x", $productCode, "/passive", "/norestart"
    )
    if ($process.ExitCode -ne 0) {
        throw "Windows Installer failed with exit code $($process.ExitCode)."
    }
}

switch ($Command.ToLowerInvariant()) {
    "status" {
        $metadata = Get-InstalledMetadata
        Write-Output "Status: installed"
        Write-Output "Version: $($metadata.version)"
        Write-Output "Directory: $(Get-InstallDirectory)"
        Write-Output "Package: msi"
    }
    "version" {
        $metadata = Get-InstalledMetadata
        Write-Output $metadata.version
    }
    "--version" {
        $metadata = Get-InstalledMetadata
        Write-Output $metadata.version
    }
    "-v" {
        $metadata = Get-InstalledMetadata
        Write-Output $metadata.version
    }
    "run" {
        if (-not $RemainingArguments -or $RemainingArguments.Count -eq 0) {
            throw "run requires an application command."
        }

        $installDir = Get-InstallDirectory
        [void](Get-InstalledMetadata)
        Enable-CurrentProcessInstrumentation -InstallDir $installDir
        $application = $RemainingArguments[0]
        $applicationArguments = @($RemainingArguments | Select-Object -Skip 1)
        & $application @applicationArguments
        exit $LASTEXITCODE
    }
    "uninstall" {
        Invoke-Uninstall
    }
    { $_ -in @("help", "--help", "-h") } {
        Show-Usage
    }
    default {
        Show-Usage | Write-Error
        exit 2
    }
}
