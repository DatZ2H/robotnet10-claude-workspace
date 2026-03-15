# Script Compilation Process / Quá trình Biên dịch

##Overview / Tổng quan

ScriptEngine compile C# scripts sử dụng Roslyn để extract metadata và generate executable runners.

##Compilation Flow / Luồng Biên dịch

```mermaid
flowchart TD
    Start([User clicks Build]) --> Collect[Step 1: Collect Files<br/>Load all .cs files]
    Collect --> Merge[Step 2: Merge Code<br/>Combine into DummyClass]
    Merge --> Compile[Step 3: Compile<br/>Roslyn CSharpCompilation]
    Compile --> Analyze[Step 4: Analyze<br/>Extract Variables, Tasks, Missions]
    Analyze --> Generate[Step 5: Generate Runners<br/>Create TaskRunner, MissionRunner]
    Generate --> Ready[State: Ready<br/>Can start execution]

    Compile -->|Errors| BuildError[State: BuildError<br/>Show diagnostics]

    style Start fill:#e6ffe6
    style Ready fill:#e6ffe6
    style BuildError fill:#ffe6e6
```

##Chi tiết từng bước / Step Details

1. **Collect Files**: Load tất cả `.cs` files từ filesystem
2. **Merge Code**: Combine vào một `DummyClass` để phân tích
3. **Compile**: Sử dụng Roslyn để compile và lấy SemanticModel
4. **Analyze**: Extract metadata (variables với `[Variable]`, methods với `[Task]`/`[Mission]`)
5. **Generate Runners**: Tạo executable classes cho mỗi task/mission

##IntelliSense Support / Hỗ trợ IntelliSense

- Sử dụng AdhocWorkspace trên WebAssembly
- IntelliSense, Hover information, Diagnostics
- Real-time code analysis
- No server round-trip for IntelliSense

##Related Documents / Tài liệu Liên quan

- [ScriptEngine Overview](README.md) - Tổng quan ScriptEngine
- [State Machine Design](StateMachine_Design.md) - Kiến trúc State Machine chi tiết
- [Script Files](ScriptFiles.md) - Quản lý file script

---

**Last Updated**: 2025-11-13

