# VDMA LIF Standard / Chuẩn VDMA LIF

## Overview / Tổng quan

VDMA LIF (Layout Interchange Format) là chuẩn quốc tế để mô tả factory layout cho AGV/AMR systems.

## Conceptual Model / Mô hình Khái niệm

```mermaid
graph LR
    Map[Map<br/>Factory Layout<br/>Coordinate system] --> Stations[Stations<br/>Physical locations<br/>pickup, dropoff, charging]
    Map --> Edges[Edges<br/>Navigation paths<br/>Connections between stations]
    Map --> Zones[Zones<br/>Special areas<br/>Restricted, slow-speed]
    Map --> VTypes[VehicleTypes<br/>Robot specifications<br/>Dimensions, envelopes]

    Stations --> INodes[InteractionNodes<br/>Approach points<br/>Position + deviation]
    INodes --> Actions[Actions<br/>Robot behaviors<br/>pick, drop, charge, wait]

    Edges -.->|references| Stations

    style Map fill:#ffe6e6
    style Stations fill:#e6f3ff
    style INodes fill:#e6ffe6
    style Edges fill:#fff0e6
    style Actions fill:#f0e6ff
    style Zones fill:#ffe6f0
    style VTypes fill:#f0ffe6
```

## Object Hierarchy / Phân cấp Đối tượng

```mermaid
graph TD
    LIF[VDMA LIF Document]
    LIF --> Meta[MetaInformation<br/>Project ID, Creator, Timestamp]
    LIF --> Layout[Layout Properties<br/>layoutId, layoutName<br/>layoutVersion, layoutDescription<br/>layoutLevel]
    LIF --> CoordRef[Coordinate Reference Point<br/>Origin x, y]
    LIF --> VTypes[VehicleTypes Array]
    LIF --> Stations[Stations Array]
    LIF --> Edges[Edges Array]
    LIF --> Zones[Zones Array]

    VTypes --> VType[VehicleType<br/>vehicleTypeId, description<br/>vehicleGeometry<br/>envelopes2d]

    Stations --> Station[Station<br/>stationId, stationType<br/>stationPosition]
    Station --> INodes[InteractionNodes Array]
    INodes --> INode[InteractionNode<br/>interactionNodeId<br/>nodePosition<br/>vehicleTypeIds]
    INode --> Actions[Actions Array]
    Actions --> Action[Action<br/>actionType, blockingType<br/>actionParameters]

    Edges --> Edge[Edge<br/>edgeId, startStationId, endStationId<br/>trajectory, maxSpeed<br/>bidirectional, vehicleTypeIds]

    Zones --> Zone[Zone<br/>zoneId, zoneType<br/>polygon geometry]

    style LIF fill:#ffe6e6
    style Layout fill:#e6f3ff
    style Station fill:#e6ffe6
    style INode fill:#fff0e6
    style Action fill:#f0e6ff
    style Edge fill:#ffe6f0
    style Zone fill:#f0ffe6
```

## Core Concepts / Khái niệm Cốt lõi

**Map / Layout**:
- Top-level container cho tất cả map elements
- Defines coordinate system (origin, resolution)
- Properties: layoutId, name, version, level (floor number)

**Station** (Physical location):
- Represents a physical point trong factory
- Properties: stationId, stationType, stationPosition (x, y, theta)
- Contains one hoặc nhiều InteractionNodes

**InteractionNode** (Approach point):
- Specific position nơi robot interacts với station
- Multiple nodes per station cho different vehicle types
- Properties: interactionNodeId, position, allowedDeviations
- Contains Actions to execute

**Action** (Robot behavior):
- Defines what robot does tại InteractionNode
- Properties: actionType, blockingType, actionParameters
- Blocking types: HARD, SOFT, NONE

**Edge** (Navigation path):
- Connection between two stations
- Properties: edgeId, startStationId, endStationId, trajectory
- bidirectional: true/false

**Zone** (Special area):
- 2D polygon area với special properties
- Zone types: safetyZone, restrictedZone, speedLimitZone

**VehicleType** (Robot specification):
- Defines robot dimensions và capabilities
- Referenced by vehicleTypeIds trong stations, nodes, edges

## Related Documents / Tài liệu Liên quan

- [MapEditor Overview](README.md) - Tổng quan MapEditor
- [Database Design](Database_Design.md) - Cấu trúc database cho VDMA LIF
- [Import/Export](ImportExport.md) - Import/Export VDMA LIF JSON

---

**Last Updated**: 2025-11-13
