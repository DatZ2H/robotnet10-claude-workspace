# RobotNet10 AI Context

Claude Code context repository cho dự án RobotNet10 — AMR Fleet Management System (Phenikaa-X Robotics).

Repo này chứa **domain knowledge, rules, và commands** để AI agents làm việc hiệu quả với RobotNet10 codebase mà không cần mô tả lại context từ đầu.

## Repo này dùng để làm gì?

RobotNet10 là hệ thống phần mềm phức tạp (47 projects, 1,304+ files C#) bao gồm nhiều domain:
SLAM, Navigation, Motor Control, Fleet Management, VDA 5050, Script Engine, Map Editor...

Mỗi khi developer mới (hoặc AI agent) bắt đầu làm việc với một domain, cần hiểu:
- Kiến trúc tổng thể và vị trí domain trong hệ thống
- Safety constraints (motor control, SLAM có thể gây va chạm nếu sai)
- Coding patterns và conventions riêng của project
- Cross-domain dependencies (Shared contracts ảnh hưởng cả RobotApp và FleetManager)

Repo này **đóng gói tất cả context** đó để setup trong 5 phút.

## Nội dung

```
robotnet10-ai-context/
├── README.md              ← File này
├── QUICKSTART.md          ← 5 phút setup
├── setup.sh / setup.ps1   ← Script tự động setup
│
├── .claude/               ← Claude Code infrastructure
│   ├── CLAUDE.md          ← Project context (auto-load)
│   ├── settings.json      ← Permissions + hooks
│   ├── commands/           ← /onboard, /explain-domain
│   └── rules/              ← Auto-load rules theo domain
│
└── docs/                   ← Domain knowledge (70+ files)
    ├── ai-guide/           ← AI agent orientation (REQUIRED)
    ├── DOCUMENTATION_MAP.md
    ├── architecture/
    ├── CartographerSharp/  ← SLAM docs + research
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
git clone <repo-url> ~/robotnet10-ai-context

# 2. Setup (tạo symlink .claude/ vào RobotNet10 workspace)
cd ~/robotnet10-ai-context
./setup.sh /path/to/robotnet10   # Linux/macOS
# hoặc
.\setup.ps1 -RobotNet10Path "C:\path\to\robotnet10"  # Windows (Admin)

# 3. Sử dụng
cd /path/to/robotnet10
claude
```

## Claude Code Rules (auto-load)

Khi edit files trong RobotNet10, Claude tự động load rules phù hợp:

| Rule | Trigger (file patterns) | Mục đích |
|------|------------------------|---------|
| `safety-critical.md` | `Motion/`, `CANOpen/`, `CiA402/` | ⚠️ Motor control safety |
| `robotapp-context.md` | `RobotApp/**` | RobotApp architecture |
| `fleetmanager-context.md` | `FleetManager/**` | FleetManager architecture |
| `slam-cartographer-context.md` | `CartographerSharp/`, `CeresSharp/`, `SLAM/` | SLAM domain (262 files) |
| `shared-contracts.md` | `Shared/**` | Cross-app impact warnings |
| `test-standards.md` | `Tests/**` | NUnit testing standards |

## Commands

| Command | Mô tả |
|---------|-------|
| `/onboard` | Onboarding tương tác — chọn domain để bắt đầu |
| `/explain-domain <topic>` | Trace implementation của một domain cụ thể |

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

## Liên quan

- **RobotNet10 codebase**: GitLab nội bộ (Phenikaa-X)
- **AMR-T800 Hub**: Orchestration hub cho dự án AMR T800

---

*Phenikaa-X Robotics — AMR T800 Project*
