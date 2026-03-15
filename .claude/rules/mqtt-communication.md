---
globs:
  - "srcs/**/MqttConnection/**"
  - "srcs/**/RobotConnections/**"
---

# MQTT Communication Patterns

## Library

RobotNet10 uses **MQTTnet** for MQTT communication.

## VDA 5050 topic structure

```
{interfaceName}/{majorVersion}/{manufacturer}/{serialNumber}/{topic}
```

Example: `uagv/v2/Phenikaa-X/robot-001/order`

Standard topics: `order`, `instantActions`, `state`, `visualization`, `connection`, `factsheet`

## QoS levels

| Message type | QoS | Rationale |
|-------------|-----|-----------|
| Order | QoS 1 (at least once) | Must not be lost |
| InstantAction | QoS 1 | Must not be lost |
| State | QoS 0 (at most once) | Frequent updates, latest value matters |
| Visualization | QoS 0 | High frequency, loss acceptable |
| Connection | QoS 1 + retained | Must persist for last-will detection |

## Reconnection handling

- MQTTnet handles auto-reconnection via `MqttClientOptions.CleanSession = false`
- Application-level: re-subscribe to topics after reconnect
- Connection state changes must be logged and propagated to UI (via SignalR or state service)
- Do NOT assume messages received in order after reconnection

## Message serialization

- Use `System.Text.Json` with `JsonPropertyName` attributes matching VDA 5050 spec
- Models in `Shared/RobotNet.VDA5050/` — do NOT create duplicate models
- Deserialize with null-safety: always check for null fields in received messages

## When editing MQTT code

- Test with both connected and disconnected scenarios
- Verify QoS levels match the table above
- Handle `MqttClientDisconnectedEventArgs` — check `Exception` for root cause
- Retained messages: only use for Connection topic (last-will)
- Thread safety: MQTTnet callback handlers may run on different threads
- Do NOT block in message handlers — offload heavy processing to background tasks
