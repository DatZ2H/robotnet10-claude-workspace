# RobotNet10 Claude Workspace

Claude Code context repository cho dự án RobotNet10 — AMR Fleet Management System (Phenikaa-X Robotics).

Repo này chứa **domain knowledge, rules, hooks, và commands** để AI agents làm việc hiệu quả với RobotNet10 codebase mà không cần mô tả lại context từ đầu.

## Repo này dùng để làm gì?

RobotNet10 là hệ thống phần mềm phức tạp (43 projects, ~1,300 files C#) bao gồm nhiều domain:
SLAM, Navigation, Motor Control, Fleet Management, VDA 5050, Script Engine, Map Editor...

Mỗi khi developer mới (hoặc AI agent) bắt đầu làm việc với một domain, cần hiểu:
- Kiến trúc tổng thể và vị trí domain trong hệ thống
- Safety constraints (motor control, SLAM có thể gây va chạm nếu sai)
- Coding patterns và conventions riêng của project
- Cross-domain dependencies (Shared contracts ảnh hưởng cả RobotApp và FleetManager)

Repo này **đóng gói tất cả context** đó để setup trong 5 phút.

## Nội dung

```
robotnet10-claude-workspace/
├── README.md                ← File này
├── QUICKSTART.md            ← 5 phút setup
├── CHANGELOG.md             ← Release notes
├── UPDATING.md              ← Hướng dẫn sync/update
├── setup.sh / setup.ps1     ← Script tự động setup
│
├── .claude/                 ← Claude Code infrastructure
│   ├── CLAUDE.md            ← Project context (auto-load)
│   ├── settings.json        ← Permissions, hooks, deny rules
│   ├── commands/            ← 8 workflow commands
│   ├── rules/               ← 8 auto-load rules theo domain
│   └── memory/              ← Memory system (user-specific, gitignored)
│
└── docs/                    ← Domain knowledge (72 files)
    ├── ai-guide/            ← AI agent orientation
    ├── DOCUMENTATION_MAP.md
    ├── architecture/
    ├── CartographerSharp/   ← SLAM docs + research
    ├── Localization/
    ├── development/
    ├── robotapp/
    ├── fleetmanager/
    ├── vda5050/
    ├── ScriptEngine/
    ├── MapEditor/
    └── RobotApp-TunningNav/
```

## Quick Start

Xem [QUICKSTART.md](QUICKSTART.md) cho hướng dẫn đầy đủ.

```bash
# 1. Clone
git clone <repo-url> ~/robotnet10-claude-workspace

# 2. Setup (tạo symlink .claude/ vào RobotNet10 workspace)
cd ~/robotnet10-claude-workspace
./setup.sh /path/to/robotnet10   # Linux/macOS
# hoặc
.\setup.ps1 -RobotNet10Path "C:\path\to\robotnet10"  # Windows (Admin)

# 3. Sử dụng
cd /path/to/robotnet10
claude
```

## Features

### Rules (auto-load theo domain)

Khi edit files trong RobotNet10, Claude tự động load rules phù hợp:

| Rule | Trigger (file patterns) | Mục đích |
|------|------------------------|---------|
| `safety-critical.md` | `Motion/`, `CANOpen/`, `CiA402/`, `Services/Navigation/`, `Services/State/` | ⚠️ Motor control safety |
| `robotapp-context.md` | `RobotApp/**` | RobotApp architecture |
| `fleetmanager-context.md` | `FleetManager/**` | FleetManager architecture |
| `slam-cartographer-context.md` | `CartographerSharp/`, `CeresSharp/`, `SLAM/`, `Localization/` | SLAM domain (~262 files) |
| `shared-contracts.md` | `Shared/**` | Cross-app impact warnings |
| `test-standards.md` | `Tests/**`, `*Tests*/**` | NUnit + xUnit testing standards |
| `blazor-ui.md` | `*.Client/**`, `Components/**` | Blazor UI patterns |
| `mqtt-communication.md` | `MqttConnection/**`, `RobotConnections/**` | MQTT/VDA 5050 patterns |

### Commands (8 workflow commands)

| Command | Mô tả |
|---------|-------|
| `/onboard` | Onboarding tương tác — chọn domain để bắt đầu |
| `/explain-domain` | Trace implementation của domain cụ thể |
| `/safety-review` | Review safety-critical changes trước commit |
| `/build [target]` | Build shortcut — all, robotapp, fleet, hoặc project name |
| `/test-domain [domain]` | Test theo domain — không cần nhớ path + framework |
| `/trace-vda5050 [message]` | Trace VDA 5050 message flow (Order/State/InstantAction) |
| `/check-shared` | Kiểm tra backward compatibility của Shared/ changes |
| `/device-scaffold [name]` | Scaffold device mới theo pattern chuẩn |

### Safety Hooks

- **PreToolUse** (Edit/Write): Cảnh báo khi edit files trong safety-critical zones (Motion/, CANOpen/, CiA402/)
- **PostToolUse** (Edit/Write): Nhắc build solution khi edit Shared/ contracts
- **Deny rules**: Chặn `rm -rf` và `dotnet ef database update` (destructive commands)
- **SessionStart**: Hiển thị branch + file status khi bắt đầu session

### Memory System

Claude Code tự động học và lưu context của bạn qua các session. Memory user-specific (vai trò, preferences) được gitignored — mỗi developer có memory riêng.

## Selective Adoption

Không bắt buộc cài tất cả. Chọn thành phần phù hợp:

| Thành phần | Mô tả | Có thể bỏ? | Hậu quả nếu bỏ |
|------------|-------|-------------|-----------------|
| `.claude/CLAUDE.md` | Project context | **Không** — core | Claude không hiểu project |
| `.claude/rules/safety-critical.md` | Safety warnings | **Không** — critical | Mất bảo vệ motor control |
| `.claude/rules/robotapp-context.md` | RobotApp context | Có — nếu chỉ làm FleetManager | Thiếu context RobotApp |
| `.claude/rules/fleetmanager-context.md` | FleetManager context | Có — nếu chỉ làm RobotApp | Thiếu context FM |
| `.claude/rules/slam-*.md` | SLAM domain | Có — nếu không làm SLAM | Thiếu SLAM guidance |
| `.claude/rules/blazor-ui.md` | Blazor patterns | Có | Thiếu UI guidance |
| `.claude/rules/mqtt-*.md` | MQTT patterns | Có | Thiếu MQTT guidance |
| `.claude/rules/shared-contracts.md` | Cross-app warnings | **Không** — nếu edit Shared/ | Thiếu break warnings |
| `.claude/rules/test-standards.md` | Test conventions | **Không** — nếu viết tests | Sai framework/style |
| `.claude/settings.json` (hooks) | Safety hooks | **Khuyên nghị** | Mất runtime protection |
| `.claude/settings.json` (deny) | Destructive cmd block | **Khuyên nghị** | Mất guardrails |
| `.claude/commands/*` | 8 workflow commands | Có — chọn cái cần | Phải nhớ commands thủ công |
| `docs/` | 72 domain docs | Có — tham khảo | Claude ít context khi cần tra cứu |

Setup selective:

```bash
# Chỉ cài rules + CLAUDE.md (không hooks, không commands)
./setup.sh --rules-only /path/to/robotnet10

# Cài đầy đủ nhưng bỏ hooks
./setup.sh --no-hooks /path/to/robotnet10

# Windows
.\setup.ps1 -RobotNet10Path "C:\path\to\robotnet10" -RulesOnly
.\setup.ps1 -RobotNet10Path "C:\path\to\robotnet10" -NoHooks
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

## Cập nhật

Xem [UPDATING.md](UPDATING.md) cho hướng dẫn đầy đủ về sync workflow.

## Đóng góp

1. Fork repo
2. Tạo branch: `docs/<topic>`
3. Commit: English, imperative mood
4. Mở PR

> [!IMPORTANT]
> Repo này chỉ chứa **docs và AI infrastructure** — KHÔNG chứa source code, EDS files, hay credentials.

## Liên quan

- **RobotNet10 codebase**: GitLab nội bộ (Phenikaa-X)
- **AMR-T800 Hub**: Orchestration hub cho dự án AMR T800

---

*Phenikaa-X Robotics — AMR T800 Project*
