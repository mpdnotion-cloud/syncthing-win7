# build-win7.ps1
# Builds Syncthing for Windows 7 / Windows Server 2008 R2 SP1 (x64).
#
# Why: Go >= 1.21 dropped support for Windows 7 / Server 2008 R2, and this
# code requires Go 1.26 (see go.mod). This script uses the "go-legacy-win7"
# toolchain, a Go fork that restores Windows 7 support:
#   https://github.com/thongtech/go-legacy-win7
#
# Build settings for the target machine (e.g. Celeron G1610T, 8 GB RAM):
#   - GOAMD64=v1     -> baseline x86-64, no AVX required.
#   - CGO_ENABLED=0  -> pure-Go SQLite (modernc.org/sqlite), no C DLLs.
#   - -no-upgrade    -> disables auto-upgrade: official builds do not start on
#                       Windows 7 / 2008 R2 and would replace this binary.
#
# Usage (on a Windows 10/11 x64 machine, from the repository root):
#   powershell -ExecutionPolicy Bypass -File .\build-win7.ps1
# Output: syncthing-windows-amd64-<version>.zip in the repository root.

param(
    [string]$GoLegacyVersion = "1.26.7-1",
    [string]$Version = "v2.1.5+win7"
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$toolDir = Join-Path $root ".toolchain"
$goDir = Join-Path $toolDir "go-legacy-win7"
$goExe = Join-Path $goDir "bin\go.exe"

if (-not (Test-Path $goExe)) {
    New-Item -ItemType Directory -Force -Path $toolDir | Out-Null
    $zip = Join-Path $toolDir "go-legacy-win7.zip"
    $url = "https://github.com/thongtech/go-legacy-win7/releases/download/v$GoLegacyVersion/go-legacy-win7-$GoLegacyVersion.windows_amd64.zip"
    Write-Host "Downloading $url"
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath $toolDir -Force
    Remove-Item $zip
}

$env:PATH = (Join-Path $goDir "bin") + ";" + $env:PATH
$env:GOTOOLCHAIN = "local"   # never let Go download the official toolchain
$env:CGO_ENABLED = "0"
$env:GOAMD64 = "v1"
$env:VERSION = $Version

& $goExe version
Push-Location $root
try {
    & $goExe run build.go -goos windows -goarch amd64 -no-upgrade zip
    if ($LASTEXITCODE -ne 0) { throw "Build failed ($LASTEXITCODE)" }
} finally {
    Pop-Location
}
