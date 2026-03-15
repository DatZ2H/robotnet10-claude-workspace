# Tasks / Nhiệm vụ Định kỳ

##Overview / Tổng quan

Tasks là methods chạy lặp lại theo interval định kỳ, phù hợp cho monitoring và automation đơn giản.

##Cách sử dụng / Usage

```csharp
[Task(Interval = 1000, AutoStart = true)]
public void MonitorBattery()
{
    var level = GetBatteryLevel();
    if (level < batteryThreshold)
    {
        Logger.Warning($"Battery low: {level}%");
    }
}

// Async task support
[Task(Interval = 5000, AutoStart = false)]
public async Task CheckConnection()
{
    await PingServerAsync();
    Logger.Info("Connection OK");
}
```

##Đặc điểm / Features

- **Timer-based execution**: 
  - Standard: Sử dụng `System.Threading.Timer`
  - Realtime (Linux): Sử dụng `RealtimeTimer` với dedicated thread và highest priority
- **AutoStart option**: Task có `AutoStart = true` sẽ tự động start khi Engine chuyển sang `Starting` state (xem [StateMachine_Design.md](StateMachine_Design.md))
- **Warning**: Nếu execution time > interval
- **ScriptGlobals**: Reused cho tất cả executions (performance)
- **Thread-safe**: Variables được chia sẻ thread-safe
- **State Machine**: Task có state machine quản lý lifecycle (Idle, Running, Pausing, Paused, Resuming, Stopping, Stopped, Error)
- **Pause/Resume**: Timer/Realtime loop tiếp tục chạy khi paused, chỉ skip execution. Resume ngay lập tức không cần restart timer

##Task Attributes / Thuộc tính Task

- `[Task(Interval = milliseconds)]`: Định nghĩa interval giữa các lần chạy
- `[Task(Interval = milliseconds, AutoStart = true/false)]`: Tự động start khi engine ready

##Task Control APIs / API Điều khiển Task

```csharp
EnableTask("MonitoringTask");   // Tương đương task.Resume() - chuyển từ Paused → Running
DisableTask("MaintenanceTask"); // Tương đương task.Pause() - chuyển từ Running → Paused
```

**Lưu ý**:
- `EnableTask/DisableTask` là API level (public interface cho scripts)
- `Pause/Resume` là state machine level (internal state transitions)
- `EnableTask()` = `Resume()` - chuyển từ `Paused` → `Resuming` → `Running`
- `DisableTask()` = `Pause()` - chuyển từ `Running` → `Pausing` → `Paused`
- **Pause/Resume Behavior**: 
  - Khi `Pause`: Timer/Realtime loop **vẫn tiếp tục chạy**, chỉ skip execution khi timer expire
  - Khi `Resume`: Timer/Realtime loop **đã chạy**, chỉ enable execution lại
  - Điều này đảm bảo timer không bị gián đoạn và có thể resume ngay lập tức
- Xem chi tiết về Task state machine trong [StateMachine_Design.md](StateMachine_Design.md)
- Xem tích hợp realtime trong [Realtime Integration Guide](../development/RealtimeIntegration.md)

##Related Documents / Tài liệu Liên quan

- [ScriptEngine Overview](README.md) - Tổng quan ScriptEngine
- [Variables](Variables.md) - Tasks có thể đọc/ghi variables
- [Missions](Missions.md) - Tasks có thể tạo/cancel missions
- [Built-in APIs](BuiltInAPIs.md) - Task control APIs

---

**Last Updated**: 2025-11-13

