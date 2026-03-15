# RobotConnections Module / Module Kết nối Robot

## Overview / Tổng quan

RobotConnections Module quản lý kết nối MQTT của các robot theo VDA 5050, đảm bảo giao tiếp ổn định giữa FleetManager và RobotApp.

## Mục đích / Purpose

Quản lý kết nối MQTT của các robot theo VDA 5050 để đảm bảo giao tiếp ổn định và real-time.

## ⚠️ Lưu ý / Important Note

**MQTT Broker chạy trên service ngoài FleetManager** (không phải trong FleetManager).

## Chức năng chính / Main Features

- Quản lý MQTT connection status của từng robot
- Subscribe/unsubscribe MQTT topics theo VDA 5050
- Connection timeout và reconnection logic
- Heartbeat mechanism (qua VDA 5050 connection messages)
- Thông báo cho RobotManager khi robot disconnect/reconnect

## 📡 MQTT Topics Management / Quản lý MQTT Topics

```mermaid
graph TB
    subgraph "Subscribed Topics<br/>Robot → FleetManager"
        StateTopic[uagv/v2/{manufacturer}/+/state<br/>QoS: 0, Retain: true]
        VizTopic[uagv/v2/{manufacturer}/+/visualization<br/>QoS: 0, Retain: false]
        ConnTopic[uagv/v2/{manufacturer}/+/connection<br/>QoS: 1, Retain: true]
    end
    
    subgraph "Published Topics<br/>FleetManager → Robot"
        OrderTopic[uagv/v2/{manufacturer}/{serialNumber}/order<br/>QoS: 1, Retain: false]
        InstantTopic[uagv/v2/{manufacturer}/{serialNumber}/instantActions<br/>QoS: 1, Retain: false]
    end
    
    RobotConnections[RobotConnections Module] --> StateTopic
    RobotConnections --> VizTopic
    RobotConnections --> ConnTopic
    RobotConnections --> OrderTopic
    RobotConnections --> InstantTopic
    
    style RobotConnections fill:#e6f3ff
```

## Connection States / Trạng thái Kết nối

- **ONLINE**: Robot connected và operational
- **OFFLINE**: Robot disconnected
- **CONNECTIONBROKEN**: Connection lost unexpectedly

## Features / Tính năng

- Không lưu connection history (chỉ quản lý state hiện tại)
- Auto-reconnection logic khi connection lost
- Notify RobotManager về connection status changes

## Related Documents / Tài liệu Liên quan

- [FleetManager Overview](README.md) - Tổng quan FleetManager
- [RobotManager Module](RobotManager.md) - Nhận thông báo từ RobotConnections
- [VDA 5050 Integration](../vda5050/README.md) - Chi tiết về VDA 5050 protocol

---

**Last Updated**: 2025-11-13

