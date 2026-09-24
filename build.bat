@echo off
setlocal enabledelayedexpansion
title Build Release Packager - JA_Route

set WORKSPACE_DIR=%~dp0
cd /d "%WORKSPACE_DIR%"

set APP_NAME=ja_route
set APP_TITLE=JA_Route
set APP_VERSION=1.2.0

echo ===============================================================================
echo   BAT DAU QUY TRINH BIEN DICH VA DONG GOI RELEASE CHO %APP_TITLE% v%APP_VERSION%
echo ===============================================================================
echo.

:: 1. Terminate the Running Application
echo [1/5] Terminating any active %APP_NAME%.exe instances...
taskkill /IM %APP_NAME%.exe /F 2>nul
ping 127.0.0.1 -n 2 >nul

:: 2. Clean temporary build cache safely without flutter clean
echo [2/5] Cleaning temporary build cache...
if exist windows\flutter\ephemeral rmdir /s /q windows\flutter\ephemeral

:: 3. Compile the Release Build
echo [3/5] Compiling Windows desktop application (Release mode)...
call flutter build windows --release
if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Flutter build windows failed with exit code %ERRORLEVEL%!
    pause
    exit /b %ERRORLEVEL%
)

set REL=build\windows\x64\runner\Release

:: 4. Clean runtime residue from Release before copying accessories
echo [4/5] Bundling embedded assets, i18n, documentation, and debug.bat...
if exist "%REL%\config.ini" del /f /q "%REL%\config.ini"
if exist "%REL%\*.log" del /f /q "%REL%\*.log"
if exist "%REL%\debug_theme.txt" del /f /q "%REL%\debug_theme.txt"
if exist "%REL%\ja_route_config_*.json" del /f /q "%REL%\ja_route_config_*.json"
if exist "%REL%\logs" rmdir /s /q "%REL%\logs"
if exist "%REL%\backups" rmdir /s /q "%REL%\backups"

:: Copy accessories
if exist bin xcopy /e /i /y /q bin "%REL%\bin\"
if exist assets xcopy /e /i /y /q assets "%REL%\assets\"
if exist i18n xcopy /e /i /y /q i18n "%REL%\i18n\"
if exist ABOUT.txt copy /y ABOUT.txt "%REL%\" >nul
if exist README.md copy /y README.md "%REL%\" >nul
if exist CHANGELOG.md copy /y CHANGELOG.md "%REL%\" >nul
if exist LICENSE copy /y LICENSE "%REL%\" >nul
if exist install.bat copy /y install.bat "%REL%\" >nul
if exist uninstall.bat copy /y uninstall.bat "%REL%\" >nul
if exist uninstall.ps1 copy /y uninstall.ps1 "%REL%\" >nul

:: Create standard debug.bat inside Release directory with self-elevation (RunAs) and -debug
(
    echo @echo off
    echo cd /d %%~dp0
    echo for %%%%i in (*.exe^) do ^(
    echo     powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%%%%~fi' -ArgumentList '-debug' -Verb RunAs"
    echo     exit /b
    echo ^)
) > "%REL%\debug.bat"

:: Create .Release.lnk shortcut in workspace root pointing to Release directory
powershell -NoProfile -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%WORKSPACE_DIR%\.Release.lnk'); $Shortcut.TargetPath = '%WORKSPACE_DIR%\%REL%'; $Shortcut.Save()"

:: 5. Package into dist/ with parent folder ZIP
echo [5/5] Packaging standalone Windows x64 ZIP wrapped in parent folder...
if exist "dist" rmdir /s /q "dist"
mkdir "dist"
xcopy /e /i /y /q "%REL%\*.*" "dist\"

set DIST_PACK_DIR=dist_pack\%APP_TITLE%_v%APP_VERSION%_Windows_x64
if exist "dist_pack" rmdir /s /q "dist_pack"
mkdir "%DIST_PACK_DIR%"
xcopy /e /i /y /q "dist\*.*" "%DIST_PACK_DIR%\"
powershell -NoProfile -Command "Compress-Archive -Path 'dist_pack\*' -DestinationPath 'dist\%APP_TITLE%_v%APP_VERSION%_Windows_x64.zip' -Force"
if exist "dist_pack" rmdir /s /q "dist_pack"

echo.
echo ===============================================================================
echo   [SUCCESS] BUILD VA DONG GOI HOAN TAT!
echo   - Thu muc Release : %REL%
echo   - Shortcut        : .Release.lnk
echo   - Thu muc dist    : dist\
echo   - File ZIP        : dist\%APP_TITLE%_v%APP_VERSION%_Windows_x64.zip
echo   - Debug launcher  : dist\debug.bat
echo   - Installer suite : dist\install.bat ^& uninstall.bat
echo ===============================================================================
echo.
pause
