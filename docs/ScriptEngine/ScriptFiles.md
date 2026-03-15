# Script Files / File Script

##Overview / Tổng quan

ScriptEngine hỗ trợ multi-file C# scripts, cho phép tổ chức code như một C# project thực sự.

##File Organization / Tổ chức File

Scripts được tổ chức như C# project:

```
Scripts/
├── Common/
│   ├── Helpers.cs          # Shared helper methods
│   └── Constants.cs        # Global constants
├── Tasks/
│   ├── MonitorTask.cs      # Periodic monitoring
│   └── MaintenanceTask.cs  # Periodic maintenance
└── Missions/
    ├── DeliverMission.cs   # Delivery workflow
    └── ChargeMission.cs    # Charging workflow
```

##Đặc điểm / Features

- **Multi-file support**: Files share variables & methods
- **Top-level statements**: Allowed trong C# scripts
- **Class definitions**: Can define classes, structs, enums
- **Using directives**: Supported for namespaces
- **File system storage**: Scripts lưu trong file system
- **Backup & Restore**: ZIP format với preserved structure

##File Locking / Khóa File

- SignalR-based file locking
- Khi user đang edit, các session khác không được sửa file
- ScriptEngine quản lý trạng thái cho phép chỉnh sửa hay không
- Không có realtime update file content, chỉ khi user gọi action Save mới gửi lên server

##Related Documents / Tài liệu Liên quan

- [ScriptEngine Overview](README.md) - Tổng quan ScriptEngine
- [Backup & Restore](DataPersistence.md#backup--restore) - Sao lưu và khôi phục scripts

---

**Last Updated**: 2025-11-13

