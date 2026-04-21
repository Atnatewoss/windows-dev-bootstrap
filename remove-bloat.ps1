# remove-bloat.ps1
# Run as Administrator

Write-ColorOutput Cyan "=========================================="
Write-ColorOutput Cyan "  Windows Bloatware Removal"
Write-ColorOutput Cyan "=========================================="
Write-ColorOutput Yellow "This will help you remove unwanted Windows apps."
Write-ColorOutput Yellow "Default selections are recommended for developers."
Write-Host ""

# List of bloatware with default selection (true = remove by default)
$bloatware = @(
    @{name="Copilot (Windows Copilot)"; package="Microsoft.Windows.Copilot"; default=$true},
    @{name="Clipchamp Video Editor"; package="Microsoft.Clipchamp"; default=$true},
    @{name="Microsoft News"; package="Microsoft.BingNews"; default=$true},
    @{name="Microsoft Solitaire Collection"; package="Microsoft.MicrosoftSolitaireCollection"; default=$true},
    @{name="Xbox App (keep if you game)"; package="Microsoft.XboxApp"; default=$false},
    @{name="Xbox Game Bar"; package="Microsoft.XboxGamingOverlay"; default=$true},
    @{name="Microsoft Teams (personal)"; package="Microsoft.Teams"; default=$true},
    @{name="Microsoft OneDrive"; package="Microsoft.OneDrive"; default=$false},
    @{name="Microsoft People"; package="Microsoft.People"; default=$true},
    @{name="Microsoft Get Help"; package="Microsoft.GetHelp"; default=$true},
    @{name="Microsoft Feedback Hub"; package="Microsoft.FeedbackHub"; default=$true},
    @{name="Microsoft Maps"; package="Microsoft.WindowsMaps"; default=$true},
    @{name="Microsoft Skype"; package="Microsoft.Skype"; default=$true},
    @{name="Microsoft To Do"; package="Microsoft.Todos"; default=$false},
    @{name="Microsoft Whiteboard"; package="Microsoft.Whiteboard"; default=$true},
    @{name="Power Automate Desktop"; package="Microsoft.PowerAutomateDesktop"; default=$true}
)

# Display checklist
$selected = @()
for ($i = 0; $i -lt $bloatware.Count; $i++) {
    $item = $bloatware[$i]
    $defaultMark = if ($item.default) { "[X]" } else { "[ ]" }
    Write-Host "$($i+1). $defaultMark $($item.name)"
}

Write-Host ""
Write-ColorOutput Yellow "Enter numbers to toggle (e.g., '1,3,5' or '1-5' or 'all'), then press Enter:"
$input = Read-Host

# Parse input (simple version)
if ($input -eq "all") {
    $selected = $bloatware | ForEach-Object { $_.package }
} else {
    $ranges = $input -split ','
    foreach ($range in $ranges) {
        if ($range -match '(\d+)-(\d+)') {
            for ($i = [int]$matches[1]; $i -le [int]$matches[2]; $i++) {
                if ($i -ge 1 -and $i -le $bloatware.Count) {
                    $selected += $bloatware[$i-1].package
                }
            }
        } elseif ($range -match '\d+') {
            $idx = [int]$range
            if ($idx -ge 1 -and $idx -le $bloatware.Count) {
                $selected += $bloatware[$idx-1].package
            }
        }
    }
    $selected = $selected | Select-Object -Unique
}

# Confirm removal
Write-Host ""
Write-ColorOutput Yellow "The following packages will be removed:"
foreach ($pkg in $selected) {
    $name = ($bloatware | Where-Object { $_.package -eq $pkg }).name
    Write-Output "  - $name"
}

$confirm = Read-Host "`nProceed with removal? (Y/N)"
if ($confirm -ne 'Y' -and $confirm -ne 'y') {
    Write-ColorOutput Green "Skipped bloatware removal."
    return
}

# Remove selected packages
foreach ($pkg in $selected) {
    Write-Output "Removing: $pkg"
    Get-AppxPackage -Name $pkg | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $pkg } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

Write-ColorOutput Green "`n✓ Bloatware removal complete!"
Write-ColorOutput Yellow "Note: Some apps may require a restart to fully disappear from Start Menu."
