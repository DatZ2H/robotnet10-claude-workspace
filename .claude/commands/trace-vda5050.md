---
description: Trace VDA 5050 message flow across FleetManager and RobotApp
---

# Trace VDA 5050 Message Flow

Trace how a VDA 5050 message (Order, State, InstantAction, etc.) flows through the system.

## Parse the argument: $ARGUMENTS

Accepted message types: Order, State, InstantAction, Visualization, Connection, FactSheet
Default: Order (if no argument provided)

## Steps

1. Identify the message model in `Shared/RobotNet.VDA5050/` (e.g., OrderMsg, StateMsg)
2. Use the Agent tool to spawn 2 parallel subagents:

### Subagent 1: FleetManager side
Search and trace the message flow through FleetManager:
- MQTT topic subscription/publishing (in RobotConnections or Services)
- Message deserialization and validation
- Business logic processing (RobotManager, TrafficControl, RobotController)
- Response message construction and publishing
- Report the chain: MQTT topic → handler method → processing → response

### Subagent 2: RobotApp side
Search and trace the message flow through RobotApp:
- MQTT topic subscription/publishing
- Message deserialization
- State machine transitions triggered by this message
- Action execution
- Response/status message construction
- Report the chain: MQTT topic → handler → state machine → action → response

3. Combine results into a unified flow diagram:

```
FleetManager                    MQTT                    RobotApp
─────────────                   ────                    ────────
[publish Order] ──────────────> topic ──────────────> [receive Order]
                                                      [validate]
                                                      [state transition]
                                                      [execute actions]
[receive State] <────────────── topic <────────────── [publish State]
```

4. List all files involved in the flow, grouped by project
5. Note any error handling, retry logic, or edge cases found
