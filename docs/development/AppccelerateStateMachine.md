# Appccelerate.StateMachine Usage Guide / Hướng dẫn Sử dụng Appccelerate.StateMachine

## Overview / Tổng quan

Tài liệu này mô tả cách sử dụng thư viện **Appccelerate.StateMachine** trong dự án RobotNet10. Thư viện này được sử dụng để quản lý state machine cho ScriptEngine (Task, Mission, và Engine Manager).

## Installation / Cài đặt

### NuGet Package

```xml
<PackageReference Include="Appccelerate.StateMachine" Version="6.0.0" />
```

### Namespaces

```csharp
using Appccelerate.StateMachine;
using Appccelerate.StateMachine.Machine;
```

## Core Concepts / Khái niệm Cơ bản

### 1. States / Trạng thái

States là các trạng thái mà state machine có thể ở trong. Thường được định nghĩa bằng enum:

```csharp
public enum TaskState
{
    Idle = 0,
    Running,
    Pausing,
    Paused,
    Resuming,
    Stopping,
    Stopped,
    Error,
}
```

### 2. Triggers / Sự kiện

Triggers là các sự kiện có thể kích hoạt chuyển đổi trạng thái. Cũng thường là enum:

```csharp
public enum TaskTrigger
{
    Start,
    Pause,
    Resume,
    Stop,
    Dispose,
    PausingCompleted,
    ResumingCompleted,
    StoppingCompleted,
    ErrorOccurred,
}
```

### 3. State Machine Types / Các Loại State Machine

Appccelerate.StateMachine hỗ trợ hai loại state machine:

- **PassiveStateMachine**: State machine được điều khiển thủ công, cần gọi `Fire()` để trigger transitions
- **ActiveStateMachine**: State machine tự động xử lý events từ queue

**Trong RobotNet10, chúng ta sử dụng `PassiveStateMachine`** để có kiểm soát tốt hơn.

## Building State Machine / Xây dựng State Machine

### Step 1: Create Builder / Tạo Builder

```csharp
var builder = new StateMachineDefinitionBuilder<TState, TTrigger>();
```

### Step 2: Configure States / Cấu hình States

Sử dụng fluent API để cấu hình các states và transitions:

```csharp
builder.In(TaskState.Idle)
    .On(TaskTrigger.Start)
    .Goto(TaskState.Running)
    .Execute(() => OnEnterRunning());
```

### Step 3: Configure Entry/Exit Actions / Cấu hình Entry/Exit Actions

**Important**: `ExecuteOnEntry()` và `ExecuteOnExit()` phải được gọi **trước** các `On()` calls:

```csharp
builder.In(TaskState.Running)
    .ExecuteOnEntry(() => { _currentState = TaskState.Running; OnEnterRunning(); })
    .ExecuteOnExit(() => OnExitRunning())
    .On(TaskTrigger.Pause)
    .Goto(TaskState.Pausing)
    .Execute(() => { _currentState = TaskState.Pausing; OnEnterPausing(); });
```

**⚠️ Common Mistake**: Đặt `ExecuteOnEntry()` sau `On()` sẽ gây lỗi compile.

### Step 4: Build and Create / Build và Tạo

```csharp
var stateMachine = builder
    .WithInitialState(TaskState.Idle)
    .Build()
    .CreatePassiveStateMachine();

stateMachine.Start();
```

## Complete Example / Ví dụ Hoàn chỉnh

Dựa trên implementation của `ScriptTask`:

```csharp
using Appccelerate.StateMachine;
using Appccelerate.StateMachine.Machine;

public class ScriptTask
{
    private readonly PassiveStateMachine<ScriptTaskState, TaskTrigger> _stateMachine;
    private ScriptTaskState _currentState; // Track state manually

    public enum TaskTrigger
    {
        Start,
        Pause,
        Resume,
        Stop,
        Dispose,
        PausingCompleted,
        ResumingCompleted,
        StoppingCompleted,
        ErrorOccurred,
    }

    public ScriptTask()
    {
        var builder = new StateMachineDefinitionBuilder<ScriptTaskState, TaskTrigger>();
        ConfigureStateMachine(builder);

        _stateMachine = builder
            .WithInitialState(ScriptTaskState.Idle)
            .Build()
            .CreatePassiveStateMachine();

        _currentState = ScriptTaskState.Idle;
        _stateMachine.Start();
    }

    private void ConfigureStateMachine(StateMachineDefinitionBuilder<ScriptTaskState, TaskTrigger> builder)
    {
        // Idle state
        builder.In(ScriptTaskState.Idle)
            .On(TaskTrigger.Start)
            .Goto(ScriptTaskState.Running)
            .Execute(() => { _currentState = ScriptTaskState.Running; OnEnterRunning(); });

        // Running state
        builder.In(ScriptTaskState.Running)
            .ExecuteOnEntry(() => { _currentState = ScriptTaskState.Running; OnEnterRunning(); })
            .ExecuteOnExit(() => OnExitRunning())
            .On(TaskTrigger.Pause)
            .Goto(ScriptTaskState.Pausing)
            .Execute(() => { _currentState = ScriptTaskState.Pausing; OnEnterPausing(); })
            .On(TaskTrigger.Stop)
            .Goto(ScriptTaskState.Stopping)
            .Execute(() => { _currentState = ScriptTaskState.Stopping; OnEnterStopping(); })
            .On(TaskTrigger.ErrorOccurred)
            .Goto(ScriptTaskState.Error)
            .Execute(() => { _currentState = ScriptTaskState.Error; OnEnterError(); });

        // Pausing state
        builder.In(ScriptTaskState.Pausing)
            .ExecuteOnEntry(() => { _currentState = ScriptTaskState.Pausing; OnEnterPausing(); })
            .ExecuteOnExit(() => OnExitPausing())
            .On(TaskTrigger.PausingCompleted)
            .Goto(ScriptTaskState.Paused)
            .Execute(() => { _currentState = ScriptTaskState.Paused; OnEnterPaused(); })
            .On(TaskTrigger.ErrorOccurred)
            .Goto(ScriptTaskState.Error)
            .Execute(() => { _currentState = ScriptTaskState.Error; OnEnterError(); });

        // Paused state
        builder.In(ScriptTaskState.Paused)
            .ExecuteOnEntry(() => { _currentState = ScriptTaskState.Paused; OnEnterPaused(); })
            .ExecuteOnExit(() => OnExitPaused())
            .On(TaskTrigger.Resume)
            .Goto(ScriptTaskState.Resuming)
            .Execute(() => { _currentState = ScriptTaskState.Resuming; OnEnterResuming(); })
            .On(TaskTrigger.Stop)
            .Goto(ScriptTaskState.Stopping)
            .Execute(() => { _currentState = ScriptTaskState.Stopping; OnEnterStopping(); });

        // Resuming state
        builder.In(ScriptTaskState.Resuming)
            .ExecuteOnEntry(() => { _currentState = ScriptTaskState.Resuming; OnEnterResuming(); })
            .ExecuteOnExit(() => OnExitResuming())
            .On(TaskTrigger.ResumingCompleted)
            .Goto(ScriptTaskState.Running)
            .Execute(() => { _currentState = ScriptTaskState.Running; OnEnterRunning(); })
            .On(TaskTrigger.ErrorOccurred)
            .Goto(ScriptTaskState.Error)
            .Execute(() => { _currentState = ScriptTaskState.Error; OnEnterError(); });

        // Stopping state
        builder.In(ScriptTaskState.Stopping)
            .ExecuteOnEntry(() => { _currentState = ScriptTaskState.Stopping; OnEnterStopping(); })
            .ExecuteOnExit(() => OnExitStopping())
            .On(TaskTrigger.StoppingCompleted)
            .Goto(ScriptTaskState.Stopped)
            .Execute(() => { _currentState = ScriptTaskState.Stopped; OnEnterStopped(); })
            .On(TaskTrigger.ErrorOccurred)
            .Goto(ScriptTaskState.Error)
            .Execute(() => { _currentState = ScriptTaskState.Error; OnEnterError(); });

        // Stopped state
        builder.In(ScriptTaskState.Stopped)
            .ExecuteOnEntry(() => { _currentState = ScriptTaskState.Stopped; OnEnterStopped(); })
            .ExecuteOnExit(() => OnExitStopped())
            .On(TaskTrigger.Start)
            .Goto(ScriptTaskState.Running)
            .Execute(() => { _currentState = ScriptTaskState.Running; OnEnterRunning(); })
            .On(TaskTrigger.Dispose)
            .Execute(() => OnDispose());

        // Error state
        builder.In(ScriptTaskState.Error)
            .ExecuteOnEntry(() => { _currentState = ScriptTaskState.Error; OnEnterError(); })
            .ExecuteOnExit(() => OnExitError())
            .On(TaskTrigger.Start)
            .Goto(ScriptTaskState.Running)
            .Execute(() => { _currentState = ScriptTaskState.Running; OnEnterRunning(); })
            .On(TaskTrigger.Dispose)
            .Execute(() => OnDispose());
    }

    // Public methods to fire triggers
    public void Start()
    {
        _stateMachine.Fire(TaskTrigger.Start);
    }

    public void Pause()
    {
        _stateMachine.Fire(TaskTrigger.Pause);
    }

    // State property
    public ScriptTaskState State => _currentState;
}
```

## Key API Methods / Các Method API Chính

### StateMachineDefinitionBuilder Methods

| Method | Description | Example |
|--------|-------------|---------|
| `In(TState state)` | Bắt đầu cấu hình một state | `builder.In(TaskState.Running)` |
| `On(TTrigger trigger)` | Định nghĩa trigger cho transition | `.On(TaskTrigger.Start)` |
| `Goto(TState state)` | Chỉ định state đích | `.Goto(TaskState.Running)` |
| `Execute(Action action)` | Thực thi action khi transition | `.Execute(() => OnEnterRunning())` |
| `ExecuteOnEntry(Action action)` | Thực thi khi vào state | `.ExecuteOnEntry(() => OnEnterRunning())` |
| `ExecuteOnExit(Action action)` | Thực thi khi ra khỏi state | `.ExecuteOnExit(() => OnExitRunning())` |
| `WithInitialState(TState state)` | Đặt initial state | `.WithInitialState(TaskState.Idle)` |
| `Build()` | Build definition | `.Build()` |
| `CreatePassiveStateMachine()` | Tạo passive state machine | `.CreatePassiveStateMachine()` |

### PassiveStateMachine Methods

| Method | Description | Example |
|--------|-------------|---------|
| `Start()` | Khởi động state machine | `stateMachine.Start()` |
| `Fire(TTrigger trigger)` | Fire một trigger | `stateMachine.Fire(TaskTrigger.Start)` |
| `Stop()` | Dừng state machine | `stateMachine.Stop()` |

## ⚠️ Important Notes / Lưu Ý Quan trọng

### 1. State Tracking / Theo dõi State

**Problem**: `PassiveStateMachine` không có property `CurrentState` hoặc `CurrentStateId` để đọc state hiện tại.

**Solution**: Sử dụng một field riêng để track state và update nó trong các transition handlers:

```csharp
private ScriptTaskState _currentState;

// Update trong ExecuteOnEntry hoặc Execute
builder.In(TaskState.Running)
    .ExecuteOnEntry(() => { _currentState = TaskState.Running; OnEnterRunning(); });

// Hoặc trong Execute của transition
.On(TaskTrigger.Start)
    .Goto(TaskState.Running)
    .Execute(() => { _currentState = TaskState.Running; OnEnterRunning(); });
```

### 2. Entry/Exit Actions Order / Thứ tự Entry/Exit Actions

**Critical**: `ExecuteOnEntry()` và `ExecuteOnExit()` **PHẢI** được gọi **TRƯỚC** các `On()` calls:

```csharp
// ✅ CORRECT
builder.In(TaskState.Running)
    .ExecuteOnEntry(() => OnEnterRunning())  // First
    .ExecuteOnExit(() => OnExitRunning())   // Second
    .On(TaskTrigger.Pause)                   // Then transitions
    .Goto(TaskState.Pausing);

// ❌ WRONG - Will cause compile error
builder.In(TaskState.Running)
    .On(TaskTrigger.Pause)
    .Goto(TaskState.Pausing)
    .ExecuteOnEntry(() => OnEnterRunning()); // Error!
```

### 3. State Machine Lifecycle / Vòng đời State Machine

1. **Create**: Build definition và create state machine
2. **Start**: Gọi `Start()` để khởi động (state machine sẽ ở initial state)
3. **Fire Triggers**: Sử dụng `Fire()` để trigger transitions
4. **Stop**: Gọi `Stop()` khi không cần dùng nữa

```csharp
var stateMachine = builder
    .WithInitialState(TaskState.Idle)
    .Build()
    .CreatePassiveStateMachine();

stateMachine.Start();  // State machine is now in Idle state

// Later...
stateMachine.Fire(TaskTrigger.Start);  // Transition to Running

// When done...
stateMachine.Stop();
```

### 4. Error Handling / Xử lý Lỗi

State machine sẽ throw exception nếu:
- Fire trigger không hợp lệ (không có transition từ state hiện tại)
- State machine chưa được start
- State machine đã được stop

```csharp
try
{
    _stateMachine.Fire(TaskTrigger.Start);
}
catch (Exception ex)
{
    _logger.LogError($"Failed to fire trigger: {ex.Message}");
    throw;
}
```

### 5. Thread Safety / An toàn Luồng

`PassiveStateMachine` **không thread-safe**. Nếu cần thread safety, sử dụng lock:

```csharp
private readonly object _lockObject = new();

public void Start()
{
    lock (_lockObject)
    {
        _stateMachine.Fire(TaskTrigger.Start);
    }
}
```

## Best Practices / Thực hành Tốt nhất

### 1. Separate Configuration Method / Tách Method Cấu hình

Tách logic cấu hình state machine ra method riêng để code dễ đọc:

```csharp
private void ConfigureStateMachine(StateMachineDefinitionBuilder<TState, TTrigger> builder)
{
    // All configuration here
}
```

### 2. Consistent State Tracking / Theo dõi State Nhất quán

Luôn update `_currentState` trong cả `ExecuteOnEntry()` và `Execute()` của transitions để đảm bảo consistency:

```csharp
builder.In(TaskState.Running)
    .ExecuteOnEntry(() => { _currentState = TaskState.Running; OnEnterRunning(); })
    .On(TaskTrigger.Start)
    .Goto(TaskState.Running)
    .Execute(() => { _currentState = TaskState.Running; OnEnterRunning(); });
```

### 3. Use Descriptive Trigger Names / Sử dụng Tên Trigger Mô tả

Đặt tên trigger rõ ràng để dễ hiểu:

```csharp
// ✅ Good
TaskTrigger.PausingCompleted
TaskTrigger.ResumingCompleted
TaskTrigger.ErrorOccurred

// ❌ Bad
TaskTrigger.Done
TaskTrigger.Ok
TaskTrigger.Err
```

### 4. Document State Transitions / Tài liệu hóa State Transitions

Sử dụng comments để giải thích logic:

```csharp
// Idle → Running: Start task
builder.In(TaskState.Idle)
    .On(TaskTrigger.Start)
    .Goto(TaskState.Running);

// Running → Pausing → Paused: Pause task (wait for current execution)
builder.In(TaskState.Running)
    .On(TaskTrigger.Pause)
    .Goto(TaskState.Pausing);
```

## State Transition Patterns / Mẫu Chuyển đổi State

### Pattern 1: Simple Transition / Chuyển đổi Đơn giản

```csharp
builder.In(StateA)
    .On(TriggerX)
    .Goto(StateB)
    .Execute(() => OnEnterStateB());
```

### Pattern 2: Transition with Entry/Exit / Chuyển đổi với Entry/Exit

```csharp
builder.In(StateA)
    .ExecuteOnEntry(() => OnEnterStateA())
    .ExecuteOnExit(() => OnExitStateA())
    .On(TriggerX)
    .Goto(StateB)
    .Execute(() => OnEnterStateB());
```

### Pattern 3: Intermediate State / State Trung gian

Sử dụng intermediate state cho async operations:

```csharp
// Start → Intermediate → Final
builder.In(StateA)
    .On(TriggerStart)
    .Goto(StateIntermediate)
    .Execute(() => StartAsyncOperation());

builder.In(StateIntermediate)
    .ExecuteOnEntry(() => OnEnterIntermediate())
    .On(TriggerCompleted)
    .Goto(StateFinal)
    .Execute(() => OnEnterFinal());
```

## Common Pitfalls / Lỗi Thường gặp

### 1. Forgetting to Start / Quên Start

```csharp
// ❌ Wrong
var stateMachine = builder.Build().CreatePassiveStateMachine();
stateMachine.Fire(TaskTrigger.Start); // Exception!

// ✅ Correct
var stateMachine = builder.Build().CreatePassiveStateMachine();
stateMachine.Start();
stateMachine.Fire(TaskTrigger.Start);
```

### 2. Wrong Order of ExecuteOnEntry / Thứ tự ExecuteOnEntry Sai

```csharp
// ❌ Wrong - Compile error
builder.In(StateA)
    .On(TriggerX)
    .Goto(StateB)
    .ExecuteOnEntry(() => OnEnterStateB());

// ✅ Correct
builder.In(StateA)
    .ExecuteOnEntry(() => OnEnterStateA())
    .On(TriggerX)
    .Goto(StateB)
    .Execute(() => OnEnterStateB());
```

### 3. Not Tracking State / Không Theo dõi State

```csharp
// ❌ Wrong - No way to read current state
public TaskState State => _stateMachine.CurrentState; // Property doesn't exist!

// ✅ Correct
private TaskState _currentState;
public TaskState State => _currentState;

// Update in transitions
.Execute(() => { _currentState = TaskState.Running; OnEnterRunning(); });
```

### 4. Fire Invalid Trigger / Fire Trigger Không hợp lệ

```csharp
// ❌ Wrong - Will throw exception if no transition defined
stateMachine.Fire(TaskTrigger.Start); // If current state doesn't allow Start

// ✅ Correct - Check state first or handle exception
if (_currentState == TaskState.Idle || _currentState == TaskState.Stopped)
{
    stateMachine.Fire(TaskTrigger.Start);
}
```

## Related Documents / Tài liệu Liên quan

- [StateMachine Design](../ScriptEngine/StateMachine_Design.md) - State machine architecture cho ScriptEngine
- ScriptTask Implementation (`srcs/RobotNet10/Commons/RobotNet10.ScriptEngine/Models/ScriptTask.cs`) - Reference implementation
- [Appccelerate.StateMachine Documentation](https://github.com/appccelerate/statemachine) - Official documentation

## Example Usage in RobotNet10 / Ví dụ Sử dụng trong RobotNet10

State machine được sử dụng trong:

1. **ScriptTask** (`ScriptTask.cs`) - Task state management
2. **ScriptMissionInstance** (planned) - Mission instance state management  
3. **ScriptEngineManager** (planned) - Engine manager state management

Xem implementation chi tiết trong các file này để hiểu cách sử dụng trong context thực tế.

---

**Last Updated**: 2025-11-13
**Status**: Usage Guide for Appccelerate.StateMachine
**Version**: 1.0
**Library Version**: 6.0.0

