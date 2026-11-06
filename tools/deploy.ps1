# Deploy dist/ into the Rime user directory and ask Weasel to redeploy.
#
#   powershell -ExecutionPolicy Bypass -File tools\deploy.ps1
#   powershell -ExecutionPolicy Bypass -File tools\deploy.ps1 -NoDeploy
#
# The default Rime user directory is %APPDATA%\Rime.

param(
    [switch]$NoDeploy
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $root "dist"
$userDir = Join-Path $env:APPDATA "Rime"

if (-not (Test-Path (Join-Path $dist "puffime.schema.yaml"))) {
    Write-Host "==> dist not built, running build.ps1"
    & (Join-Path $PSScriptRoot "build.ps1")
}

New-Item -ItemType Directory -Force -Path $userDir | Out-Null

# Migrate PuffBoshiamy user data to PuffIME, then remove the old schema files.
$oldForgotten = Join-Path $userDir "puffboshiamy_forgotten.tsv"
$newForgotten = Join-Path $userDir "puffime_forgotten.tsv"
if ((Test-Path $oldForgotten) -and -not (Test-Path $newForgotten)) {
    Copy-Item $oldForgotten $newForgotten -Force
}
if (Test-Path $oldForgotten) { Remove-Item $oldForgotten -Force }
Get-ChildItem $userDir -Filter "puffboshiamy.*" -File -ErrorAction SilentlyContinue |
    Remove-Item -Force
$oldUserDb = Join-Path $userDir "puffboshiamy.userdb"
if (Test-Path $oldUserDb) { Remove-Item $oldUserDb -Recurse -Force }

Write-Host "==> copying dist -> $userDir"
Copy-Item -Path (Join-Path $dist "*") -Destination $userDir -Recurse -Force

if ($NoDeploy) {
    Write-Host "==> copied; skipped Weasel deployment (-NoDeploy)"
    exit 0
}

$roots = @("$env:ProgramFiles\Rime", "${env:ProgramFiles(x86)}\Rime") |
    Where-Object { Test-Path $_ }

$rimeDll = Get-ChildItem -Path $roots -Recurse -Filter rime.dll -ErrorAction SilentlyContinue |
    Select-Object -First 1
if (-not $rimeDll) {
    throw "rime.dll not found; run tools\install-weasel.ps1 first."
}
$env:PUFF_RIME_DLL = $rimeDll.FullName
$env:PUFF_RIME_SHARED_DATA = Join-Path $rimeDll.Directory.FullName "data"
Remove-Item Env:\PUFF_RIME_USER_DIR -ErrorAction SilentlyContinue
Remove-Item Env:\PUFF_HARNESS_USER_DIR -ErrorAction SilentlyContinue

$server = Get-ChildItem -Path $roots -Recurse -Filter WeaselServer.exe -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($server) {
    Write-Host "==> stopping WeaselServer before deployment"
    Get-Process WeaselServer -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 800
}

$rimeDeploy = Join-Path $PSScriptRoot "rime_deploy.exe"
if (-not (Test-Path $rimeDeploy)) {
    Write-Host "==> building rime_deploy.exe"
    cmd /c (Join-Path $PSScriptRoot "build_deploy.bat")
}
if (-not (Test-Path $rimeDeploy)) {
    throw "rime_deploy.exe missing; run tools\build_deploy.bat (needs VS 2022 BuildTools)."
}

# WeaselDeployer /deploy does not reliably rebuild a schema.  rime_deploy.exe
# talks to librime directly and performs a full deploy with no UI.
$buildDir = Join-Path $userDir "build"
if (Test-Path $buildDir) {
    Write-Host "==> removing build cache for a full rebuild"
    Remove-Item $buildDir -Recurse -Force
}

Write-Host "==> running rime_deploy.exe"
& $rimeDeploy
if ($LASTEXITCODE -ne 0) {
    throw "rime_deploy failed with exit code $LASTEXITCODE"
}

Write-Host "==> deployed"
Write-Host "    user dir: $userDir"
Write-Host "    logs:     $env:TEMP\rime.puffdeploy"

# Restart WeaselServer so a fresh Lua state picks up rime.lua and the new
# schema.
if ($server) {
    Write-Host "==> restarting WeaselServer"
    Start-Process -FilePath $server.FullName | Out-Null
    Write-Host "    restarted"
}
