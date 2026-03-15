# SVG Canvas Architecture / Kiến trúc Canvas SVG

## Overview / Tổng quan

MapEditor sử dụng SVG canvas để render và edit maps với interactive features.

## Rendering Strategy / Chiến lược Render

```mermaid
graph TD
    DataLoad[Load Map Data<br/>from Server API] --> Layers[Layer Management<br/>Organize visual elements]

    Layers --> BG[Background Layer<br/>Factory floor image<br/>Optional grid overlay]
    Layers --> ZoneL[Zone Layer<br/>Polygon areas<br/>Fill + stroke colors]
    Layers --> EdgeL[Edge Layer<br/>Lines with arrows<br/>Color by direction]
    Layers --> StationL[Station Layer<br/>Icons by type<br/>Labels]
    Layers --> OverlayL[Overlay Layer<br/>Selection highlights<br/>Hover tooltips]

    BG --> Render[SVG Rendering Engine]
    ZoneL --> Render
    EdgeL --> Render
    StationL --> Render
    OverlayL --> Render

    Render --> Interaction[Interaction Handler<br/>Mouse events<br/>Touch events]

    Interaction --> Select[Selection<br/>Single/multi-select<br/>Highlight selected]
    Interaction --> Hover[Hover<br/>Show tooltips<br/>Preview info]
    Interaction --> Drag[Drag<br/>Move objects<br/>Update coordinates]
    Interaction --> PanZoom[Pan & Zoom<br/>Canvas navigation<br/>Wheel/pinch gestures]

    Select --> Inspector[Object Inspector<br/>Property panel<br/>Edit values]
    Drag --> Inspector

    style BG fill:#f5f5f5
    style ZoneL fill:#ffe6f0
    style EdgeL fill:#fff0e6
    style StationL fill:#e6f3ff
    style OverlayL fill:#f0e6ff
```

## Coordinate Systems / Hệ tọa độ

**Two Coordinate Systems**:

1. **Screen Coordinates** (Canvas pixels):
   - Origin: Top-left corner
   - X-axis: Right (positive)
   - Y-axis: Down (positive)
   - Used for: Rendering, mouse events

2. **World Coordinates** (Physical meters):
   - Origin: Map referencePoint
   - X-axis: Right (positive)
   - Y-axis: Up (positive)
   - Used for: VDMA LIF data, robot positions

**Transformation**: World ↔ Screen với scale, translate, và Y-axis flip

## Visual Styling Conventions

**Station Icons by Type**:
- Charging: Lightning bolt, yellow
- Pickup: Box icon, green
- Dropoff: Outbox icon, red
- Parking: P icon, blue

**Edge Visualization**:
- Bidirectional: Gray line, no arrow
- Unidirectional: Blue line, arrow at end
- Selected: Orange outline, dashed

**Zone Appearance**:
- Safety Zone: Blue fill, semi-transparent
- Restricted Zone: Red fill, diagonal stripes
- Speed Limit Zone: Yellow fill

## Editing Workflows

**Object Creation**: Tool select → Click canvas → Create → Property edit → Validate

**Object Manipulation**: Click → Select → Drag/Edit → Validate → Save

**Multi-Object Operations**: Box selection, Shift+Click, Batch edit, Align tools

## Related Documents / Tài liệu Liên quan

- [MapEditor Overview](README.md) - Tổng quan MapEditor
- [VDMA LIF Standard](VDMA_LIF_Standard.md) - Map data structure

---

**Last Updated**: 2025-11-13
