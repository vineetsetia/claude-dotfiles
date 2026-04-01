#!/bin/bash
# Claude dotfiles auto-sync agent
# Pulls remote changes, pushes local changes, notifies on updates
# Usage: Run via cron or Task Scheduler

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR" || exit 1

LOGFILE="$DOTFILES_DIR/.sync.log"
NOTIFY=${CLAUDE_DOTFILES_NOTIFY:-true}

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOGFILE"; }

# Copy live config files into dotfiles repo if they've changed
copy_if_changed() {
    local src="$1" dest="$2"
    if [ -f "$src" ] && [ ! -L "$src" ]; then
        if ! cmp -s "$src" "$dest" 2>/dev/null; then
            cp "$src" "$dest"
            log "UPDATED: copied $(basename "$src") from live config"
        fi
    fi
}

# Sync Claude settings
copy_if_changed "$HOME/.claude/settings.json" "$DOTFILES_DIR/.claude/settings.json"

# Sync Copilot settings
copy_if_changed "$HOME/.copilot/config.json" "$DOTFILES_DIR/.copilot/config.json"
copy_if_changed "$HOME/.copilot/permissions-config.json" "$DOTFILES_DIR/.copilot/permissions-config.json"

# Fetch remote
git fetch origin 2>/dev/null

# Check if remote has new commits
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/master 2>/dev/null || echo "$LOCAL")

if [ "$LOCAL" != "$REMOTE" ]; then
    # Pull remote changes
    git pull --rebase origin master >> "$LOGFILE" 2>&1
    if [ $? -eq 0 ]; then
        log "PULLED: synced from remote"
        if [ "$NOTIFY" = "true" ] && command -v notify-send &>/dev/null; then
            notify-send "Claude Dotfiles" "Settings updated from another device"
        fi
        # Windows toast notification
        if command -v powershell.exe &>/dev/null; then
            powershell.exe -Command "New-BurntToastNotification -Text 'Claude Dotfiles', 'Settings synced from another device'" 2>/dev/null
        fi
    else
        log "ERROR: pull failed, check manually"
    fi
fi

# Check for local changes
if ! git diff --quiet HEAD -- . 2>/dev/null || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    git add -A
    git commit -m "Auto-sync settings $(date '+%Y-%m-%d %H:%M')" >> "$LOGFILE" 2>&1
    git push origin master >> "$LOGFILE" 2>&1
    if [ $? -eq 0 ]; then
        log "PUSHED: local changes synced to remote"
    else
        log "ERROR: push failed, check manually"
    fi
else
    log "OK: no changes"
fi

# Trim log to last 100 lines
tail -100 "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
