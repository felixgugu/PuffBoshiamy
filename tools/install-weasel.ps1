# Install Weasel (小狼毫) via winget and report the deployer path.
#
#   powershell -ExecutionPolicy Bypass -File tools\install-weasel.ps1
#
# Requires an administrator/UAC confirmation.

$ErrorActionPreference = "Stop"
$id = "Rime.Weasel"

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget not found. Install it from the Microsoft Store (App Installer)."
}

Write-Host "==> checking $id"
$list = (& winget list --id $id --exact --accept-source-agreements 2>$null | Out-String)
if ($list -notmatch [regex]::Escape($id)) {
    Write-Host "==> installing $id"
    & winget install --id $id --exact --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "winget install failed with exit code $LASTEXITCODE"
    }
}
else {
    Write-Host "==> $id already installed"
}

$roots = @("$env:ProgramFiles\Rime", "${env:ProgramFiles(x86)}\Rime") |
    Where-Object { Test-Path $_ }

$deployer = Get-ChildItem -Path $roots -Recurse -Filter WeaselDeployer.exe -ErrorAction SilentlyContinue |
    Select-Object -First 1

if (-not $deployer) {
    throw "WeaselDeployer.exe not found under Program Files\Rime."
}

Write-Host "==> WeaselDeployer: $($deployer.FullName)"
Write-Host "==> done"
