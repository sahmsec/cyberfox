@echo off
Title Cyberfox Secure Setup
setlocal enabledelayedexpansion

:: Configuration
set "bat_dir=%~dp0"
set "folder=%bat_dir%AWS\Cyberfox Portable"
set "winrar_url=https://www.win-rar.com/fileadmin/winrar-versions/winrar/winrar-x64-624.exe"
set "winrar_installer=!folder!\WinRAR-free.exe"
set "cyberfox_url=https://github.com/sahmsec/Cyberfox/releases/download/v1.0/CyberfoxPortable.zip"
set "cyberfox_zip=!folder!\CyberfoxPortable.zip"
set "password=aws"

:: Header
echo =============================================
echo Cyberfox Secure Environment Setup
echo =============================================
echo.

:: Check admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [STEP] Requesting administrative privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~dpnx0\"' -Verb RunAs"
    exit /b
)

:: User confirmation
choice /c yn /n /m "This will create secure workspace and download Cyberfox. Continue? (Y/N)"
if %errorlevel% equ 2 (
    exit /b
)

:: Create workspace folder
if not exist "!folder!\" (
    mkdir "!folder!"
    echo [SUCCESS] Created workspace: !folder!
) else (
    echo [INFO] Workspace already exists: !folder!
)

:: Download Cyberfox ZIP
echo [STEP] Downloading Cyberfox package...
powershell -Command "Invoke-WebRequest -Uri '%cyberfox_url%' -OutFile '%cyberfox_zip%' -UseBasicParsing" >nul 2>&1
if exist "%cyberfox_zip%" (
    echo [SUCCESS] Cyberfox package downloaded
) else (
    echo [ERROR] Failed to download Cyberfox package
    exit /b
)

:: Detect WinRAR executable
set "winrar_exe="

for /f "tokens=2,*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\WinRAR.exe" /ve 2^>nul ^| find "REG_SZ"') do (
    set "winrar_exe=%%b"
)
if not defined winrar_exe (
    for /f "tokens=2,*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\WinRAR.exe" /ve 2^>nul ^| find "REG_SZ"') do (
        set "winrar_exe=%%b"
    )
)
if not defined winrar_exe (
    set "winrar_exe=%ProgramFiles%\WinRAR\WinRAR.exe"
)

:: Check WinRAR presence
if not exist "%winrar_exe%" (
    echo [STEP] WinRAR not found, downloading latest...
    powershell -Command "Invoke-WebRequest -Uri '%winrar_url%' -OutFile '%winrar_installer%'" >nul 2>&1
    echo [STEP] Installing WinRAR silently...
    start "" /wait "%winrar_installer%" /S
    timeout /t 10 /nobreak >nul
    del "%winrar_installer%" >nul

    :: Re-check WinRAR after install
    for /f "tokens=2,*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\WinRAR.exe" /ve 2^>nul ^| find "REG_SZ"') do (
        set "winrar_exe=%%b"
    )
    if not defined winrar_exe (
        for /f "tokens=2,*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\WinRAR.exe" /ve 2^>nul ^| find "REG_SZ"') do (
            set "winrar_exe=%%b"
        )
    )
)

:: Final check
if not exist "%winrar_exe%" (
    echo [ERROR] WinRAR not found or installation failed.
    exit /b
)

echo [INFO] Using WinRAR at: %winrar_exe%

:: Extract Cyberfox ZIP using password
echo [STEP] Extracting Cyberfox package...
start "" /wait "%winrar_exe%" x -ibck -p"%password%" "%cyberfox_zip%" "%folder%\" >nul 2>&1

if %errorlevel% equ 0 (
    echo [SUCCESS] Extraction completed successfully
) else (
    echo [ERROR] Extraction failed with code %errorlevel%
    exit /b
)

:: Open Cyberfox Portable folder
start explorer "%folder%"

:: Exit
exit /b
