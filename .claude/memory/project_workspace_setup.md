---
name: Workspace Setup
description: AI context repo is separate from source, symlinked into actual RobotNet10 source repo
type: project
---

The workspace `robotnet10-claude-workspace` is an AI context repo (docs + `.claude/` config) that is symlinked into the actual source repo. The source code lives in `srcs/RobotNet10/` (accessible via symlink). This means `.claude/` config files are version-controlled separately from source code.

**Why:** Allows iterating on AI tooling config without polluting the main source repo's git history.

**How to apply:** When creating/editing `.claude/` files, remember they are committed to this context repo, not the source repo. When referencing source paths, use relative paths from the workspace root (e.g., `srcs/RobotNet10/...`).
