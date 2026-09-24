@echo off
chcp 65001 >nul
setlocal EnableExtensions DisableDelayedExpansion
set "SILENT_MODE=0"
if /i "%~1"=="/silent" set "SILENT_MODE=1"
if /i "%~1"=="/s" set "SILENT_MODE=1"
title Cài đặt JA_Route - Windows Dual Network Route Fixer

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "SOURCE_DIR="
if exist "%SCRIPT_DIR%\ja_route.exe" (
    set "SOURCE_DIR=%SCRIPT_DIR%"
) else if exist "%SCRIPT_DIR%\build\windows\x64\runner\Release\ja_route.exe" (
    set "SOURCE_DIR=%SCRIPT_DIR%\build\windows\x64\runner\Release"
) else if exist "%SCRIPT_DIR%\dist\ja_route.exe" (
    set "SOURCE_DIR=%SCRIPT_DIR%\dist"
)

if not defined SOURCE_DIR (
    echo [ERROR] Khong tim thay file ja_route.exe de cai dat!
    if "%SILENT_MODE%"=="0" pause
    exit /b 1
)

set "TARGET_DIR=%LOCALAPPDATA%\Programs\JA_Route"
if /i "%SOURCE_DIR%"=="%TARGET_DIR%" (
    echo [WARNING] Thu muc nguon trung voi thu muc cai dat: %TARGET_DIR%
    exit /b 1
)

if not exist "%SOURCE_DIR%\flutter_windows.dll" (
    echo [ERROR] Thieu tap tin thu vien flutter_windows.dll!
    if "%SILENT_MODE%"=="0" pause
    exit /b 1
)
if not exist "%SOURCE_DIR%\data\app.so" (
    echo [ERROR] Thieu tap tin chuong trinh data\app.so!
    if "%SILENT_MODE%"=="0" pause
    exit /b 1
)

if "%SILENT_MODE%"=="0" (
    echo ===============================================================================
    echo   CAI DAT JA_ROUTE - WINDOWS DUAL NETWORK ROUTE FIXER
    echo ===============================================================================
    echo [+] Thu muc nguon   : %SOURCE_DIR%
    echo [+] Thu muc cai dat : %TARGET_DIR%
    echo.
)

:: Kiem tra neu tien trinh ja_route.exe dang chay trong thu muc dich
powershell -NoProfile -Command "$exe = Join-Path $env:TARGET_DIR 'ja_route.exe'; if (Get-Process ja_route -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe }) { exit 1 }"
if errorlevel 1 (
    echo [ERROR] JA_Route dang chay. Vui long dong ung dung truoc khi cai dat hoac cap nhat!
    if "%SILENT_MODE%"=="0" pause
    exit /b 1
)

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

:: Sao chep tap tin va bao toan du lieu nguoi dung (config, logs, history)
robocopy "%SOURCE_DIR%" "%TARGET_DIR%" /E /R:1 /W:1 /XD logs backups /XF update_config.json search_history.json config.json config.ini *.log *.key >nul
if exist "%SCRIPT_DIR%\uninstall.ps1" copy /y "%SCRIPT_DIR%\uninstall.ps1" "%TARGET_DIR%\uninstall.ps1" >nul
if exist "%SCRIPT_DIR%\uninstall.bat" copy /y "%SCRIPT_DIR%\uninstall.bat" "%TARGET_DIR%\uninstall.bat" >nul
if exist "%SCRIPT_DIR%\debug.bat" copy /y "%SCRIPT_DIR%\debug.bat" "%TARGET_DIR%\debug.bat" >nul

:: Copy default config neu chua co trong target dir
if not exist "%TARGET_DIR%\config.json" (
    if exist "%SOURCE_DIR%\config.json" copy /y "%SOURCE_DIR%\config.json" "%TARGET_DIR%\config.json" >nul
)

:: Tao shortcut Desktop va Start Menu
set "START_MENU_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\JA_Route"
if not exist "%START_MENU_DIR%" mkdir "%START_MENU_DIR%"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ws = New-Object -ComObject WScript.Shell; " ^
  "$exe = Join-Path $env:TARGET_DIR 'ja_route.exe'; " ^
  "$uninst = Join-Path $env:TARGET_DIR 'uninstall.bat'; " ^
  "$debug = Join-Path $env:TARGET_DIR 'debug.bat'; " ^
  "$d = $ws.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) 'JA_Route.lnk')); " ^
  "$d.TargetPath = $exe; $d.WorkingDirectory = $env:TARGET_DIR; $d.IconLocation = $exe + ',0'; $d.Save(); " ^
  "$m = $ws.CreateShortcut((Join-Path $env:START_MENU_DIR 'JA_Route.lnk')); " ^
  "$m.TargetPath = $exe; $m.WorkingDirectory = $env:TARGET_DIR; $m.IconLocation = $exe + ',0'; $m.Save(); " ^
  "$dbg = $ws.CreateShortcut((Join-Path $env:START_MENU_DIR 'JA_Route (Debug Mode).lnk')); " ^
  "$dbg.TargetPath = 'cmd.exe'; $dbg.Arguments = '/c ' + [char]34 + [char]34 + $debug + [char]34 + [char]34; " ^
  "$dbg.WorkingDirectory = $env:TARGET_DIR; $dbg.IconLocation = $exe + ',0'; $dbg.Save(); " ^
  "$u = $ws.CreateShortcut((Join-Path $env:START_MENU_DIR 'Uninstall JA_Route.lnk')); " ^
  "$u.TargetPath = 'cmd.exe'; $u.Arguments = '/c ' + [char]34 + [char]34 + $uninst + [char]34 + [char]34; " ^
  "$u.WorkingDirectory = $env:TARGET_DIR; $u.IconLocation = [System.IO.Path]::Combine($env:SystemRoot, 'System32', 'shell32.dll') + ',-240'; $u.Save();"

:: Dang ky Control Panel Add/Remove Programs (HKCU khong can Admin)
set "REG_KEY=HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\JA_Route"
reg add "%REG_KEY%" /v "DisplayName" /t REG_SZ /d "JA_Route" /f >nul
reg add "%REG_KEY%" /v "DisplayVersion" /t REG_SZ /d "1.1.0" /f >nul
reg add "%REG_KEY%" /v "Publisher" /t REG_SZ /d "JA Tech" /f >nul
reg add "%REG_KEY%" /v "DisplayIcon" /t REG_SZ /d "%TARGET_DIR%\ja_route.exe,0" /f >nul
reg add "%REG_KEY%" /v "InstallLocation" /t REG_SZ /d "%TARGET_DIR%" /f >nul
reg add "%REG_KEY%" /v "NoModify" /t REG_DWORD /d 1 /f >nul
reg add "%REG_KEY%" /v "NoRepair" /t REG_DWORD /d 1 /f >nul

powershell -NoProfile -Command "$key='HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\JA_Route'; $q=[char]34; $bat=Join-Path $env:TARGET_DIR 'uninstall.bat'; Set-ItemProperty $key UninstallString ('cmd.exe /c '+$q+$q+$bat+$q+$q); Set-ItemProperty $key QuietUninstallString ('cmd.exe /c '+$q+$q+$bat+$q+' /silent'+$q)" >nul 2>&1

if "%SILENT_MODE%"=="0" (
    echo.
    echo ===============================================================================
    echo   [SUCCESS] CAI DAT JA_ROUTE THANH CONG!
    echo   - Shortcut Desktop    : Desktop\JA_Route.lnk
    echo   - Shortcut Start Menu : Start Menu\Programs\JA_Route\
    echo   - Control Panel       : Da dang ky Uninstall trong Programs and Features
    echo ===============================================================================
    echo.
    pause
)
exit /b 0
