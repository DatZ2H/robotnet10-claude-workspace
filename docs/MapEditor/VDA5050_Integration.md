# VDA 5050 Integration / Tích hợp VDA 5050

## Overview / Tổng quan

MapEditor convert map data thành VDA 5050 Order messages để gửi đến robot.

## Conversion Concept

```mermaid
graph LR
    subgraph "VDMA LIF Map"
        MapStations[Stations<br/>Physical locations]
        MapINodes[InteractionNodes<br/>Approach points]
        MapActions[Actions<br/>Behaviors]
        MapEdges[Edges<br/>Navigation paths]
    end

    subgraph "VDA 5050 Order"
        OrderNodes[Nodes<br/>Waypoints]
        OrderEdges[Edges<br/>Paths]
        OrderActions[Actions<br/>Tasks]
    end

    MapINodes -->|Map position<br/>+ deviations| OrderNodes
    MapActions -->|Copy action<br/>properties| OrderActions
    MapEdges -->|Map trajectory<br/>+ constraints| OrderEdges

    OrderActions -.->|Embedded in| OrderNodes

    style MapStations fill:#e6f3ff
    style MapINodes fill:#e6ffe6
    style MapActions fill:#f0e6ff
    style MapEdges fill:#fff0e6
    style OrderNodes fill:#e6f3ff
    style OrderEdges fill:#fff0e6
    style OrderActions fill:#f0e6ff
```

## Order Generation Flow

```mermaid
sequenceDiagram
    participant FM as FleetManager
    participant PF as PathFinder
    participant Gen as OrderGenerator
    participant DB as Database

    FM->>PF: FindPath(startStation, endStation)
    PF->>DB: Load Stations & Edges
    PF->>PF: Run A* algorithm
    PF-->>FM: Path (stationIds[], edgeIds[])

    FM->>Gen: GenerateOrder(path, vehicleType)
    Gen->>DB: Load InteractionNodes for stations
    Gen->>DB: Load Actions for nodes
    Gen->>Gen: Build Order structure
    Gen-->>FM: VDA 5050 Order object
```

## Mapping Rules

**InteractionNode → VDA 5050 Node**:
- nodeId: InteractionNode.interactionNodeId
- sequenceId: Even numbers (0, 2, 4, ...)
- nodePosition: From InteractionNode position
- actions: From Actions table

**Edge → VDA 5050 Edge**:
- edgeId: Edge.edgeId
- sequenceId: Odd numbers (1, 3, 5, ...)
- trajectory: From Edge.trajectory
- maxSpeed: From Edge.maxSpeed

**Action → VDA 5050 Action**:
- actionType: Action.actionType
- blockingType: Action.blockingType
- actionParameters: Action.actionParameters

## Vehicle Type Filtering

**Filtering Logic**:
- Load InteractionNodes for each station
- Check vehicleTypeIds compatibility
- Filter edges by vehicleTypeIds
- Build Order với filtered elements only

## Related Documents / Tài liệu Liên quan

- [MapEditor Overview](README.md) - Tổng quan MapEditor
- [PathFinding](PathFinding.md) - Tính toán path trước khi generate order
- [VDA 5050 Integration](../vda5050/README.md) - Chi tiết về VDA 5050 protocol

---

**Last Updated**: 2025-11-13
