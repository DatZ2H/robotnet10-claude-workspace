# Quick Start — 5 phút Setup

Hướng dẫn setup nhanh `robotnet10-claude-workspace` cho developer mới.

---

## Yêu cầu

- Git
- Claude Code CLI (`npm install -g @anthropic-ai/claude-code`)
- RobotNet10 workspace (clone từ GitLab nội bộ)
- **Python 3.x** (cần cho safety hooks — `python3` trên Linux, `python` trên Windows)

## Setup

### Option A: Full install — Symlink (khuyên nghị — Linux/macOS)

```bash
# 1. Clone context repo
git clone <robotnet10-claude-workspace-url> ~/robotnet10-claude-workspace

# 2. Chạy setup script
cd ~/robotnet10-claude-workspace
./setup.sh /path/to/robotnet10

# 3. Mở Claude Code tại RobotNet10
cd /path/to/robotnet10
claude
```

### Option B: Full install — Symlink (Windows PowerShell)

```powershell
# 1. Clone context repo
git clone <robotnet10-claude-workspace-url> $HOME\robotnet10-claude-workspace

# 2. Chạy setup script (Run as Administrator)
cd $HOME\robotnet10-claude-workspace
.\setup.ps1 -RobotNet10Path "C:\path\to\robotnet10"

# 3. Mở Claude Code tại RobotNet10
cd C:\path\to\robotnet10
claude
```

### Option C: Rules-only (không hooks, không commands)

```bash
./setup.sh --rules-only /path/to/robotnet10
# Windows:
.\setup.ps1 -RobotNet10Path "C:\path\to\robotnet10" -RulesOnly
```

### Option D: Full nhưng bỏ hooks

```bash
./setup.sh --no-hooks /path/to/robotnet10
# Windows:
.\setup.ps1 -RobotNet10Path "C:\path\to\robotnet10" -NoHooks
```

### Option E: Manual copy

```bash
# Copy .claude/ vào RobotNet10 root
cp -r ~/robotnet10-claude-workspace/.claude/ /path/to/robotnet10/
```

## Xác nhận setup thành công

Khi mở Claude Code tại RobotNet10 directory, bạn sẽ thấy:
- SessionStart hook in ra: `RobotNet10 | <branch> | <N> files modified`
- Claude tự động đọc `.claude/CLAUDE.md`
- Gõ `/onboard` → Claude hỏi bạn muốn làm việc với domain nào

## Sử dụng hàng ngày

### Commands

| Lệnh | Mục đích |
|------|---------|
| `/onboard` | Onboarding tương tác — chọn domain để bắt đầu |
| `/explain-domain SLAM` | Trace implementation của một domain cụ thể |
| `/safety-review` | Review safety-critical changes trước commit |
| `/build all` | Build toàn bộ solution |
| `/build robotapp` | Build chỉ RobotApp |
| `/test-domain SLAM` | Chạy tests cho SLAM domain |
| `/trace-vda5050 Order` | Trace VDA 5050 Order message flow |
| `/check-shared` | Kiểm tra Shared/ backward compatibility |
| `/device-scaffold MyDevice` | Scaffold device mới theo pattern chuẩn |

### Rules tự động

Khi bạn edit files, Claude tự động load rules phù hợp:

| Edit files trong... | Rule auto-load |
|--------------------|---------------|
| `CartographerSharp/`, `CeresSharp/`, `SLAM/`, `Localization/` | `slam-cartographer-context.md` |
| `RobotApp/` | `robotapp-context.md` |
| `FleetManager/` | `fleetmanager-context.md` |
| `Motion/`, `CANOpen/`, `CiA402/`, `Services/Navigation/`, `Services/State/` | `safety-critical.md` |
| `Shared/` | `shared-contracts.md` |
| `*.Client/`, `Components/` | `blazor-ui.md` |
| `MqttConnection/`, `RobotConnections/` | `mqtt-communication.md` |
| Test projects | `test-standards.md` |

### Safety Hooks

Setup bao gồm safety hooks tự động:

- **PreToolUse**: Cảnh báo khi edit files trong safety-critical zones (Motion/, CANOpen/, CiA402/)
- **PostToolUse**: Nhắc build solution khi edit Shared/ contracts
- **Deny rules**: Chặn `rm -rf` và `dotnet ef database update`

Nếu không muốn hooks, dùng `--no-hooks` khi setup.

## Cập nhật context

```bash
cd ~/robotnet10-claude-workspace
git pull
```

Nếu dùng symlink, RobotNet10 workspace tự động nhận context mới.
Nếu dùng copy, cần chạy lại setup script.

Xem [UPDATING.md](UPDATING.md) cho các tình huống nâng cao (conflict resolution, contribute ngược lại).

## Troubleshooting

| Vấn đề | Giải pháp |
|--------|-----------|
| Hook báo lỗi "python3 not found" | Cài Python 3.x hoặc dùng `--no-hooks` |
| Symlink không tạo được (Windows) | Chạy PowerShell as Administrator, hoặc script sẽ fallback sang junction/copy |
| SessionStart không hiện status | Kiểm tra `.claude/settings.json` có tồn tại tại RobotNet10 workspace |
| Rules không auto-load | Kiểm tra glob patterns match với file path bạn đang edit |
