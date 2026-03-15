# Architecture Overview / Tổng quan Kiến trúc

## Mục đích / Purpose

Tài liệu này mô tả kiến trúc tổng thể của hệ thống RobotNet10 - một hệ thống quản lý đội xe robot AMR (Autonomous Mobile Robot) tuân thủ tiêu chuẩn VDA 5050.

## Bối cảnh Dự án / Project Context

### Vấn đề Cần Giải quyết

Trong môi trường sản xuất hiện đại (Industry 4.0), các nhà máy cần:
- **Tự động hóa vận chuyển nội bộ**: Di chuyển nguyên vật liệu, sản phẩm giữa các trạm
- **Quản lý nhiều robot**: Điều phối hàng chục đến hàng trăm robot làm việc đồng thời
- **Tương thác với nhiều hệ thống**: Tích hợp với WMS, ERP, MES
- **Linh hoạt và mở rộng**: Dễ dàng thêm robot, thay đổi layout nhà máy

### Giải pháp RobotNet10

RobotNet10 cung cấp:
1. **Hệ thống quản lý đội xe tập trung** (FleetManager) - Điều phối toàn bộ fleet
2. **Phần mềm điều khiển robot** (RobotApp) - Chạy trên từng robot
3. **Tuân thủ VDA 5050** - Tương thác với robot/hệ thống của bên thứ 3
4. **Scripting mạnh mẽ** (ScriptEngine) - Tùy chỉnh hành vi mà không cần rebuild
5. **Quản lý bản đồ** (MapEditor) - Tuân thủ VDMA LIF standard

## Kiến trúc Tổng thể / High-Level Architecture

```mermaid
graph TB
    subgraph Factory[" Factory Network"]
        subgraph FleetMgr["FleetManager Server"]
            UI[Web Dashboard<br/>Blazor Web App<br/>.NET 10]
            FleetCore[Fleet Management<br/>Core Services<br/>ScriptEngine Integration]
            VDA_FM[VDA 5050<br/>Protocol Handler]
            DB[(Database<br/>SQL Server)]

            UI --> FleetCore
            FleetCore --> VDA_FM
            FleetCore --> DB
        end

        MQTT[MQTT Broker<br/>Eclipse Mosquitto]

        subgraph Robot1[" Robot #1"]
            RApp1[RobotApp]
            VDA_R1[VDA 5050<br/>Handler]
            Nav1[Navigation &<br/>Control]
            HW1[Hardware<br/>Interface]

            RApp1 --> VDA_R1
            VDA_R1 --> Nav1
            Nav1 --> HW1
        end

        subgraph Robot2[" Robot #2"]
            RApp2[RobotApp]
            VDA_R2[VDA 5050<br/>Handler]
            Nav2[Navigation &<br/>Control]
            HW2[Hardware<br/>Interface]

            RApp2 --> VDA_R2
            VDA_R2 --> Nav2
            Nav2 --> HW2
        end

        subgraph RobotN[" Robot #N"]
            RAppN[RobotApp]
            VDA_RN[VDA 5050<br/>Handler]
            NavN[Navigation &<br/>Control]
            HWN[Hardware<br/>Interface]

            RAppN --> VDA_RN
            VDA_RN --> NavN
            NavN --> HWN
        end

        VDA_FM <-->|Order/InstantActions| MQTT
        MQTT <-->|State/Visualization| VDA_R1
        MQTT <-->|State/Visualization| VDA_R2
        MQTT <-->|State/Visualization| VDA_RN
    end

    Operator[ Operator] -->|Web Browser| UI

    style Factory fill:#f0f8ff
    style FleetMgr fill:#e6f3ff
    style Robot1 fill:#fff0e6
    style Robot2 fill:#fff0e6
    style RobotN fill:#fff0e6
```

### Các Thành phần Chính / Core Components

#### 1. FleetManager (Server)
**Vai trò**: Hệ thống điều phối trung tâm
- Quản lý toàn bộ đội xe robot
- Lập kế hoạch nhiệm vụ (mission planning)
- Tối ưu hóa lộ trình
- Giải quyết xung đột giữa robot
- Giao diện web cho operator

**Triển khai**: Server tại nhà máy (Linux/Windows)

#### 2. RobotApp (On Robot)
**Vai trò**: Phần mềm điều khiển robot đơn lẻ
- Nhận lệnh từ FleetManager
- Điều khiển robot di chuyển
- Báo cáo trạng thái
- Xử lý tình huống khẩn cấp
- Giao diện web cấu hình local

**Triển khai**: Máy tính nhúng trên robot (Ubuntu 22.04)

#### 3. MQTT Broker
**Vai trò**: Message broker cho giao tiếp
- Trung gian giữa FleetManager và RobotApps
- Hỗ trợ publish-subscribe pattern
- QoS levels theo VDA 5050
- TLS/SSL security

**Lựa chọn**: Eclipse Mosquitto (recommended)

## Luồng Giao tiếp / Communication Flow

### Quy trình Gán Nhiệm vụ / Order Assignment Flow

```mermaid
sequenceDiagram
    participant FM as FleetManager
    participant MQTT as MQTT Broker
    participant R as RobotApp

    Note over FM: Operator creates mission
    FM->>FM: Generate VDA 5050 Order
    FM->>MQTT: Publish Order
    Note over FM,MQTT: Topic: uagv/v2/{mfr}/{serial}/order

    MQTT->>R: Forward Order
    R->>R: Validate & Process Order
    R->>R: Start executing nodes/edges

    loop Every 1-10 Hz
        R->>MQTT: Publish State
        Note over R,MQTT: Topic: uagv/v2/{mfr}/{serial}/state
        MQTT->>FM: Forward State
        FM->>FM: Update Dashboard
    end

    R->>R: Complete mission
    R->>MQTT: Publish Final State
    MQTT->>FM: Forward Final State
    Note over FM: Mission completed
```

### Quy trình Dừng Khẩn cấp / Emergency Stop Flow

```mermaid
sequenceDiagram
    participant FM as FleetManager
    participant MQTT as MQTT Broker
    participant R as RobotApp

    Note over FM: Operator clicks<br/>Emergency Stop

    FM->>MQTT: Publish InstantAction<br/>(stopPause)
    Note over FM,MQTT: Topic: uagv/v2/{mfr}/{serial}/instantActions<br/>QoS: 1 (at least once)

    MQTT->>R: Forward InstantAction

    Note over R: Immediate Response<br/>(< 50ms)
    R->>R: Stop all motors
    R->>R: Set paused=true

    R->>MQTT: Publish State<br/>(paused=true)
    MQTT->>FM: Forward State

    Note over FM: Dashboard shows<br/>Robot PAUSED
```

## Kiến trúc Dữ liệu / Data Architecture

### Luồng Dữ liệu / Data Flow

```mermaid
graph LR
    subgraph Inputs
        Operator[Operator Input]
        Sensors[Robot Sensors]
        External[External Systems]
    end

    subgraph Processing
        FM[FleetManager<br/>Business Logic]
        RA[RobotApp<br/>Control Logic]
    end

    subgraph Storage
        DB[(Database)]
        Maps[Map Data<br/>VDMA LIF]
        Scripts[Scripts<br/>C# Code]
    end

    subgraph Outputs
        Orders[VDA 5050 Orders]
        States[Robot States]
        Reports[Analytics & Reports]
    end

    Operator --> FM
    External --> FM
    FM --> DB
    FM --> Orders

    Orders --> RA
    Sensors --> RA
    Maps --> RA
    Scripts --> RA
    RA --> States

    States --> FM
    DB --> Reports

    style Processing fill:#e6f3ff
    style Storage fill:#fff0e6
```

### Các Loại Message VDA 5050 / VDA 5050 Message Types

```mermaid
graph TB
    subgraph FM_to_Robot["FleetManager → Robot"]
        Order[Order<br/>Mission assignment<br/>Nodes + Edges + Actions]
        Instant[InstantActions<br/>Immediate commands<br/>stop, pause, cancel]
    end

    subgraph Robot_to_FM["Robot → FleetManager"]
        State[State<br/>Current status<br/>Position, battery, errors]
        Viz[Visualization<br/>Display data<br/>Real-time position]
    end

    subgraph Bidirectional["Bidirectional"]
        Conn[Connection<br/>Heartbeat<br/>Online/Offline status]
    end

    style FM_to_Robot fill:#ffe6e6
    style Robot_to_FM fill:#e6ffe6
    style Bidirectional fill:#e6e6ff
```

## Module Chi tiết / Detailed Modules

### 1. ScriptEngine (Shared Library)

**Mục đích**: Cho phép tùy chỉnh hành vi mà không cần rebuild app

**Kiến trúc**:

```mermaid
graph TB
    subgraph Browser["Browser - Blazor WASM"]
        Editor[Monaco Editor<br/>C# Code Editing]
        Roslyn[Roslyn Analysis<br/>IntelliSense & Diagnostics]
    end

    subgraph Server["Server - .NET"]
        Compiler[Script Compiler<br/>Merge & Analyze]
        SM[State Machine<br/>Idle → Building → Ready → Running]
        TaskMgr[Task Manager<br/>Periodic Execution]
        MissionMgr[Mission Manager<br/>Long-running Workflows]
        VarMgr[Variable Manager<br/>Shared State]
    end

    Editor -->|SignalR<br/>Save & Build| Compiler
    Compiler --> SM
    SM --> TaskMgr
    SM --> MissionMgr
    TaskMgr --> VarMgr
    MissionMgr --> VarMgr

    style Browser fill:#e6f3ff
    style Server fill:#fff0e6
```

**Use Cases**:
- **RobotApp**: Custom VDA 5050 actions, sensor processing, navigation logic
- **FleetManager**: 
  - Mission planning algorithms (Mission methods tạo MissionInstance)
  - Task execution (periodic tasks)
  - External system integration (HTTP, Modbus TCP, OPC UA, CcLink, ProfileNet, MQTT)
  - FleetManager APIs: `MoveToNode()`, `GetRobotById()`, etc. để tạo VDA 5050 orders

### 2. MapEditor (Shared Library)

**Mục đích**: Quản lý bản đồ nhà máy theo chuẩn VDMA LIF

**Kiến trúc**:

```mermaid
graph TB
    subgraph UI["Web UI - Blazor WASM"]
        Canvas[SVG Map Editor<br/>Interactive Drawing]
        Props[Properties Panel<br/>Edit Elements]
    end

    subgraph Services["Service Layer"]
        MapSvc[Map Service<br/>CRUD Operations]
        Converter[VDMA LIF Converter<br/>JSON ↔ Database]
        PathFinder[PathFinder<br/>A* Algorithm]
        Validator[Map Validator<br/>Compliance Check]
    end

    subgraph Storage["Database - Normalized Schema"]
        Maps[(Maps)]
        Stations[(Stations)]
        Edges[(Edges)]
        Nodes[(InteractionNodes)]
        Actions[(NodeActions)]
    end

    Canvas --> MapSvc
    Props --> MapSvc
    MapSvc --> Converter
    MapSvc --> PathFinder
    MapSvc --> Validator
    Converter --> Maps
    Maps --> Stations
    Stations --> Nodes
    Nodes --> Actions
    Maps --> Edges

    style UI fill:#e6f3ff
    style Services fill:#fff9e6
    style Storage fill:#ffe6f0
```

**Tính năng**:
- Import/Export VDMA LIF JSON
- Visual editing với SVG canvas
- Lưu trữ map data trong database (SQL Server cho FleetManager, SQLite cho RobotApp)
- PathFinding giữa các stations (A* algorithm)
- FleetManager sử dụng map data từ database để tính toán routes

## Nguyên tắc Thiết kế / Design Principles

### 1. Interoperability / Khả năng Tương tác

**Tại sao quan trọng**: Cho phép làm việc với robot/hệ thống của hãng khác

**Cách thực hiện**:
- ✅ Tuân thủ nghiêm ngặt VDA 5050 v2.1.0 (tương thích ngược với v2.0.0)
- ✅ Tuân thủ VDMA LIF cho map format
- ✅ Sử dụng MQTT standard protocol
- ✅ JSON serialization với camelCase naming

### 2. Modularity / Tính Mô-đun

**Tại sao quan trọng**: Dễ bảo trì, mở rộng, test

**Cách thực hiện**:
- ✅ Clean Architecture layers
- ✅ Dependency Injection
- ✅ Interface-based design
- ✅ Shared libraries (ScriptEngine, MapEditor)

### 3. Reliability / Độ Tin cậy

**Tại sao quan trọng**: Hệ thống sản xuất không được gián đoạn

**Cách thực hiện**:
- ✅ MQTT QoS levels (0, 1 theo message type)
- ✅ Auto-reconnection logic
- ✅ Graceful degradation
- ✅ Comprehensive error handling
- ✅ Safety monitoring (emergency stop < 50ms)

### 4. Scalability / Khả năng Mở rộng

**Tại sao quan trọng**: Hỗ trợ từ vài robot đến 100+ robot

**Cách thực hiện**:
- ✅ Asynchronous processing (async/await)
- ✅ Efficient database queries (indexes)
- ✅ State-less service design
- ✅ MQTT broker clustering (if needed)

### 5. Maintainability / Dễ Bảo trì

**Tại sao quan trọng**: Giảm chi phí vận hành dài hạn

**Cách thực hiện**:
- ✅ Clear code organization
- ✅ Comprehensive documentation
- ✅ Unit & integration tests
- ✅ Structured logging
- ✅ CI/CD pipeline

## Quyết định Công nghệ / Technology Choices

### Tại sao .NET 10?

| Tiêu chí | Lý do |
|----------|-------|
| **Cross-platform** | Chạy trên Linux (robot) và Windows/Linux (server) |
| **Performance** | High-performance runtime, native compilation option |
| **Ecosystem** | Rich libraries: MQTTnet, EF Core, SignalR |
| **Type Safety** | C# strong typing giảm bugs |
| **Tooling** | Visual Studio, VS Code, JetBrains Rider |

### Tại sao Blazor?

| Tiêu chí | Lý do |
|----------|-------|
| **Full-stack C#** | Một ngôn ngữ cho cả backend và frontend |
| **WebAssembly** | Client-side execution (Monaco Editor, Roslyn) |
| **SignalR Integration** | Real-time updates dễ dàng |
| **Component Model** | Reusable UI components |

### Tại sao MQTT?

| Tiêu chí | Lý do |
|----------|-------|
| **Lightweight** | Low overhead cho IoT/robotics |
| **Pub-Sub Pattern** | Perfect cho 1-to-many communication |
| **QoS Levels** | Reliable delivery options |
| **VDA 5050 Requirement** | Standard chỉ định MQTT |
| **Industry Standard** | Widely supported, mature ecosystem |

### Tại sao SQL Server cho FleetManager?

| Tiêu chí | Lý do |
|----------|-------|
| **Enterprise Features** | Advanced features cho fleet management |
| **Performance** | Excellent for complex queries và analytics |
| **JSON Support** | Store VDA 5050 messages, VDMA LIF data |
| **Reliability** | ACID compliance, proven stability |
| **Integration** | Tích hợp tốt với .NET ecosystem |

**Lưu ý**: RobotApp sử dụng SQLite cho local storage.

## Yêu cầu Hiệu năng / Performance Requirements

### Real-time Requirements

| Thao tác | Yêu cầu | Lý do |
|----------|---------|-------|
| **Emergency Stop** | < 50ms | An toàn con người |
| **Order Processing** | < 100ms | Responsive system |
| **State Update** | 1-10 Hz | Real-time monitoring |
| **Navigation Loop** | 10-50 Hz | Smooth motion control |
| **MQTT Latency** | < 50ms | VDA 5050 recommendation |

### Scalability Requirements

| Chỉ số | Mục tiêu | Ghi chú |
|--------|----------|---------|
| **Max Robots** | 100+ | Per FleetManager instance |
| **State Processing** | < 50ms | Per robot state message |
| **Dashboard Update** | < 100ms | Via SignalR real-time |
| **Database Query** | < 200ms | Average response time |
| **Mission Planning** | < 2 seconds | Route optimization |

## Kiến trúc Bảo mật / Security Architecture

```mermaid
graph TB
    subgraph Network["Network Security"]
        TLS[MQTT over TLS/SSL]
        Cert[Certificate-based Auth]
        FW[Firewall & Network Segmentation]
    end

    subgraph App["Application Security"]
        Auth[User Authentication<br/>ASP.NET Identity]
        RBAC[Role-based Access Control<br/>Admin/Operator/Viewer]
        Encrypt[Encrypted Credentials<br/>User Secrets]
        Audit[Audit Logging<br/>Track all changes]
    end

    subgraph Robot["Robot Security"]
        Local[Local Firewall]
        SecureBoot[Secure Boot - Optional]
        Update[Secure Update Mechanism]
    end

    style Network fill:#ffe6e6
    style App fill:#e6ffe6
    style Robot fill:#e6e6ff
```

## Tương lai / Future Considerations

### Potential Enhancements

1. **Multi-fleet Support**: Nhiều FleetManager instances cho nhà máy lớn
2. **AI-based Optimization**: Machine learning cho route optimization
3. **Predictive Maintenance**: Dự đoán lỗi dựa trên telemetry data
4. **Cloud Integration**: Backup data, remote monitoring
5. **Mobile App**: iOS/Android app cho operators
6. **REST API**: Third-party integration via REST

### Scalability Roadmap

```mermaid
graph LR
    Phase1[Phase 1<br/>Single FleetManager<br/>10-20 robots]
    Phase2[Phase 2<br/>Optimized FleetManager<br/>50-100 robots]
    Phase3[Phase 3<br/>Distributed System<br/>100+ robots]

    Phase1 -->|Performance tuning| Phase2
    Phase2 -->|Microservices?<br/>Distributed MQTT| Phase3

    style Phase1 fill:#e6f3ff
    style Phase2 fill:#fff0e6
    style Phase3 fill:#e6ffe6
```

## Related Documents / Tài liệu Liên quan

### Kiến trúc Chi tiết / Detailed Architecture
- [ScriptEngine Architecture](../ScriptEngine/README.md) - Web-based C# scripting system
- [MapEditor Architecture](../MapEditor/README.md) - VDMA LIF map management
- [RobotApp Architecture](../robotapp/README.md) - Robot control application
- [FleetManager Architecture](../fleetmanager/README.md) - Fleet management system

### Tiêu chuẩn / Standards
- [VDA 5050 Implementation](../vda5050/README.md) - VDA 5050 protocol details

### Phát triển / Development
- [AI Collaboration Guide](../ai-guide/README.md) - For AI agents working on this project

---

**Last Updated**: 2026-03-15
**Status**: Architecture Design Document
**Version**: 1.0
