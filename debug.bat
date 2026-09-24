@echo off
cd /d %~dp0
title JA_Route (Debug Mode)

echo ===============================================================================
echo   KHOI CHAY JA_ROUTE TRONG CHE DO DEBUG (-debug) VOI QUYEN ADMINISTRATOR
echo ===============================================================================
echo.

set EXE_PATH=

if exist "build\windows\x64\runner\Debug\ja_route.exe" (
    set "EXE_PATH=%~dp0build\windows\x64\runner\Debug\ja_route.exe"
) else if exist "build\windows\x64\runner\Release\ja_route.exe" (
    set "EXE_PATH=%~dp0build\windows\x64\runner\Release\ja_route.exe"
) else if exist "dist\ja_route.exe" (
    set "EXE_PATH=%~dp0dist\ja_route.exe"
) else (
    for %%i in (*.exe) do (
        set "EXE_PATH=%%~fi"
    )
)

if "%EXE_PATH%"=="" (
    echo [CANH BAO] Chua tim thay file ja_route.exe da bien dich!
    echo Vui long chay 'build.bat' hoac 'run.bat' de bien dich ung dung truoc khi chay che do debug.
    echo.
    pause
    exit /b 1
)

echo [+] Dang khoi chay: %EXE_PATH%
echo [+] Tham so: -debug
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%EXE_PATH%' -ArgumentList '-debug' -WorkingDirectory '%~dp0' -Verb RunAs"
if %ERRORLEVEL% neq 0 (
    echo.
    echo [Loi] Khong the khoi chay! Vui long dong y quyen UAC Administrator tren man hinh.
    pause
    exit /b 1
)

echo [OK] Ung dung da duoc khoi chay o che do Debug.
exit /b 0
