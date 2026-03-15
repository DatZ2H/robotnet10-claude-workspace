# Design Rationale / Lý do Thiết kế

## Overview / Tổng quan

Tài liệu này giải thích các quyết định thiết kế quan trọng của MapEditor.

## Why VDMA LIF Standard?

| Rationale | Explanation |
|-----------|-------------|
| **Industry Standard** | Widely adopted trong EU logistics and manufacturing |
| **Interoperability** | Exchange maps với AutoCAD, other fleet systems |
| **Future-proof** | Active standard với ongoing development |
| **Tool Support** | CAD tools can export VDMA LIF |
| **Comprehensive** | Covers all requirements |
| **Open Specification** | Publicly available, không vendor lock-in |

## Why Blazor WASM + SVG Canvas?

| Rationale | Explanation |
|-----------|-------------|
| **No Plugins** | Runs trong any modern browser |
| **C# on Client** | Share code với server |
| **SVG Native** | Scalable vector graphics, perfect for maps |
| **WASM Performance** | Near-native speed |
| **Interactive** | Easy event handling |
| **Accessibility** | SVG elements accessible |
| **Export Quality** | SVG can be exported to PDF, PNG |

## Why Normalized Database Schema?

| Rationale | Explanation |
|-----------|-------------|
| **Query Flexibility** | Find all charging stations easily |
| **Data Integrity** | Foreign keys prevent orphaned data |
| **Performance** | Indexes optimize queries |
| **Maintenance** | Update individual stations easily |
| **Analytics** | Join với robot positions, metrics |
| **Scalability** | Large maps still performant |

## Why PathFinding Integration?

| Rationale | Explanation |
|-----------|-------------|
| **Validation** | Ensure routes exist before dispatch |
| **Optimization** | Find shortest/fastest path |
| **Conflict Avoidance** | Calculate alternative routes |
| **Map Quality** | Detect connectivity issues |
| **User Feedback** | Show estimated time and distance |

**Algorithm Choice - A***:
- Optimal: Guaranteed shortest path
- Efficient: Heuristic guides search
- Flexible: Adjustable cost function
- Standard: Well-known algorithm

## Related Documents / Tài liệu Liên quan

- [MapEditor Overview](README.md) - Tổng quan MapEditor
- [VDMA LIF Standard](VDMA_LIF_Standard.md) - Chuẩn VDMA LIF
- [Database Design](Database_Design.md) - Database schema rationale
- [PathFinding](PathFinding.md) - PathFinding rationale

---

**Last Updated**: 2025-11-13
