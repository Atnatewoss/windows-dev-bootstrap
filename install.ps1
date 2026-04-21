# install.ps1
# Run this script as Administrator

param(
    [switch]$SkipNetworkCheck,
    [switch]$SkipBloatRemoval
)

# Colors for output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

Write-ColorOutput Green "=========================================="
Write-ColorOutput Green "  Windows for Developers - Setup Script"
Write-ColorOutput Green "=========================================="
Write-ColorOutput Yellow "This script will install all your development tools."
Write-ColorOutput Yellow "Run as Administrator is required."
Write-Host ""

# Check Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-ColorOutput Red "ERROR: Please run this script as Administrator."
    Write-ColorOutput Yellow "Right-click PowerShell or this script -> Run as Administrator"
    pause
    exit 1
}

# Check network connection
if (-not $SkipNetworkCheck) {
    Write-ColorOutput Cyan "Checking network connection..."
    try {
        $test = Test-Connection -ComputerName "8.8.8.8" -Count 2 -Quiet
        if (-not $test) {
            Write-ColorOutput Red "No internet connection detected. Please connect and try again."
            pause
            exit 1
        }
        Write-ColorOutput Green "✓ Internet connected"
    }
    catch {
        Write-ColorOutput Red "Network check failed. Use -SkipNetworkCheck to bypass."
        pause
        exit 1
    }
}

# Load config
$configPath = Join-Path $PSScriptRoot "config.json"
if (-not (Test-Path $configPath)) {
    Write-ColorOutput Red "config.json not found in $PSScriptRoot"
    pause
    exit 1
}

$config = Get-Content $configPath | ConvertFrom-Json

# Calculate total download size
$totalSizeMB = 0
foreach ($app in $config.apps) {
    if ($app.size_mb) {
        $totalSizeMB += $app.size_mb
    }
}

Write-ColorOutput Cyan "`n📦 Total estimated download size: $([math]::Round($totalSizeMB, 1)) MB"
Write-ColorOutput Yellow "This includes:"
foreach ($app in $config.apps) {
    if ($app.size_mb) {
        Write-Output "  - $($app.name): $($app.size_mb) MB"
    }
}

Write-Host ""
$confirmation = Read-Host "Do you want to continue with installation? (Y/N)"
if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
    Write-ColorOutput Red "Aborted."
    pause
    exit 0
}

# Create downloads folder
$downloadDir = Join-Path $env:TEMP "windows-dev-setup"
New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null

# Install Winget if not present (for Microsoft Store apps)
Write-ColorOutput Cyan "`n🔧 Ensuring Winget is available..."
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-ColorOutput Yellow "Winget not found. Installing App Installer from Microsoft Store..."
    Start-Process "ms-windows-store://pdp/?productid=9NBLGGH4NNS1" -Wait
    Write-ColorOutput Green "Please install 'App Installer' from the Store, then re-run this script."
    pause
    exit 1
}
Write-ColorOutput Green "✓ Winget ready"

# Install each app
foreach ($app in $config.apps) {
    Write-ColorOutput Cyan "`n📥 Installing: $($app.name)"

    switch ($app.method) {
        "winget" {
            winget install --id $app.id --silent --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput Green "  ✓ Installed via Winget"
            } else {
                Write-ColorOutput Red "  ✗ Winget install failed"
            }
        }
        "direct_download" {
            $outputPath = Join-Path $downloadDir "$($app.name).exe"
            Write-ColorOutput Yellow "  Downloading from $($app.url)..."
            Invoke-WebRequest -Uri $app.url -OutFile $outputPath
            Write-ColorOutput Yellow "  Running installer (silent mode if supported)..."
            Start-Process -FilePath $outputPath -ArgumentList $app.silent_args -Wait -NoNewWindow
            Write-ColorOutput Green "  ✓ Installer executed"
        }
        "manual" {
            Write-ColorOutput Yellow "  ⚠ Manual installation required: $($app.instructions)"
            Start-Process $app.url
        }
        "store" {
            Start-Process "ms-windows-store://pdp/?productid=$($app.store_id)" -Wait
            Write-ColorOutput Yellow "  Please install from Store window that opened, then press Enter"
            pause
        }
    }
}

# Pin to taskbar (Windows 11/10)
Write-ColorOutput Cyan "`n📌 Pinning apps to taskbar..."
foreach ($app in $config.apps | Where-Object { $_.pin_to_taskbar }) {
    $pinPath = $app.pin_path
    if (Test-Path $pinPath) {
        # PowerShell method for taskbar pinning (Windows 10/11)
        $shell = New-Object -ComObject Shell.Application
        $folder = Split-Path $pinPath
        $file = Split-Path $pinPath -Leaf
        $shell.Namespace($folder).ParseName($file).InvokeVerb("pintotaskbar")
        Write-ColorOutput Green "  ✓ Pinned: $($app.name)"
    } else {
        Write-ColorOutput Yellow "  ⚠ Could not find: $($app.name) at $pinPath"
    }
}

# Run bloatware removal if not skipped
if (-not $SkipBloatRemoval) {
    $bloatScript = Join-Path $PSScriptRoot "remove-bloat.ps1"
    if (Test-Path $bloatScript) {
        Write-ColorOutput Cyan "`n🧹 Running bloatware removal script..."
        & $bloatScript
    } else {
        Write-ColorOutput Yellow "remove-bloat.ps1 not found, skipping."
    }
}

Write-ColorOutput Green "`n=========================================="
Write-ColorOutput Green "  Setup Complete!"
Write-ColorOutput Green "=========================================="
Write-ColorOutput Yellow "Next steps:"
Write-ColorOutput Yellow "  1. Log into Bitwarden"
Write-ColorOutput Yellow "  2. Log into Brave profiles"
Write-ColorOutput Yellow "  3. Open Obsidian and restore your vault"
Write-ColorOutput Yellow "  4. Start coding!"
Write-Host ""
pause
