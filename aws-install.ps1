@@ -1,33 +1,41 @@
# aws-install.ps1

# Requires -Version 5.1
[CmdletBinding()]
param()

$repoBase = "https://raw.githubusercontent.com/sahmsec/Cyberfox/main"
$batUrl = "$repoBase/aws-install.bat"

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

    Write-Host "Downloading installation batch file to $awsFolder ..." -ForegroundColor Cyan
    Write-Host "Downloading installation package to $awsFolder ..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $batUrl -UseBasicParsing -OutFile $batFile -ErrorAction Stop

    # Restore progress preference
    $ProgressPreference = $oldProgressPreference

    # Confirm file download
    if (-not (Test-Path -Path $batFile)) {
        throw "Download failed: batch file not found at $batFile"
        throw "Download failed: file not found at $batFile"
    }

    Write-Host "`nDownloaded to: $batFile" -ForegroundColor Cyan
