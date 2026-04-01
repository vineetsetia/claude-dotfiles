# Claude Code Dotfiles - Setup Guide

## What This Does
- Syncs your Claude Code `settings.json` across all devices via Git
- Auto-syncs every 15 minutes in the background
- Syncs on every Claude Code session start
- Sends a desktop notification when settings are updated from another device

## Setup on a New Device

### Step 1: Clone the repo
```bash
git clone https://github.com/vineetsetia/claude-dotfiles.git ~/claude/dotfiles
```
Or on Windows:
```powershell
git clone https://github.com/vineetsetia/claude-dotfiles.git C:\Users\vineset\claude\dotfiles
```

### Step 2: Run the setup script

**Windows (PowerShell as Admin):**
```powershell
cd C:\Users\vineset\claude\dotfiles
powershell -ExecutionPolicy Bypass -File setup.ps1
```

**Bash / WSL / Mac / Linux:**
```bash
cd ~/claude/dotfiles
chmod +x setup.sh
./setup.sh
```

This will:
- Symlink `settings.json` into `~/.claude/`
- Add a `claude --resume` alias to your shell

### Step 3: Set up auto-sync (every 15 minutes)

**Windows (PowerShell as Admin):**
```powershell
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-ExecutionPolicy Bypass -WindowStyle Hidden -File C:\Users\vineset\claude\dotfiles\sync.ps1'
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration (New-TimeSpan -Days 9999)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName 'ClaudeDotfilesSync' -Action $action -Trigger $trigger -Settings $settings -Description 'Sync Claude Code settings across devices every 15 minutes' -Force
```

**Mac / Linux (cron):**
```bash
(crontab -l 2>/dev/null; echo "*/15 * * * * bash $HOME/claude/dotfiles/sync.sh") | crontab -
```

### Step 4: Verify
```bash
# Check sync log
cat ~/claude/dotfiles/.sync.log

# Manual sync test
bash ~/claude/dotfiles/sync.sh
```

## How It Works
- `sync.sh` / `sync.ps1` runs every 15 min and on session start
- It pulls remote changes first, then pushes local changes
- Desktop notifications fire when settings arrive from another device
- The SessionStart hook in `settings.json` triggers a sync when you open Claude Code
- Logs are kept in `.sync.log` (auto-trimmed to 100 lines)

## Troubleshooting
- **Merge conflicts**: `cd ~/claude/dotfiles && git status` — resolve manually
- **Push failures**: Make sure you have write access to the repo on this device
- **No notifications**: Windows toast notifications require the app identity; fallback uses BalloonTip
