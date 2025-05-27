# Requires -Version 5.1
[CmdletBinding()]
param()

$repoBase = "https://raw.githubusercontent.com/sahmsec/Cyberfox/main"
$batUrl = "$repoBase/aws-install.bat"

# Get desktop path dynamically
$desktopPath = [Environment]::GetFolderPath("Desktop")
$awsFolder = Join-Path -Path $desktopPath -ChildPath "AWS"

# Create AWS folder if not exists
if (-not (Test-Path -Path $awsFolder -PathType Container)) {
    New-Item -Path $awsFolder -ItemType Directory | Out-Null
    Write-Host "Created AWS folder: $awsFolder"
} else {
    Write-Host "AWS folder exists: $awsFolder"
}

# Define path for the batch file inside AWS folder
$batFile = Join-Path -Path $awsFolder -ChildPath "aws-install.bat"

try {
    # Use TLS 1.2+
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-Host "Downloading batch file to $batFile ..."
    Invoke-WebRequest -Uri $batUrl -UseBasicParsing -OutFile $batFile -ErrorAction Stop

    if (-not (Test-Path -Path $batFile)) {
        throw "Failed to download batch file."
    }
    Write-Host "Batch file downloaded successfully."

    Write-Host "Launching batch file elevated..."
    $proc = Start-Process -FilePath $batFile -Verb RunAs -Wait -PassThru

    Write-Host "Batch execution finished with exit code $($proc.ExitCode)."

    # Delete batch file after execution
    Remove-Item -Path $batFile -Force
    Write-Host "Deleted batch file: $batFile"

} catch {
    Write-Host "Error: $_"
    exit 1
}
