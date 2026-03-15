# VDA5050 Robot Management Architecture

## Tổng quan / Overview

Tài liệu này mô tả kiến trúc hệ thống quản lý nhiều robot theo tiêu chuẩn VDA5050 trong FleetManager. Hệ thống được thiết kế để quản lý tối đa 203 robots với single FleetManager instance.

## Mục tiêu / Goals

- Quản lý kết nối MQTT với nhiều robots theo VDA5050
- Quản lý state, order, action của từng robot (in-memory, latest only)
- Cung cấp high-level APIs để điều khiển robot
- Real-time updates qua SignalR
- Auto-discovery robots qua connection/state messages

## Kiến trúc Tổng thể / System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    FleetManager Instance                    │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         RobotConnections Service                     │   │
│  │  - MQTT Client (single instance)                     │   │
│  │  - Subscribe topics (wildcard)                       │   │
│  │  - Publish orders/instantActions                     │   │
│  │  - Message routing by SerialNumber                   │   │
│  └──────────────────┬───────────────────────────────────┘   │
│                     │                                        │
│                     │ Event Bus                              │
│                     │                                        │
│  ┌──────────────────▼───────────────────────────────────┐   │
│  │         RobotManager Service                         │   │
│  │  - Quản lý RobotController instances                 │   │
│  │  - Subscribe events từ RobotConnections              │   │
│  │  - Update RobotData vào RobotController              │   │
│  │  - Timeout monitoring (30s)                          │   │
│  │  - Auto-create RobotController khi discover robot    │   │
│  └──────────────────┬───────────────────────────────────┘   │
│                     │                                        │
│  ┌──────────────────▼───────────────────────────────────┐   │
│  │         RobotController (Instance per Robot)         │   │
│  │  - Chứa RobotData của robot                          │   │
│  │  - Methods: MoveToNode(), SendInstantAction(), etc.  │   │
│  │  - Thread-safe với lock                             │   │
│  └──────────────────┬───────────────────────────────────┘   │
│                     │                                        │
│  ┌──────────────────▼───────────────────────────────────┐   │
│  │         SignalR Hub (RobotStateHub)                  │   │
│  │  - Broadcast state changes                           │   │
│  │  - Per-robot subscriptions                           │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           │ MQTT
                           │
        ┌──────────────────┴──────────────────┐
        │                                     │
┌───────▼────────┐                  ┌─────────▼────────┐
│  MQTT Broker   │                  │   Robot Fleet   │
│                │                  │  (203 robots)   │
└────────────────┘                  └─────────────────┘
```

## Module Structure

### 1. RobotConnections Service

**Trách nhiệm:**
- Quản lý MQTT client connection (single instance)
- Subscribe topics với wildcard pattern
- Deserialize và route messages dựa trên SerialNumber
- Publish orders và instantActions đến robots
- Validate SerialNumber tồn tại trong database trước khi xử lý

**MQTT Topics:**

**Subscribe (wildcard):**
- `uagv/v2/{Manufacturer}/+/state` (QoS 0, Retain: true)
- `uagv/v2/{Manufacturer}/+/connection` (QoS 1, Retain: true)
- `uagv/v2/{Manufacturer}/+/visualization` (QoS 0, Retain: false)
- `uagv/v2/{Manufacturer}/+/factsheet` (QoS 0, Retain: true)

**Publish:**
- `uagv/v2/{Manufacturer}/{SerialNumber}/order` (QoS 1, Retain: false)
- `uagv/v2/{Manufacturer}/{SerialNumber}/instantActions` (QoS 1, Retain: false)

**Configuration (appsettings.json):**
```json
{
  "VDA5050": {
    "MqttBroker": {
      "Host": "localhost",
      "Port": 1883,
      "Username": "",
      "Password": "",
      "EnablePassword": false,
      "EnableTls": false,
      "CaCertificatesPath": "",
      "ClientCertificatePath": "",
      "ClientKeyPath": ""
    },
    "Protocol": {
      "Manufacturer": "RobotNet",
      "Version": "2.1.0",
      "TopicPrefix": "uagv/v2"
    }
  }
}
```

**Interfaces:**
```csharp
public interface IRobotConnectionsService
{
    Task StartAsync(CancellationToken cancellationToken = default);
    Task StopAsync(CancellationToken cancellationToken = default);
    bool IsConnected();
    Task<bool> PublishOrderAsync(string robotId, OrderMsg order, CancellationToken cancellationToken = default);
    Task<bool> PublishInstantActionsAsync(string robotId, InstantActionsMsg instantActions, CancellationToken cancellationToken = default);
}
```

### 2. RobotManager Service

**Trách nhiệm:**
- Quản lý `RobotController` instances (mỗi robot có 1 instance)
- Subscribe events từ RobotConnectionsService qua Event Bus
- Route events đến đúng RobotController instance và update RobotData
- Auto-create RobotController khi nhận Connection/State message đầu tiên (sau khi validate có trong DB)
- Timeout monitoring: Check mỗi 15s, nếu 30s không có State hoặc Visualization → set ConnectionState = OFFLINE
- Remove RobotController khi robotId bị xóa khỏi DB

**Data Structures (In-Memory):**
```csharp
// RobotController instances per robot
ConcurrentDictionary<string, IRobotController> // Key: RobotId (SerialNumber)
```

**Timeout Monitoring:**
- Sử dụng `WatchTimerAsync` từ RobotNet10.Common
- Check interval: 15 giy
- Timeout threshold: 30 giy không có State hoặc Visualization message
- Reset timeout riêng biệt cho State và Visualization
- Khi timeout: Set `ConnectionState = OFFLINE` trong RobotController.RobotData
- Không cần retry/reconnect/event notification

**RobotController Lifecycle:**
- **Creation**: Tạo khi nhận Connection/State message đầu tiên và SerialNumber tồn tại trong DB
- **Deletion**: Xóa khi robotId bị xóa khỏi DB (service xóa robot sẽ inject RobotManagerService và gọi `RemoveRobotController(robotId)`)
- **Dispose**: RobotController implement IDisposable để cleanup resources

**Interfaces:**
```csharp
public interface IRobotManagerService
{
    // RobotController Management
    IRobotController? GetRobotController(string robotId);
    IReadOnlyDictionary<string, IRobotController> GetAllRobotControllers();
    void RemoveRobotController(string robotId);
    
    // Backward compatibility (delegate to RobotController)
    RobotData? GetRobotData(string robotId);
    IReadOnlyDictionary<string, RobotData> GetAllRobotData();
    IReadOnlyList<string> GetAvailableRobots(); // Robots với IsOnline == true
}
```

### 3. RobotController (Instance per Robot)

**Trách nhiệm:**
- Mô hình hóa thông tin của 1 robot, định danh bằng RobotId (SerialNumber)
- Không phải service, mà là instance với mỗi robot
- Chứa thông tin robot gửi lên (RobotData)
- Chứa các functions để xử lý và publish xuống robot
- Thread-safe với lock cho các methods gửi order/instantAction

**Properties:**
```csharp
public interface IRobotController : IDisposable
{
    string RobotId { get; }              // SerialNumber
    RobotData RobotData { get; }         // Tất cả thông tin robot
    bool IsOnline { get; }               // Derived từ ConnectionState
}
```

**Methods (Thread-safe với lock):**
```csharp
public interface IRobotController
{
    // Robot Control
    Task<bool> MoveToNodeAsync(string nodeName, CancellationToken cancellationToken = default);
    Task<bool> SendInstantActionAsync(Action action, CancellationToken cancellationToken = default);
    Task<bool> SendOrderAsync(OrderMsg order, CancellationToken cancellationToken = default);
    Task<bool> SendInstantActionsAsync(InstantActionsMsg instantActions, CancellationToken cancellationToken = default);
    Task<bool> RequestFactsheetAsync(CancellationToken cancellationToken = default);
    Task<bool> RequestStateAsync(CancellationToken cancellationToken = default);
    Task<bool> CancelOrderAsync(CancellationToken cancellationToken = default);
}
```

**Dependencies (Injected):**
- `IRobotConnectionsService` - Để publish messages
- `IConfigManager` - Để lấy VDA5050 config (Manufacturer, Version)
- `Logger<RobotController>` - Để logging
- `IRobotManagerService` - (Optional) Để tự xóa khi cần

**MoveToNode Implementation:**
- Implement cơ bản: Tạo OrderMsg đơn giản với 1 node (target node)
- Có thể inject `ITrafficControlService` sau để tính route phức tạp hơn
- Sẽ được implement trong cuộc hội thoại khác

**Thread-Safety:**
- Lock các methods có thể gửi order hoặc instantAction xuống robot
- Không cần lock RobotData (read-only access từ bên ngoài)
- RobotManagerService update RobotData trực tiếp (thread-safe dictionary)

### 4. Event Bus System

**Trách nhiệm:**
- In-memory event system để communication giữa modules
- Decouple RobotConnections và RobotManager
- Sử dụng C# event pattern

**Events:**
```csharp
public interface IRobotEventBus
{
    event EventHandler<StateMessageReceivedEvent>? StateMessageReceived;
    event EventHandler<ConnectionStateChangedEvent>? ConnectionStateChanged;
    event EventHandler<VisualizationMessageReceivedEvent>? VisualizationMessageReceived;
    event EventHandler<FactsheetMessageReceivedEvent>? FactsheetMessageReceived;
    
    void PublishStateMessageReceived(string robotId, StateMsg stateMsg);
    void PublishConnectionStateChanged(string robotId, ConnectionState connectionState);
    void PublishVisualizationMessageReceived(string robotId, Visualizationmsg visualizationMsg);
    void PublishFactsheetMessageReceived(string robotId, FactSheetMsg factsheetMsg);
}
```

**Event Classes:**
- `StateMessageReceivedEvent` - Khi nhận state message từ robot
- `ConnectionStateChangedEvent` - Khi connection state thay đổi
- `VisualizationMessageReceivedEvent` - Khi nhận visualization message
- `FactsheetMessageReceivedEvent` - Khi nhận factsheet message

### 5. SignalR Hub

**Trách nhiệm:**
- Broadcast real-time updates đến WebUI clients
- Support per-robot subscriptions
- Broadcast tất cả state changes

**Hub Methods:**
- `SubscribeToRobot(string robotId)` - Subscribe updates cho 1 robot
- `UnsubscribeFromRobot(string robotId)` - Unsubscribe

**Broadcast:**
- Broadcast tất cả state changes đến tất cả clients
- Group: `robot:{robotId}` cho subscription per robot

## Data Flow

### State Message Flow
```
Robot → MQTT Broker → RobotConnectionsService
    → Deserialize & Validate SerialNumber exists in DB
    → Publish StateMessageReceivedEvent via Event Bus
    → RobotManagerService receives event
    → Tìm RobotController instance theo RobotId
    → Update RobotData.State vào RobotController
    → Determine OrderStatus từ State message
    → Broadcast via SignalR Hub
    → WebUI Clients receive update
```

### Order Flow
```
ScriptEngine/WebUI → RobotManagerService.GetRobotController(robotId)
    → robotController.MoveToNode("NodeA")
    → RobotController tính toán route (cơ bản)
    → Tạo OrderMsg
    → RobotConnectionsService.PublishOrderAsync()
    → MQTT Broker → Robot
    → Robot processes order
    → Robot sends State message with orderId/orderUpdateId
    → RobotManagerService updates RobotData vào RobotController
    → Determine OrderStatus (Accepted, Completed, etc.)
```

### Connection State Flow
```
Robot → MQTT Broker (connection message)
    → RobotConnectionsService
    → Publish ConnectionStateChangedEvent
    → RobotManagerService receives event
    → Tìm hoặc tạo RobotController instance
    → Update RobotData.ConnectionState vào RobotController
    → SignalR broadcasts update
```

### RobotController Creation Flow
```
Robot → MQTT Broker (connection/state message)
    → RobotConnectionsService
    → Validate SerialNumber exists in DB
    → Publish event via Event Bus
    → RobotManagerService receives event
    → Check if RobotController exists
    → If not exists: Create new RobotController instance
    → Inject dependencies (IRobotConnectionsService, IConfigManager, Logger)
    → Add to ConcurrentDictionary<string, IRobotController>
    → Update RobotData vào RobotController
```

## Data Models

### RobotData
```csharp
public class RobotData
{
    public string RobotId { get; set; }              // SerialNumber
    public StateMsg? State { get; set; }              // Latest State message
    public ConnectionState ConnectionState { get; set; }
    public OrderMsg? Order { get; set; }              // Latest Order message
    public OrderStatus OrderStatus { get; set; }      // Order status tracking
    public FactSheetMsg? Factsheet { get; set; }      // Latest Factsheet
    public VisualizationMsg? Visualization { get; set; } // Latest Visualization
    public DateTime LastUpdated { get; set; }         // Last update timestamp
}
```

### OrderStatus
```csharp
public enum OrderStatus
{
    Pending,      // Order đã tạo nhưng chưa gửi
    Sent,         // Order đã gửi qua MQTT
    Accepted,     // Robot đã accept order (orderId và orderUpdateId khớp)
    Rejected,     // Robot reject order (error với errorReferences)
    Completed,    // Order hoàn thành (nodeStates và edgeStates empty)
    Failed        // Order failed (FATAL error liên quan đến order)
}
```

**Order Status Determination Logic:**
- **Accepted**: `orderId` và `orderUpdateId` trong state khớp với order đã gửi
- **Rejected (Error)**: Có error với `errorReferences` chứa `orderId` hoặc `orderUpdateId` → Log và hủy order (không retry)
- **Completed**: `nodeStates` và `edgeStates` empty, `orderId` khác rỗng
- **Failed**: Có error FATAL liên quan đến order

## Robot Discovery

**Auto-Discovery:**
- Khi nhận connection/state message với SerialNumber
- Kiểm tra SerialNumber có trong database không (qua IRobotService)
- Nếu không có → Bỏ qua message (không tự động tạo robot)
- Nếu có → Xử lý message và update state

**Mapping:**
- `SerialNumber` (từ VDA5050) = `RobotId` (trong database)

## Configuration

### MQTT Configuration
- Lưu trong `appsettings.json` section `VDA5050`
- Bao gồm: Host, Port, Username, Password, TLS settings, Manufacturer, Version, TopicPrefix

### Service Registration
- `IRobotConnectionsService` → Singleton
- `IRobotManagerService` → Singleton
- `IRobotEventBus` → Singleton
- `RobotController` instances → Managed by RobotManagerService (không register trong DI)

## Retry Logic

**Order Rejection Handling:**
- **Reject do Error**: Log và hủy order (không retry)
- **Reject do Connection/Timeout**: Retry với exponential backoff
- Retry cho đến khi có hành động hủy bỏ

## 📡 Factsheet Handling

- Subscribe factsheet topic với wildcard
- Lưu factsheet per robot khi nhận được
- Có thể request factsheet bằng instant action `factsheetRequest`
- Factsheet được retain trên MQTT broker

## Performance Considerations

**Với 203 robots:**
- State messages: ~1,015 messages/second (5 Hz per robot)
- Visualization: ~406 messages/second (2 Hz per robot)
- Total inbound: ~1,500 messages/second
- Estimated CPU: ~2.25 cores for message processing
- Memory: ~1-2 GB (in-memory state + overhead)

**Optimization:**
- In-memory storage (no database writes for state)
- Single MQTT client (no connection pool needed)
- Event-driven architecture (async processing)

## Security Considerations

- MQTT TLS support (optional)
- Certificate-based authentication (optional)
- SerialNumber validation (must exist in database)
- No auto-creation of robots from messages

## Notes

- **Single Instance**: FleetManager chạy single instance (không cần HA)
- **In-Memory Queue**: Sử dụng Channel<T> cho async processing nếu cần
- **No History**: Chỉ lưu state/order/action mới nhất (không lưu history)
- **RobotController**: Instance per robot, không phải service
- **MoveToNode**: Implement cơ bản (tạo order đơn giản), có thể enhance với TrafficControl sau
- **Timeout Monitoring**: 30s không có State hoặc Visualization → OFFLINE

## Dependencies

- `RobotNet.VDA5050` - VDA5050 message models (qua RobotNet10.Common)
- `RobotNet10.Common` - Common utilities (WatchTimerAsync, MQTTClient, etc.)
- `Microsoft.AspNetCore.SignalR` - SignalR for real-time updates
- `IRobotService` - Existing service for robot database operations

## Implementation Phases

Công việc được chia thành các phase nhỏ để thực hiện lần lượt:

### Phase 1: Foundation - Configuration & Event Bus
**Mục tiêu:** Thiết lập nền tảng cơ bản

**Tasks:**
- [ ] Tạo MQTT configuration models (`MqttConfig`, `VDA5050ProtocolConfig`, `VDA5050Config`)
- [ ] Thêm VDA5050 section vào `appsettings.json`
- [ ] Tạo Event Bus interface và implementation (`IRobotEventBus`, `RobotEventBus`)
- [ ] Tạo Event classes (`StateMessageReceivedEvent`, `ConnectionStateChangedEvent`, `VisualizationMessageReceivedEvent`, `FactsheetMessageReceivedEvent`)
- [ ] Register Event Bus trong DI container (Singleton)

**Deliverables:**
- Configuration models
- Event Bus system hoàn chỉnh
- Service registration trong Program.cs

---

### Phase 2: RobotConnections Service - Core MQTT
**Mục tiêu:** Implement MQTT client connection và subscription

**Tasks:**
- [ ] Tạo `IRobotConnectionsService` interface
- [ ] Implement `RobotConnectionsService` với MQTT client
- [ ] Load configuration từ appsettings.json
- [ ] Implement `StartAsync()` - Connect to MQTT broker
- [ ] Implement `StopAsync()` - Disconnect from broker
- [ ] Implement `IsConnected()` - Check connection status
- [ ] Subscribe to topics với wildcard pattern:
  - `uagv/v2/{Manufacturer}/+/state`
  - `uagv/v2/{Manufacturer}/+/connection`
  - `uagv/v2/{Manufacturer}/+/visualization`
  - `uagv/v2/{Manufacturer}/+/factsheet`
- [ ] Message handler để deserialize messages
- [ ] Validate SerialNumber exists in database (qua IRobotService)
- [ ] Route messages to Event Bus based on message type
- [ ] Register service trong DI container (Singleton)

**Deliverables:**
- RobotConnectionsService hoàn chỉnh
- MQTT connection và subscription working
- Message routing to Event Bus

---

### Phase 3: RobotManager Service - Core Management
**Mục tiêu:** Quản lý RobotController instances và event routing

**Tasks:**
- [ ] Refactor RobotManagerService: Xóa `_robotData` dictionary
- [ ] Thêm `ConcurrentDictionary<string, IRobotController> _robotControllers`
- [ ] Subscribe to Event Bus events
- [ ] Implement event handlers:
  - `OnStateMessageReceived` → Tìm RobotController, update RobotData.State, determine OrderStatus
  - `OnConnectionStateChanged` → Tìm hoặc tạo RobotController, update ConnectionState
  - `OnVisualizationMessageReceived` → Tìm RobotController, update Visualization
  - `OnFactsheetMessageReceived` → Tìm RobotController, update Factsheet
- [ ] Implement `GetRobotController(robotId)` - Trả về instance
- [ ] Implement `GetAllRobotControllers()` - Trả về tất cả instances
- [ ] Implement `RemoveRobotController(robotId)` - Xóa instance và dispose
- [ ] Backward compatibility: `GetRobotData()` → delegate to `GetRobotController().RobotData`
- [ ] Register service trong DI container (Singleton)

**Deliverables:**
- RobotManagerService quản lý RobotController instances
- Event routing working
- RobotController creation on first message

---

### Phase 4: RobotController Implementation
**Mục tiêu:** Implement RobotController class (instance per robot)

**Tasks:**
- [ ] Tạo `IRobotController` interface
- [ ] Implement `RobotController` class với IDisposable
- [ ] Properties: `RobotId`, `RobotData`, `IsOnline`
- [ ] Inject dependencies: `IRobotConnectionsService`, `IConfigManager`, `Logger<RobotController>`
- [ ] Implement methods với thread-safe lock:
  - `MoveToNodeAsync()` - Tạo OrderMsg đơn giản với 1 node
  - `SendInstantActionAsync()` - Gửi instant action
  - `SendOrderAsync()` - Gửi order
  - `SendInstantActionsAsync()` - Gửi instant actions
  - `RequestFactsheetAsync()` - Gửi factsheetRequest action
  - `RequestStateAsync()` - Gửi RequestState action
  - `CancelOrderAsync()` - Gửi cancelOrder action
- [ ] Implement `Dispose()` để cleanup resources
- [ ] Helper methods: `FillVDA5050Header()`, `GetNextHeaderId()`

**Deliverables:**
- RobotController class hoàn chỉnh
- Thread-safe methods
- All control methods working

---

### Phase 5: Timeout Monitoring
**Mục tiêu:** Monitor robot timeout và set OFFLINE khi cần

**Tasks:**
- [ ] Implement timeout monitoring trong RobotManagerService
- [ ] Sử dụng `WatchTimerAsync` từ RobotNet10.Common
- [ ] Check interval: 15 giy
- [ ] Timeout threshold: 30 giy không có State hoặc Visualization
- [ ] Track last update time riêng biệt cho State và Visualization
- [ ] Reset timeout khi nhận State hoặc Visualization mới
- [ ] Set `ConnectionState = OFFLINE` khi timeout
- [ ] Start timer khi RobotManagerService start

**Deliverables:**
- Timeout monitoring working
- Auto-set OFFLINE khi timeout

---

### Phase 7: SignalR Integration
**Mục tiêu:** Real-time updates đến WebUI

**Tasks:**
- [ ] Update `RobotStateHub` để integrate với RobotManagerService
- [ ] Implement broadcast state changes khi state updated
- [ ] Implement per-robot subscriptions (groups)
- [ ] Broadcast connection state changes
- [ ] Broadcast order status changes
- [ ] Broadcast action status changes
- [ ] Test SignalR connections từ WebUI

**Deliverables:**
- SignalR integration hoàn chỉnh
- Real-time updates working
- WebUI có thể subscribe và nhận updates

---

### Phase 8: Testing & Integration
**Mục tiêu:** Test toàn bộ hệ thống

**Tasks:**
- [ ] Unit tests cho từng service
- [ ] Integration tests cho message flow
- [ ] Test với real MQTT broker
- [ ] Test với multiple robots (simulated)
- [ ] Performance testing (203 robots)
- [ ] Error handling testing
- [ ] Retry logic testing
- [ ] Documentation updates

**Deliverables:**
- Test suite hoàn chỉnh
- System tested và validated
- Documentation updated

---

## Implementation Checklist

### Phase 1: Foundation ✅
- [ ] Configuration models
- [ ] Event Bus system
- [ ] Service registration

### Phase 2: RobotConnections Core [ ]
- [ ] MQTT client connection
- [ ] Topic subscription
- [ ] Message routing

### Phase 3: RobotManager Core [ ]
- [ ] RobotController instance management
- [ ] Event routing to RobotController
- [ ] Auto-create RobotController
- [ ] Remove RobotController

### Phase 4: RobotController Implementation [ ]
- [ ] IRobotController interface
- [ ] RobotController class
- [ ] Thread-safe methods
- [ ] All control methods

### Phase 5: Timeout Monitoring [ ]
- [ ] WatchTimerAsync integration
- [ ] Timeout check logic
- [ ] Auto-set OFFLINE

### Phase 7: SignalR [ ]
- [ ] Hub integration
- [ ] Broadcast updates

### Phase 8: Testing [ ]
- [ ] Unit tests
- [ ] Integration tests
- [ ] Performance tests

## Related Documents

- VDA5050_EN.md - VDA5050 protocol specification
- RobotConnections.md - RobotConnections module documentation
- RobotManager.md - RobotManager module documentation
