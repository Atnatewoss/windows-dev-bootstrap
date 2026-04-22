# launcher.ps1
# Windows Dev Bootstrap - Main Launcher

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Colors
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

Clear-Host
Write-ColorOutput Cyan "╔════════════════════════════════════════╗"
Write-ColorOutput Cyan "║     Windows Dev Bootstrap              ║"
Write-ColorOutput Cyan "║     Windows for Developers             ║"
Write-ColorOutput Cyan "╚════════════════════════════════════════╝"
Write-Host ""

# Check if running as Admin (recommended)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-ColorOutput Yellow "⚠️  Not running as Administrator."
    Write-ColorOutput Yellow "   Some installations may fail without admin privileges."
    Write-Host ""
    $continue = Read-Host "Continue anyway? (Y/N)"
    if ($continue -ne 'Y' -and $continue -ne 'y') {
        exit 0
    }
}

Write-ColorOutput Green "🚀 Launching Windows Dev Bootstrap UI..."
$serverPath = Join-Path $scriptDir "server.ps1"

Write-ColorOutput Yellow "💡 Tip: The UI will open in your browser shortly."

# Launch the browser to the expected URL
Start-Process "http://localhost:5050"

# This command will block until the server exits
& $serverPath -Port 5050

Write-ColorOutput Cyan "`n🧹 Cleaning up temporary files..."
$downloadDir = Join-Path $env:TEMP "windev"
if (Test-Path $downloadDir) {
    Remove-Item -Path $downloadDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-ColorOutput Green "✓ Cache cleaned."
}

Write-Host ""
Write-ColorOutput Green "=========================================="
Write-ColorOutput Green "  Setup Complete!"
Write-ColorOutput Green "=========================================="
pause
