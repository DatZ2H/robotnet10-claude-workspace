---
globs:
  - "srcs/**/Shared/**"
---

# Shared Contracts — Cross-App Impact

> [!WARNING]
> Thay đổi trong Shared/ ảnh hưởng CẢ RobotApp VÀ FleetManager.
> Phải build toàn bộ solution sau khi thay đổi.

## Shared projects

| Project | Content |
|---------|---------|
| RobotNet.VDA5050 | VDA 5050 protocol models (OrderMsg, StateMsg, etc.) |
| RobotNet10.Shared | Common contracts dùng chung |
| RobotNet10.MapEditor.Shared | Map editor shared models |
| RobotNet10.NavigationTune.Shared | Nav tuning shared models |
| RobotNet10.ScriptEngine.Shared | Script engine shared models |

## VDA 5050 naming rules

- Field names PHẢI match VDA 5050 spec exactly (camelCase)
- Dùng `[JsonPropertyName("camelCase")]` cho serialization
- Class names thực tế: `OrderMsg`, `StateMsg` (có suffix `Msg`), KHÔNG phải `Order`, `State`
- Error type: `MessageResult<T>` (record type), KHÔNG phải `Result<T>`

## Before editing Shared/

1. Xác định consumers: RobotApp, FleetManager, hoặc cả hai?
2. Check backward compatibility nếu thay đổi model fields
3. Build toàn bộ solution: `dotnet build srcs/RobotNet10/RobotNet10.slnx`
4. Run tests: `dotnet test srcs/RobotNet10/RobotNet10.slnx`
