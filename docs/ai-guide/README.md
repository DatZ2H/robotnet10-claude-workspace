# AI Collaboration Guide / Huong dan cho AI Agents

## Welcome AI Agent! / Chao mung AI Agent!

Tài liệu này được thiết kế đặc biệt để giúp các AI agents (như bạn) hiểu nhanh dự án RobotNet10 và làm việc hiệu quả.

**QUAN TRỌNG**: Đọc tài liệu này TRƯỚC KHI bắt đầu làm việc với dự án.

## Quick Context / Boi canh Nhanh

### Project Summary / Tóm tắt Dự án

**What**: Mobile robot AMR fleet management system
**Goal**: Manage multiple autonomous mobile robots following VDA 5050 standard
**Components**:
- **RobotApp**: Software runs on each robot (Ubuntu 22.04)
- **FleetManager**: Central management system on factory server
- **Communication**: MQTT broker with VDA 5050 protocol

**Technology Stack**:
- **.NET 10** (C#) - FleetManager và RobotApp
- **Blazor Web App** (Web UI) - FleetManager dashboard
- **MQTT** (MQTTnet library) - VDA 5050 communication
- **SQL Server** - FleetManager database
- **SQLite** - RobotApp local database
- **VDA 5050** (v2.1.0) - Standard protocol (backward compatible with v2.0.0)
- **VDMA LIF** - Map data standard

### Project Status / Trang thai Du an

**Current Phase**: Active Development

**What exists**:
- ✅ 47 projects in solution (.slnx format)
- ✅ 1,304+ .cs source files across all layers
- ✅ RobotApp with full communication stack (CANOpen, LiDAR, SLAM)
- ✅ FleetManager with 7 core modules
- ✅ 5 test projects (NUnit)
- ✅ Linux RT kernel 6.6.116 prepared
- ✅ Comprehensive documentation

**This means**: You are modifying EXISTING code, not creating from scratch. Read existing patterns before making changes.

## Key Design Decisions / Quyet dinh Thiet ke Quan trong

### 1. Why VDA 5050?
- **Interoperability**: Work with third-party systems
- **Standardization**: Clear protocol specification
- **Industry adoption**: Widely supported

### 2. Why .NET/Blazor?
- **Cross-platform**: Runs on Linux (robots) and Windows/Linux (server)
- **Performance**: High-performance runtime
- **Unified UI**: Blazor for both RobotApp and FleetManager web interfaces
- **Strong typing**: C# type safety reduces bugs
- **Ecosystem**: Rich libraries (MQTTnet, EF Core, etc.)

### 3. Why MQTT?
- **Lightweight**: Low overhead for IoT/robotics
- **Publish-Subscribe**: Perfect for 1-to-many communication
- **QoS Levels**: Reliable message delivery
- **VDA 5050 requirement**: Standard specifies MQTT

### 4. Architecture Pattern
- **Modular Service Architecture**: Tổ chức theo chức năng (Services/, Controllers/, Hubs/)
- **Dependency Injection**: Testable, maintainable code
- **Async/Await**: Non-blocking I/O operations

### 5. FleetManager Core Modules
FleetManager được tổ chức thành 7 core modules:

1. **Identity**: Authentication & Authorization (ASP.NET Identity mặc định, Components/Account/ — không phải module riêng)
2. **MapEditor**: Map management theo VDMA LIF standard (shared library)
3. **RobotConnections**: MQTT connection management, heartbeat monitoring
4. **RobotManager**: Robot state, order, và action management
5. **TrafficControl**: Route calculation (A*), conflict detection & resolution
6. **ScriptEngine**: C# scripting engine cho custom behaviors (shared library)
7. **FleetManagerConfig**: Dynamic configuration management (runtime updates)

**Important**: ScriptEngine và MapEditor là shared libraries được dùng bởi cả RobotApp và FleetManager.

## Code Organization Principles / Nguyen tac To chuc Code

### Project Structure (actual, from .slnx)

```
srcs/RobotNet10/
├── Commons/                    # Business logic libraries (10 projects)
│   ├── RobotNet10.Common/
│   ├── RobotNet10.CustomConfiguration/
│   ├── RobotNet10.GlobalPathPlanner/
│   ├── RobotNet10.MapManager/
│   ├── RobotNet10.MqttConnection/
│   ├── RobotNet10.NavigationTune/
│   ├── RobotNet10.Realtime/
│   ├── RobotNet10.Script/
│   ├── RobotNet10.ScriptEngine/
│   └── RobotNet10.StorageManager/
│
├── Components/                 # Blazor UI libraries (5 projects)
│   ├── RobotNet10.Components/
│   ├── RobotNet10.CustomConfigurationEditor/
│   ├── RobotNet10.MapEditor/
│   ├── RobotNet10.NavigationTuneUI/
│   └── RobotNet10.ScriptEditor/
│
├── RobotApp/                   # Robot-side app (5 projects + 8 communication)
│   ├── RobotNet10.RobotApp/
│   ├── RobotNet10.RobotApp.Client/
│   ├── RobotNet10.RobotApp.Script/
│   ├── RobotNet10.RobotApp.Script.Shared/
│   ├── RobotNet10.RobotApp.Shared/
│   └── Communication/         # Hardware drivers
│       ├── RobotNet10.CANOpen/
│       ├── RobotNet10.CANOpen.CiA402/
│       ├── CartographerSharp/
│       ├── CeresSharp/
│       ├── Olei.LidarSensor/
│       ├── Sick.ColaB/
│       └── Sick.SafetyScanners/
│
├── FleetManager/               # Server-side app (5 projects)
│   ├── RobotNet10.FleetManager/
│   ├── RobotNet10.FleetManager.Client/
│   ├── RobotNet10.FleetManager.Script/
│   ├── RobotNet10.FleetManager.Script.Shared/
│   └── RobotNet10.FleetManager.Shared/
│
├── Shared/                     # Cross-app models (5 projects)
│   ├── RobotNet.VDA5050/
│   ├── RobotNet10.MapEditor.Shared/
│   ├── RobotNet10.NavigationTune.Shared/
│   ├── RobotNet10.ScriptEngine.Shared/
│   └── RobotNet10.Shared/
│
└── Tests/                      # Test projects (5 projects)
    ├── RobotNet10.GlobalPathPlanner.Test/
    ├── RobotNet10.MapManager.Test/
    ├── RobotNet10.RobotManager.Test/
    ├── RobotNet10.ScriptEngine.Test/
    └── RobotNet10.StorageManager.Test/
```

**Important Notes**:
- Total: **47 projects**, **1,304+ .cs files**
- ScriptEngine and MapEditor are shared libraries used by both RobotApp and FleetManager
- FleetManager uses **SQL Server**, RobotApp uses **SQLite**
- Communication drivers live under RobotApp/ (robot-side only)
- Solution uses modern **.slnx** format

### Naming Conventions

**Interfaces**:
```csharp
public interface IFleetCoordinator { }
public interface IMissionPlanner { }
public interface IVda5050Handler { }
```

**Services**:
```csharp
public class FleetCoordinator : IFleetCoordinator { }
public class MissionPlanner : IMissionPlanner { }
```

**Models** (VDA 5050 - match standard):
```csharp
public class OrderMsg { }   // VDA 5050 Order (suffix Msg)
public class StateMsg { }   // VDA 5050 State (suffix Msg)
public class Node { }       // Exactly as in VDA 5050
```

**Models** (Domain-specific):
```csharp
public class Robot { }
public class Mission { }
public class Waypoint { }
```

## Important Patterns / Cac Pattern Quan trong

### 1. Dependency Injection

**Always use constructor injection**:
```csharp
public class FleetCoordinator : IFleetCoordinator
{
    private readonly ILogger<FleetCoordinator> _logger;
    private readonly IMqttClient _mqttClient;

    // ✅ Correct: Constructor injection
    public FleetCoordinator(
        ILogger<FleetCoordinator> logger,
        IMqttClient mqttClient)
    {
        _logger = logger;
        _mqttClient = mqttClient;
    }
}

// ❌ Wrong: Don't use service locator pattern
public class BadExample
{
    public void DoSomething()
    {
        var service = ServiceLocator.Get<ISomeService>(); // Don't do this
    }
}
```

### 2. Async/Await

**All I/O operations must be async**:
```csharp
// ✅ Correct
public async Task PublishStateAsync(RobotState state)
{
    var message = CreateMqttMessage(state);
    await _mqttClient.PublishAsync(message);
}

// ❌ Wrong: Blocking synchronous call
public void PublishState(RobotState state)
{
    var message = CreateMqttMessage(state);
    _mqttClient.PublishAsync(message).Wait(); // Don't do this
}
```

### 3. VDA 5050 Message Handling

**Always validate VDA 5050 messages**:
```csharp
public class OrderProcessor
{
    private readonly IVda5050Validator _validator;

    public async Task<bool> ProcessOrderAsync(Order order)
    {
        // 1. Validate against VDA 5050 spec
        var validationResult = _validator.ValidateOrder(order);
        if (!validationResult.IsValid)
        {
            _logger.LogError("Invalid order: {Errors}", validationResult.Errors);
            return false;
        }

        // 2. Check business logic
        if (!IsOrderFeasible(order))
        {
            _logger.LogWarning("Order not feasible: {OrderId}", order.OrderId);
            return false;
        }

        // 3. Process order
        await ExecuteOrderAsync(order);
        return true;
    }
}
```

## Critical Implementation Guidelines / Huong dan Trien khai Quan trong

### 1. VDA 5050 Compliance / Tuân thủ VDA 5050

**DO**:
- ✅ Use exact field names from VDA 5050 specification
- ✅ Follow sequence ID ordering (nodes: even, edges: odd)
- ✅ Validate all messages against VDA 5050 schema
- ✅ Handle all mandatory fields
- ✅ Implement all required message types

**DON'T**:
- ❌ Change VDA 5050 field names (e.g., don't rename `orderId` to `OrderId`)
- ❌ Skip message validation
- ❌ Ignore optional fields that might be used by third-party systems

**Example - VDA 5050 Model naming**:
```csharp
// Codebase dùng suffix Msg: OrderMsg, StateMsg (KHÔNG phải Order, State)
// Field names match VDA 5050 spec via [JsonPropertyName("camelCase")]
// Xem Shared/RobotNet.VDA5050/ cho models thực tế
```

### 2. MQTT Connection Management / Quản lý Kết nối MQTT

**Implement reconnection logic**:
```csharp
public class MqttService
{
    private readonly IMqttClient _mqttClient;
    private bool _isReconnecting;

    public async Task ConnectAsync()
    {
        var options = new MqttClientOptionsBuilder()
            .WithTcpServer(_config.BrokerAddress, _config.Port)
            .WithClientId(_config.ClientId)
            .WithCleanSession(false)
            .WithKeepAlivePeriod(TimeSpan.FromSeconds(60))
            .Build();

        _mqttClient.DisconnectedAsync += async e =>
        {
            if (_isReconnecting) return;

            _isReconnecting = true;
            _logger.LogWarning("MQTT disconnected. Reconnecting...");

            await Task.Delay(TimeSpan.FromSeconds(5));

            try
            {
                await _mqttClient.ConnectAsync(options);
                _logger.LogInformation("MQTT reconnected successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "MQTT reconnection failed");
            }
            finally
            {
                _isReconnecting = false;
            }
        };

        await _mqttClient.ConnectAsync(options);
    }
}
```

### 3. Error Handling / Xử lý Lỗi

**Use structured error handling**:
```csharp
// Codebase dùng MessageResult<T> (record type) cho error handling
// KHÔNG phải Result<T> (class) — xem Shared/ cho định nghĩa thực tế
```

### 4. Logging Best Practices / Thực hành Log tốt

```csharp
public class OrderProcessor
{
    private readonly ILogger<OrderProcessor> _logger;

    public async Task ProcessOrderAsync(Order order)
    {
        // ✅ Use structured logging with parameters
        _logger.LogInformation(
            "Processing order: OrderId={OrderId}, UpdateId={UpdateId}, Nodes={NodeCount}",
            order.OrderId,
            order.OrderUpdateId,
            order.Nodes.Count
        );

        // ❌ Don't use string interpolation in logs
        // _logger.LogInformation($"Processing order: {order.OrderId}");

        try
        {
            await ExecuteOrderAsync(order);
            _logger.LogInformation("Order completed: {OrderId}", order.OrderId);
        }
        catch (Exception ex)
        {
            // ✅ Include exception and context
            _logger.LogError(ex,
                "Failed to process order: OrderId={OrderId}",
                order.OrderId
            );
        }
    }
}
```

## Common Tasks & Workflows / Nhiem vu & Quy trinh Thuong gap

### Task 1: Implement a VDA 5050 Message Handler

**Steps**:
1. Review VDA 5050 specification for the message type
2. Create/verify model in `Shared/VDA5050/Models/`
3. Create handler in appropriate project
4. Add validation logic
5. Implement business logic
6. Add unit tests
7. Add integration tests

**Example**:
```csharp
// Codebase dùng OrderMsg (không phải Order) — xem Shared/RobotNet.VDA5050/
// Xem existing handlers trong RobotApp/Services/ cho patterns thực tế
```

### Task 2: Add New Service

**Steps**:
1. Define interface in appropriate namespace
2. Implement service class
3. Add dependencies via constructor injection
4. Add unit tests
5. Register in DI container (Program.cs)
6. Use in other services/controllers

**Example**:
```csharp
// 1. Interface
public interface IMissionPlanner
{
    Task<Mission> CreateMissionAsync(MissionRequest request);
    Task<bool> ValidateMissionAsync(Mission mission);
}

// 2. Implementation
public class MissionPlanner : IMissionPlanner
{
    private readonly ILogger<MissionPlanner> _logger;
    private readonly IRouteOptimizer _routeOptimizer;

    public MissionPlanner(
        ILogger<MissionPlanner> logger,
        IRouteOptimizer routeOptimizer)
    {
        _logger = logger;
        _routeOptimizer = routeOptimizer;
    }

    public async Task<Mission> CreateMissionAsync(MissionRequest request)
    {
        // Implementation
    }

    public async Task<bool> ValidateMissionAsync(Mission mission)
    {
        // Implementation
    }
}

// 3. Register
builder.Services.AddScoped<IMissionPlanner, MissionPlanner>();
```

### Task 3: Add Database Entity

**Steps**:
1. Create model class in Models/
2. Add DbSet to DbContext
3. Create migration
4. Apply migration
5. Create repository (if needed)
6. Add seed data (if needed)

**Example**:
```csharp
// 1. Model
public class Robot
{
    public Guid Id { get; set; }
    public string SerialNumber { get; set; }
    public string Manufacturer { get; set; }
    public RobotStatus Status { get; set; }
    public double? CurrentX { get; set; }
    public double? CurrentY { get; set; }
    public double? BatteryLevel { get; set; }
    public DateTime Created { get; set; }
    public DateTime Modified { get; set; }
}

// 2. DbContext
public class FleetDbContext : DbContext
{
    public DbSet<Robot> Robots { get; set; }
    public DbSet<Mission> Missions { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Robot>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.SerialNumber).IsUnique();
            entity.Property(e => e.SerialNumber).IsRequired().HasMaxLength(50);
        });
    }
}

// 3. Create migration
// dotnet ef migrations add AddRobotEntity

// 4. Apply migration
// dotnet ef database update
```

## When to Ask for Human Help / Khi nao Can Hoi Con nguoi

**Ask for clarification when**:
- Requirements are ambiguous or conflicting
- Multiple valid approaches exist (e.g., architectural decisions)
- Security-sensitive decisions
- Performance trade-offs
- Budget constraints (e.g., cloud services)

**You can decide independently**:
- Naming conventions (follow established patterns)
- Code organization (follow project structure)
- Implementation details (algorithms, data structures)
- Refactoring for code quality
- Adding logging/error handling
- Writing tests

## Learning Resources for AI / Tai lieu Hoc cho AI

**Documentation Structure Note**:
Tài liệu đã được tổ chức thành cấu trúc modular:
- Mỗi module có file README.md tổng quan và các file chi tiết riêng
- FleetManager: 7 module files trong `docs/fleetmanager/`
- ScriptEngine: 9 module files trong `docs/ScriptEngine/`
- MapEditor: 7 module files trong `docs/MapEditor/`
- Luôn bắt đầu từ README.md của module để có overview, sau đó đọc các file chi tiết khi cần

**Priority Reading Order**:
1. **This document** (you're here!) - Start here
2. [Architecture Overview](../architecture/README.md) - Understand system design
3. [FleetManager Documentation](../fleetmanager/README.md) - Core modules overview
   - [Identity Module](../fleetmanager/Identity.md) - Authentication & Authorization
   - [MapEditor Module](../fleetmanager/MapEditor.md) - Map management
   - [RobotConnections Module](../fleetmanager/RobotConnections.md) - MQTT management
   - [RobotManager Module](../fleetmanager/RobotManager.md) - Robot state & orders
   - [TrafficControl Module](../fleetmanager/TrafficControl.md) - Route & conflict resolution
   - [ScriptEngine Module](../fleetmanager/ScriptEngine.md) - Scripting integration
   - [FleetManagerConfig Module](../fleetmanager/FleetManagerConfig.md) - Configuration
4. [ScriptEngine Documentation](../ScriptEngine/README.md) - Shared scripting library
   - [Script Files](../ScriptEngine/ScriptFiles.md)
   - [Variables](../ScriptEngine/Variables.md)
   - [Tasks](../ScriptEngine/Tasks.md)
   - [Missions](../ScriptEngine/Missions.md)
   - [Extension APIs](../ScriptEngine/ExtensionAPIs.md)
5. [MapEditor Documentation](../MapEditor/README.md) - Shared map editor library
   - [VDMA LIF Standard](../MapEditor/VDMA_LIF_Standard.md)
   - [Database Design](../MapEditor/Database_Design.md)
   - [PathFinding](../MapEditor/PathFinding.md)
6. [VDA 5050 Integration](../vda5050/README.md) - Critical protocol details
7. [RobotApp Documentation](../robotapp/README.md) - Robot-side implementation
8. [Development Guide](../development/README.md) - Technical setup

**When implementing**:
- VDA 5050 spec: Official standard document
- .NET docs: https://docs.microsoft.com/en-us/dotnet/
- MQTTnet: https://github.com/dotnet/MQTTnet

## Pre-Implementation Checklist / Checklist Truoc Khi Code

Before starting a task, verify:
- [ ] I understand the requirement clearly
- [ ] I've read relevant documentation
- [ ] I know which project the code belongs to (RobotApp/FleetManager/Shared)
- [ ] I understand the dependencies needed
- [ ] I know the design patterns to follow
- [ ] I understand VDA 5050 requirements (if applicable)
- [ ] I know how to test the feature

## Getting Started / Bat dau

**First steps for a new AI agent joining the project**:

1. **Read this document completely**
2. **Scan architecture docs** for system understanding
3. **Review VDA 5050 docs** if working on protocol
4. **Check current project status** (see git commits, issues)
5. **Ask clarifying questions** if needed
6. **Start coding** following patterns above

## Pro Tips for AI Agents / Meo cho AI Agents

1. **Always validate VDA 5050 compliance** - This is critical for interoperability
2. **Use structured logging** - Makes debugging easier for humans
3. **Write async code** - All I/O should be non-blocking
4. **Follow naming conventions** - Consistency matters
5. **Add XML documentation** - Helps other AI and human developers
6. **Think about error cases** - Don't just code the happy path
7. **Consider scalability** - System will manage 100+ robots
8. **Security first** - Validate inputs, encrypt sensitive data
9. **Test your code** - Write unit tests
10. **Keep it simple** - Don't over-engineer

## Collaboration with Humans / Cong tac voi Con nguoi

**Communication style**:
- Be concise but complete
- Explain technical decisions
- Highlight trade-offs
- Ask questions when uncertain
- Provide examples

**Code review expectations**:
- Humans will review your code
- Be open to feedback
- Explain your reasoning
- Learn from review comments

## Summary / Tom tat

**Remember**:
- **Goal**: Build VDA 5050-compliant AMR fleet management system
- **Tech**: .NET 10, Blazor Web App, MQTT, SQL Server (FleetManager), SQLite (RobotApp)
- **Standards**: VDA 5050 v2.1.0 (backward compatible with v2.0.0), VDMA LIF, Modular Service Architecture, Async/Await
- **Structure**: 47 projects across 6 layers (Shared, Commons, Components, RobotApp, FleetManager, Communication)
- **Quality**: Tests (NUnit), structured logging (NLog), error handling, validation
- **Key Modules**: Identity, MapEditor, RobotConnections, RobotManager, TrafficControl, ScriptEngine, FleetManagerConfig

> [!NOTE]
> For Claude Code users: `.claude/CLAUDE.md` provides the primary project context.
> This file serves as supplementary reference for all AI agents.

---

**Last Updated**: 2026-03-15
**Status**: Essential Reading for AI Agents
**Version**: 3.0 (Updated project status, removed banned emojis, added Claude Code reference)
