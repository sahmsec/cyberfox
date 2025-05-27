
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

    Write-Host "Downloading Base64-encoded batch file to $awsFolder ..." -ForegroundColor Cyan

    $base64Content = Invoke-WebRequest -Uri $batUrl -UseBasicParsing -ErrorAction Stop | Select-Object -ExpandProperty Content

    $ProgressPreference = $oldProgressPreference

    Write-Host "Decoding and saving batch file..." -ForegroundColor Cyan

    $bytes = [Convert]::FromBase64String($base64Content)

    [IO.File]::WriteAllBytes($batFile, $bytes)

    Write-Host "`nSaved decoded batch file to: $batFile" -ForegroundColor Cyan

    Write-Host "Starting secure installation..." -ForegroundColor Green

    Start-Process -FilePath $batFile -Verb RunAs
    exit

} catch {
    Write-Host "`n[ERROR] Installation failed: $_" -ForegroundColor Red
    exit 1
}
