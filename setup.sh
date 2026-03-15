#!/bin/bash
# setup.sh — Setup robotnet10-claude-workspace cho RobotNet10 workspace
# Usage: ./setup.sh [OPTIONS] /path/to/robotnet10
#
# Options:
#   --rules-only    Only copy rules/ and CLAUDE.md (no hooks, no commands)
#   --no-hooks      Copy everything except hooks (settings.json without hooks)
#   -h, --help      Show this help

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RULES_ONLY=false
NO_HOOKS=false
ROBOTNET10_PATH=""

# --- Parse arguments ---

while [[ $# -gt 0 ]]; do
    case "$1" in
        --rules-only)
            RULES_ONLY=true
            shift
            ;;
        --no-hooks)
            NO_HOOKS=true
            shift
            ;;
        -h|--help)
            echo "Usage: ./setup.sh [OPTIONS] /path/to/robotnet10"
            echo ""
            echo "Options:"
            echo "  --rules-only    Only copy rules/ and CLAUDE.md (no hooks, no commands)"
            echo "  --no-hooks      Copy everything except hooks"
            echo "  -h, --help      Show this help"
            exit 0
            ;;
        *)
            ROBOTNET10_PATH="$1"
            shift
            ;;
    esac
done

# --- Validation ---

if [ -z "$ROBOTNET10_PATH" ]; then
    echo "Usage: ./setup.sh [OPTIONS] /path/to/robotnet10"
    echo "Run ./setup.sh --help for options."
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

# Check python availability (needed for hooks)
if ! "$RULES_ONLY"; then
    if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
        echo "Warning: Neither python3 nor python found."
        echo "  Hooks in .claude/settings.json require Python to work."
        echo "  Install Python 3.x or use --rules-only to skip hooks."
        read -p "Continue without Python? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

# --- Backup existing settings ---

TARGET_CLAUDE="$ROBOTNET10_PATH/.claude"
BACKUP_LOCAL_SETTINGS=""

if [ -f "$TARGET_CLAUDE/settings.local.json" ]; then
    BACKUP_LOCAL_SETTINGS=$(mktemp)
    cp "$TARGET_CLAUDE/settings.local.json" "$BACKUP_LOCAL_SETTINGS"
    echo "Backed up settings.local.json"
fi

# --- Handle existing .claude/ ---

if [ -d "$TARGET_CLAUDE" ] || [ -L "$TARGET_CLAUDE" ]; then
    echo "Found existing .claude/ at $TARGET_CLAUDE"
    read -p "Replace it? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        # Cleanup backup temp file
        [ -n "$BACKUP_LOCAL_SETTINGS" ] && rm -f "$BACKUP_LOCAL_SETTINGS"
        exit 0
    fi
    rm -rf "$TARGET_CLAUDE"
fi

# --- Setup ---

if "$RULES_ONLY"; then
    # Selective: only CLAUDE.md + rules/
    echo "Installing rules-only mode..."
    mkdir -p "$TARGET_CLAUDE/rules"
    cp "$SCRIPT_DIR/.claude/CLAUDE.md" "$TARGET_CLAUDE/CLAUDE.md"
    cp "$SCRIPT_DIR/.claude/rules/"*.md "$TARGET_CLAUDE/rules/"
    echo "Installed: CLAUDE.md + $(ls "$TARGET_CLAUDE/rules/" | wc -l) rules"
else
    # Full install: symlink (preferred) or copy
    if ln -s "$SCRIPT_DIR/.claude" "$TARGET_CLAUDE" 2>/dev/null; then
        echo "Created symlink: $TARGET_CLAUDE -> $SCRIPT_DIR/.claude"
    else
        echo "Symlink failed (may need elevated permissions). Falling back to copy..."
        cp -r "$SCRIPT_DIR/.claude" "$TARGET_CLAUDE"
        echo "Copied .claude/ to $TARGET_CLAUDE (note: changes won't sync back to this repo)"
    fi

    # If --no-hooks, strip hooks from settings.json
    if "$NO_HOOKS" && [ -f "$TARGET_CLAUDE/settings.json" ]; then
        if command -v python3 &>/dev/null || command -v python &>/dev/null; then
            PYTHON_CMD=$(command -v python3 || command -v python)
            "$PYTHON_CMD" -c "
import json
with open('$TARGET_CLAUDE/settings.json', 'r') as f:
    data = json.load(f)
data.pop('hooks', None)
with open('$TARGET_CLAUDE/settings.json', 'w') as f:
    json.dump(data, f, indent=2)
"
            echo "Removed hooks from settings.json (--no-hooks)"
        else
            echo "Warning: Python not found, could not strip hooks. Edit settings.json manually."
        fi
    fi
fi

# --- Restore backup ---

if [ -n "$BACKUP_LOCAL_SETTINGS" ] && [ -f "$BACKUP_LOCAL_SETTINGS" ]; then
    if [ -L "$TARGET_CLAUDE" ]; then
        # Symlink mode — writing into the symlink would modify the context repo directory.
        # settings.local.json is user-specific and should NOT be committed there.
        echo ""
        echo "Warning: In symlink mode, settings.local.json cannot be restored automatically"
        echo "  (it would write into the context repo, not the workspace)."
        echo "  Your backup is saved at: $BACKUP_LOCAL_SETTINGS"
        echo "  To restore manually, copy it to your workspace .claude/ after switching to copy mode,"
        echo "  or add it at workspace level."
    else
        cp "$BACKUP_LOCAL_SETTINGS" "$TARGET_CLAUDE/settings.local.json"
        rm -f "$BACKUP_LOCAL_SETTINGS"
        echo "Restored settings.local.json from backup"
    fi
fi

# --- Verify ---

if [ -f "$TARGET_CLAUDE/CLAUDE.md" ]; then
    echo ""
    echo "Setup complete."
    echo ""
    echo "Next steps:"
    echo "  cd $ROBOTNET10_PATH"
    echo "  claude"
    echo "  /onboard"
    if "$RULES_ONLY"; then
        echo ""
        echo "Note: Only rules + CLAUDE.md installed. For full setup (hooks, commands):"
        echo "  ./setup.sh $ROBOTNET10_PATH"
    fi
else
    echo "Error: Setup completed but CLAUDE.md not found. Check paths."
    exit 1
fi
