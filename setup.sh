#!/bin/bash
# setup.sh — Setup robotnet10-ai-context cho RobotNet10 workspace
# Usage: ./setup.sh /path/to/robotnet10

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROBOTNET10_PATH="${1:-}"

# --- Validation ---

if [ -z "$ROBOTNET10_PATH" ]; then
    echo "Usage: ./setup.sh /path/to/robotnet10"
    echo ""
    echo "  /path/to/robotnet10  Path to RobotNet10 workspace (containing .slnx)"
    exit 1
fi

if [ ! -d "$ROBOTNET10_PATH" ]; then
    echo "Error: Directory not found: $ROBOTNET10_PATH"
    exit 1
fi

# Check if it looks like a RobotNet10 workspace
if [ ! -f "$ROBOTNET10_PATH/srcs/RobotNet10/RobotNet10.slnx" ] && [ ! -f "$ROBOTNET10_PATH/RobotNet10.slnx" ]; then
    echo "Warning: Could not find RobotNet10.slnx in expected locations."
    echo "  Checked: $ROBOTNET10_PATH/srcs/RobotNet10/RobotNet10.slnx"
    echo "  Checked: $ROBOTNET10_PATH/RobotNet10.slnx"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# --- Setup ---

TARGET_CLAUDE="$ROBOTNET10_PATH/.claude"

if [ -d "$TARGET_CLAUDE" ] || [ -L "$TARGET_CLAUDE" ]; then
    echo "Found existing .claude/ at $TARGET_CLAUDE"
    read -p "Replace it? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
    rm -rf "$TARGET_CLAUDE"
fi

# Create symlink (fallback to copy if symlink fails, e.g. no permission)
if ln -s "$SCRIPT_DIR/.claude" "$TARGET_CLAUDE" 2>/dev/null; then
    echo "Created symlink: $TARGET_CLAUDE -> $SCRIPT_DIR/.claude"
else
    echo "Symlink failed (may need elevated permissions). Falling back to copy..."
    cp -r "$SCRIPT_DIR/.claude" "$TARGET_CLAUDE"
    echo "Copied .claude/ to $TARGET_CLAUDE (note: changes won't sync back to this repo)"
fi

# Verify
if [ -f "$TARGET_CLAUDE/CLAUDE.md" ]; then
    echo ""
    echo "Setup complete."
    echo ""
    echo "Next steps:"
    echo "  cd $ROBOTNET10_PATH"
    echo "  claude"
    echo "  /onboard"
else
    echo "Error: Symlink created but CLAUDE.md not found. Check paths."
    exit 1
fi
