# aws-install.ps1
# Checks/creates AWS folder on Desktop, downloads password-protected ZIP from GitHub,
# extracts it using WinRAR CLI with password 'aws', then deletes the ZIP.

$desktopPath = [Environment]::GetFolderPath("Desktop")
$awsFolder = Join-Path $desktopPath "AWS"
$url = "https://github.com/sahmsec/Cyberfox/releases/download/v1.0/CyberfoxPortable.zip"
$zipFile = Join-Path $awsFolder "CyberfoxPortable.zip"
$password = "aws"

function Get-WinRARPath {
    $pathsToCheck = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\WinRAR.exe",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\WinRAR.exe",
        "HKLM:\SOFTWARE\WinRAR"
    )
    foreach ($path in $pathsToCheck) {
        try {
            if ($path -like "*App Paths*") {
                $regValue = (Get-ItemProperty -Path $path -ErrorAction SilentlyContinue).'(default)'
                if ($regValue -and (Test-Path $regValue)) {
                    return $regValue
                }
            } elseif ($path -eq "HKLM:\SOFTWARE\WinRAR") {
                $installPath = (Get-ItemProperty -Path $path -Name "Path" -ErrorAction SilentlyContinue).Path
                if ($installPath) {
                    $winrarExe = Join-Path $installPath "WinRAR.exe"
                    if (Test-Path $winrarExe) {
                        return $winrarExe
                    }
                }
            }
        } catch {}
    }

    $defaultPaths = @(
        "$env:ProgramFiles\WinRAR\WinRAR.exe",
        "$env:ProgramFiles(x86)\WinRAR\WinRAR.exe"
    )
    foreach ($p in $defaultPaths) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

$winrarPath = Get-WinRARPath
if (-not $winrarPath) {
    Write-Host "WinRAR not found. Please install it from https://www.win-rar.com/ and rerun this script." -ForegroundColor Red
    exit 1
}
Write-Host "Found WinRAR at: $winrarPath"

if (-Not (Test-Path $awsFolder)) {
    New-Item -ItemType Directory -Path $awsFolder | Out-Null
    Write-Host "Created folder: $awsFolder"
} else {
    Write-Host "Folder already exists: $awsFolder"
}

Write-Host "Downloading zip..."
try {
    Invoke-WebRequest -Uri $url -OutFile $zipFile -UseBasicParsing
    Write-Host "Download complete."
} catch {
    Write-Host "Download failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host "Extracting zip with password..."
$extractArgs = @(
    "x",
    "-p$password",
    "-y",
    "`"$zipFile`"",
    "`"$awsFolder`""
)
$proc = Start-Process -FilePath $winrarPath -ArgumentList $extractArgs -Wait -PassThru
if ($proc.ExitCode -eq 0) {
    Write-Host "Extraction successful."
} elseif ($proc.ExitCode -eq 1) {
    Write-Host "Extraction completed with warnings."
} else {
    Write-Host "Extraction failed with exit code $($proc.ExitCode)." -ForegroundColor Red
    exit 1
}

Remove-Item $zipFile
Write-Host "Deleted zip file."

Write-Host "All done! Files extracted to $awsFolder"
