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
| SLAM/ | SLAM integration, Localization, ScanMapping services (47 files) |
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
- `IVelocityController` — all velocity commands go through this
- `RobotStateMachine` (class, not interface) — state transitions (Idle, Moving, Error, E-Stop...)
- `IDeviceProvider` — device discovery and lifecycle
- `ISafety` — safety chain (handles E-Stop, no separate IEmergencyStop interface)
- `ICiA402Servo` — CiA402 drive control
- `ISLAMService` / `ILocalizationService` / `IScanMappingService` — SLAM domain interfaces

## Device pattern
```
DeviceBase (abstract)
  -> DeviceAttribute (metadata: name, type, hub)
  -> IDeviceProvider (DI registration)
  -> SignalR Hub (real-time UI updates)
  -> Blazor Component (UI rendering)
```

## When editing RobotApp code
- Check if change affects real-time paths (Navigation, Motion) — these have timing constraints
- SignalR hubs are the bridge between backend services and UI — changes propagate to client
- Script integration allows user-defined behaviors — be careful with Script API surface
