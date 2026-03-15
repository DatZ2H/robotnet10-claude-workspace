# Import/Export Workflow / Quy trình Import/Export

## Overview / Tổng quan

MapEditor hỗ trợ import và export VDMA LIF JSON format để trao đổi map data với các hệ thống khác.

## Import Process / Quy trình Import

```mermaid
flowchart TD
    Start([User Upload<br/>VDMA LIF JSON]) --> Parse[Parse JSON<br/>Deserialize to models]

    Parse --> ValidFormat{Valid JSON<br/>Structure?}
    ValidFormat -->|No| ErrorFormat[Error: Invalid JSON<br/>Abort import]

    ValidFormat -->|Yes| ValidSchema{Valid VDMA LIF<br/>Schema?}
    ValidSchema -->|No| ErrorSchema[Error: Schema mismatch<br/>Abort import]

    ValidSchema -->|Yes| ValidRefs{Valid<br/>References?}
    ValidRefs -->|No| ErrorRefs[Error: Broken references<br/>Abort import]

    ValidRefs -->|Yes| Transaction[Begin Database Transaction]

    Transaction --> SaveMap[Create Map Entity]
    SaveMap --> SaveVTypes[Create VehicleTypes]
    SaveVTypes --> SaveStations[Create Stations]
    SaveStations --> SaveINodes[Create InteractionNodes]
    SaveINodes --> SaveActions[Create Actions]
    SaveActions --> SaveEdges[Create Edges]
    SaveEdges --> SaveZones[Create Zones]

    SaveZones --> ValidateMap[Validate Map<br/>Connectivity check]

    ValidateMap --> ValidCheck{Validation<br/>Passed?}
    ValidCheck -->|No| Rollback[Rollback Transaction<br/>Abort import]
    ValidCheck -->|Yes| Commit[Commit Transaction]

    Commit --> Success([Import Complete<br/>Return Map ID])

    style Start fill:#e6ffe6
    style Success fill:#e6ffe6
    style ErrorFormat fill:#ffe6e6
    style Rollback fill:#ffe6e6
```

## Export Process / Quy trình Export

```mermaid
flowchart TD
    Start([User Click Export<br/>Select Map ID]) --> LoadMap[Load Map Entity]

    LoadMap --> LoadRelated[Load Related Entities<br/>Parallel queries]

    LoadRelated --> LoadVTypes[Query VehicleTypes]
    LoadRelated --> LoadStations[Query Stations]
    LoadRelated --> LoadEdges[Query Edges]
    LoadRelated --> LoadZones[Query Zones]

    LoadStations --> LoadINodes[Query InteractionNodes]
    LoadINodes --> LoadActions[Query Actions]

    LoadVTypes --> Transform[Transform to VDMA LIF Models]
    LoadActions --> Transform
    LoadEdges --> Transform
    LoadZones --> Transform

    Transform --> Build[Build VDMA LIF Structure<br/>metaInformation, layout, arrays]

    Build --> Serialize[Serialize to JSON<br/>camelCase, pretty print]

    Serialize --> Validate{Valid VDMA LIF<br/>Output?}
    Validate -->|No| ErrorExport[Internal Error]
    Validate -->|Yes| Download[Generate Download<br/>Filename: mapId.json]

    Download --> Success([Export Complete])

    style Start fill:#e6ffe6
    style Success fill:#e6ffe6
    style ErrorExport fill:#ffe6e6
```

## ✅ Data Integrity Guarantees

**Import Validations**:
1. JSON Syntax: Valid JSON format
2. Schema Compliance: Required fields present
3. Reference Integrity: Edges reference existing stations
4. Geometric Validity: Positions, trajectories valid
5. Unique Constraints: No duplicate IDs

**Export Guarantees**:
1. Completeness: All related entities included
2. Format Compliance: Valid VDMA LIF schema
3. Reference Resolution: All IDs properly mapped
4. Transaction Safety: All-or-nothing import

## Related Documents / Tài liệu Liên quan

- [MapEditor Overview](README.md) - Tổng quan MapEditor
- [VDMA LIF Standard](VDMA_LIF_Standard.md) - Format specification
- [Database Design](Database_Design.md) - Database schema

---

**Last Updated**: 2025-11-13
