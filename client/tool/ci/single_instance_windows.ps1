# Single-instance check of the Windows release build (doc 10, Windows:
# Single instance). Starts the app, starts it again with a soundspan://
# link, and asserts that the second process exits 0 within 10 s, that one
# app process remains, and that the first instance logged the second launch.
#
# Usage, from client/:
#   pwsh tool/ci/single_instance_windows.ps1 [-Bundle build/windows/x64/runner/Release]
param(
  [string]$Bundle = 'build/windows/x64/runner/Release'
)

$ErrorActionPreference = 'Stop'

$exe = Join-Path (Resolve-Path $Bundle) 'soundspan.exe'
if (-not (Test-Path $exe)) { throw "single_instance: executable not found: $exe" }
$link = 'soundspan://link?code=TEST22&server=https%3A%2F%2Fexample.invalid'

# path_provider's application support directory: %APPDATA%\<CompanyName>\<ProductName>.
$logs = Join-Path $env:APPDATA 'io.soundspan\soundspan\logs'
if (Test-Path $logs) { Remove-Item -Recurse -Force $logs }

function Fail([string]$message) {
  Write-Host "single_instance: $message"
  if (Test-Path $logs) {
    Get-ChildItem $logs -Filter 'app.*.log' | ForEach-Object {
      Write-Host "--- $($_.FullName)"
      Get-Content $_.FullName | Write-Host
    }
  }
  exit 1
}

$first = Start-Process -FilePath $exe -PassThru
try {
  $deadline = (Get-Date).AddSeconds(60)
  while ((Get-Date) -lt $deadline) {
    $first.Refresh()
    if ($first.HasExited) { Fail "the first instance exited with $($first.ExitCode)" }
    if ($first.MainWindowHandle -ne [IntPtr]::Zero) { break }
    Start-Sleep -Seconds 1
  }
  if ($first.MainWindowHandle -eq [IntPtr]::Zero) {
    Fail "the first instance's window did not appear within 60 s"
  }

  $second = Start-Process -FilePath $exe -ArgumentList $link -PassThru
  if (-not $second.WaitForExit(10000)) {
    $second.Kill()
    Fail 'the second instance did not exit within 10 s'
  }
  if ($second.ExitCode -ne 0) { Fail "the second instance exited with $($second.ExitCode)" }

  $processes = @(Get-Process -Name 'soundspan' -ErrorAction SilentlyContinue)
  if ($processes.Count -ne 1) { Fail "expected one app process, found $($processes.Count)" }
  if ($processes[0].Id -ne $first.Id) { Fail 'the remaining process is not the first instance' }

  $deadline = (Get-Date).AddSeconds(10)
  while ((Get-Date) -lt $deadline) {
    if ((Test-Path $logs) -and
        (Select-String -Path (Join-Path $logs 'app.*.log') -Pattern 'Second instance launched' -Quiet)) {
      Write-Host 'single_instance: second launch forwarded to the first instance'
      exit 0
    }
    Start-Sleep -Seconds 1
  }
  Fail "the first instance's log has no second-launch entry"
}
finally {
  if (-not $first.HasExited) { Stop-Process -Id $first.Id -Force }
}
