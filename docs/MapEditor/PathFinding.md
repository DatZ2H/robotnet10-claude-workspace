# PathFinding Architecture / Kiến trúc Tìm đường

## Overview / Tổng quan

MapEditor tích hợp A* algorithm để tính toán routes giữa các stations trên map.

## A* Algorithm Workflow

```mermaid
graph TD
    Start([PathFinding Request<br/>startStationId<br/>endStationId<br/>vehicleTypeId]) --> LoadData[Load Graph Data<br/>Query Stations table<br/>Query Edges table]

    LoadData --> FilterVehicle{Vehicle Type<br/>Filtering?}
    FilterVehicle -->|Yes| FilterEdges[Filter Edges<br/>vehicleTypeIds contains type]
    FilterVehicle -->|No| BuildGraph
    FilterEdges --> BuildGraph[Build Graph Structure<br/>Adjacency list]

    BuildGraph --> InitAStar[Initialize A*<br/>openSet, closedSet<br/>gScore, fScore]

    InitAStar --> Loop{Open Set<br/>Not Empty?}
    Loop -->|No| NoPath([No Path Found])
    Loop -->|Yes| Current[Dequeue lowest fScore]

    Current --> CheckGoal{current ==<br/>endStation?}
    CheckGoal -->|Yes| Reconstruct[Reconstruct Path<br/>Backtrack via cameFrom]
    CheckGoal -->|No| Expand[Expand Neighbors]

    Reconstruct --> Result([Return Path<br/>edgeIds[], stationIds[]<br/>totalDistance, estimatedTime])

    Expand --> CalcG[Calculate gScore]
    CalcG --> CheckBetter{gScore better?}
    CheckBetter -->|Yes| Update[Update scores<br/>Add to openSet]
    Update --> Loop

    style Start fill:#e6ffe6
    style Result fill:#e6ffe6
    style NoPath fill:#ffe6e6
```

## Graph Representation

**Adjacency List Structure**:
- Nodes Map: stationId → Station object
- Edges Map: edgeId → Edge object
- Adjacency List: stationId → List of Edge

## Heuristic Function

**Euclidean Distance**:
```
h(station, goal) = sqrt((goal.x - station.x)+ (goal.y - station.y))
```

**Properties**:
- Admissible: Never overestimates
- Consistent: Satisfies triangle inequality
- Guarantees: Optimal path với A*

## Edge Weight Calculation

**Weight = Travel Time**:
```
weight(edge) = edge.length / edge.maxSpeed
```

**Rationale**: Optimize for fastest path (considers both distance AND speed limits)

## Vehicle Type Filtering

**Filter Logic**:
- Edge có vehicleTypeIds empty/null → Allow all vehicles
- Edge có vehicleTypeIds → Check if contains requestedType
- If match → Include in graph
- If no match → Exclude from graph

## ✅ Path Validation

**Validation Steps**:
1. Connectivity: Path exists?
2. Edge Sequence: Edges connect properly?
3. Speed Limits: Robot capabilities compatible?
4. Orientation: Robot can achieve required orientations?

**Return Path Object**:
- edgeIds: string[]
- stationIds: string[]
- totalDistance: float
- estimatedTime: float
- validationStatus: Valid | Warning | Invalid

## Related Documents / Tài liệu Liên quan

- [MapEditor Overview](README.md) - Tổng quan MapEditor
- [Database Design](Database_Design.md) - Graph data từ database
- [VDA 5050 Integration](VDA5050_Integration.md) - Convert path to VDA 5050 order

---

**Last Updated**: 2025-11-13
