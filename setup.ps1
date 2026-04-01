# Claude Code dotfiles setup script for Windows/PowerShell
# Run this on each new device to link settings

$dotfilesDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$claudeDir = "$env:USERPROFILE\.claude"

# Backup existing settings if present and not already a symlink
$settingsPath = "$claudeDir\settings.json"
if ((Test-Path $settingsPath) -and -not ((Get-Item $settingsPath).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    Write-Host "Backing up existing settings.json to settings.json.bak"
    Copy-Item $settingsPath "$claudeDir\settings.json.bak"
}

# Create .claude dir if needed
New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null

# Create symlink (requires admin or developer mode)
if (Test-Path $settingsPath) { Remove-Item $settingsPath }
New-Item -ItemType SymbolicLink -Path $settingsPath -Target "$dotfilesDir\.claude\settings.json"
Write-Host "Linked: $settingsPath -> $dotfilesDir\.claude\settings.json"

# Add claude resume alias to PowerShell profile
$profilePath = $PROFILE
if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}
if (-not (Select-String -Path $profilePath -Pattern "claude --resume" -Quiet -ErrorAction SilentlyContinue)) {
    Add-Content $profilePath "`n# Claude Code - always resume`nfunction claude { claude.exe --resume @args }"
    Write-Host "Added resume function to $profilePath"
} else {
    Write-Host "Resume alias already exists in $profilePath"
}

Write-Host "Done! Restart your shell to apply changes."
