---
globs:
  - "srcs/**/RobotApp/**"
---

# RobotApp Context

## Runtime environment
- **OS:** Ubuntu 22.04 (Linux RT kernel 6.6.116-rt66)
- **Database:** SQLite (local on robot)
- **UI:** Blazor Web App (accessed via robot's IP)
- **Real-time:** Uses RobotNet10.Realtime for high-priority threads

## Entry point
- Main project: `RobotApp/RobotNet10.RobotApp/`
- Client (Blazor WASM): `RobotApp/RobotNet10.RobotApp.Client/`
- Shared models: `RobotApp/RobotNet10.RobotApp.Shared/`
- Script integration: `RobotApp/RobotNet10.RobotApp.Script/` + `.Script.Shared/`

## Architecture breakdown

| Folder | Purpose |
|--------|---------|
| Services/Navigation/ | Navigation algorithms, path following, velocity control |
| Services/State/ | Robot state machine (Appccelerate) |
| SLAM/ | SLAM integration, Localization, ScanMapping services (~57 files) |
| Hubs/ | SignalR hubs — 13 hub classes (DeviceHub, MotionHub, SLAMHub, NavigationMonitorHub...) |
| Drivers/ | Hardware driver initialization and management |
| Motion/ | Kinematics, differential drive, trajectory |
| Devices/ | Device abstraction layer (DeviceBase, IDeviceProvider) |
| Controllers/ | REST API endpoints (MapsController, etc.) |
| Modules/ | Hardware modules (ILiftModule, IRotationModule) |
| Components/ | Blazor UI components |
| Interfaces/ | Core abstractions (ISafety, INavigation, ILocalization, etc.) |

## Communication drivers (under RobotApp/Communication/)

| Driver | Project | Purpose |
|--------|---------|---------|
| CANOpen | RobotNet10.CANOpen | CANOpen protocol stack |
| CiA402 | RobotNet10.CANOpen.CiA402 | Motor drive profile |
| CartographerSharp | CartographerSharp | SLAM (Google Cartographer port) |
| CeresSharp | CeresSharp | Ceres solver for SLAM |
| Olei LiDAR | Olei.LidarSensor | Olei brand LiDAR driver |
| SICK CoLa B | Sick.ColaB | SICK LiDAR communication |
| SICK Safety | Sick.SafetyScanners | SICK safety scanner integration |

## Key interfaces to know
- `RobotStateMachine` (class, not interface) — 24 states via `RobotStateType` enum. Root: System, Auto, Manual, Service, Remote_Override, Stop, Fault. Auto sub-states: Idle, Executing (Moving, ACT), Paused, Canceling, Recovering. ACT sub-states: Docking, Docked, Charging, Undocking, Loading, Unloading, TechAction
- `IDeviceProvider` — device discovery and lifecycle
- `ISafety` — speed limits and safety stop flag (IsSafetyStop, MinSpeed, UpdateSpeed, SpeedType enum: Order/PLC/SoftSafety, indexer this[SpeedType])
- `ICiA402Servo` — CiA402 drive control
- `ISLAMService` — unified SLAM interface (localization + scan mapping + rerender, NO separate ILocalizationService/IScanMappingService)
- Note: `ILocalization` (Interfaces/) is a high-level pose data abstraction, NOT the same as `ISLAMService` (SLAM/) which handles SLAM-specific operations. `INavigation` has its own `NavigationState` enum (None, Idle, Initializing, Waiting, Moving, Rotating, etc.) — separate from RobotStateMachine states

## Device pattern
```
DeviceBase (abstract)
  -> DeviceAttribute (metadata: DeviceType, Brand, DriverName, Version, Description)
  -> IDeviceProvider (DI registration)
  -> SignalR Hub (real-time UI updates)
  -> Blazor Component (UI rendering)
```

## Real-time timing constraints

| Path | Cycle | Deadline | Notes |
|------|-------|----------|-------|
| IPC (CANOpen PDO) | 50 Hz | 20ms | CSV mode velocity targets to motor driver |
| Pose extrapolation | 20-100 Hz | 10-50ms | SLAM pose output |
| Scan matching | 5-20 Hz | 50-200ms | Must NOT block IPC cycle |
| Navigation loop | 10-20 Hz | 50-100ms | Path following + velocity control |
| SignalR UI updates | 1-10 Hz | N/A (best effort) | UI refresh, no hard deadline |

## SignalR hubs (13)

DeviceHub, MotionHub, SLAMHub, NavigationMonitorHub, SafetyHub, ScriptHub, DiagnosticHub, MapHub, ConfigHub, LogHub, SystemHub, ModuleHub, TaskHub

## When editing RobotApp code
- Check if change affects real-time paths (Navigation, Motion) — these have timing constraints (see table above)
- IPC cycle is 50 Hz (20ms) — blocking operations in the motor control path WILL cause motor stutter or safety fault
- SignalR hubs are the bridge between backend services and UI — changes propagate to client
- Script integration allows user-defined behaviors — be careful with Script API surface
