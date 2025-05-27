# aws-install.ps1

[CmdletBinding()]
param()

$repoBase = "https://raw.githubusercontent.com/sahmsec/Cyberfox/main"
$batUrl = "$repoBase/aws-install.bat"

$desktopPath = [Environment]::GetFolderPath("Desktop")
$awsFolder = Join-Path -Path $desktopPath -ChildPath "AWS"

if (-not (Test-Path -Path $awsFolder -PathType Container)) {
    New-Item -Path $awsFolder -ItemType Directory | Out-Null
}

$batFile = Join-Path -Path $awsFolder -ChildPath "aws-install-$(Get-Date -Format 'yyyyMMddHHmmss').bat"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $oldProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    Write-Host "Downloading installation batch file to $awsFolder ..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $batUrl -UseBasicParsing -OutFile $batFile -ErrorAction Stop

    $ProgressPreference = $oldProgressPreference

    if (-not (Test-Path -Path $batFile)) {
        throw "Download failed: batch file not found at $batFile"
    }

    Write-Host "`nDownloaded to: $batFile" -ForegroundColor Cyan
    $hash = Get-FileHash $batFile -Algorithm SHA256 | Select-Object -ExpandProperty Hash
    Write-Host "SHA256: $hash" -ForegroundColor Cyan

    Write-Host "Starting secure installation..." -ForegroundColor Green

    # Launch batch file elevated and immediately exit PowerShell
    Start-Process -FilePath $batFile -Verb RunAs
    exit

} catch {
    Write-Host "`n[ERROR] Installation failed: $_" -ForegroundColor Red
    exit 1
}
