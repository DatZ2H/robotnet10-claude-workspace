# Quick Start — 5 phut Setup

Huong dan setup nhanh `robotnet10-claude-workspace` cho developer moi.

---

## Yeu cau

- Git
- Claude Code CLI (`npm install -g @anthropic-ai/claude-code`)
- RobotNet10 workspace (clone tu GitLab noi bo)
- **Python 3.x** (can cho safety hooks — `python3` tren Linux, `python` tren Windows)

## Setup

### Option A: Full install — Symlink (khuyen nghi — Linux/macOS)

```bash
# 1. Clone context repo
git clone <robotnet10-claude-workspace-url> ~/robotnet10-claude-workspace

# 2. Chay setup script
cd ~/robotnet10-claude-workspace
./setup.sh /path/to/robotnet10

# 3. Mo Claude Code tai RobotNet10
cd /path/to/robotnet10
claude
```

### Option B: Full install — Symlink (Windows PowerShell)

```powershell
# 1. Clone context repo
git clone <robotnet10-claude-workspace-url> $HOME\robotnet10-claude-workspace

# 2. Chay setup script (Run as Administrator)
cd $HOME\robotnet10-claude-workspace
.\setup.ps1 -RobotNet10Path "C:\path\to\robotnet10"

# 3. Mo Claude Code tai RobotNet10
cd C:\path\to\robotnet10
claude
```

### Option C: Rules-only (khong hooks, khong commands)

```bash
./setup.sh --rules-only /path/to/robotnet10
# Windows:
.\setup.ps1 -RobotNet10Path "C:\path\to\robotnet10" -RulesOnly
```

### Option D: Full nhung bo hooks

```bash
./setup.sh --no-hooks /path/to/robotnet10
# Windows:
.\setup.ps1 -RobotNet10Path "C:\path\to\robotnet10" -NoHooks
```

### Option E: Manual copy

```bash
# Copy .claude/ vao RobotNet10 root
cp -r ~/robotnet10-claude-workspace/.claude/ /path/to/robotnet10/
```

## Xac nhan setup thanh cong

Khi mo Claude Code tai RobotNet10 directory, ban se thay:
- SessionStart hook in ra: `RobotNet10 | <branch> | <N> files modified`
- Claude tu dong doc `.claude/CLAUDE.md`
- Go `/onboard` → Claude hoi ban muon lam viec voi domain nao

## Su dung hang ngay

### Commands

| Lenh | Muc dich |
|------|---------|
| `/onboard` | Onboarding tuong tac — chon domain de bat dau |
| `/explain-domain SLAM` | Trace implementation cua mot domain cu the |
| `/safety-review` | Review safety-critical changes truoc commit |
| `/build all` | Build toan bo solution |
| `/build robotapp` | Build chi RobotApp |
| `/test-domain SLAM` | Chay tests cho SLAM domain |
| `/trace-vda5050 Order` | Trace VDA 5050 Order message flow |
| `/check-shared` | Kiem tra Shared/ backward compatibility |
| `/device-scaffold MyDevice` | Scaffold device moi theo pattern chuan |

### Rules tu dong

Khi ban edit files, Claude tu dong load rules phu hop:

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

Setup bao gom safety hooks tu dong:

- **PreToolUse**: Canh bao khi edit files trong safety-critical zones (Motion/, CANOpen/, CiA402/)
- **PostToolUse**: Nhac build solution khi edit Shared/ contracts
- **Deny rules**: Chan `rm -rf` va `dotnet ef database update`

Neu khong muon hooks, dung `--no-hooks` khi setup.

## Cap nhat context

```bash
cd ~/robotnet10-claude-workspace
git pull
```

Neu dung symlink, RobotNet10 workspace tu dong nhan context moi.
Neu dung copy, can chay lai setup script.

Xem [UPDATING.md](UPDATING.md) cho cac tinh huong nang cao (conflict resolution, contribute nguoc lai).

## Troubleshooting

| Van de | Giai phap |
|--------|-----------|
| Hook bao loi "python3 not found" | Cai Python 3.x hoac dung `--no-hooks` |
| Symlink khong tao duoc (Windows) | Chay PowerShell as Administrator, hoac script se fallback sang junction/copy |
| SessionStart khong hien status | Kiem tra `.claude/settings.json` co ton tai tai RobotNet10 workspace |
| Rules khong auto-load | Kiem tra glob patterns match voi file path ban dang edit |
