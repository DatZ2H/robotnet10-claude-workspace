# Variables / Biến Toàn cục

##Overview / Tổng quan

Variables là shared state được chia sẻ giữa tất cả scripts trong ScriptEngine.

##Cách sử dụng / Usage

```csharp
// Simple variable (không hiện UI)
int counter = 0;
string robotName = "ROBOT001";

// Variable visible trong UI (read-only)
[Variable]
double batteryThreshold = 20.0;

// Variable có thể edit từ UI
[Variable(Writeable = true)]
int maxSpeed = 100;
```

##Cách hoạt động / How It Works

- Stored in `ConcurrentDictionary<string, object?>`
- Thread-safe dictionary operations
- Runtime-only (không persist to database)
- Property wrappers tự động generate

##Variable Attributes / Thuộc tính Variable

- `[Variable]`: Variable hiển thị trong UI, read-only
- `[Variable(Writeable = true)]`: Variable có thể edit từ UI
- Không có attribute: Variable không hiển thị trong UI

##Related Documents / Tài liệu Liên quan

- [ScriptEngine Overview](README.md) - Tổng quan ScriptEngine
- [Tasks](Tasks.md) - Tasks có thể đọc/ghi variables
- [Missions](Missions.md) - Missions có thể đọc/ghi variables

---

**Last Updated**: 2025-11-13

