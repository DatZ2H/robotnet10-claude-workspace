# RobotNet10 Claude Workspace

Gói context cho [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — giúp AI hiểu RobotNet10 codebase (43 projects C# .NET 10, AMR fleet management, Phenikaa-X Robotics) mà không cần giải thích lại từ đầu mỗi session.

> [!IMPORTANT]
> Repo này **không chứa source code**. Nó chứa tài liệu, rules, hooks, và commands mà bạn gắn vào RobotNet10 workspace.

## Cách hoạt động

Claude Code tự động đọc folder `.claude/` tại root của workspace. Repo này cung cấp folder `.claude/` đã cấu hình sẵn cho RobotNet10:

```
RobotNet10 workspace (source code)
├── srcs/RobotNet10/...
├── ...
└── .claude/              ← Bạn đặt folder này vào đây
    ├── CLAUDE.md         ← Claude đọc file này MỌI session (project context)
    ├── settings.json     ← Permissions, safety hooks, deny rules
    ├── rules/            ← Auto-load khi edit file khớp pattern
    └── commands/         ← Gõ /tên-command để dùng
```

**Khi nào Claude load gì:**

| Thành phần | Khi nào load | Ví dụ |
|------------|-------------|-------|
| `CLAUDE.md` | **Mọi session** — luôn luôn | Claude biết kiến trúc, domain map, build commands |
| `rules/*.md` | **Tự động** khi edit file khớp glob pattern | Edit `Motion/Kinematics.cs` → load `safety-critical.md` |
| `commands/*.md` | **Khi bạn gõ** `/tên-command` | Gõ `/safety-review` → Claude chạy safety checklist |
| `settings.json` | **Mọi session** — hooks chạy tự động | Cảnh báo khi edit safety-critical files |
| `docs/` | **Không tự load** — Claude tra cứu khi cần | `/explain-domain SLAM` → Claude đọc docs/CartographerSharp/ |

---

## Cài đặt

### Option A: Script tự động (cài tất cả)

```bash
git clone https://github.com/DatZ2H/robotnet10-claude-workspace.git ~/robotnet10-claude-workspace
cd ~/robotnet10-claude-workspace
./setup.sh /path/to/robotnet10        # Linux/macOS
.\setup.ps1 -RobotNet10Path "C:\path\to\robotnet10"  # Windows (cần Admin cho symlink)
```

Script tạo symlink `.claude/` → context repo. Thay đổi trong context repo tự đồng bộ.

Các option của script:

| Flag | Tác dụng |
|------|---------|
| *(không flag)* | Cài tất cả qua symlink (thay đổi tự đồng bộ) |
| `--rules-only` | Chỉ **copy** `CLAUDE.md` + `rules/` (không symlink, không hooks, không commands) |
| `--no-hooks` | Symlink tất cả nhưng bỏ hooks trong settings.json |

---

### Option B: Cài đặt thủ công (chọn từng thành phần)

Nếu bạn muốn kiểm soát chính xác những gì được cài, làm theo các bước dưới đây.

**Yêu cầu:** Đã clone repo này về máy.

```bash
git clone https://github.com/DatZ2H/robotnet10-claude-workspace.git ~/robotnet10-claude-workspace
```

Các lệnh dưới đây dùng bash syntax. Trên Windows, dùng Git Bash hoặc WSL.

Gán biến `$WORKSPACE` trước khi bắt đầu:

```bash
WORKSPACE=/path/to/your/robotnet10  # Thay bằng đường dẫn thực tế
```

#### Bước 1 (bắt buộc): Tạo folder `.claude/` và copy `CLAUDE.md`

Đây là file duy nhất **bắt buộc**. Không có nó, Claude không hiểu project.

```bash
mkdir -p $WORKSPACE/.claude
cp ~/robotnet10-claude-workspace/.claude/CLAUDE.md $WORKSPACE/.claude/
```

Sau bước này bạn đã có thể dùng Claude Code với RobotNet10. Các bước tiếp theo là tuỳ chọn.

#### Bước 2 (khuyên dùng): Copy rules theo domain bạn làm việc

Rules tự động load khi bạn edit file khớp pattern. Chọn rules phù hợp với domain của bạn:

```bash
mkdir -p $WORKSPACE/.claude/rules
```

**Rules nền tảng** — nên copy bất kể bạn làm domain nào:

```bash
# Safety — bảo vệ motor control, SLAM (tránh va chạm vật lý)
cp ~/robotnet10-claude-workspace/.claude/rules/safety-critical.md $WORKSPACE/.claude/rules/

# Shared contracts — cảnh báo khi edit code ảnh hưởng cả RobotApp + FleetManager
cp ~/robotnet10-claude-workspace/.claude/rules/shared-contracts.md $WORKSPACE/.claude/rules/

# Test standards — NUnit + xUnit conventions (cần khi viết tests)
cp ~/robotnet10-claude-workspace/.claude/rules/test-standards.md $WORKSPACE/.claude/rules/
```

**Rules theo domain** — chỉ copy cái bạn cần:

```bash
# Nếu làm RobotApp (robot-side, Ubuntu, SignalR hubs, device drivers)
cp ~/robotnet10-claude-workspace/.claude/rules/robotapp-context.md $WORKSPACE/.claude/rules/

# Nếu làm FleetManager (server-side, Docker, SQL Server, VDA 5050)
cp ~/robotnet10-claude-workspace/.claude/rules/fleetmanager-context.md $WORKSPACE/.claude/rules/

# Nếu làm SLAM / Localization (CartographerSharp, CeresSharp)
cp ~/robotnet10-claude-workspace/.claude/rules/slam-cartographer-context.md $WORKSPACE/.claude/rules/

# Nếu làm Blazor UI (Components, Client projects)
cp ~/robotnet10-claude-workspace/.claude/rules/blazor-ui.md $WORKSPACE/.claude/rules/

# Nếu làm MQTT / VDA 5050 communication
cp ~/robotnet10-claude-workspace/.claude/rules/mqtt-communication.md $WORKSPACE/.claude/rules/
```

Hoặc copy tất cả nếu không muốn chọn:

```bash
cp ~/robotnet10-claude-workspace/.claude/rules/*.md $WORKSPACE/.claude/rules/
```

#### Bước 3 (tuỳ chọn): Copy commands

Commands là shortcuts gõ trong Claude Code. Chọn cái bạn dùng:

```bash
mkdir -p $WORKSPACE/.claude/commands
```

```bash
# Onboarding — Claude hỏi bạn muốn làm domain nào, rồi giải thích
cp ~/robotnet10-claude-workspace/.claude/commands/onboard.md $WORKSPACE/.claude/commands/

# Safety review — scan git diff, kiểm tra safety checklist trước commit
cp ~/robotnet10-claude-workspace/.claude/commands/safety-review.md $WORKSPACE/.claude/commands/

# Build shortcut — dotnet build không cần nhớ path
cp ~/robotnet10-claude-workspace/.claude/commands/build.md $WORKSPACE/.claude/commands/

# Test theo domain — map domain name → đúng test project + framework
cp ~/robotnet10-claude-workspace/.claude/commands/test-domain.md $WORKSPACE/.claude/commands/

# Giải thích domain — trace concept qua source code
cp ~/robotnet10-claude-workspace/.claude/commands/explain-domain.md $WORKSPACE/.claude/commands/

# Trace VDA 5050 message flow (Order/State/InstantAction)
cp ~/robotnet10-claude-workspace/.claude/commands/trace-vda5050.md $WORKSPACE/.claude/commands/

# Kiểm tra backward compatibility khi edit Shared/
cp ~/robotnet10-claude-workspace/.claude/commands/check-shared.md $WORKSPACE/.claude/commands/

# Scaffold device mới theo DeviceBase pattern
cp ~/robotnet10-claude-workspace/.claude/commands/device-scaffold.md $WORKSPACE/.claude/commands/
```

Hoặc copy tất cả:

```bash
cp ~/robotnet10-claude-workspace/.claude/commands/*.md $WORKSPACE/.claude/commands/
```

#### Bước 4 (tuỳ chọn): Copy settings.json (hooks + permissions)

File này chứa safety hooks (cảnh báo khi edit motor control code) và deny rules (chặn `rm -rf`). **Cần Python 3.x** để hooks hoạt động.

```bash
cp ~/robotnet10-claude-workspace/.claude/settings.json $WORKSPACE/.claude/
```

Nội dung settings.json:

| Thành phần | Tác dụng |
|------------|---------|
| `permissions.allow` | Tự động cho phép `dotnet build/test/run`, `git`, `docker` |
| `permissions.deny` | Chặn `rm -rf` và `dotnet ef database update` |
| `hooks.SessionStart` | Hiển thị branch + số file modified khi mở session |
| `hooks.PreToolUse` | Cảnh báo khi edit files trong Motion/, CANOpen/, CiA402/ |
| `hooks.PostToolUse` | Nhắc build solution khi edit Shared/ contracts |

Nếu bạn không muốn hooks nhưng muốn permissions, tạo file thủ công:

```json
{
  "permissions": {
    "allow": [
      "Bash(dotnet build:*)",
      "Bash(dotnet test:*)",
      "Bash(dotnet run:*)",
      "Bash(git:*)"
    ],
    "deny": [
      "Bash(rm -rf:*)"
    ]
  }
}
```

#### Bước 5 (tuỳ chọn): Copy docs

`docs/` không tự load — Claude chỉ đọc khi bạn hỏi hoặc dùng `/explain-domain`. Copy theo domain bạn quan tâm:

```bash
# Copy docs vào workspace (hoặc để tại context repo, Claude tìm được nếu dùng symlink)
mkdir -p $WORKSPACE/docs

# Docs root-level (documentation hub, index, quick start)
cp ~/robotnet10-claude-workspace/docs/README.md $WORKSPACE/docs/
cp ~/robotnet10-claude-workspace/docs/DOCUMENTATION_MAP.md $WORKSPACE/docs/
cp ~/robotnet10-claude-workspace/docs/QUICK_START.md $WORKSPACE/docs/

# SLAM domain (13 files — thuật toán, tuning, Ceres solver)
cp -r ~/robotnet10-claude-workspace/docs/CartographerSharp/ $WORKSPACE/docs/
cp -r ~/robotnet10-claude-workspace/docs/Localization/ $WORKSPACE/docs/

# RobotApp (2 files — state management, overview)
cp -r ~/robotnet10-claude-workspace/docs/robotapp/ $WORKSPACE/docs/

# FleetManager (12 files — traffic control, robot connections, VDA 5050)
cp -r ~/robotnet10-claude-workspace/docs/fleetmanager/ $WORKSPACE/docs/

# Map Editor (16 files — VDMA LIF, path finding, SVG canvas)
cp -r ~/robotnet10-claude-workspace/docs/MapEditor/ $WORKSPACE/docs/

# Script Engine (13 files — compilation, missions, security)
cp -r ~/robotnet10-claude-workspace/docs/ScriptEngine/ $WORKSPACE/docs/

# Navigation tuning (7 files)
cp -r ~/robotnet10-claude-workspace/docs/RobotApp-TunningNav/ $WORKSPACE/docs/

# VDA 5050 protocol
cp -r ~/robotnet10-claude-workspace/docs/vda5050/ $WORKSPACE/docs/

# Architecture + Development guides
cp -r ~/robotnet10-claude-workspace/docs/architecture/ $WORKSPACE/docs/
cp -r ~/robotnet10-claude-workspace/docs/development/ $WORKSPACE/docs/

# AI agent orientation
cp -r ~/robotnet10-claude-workspace/docs/ai-guide/ $WORKSPACE/docs/
```

---

### Kiểm tra cài đặt

```bash
cd $WORKSPACE
claude
```

Nếu cài đúng, bạn sẽ thấy:
- Claude hiểu khi bạn hỏi về RobotNet10 (nhờ `CLAUDE.md`)
- Nếu có settings.json: dòng `RobotNet10 | main | 0 files modified` khi mở session
- Nếu có commands: gõ `/onboard` → Claude hỏi bạn muốn làm domain nào

---

## Chọn gì cho domain của bạn?

| Bạn làm... | Bước 1 | Bước 2 (rules) | Bước 3 (commands) | Bước 4 | Bước 5 (docs) |
|------------|--------|----------------|-------------------|--------|---------------|
| **RobotApp chung** | ✅ | safety + shared + test + robotapp | build, test-domain, safety-review | ✅ | robotapp/, development/ |
| **Motor/Navigation** | ✅ | safety + shared + robotapp | build, safety-review | ✅ | RobotApp-TunningNav/ |
| **SLAM** | ✅ | safety + shared + robotapp + slam | build, test-domain, explain-domain | ✅ | CartographerSharp/, Localization/ |
| **FleetManager** | ✅ | safety + shared + test + fleetmanager + mqtt | build, test-domain, trace-vda5050 | ✅ | fleetmanager/, vda5050/ |
| **Blazor UI** | ✅ | shared + test + blazor-ui + (robotapp hoặc fleetmanager) | build | Tuỳ | — |
| **Script Engine** | ✅ | shared + test | build, test-domain | Tuỳ | ScriptEngine/ |
| **Tất cả / Team Lead** | ✅ | Tất cả rules | Tất cả commands | ✅ | Tất cả docs |

---

## Cập nhật

Nếu dùng symlink (Option A): `git pull` trong context repo → workspace tự đồng bộ.

Nếu dùng copy thủ công (Option B): chạy lại các bước copy sau khi `git pull`.

Xem [UPDATING.md](UPDATING.md) cho các tình huống nâng cao.

## Cấu trúc repo

```
robotnet10-claude-workspace/
├── .claude/
│   ├── CLAUDE.md              ← Project context (kiến trúc, domain map, patterns)
│   ├── settings.json          ← Hooks + permissions + deny rules
│   ├── rules/                 ← 8 auto-load rules theo domain
│   │   ├── safety-critical.md
│   │   ├── robotapp-context.md
│   │   ├── fleetmanager-context.md
│   │   ├── slam-cartographer-context.md
│   │   ├── shared-contracts.md
│   │   ├── test-standards.md
│   │   ├── blazor-ui.md
│   │   └── mqtt-communication.md
│   └── commands/              ← 8 workflow commands
│       ├── onboard.md
│       ├── safety-review.md
│       ├── build.md
│       ├── test-domain.md
│       ├── explain-domain.md
│       ├── trace-vda5050.md
│       ├── check-shared.md
│       └── device-scaffold.md
│
├── docs/                      ← 74 domain knowledge files
│   ├── CartographerSharp/     ← SLAM (13 files)
│   ├── fleetmanager/          ← Fleet management (12 files)
│   ├── ScriptEngine/          ← Scripting (13 files)
│   ├── MapEditor/             ← Map editor (16 files)
│   ├── RobotApp-TunningNav/   ← Nav tuning (7 files)
│   ├── vda5050/               ← VDA 5050 protocol
│   ├── architecture/          ← System architecture
│   ├── development/           ← Developer guides
│   ├── robotapp/              ← RobotApp docs
│   ├── Localization/          ← Localization service
│   └── ai-guide/              ← AI agent orientation
│
├── setup.sh / setup.ps1       ← Script tự động
├── QUICKSTART.md              ← Hướng dẫn setup nhanh
├── UPDATING.md                ← Hướng dẫn sync/update
└── CHANGELOG.md               ← Release notes
```

## RobotNet10 Overview

| Component | Mô tả | Runtime |
|-----------|-------|---------|
| **RobotApp** | Điều khiển robot AMR đơn lẻ | Ubuntu 22.04, Linux RT |
| **FleetManager** | Điều phối đội xe robot | Docker, SQL Server |
| **Communication** | MQTT theo VDA 5050 v2.1.0 | |

**Tech stack:** C# .NET 10, Blazor Web App, MQTT (MQTTnet), CANOpen/CiA402, CartographerSharp (SLAM)

**Kiến trúc 3-layer:**
```
Shared (5 libs) → Commons (10 libs) + Components (5 UI) → Apps (RobotApp + FleetManager)
                                                              ↕ Communication (7 drivers)
```

## Đóng góp

1. Fork repo
2. Tạo branch: `docs/<topic>`
3. Commit: English, imperative mood
4. Mở PR

> [!IMPORTANT]
> Repo này chỉ chứa **docs và AI infrastructure** — KHÔNG chứa source code, EDS files, hay credentials.

---

*Phenikaa-X Robotics — AMR T800 Project*
