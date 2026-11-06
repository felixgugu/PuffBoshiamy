param(
    [switch]$NoZip
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $root "dist"
$out  = Join-Path $root "release\PuffIME-trime"
$cfg  = Join-Path $root "platforms\android\trime"

Write-Host "==> building dictionaries"
& (Join-Path $PSScriptRoot "build.ps1")

if (Test-Path $out) {
    Remove-Item $out -Recurse -Force
}
New-Item -ItemType Directory -Force -Path (Join-Path $out "lua") | Out-Null

Write-Host "==> collecting Trime files"
Copy-Item (Join-Path $dist "puffime.dict.yaml") $out -Force
Copy-Item (Join-Path $dist "puffzhuyin.dict.yaml") $out -Force
Copy-Item (Join-Path $root "src\puffzhuyin.schema.yaml") $out -Force
Get-ChildItem (Join-Path $dist "lua\*.lua") -File |
    Copy-Item -Destination (Join-Path $out "lua") -Force
Remove-Item (Join-Path $out "lua\forgotten.lua") -Force -ErrorAction SilentlyContinue

python (Join-Path $PSScriptRoot "make_trime_files.py") `
    --schema (Join-Path $root "src\puffime.schema.yaml") `
    --rime (Join-Path $root "src\rime.lua") `
    --out $out

Copy-Item (Join-Path $cfg "default.custom.yaml") $out -Force
Copy-Item (Join-Path $cfg "trime.custom.yaml") $out -Force
Copy-Item (Join-Path $cfg "README.md") $out -Force

if (-not $NoZip) {
    $zip = Join-Path $root "release\PuffIME-trime.zip"
    if (Test-Path $zip) { Remove-Item $zip -Force }
    Write-Host "==> creating $zip"
    Compress-Archive -Path (Join-Path $out "*") -DestinationPath $zip -Force
}

Write-Host "==> Trime package: $out"
if (-not $NoZip) {
    Write-Host "==> zip:           $(Join-Path $root 'release\PuffIME-trime.zip')"
}
Get-ChildItem $out -Recurse -File | Select-Object FullName,Length | Format-Table -AutoSize
