# Identity Module / Module Xác thực

## Overview / Tổng quan

Identity Module quản lý authentication và authorization cho FleetManager, đảm bảo người dùng có quyền truy cập phù hợp với vai trò của họ.

## Mục đích / Purpose

- User authentication (Individual Account - ASP.NET Identity)
- Role-based access control (RBAC)
- Permission management
- User management

## 👥 Roles được định nghĩa / Defined Roles

```mermaid
graph TB
    subgraph "Development Team Roles"
        SystemAdmin[SystemAdmin<br/>Quản trị hệ thống<br/>Full access]
        Developer[Developer<br/>Nhà phát triển<br/>Script editing, Debug]
    end
    
    subgraph "Operations Team Roles"
        FleetOperator[FleetOperator<br/>Vận hành đội xe<br/>Mission control, Robot control]
        MapEditor[MapEditor<br/>Biên tập bản đồ<br/>Map management]
        Viewer[Viewer<br/>Người xem<br/>Read-only access]
    end
    
    subgraph "Special Roles"
        ScriptEditor[ScriptEditor<br/>Biên tập Script<br/>Script editing only]
        Analyst[Analyst<br/>Phân tích<br/>Analytics & Reports]
    end
    
    style SystemAdmin fill:#ffe6e6
    style Developer fill:#fff0e6
    style FleetOperator fill:#e6ffe6
    style MapEditor fill:#e6f3ff
    style Viewer fill:#f0e6ff
    style ScriptEditor fill:#fff9e6
    style Analyst fill:#e6e6ff
```

## Permissions Matrix / Ma trận Quyền

| Feature | SystemAdmin | Developer | FleetOperator | MapEditor | ScriptEditor | Analyst | Viewer |
|---------|-------------|-----------|---------------|-----------|--------------|---------|--------|
| System Config | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| User Management | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Script Editing | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Mission Control | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Robot Control | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Map Editing | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Analytics | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ |
| View Dashboard | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

## Multi-tenant Support / Hỗ trợ Đa Tenant

- Mỗi nhà máy có FleetManager instance riêng trên server local
- Nhiều khu vực trong nhà máy có thể dùng chung FleetManager nếu robot di chuyển qua lại giữa các khu vực

## Related Documents / Tài liệu Liên quan

- [FleetManager Overview](README.md) - Tổng quan FleetManager
- [Architecture Overview](../architecture/README.md) - Kiến trúc hệ thống

---

**Last Updated**: 2025-11-13

