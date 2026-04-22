# bootstrap.ps1
# This script is meant to be run via:
# irm https://raw.githubusercontent.com/YOUR_ORG/windows-dev-bootstrap/main/bootstrap.ps1 | iex

$ErrorActionPreference = 'Stop'

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Downloading Windows Dev Bootstrap..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$repoZipUrl = "https://github.com/Atnateowss/windows-dev-bootstrap/archive/refs/heads/main.zip"
$tempDir = Join-Path $env:TEMP "WindowsDevBootstrap"
$zipPath = Join-Path $env:TEMP "windows-dev-bootstrap.zip"

if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}

Write-Host "Downloading repository..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $repoZipUrl -OutFile $zipPath

Write-Host "Extracting files..." -ForegroundColor Yellow
Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force

$extractedDir = Join-Path $tempDir "windows-dev-bootstrap-main"
$launcherPath = Join-Path $extractedDir "launcher.ps1"

if (Test-Path $launcherPath) {
    Write-Host "Starting Launcher..." -ForegroundColor Green
    Set-Location $extractedDir
    & $launcherPath
} else {
    Write-Host "Error: Could not find launcher.ps1 in the extracted files." -ForegroundColor Red
}

# Cleanup
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
# We leave $tempDir cleanup to launcher.ps1 or the user, or we can clean it up here after launcher finishes.
if (Test-Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
