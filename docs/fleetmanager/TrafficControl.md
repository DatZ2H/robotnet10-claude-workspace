# TrafficControl Module / Module Điều khiển Giao thông

## Overview / Tổng quan

TrafficControl Module tính toán route cho order, phát hiện conflict và đưa tuyến đường mới để giải quyết xung đột giữa các robot.

## Mục đích / Purpose

- Tính toán route tối ưu cho robot orders
- Phát hiện và giải quyết conflicts giữa các robot
- Quản lý base và horizon của VDA 5050 orders

## Chức năng chính / Main Features

### 1. Route Calculation / Tính toán Tuyến đường

- Tính toán route giữa hai nodes/stations
- Sử dụng A* algorithm trên map data từ MapEditor
- Đọc map data từ SQL Server database
- Tạo VDA 5050 order structure với nodes và edges

### 2. Base và Horizon Management

- **Base**: Phần order đã được release và robot đang thực hiện
- **Horizon**: Phần order chưa được release, đang chờ điều kiện
- Monitor traffic trên map
- Quyết định khi nào release thêm nodes/edges vào order
- Update `orderUpdateId` khi release thêm phần horizon

### 3. Conflict Detection / Phát hiện Xung đột

- Dựa trên **planned routes** của các robot
- Phát hiện head-on collisions
- Phát hiện deadlock situations
- Phát hiện resource conflicts

### 4. Conflict Resolution / Giải quyết Xung đột

- Sử dụng OrderUpdate để tạo tuyến đường mới cho một robot
- Deadlock resolution: Một robot đợi robot khác đi qua
- Robot nào hoàn thành phần base trước sẽ được đăng ký thêm phần base tiếp theo

## Conflict Resolution Flow / Luồng Giải quyết Xung đột

```mermaid
flowchart TD
    Detect[TrafficControl<br/>Detects Conflict<br/>based on planned routes] --> Analyze{Conflict Type}
    
    Analyze -->|Head-on Collision| CheckBase{Which robot<br/>finished base first?}
    Analyze -->|Deadlock| UpdateOrder[Send OrderUpdate<br/>to one robot]
    
    CheckBase -->|Robot A| UpdateA[Update Order for Robot A<br/>Add new base section<br/>via OrderUpdate]
    CheckBase -->|Robot B| UpdateB[Update Order for Robot B<br/>Add new base section<br/>via OrderUpdate]
    
    UpdateOrder --> Wait[Other robot waits<br/>via OrderUpdate]
    UpdateA --> Resolved[Conflict Resolved]
    UpdateB --> Resolved
    Wait --> Resolved
    
    style Detect fill:#ffe6e6
    style Resolved fill:#e6ffe6
```

## 📡 OrderUpdate Flow / Luồng OrderUpdate

```mermaid
sequenceDiagram
    participant TrafficControl
    participant MapEditor as Map Data
    participant RobotManager
    participant VDAHandler as VDA 5050 Handler
    participant MQTT
    participant Robot
    
    Note over TrafficControl: Detects conflict or<br/>traffic allows extension
    TrafficControl->>MapEditor: Get route extension
    MapEditor->>TrafficControl: New route section
    TrafficControl->>RobotManager: Check robot state
    RobotManager->>TrafficControl: Current order info
    TrafficControl->>VDAHandler: Generate OrderUpdate<br/>(same orderId, orderUpdateId++)
    VDAHandler->>MQTT: Publish OrderUpdate (QoS 1)
    MQTT->>Robot: Forward OrderUpdate
    
    Robot->>Robot: Continue with extended route
    Robot->>MQTT: State Update (new orderUpdateId)
    MQTT->>RobotManager: Forward State
```

## Related Documents / Tài liệu Liên quan

- [FleetManager Overview](README.md) - Tổng quan FleetManager
- [MapEditor Module](MapEditor.md) - Cung cấp map data cho route calculation
- [RobotManager Module](RobotManager.md) - Cung cấp robot state để check conflicts
- [VDA 5050 Integration](../vda5050/README.md) - Chi tiết về OrderUpdate mechanism

---

**Last Updated**: 2025-11-13

