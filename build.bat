@echo off
setlocal
cd /d "%~dp0"
echo Building JA_Route without deleting runtime data or existing packages...
call flutter build windows --release
if errorlevel 1 exit /b %ERRORLEVEL%
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\package_windows.ps1"
if errorlevel 1 exit /b %ERRORLEVEL%
echo Package and SHA256SUMS.txt created in the new dist/package-* directory.
endlocal
