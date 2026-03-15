# Missions / Nhiệm vụ Dài hạn

##Overview / Tổng quan

Missions là long-running workflows với progress tracking, phù hợp cho các nhiệm vụ phức tạp có thể cancel và track progress.

**Lưu ý quan trọng**: 
- `Mission` = method trong script với `[Mission]` attribute (không có state machine)
- `MissionInstance` = instance được tạo từ Mission method khi gọi `CreateMission()` (có state machine)
- Xem chi tiết về state machine trong [StateMachine_Design.md](StateMachine_Design.md)

##Cách sử dụng / Usage

```csharp
[Mission(TotalScore = 10)]
public async IAsyncEnumerable<MissionStatus> PickAndPlace(
    string pickLocation,
    string placeLocation,
    [EnumeratorCancellation] CancellationToken ct)
{
    yield return new MissionStatus { Score = 1, Message = "Moving to pick" };
    await MoveTo(pickLocation);

    yield return new MissionStatus { Score = 3, Message = "Picking item" };
    await PerformPick();

    yield return new MissionStatus { Score = 5, Message = "Moving to place" };
    await MoveTo(placeLocation);

    yield return new MissionStatus { Score = 8, Message = "Placing item" };
    await PerformPlace();

    yield return new MissionStatus { Score = 10, Message = "Completed" };
}
```

##Đặc điểm / Features

- **IAsyncEnumerable<MissionStatus>**: Return type để track progress
- **CancellationToken support**: Có thể cancel mission
- **Progress tracking**: Score/TotalScore để track tiến độ
- **Per-instance MissionGlobals**: Isolated execution cho mỗi mission instance
- **Persist to database**: Mission history được lưu vào database

##Mission Attributes / Thuộc tính Mission

- `[Mission(TotalScore = number)]`: Định nghĩa total score cho progress tracking

##Mission Status / Trạng thái Mission

**ScriptMissionState Enum** (tương ứng với state machine trong [StateMachine_Design.md](StateMachine_Design.md)):
- `Idle` (0) - MissionInstance chưa được start
- `Running` (1) - MissionInstance đang thực thi
- `Canceling` (2) - MissionInstance đang được cancel
- `Pausing` (3) - MissionInstance đang được pause
- `Paused` (4) - MissionInstance đã bị pause
- `Resuming` (5) - MissionInstance đang được resume
- `Canceled` (6) - MissionInstance đã bị cancel
- `Completed` (7) - MissionInstance đã hoàn thành thành công
- `Error` (8) - MissionInstance gặp lỗi

**Lưu ý**: 
- `Mission` là method trong script với `[Mission]` attribute (không có state machine)
- `MissionInstance` là instance được tạo từ Mission method khi gọi `CreateMission()` (có state machine)
- State machine quản lý state của **MissionInstance**, không phải Mission
- Terminal states (`Completed`, `Canceled`, `Error`) là final states - khi về các state này, MissionInstance sẽ:
  1. Lưu trạng thái, log và score vào database
  2. Dispose MissionInstance

##Mission Management APIs / API Quản lý Mission

```csharp
// Create mission
Guid missionId = CreateMission("DeliverPackage",
    fromLocation: "A1",
    toLocation: "B2");

// Cancel mission
CancelMission(missionId);
```

##Data Persistence / Lưu trữ Dữ liệu

Missions được persist vào database với MissionInstances và MissionLogs tables.

##Related Documents / Tài liệu Liên quan

- [ScriptEngine Overview](README.md) - Tổng quan ScriptEngine
- [Variables](Variables.md) - Missions có thể đọc/ghi variables
- [Tasks](Tasks.md) - Tasks có thể tạo/cancel missions
- [Data Persistence](DataPersistence.md) - Chi tiết về database storage
- [Built-in APIs](BuiltInAPIs.md) - Mission management APIs

---

**Last Updated**: 2025-11-13

