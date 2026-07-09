@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Update cloudflared

echo ==================================================
echo  cloudflared updater for Windows
echo ==================================================
echo.

REM Check for administrator rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Please right-click this file and choose "Run as administrator".
    echo.
    pause
    exit /b 1
)

echo Checking current cloudflared version...
where cloudflared >nul 2>&1
if %errorlevel% equ 0 (
    cloudflared --version
) else (
    echo cloudflared was not found in PATH.
)
echo.

echo Attempting cloudflared self-update...
where cloudflared >nul 2>&1
if %errorlevel% equ 0 (
    cloudflared update
    set "UPDATE_RESULT=!errorlevel!"
) else (
    set "UPDATE_RESULT=1"
)

if not "!UPDATE_RESULT!"=="0" (
    echo.
    echo Self-update did not complete successfully.
    echo Trying winget upgrade instead...
    echo.

    where winget >nul 2>&1
    if %errorlevel% neq 0 (
        echo ERROR: winget is not installed or is not available in PATH.
        echo You may need to manually download the latest cloudflared installer/binary.
        echo.
        pause
        exit /b 1
    )

    winget upgrade --id Cloudflare.cloudflared --accept-package-agreements --accept-source-agreements
    if !errorlevel! neq 0 (
        echo.
        echo ERROR: winget upgrade failed.
        echo.
        pause
        exit /b 1
    )
)

echo.
echo Checking for cloudflared Windows service...
sc query cloudflared >nul 2>&1
if %errorlevel% equ 0 (
    echo Restarting cloudflared service...
    net stop cloudflared
    net start cloudflared
) else (
    echo No service named "cloudflared" was found.
    echo Searching for services containing "cloudflared":
    sc query type= service state= all | findstr /i cloudflared
    echo.
    echo If your service has a different name, restart it manually from Services.msc.
)

echo.
echo Updated cloudflared version:
where cloudflared >nul 2>&1
if %errorlevel% equ 0 (
    cloudflared --version
) else (
    echo cloudflared still not found in PATH.
)

echo.
echo Done.
pause
exit /b 0
