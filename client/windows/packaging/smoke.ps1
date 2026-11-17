# Install smoke test of the Windows packages (doc 11, client-build.yml:
# smoke-windows), on a fresh runner that never built the app.
#
# 1. Inno Setup: silent per-user install; soundspan.exe, the app-local MSVC
#    runtime and the soundspan:// registry values are present.
# 2. The installed app starts and stays up, writes its log, and a second
#    launch with a soundspan:// link exits 0 while the first keeps running.
# 3. Silent uninstall removes the install directory and the registry key.
# 4. MSIX: a copy signed with a throwaway self-signed certificate installs,
#    lists io.soundspan.app at the expected version with the soundspan
#    protocol, launches from its AppsFolder entry, and is removed. The
#    uploaded artifact stays unsigned.
#
# Every failed assertion exits 1 with a message and copies the app log to
# -LogOut for the workflow to upload.
#
# Usage (Windows PowerShell 5.1, elevated for the certificate trust):
#   powershell -NoProfile -ExecutionPolicy Bypass -File smoke.ps1 `
#     -Dist <dir with the packages> -Version <version> [-LogOut <dir>]
param(
  [Parameter(Mandatory = $true)][string]$Dist,
  [Parameter(Mandatory = $true)][string]$Version,
  [string]$LogOut = 'smoke-logs'
)

$ErrorActionPreference = 'Stop'

$installer = Join-Path $Dist "soundspan-$Version-windows-x64-unsigned-setup.exe"
$msix = Join-Path $Dist "soundspan-$Version-windows-x64-unsigned.msix"
$installDir = Join-Path $env:LOCALAPPDATA 'Programs\soundspan'
$exe = Join-Path $installDir 'soundspan.exe'
$classKey = 'HKCU:\Software\Classes\soundspan'
# path_provider's application support directory: %APPDATA%\<CompanyName>\<ProductName>.
$logs = Join-Path $env:APPDATA 'io.soundspan\soundspan\logs'
$identity = 'io.soundspan.app'
$publisher = 'CN=soundspan-unsigned'

function Save-Logs {
  New-Item -ItemType Directory -Force -Path $LogOut | Out-Null
  if (Test-Path $logs) { Copy-Item -Path (Join-Path $logs '*') -Destination $LogOut -Recurse -Force }
  # An MSIX app's roaming data is redirected into its package folder.
  Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA 'Packages') -Directory -Filter "$identity*" -ErrorAction SilentlyContinue |
    ForEach-Object {
      $packaged = Join-Path $_.FullName 'LocalCache\Roaming\io.soundspan\soundspan\logs'
      if (Test-Path $packaged) {
        $target = Join-Path $LogOut 'msix'
        New-Item -ItemType Directory -Force -Path $target | Out-Null
        Copy-Item -Path (Join-Path $packaged '*') -Destination $target -Recurse -Force
      }
    }
}

function Fail([string]$message) {
  Write-Host "smoke: FAIL: $message"
  Save-Logs
  Get-Process -Name 'soundspan' -ErrorAction SilentlyContinue | Stop-Process -Force
  exit 1
}

function Pass([string]$message) { Write-Host "smoke: ok: $message" }

function Stop-App {
  Get-Process -Name 'soundspan' -ErrorAction SilentlyContinue | Stop-Process -Force
  $deadline = (Get-Date).AddSeconds(15)
  while ((Get-Process -Name 'soundspan' -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 500
  }
}

foreach ($file in $installer, $msix) {
  if (-not (Test-Path $file)) { Fail "package not found: $file" }
}
if (Test-Path $logs) { Remove-Item -Recurse -Force $logs }

# --- 1. Inno Setup install -------------------------------------------------

$setup = Start-Process -FilePath $installer -Wait -PassThru `
  -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/CURRENTUSER', '/NORESTART', "/LOG=$(Join-Path $env:TEMP 'soundspan-setup.log')"
if ($setup.ExitCode -ne 0) {
  Get-Content (Join-Path $env:TEMP 'soundspan-setup.log') -ErrorAction SilentlyContinue | Write-Host
  Fail "the installer exited with $($setup.ExitCode)"
}
Pass 'the installer exited 0'

foreach ($name in 'soundspan.exe', 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
  if (-not (Test-Path (Join-Path $installDir $name))) { Fail "$name is not in $installDir" }
}
Pass "soundspan.exe and the MSVC runtime are in $installDir"

if (-not (Test-Path $classKey)) { Fail "$classKey is missing" }
$class = Get-ItemProperty -Path $classKey
if ($class.'(default)' -ne 'URL:soundspan') { Fail "$classKey default value is '$($class.'(default)')'" }
if ($null -eq $class.'URL Protocol' -or $class.'URL Protocol' -ne '') {
  Fail "$classKey has no empty 'URL Protocol' value"
}
$commandKey = Join-Path $classKey 'shell\open\command'
if (-not (Test-Path $commandKey)) { Fail "$commandKey is missing" }
$command = (Get-ItemProperty -Path $commandKey).'(default)'
$expectedCommand = "`"$exe`" `"%1`""
if ($command -ne $expectedCommand) { Fail "$commandKey is '$command', expected '$expectedCommand'" }
Pass 'the soundspan:// registry values are present'

# --- 2. Launch and second-launch forwarding --------------------------------

$first = Start-Process -FilePath $exe -PassThru
Start-Sleep -Seconds 20
$first.Refresh()
if ($first.HasExited) { Fail "the app exited with $($first.ExitCode) within 20 s" }
Pass 'the app is running after 20 s'

$second = Start-Process -FilePath $exe -ArgumentList 'soundspan://album/smoke' -PassThru
if (-not $second.WaitForExit(10000)) {
  $second.Kill()
  Fail 'the second launch did not exit within 10 s'
}
if ($second.ExitCode -ne 0) { Fail "the second launch exited with $($second.ExitCode)" }
$first.Refresh()
if ($first.HasExited) { Fail 'the first instance exited after the second launch' }
Pass 'the second launch exited 0 and the first instance keeps running'

# The log file appears with the first flushed entry; the forwarded second
# launch writes one, so wait for it after that.
$deadline = (Get-Date).AddSeconds(15)
$logFiles = @()
while ($logFiles.Count -eq 0 -and (Get-Date) -lt $deadline) {
  $logFiles = @(Get-ChildItem -Path $logs -File -ErrorAction SilentlyContinue)
  if ($logFiles.Count -eq 0) { Start-Sleep -Seconds 1 }
}
if ($logFiles.Count -eq 0) {
  Get-ChildItem -Recurse -Path (Join-Path $env:APPDATA 'io.soundspan') -ErrorAction SilentlyContinue |
    ForEach-Object { Write-Host "  found: $($_.FullName)" }
  Fail "no log file under $logs"
}
Pass "the app wrote $($logFiles[0].Name)"

Stop-App

# --- 3. Uninstall ----------------------------------------------------------

$uninstaller = Join-Path $installDir 'unins000.exe'
if (-not (Test-Path $uninstaller)) { Fail "no uninstaller at $uninstaller" }
$uninstall = Start-Process -FilePath $uninstaller -Wait -PassThru `
  -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART'
if ($uninstall.ExitCode -ne 0) { Fail "the uninstaller exited with $($uninstall.ExitCode)" }
# The uninstaller finishes from a copy of itself in %TEMP%; wait for it.
$deadline = (Get-Date).AddSeconds(60)
while (((Test-Path $installDir) -or (Test-Path $classKey)) -and (Get-Date) -lt $deadline) {
  Start-Sleep -Seconds 1
}
if (Test-Path $installDir) {
  Get-ChildItem -Recurse $installDir | ForEach-Object { Write-Host "  left: $($_.FullName)" }
  Fail "$installDir is still there after uninstall"
}
if (Test-Path $classKey) { Fail "$classKey is still there after uninstall" }
Pass 'the uninstaller removed the install directory and the registry key'

# --- 4. MSIX ---------------------------------------------------------------

$work = Join-Path $env:RUNNER_TEMP 'msix-smoke'
if (-not $env:RUNNER_TEMP) { $work = Join-Path $env:TEMP 'msix-smoke' }
New-Item -ItemType Directory -Force -Path $work | Out-Null
$signed = Join-Path $work 'soundspan-smoke.msix'
Copy-Item -Path $msix -Destination $signed -Force

# Throwaway code-signing certificate whose subject equals the manifest
# publisher, trusted for this job only.
$cert = New-SelfSignedCertificate -Type Custom -Subject $publisher `
  -KeyUsage DigitalSignature -FriendlyName 'soundspan smoke test' `
  -CertStoreLocation 'Cert:\CurrentUser\My' `
  -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}')
$password = ConvertTo-SecureString -String 'smoke' -Force -AsPlainText
$pfx = Join-Path $work 'smoke.pfx'
Export-PfxCertificate -Cert $cert -FilePath $pfx -Password $password | Out-Null
Import-PfxCertificate -FilePath $pfx -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople' -Password $password | Out-Null

$signtool = Get-ChildItem -Path "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\signtool.exe" -ErrorAction SilentlyContinue |
  Sort-Object { [version]$_.Directory.Parent.Name } |
  Select-Object -Last 1
if (-not $signtool) { Fail 'signtool.exe not found under Windows Kits 10' }
& $signtool.FullName sign /fd SHA256 /f $pfx /p smoke $signed
if ($LASTEXITCODE -ne 0) { Fail "signtool exited with $LASTEXITCODE" }

try {
  Add-AppxPackage -Path $signed
} catch {
  Fail "Add-AppxPackage failed: $($_.Exception.Message)"
}
$package = Get-AppxPackage -Name $identity
if (-not $package) { Fail "Get-AppxPackage does not list $identity" }
if ($package.Version -ne "$Version.0") { Fail "$identity is at $($package.Version), expected $Version.0" }
Pass "$identity $($package.Version) is installed"

$manifest = [xml](Get-Content -Raw (Join-Path $package.InstallLocation 'AppxManifest.xml'))
$protocols = @($manifest.GetElementsByTagName('uap:Protocol') | ForEach-Object { $_.GetAttribute('Name') })
if ($protocols -notcontains 'soundspan') { Fail "the MSIX manifest declares no soundspan protocol (found: $($protocols -join ', '))" }
Pass 'the MSIX manifest declares the soundspan protocol'

$appId = @($manifest.Package.Applications.Application)[0].Id
Start-Process -FilePath 'explorer.exe' -ArgumentList "shell:AppsFolder\$($package.PackageFamilyName)!$appId"
Start-Sleep -Seconds 20
if (-not (Get-Process -Name 'soundspan' -ErrorAction SilentlyContinue)) {
  Fail 'no soundspan process 20 s after launching the MSIX app'
}
Pass 'the MSIX app is running after 20 s'

Stop-App
Remove-AppxPackage -Package $package.PackageFullName
if (Get-AppxPackage -Name $identity) { Fail "$identity is still installed after Remove-AppxPackage" }
Pass 'the MSIX package was removed'

Remove-Item -Path "Cert:\CurrentUser\My\$($cert.Thumbprint)" -ErrorAction SilentlyContinue
Remove-Item -Path "Cert:\LocalMachine\TrustedPeople\$($cert.Thumbprint)" -ErrorAction SilentlyContinue

Write-Host 'smoke: all checks passed'
exit 0
