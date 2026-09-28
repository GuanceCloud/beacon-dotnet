@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0beacon-dotnet.ps1" %*
exit /b %ERRORLEVEL%
