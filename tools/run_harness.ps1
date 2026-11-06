# Build and run the headless librime harness.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\run_harness.ps1
#
# Requires VS 2022 Build Tools (MSVC).  Stops WeaselServer while the harness
# runs, then starts it again.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$server = Get-ChildItem "$env:ProgramFiles\Rime" -Recurse -Filter WeaselServer.exe -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName

# Use an isolated copy of the Rime user directory so tests do not learn into
# the real user dictionary and candidate order is deterministic.
$realUser = Join-Path $env:APPDATA "Rime"
$harnessUser = Join-Path $env:TEMP "puffime-harness-rime"
Remove-Item $harnessUser -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $harnessUser | Out-Null
Copy-Item (Join-Path $realUser "*.yaml") $harnessUser -Force
Copy-Item (Join-Path $realUser "*.dict.yaml") $harnessUser -Force
Copy-Item (Join-Path $realUser "rime.lua") $harnessUser -Force
Copy-Item (Join-Path $realUser "lua") $harnessUser -Recurse -Force
Copy-Item (Join-Path $realUser "build") $harnessUser -Recurse -Force
$env:PUFF_RIME_USER_DIR = $harnessUser
# forgotten.lua only trusts this harness-specific name for its TSV path.
$env:PUFF_HARNESS_USER_DIR = $harnessUser

Get-Process WeaselServer -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

Push-Location $root
try {
    cmd /c tools\build_harness.bat
    if ($LASTEXITCODE -ne 0) {
        throw "harness build failed (is VS 2022 Build Tools installed?)"
    }
    & .\tools\rime_harness.exe
    if ($LASTEXITCODE -ne 0) {
        throw "harness run failed with exit code $LASTEXITCODE"
    }
    Write-Host "==> output: $root\tools\harness-output.txt"
}
finally {
    Pop-Location
    # The harness uses PUFF_RIME_USER_DIR / PUFF_HARNESS_USER_DIR to isolate
    # tests.  Do not let the real WeaselServer inherit them.
    Remove-Item Env:\PUFF_RIME_USER_DIR -ErrorAction SilentlyContinue
    Remove-Item Env:\PUFF_HARNESS_USER_DIR -ErrorAction SilentlyContinue
    if ($server -and (Test-Path $server)) {
        Start-Process -FilePath $server | Out-Null
    }
}
