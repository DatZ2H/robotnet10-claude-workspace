# CLAUDE.md — RobotNet10

## Project context
- AMR fleet management system, C# .NET 10 custom framework, Phenikaa-X Robotics
- 43 projects, 2 apps (RobotApp + FleetManager), 7 communication drivers
- Solution file: `srcs/RobotNet10/RobotNet10.slnx` (modern .slnx format)
- Active development — NOT greenfield (~1,300 .cs files)

## Architecture (3-layer)

```
Shared (5 libs)  ──┐
Commons (10 libs) ─┼──> Apps (RobotApp + FleetManager)
Components (5 UI) ─┘        ↕
                    Communication (7 drivers)
```

### Layer breakdown

| Layer | Projects | Role |
|-------|----------|------|
| Shared | VDA5050, MapEditor.Shared, NavigationTune.Shared, ScriptEngine.Shared, Shared | Cross-app models and contracts |
| Commons | Common, CustomConfiguration, GlobalPathPlanner, MapManager, MqttConnection, NavigationTune, Realtime, Script, ScriptEngine, StorageManager | Business logic libraries |
| Components | Components, CustomConfigurationEditor, MapEditor, NavigationTuneUI, ScriptEditor | Blazor UI libraries |
| RobotApp | RobotApp, RobotApp.Client, RobotApp.Script, RobotApp.Script.Shared, RobotApp.Shared | Robot-side app (Ubuntu 22.04, SQLite) |
| FleetManager | FleetManager, FleetManager.Client, FleetManager.Script, FleetManager.Script.Shared, FleetManager.Shared | Server-side app (Docker, SQL Server, Blazor) |
| Communication | CANOpen, CANOpen.CiA402, CartographerSharp, CeresSharp, Olei.LidarSensor, Sick.ColaB, Sick.SafetyScanners | Hardware drivers (under RobotApp/) |
| Tests | GlobalPathPlanner.Test (xUnit), MapManager.Test (NUnit), NavigationTune.Test (xUnit), RobotManager.Test (NUnit), ScriptEngine.Test (NUnit), StorageManager.Test (xUnit), CeresSharp.Test (NUnit), RobotApp.Tests (xUnit) | Mixed NUnit + xUnit |

## Domain map

| Domain | Key projects | Entry docs |
|--------|-------------|------------|
| Motion & Kinematics | RobotApp/Motion/, Services/Navigation/ | docs/RobotApp-TunningNav/ |
| CANOpen/CiA402 | Communication/RobotNet10.CANOpen*, eds/ | EDS file trong eds/ |
| SLAM & Localization | Communication/CartographerSharp/, CeresSharp/, RobotApp/SLAM/ | docs/CartographerSharp/, docs/Localization/ |
| Path Planning | Commons/RobotNet10.GlobalPathPlanner/ | docs/MapEditor/PathFinding.md |
| State Machine | RobotApp/Services/State/ | docs/development/AppccelerateStateMachine.md |
| Fleet/VDA5050 | FleetManager/Services/, Shared/RobotNet.VDA5050/ | docs/fleetmanager/, docs/vda5050/ |
| Script Engine | Commons/RobotNet10.ScriptEngine/, Components/ScriptEditor/ | docs/ScriptEngine/ |
| Map Editor | Commons/RobotNet10.MapManager/, Components/MapEditor/ | docs/MapEditor/ |
| Nav Tuning | Commons/RobotNet10.NavigationTune/, Components/NavigationTuneUI/ | docs/RobotApp-TunningNav/ |
| Config | Commons/RobotNet10.CustomConfiguration/ | — |
| LiDAR | Communication/Olei.LidarSensor/, Communication/Sick.*/ | — |
| Realtime | Commons/RobotNet10.Realtime/ | docs/development/RealtimeIntegration.md |

## Safety zones — CRITICAL

Files trong Motion/, CANOpen/, CiA402/, Services/Navigation/, Services/State/
điều khiển motor vật lý. Sai có thể gây va chạm/hư thiết bị.

Auto-loaded rule: `.claude/rules/safety-critical.md`

## Key patterns

- **DI:** Constructor injection, register trong Program.cs (AddCanOpenManager, AddRobot, etc.)
- **State machine:** Appccelerate.StateMachine — RobotStateMachine trong Services/State/
- **SignalR:** 13 hubs trong RobotApp/Hubs/ (DeviceHub, MotionHub, SLAMHub...)
- **Device abstraction:** DeviceBase -> DeviceAttribute -> IDeviceProvider -> Hub -> UI
- **Async:** `*Async` suffix bắt buộc cho I/O methods
- **Namespace:** `RobotNet10.{ProjectName}[.{SubNamespace}]`
- **Logging:** NLog, structured logging (KHÔNG string interpolation trong log calls)
- **Testing:** NUnit + xUnit (mixed per project) + Moq + EF InMemory
- **VDA 5050:** Models dùng `[JsonPropertyName]` match spec exactly

## Build & run

```bash
# Build all
dotnet build srcs/RobotNet10/RobotNet10.slnx

# Test all
dotnet test srcs/RobotNet10/RobotNet10.slnx

# Run RobotApp
dotnet run --project srcs/RobotNet10/RobotApp/RobotNet10.RobotApp/

# Run FleetManager (Docker)
docker compose -f srcs/RobotNet10/FleetManager/docker-compose.yml up
```

## Language

- Code comments, commit messages: **English**
- Documentation: **Vietnamese có dấu** + English technical terms
- Namespace, class names: English, PascalCase
- VDA 5050 field names: match spec exactly (camelCase via JsonPropertyName)

## Git workflow

- Branch: `feat/<topic>`, `fix/<topic>`, `docs/<topic>`
- Commit: English, imperative mood
- Main branch: `main`

## Available rules (auto-load)

| Rule | Trigger (globs) |
|------|----------------|
| safety-critical.md | srcs/**/CANOpen/**, CiA402/**, Motion/**, Services/Navigation/**, Services/State/** |
| robotapp-context.md | srcs/**/RobotApp/** |
| fleetmanager-context.md | srcs/**/FleetManager/** |
| slam-cartographer-context.md | srcs/**/CartographerSharp/**, CeresSharp/**, SLAM/**, Localization/** |
| shared-contracts.md | srcs/**/Shared/** |
| test-standards.md | srcs/**/*.Test/**, *Tests*/** |
| blazor-ui.md | srcs/**/*.Client/**, srcs/**/Components/** |
| mqtt-communication.md | srcs/**/MqttConnection/**, srcs/**/RobotConnections/** |

## Available commands

| Command | Mô tả |
|---------|-------|
| /onboard | Onboarding tương tác — chọn domain để bắt đầu |
| /explain-domain | Trace implementation của domain cụ thể |
| /safety-review | Review safety-critical changes trước commit |
| /build [target] | Build shortcut — all, robotapp, fleet, hoặc project name |
| /test-domain [domain] | Test theo domain — không cần nhớ path + framework |
| /trace-vda5050 [message] | Trace VDA 5050 message flow (Order/State/InstantAction) |
| /check-shared | Kiểm tra backward compatibility của Shared/ changes |
| /device-scaffold [name] | Scaffold device mới theo pattern chuẩn |

## Khi cần tham khảo thêm

- Hardware manual: MBDV-2X-520AC-F02 dual-axis servo driver
- Motor: MSD180-10-075-20GSL-N (750W, gear ratio 10:1, no brake)
- Control: CSV mode (Cyclic Synchronous Velocity) qua CANOpen
- IPC cycle: 50 Hz
- EDS file: `eds/CANOPEN_EDS_MBDV_Servo_DulAxes_V1.0.eds`
