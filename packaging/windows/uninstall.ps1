#Requires -Version 5.1

& (Join-Path $PSScriptRoot "beacon-dotnet.ps1") uninstall
exit $LASTEXITCODE
