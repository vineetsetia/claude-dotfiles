#!/bin/bash
# Claude Code dotfiles setup script
# Run this on each new device to link settings

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# Backup existing settings if present
if [ -f "$CLAUDE_DIR/settings.json" ] && [ ! -L "$CLAUDE_DIR/settings.json" ]; then
    echo "Backing up existing settings.json to settings.json.bak"
    cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak"
fi

# Create .claude dir if needed
mkdir -p "$CLAUDE_DIR"

# Symlink settings.json
ln -sf "$DOTFILES_DIR/.claude/settings.json" "$CLAUDE_DIR/settings.json"
echo "Linked: $CLAUDE_DIR/settings.json -> $DOTFILES_DIR/.claude/settings.json"

# Add claude resume alias to shell profile
add_alias() {
    local profile="$1"
    if [ -f "$profile" ] && grep -q "alias claude=" "$profile" 2>/dev/null; then
        echo "Alias already exists in $profile"
    elif [ -f "$profile" ]; then
        echo "" >> "$profile"
        echo "# Claude Code - always resume" >> "$profile"
        echo "alias claude='claude --resume'" >> "$profile"
        echo "Added resume alias to $profile"
    fi
}

add_alias "$HOME/.bashrc"
add_alias "$HOME/.zshrc"

echo "Done! Restart your shell or run: source ~/.bashrc"
