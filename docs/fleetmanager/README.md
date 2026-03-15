# FleetManager Documentation / Tài liệu FleetManager

## Overview / Tổng quan

FleetManager là hệ thống quản lý và điều phối đội xe robot AMR, chạy trên server tại nhà máy. Ứng dụng này giám sát, điều phối nhiều robot AMR, gán nhiệm vụ, tối ưu hóa lộ trình và cung cấp giao diện web cho người vận hành.

## Bối cảnh & Mục tiêu / Context & Goals

### Vấn đề Cần Giải quyết

Trong môi trường sản xuất hiện đại:
- **Quản lý nhiều robot**: Điều phối hàng chục đến hàng trăm robot làm việc đồng thời
- **Tối ưu hóa hiệu quả**: Giảm thời gian chờ, tối ưu lộ trình, cn bằng tải
- **Giải quyết xung đột**: Tránh deadlock, collision giữa các robot
- **Giám sát real-time**: Theo dõi trạng thái và hiệu suất của từng robot
- **Tích hợp hệ thống**: Kết nối với WMS, ERP, MES và các hệ thống khác

### Giải pháp FleetManager

FleetManager cung cấp:
1. **Fleet Coordination** - Điều phối tập trung toàn bộ đội xe
2. **Mission Planning** - Lập kế hoạch và quản lý nhiệm vụ thông minh
3. **Route Optimization** - Tối ưu hóa lộ trình dựa trên nhiều tiêu chí
4. **Conflict Resolution** - Tự động giải quyết xung đột giữa robot
5. **Real-time Monitoring** - Giám sát và phân tích hiệu suất
6. **Web Dashboard** - Giao diện trực quan cho operators

## Kiến trúc Tổng thể / System Architecture

### High-Level Architecture

```mermaid
graph TB
    subgraph "FleetManager Server"
        subgraph "Presentation Layer"
            WebUI[Blazor Web UI<br/>Dashboard, Mission Control<br/>Fleet Map, Analytics]
            SignalR[SignalR Hub<br/>Real-time Updates]
        end
        
        subgraph "Application Layer - Core Modules"
            Identity[Identity Module<br/>Authentication & Authorization<br/>RBAC]
            MapEditor[MapEditor Module<br/>Map Management<br/>VDMA LIF]
            RobotConn[RobotConnections Module<br/>MQTT Management<br/>VDA 5050 Protocol]
            RobotMgr[RobotManager Module<br/>State, Order, Action<br/>VDA 5050 Handler]
            TrafficCtrl[TrafficControl Module<br/>Route Calculation<br/>Conflict Resolution]
            ScriptEngine[ScriptEngine Module<br/>Script Management<br/>Mission & Task Execution]
            Config[FleetManagerConfig Module<br/>Dynamic Configuration<br/>Runtime Updates]
        end
        
        subgraph "Data Layer"
            DB[(SQL Server Database<br/>Robots, Missions<br/>Analytics, Maps<br/>MapEditor Data)]
        end
        
        subgraph "Communication Layer"
            MQTT[MQTT Client<br/>Multi-robot Connection<br/>Topic Management]
        end
    end
    
    subgraph "External Systems"
        MQTTBroker[MQTT Broker<br/>Eclipse Mosquitto]
        Robots[Robot Fleet<br/>RobotApp instances]
        External[External Systems<br/>WMS, ERP, MES]
    end
    
    WebUI --> SignalR
    SignalR --> Identity
    SignalR --> RobotMgr
    SignalR --> ScriptEngine
    
    Identity --> WebUI
    MapEditor --> DB
    RobotConn --> MQTT
    RobotMgr --> RobotConn
    RobotMgr --> TrafficCtrl
    TrafficCtrl --> MapEditor
    TrafficCtrl --> RobotMgr
    ScriptEngine --> RobotMgr
    ScriptEngine --> TrafficCtrl
    Config --> RobotConn
    Config --> RobotMgr
    Config --> TrafficCtrl
    Config --> ScriptEngine
    
    MQTT --> MQTTBroker
    MQTTBroker <--> Robots
    
    RobotMgr --> DB
    MapEditor --> DB
    ScriptEngine --> DB
    Config --> DB
    
    External --> WebUI
    External --> ScriptEngine
    
    style WebUI fill:#e6f3ff
    style Identity fill:#ffe6e6
    style MapEditor fill:#fff0e6
    style RobotConn fill:#e6ffe6
    style RobotMgr fill:#e6f3ff
    style TrafficCtrl fill:#fff0e6
    style ScriptEngine fill:#e6ffe6
    style Config fill:#f0e6ff
    style DB fill:#ffe6f0
    style MQTT fill:#f0e6ff
```

### Component Interaction Flow

```mermaid
sequenceDiagram
    participant Operator
    participant WebUI
    participant MissionSvc as Mission Service
    participant RouteSvc as Route Optimizer
    participant ConflictSvc as Conflict Resolver
    participant VDAHandler as VDA 5050 Handler
    participant MQTT
    participant Robot
    
    Operator->>WebUI: Create Mission
    WebUI->>MissionSvc: Mission Request
    MissionSvc->>RouteSvc: Optimize Route
    RouteSvc->>ConflictSvc: Check Conflicts
    ConflictSvc-->>RouteSvc: Route Approved
    RouteSvc-->>MissionSvc: Optimized Route
    MissionSvc->>VDAHandler: Generate Order
    VDAHandler->>MQTT: Publish Order
    MQTT->>Robot: VDA 5050 Order
    
    Robot->>MQTT: State Update
    MQTT->>VDAHandler: Process State
    VDAHandler->>MissionSvc: Update Progress
    MissionSvc->>WebUI: Real-time Update
    WebUI->>Operator: Show Status
```

## Cấu trúc Tài liệu / Documentation Structure

Tài liệu FleetManager được tổ chức thành các module riêng biệt để dễ dàng tra cứu và bảo trì:

```
docs/fleetmanager/
├── README.md                    # File này - Tổng quan FleetManager
├── Identity.md                  # Module Xác thực và Phân quyền
├── MapEditor.md                 # Module Quản lý Bản đồ
├── RobotConnections.md          # Module Kết nối Robot
├── RobotManager.md              # Module Quản lý Robot
├── TrafficControl.md            # Module Điều khiển Giao thông
├── ScriptEngine.md              # Module Script Engine
└── FleetManagerConfig.md        # Module Cấu hình
```

## Core Modules / Các Module Chính

FleetManager được tổ chức thành 7 module chính, mỗi module có trách nhiệm cụ thể:

### 1. [Identity Module](Identity.md) - Module Xác thực và Phân quyền

Quản lý authentication và authorization cho FleetManager với 7 roles (SystemAdmin, Developer, FleetOperator, MapEditor, Viewer, ScriptEditor, Analyst).

**[Xem chi tiết →](Identity.md)**

### 2. [MapEditor Module](MapEditor.md) - Module Quản lý Bản đồ

Quản lý bản đồ nhà máy theo tiêu chuẩn VDMA LIF. Shared library cho FleetManager và RobotApp với visual editing và pathfinding.

**[Xem chi tiết →](MapEditor.md)**

### 3. [RobotConnections Module](RobotConnections.md) - Module Kết nối Robot

Quản lý kết nối MQTT của các robot theo VDA 5050. MQTT Broker chạy trên service ngoài FleetManager.

**[Xem chi tiết →](RobotConnections.md)**

### 4. [RobotManager Module](RobotManager.md) - Module Quản lý Robot

Quản lý state, order, và action của robots. Cung cấp APIs cho ScriptEngine và xử lý VDA 5050 protocol.

**[Xem chi tiết →](RobotManager.md)**

### 5. [TrafficControl Module](TrafficControl.md) - Module Điều khiển Giao thông

Tính toán route cho order, phát hiện conflict và giải quyết xung đột. Quản lý base và horizon của VDA 5050 orders.

**[Xem chi tiết →](TrafficControl.md)**

### 6. [ScriptEngine Module](ScriptEngine.md) - Module Script Engine

Quản lý script do người dùng thiết kế, chạy Task và Mission. Shared library với IntelliSense support và FleetManager APIs.

**[Xem chi tiết →](ScriptEngine.md)**

### 7. [FleetManagerConfig Module](FleetManagerConfig.md) - Module Cấu hình

Quản lý cấu hình động cho hệ thống, cho phép thay đổi runtime mà không cần restart. Lưu trữ trong database.

**[Xem chi tiết →](FleetManagerConfig.md)**

## 📡 VDA 5050 Protocol Handler

**Mục đích**: Xử lý giao tiếp VDA 5050 với các robot (không phải module riêng, mà là phần của RobotManager và RobotConnections).

**Chức năng**:
- **Order Generation**: Tạo VDA 5050 orders từ TrafficControl
- **Order Updates**: Tạo OrderUpdate (cùng orderId, orderUpdateId tăng) khi TrafficControl yêu cầu
- **State Processing**: Xử lý state messages từ robots (chỉ quản lý state hiện tại, không lưu history)
- **Action Generation**: Tạo instant actions (stopPause, cancelOrder, etc.)
- **Message Validation**: Validate VDA 5050 messages

**Lưu ý**: VDA 5050 Protocol Handler không phải là module riêng, mà là chức năng được tích hợp trong RobotManager và RobotConnections modules.

### 6. Analytics & Reporting

**Mục đích**: Thu thập, phân tích và báo cáo dữ liệu vận hành.

**Metrics theo dõi**:

```mermaid
graph TB
    subgraph "Fleet Metrics"
        CompletionRate[Mission Completion Rate<br/>% missions completed]
        AvgDuration[Average Mission Duration<br/>Time per mission]
        Utilization[Robot Utilization Rate<br/>% time active]
        Distance[Total Distance Traveled<br/>km per day/week]
    end
    
    subgraph "Robot Metrics"
        Battery[Battery Consumption<br/>Charging patterns]
        Errors[Error Frequency<br/>Error types and rates]
        IdleTime[Idle Time<br/>Waiting time]
        Performance[Performance Comparison<br/>Robot vs Robot]
    end
    
    subgraph "Reports"
        Daily[Daily Summary<br/>24-hour overview]
        Weekly[Weekly Report<br/>Trends and patterns]
        Monthly[Monthly Analysis<br/>Long-term trends]
        Predictive[Predictive Alerts<br/>Maintenance warnings]
    end
    
    CompletionRate --> Daily
    AvgDuration --> Daily
    Utilization --> Weekly
    Distance --> Weekly
    Battery --> Monthly
    Errors --> Predictive
    IdleTime --> Monthly
    Performance --> Weekly
    
    style CompletionRate fill:#e6f3ff
    style Daily fill:#e6ffe6
```

### 7. Web Dashboard (Blazor)

**Mục đích**: Giao diện web cho operators.

**Technology Stack**:
- **Blazor Web App**: .NET 10
- **Authentication**: Individual Account (ASP.NET Identity)
- **Real-time**: SignalR for live updates
- **Script Editor**: Monaco Editor với ScriptEngine integration

**Các trang chính**:

```mermaid
graph TB
    subgraph "Dashboard Pages"
        Dashboard[Dashboard<br/>Fleet overview<br/>Key metrics<br/>Active missions]
        FleetMap[Fleet Map<br/>Real-time positions<br/>Route visualization<br/>Zone management]
        MissionCtrl[Mission Control<br/>Create missions<br/>Edit missions<br/>Queue management]
        RobotMgr[Robot Management<br/>Robot list<br/>Individual details<br/>Manual control]
        Analytics[Analytics<br/>Performance metrics<br/>Charts and graphs<br/>Reports]
        Config[Configuration<br/>Map management<br/>System settings<br/>User management]
        ScriptEditor[Script Editor<br/>C# Code Editing<br/>Monaco Editor<br/>ScriptEngine Integration]
    end
    
    Dashboard --> SignalR[SignalR Real-time]
    FleetMap --> SignalR
    MissionCtrl --> SignalR
    RobotMgr --> SignalR
    Analytics --> DB[(Database)]
    Config --> DB
    ScriptEditor --> ScriptEngine[ScriptEngine<br/>SignalR Locking]
    
    style Dashboard fill:#e6f3ff
    style SignalR fill:#fff0e6
    style ScriptEditor fill:#e6ffe6
```

**Script Editor Features**:
- Monaco Editor với C# IntelliSense
- SignalR-based file locking: Khi user đang edit, các session khác không được sửa file
- Save action: Không có realtime update file content, chỉ khi user gọi action Save mới gửi lên server
- ScriptEngine quản lý trạng thái cho phép chỉnh sửa hay không

## 📡 Communication Architecture / Kiến trúc Giao tiếp

### MQTT Topic Structure

```mermaid
graph TB
    subgraph "Published Topics<br/>FleetManager → Robots"
        OrderTopic[uagv/v2/{manufacturer}/{serialNumber}/order<br/>QoS: 1, Retain: false]
        InstantTopic[uagv/v2/{manufacturer}/{serialNumber}/instantActions<br/>QoS: 1, Retain: false]
    end
    
    subgraph "Subscribed Topics<br/>Robots → FleetManager"
        StateTopic[uagv/v2/{manufacturer}/+/state<br/>QoS: 0, Retain: true]
        VizTopic[uagv/v2/{manufacturer}/+/visualization<br/>QoS: 0, Retain: false]
        ConnTopic[uagv/v2/{manufacturer}/+/connection<br/>QoS: 1, Retain: true]
    end
    
    FleetMgr[FleetManager] --> OrderTopic
    FleetMgr --> InstantTopic
    StateTopic --> FleetMgr
    VizTopic --> FleetMgr
    ConnTopic --> FleetMgr
    
    style FleetMgr fill:#e6f3ff
    style OrderTopic fill:#fff0e6
    style StateTopic fill:#e6ffe6
```

### Message Flow Patterns

**Order Assignment Flow**:

```mermaid
sequenceDiagram
    participant Operator
    participant FleetMgr as FleetManager
    participant MQTT as MQTT Broker
    participant Robot
    
    Operator->>FleetMgr: Create Mission
    FleetMgr->>FleetMgr: Plan Route
    FleetMgr->>FleetMgr: Check Conflicts
    FleetMgr->>FleetMgr: Generate VDA 5050 Order
    FleetMgr->>MQTT: Publish Order (QoS 1)
    MQTT->>Robot: Forward Order
    
    Robot->>MQTT: Publish State (QoS 0)
    MQTT->>FleetMgr: Forward State
    FleetMgr->>Operator: Update Dashboard
    
    Note over Robot: Execute Order
    Robot->>MQTT: State Updates (1-10 Hz)
    MQTT->>FleetMgr: Forward States
    FleetMgr->>Operator: Real-time Updates
```

**Emergency Stop Flow**:

```mermaid
sequenceDiagram
    participant Operator
    participant FleetMgr as FleetManager
    participant MQTT as MQTT Broker
    participant Robot
    
    Operator->>FleetMgr: Emergency Stop
    FleetMgr->>FleetMgr: Generate InstantAction<br/>(stopPause)
    FleetMgr->>MQTT: Publish InstantAction (QoS 1)
    Note over FleetMgr,MQTT: < 50ms latency required
    MQTT->>Robot: Forward InstantAction
    
    Robot->>Robot: Stop Motors Immediately
    Robot->>Robot: Set paused=true
    Robot->>MQTT: Publish State (paused=true)
    MQTT->>FleetMgr: Forward State
    FleetMgr->>Operator: Show PAUSED Status
```

## Data Architecture / Kiến trúc Dữ liệu

### Core Entities

```mermaid
erDiagram
    Robots ||--o{ MissionInstances : assigned
    Robots ||--o{ Orders : has
    MissionInstances ||--o{ Orders : generates
    Maps ||--o{ Stations : contains
    Maps ||--o{ Edges : contains
    Maps ||--o{ Nodes : contains
    
    Robots {
        uuid id PK
        string serialNumber UK
        string manufacturer
        int status
        float currentX
        float currentY
        float batteryLevel
        datetime lastSeen
        string currentOrderId
        int currentOrderUpdateId
    }
    
    MissionInstances {
        uuid id PK
        string missionName
        string parameters
        int status
        uuid assignedRobotId FK
        datetime startedAt
        datetime completedAt
    }
    
    Orders {
        uuid id PK
        uuid robotId FK
        string orderId UK
        int orderUpdateId
        string orderData
        datetime createdAt
        datetime completedAt
    }
    
    Maps {
        uuid id PK
        string mapId UK
        string name
        float resolution
    }
    
    Stations {
        uuid id PK
        uuid mapId FK
        string stationId UK
        string stationType
        float positionX
        float positionY
    }
    
    Edges {
        uuid id PK
        uuid mapId FK
        string edgeId UK
        string startNodeId
        string endNodeId
    }
    
    Nodes {
        uuid id PK
        uuid mapId FK
        string nodeId UK
        float positionX
        float positionY
    }
```

**Lưu ý về State Management**:
- FleetManager chỉ quản lý state hiện tại của robot, không lưu state history
- State được cập nhật real-time từ VDA 5050 state messages
- Khi robot mất kết nối, FleetManager dựa vào thời gian state cuối cùng để quyết định timeout cho order

### Data Flow

```mermaid
graph LR
    subgraph "Input Sources"
        Operator[Operator Input]
        Robots[Robot States]
        External[External Systems]
    end
    
    subgraph "Processing"
        FleetSvc[Fleet Service]
        MissionSvc[Mission Service]
        AnalyticsSvc[Analytics Service]
    end
    
    subgraph "Storage"
        DB[(SQL Server<br/>Robots, Missions<br/>Maps, Analytics)]
    end
    
    subgraph "Output"
        Dashboard[Web Dashboard]
        Reports[Analytics Reports]
        Orders[VDA 5050 Orders]
    end
    
    Operator --> FleetSvc
    Operator --> MissionSvc
    Robots --> FleetSvc
    External --> MissionSvc
    
    FleetSvc --> DB
    MissionSvc --> DB
    AnalyticsSvc --> DB
    
    DB --> Dashboard
    DB --> Reports
    FleetSvc --> Orders
    
    style DB fill:#ffe6f0
    style Dashboard fill:#e6f3ff
```

## Design Principles / Nguyên tắc Thiết kế

### 1. Scalability / Khả năng Mở rộng

**Mục tiêu**: Hỗ trợ 100+ robot đồng thời

**Thiết kế**:
- Stateless service design (không lưu state trong memory)
- Asynchronous processing (async/await)
- Efficient database queries (indexes, pagination)
- MQTT broker clustering support (nếu cần)

### 2. Reliability / Độ Tin cậy

**Mục tiêu**: Hệ thống không được gián đoạn

**Thiết kế**:
- MQTT QoS levels phù hợp (QoS 1 cho orders)
- Auto-reconnection logic
- Graceful degradation (degraded mode khi có lỗi)
- Comprehensive error handling
- Safety monitoring (emergency stop < 50ms)

### 3. Real-time Performance / Hiệu năng Real-time

**Yêu cầu**:
- State processing: < 50ms per robot state
- Order generation: < 100ms
- Conflict detection: < 500ms
- Dashboard update: < 100ms (via SignalR)

**Thiết kế**:
- SignalR for real-time updates
- Efficient state processing pipeline
- Background workers for heavy tasks
- Caching frequently accessed data

### 4. Interoperability / Khả năng Tương tác

**Mục tiêu**: Tương thích với hệ thống bên thứ 3

**Thiết kế**:
- Tuân thủ nghiêm ngặt VDA 5050 v2.1.0 (tương thích ngược với v2.0.0)
- Standard MQTT protocol
- REST API for external integration (planned)
- JSON message format (camelCase)

## Security Architecture / Kiến trúc Bảo mật

```mermaid
graph TB
    subgraph "Network Security"
        TLS[MQTT over TLS/SSL]
        Cert[Certificate-based Authentication]
        Firewall[Network Segmentation]
    end
    
    subgraph "Application Security"
        Auth[User Authentication<br/>ASP.NET Identity]
        RBAC[Role-based Access Control<br/>Admin/Operator/Viewer]
        Encrypt[Encrypted Credentials]
        Audit[Audit Logging]
    end
    
    subgraph "Data Security"
        DBEncrypt[Database Encryption]
        Backup[Backup & Recovery]
        Access[Access Control]
    end
    
    TLS --> Auth
    Cert --> Auth
    Auth --> RBAC
    RBAC --> Access
    Access --> DBEncrypt
    DBEncrypt --> Backup
    
    style TLS fill:#ffe6e6
    style Auth fill:#e6ffe6
    style DBEncrypt fill:#e6f3ff
```

## Performance Requirements / Yêu cầu Hiệu năng

| Chỉ số | Mục tiêu | Ghi chú |
|--------|----------|---------|
| **Max Robots** | 100+ | Per FleetManager instance |
| **State Processing** | < 50ms | Per robot state message |
| **Order Generation** | < 100ms | From mission to VDA 5050 order |
| **Conflict Detection** | < 500ms | Multi-robot conflict check |
| **Route Optimization** | < 2 seconds | A* pathfinding |
| **Dashboard Update** | < 100ms | Via SignalR real-time |
| **Database Query** | < 200ms | Average response time |

## ScriptEngine Integration / Tích hợp ScriptEngine

**Mục đích**: Cho phép tùy chỉnh logic mission planning và tích hợp hệ thống bên ngoài.

**FleetManager Script APIs**:

ScriptEngine trong FleetManager expose các APIs thông qua `FleetScriptGlobals`:

```csharp
// Robot Management
Robot GetRobotById(string robotId);
Robot GetRobotBySerial(string serialNumber);
List<Robot> GetAvailableRobots();

// Order Creation (tự động tìm route và tạo order)
Task MoveToNode(string robotSerial, string nodeId);
Task MoveToStation(string robotSerial, string stationId);

// Robot State
RobotState GetRobotState(string robotSerial);

// External System Integration
// Có thể khai báo kết nối với:
// - HTTP APIs
// - Modbus TCP
// - OPC UA
// - CcLink
// - ProfileNet
// - MQTT (external)
```

**Mission và Task trong FleetManager**:

- **Mission**: Methods có `[Mission]` attribute trong script, được ScriptEngine extract và tạo thành MissionInstance
- **Task**: Methods có `[Task]` attribute, chạy lặp lại theo interval
- Mission và Task có thể tương tác qua common APIs:
  - `EnableTask(string taskName)` / `DisableTask(string taskName)`
  - `CreateMission(string missionName, params)` / `CancelMission(Guid missionId)`

**Luồng Mission Execution**:

```mermaid
sequenceDiagram
    participant Script as C# Script
    participant ScriptEngine
    participant MissionInstance
    participant FleetAPI as FleetManager APIs
    participant RouteSvc as Route Service
    participant VDAHandler as VDA Handler
    participant Robot
    
    Script->>ScriptEngine: [Mission] method defined
    ScriptEngine->>ScriptEngine: Extract & compile
    ScriptEngine->>MissionInstance: Create MissionInstance
    MissionInstance->>FleetAPI: MoveToNode("ROBOT001", "NodeA")
    FleetAPI->>RouteSvc: Find route to NodeA
    RouteSvc->>VDAHandler: Generate VDA 5050 Order
    VDAHandler->>Robot: Send Order
    Robot->>FleetAPI: State updates
    FleetAPI->>MissionInstance: Continue execution
```

## Deployment Architecture / Kiến trúc Triển khai

**Deployment Model**:
- **Single Instance**: FleetManager chạy một instance duy nhất, có thể điều phối nhiều robot (100+)
- **Không hỗ trợ multiple instances**: FleetManager không chạy multiple instances để share workload

**Infrastructure**:

```mermaid
graph TB
    subgraph "FleetManager Server"
        App[FleetManager App<br/>Blazor Web App<br/>.NET 10]
    end
    
    subgraph "Infrastructure"
        Server[Server<br/>Linux/Windows]
        MQTTBroker[MQTT Broker<br/>Eclipse Mosquitto]
        Database[SQL Server<br/>Database]
        ReverseProxy[Reverse Proxy<br/>Nginx/IIS]
    end
    
    App --> MQTTBroker
    App --> Database
    ReverseProxy --> App
    
    style App fill:#e6f3ff
    style Database fill:#fff0e6
```

## Related Documents / Tài liệu Liên quan

- [Architecture Overview](../architecture/README.md) - System architecture overview
- [RobotApp Documentation](../robotapp/README.md) - Robot-side application
- [VDA 5050 Implementation](../vda5050/README.md) - Protocol details
- [MapEditor Documentation](../MapEditor/README.md) - Map management
- [ScriptEngine Documentation](../ScriptEngine/README.md) - Custom scripting
- [Development Guide](../development/README.md) - Implementation details

---

**Status**: Architecture & Design Document
**Focus**: System Architecture, Design Concepts, Component Interactions
**Last Updated**: 2025-11-13
**Version**: 2.2 (Updated with 7 core modules structure)
