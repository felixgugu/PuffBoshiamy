@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo.
echo Installing PuffIME...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-package.ps1"
if errorlevel 1 (
    echo.
    echo Installation failed. Read the messages above.
) else (
    echo.
    echo Done. You can close this window.
)
echo.
pause >nul
