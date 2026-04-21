# pin-to-taskbar.ps1
# Windows Taskbar Pinning Utility
# Supports Windows 10 and Windows 11

param(
    [string]$AppPath,
    [string]$AppName,
    [switch]$ListPinned
)

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

# Function to pin to taskbar (Windows 10/11)
function Pin-ToTaskbar {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Write-ColorOutput Red "  ✗ File not found: $Path"
        return $false
    }

    # Method 1: Shell.Application COM object
    try {
        $shell = New-Object -ComObject Shell.Application
        $folder = Split-Path $Path
        $file = Split-Path $Path -Leaf
        $namespace = $shell.Namespace($folder)
        $item = $namespace.ParseName($file)

        if ($item) {
            $verb = $item.Verbs() | Where-Object { $_.Name -like "*Pin to taskbar*" }
            if ($verb) {
                $verb.DoIt()
                Write-ColorOutput Green "  ✓ Pinned: $(Split-Path $Path -Leaf)"
                return $true
            } else {
                Write-ColorOutput Yellow "  ⚠ 'Pin to taskbar' verb not found for: $Path"
            }
        }
    }
    catch {
        Write-ColorOutput Yellow "  ⚠ COM method failed: $_"
    }

    # Method 2: Create shortcut in shell:Quick Launch\User Pinned\TaskBar
    try {
        $taskbarPath = Join-Path $env:APPDATA "Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
        if (-not (Test-Path $taskbarPath)) {
            New-Item -ItemType Directory -Force -Path $taskbarPath | Out-Null
        }

        $shortcutName = [System.IO.Path]::GetFileNameWithoutExtension($Path) + ".lnk"
        $shortcutPath = Join-Path $taskbarPath $shortcutName

        $WScriptShell = New-Object -ComObject WScript.Shell
        $shortcut = $WScriptShell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $Path
        $shortcut.Save()

        Write-ColorOutput Green "  ✓ Pinned via shortcut: $(Split-Path $Path -Leaf)"
        return $true
    }
    catch {
        Write-ColorOutput Red "  ✗ Shortcut method failed: $_"
        return $false
    }
}

# Function to list currently pinned items
function List-PinnedItems {
    Write-ColorOutput Cyan "`n📌 Currently pinned taskbar items:"

    $taskbarPath = Join-Path $env:APPDATA "Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
    if (Test-Path $taskbarPath) {
        $pinned = Get-ChildItem $taskbarPath -Filter "*.lnk"
        foreach ($item in $pinned) {
            $target = (New-Object -ComObject WScript.Shell).CreateShortcut($item.FullName).TargetPath
            Write-Output "  - $($item.BaseName) -> $target"
        }
    } else {
        Write-ColorOutput Yellow "  No pinned items found or taskbar path doesn't exist."
    }
}

# Main execution
if ($ListPinned) {
    List-PinnedItems
    exit 0
}

if ($AppPath) {
    Pin-ToTaskbar -Path $AppPath
} else {
    # If no parameters, show usage
    Write-ColorOutput Cyan "=========================================="
    Write-ColorOutput Cyan "  Taskbar Pinning Utility"
    Write-ColorOutput Cyan "=========================================="
    Write-Host ""
    Write-ColorOutput Yellow "Usage:"
    Write-Output "  .\pin-to-taskbar.ps1 -AppPath `"C:\path\to\app.exe`""
    Write-Output "  .\pin-to-taskbar.ps1 -ListPinned"
    Write-Host ""
    Write-ColorOutput Yellow "Examples:"
    Write-Output "  .\pin-to-taskbar.ps1 -AppPath `"C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe`""
    Write-Output "  .\pin-to-taskbar.ps1 -ListPinned"
}
