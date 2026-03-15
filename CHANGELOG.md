# Changelog

## [0.9.0] — 2026-03-15

Pre-release version of the RobotNet10 Claude Workspace. Core features complete, minor issues being tracked.

### Added
- **8 auto-load rules**: safety-critical, robotapp-context, fleetmanager-context, slam-cartographer-context, shared-contracts, test-standards, blazor-ui, mqtt-communication
- **8 workflow commands**: /onboard, /explain-domain, /safety-review, /build, /test-domain, /trace-vda5050, /check-shared, /device-scaffold
- **Safety hooks**: PreToolUse warning for safety-critical zones, PostToolUse reminder for Shared/ changes
- **Deny rules**: Block `rm -rf` and `dotnet ef database update`
- **Memory system**: Auto-learning user context across sessions (user-specific files gitignored)
- **Selective adoption**: `--rules-only` and `--no-hooks` options in setup scripts
- **72 domain docs**: SLAM, Navigation, VDA 5050, Motor Control, Fleet Management, etc.
- **UPDATING.md**: Sync workflow guide for team adoption

### Fixed
- Setup scripts now backup and restore `settings.local.json` before replacing `.claude/`
- Hooks use portable Python detection (`python3` || `python`) for Windows compatibility
- User-specific memory files untracked and gitignored (no more personal data leaks)

### Changed
- README.md rewritten with accurate stats (43 projects), all 8 rules/commands, selective adoption guide
- QUICKSTART.md updated with prerequisites (Python 3.x), all setup options, troubleshooting
- MEMORY.md converted to empty template for team use
