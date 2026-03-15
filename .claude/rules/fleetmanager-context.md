---
globs:
  - "srcs/**/FleetManager/**"
---

# FleetManager Context

## Runtime environment
- **Deployment:** Docker container
- **Database:** SQL Server (EF Core)
- **UI:** Blazor Web App (server-side + WASM client)
- **Communication:** MQTT (MQTTnet) for VDA 5050 robot communication

## Entry point
- Main project: `FleetManager/RobotNet10.FleetManager/`
- Client (Blazor WASM): `FleetManager/RobotNet10.FleetManager.Client/`
- Shared models: `FleetManager/RobotNet10.FleetManager.Shared/`
- Script integration: `FleetManager/RobotNet10.FleetManager.Script/` + `.Script.Shared/`

## Core modules

| Module | Purpose |
|--------|---------|
| Identity | Authentication & authorization — ASP.NET Identity mặc định (Components/Account/), không phải module riêng |
| RobotConnections | MQTT connection management, heartbeat monitoring |
| RobotManager | Robot state, order, action management |
| TrafficControl | Route calculation (A*), conflict detection & resolution |
| ScriptEngine | C# scripting for custom fleet behaviors |
| MapEditor | Map management (VDMA LIF standard) |
| FleetManagerConfig | Dynamic configuration (runtime updates) |

## VDA 5050 integration
- Protocol version: v2.1.0 (backward compatible with v2.0.0)
- MQTT topics follow VDA 5050 topic structure
- Models in `Shared/RobotNet.VDA5050/` — field names MUST match spec exactly
- Use `[JsonPropertyName("camelCase")]` for VDA 5050 serialization

## Shared libraries used
- `Commons/RobotNet10.ScriptEngine/` — scripting engine (shared with RobotApp)
- `Commons/RobotNet10.MapManager/` — map data layer (shared with RobotApp)
- `Components/RobotNet10.MapEditor/` — map editor UI (shared Blazor component)

## When editing FleetManager code
- MQTT message handling must be robust (reconnection, QoS, message ordering)
- VDA 5050 models are shared contracts — changes affect RobotApp too
- TrafficControl is performance-sensitive with many robots — consider scalability
- Database migrations: use `dotnet ef migrations add <Name>` then `dotnet ef database update`
- Docker compose file defines the full deployment stack
