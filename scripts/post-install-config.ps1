# post-install-config.ps1
# Post-installation configurations for development environment

param(
    [switch]$SkipGitConfig,
    [switch]$SkipTerminal,
    [switch]$SkipObsidianVault,
    [switch]$SkipAll
)

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

Clear-Host
Write-ColorOutput Cyan "=========================================="
Write-ColorOutput Cyan "  Post-Install Configuration"
Write-ColorOutput Cyan "  Windows for Developers"
Write-ColorOutput Cyan "=========================================="
Write-Host ""

if (-not $SkipAll) {
    Write-ColorOutput Yellow "This script will help you configure:"
    Write-Output "  1. Git user name & email"
    Write-Output "  2. Windows Terminal settings"
    Write-Output "  3. Obsidian vault setup"
    Write-Host ""

    $confirm = Read-Host "Run post-install configuration? (Y/N)"
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        Write-ColorOutput Green "Skipped."
        exit 0
    }
}

# 1. Git Configuration
if (-not $SkipGitConfig -and -not $SkipAll) {
    Write-ColorOutput Cyan "`n🔧 Configuring Git..."

    $gitPath = Get-Command git -ErrorAction SilentlyContinue
    if ($gitPath) {
        $currentName = git config --global user.name
        $currentEmail = git config --global user.email

        if ($currentName) {
            Write-ColorOutput Yellow "Current Git user.name: $currentName"
            $changeName = Read-Host "Change it? (Y/N)"
            if ($changeName -eq 'Y' -or $changeName -eq 'y') {
                $newName = Read-Host "Enter your full name"
                git config --global user.name "$newName"
                Write-ColorOutput Green "  ✓ Git user.name updated"
            }
        } else {
            $newName = Read-Host "Enter your full name (for Git commits)"
            git config --global user.name "$newName"
            Write-ColorOutput Green "  ✓ Git user.name set"
        }

        if ($currentEmail) {
            Write-ColorOutput Yellow "Current Git user.email: $currentEmail"
            $changeEmail = Read-Host "Change it? (Y/N)"
            if ($changeEmail -eq 'Y' -or $changeEmail -eq 'y') {
                $newEmail = Read-Host "Enter your email"
                git config --global user.email "$newEmail"
                Write-ColorOutput Green "  ✓ Git user.email updated"
            }
        } else {
            $newEmail = Read-Host "Enter your email (for Git commits)"
            git config --global user.email "$newEmail"
            Write-ColorOutput Green "  ✓ Git user.email set"
        }

        # Additional useful Git configs
        git config --global core.autocrlf input
        git config --global init.defaultBranch main
        git config --global pull.rebase false
        Write-ColorOutput Green "  ✓ Additional Git configs set (autocrlf, default branch, pull behavior)"
    } else {
        Write-ColorOutput Red "  ✗ Git not found. Install Git first."
    }
}

# 2. Windows Terminal Settings
if (-not $SkipTerminal -and -not $SkipAll) {
    Write-ColorOutput Cyan "`n🖥️  Configuring Windows Terminal..."

    $terminalPath = "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"

    if (Test-Path $terminalPath) {
        Write-ColorOutput Yellow "Windows Terminal settings found at: $terminalPath"
        $openSettings = Read-Host "Open settings.json to customize? (Y/N)"
        if ($openSettings -eq 'Y' -or $openSettings -eq 'y') {
            notepad $terminalPath
            Write-ColorOutput Green "  ✓ Settings opened in Notepad"
        }

        # Suggest useful PowerShell profile
        $profilePath = Join-Path $PROFILE.CurrentUserAllHosts
        $createProfile = Read-Host "Create PowerShell profile with useful aliases? (Y/N)"
        if ($createProfile -eq 'Y' -or $createProfile -eq 'y') {
            if (-not (Test-Path $profilePath)) {
                New-Item -ItemType File -Force -Path $profilePath | Out-Null
            }

            $aliases = @"
# Windows Dev Bootstrap - PowerShell Aliases
function ll { Get-ChildItem }
function gst { git status }
function gco { git checkout `
$args }
function gaa { git add --all }
function gcmsg { git commit -m `
$args }
function gp { git push }

# Node/Python shortcuts
function nr { npm run `
$args }
function ni { npm install }
function pi { pip install `
$args }

# Quick directory navigation
function dev { cd ~/dev }
function projects { cd ~/projects }

Write-Host "Windows Dev Bootstrap profile loaded!" -ForegroundColor Cyan
"@
            Add-Content -Path $profilePath -Value "`n$aliases"
            Write-ColorOutput Green "  ✓ PowerShell profile created at: $profilePath"
        }
    } else {
        Write-ColorOutput Yellow "  Windows Terminal not found. Install from Microsoft Store first."
    }
}

# 3. Obsidian Vault Setup
if (-not $SkipObsidianVault -and -not $SkipAll) {
    Write-ColorOutput Cyan "`n📝 Obsidian Vault Setup..."

    $obsidianPath = "$env:LOCALAPPDATA\Obsidian\Obsidian.exe"

    if (Test-Path $obsidianPath) {
        Write-ColorOutput Yellow "Obsidian is installed."

        $vaultChoice = Read-Host "Do you want to: (1) Create new vault, (2) Clone from GitHub, (3) Skip"

        switch ($vaultChoice) {
            "1" {
                $vaultName = Read-Host "Enter vault name"
                $vaultPath = Read-Host "Enter vault location (default: ~/Documents/Obsidian)"
                if (-not $vaultPath) { $vaultPath = "$env:USERPROFILE\Documents\Obsidian" }
                $fullPath = Join-Path $vaultPath $vaultName
                New-Item -ItemType Directory -Force -Path $fullPath | Out-Null
                Write-ColorOutput Green "  ✓ New vault created at: $fullPath"
                Write-ColorOutput Yellow "  Open Obsidian and add this vault"
            }
            "2" {
                $repoUrl = Read-Host "Enter GitHub repo URL (e.g., https://github.com/username/notes.git)"
                $clonePath = Read-Host "Enter clone location (default: ~/Documents/Obsidian)"
                if (-not $clonePath) { $clonePath = "$env:USERPROFILE\Documents\Obsidian" }

                if (Get-Command git -ErrorAction SilentlyContinue) {
                    git clone $repoUrl $clonePath
                    Write-ColorOutput Green "  ✓ Vault cloned to: $clonePath"
                } else {
                    Write-ColorOutput Red "  ✗ Git not found. Install Git first."
                }
            }
            default {
                Write-ColorOutput Yellow "  Skipped Obsidian setup"
            }
        }
    } else {
        Write-ColorOutput Yellow "  Obsidian not installed yet. Run install.ps1 first."
    }
}

# 4. Suggested folder structure
Write-ColorOutput Cyan "`n📁 Suggested Development Folder Structure..."
$createFolders = Read-Host "Create ~/dev and ~/projects folders? (Y/N)"
if ($createFolders -eq 'Y' -or $createFolders -eq 'y') {
    $devPath = "$env:USERPROFILE\dev"
    $projectsPath = "$env:USERPROFILE\projects"

    New-Item -ItemType Directory -Force -Path $devPath | Out-Null
    New-Item -ItemType Directory -Force -Path $projectsPath | Out-Null

    Write-ColorOutput Green "  ✓ Created: $devPath"
    Write-ColorOutput Green "  ✓ Created: $projectsPath"
}

# 5. Summary
Write-ColorOutput Green "`n=========================================="
Write-ColorOutput Green "  Post-Install Configuration Complete!"
Write-ColorOutput Green "=========================================="
Write-Host ""
Write-ColorOutput Yellow "Next steps:"
Write-Output "  1. Log into Bitwarden and sync passwords"
Write-Output "  2. Log into Brave profiles (GitHub, Gmail, etc.)"
Write-Output "  3. Open Obsidian and load your vault"
Write-Output "  4. Restart your terminal to load PowerShell profile"
Write-Output "  5. Start coding!"
Write-Host ""

pause
