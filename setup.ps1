# setup.ps1 — Setup robotnet10-claude-workspace cho RobotNet10 workspace (Windows)
# Usage: .\setup.ps1 -RobotNet10Path "C:\path\to\robotnet10" [-RulesOnly] [-NoHooks]
# Note: Requires Administrator privileges for symlinks (junction fallback available)

param(
    [Parameter(Mandatory=$true)]
    [string]$RobotNet10Path,

    [switch]$RulesOnly,
    [switch]$NoHooks
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- Validation ---

if (-not (Test-Path $RobotNet10Path -PathType Container)) {
    Write-Error "Directory not found: $RobotNet10Path"
    exit 1
}

# Check if it looks like a RobotNet10 workspace
$slnxPath1 = Join-Path $RobotNet10Path "srcs\RobotNet10\RobotNet10.slnx"
$slnxPath2 = Join-Path $RobotNet10Path "RobotNet10.slnx"

if (-not (Test-Path $slnxPath1) -and -not (Test-Path $slnxPath2)) {
    Write-Warning "Could not find RobotNet10.slnx in expected locations."
    Write-Warning "  Checked: $slnxPath1"
    Write-Warning "  Checked: $slnxPath2"
    $continue = Read-Host "Continue anyway? [y/N]"
    if ($continue -ne "y" -and $continue -ne "Y") {
        exit 1
    }
}

# Check python availability (needed for hooks)
if (-not $RulesOnly) {
    $pythonCmd = $null
    if (Get-Command python3 -ErrorAction SilentlyContinue) {
        $pythonCmd = "python3"
    } elseif (Get-Command python -ErrorAction SilentlyContinue) {
        $pythonCmd = "python"
    }

    if (-not $pythonCmd) {
        Write-Warning "Neither python3 nor python found."
        Write-Warning "  Hooks in .claude/settings.json require Python to work."
        Write-Warning "  Install Python 3.x or use -RulesOnly to skip hooks."
        $continue = Read-Host "Continue without Python? [y/N]"
        if ($continue -ne "y" -and $continue -ne "Y") {
            exit 1
        }
    }
}

# --- Backup existing settings ---

$TargetClaude = Join-Path $RobotNet10Path ".claude"
$SourceClaude = Join-Path $ScriptDir ".claude"
$BackupLocalSettings = $null

$localSettingsPath = Join-Path $TargetClaude "settings.local.json"
if (Test-Path $localSettingsPath) {
    $BackupLocalSettings = [System.IO.Path]::GetTempFileName()
    Copy-Item $localSettingsPath $BackupLocalSettings
    Write-Host "Backed up settings.local.json"
}

# --- Handle existing .claude/ ---

if (Test-Path $TargetClaude) {
    Write-Host "Found existing .claude/ at $TargetClaude"
    $replace = Read-Host "Replace it? [y/N]"
    if ($replace -ne "y" -and $replace -ne "Y") {
        Write-Host "Aborted."
        if ($BackupLocalSettings) { Remove-Item $BackupLocalSettings -Force }
        exit 0
    }

    # Remove existing (could be symlink/junction or directory)
    $item = Get-Item $TargetClaude -Force
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        $item.Delete()
    } else {
        Remove-Item $TargetClaude -Recurse -Force
    }
}

# --- Setup ---

if ($RulesOnly) {
    # Selective: only CLAUDE.md + rules/
    Write-Host "Installing rules-only mode..."
    New-Item -ItemType Directory -Path (Join-Path $TargetClaude "rules") -Force | Out-Null
    Copy-Item (Join-Path $SourceClaude "CLAUDE.md") (Join-Path $TargetClaude "CLAUDE.md")
    Copy-Item (Join-Path $SourceClaude "rules\*.md") (Join-Path $TargetClaude "rules\") -Force
    $ruleCount = (Get-ChildItem (Join-Path $TargetClaude "rules") -Filter "*.md").Count
    Write-Host "Installed: CLAUDE.md + $ruleCount rules"
} else {
    # Full install: symlink (preferred) -> junction (fallback) -> copy (last resort)
    try {
        New-Item -ItemType SymbolicLink -Path $TargetClaude -Target $SourceClaude | Out-Null
        Write-Host "Created symlink: $TargetClaude -> $SourceClaude"
    } catch {
        Write-Warning "Symlink creation failed (requires Administrator privileges)."
        Write-Host "Falling back to directory junction..."

        try {
            cmd /c "mklink /J `"$TargetClaude`" `"$SourceClaude`"" | Out-Null
            Write-Host "Created junction: $TargetClaude -> $SourceClaude"
        } catch {
            Write-Warning "Junction also failed. Copying files instead..."
            Copy-Item -Path $SourceClaude -Destination $TargetClaude -Recurse
            Write-Host "Copied .claude/ to $TargetClaude"
            Write-Warning "Note: Updates to context repo will NOT auto-sync. Run setup again after git pull."
        }
    }

    # If -NoHooks, strip hooks from settings.json
    if ($NoHooks) {
        $settingsPath = Join-Path $TargetClaude "settings.json"
        if ((Test-Path $settingsPath) -and $pythonCmd) {
            & $pythonCmd -c @"
import json
with open(r'$settingsPath', 'r') as f:
    data = json.load(f)
data.pop('hooks', None)
with open(r'$settingsPath', 'w') as f:
    json.dump(data, f, indent=2)
"@
            Write-Host "Removed hooks from settings.json (-NoHooks)"
        }
    }
}

# --- Restore backup ---

if ($BackupLocalSettings -and (Test-Path $BackupLocalSettings)) {
    $targetItem = Get-Item $TargetClaude -Force -ErrorAction SilentlyContinue
    $isSymlink = $targetItem -and ($targetItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)

    if ($isSymlink) {
        # Symlink/junction mode — writing into it would modify the context repo directory.
        # settings.local.json is user-specific and should NOT be committed there.
        Write-Host ""
        Write-Warning "In symlink mode, settings.local.json cannot be restored automatically"
        Write-Warning "  (it would write into the context repo, not the workspace)."
        Write-Host "  Your backup is saved at: $BackupLocalSettings"
        Write-Host "  To restore manually, copy it to your workspace .claude/ after switching to copy mode."
    } else {
        Copy-Item $BackupLocalSettings (Join-Path $TargetClaude "settings.local.json") -Force
        Remove-Item $BackupLocalSettings -Force
        Write-Host "Restored settings.local.json from backup"
    }
}

# --- Verify ---

$claudeMd = Join-Path $TargetClaude "CLAUDE.md"
if (Test-Path $claudeMd) {
    Write-Host ""
    Write-Host "Setup complete." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  cd $RobotNet10Path"
    Write-Host "  claude"
    Write-Host "  /onboard"
    if ($RulesOnly) {
        Write-Host ""
        Write-Host "Note: Only rules + CLAUDE.md installed. For full setup (hooks, commands):"
        Write-Host "  .\setup.ps1 -RobotNet10Path `"$RobotNet10Path`""
    }
} else {
    Write-Error "Setup completed but CLAUDE.md not found. Check paths."
    exit 1
}
