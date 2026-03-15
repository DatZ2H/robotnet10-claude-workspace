# Quick Start — 5 phut Setup

Hướng dẫn setup nhanh `robotnet10-ai-context` cho developer mới.

---

## Yêu cầu

- Git
- Claude Code CLI (`npm install -g @anthropic-ai/claude-code`)
- RobotNet10 workspace (clone từ GitLab nội bộ)

## Setup

### Option A: Symlink (khuyến nghị — Linux/macOS)

```bash
# 1. Clone context repo
git clone <robotnet10-ai-context-url> ~/robotnet10-ai-context

# 2. Chạy setup script
cd ~/robotnet10-ai-context
./setup.sh /path/to/robotnet10

# 3. Mở Claude Code tại RobotNet10
cd /path/to/robotnet10
claude
```

### Option B: Symlink (Windows PowerShell)

```powershell
# 1. Clone context repo
git clone <robotnet10-ai-context-url> $HOME\robotnet10-ai-context

# 2. Chạy setup script (Run as Administrator)
cd $HOME\robotnet10-ai-context
.\setup.ps1 -RobotNet10Path "C:\path\to\robotnet10"

# 3. Mở Claude Code tại RobotNet10
cd C:\path\to\robotnet10
claude
```

### Option C: Manual copy

```bash
# Copy .claude/ vào RobotNet10 root
cp -r ~/robotnet10-ai-context/.claude/ /path/to/robotnet10/
```

## Xác nhận setup thành công

Khi mở Claude Code tại RobotNet10 directory, bạn sẽ thấy:
- SessionStart hook in ra: `RobotNet10 | <branch> | <N> files modified`
- Claude tự động đọc `.claude/CLAUDE.md`
- Gõ `/onboard` → Claude hỏi bạn muốn làm việc với domain nào

## Sử dụng hàng ngày

| Lệnh | Mục đích |
|------|---------|
| `/onboard` | Onboarding tương tác — chọn domain để bắt đầu |
| `/explain-domain SLAM` | Trace implementation của một domain cụ thể |

## Rules tự động

Khi bạn edit files, Claude tự động load rules phù hợp:

| Edit files trong... | Rule auto-load |
|--------------------|---------------|
| `CartographerSharp/`, `CeresSharp/`, `SLAM/` | `slam-cartographer-context.md` |
| `RobotApp/` | `robotapp-context.md` |
| `FleetManager/` | `fleetmanager-context.md` |
| `Motion/`, `CANOpen/`, `CiA402/` | `safety-critical.md` |
| `Shared/` | `shared-contracts.md` |
| Test projects | `test-standards.md` |

## Cập nhật context

```bash
cd ~/robotnet10-ai-context
git pull
```

Nếu dùng symlink, RobotNet10 workspace tự động nhận context mới.
Nếu dùng copy, cần copy lại `.claude/`.
