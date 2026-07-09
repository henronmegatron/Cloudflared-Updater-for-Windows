# cloudflared Windows Updater

A simple Windows batch script for updating `cloudflared` on Windows.

The script first attempts to update `cloudflared` using its built-in self-update command. If that fails, it falls back to upgrading via `winget`. After updating, it checks whether a Windows service named `cloudflared` exists and restarts it.

## What it does

* Checks that the script is being run as Administrator
* Displays the currently installed `cloudflared` version
* Attempts to run:

```bat
cloudflared update
```

* Falls back to `winget` if the self-update does not complete successfully
* Restarts the `cloudflared` Windows service if one is found
* Displays the updated `cloudflared` version

## Requirements

* Windows
* Administrator permissions
* `cloudflared` installed and available in PATH
* `winget` installed for fallback updates

`winget` is normally included with modern versions of Windows 10 and Windows 11 through App Installer.

## Usage

1. Download or clone this repository.
2. Save the script as something like:

```text
update-cloudflared.bat
```

3. Right-click the file.
4. Select **Run as administrator**.
5. Follow the output in the command window.

## Example output

```text
==================================================
 cloudflared updater for Windows
==================================================

Checking current cloudflared version...
cloudflared version 2026.6.1

Attempting cloudflared self-update...
cloudflared has been updated to version 2026.7.1

Checking for cloudflared Windows service...
Restarting cloudflared service...

Updated cloudflared version:
cloudflared version 2026.7.1

Done.
```

## Notes

The script uses this update order:

1. `cloudflared update`
2. `winget upgrade --id Cloudflare.cloudflared`

This is useful because `cloudflared update` may not always behave consistently on Windows, especially depending on how `cloudflared` was originally installed.

If the self-update command fails, the script automatically tries the official `winget` package instead.

## Windows service behaviour

The script checks for a service named:

```text
cloudflared
```

If found, it restarts the service using:

```bat
net stop cloudflared
net start cloudflared
```

If your Cloudflare Tunnel service uses a different service name, the script will search for services containing `cloudflared` and ask you to restart the correct service manually.

## Script

```bat
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
```

## Disclaimer

Use at your own risk. This script modifies the installed `cloudflared` version and restarts the Cloudflare Tunnel service if present.

It is intended for personal or administrative use on Windows machines where you understand how `cloudflared` is installed and used.
