# RobotNet10 Claude Workspace

Claude Code context repository cho du an RobotNet10 — AMR Fleet Management System (Phenikaa-X Robotics).

Repo nay chua **domain knowledge, rules, hooks, va commands** de AI agents lam viec hieu qua voi RobotNet10 codebase ma khong can mo ta lai context tu dau.

## Repo nay dung de lam gi?

RobotNet10 la he thong phan mem phuc tap (43 projects, ~1,300 files C#) bao gom nhieu domain:
SLAM, Navigation, Motor Control, Fleet Management, VDA 5050, Script Engine, Map Editor...

Moi khi developer moi (hoac AI agent) bat dau lam viec voi mot domain, can hieu:
- Kien truc tong the va vi tri domain trong he thong
- Safety constraints (motor control, SLAM co the gay va cham neu sai)
- Coding patterns va conventions rieng cua project
- Cross-domain dependencies (Shared contracts anh huong ca RobotApp va FleetManager)

Repo nay **dong goi tat ca context** do de setup trong 5 phut.

## Noi dung

```
robotnet10-claude-workspace/
├── README.md                ← File nay
├── QUICKSTART.md            ← 5 phut setup
├── CHANGELOG.md             ← Release notes
├── UPDATING.md              ← Huong dan sync/update
├── setup.sh / setup.ps1     ← Script tu dong setup
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

Xem [QUICKSTART.md](QUICKSTART.md) cho huong dan day du.

```bash
# 1. Clone
git clone <repo-url> ~/robotnet10-claude-workspace

# 2. Setup (tao symlink .claude/ vao RobotNet10 workspace)
cd ~/robotnet10-claude-workspace
./setup.sh /path/to/robotnet10   # Linux/macOS
# hoac
.\setup.ps1 -RobotNet10Path "C:\path\to\robotnet10"  # Windows (Admin)

# 3. Su dung
cd /path/to/robotnet10
claude
```

## Features

### Rules (auto-load theo domain)

Khi edit files trong RobotNet10, Claude tu dong load rules phu hop:

| Rule | Trigger (file patterns) | Muc dich |
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

| Command | Mo ta |
|---------|-------|
| `/onboard` | Onboarding tuong tac — chon domain de bat dau |
| `/explain-domain` | Trace implementation cua domain cu the |
| `/safety-review` | Review safety-critical changes truoc commit |
| `/build [target]` | Build shortcut — all, robotapp, fleet, hoac project name |
| `/test-domain [domain]` | Test theo domain — khong can nho path + framework |
| `/trace-vda5050 [message]` | Trace VDA 5050 message flow (Order/State/InstantAction) |
| `/check-shared` | Kiem tra backward compatibility cua Shared/ changes |
| `/device-scaffold [name]` | Scaffold device moi theo pattern chuan |

### Safety Hooks

- **PreToolUse** (Edit/Write): Canh bao khi edit files trong safety-critical zones (Motion/, CANOpen/, CiA402/)
- **PostToolUse** (Edit/Write): Nhac build solution khi edit Shared/ contracts
- **Deny rules**: Chan `rm -rf` va `dotnet ef database update` (destructive commands)
- **SessionStart**: Hien thi branch + file status khi bat dau session

### Memory System

Claude Code tu dong hoc va luu context cua ban qua cac session. Memory user-specific (vai tro, preferences) duoc gitignored — moi developer co memory rieng.

## Selective Adoption

Khong bat buoc cai tat ca. Chon thanh phan phu hop:

| Thanh phan | Mo ta | Co the bo? | Hau qua neu bo |
|------------|-------|-------------|-----------------|
| `.claude/CLAUDE.md` | Project context | **Khong** — core | Claude khong hieu project |
| `.claude/rules/safety-critical.md` | Safety warnings | **Khong** — critical | Mat bao ve motor control |
| `.claude/rules/robotapp-context.md` | RobotApp context | Co — neu chi lam FleetManager | Thieu context RobotApp |
| `.claude/rules/fleetmanager-context.md` | FleetManager context | Co — neu chi lam RobotApp | Thieu context FM |
| `.claude/rules/slam-*.md` | SLAM domain | Co — neu khong lam SLAM | Thieu SLAM guidance |
| `.claude/rules/blazor-ui.md` | Blazor patterns | Co | Thieu UI guidance |
| `.claude/rules/mqtt-*.md` | MQTT patterns | Co | Thieu MQTT guidance |
| `.claude/rules/shared-contracts.md` | Cross-app warnings | **Khong** — neu edit Shared/ | Thieu break warnings |
| `.claude/rules/test-standards.md` | Test conventions | **Khong** — neu viet tests | Sai framework/style |
| `.claude/settings.json` (hooks) | Safety hooks | **Khuyen nghi** | Mat runtime protection |
| `.claude/settings.json` (deny) | Destructive cmd block | **Khuyen nghi** | Mat guardrails |
| `.claude/commands/*` | 8 workflow commands | Co — chon cai can | Phai nho commands thu cong |
| `docs/` | 72 domain docs | Co — tham khao | Claude it context khi can tra cuu |

Setup selective:

```bash
# Chi cai rules + CLAUDE.md (khong hooks, khong commands)
./setup.sh --rules-only /path/to/robotnet10

# Cai day du nhung bo hooks
./setup.sh --no-hooks /path/to/robotnet10

# Windows
.\setup.ps1 -RobotNet10Path "C:\path\to\robotnet10" -RulesOnly
.\setup.ps1 -RobotNet10Path "C:\path\to\robotnet10" -NoHooks
```

## RobotNet10 Overview

| Component | Mo ta | Runtime |
|-----------|-------|---------|
| **RobotApp** | Dieu khien robot AMR don le | Ubuntu 22.04, Linux RT |
| **FleetManager** | Dieu phoi doi xe robot | Docker, SQL Server |
| **Communication** | MQTT theo VDA 5050 v2.1.0 | |

**Tech stack:** C# .NET 10, Blazor Web App, MQTT (MQTTnet), CANOpen/CiA402, CartographerSharp (SLAM)

**Kien truc 3-layer:**
```
Shared (5 libs) → Commons (10 libs) + Components (5 UI) → Apps (RobotApp + FleetManager)
                                                              ↕ Communication (7 drivers)
```

## Cap nhat

Xem [UPDATING.md](UPDATING.md) cho huong dan day du ve sync workflow.

## Dong gop

1. Fork repo
2. Tao branch: `docs/<topic>`
3. Commit: English, imperative mood
4. Mo PR

> [!IMPORTANT]
> Repo nay chi chua **docs va AI infrastructure** — KHONG chua source code, EDS files, hay credentials.

## Lien quan

- **RobotNet10 codebase**: GitLab noi bo (Phenikaa-X)
- **AMR-T800 Hub**: Orchestration hub cho du an AMR T800

---

*Phenikaa-X Robotics — AMR T800 Project*
