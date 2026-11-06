# Build tools/make_dict.exe (standalone dictionary builder for the release).
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\build_make_dict.ps1
#
# Requires Python 3.  Installs PyInstaller if it is missing.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    python -c "import PyInstaller" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "==> installing PyInstaller"
        python -m pip install --quiet pyinstaller
    }
    Write-Host "==> building tools\make_dict.exe"
    python -m PyInstaller --noconfirm --clean --onefile --name make_dict `
        --distpath tools --workpath build\make_dict --specpath build\make_dict `
        tools\make_dict.py
    if ($LASTEXITCODE -ne 0) { throw "PyInstaller failed" }
    Write-Host "==> built: tools\make_dict.exe"
}
finally {
    Pop-Location
}
