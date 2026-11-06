param(
    [string]$Name = "",
    [switch]$NoDeploy
)

$ErrorActionPreference = "Stop"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$root = Split-Path -Parent $PSScriptRoot

$order = @("light", "dark", "gray", "macaron", "mediterranean")
$themes = @{
    light         = @{ key = "puff";               label = "Puff 淺" }
    dark          = @{ key = "puff_dark";          label = "Puff 深" }
    gray          = @{ key = "puff_gray";          label = "Puff 灰" }
    macaron       = @{ key = "puff_macaron";       label = "Puff 馬卡龍" }
    mediterranean = @{ key = "puff_mediterranean"; label = "Puff 地中海" }
}
$aliases = @{
    "puff"                = "light"
    "puff_dark"           = "dark"
    "puff_gray"           = "gray"
    "puff_macaron"        = "macaron"
    "puff_mediterranean"  = "mediterranean"
    "淺"                  = "light"
    "深"                  = "dark"
    "灰"                  = "gray"
    "馬卡龍"              = "macaron"
    "地中海"              = "mediterranean"
}

if ([string]::IsNullOrWhiteSpace($Name)) {
    Write-Host "Available themes:"
    for ($i = 0; $i -lt $order.Count; $i++) {
        $t = $themes[$order[$i]]
        Write-Host ("  {0}) {1,-14} {2}" -f ($i + 1), $order[$i], $t.label)
    }
    $choice = Read-Host "Choose a theme [1-$($order.Count)] (default 1)"
    if ([string]::IsNullOrWhiteSpace($choice)) {
        $Name = "light"
    }
    elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $order.Count) {
        $Name = $order[[int]$choice - 1]
    }
    else {
        throw "invalid choice: $choice"
    }
}

$norm = $Name.Trim().ToLowerInvariant()
if ($aliases.ContainsKey($Name)) {
    $norm = $aliases[$Name]
}
elseif ($aliases.ContainsKey($norm)) {
    $norm = $aliases[$norm]
}
if (-not $themes.ContainsKey($norm)) {
    throw "unknown theme '$Name'. Use: $($order -join ', ') (or 淺/深/灰/馬卡龍/地中海)"
}

$entry = $themes[$norm]
$src = Join-Path $root "platforms\windows\weasel.custom.yaml"
if (-not (Test-Path $src)) {
    throw "missing $src"
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
$text = [IO.File]::ReadAllText($src, [Text.Encoding]::UTF8)
$pattern = '(?m)^(\s*color_scheme:\s*)\S+'
if ($text -notmatch $pattern) {
    throw "color_scheme line not found in $src"
}
$new = $text -replace $pattern, "`${1}$($entry.key)"
[IO.File]::WriteAllText($src, $new, $utf8)

$dist = Join-Path $root "dist"
if (Test-Path $dist) {
    Copy-Item $src (Join-Path $dist "weasel.custom.yaml") -Force
}

if (-not $NoDeploy) {
    & (Join-Path $PSScriptRoot "deploy.ps1")
}
else {
    Write-Host "==> updated source/dist only (-NoDeploy)"
}

Write-Host ""
Write-Host "Theme: $($entry.label)  ($($entry.key))"
Write-Host "Source: $src"
if (-not $NoDeploy) {
    Write-Host "Deployed to: $env:APPDATA\Rime\weasel.custom.yaml"
}
