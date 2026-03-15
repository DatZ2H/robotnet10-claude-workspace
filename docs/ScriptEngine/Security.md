# Security & Limitations / Bảo mật & Giới hạn

##Overview / Tổng quan

ScriptEngine có các giới hạn về security và metadata references để đảm bảo an toàn.

##MetadataReference Restrictions

### Allowed / Được phép

- `System.Runtime`
- `System.Collections`
- `System.Private.CoreLib`
- `RobotNet.Script` (ScriptEngine APIs)
- App-specific DLL

### Forbidden / Không được phép

**Not included** (for security):
- `System.IO` (file system access)
- `System.Net` (network - trừ khi app explicitly add)
- `System.Reflection.Emit`
- `System.Diagnostics.Process`

##Thread Safety / An toàn Luồng

**Current Design**:
- Variables stored in `ConcurrentDictionary` (thread-safe dictionary ops)
- BUT: Complex operations (read-modify-write) NOT atomic

**Recommendation**: User adds manual locking if needed

##Related Documents / Tài liệu Liên quan

- [ScriptEngine Overview](README.md) - Tổng quan ScriptEngine
- [Variables](Variables.md) - Thread-safe variable storage
- [Design Rationale](README.md#design-rationale--lý-do-thiết-kế) - Lý do thiết kế security

---

**Last Updated**: 2025-11-13

