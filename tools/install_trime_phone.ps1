# Install the PuffIME Trime package on a connected Android phone.
#
#   powershell -ExecutionPolicy Bypass -File tools\install_trime_phone.ps1
#   powershell -ExecutionPolicy Bypass -File tools\install_trime_phone.ps1 -Serial <serial>
#
# Options:
#   -Build        rebuild release\PuffIME-trime first
#   -TrimeApk     install Trime from this APK if it is not on the phone
#   -SkipDeploy   only copy the files; do not tap the Deploy button
#   -SkipIme      do not enable / select Trime as the input method
#
# Requirements:
#   * Trime (com.osfans.trime) is installed on the phone
#   * USB debugging is enabled and this computer is authorized
#
# The script copies the package to Trime's Rime user directory, selects
# Trime as the input method, opens the app and taps the Deploy button.

param(
    [string]$Serial = "",
    [string]$PackageDir = "",
    [string]$TrimeApk = "",
    [switch]$Build,
    [switch]$SkipDeploy,
    [switch]$SkipIme
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
if (-not $PackageDir) {
    $PackageDir = Join-Path $root "release\PuffIME-trime"
}

$rimeDir = "/storage/emulated/0/Android/data/com.osfans.trime/files/rime"
$imeId = "com.osfans.trime/.ime.core.TrimeInputMethodService"

function Invoke-Adb {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$AdbArgs)
    if ($Serial) {
        & adb -s $Serial @AdbArgs
    } else {
        & adb @AdbArgs
    }
}

if ($Build -or -not (Test-Path (Join-Path $PackageDir "puffime.schema.yaml"))) {
    Write-Host "==> package not found, building it"
    & (Join-Path $PSScriptRoot "build_trime.ps1")
}

try {
    $devices = @(adb devices | Select-String -Pattern "\sdevice$")
} catch {
    throw "adb was not found. Install Android Platform Tools and put adb on PATH."
}

if ($devices.Count -eq 0) {
    throw "No adb device found. Enable USB debugging and authorize this computer."
}
if (-not $Serial -and $devices.Count -gt 1) {
    Write-Host "Connected devices:"
    $devices | ForEach-Object { Write-Host "  $($_.Line)" }
    throw "More than one device is connected; pass -Serial <serial>."
}

$installed = (Invoke-Adb shell pm list packages com.osfans.trime) -join "`n"
if ($installed -notmatch "com\.osfans\.trime") {
    if ($TrimeApk) {
        Write-Host "==> installing Trime from $TrimeApk"
        Invoke-Adb -AdbArgs @("install", "-r", $TrimeApk) | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Trime APK install failed."
        }
    } else {
        throw "Trime is not installed. Install 'Trime' (com.osfans.trime) first, or pass -TrimeApk <file.apk>."
    }
}

Write-Host "==> copying package to $rimeDir"
Invoke-Adb shell "mkdir -p '$rimeDir'" | Out-Null
Invoke-Adb push "$PackageDir\." "$rimeDir/" | Out-Null

# Migrate from the old PuffBoshiamy schema.  If the old files stay behind,
# Trime keeps deploying them and can keep selecting puffboshiamy instead of
# the new puffime schema (which is what made the Zhuyin fix appear missing
# on Android).
Write-Host "==> removing old PuffBoshiamy schema files"
Invoke-Adb shell "rm -f '$rimeDir/puffboshiamy.schema.yaml' '$rimeDir/puffboshiamy.dict.yaml' '$rimeDir/build/puffboshiamy.'*" | Out-Null
Invoke-Adb shell "rm -rf '$rimeDir/puffboshiamy.userdb'" | Out-Null

$required = @(
    "puffime.schema.yaml",
    "puffzhuyin.schema.yaml",
    "puffime.dict.yaml",
    "puffzhuyin.dict.yaml",
    "rime.lua",
    "default.custom.yaml",
    "trime.custom.yaml",
    "lua\zhuyin_key.lua",
    "lua\zhuyin_partial.lua",
    "lua\zhuyin_completion.lua",
    "lua\zhuyin_completion_data.lua",
    "lua\zhuyin_bopomofo.lua"
)
foreach ($name in $required) {
    $remote = "$rimeDir/" + ($name -replace "\\", "/")
    Invoke-Adb shell "test -f '$remote'" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Copy failed: $remote is missing."
    }
}
Write-Host "==> files copied"

if (-not $SkipIme) {
    Write-Host "==> enabling Trime as an input method"
    try {
        Invoke-Adb shell ime enable $imeId | Out-Null
        Invoke-Adb shell ime set $imeId | Out-Null
    } catch {
        Write-Host "    could not select Trime automatically; enable it in Android settings."
    }
}

function Get-TrimeUi {
    $dump = Join-Path $env:TEMP "puff-trime-ui.xml"
    $remoteDump = "/sdcard/puff-trime-ui.xml"
    Invoke-Adb shell "uiautomator dump $remoteDump" | Out-Null
    Invoke-Adb pull $remoteDump $dump | Out-Null
    if (-not (Test-Path $dump)) {
        return $null
    }
    return [xml](Get-Content $dump -Encoding UTF8)
}

function Invoke-TapNode {
    param($Node)
    if (-not $Node) {
        return $false
    }
    $m = [regex]::Match($Node.bounds, '\[(\d+),(\d+)\]\[(\d+),(\d+)\]')
    if (-not $m.Success) {
        return $false
    }
    $x = ([int]$m.Groups[1].Value + [int]$m.Groups[3].Value) / 2
    $y = ([int]$m.Groups[2].Value + [int]$m.Groups[4].Value) / 2
    Invoke-Adb shell input tap ([int]$x) ([int]$y) | Out-Null
    return $true
}

if (-not $SkipDeploy) {
    Write-Host "==> opening Trime"
    # Clear logcat so the deployment result below is unambiguous.
    Invoke-Adb -AdbArgs @("logcat", "-c") | Out-Null

    # Do not force-stop Trime here: stopping the currently selected IME
    # makes Android fall back to another keyboard (and Trime shows its
    # setup wizard again).
    Invoke-Adb shell am start -n com.osfans.trime/.ui.main.MainActivity | Out-Null
    Start-Sleep -Seconds 3

    # "部署" built from code points so the script stays ASCII-safe.
    $deployLabel = [string]([char]0x90E8) + [char]0x7F72
    $tapped = $false
    for ($attempt = 0; $attempt -lt 5; $attempt++) {
        $ui = Get-TrimeUi
        if (-not $ui) {
            Start-Sleep -Seconds 1
            continue
        }

        $deploy = $ui.SelectNodes("//node[@content-desc]") |
            Where-Object { $_.'content-desc' -eq $deployLabel -or $_.'content-desc' -eq "Deploy" } |
            Select-Object -First 1
        if ($deploy) {
            if (Invoke-TapNode $deploy) {
                $tapped = $true
                Write-Host "==> tapped Deploy"
            }
            break
        }

        # Trime's first-run setup wizard: skip it and confirm the dialog.
        $skip = $ui.SelectNodes("//node[contains(@resource-id,'/skip_button')]") |
            Select-Object -First 1
        if ($skip) {
            Write-Host "==> skipping Trime's setup wizard"
            Invoke-TapNode $skip | Out-Null
            Start-Sleep -Seconds 1
            $dialog = Get-TrimeUi
            if ($dialog) {
                $ok = $dialog.SelectNodes("//node[@resource-id='android:id/button1']") |
                    Select-Object -First 1
                Invoke-TapNode $ok | Out-Null
            }
            Start-Sleep -Seconds 1
            continue
        }

        # A settings sub-page: go back towards the main screen.
        Invoke-Adb shell input keyevent 4 | Out-Null
        Start-Sleep -Seconds 1
    }

    if ($tapped) {
        Write-Host "==> waiting for deployment..."
    } else {
        Write-Host "==> Deploy button not found."
        Write-Host "    If Trime shows its setup wizard, finish or skip it, then tap Deploy."
        Write-Host "    Waiting up to 60 seconds for deployment..."
    }

    $deployed = $false
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 2
        $logs = (Invoke-Adb -AdbArgs @("logcat", "-d", "-t", "400")) -join "`n"
        if ($logs -match "finished updating schemas") {
            $deployed = $true
            break
        }
    }
    if ($deployed) {
        Write-Host "==> deployment finished"
    } else {
        Write-Host "==> deployment was not detected; open Trime and tap Deploy once."
    }
}

Write-Host ""
Write-Host "Next steps on the phone:"
Write-Host "  1. Android settings -> System -> Languages & input -> On-screen keyboard"
Write-Host "     -> enable Trime, then choose Trime as the keyboard."
Write-Host "  2. Open Trime -> schema list -> choose the PuffIME schema."
Write-Host "  3. In any text field, tap the bottom-left Zhuyin key."
Write-Host "     The keyboard changes to Bopomofo; it returns after a character is committed."
