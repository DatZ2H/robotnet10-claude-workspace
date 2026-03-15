# setup.ps1 — Setup robotnet10-ai-context cho RobotNet10 workspace (Windows)
# Usage: .\setup.ps1 -RobotNet10Path "C:\path\to\robotnet10"
# Note: Requires Administrator privileges for symlinks

param(
    [Parameter(Mandatory=$true)]
    [string]$RobotNet10Path
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

# --- Setup ---

$TargetClaude = Join-Path $RobotNet10Path ".claude"
$SourceClaude = Join-Path $ScriptDir ".claude"

if (Test-Path $TargetClaude) {
    Write-Host "Found existing .claude/ at $TargetClaude"
    $replace = Read-Host "Replace it? [y/N]"
    if ($replace -ne "y" -and $replace -ne "Y") {
        Write-Host "Aborted."
        exit 0
    }

    # Remove existing (could be symlink or directory)
    $item = Get-Item $TargetClaude -Force
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        # It's a symlink
        $item.Delete()
    } else {
        Remove-Item $TargetClaude -Recurse -Force
    }
}

# Try to create symlink (requires admin)
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

# Verify
$claudeMd = Join-Path $TargetClaude "CLAUDE.md"
if (Test-Path $claudeMd) {
    Write-Host ""
    Write-Host "Setup complete." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  cd $RobotNet10Path"
    Write-Host "  claude"
    Write-Host "  /onboard"
} else {
    Write-Error "Setup completed but CLAUDE.md not found. Check paths."
    exit 1
}
