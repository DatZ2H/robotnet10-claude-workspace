# Project Structure & Conventions / Cấu trúc Dự án & Quy ước

## Overview / Tổng quan

Tài liệu này mô tả cấu trúc dự án RobotNet10, các thư viện được sử dụng, và các quy ước chung khi phát triển code.

## Project Structure / Cấu trúc Dự án

### Solution Organization / Tổ chức Solution

Dự án được tổ chức theo cấu trúc solution với các thư mục chính:

```
srcs/RobotNet10/
├── Commons/                          # Thư viện chung cho scripting
│   ├── RobotNet10.Script/           # Script attributes và interfaces
│   ├── RobotNet10.ScriptEngine/     # ScriptEngine core implementation
│   └── RobotNet10.MapManager/       # Map management (tương lai)
│
├── Components/                       # Blazor component libraries
│   ├── RobotNet10.Components/       # Shared UI components
│   ├── RobotNet10.MapEditor/       # Map editor components
│   └── RobotNet10.ScriptEditor/    # Script editor components
│
├── FleetManager/                     # FleetManager application
│   ├── RobotNet10.FleetManager/     # Server-side Blazor app
│   ├── RobotNet10.FleetManager.Client/  # Client-side Blazor (WASM)
│   ├── RobotNet10.FleetManager.Script/  # Script APIs cho FleetManager
│   └── RobotNet10.FleetManager.Script.Shared/  # Shared script interfaces
│
├── RobotApp/                         # RobotApp application
│   ├── RobotNet10.RobotApp/         # Server-side Blazor app
│   ├── RobotNet10.RobotApp.Client/  # Client-side Blazor (WASM)
│   ├── RobotNet10.RobotApp.Script/  # Script APIs cho RobotApp
│   └── RobotNet10.RobotApp.Script.Shared/  # Shared script interfaces
│
└── Shared/                           # Shared libraries
    ├── RobotNet10.ScriptEngine.Shared/  # ScriptEngine shared contracts
    └── RobotNet10.Shared/           # Common utilities
```

### Project Types / Các Loại Project

#### 1. Web Applications (Blazor Web App)

**RobotNet10.RobotApp** và **RobotNet10.FleetManager**:
- **SDK**: `Microsoft.NET.Sdk.Web`
- **Target Framework**: `net10.0`
- **Architecture**: Blazor Web App với Server + WASM render modes
- **Database**:
  - RobotApp: SQLite (`Microsoft.EntityFrameworkCore.Sqlite`)
  - FleetManager: SQL Server (`Microsoft.EntityFrameworkCore.SqlServer`)

#### 2. Client Projects (Blazor WASM)

**RobotNet10.RobotApp.Client** và **RobotNet10.FleetManager.Client**:
- **SDK**: `Microsoft.NET.Sdk.BlazorWebAssembly`
- **Purpose**: Client-side UI components và pages
- **Dependencies**: Reference từ Web App projects

#### 3. Script Projects

**RobotNet10.*.Script** và **RobotNet10.*.Script.Shared**:
- **SDK**: `Microsoft.NET.Sdk`
- **Purpose**: 
  - `.Script`: Implementation của script APIs
  - `.Script.Shared`: Interfaces và contracts cho script globals

#### 4. Component Libraries (Razor Class Library)

**RobotNet10.Components**, **RobotNet10.MapEditor**, **RobotNet10.ScriptEditor**:
- **SDK**: `Microsoft.NET.Sdk.Razor`
- **Purpose**: Reusable Blazor components
- **Supported Platform**: `browser` (WASM)

#### 5. Shared Libraries

**RobotNet10.ScriptEngine.Shared**, **RobotNet10.Shared**:
- **SDK**: `Microsoft.NET.Sdk`
- **Purpose**: Shared contracts, DTOs, utilities

#### 6. Commons Libraries

**RobotNet10.Script**, **RobotNet10.ScriptEngine**:
- **SDK**: `Microsoft.NET.Sdk`
- **Purpose**: Core scripting infrastructure

## Technology Stack / Công nghệ Sử dụng

### Core Framework

| Technology | Version | Purpose |
|------------|---------|---------|
| **.NET** | 10.0 | Runtime và framework |
| **C#** | Latest | Programming language |
| **Blazor** | 10.0 | Web UI framework |

### Key NuGet Packages

#### Web & UI

| Package | Version | Purpose |
|---------|---------|---------|
| `Microsoft.AspNetCore.Components.WebAssembly.Server` | 10.0.0 | Blazor WASM hosting |
| `Microsoft.AspNetCore.Components.Web` | 10.0.0 | Blazor components |
| `Microsoft.AspNetCore.Identity.EntityFrameworkCore` | 10.0.0 | Authentication & Authorization |
| `Microsoft.AspNetCore.Diagnostics.EntityFrameworkCore` | 10.0.0 | EF Core diagnostics |

#### Database

| Package | Version | Purpose | Used In |
|---------|---------|----------|---------|
| `Microsoft.EntityFrameworkCore.Sqlite` | 10.0.0 | SQLite provider | RobotApp |
| `Microsoft.EntityFrameworkCore.SqlServer` | 10.0.0 | SQL Server provider | FleetManager |
| `Microsoft.EntityFrameworkCore.Tools` | 10.0.0 | EF Core migrations | Both |

#### Scripting

| Package | Version | Purpose |
|---------|---------|---------|
| `Microsoft.CodeAnalysis.CSharp.Scripting` | 4.14.0 | C# script compilation |
| `Appccelerate.StateMachine` | 6.0.0 | State machine implementation |
| `Microsoft.AspNetCore.SignalR.Core` | 1.2.0 | SignalR for real-time communication |
| `Newtonsoft.Json` | 13.0.4 | JSON serialization |

#### Other

| Package | Version | Purpose |
|---------|---------|---------|
| `Microsoft.Extensions.DependencyInjection.Abstractions` | 10.0.0 | DI abstractions |
| `Microsoft.Extensions.Configuration.Binder` | 10.0.0 | Configuration binding |
| `Microsoft.EntityFrameworkCore.Relational` | 10.0.0 | EF Core relational features |

### Project Dependencies / Phụ thuộc Dự án

```mermaid
graph TB
    subgraph "Web Apps"
        RobotApp[RobotNet10.RobotApp]
        FleetManager[RobotNet10.FleetManager]
    end
    
    subgraph "Clients"
        RobotAppClient[RobotNet10.RobotApp.Client]
        FleetManagerClient[RobotNet10.FleetManager.Client]
    end
    
    subgraph "Script Projects"
        RobotAppScript[RobotNet10.RobotApp.Script]
        RobotAppScriptShared[RobotNet10.RobotApp.Script.Shared]
        FleetManagerScript[RobotNet10.FleetManager.Script]
        FleetManagerScriptShared[RobotNet10.FleetManager.Script.Shared]
    end
    
    subgraph "Commons"
        Script[RobotNet10.Script]
        ScriptEngine[RobotNet10.ScriptEngine]
    end
    
    subgraph "Shared"
        ScriptEngineShared[RobotNet10.ScriptEngine.Shared]
        Shared[RobotNet10.Shared]
    end
    
    subgraph "Components"
        Components[RobotNet10.Components]
        MapEditor[RobotNet10.MapEditor]
        ScriptEditor[RobotNet10.ScriptEditor]
    end
    
    RobotApp --> RobotAppClient
    RobotApp --> ScriptEngine
    FleetManager --> FleetManagerClient
    FleetManager --> ScriptEngine
    
    RobotAppScript --> RobotAppScriptShared
    RobotAppScript --> ScriptEngineShared
    RobotAppScript --> Script
    
    FleetManagerScript --> FleetManagerScriptShared
    FleetManagerScript --> ScriptEngineShared
    FleetManagerScript --> Script
    
    ScriptEngine --> ScriptEngineShared
    ScriptEngine --> Shared
    ScriptEngine --> Script
    
    Components --> ScriptEngineShared
    Components --> Shared
    
    MapEditor --> ScriptEngineShared
    MapEditor --> Shared
    
    ScriptEditor --> ScriptEngineShared
    ScriptEditor --> Shared
    
    style RobotApp fill:#e6f3ff
    style FleetManager fill:#e6f3ff
    style ScriptEngine fill:#fff0e6
```

## Naming Conventions / Quy ước Đặt tên

### Namespaces

**Pattern**: `RobotNet10.{ProjectName}[.{SubNamespace}]`

**Examples**:
```csharp
namespace RobotNet10.Script;                    // Commons
namespace RobotNet10.ScriptEngine.Shared;       // Shared
namespace RobotNet10.RobotApp.Script.Shared;    // Script shared
namespace RobotNet10.Components.Clients;         // Components
```

**Rules**:
- ✅ Use PascalCase
- ✅ Match project/folder structure
- ✅ Avoid abbreviations unless widely understood
- ✅ Keep namespaces shallow (max 3-4 levels)

### Classes & Interfaces

**Interfaces**:
```csharp
// Prefix with 'I'
public interface IScriptGlobals { }
public interface IRobotAppScriptGlobals { }
public interface ILogger { }
```

**Classes**:
```csharp
// PascalCase, descriptive names
public class ScriptEngine { }
public class HubClient { }
public class TaskAttribute : Attribute { }
```

**Abstract Classes**:
```csharp
// PascalCase, can be abstract
public abstract class HubClient { }
```

**Rules**:
- ✅ Use PascalCase
- ✅ Use descriptive names (avoid abbreviations)
- ✅ Interfaces start with 'I'
- ✅ Attributes end with 'Attribute' (e.g., `TaskAttribute`)

### Methods & Properties

**Methods**:
```csharp
// PascalCase, verb-based names
public async Task StartAsync() { }
public void EnableTask(string name) { }
public Task<Guid> CreateMission(string name, params object[] args) { }
```

**Properties**:
```csharp
// PascalCase, noun-based names
public IRobot Robot { get; }
public bool IsConnected => Connection.State == HubConnectionState.Connected;
public int Interval { get; }
```

**Async Methods**:
- ✅ Always end with `Async` suffix
- ✅ Return `Task` or `Task<T>`
- ✅ Use `async/await` pattern

**Rules**:
- ✅ Use PascalCase
- ✅ Methods: verb-based (e.g., `StartAsync`, `EnableTask`)
- ✅ Properties: noun-based (e.g., `Robot`, `IsConnected`)
- ✅ Async methods: suffix `Async`

### Fields & Variables

**Private Fields**:
```csharp
// camelCase with underscore prefix (if needed for clarity)
private readonly HubConnection Connection;
private readonly ManualResetEvent connectedWaitHandler;
```

**Local Variables**:
```csharp
// camelCase
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
var app = builder.Build();
```

**Constants**:
```csharp
// PascalCase
public const int DefaultInterval = 60;
public const string DefaultConnectionString = "DefaultConnection";
```

**Rules**:
- ✅ Private fields: camelCase (or underscore prefix if needed)
- ✅ Local variables: camelCase
- ✅ Constants: PascalCase

### Attributes

**Custom Attributes**:
```csharp
// End with 'Attribute', PascalCase
[AttributeUsage(AttributeTargets.Method, AllowMultiple = false, Inherited = false)]
public class TaskAttribute(int interval, bool autoStart = true) : Attribute
{
    public int Interval { get; } = interval;
    public bool AutoStart { get; } = autoStart;
}
```

**Usage**:
```csharp
[Task(interval: 60, autoStart: true)]
public void MonitorTask() { }
```

### Project & File Names

**Projects**:
- ✅ Format: `RobotNet10.{Component}.{SubComponent}`
- ✅ Examples: `RobotNet10.RobotApp`, `RobotNet10.FleetManager.Client`

**Files**:
- ✅ Match class/interface name (one class per file)
- ✅ Use PascalCase: `HubClient.cs`, `TaskAttribute.cs`

**Folders**:
- ✅ Use PascalCase: `Components/`, `Clients/`, `Data/`

## Code Organization Principles / Nguyên tắc Tổ chức Code

### 1. Separation of Concerns / Phân tách Trách nhiệm

**Layers**:
- **Presentation**: Blazor components và pages
- **Application**: Business logic và services
- **Data**: Database access (EF Core)
- **Infrastructure**: External integrations (MQTT, hardware)

### 2. Dependency Injection / Tiêm Phụ thuộc

**Pattern**: Constructor injection

```csharp
public class OrderManager
{
    private readonly INavigationService _navigation;
    private readonly ILogger<OrderManager> _logger;
    
    public OrderManager(INavigationService navigation, ILogger<OrderManager> logger)
    {
        _navigation = navigation;
        _logger = logger;
    }
}
```

**Registration**:
```csharp
// In Program.cs
builder.Services.AddScoped<IOrderManager, OrderManager>();
builder.Services.AddSingleton<IRobotController, RobotController>();
```

### 3. Async/Await Pattern / Mẫu Async/Await

**Always use async for I/O operations**:

```csharp
public async Task<bool> HandleOrderAsync(Order order)
{
    // Validate
    if (!ValidateOrder(order))
        return false;
    
    // Process (async)
    await _navigation.MoveToNodeAsync(order.Nodes[0].NodeId);
    
    return true;
}
```

**Rules**:
- ✅ All I/O operations: async
- ✅ Database queries: async
- ✅ MQTT operations: async
- ✅ HTTP requests: async
- ✅ File operations: async

### 4. Error Handling / Xử lý Lỗi

**Pattern**: Structured exception handling

```csharp
try
{
    await ProcessOrderAsync(order);
}
catch (ValidationException ex)
{
    _logger.LogWarning(ex, "Order validation failed: OrderId={OrderId}", order.OrderId);
    return false;
}
catch (Exception ex)
{
    _logger.LogError(ex, "Unexpected error processing order: OrderId={OrderId}", order.OrderId);
    throw;
}
```

### 5. Logging / Ghi Log

**Pattern**: Structured logging với parameters

```csharp
_logger.LogInformation("Order received: OrderId={OrderId}, UpdateId={UpdateId}", 
    order.OrderId, order.OrderUpdateId);

_logger.LogWarning("Robot not available: SerialNumber={SerialNumber}", serialNumber);

_logger.LogError(ex, "Failed to process order: OrderId={OrderId}", order.OrderId);
```

**Rules**:
- ✅ Use structured logging (parameters, not string interpolation)
- ✅ Appropriate log levels (Debug, Information, Warning, Error)
- ✅ Include context (OrderId, SerialNumber, etc.)

## Project Configuration / Cấu hình Dự án

### Common Properties / Thuộc tính Chung

**Target Framework**:
```xml
<TargetFramework>net10.0</TargetFramework>
```

**Nullable Reference Types**:
```xml
<Nullable>enable</Nullable>
```

**Implicit Usings**:
```xml
<ImplicitUsings>enable</ImplicitUsings>
```

**Documentation**:
```xml
<GenerateDocumentationFile>True</GenerateDocumentationFile>
```

### Blazor-Specific Properties / Thuộc tính Blazor

**Disable Navigation Exception**:
```xml
<BlazorDisableThrowNavigationException>true</BlazorDisableThrowNavigationException>
```

**User Secrets** (for development):
```xml
<UserSecretsId>aspnet-RobotNet10_RobotApp-{guid}</UserSecretsId>
```

## Project References / Tham chiếu Dự án

### Reference Patterns / Mẫu Tham chiếu

**Web App → Client**:
```xml
<ProjectReference Include="..\RobotNet10.RobotApp.Client\RobotNet10.RobotApp.Client.csproj" />
```

**Script → Script Shared**:
```xml
<ProjectReference Include="..\RobotNet10.RobotApp.Script.Shared\RobotNet10.RobotApp.Script.Shared.csproj" />
```

**ScriptEngine → Commons**:
```xml
<ProjectReference Include="..\RobotNet10.Script\RobotNet10.Script.csproj" />
```

**Components → Shared**:
```xml
<ProjectReference Include="..\..\Shared\RobotNet10.ScriptEngine.Shared\RobotNet10.ScriptEngine.Shared.csproj" />
<ProjectReference Include="..\..\Shared\RobotNet10.Shared\RobotNet10.Shared.csproj" />
```

### Dependency Rules / Quy tắc Phụ thuộc

**Allowed**:
- ✅ Web App → Client
- ✅ Web App → ScriptEngine
- ✅ Script → Script.Shared
- ✅ Script → ScriptEngine.Shared
- ✅ ScriptEngine → Script (Commons)
- ✅ Components → Shared libraries

**Not Allowed**:
- ❌ Client → Server (WASM cannot reference server code)
- ❌ Shared → Application-specific projects
- ❌ Circular dependencies

## Folder Structure / Cấu trúc Thư mục

### Standard Folders / Thư mục Chuẩn

**Web Applications**:
```
RobotNet10.RobotApp/
├── Components/          # Blazor components
├── Data/                # EF Core DbContext
├── Pages/               # Blazor pages (if needed)
├── Properties/          # Assembly info, launch settings
├── wwwroot/             # Static files
├── Program.cs           # Application entry point
└── appsettings.json     # Configuration
```

**Component Libraries**:
```
RobotNet10.Components/
├── Clients/             # SignalR clients
├── _Imports.razor       # Global imports
├── wwwroot/             # Static assets
└── *.razor              # Component files
```

**Script Projects**:
```
RobotNet10.RobotApp.Script/
├── IRobot.cs            # Script APIs interface
└── *.cs                 # Implementation files
```

## Code Style Guidelines / Hướng dẫn Phong cách Code

### C# Language Features / Tính năng C#

**Preferred**:
- ✅ Primary constructors (C# 12)
- ✅ Collection expressions
- ✅ Pattern matching
- ✅ Nullable reference types
- ✅ File-scoped namespaces

**Example**:
```csharp
namespace RobotNet10.Script;

[AttributeUsage(AttributeTargets.Method, AllowMultiple = false, Inherited = false)]
public class TaskAttribute(int interval, bool autoStart = true) : Attribute
{
    public int Interval { get; } = interval;
    public bool AutoStart { get; } = autoStart;
}
```

### XML Documentation / Tài liệu XML

**Required for public APIs**:
```csharp
/// <summary>
/// Thuộc tính để đánh dấu một phương thức là một tác vụ định kỳ trong hệ thống RobotNet.
/// </summary>
/// <param name="interval">Thời gian định kỳ để thực hiện tác vụ, tính bằng giy.</param>
/// <param name="autoStart">Cho phép tác vụ này tự động bắt đầu khi hệ thống khởi động hay không.</param>
[AttributeUsage(AttributeTargets.Method, AllowMultiple = false, Inherited = false)]
public class TaskAttribute(int interval, bool autoStart = true) : Attribute
{
    /// <summary>
    /// Thời gian định kỳ để thực hiện tác vụ, tính bằng giy.
    /// </summary>
    public int Interval { get; } = interval;
}
```

## Versioning / Phiên bản

### .NET Version

- **Current**: .NET 10.0
- **Target**: Latest LTS when available

### Package Versions

- **Strategy**: Use latest stable versions compatible with .NET 10
- **Update Policy**: Regular updates, test before upgrading

## Related Documents / Tài liệu Liên quan

- [Architecture Overview](../architecture/README.md) - System architecture
- [AI Collaboration Guide](../ai-guide/README.md) - AI agent guidelines
- [ScriptEngine Documentation](../ScriptEngine/README.md) - Scripting system
- [Development Guide](README.md) - Development setup (if exists)

---

**Last Updated**: 2025-11-13
**Status**: Project Structure & Conventions Document
**Version**: 1.0

