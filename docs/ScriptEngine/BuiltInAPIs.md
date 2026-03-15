# Built-in APIs / API Tích hợp Sẵn

##Overview / Tổng quan

Các APIs có sẵn trong tất cả scripts mà không cần import hoặc khai báo.

##Logger API

```csharp
Logger.Info("Informational message");
Logger.Warning("Warning message");
Logger.Error("Error message");
```

##Mission Management APIs

```csharp
// Create mission
Guid missionId = CreateMission("DeliverPackage",
    fromLocation: "A1",
    toLocation: "B2");

// Cancel mission
CancelMission(missionId);
```

##Task Control APIs

```csharp
EnableTask("MonitoringTask");   // Resume task - chuyển từ Paused → Running
DisableTask("MaintenanceTask"); // Pause task - chuyển từ Running → Paused
```

**Lưu ý**: 
- `EnableTask/DisableTask` là API level (public interface cho scripts)
- Tương đương với `Pause/Resume` ở state machine level
- Xem chi tiết về Task state machine trong [StateMachine_Design.md](StateMachine_Design.md)

##IO Connection APIs / API Kết nối IO

ScriptEngine hỗ trợ các giao tiếp công nghiệp phổ biến để tích hợp với thiết bị bên ngoài:

### HTTP Connection

```csharp
var httpConn = RobotNet.CreateHttpConnection("http://localhost:8080", timeoutSeconds: 30);
await httpConn.ConnectAsync();
var response = await httpConn.GetAsync("/api/data");
await httpConn.PostAsync("/api/update", jsonData, "application/json");
await httpConn.DisconnectAsync();
```

### ModbusTCP Connection

```csharp
var modbusConn = RobotNet.CreateModbusTcpConnection("192.168.1.100", port: 502, slaveId: 1);
await modbusConn.ConnectAsync();
var registers = await modbusConn.ReadHoldingRegistersAsync(0, 10);
await modbusConn.WriteSingleRegisterAsync(0, 100);
await modbusConn.DisconnectAsync();
```

### OPC UA Connection

```csharp
var opcConn = RobotNet.CreateOpcUaConnection("opc.tcp://localhost:4840");
await opcConn.ConnectAsync();
// Hoặc với authentication
await opcConn.ConnectAsync("username", "password");

var value = await opcConn.ReadNodeAsync("ns=2;s=MyVariable");
await opcConn.WriteNodeAsync("ns=2;s=MyVariable", 123);
var nodes = await opcConn.BrowseNodesAsync();
await opcConn.DisconnectAsync();
```

### ProfiNet Connection

```csharp
var profinetConn = RobotNet.CreateProfiNetConnection("192.168.1.100", slot: 1, subslot: 1);
await profinetConn.ConnectAsync();
var data = await profinetConn.ReadAsync(index: 0, length: 100);
await profinetConn.WriteAsync(index: 0, data: byteArray);
await profinetConn.DisconnectAsync();
```

**Lưu ý**: ProfiNet implementation hiện tại là skeleton, cần thêm thư viện hoặc implement protocol stack đầy đủ.

### CC-Link IE Connection

```csharp
var cclinkConn = RobotNet.CreateCcLinkIeConnection("192.168.1.100", stationNumber: 1);
await cclinkConn.ConnectAsync();
var data = await cclinkConn.ReadAsync(address: 0, length: 10);
await cclinkConn.WriteAsync(address: 0, data: ushortArray);
await cclinkConn.DisconnectAsync();
```

**Lưu ý**: CC-Link IE implementation hiện tại là skeleton, cần thêm thư viện hoặc implement protocol stack đầy đủ.

### Connection Lifecycle

Tất cả connections đều implement `IDisposable` và nên được dispose sau khi sử dụng:

```csharp
using var httpConn = RobotNet.CreateHttpConnection("http://localhost:8080");
await httpConn.ConnectAsync();
// ... use connection ...
// Automatically disposed when exiting using block
```

##Related Documents / Tài liệu Liên quan

- [ScriptEngine Overview](README.md) - Tổng quan ScriptEngine
- [Tasks](Tasks.md) - Sử dụng Task control APIs
- [Missions](Missions.md) - Sử dụng Mission management APIs
- [Extension APIs](ExtensionAPIs.md) - App-specific APIs

---

**Last Updated**: 2025-11-13

