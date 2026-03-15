# Quick Start Guide / Hướng dẫn Bắt đầu Nhanh

> [!NOTE]
> This guide is intended for developers with full RobotNet10 source code access from GitLab.
> The context repo (robotnet10-claude-workspace) contains only docs and .claude/ infrastructure — source code paths (`srcs/`) referenced below require the full repository.

## 5-Minute Overview / Tổng quan 5 phút

### What is RobotNet10?
AMR fleet management system with **RobotApp** (on robots) and **FleetManager** (on server), communicating via **MQTT/VDA 5050**.

### Technology
**.NET 10**, Blazor Web App, MQTT, **SQL Server** (FleetManager), **SQLite** (RobotApp), VDA 5050 v2.1.0, VDMA LIF

### Project Status
**Documentation Phase** - Architecture complete, implementation starting

---

## Quick Start by Role / Bắt đầu Theo Vai trò

### For AI Agents

**1. Read NOW** (15 min):
[AI Collaboration Guide](ai-guide/README.md) - **MANDATORY**

**2. Skim** (10 min):
- [Architecture Overview](architecture/README.md)
- [VDA 5050 Integration](vda5050/README.md)

**3. Start coding** with patterns from AI Guide

**Key points for AI**:
- ✅ Use exact VDA 5050 field names (e.g., `orderId` not `OrderId`)
- ✅ Always async/await for I/O
- ✅ Constructor injection for dependencies
- ✅ Structured logging with parameters
- ✅ Validate all VDA 5050 messages

---

### For Developers

**Step 1: Setup Environment** (30-45 min)

```bash
# Install .NET 10
# Windows: winget install Microsoft.DotNet.SDK.10
# Linux: see Development Guide

# Clone repo
git clone https://github.com/your-org/RobotNet10.git
cd RobotNet10

# Install MQTT broker (Mosquitto)
# Windows: winget install EclipseFoundation.Mosquitto
# Linux: sudo apt install mosquitto

# Install SQL Server (for FleetManager)
# Windows: SQL Server Express or Developer Edition
# Linux: See Microsoft SQL Server on Linux docs

# Note: RobotApp uses SQLite (no installation needed)
```

**Step 2: Read Docs** (30 min)
- [Development Guide](development/README.md) - Full setup
- [Architecture Overview](architecture/README.md) - System design

**Step 3: Choose Component**
- Working on robot? → [RobotApp Docs](robotapp/README.md)
- Working on server? → [FleetManager Docs](fleetmanager/README.md)

**Step 4: Setup ScriptEngine DLLs** (Required for RobotApp)

ScriptEngine cần load các DLL từ thư mục `dlls`. Bạn cần copy các file sau vào thư mục `bin/Debug/net10.0/dlls`:

```bash
# Tạo thư mục dlls nếu chưa có
mkdir -p srcs/RobotApp/bin/Debug/net10.0/dlls

# Copy .NET runtime assemblies
# Thay $DOTNET_VERSION bằng phiên bản .NET 10 của bạn (ví dụ: 10.0.0)
# Windows PowerShell:
$DOTNET_VERSION = (dotnet --version)
Copy-Item "$env:ProgramFiles\dotnet\shared\Microsoft.NETCore.App\$DOTNET_VERSION\System.Private.CoreLib.dll" -Destination "srcs/RobotApp/bin/Debug/net10.0/dlls/"
Copy-Item "$env:ProgramFiles\dotnet\shared\Microsoft.NETCore.App\$DOTNET_VERSION\System.Runtime.dll" -Destination "srcs/RobotApp/bin/Debug/net10.0/dlls/"

# Linux/Mac:
DOTNET_VERSION=$(dotnet --version)
cp "$HOME/.dotnet/shared/Microsoft.NETCore.App/$DOTNET_VERSION/System.Private.CoreLib.dll" srcs/RobotApp/bin/Debug/net10.0/dlls/
cp "$HOME/.dotnet/shared/Microsoft.NETCore.App/$DOTNET_VERSION/System.Runtime.dll" srcs/RobotApp/bin/Debug/net10.0/dlls/

# Copy project DLLs (sau khi build)
cp srcs/RobotNet10/Commons/RobotNet10.Script/bin/Debug/net10.0/RobotNet10.Script.dll srcs/RobotApp/bin/Debug/net10.0/dlls/
cp srcs/RobotNet10/RobotApp/RobotNet10.RobotApp.Script/bin/Debug/net10.0/RobotNet10.RobotApp.Script.dll srcs/RobotApp/bin/Debug/net10.0/dlls/
```

**Lưu ý**: 
- Thư mục `dlls` phải được tạo trong `bin/Debug/net10.0/` sau khi build lần đầu
- Các DLL này cần được copy lại mỗi khi rebuild project
- Có thể tự động hóa bằng build script hoặc post-build event

**Step 5: Start Coding**
```bash
cd srcs/RobotApp
dotnet run
# Access: http://localhost:5000
```

---

### For System Integrators

**1. Understand System** (45 min):
- [Architecture Overview](architecture/README.md)
- [VDA 5050 Integration](vda5050/README.md)

**2. Check Compatibility**:
- Your system supports MQTT? ✅
- Your system supports VDA 5050 v2.1.0? ✅ (Backward compatible with v2.0.0)

**3. Integration Points**:
- **MQTT Broker**: localhost:1883 (or your broker)
- **Topics**: `uagv/v2/{manufacturer}/{serialNumber}/*`
- **QoS**: Order/InstantActions (QoS 1), State/Viz (QoS 0)

**4. Test Integration**:
```bash
# Subscribe to robot states
mosquitto_sub -h localhost -t "uagv/v2/RobotNet10/+/state" -v

# Publish test order
mosquitto_pub -h localhost -t "uagv/v2/RobotNet10/ROBOT001/order" -f order.json
```

---

## Common Tasks / Nhiệm vụ Thường gặp

### Task: Run the System Locally

```bash
# Terminal 1: Start MQTT Broker
mosquitto -v

# Terminal 2: Start FleetManager
cd srcs/FleetManager
dotnet run
# Access: http://localhost:5100

# Terminal 3: Setup ScriptEngine DLLs (Required for RobotApp)
# Xem Step 4 ở trên để biết cách copy DLLs vào bin/Debug/net10.0/dlls/

# Terminal 4: Start RobotApp (simulate robot)
cd srcs/RobotApp
dotnet run
# Access: http://localhost:5000
```

**Important**: RobotApp yêu cầu setup ScriptEngine DLLs trước khi chạy (xem Step 4 ở trên).

### Task: Implement VDA 5050 Order Handler

**1. Check spec**: [VDA 5050 Integration](vda5050/README.md)

**2. Create model** (if not exists):
```csharp
// In Shared/VDA5050/Models/Order.cs
public class Order
{
    [JsonPropertyName("orderId")]
    public string OrderId { get; set; }
    // ... match VDA 5050 exactly
}
```

**3. Create handler**:
```csharp
// In RobotApp/Services/VDA5050/OrderHandler.cs
public class OrderHandler : IOrderHandler
{
    public async Task<bool> HandleOrderAsync(Order order)
    {
        // 1. Validate
        // 2. Process
        // 3. Execute
    }
}
```

**4. Register in DI**:
```csharp
// In Program.cs
builder.Services.AddScoped<IOrderHandler, OrderHandler>();
```

### Task: Add New Database Entity

**1. Create model**:
```csharp
public class Robot
{
    public Guid Id { get; set; }
    public string SerialNumber { get; set; }
    // ...
}
```

**2. Add to DbContext**:
```csharp
public class FleetDbContext : DbContext
{
    public DbSet<Robot> Robots { get; set; }
}
```

**3. Create migration**:
```bash
dotnet ef migrations add AddRobotEntity
dotnet ef database update
```

### Task: Debug MQTT Messages

**1. Monitor all topics**:
```bash
mosquitto_sub -h localhost -t "#" -v
```

**2. Test specific robot**:
```bash
# Subscribe to state
mosquitto_sub -h localhost -t "uagv/v2/RobotNet10/ROBOT001/state" -v

# Publish order
echo '{"orderId":"TEST-001","orderUpdateId":0}' | \
  mosquitto_pub -h localhost -t "uagv/v2/RobotNet10/ROBOT001/order" -l
```

**3. Check logs**:
```csharp
_logger.LogDebug("MQTT message received: Topic={Topic}", topic);
```

---

## Quick Troubleshooting / Xử lý Nhanh

### MQTT Connection Failed
```bash
# Check Mosquitto running
# Windows: sc query mosquitto
# Linux: sudo systemctl status mosquitto

# Test connection
mosquitto_sub -h localhost -t test
```

### Port Already in Use
```bash
# Find and kill process
# Windows: netstat -ano | findstr :5000
# Linux: sudo lsof -i :5000
```

### Database Connection Failed
```bash
# Check SQL Server running (FleetManager)
# Windows: Check SQL Server service
# Linux: sudo systemctl status mssql-server

# Test connection
# Use SQL Server Management Studio or sqlcmd
# sqlcmd -S localhost -U sa -d robotnet10

# For RobotApp SQLite: Check file permissions
```

### Build Errors
```bash
# Clean and rebuild
dotnet clean
dotnet restore
dotnet build
```

---

## Next Steps / Bước Tiếp theo

After quick start:

**For AI Agents**:
1. ✅ Read AI Guide (done)
2. Pick a task from backlog
3. Review relevant docs
4. Implement following patterns
5. Test your code

**For Developers**:
1. ✅ Environment setup (done)
2. Read component docs thoroughly
3. Understand VDA 5050 protocol
4. Start with simple task
5. Review coding standards

**For Integrators**:
1. ✅ System understanding (done)
2. Test MQTT connectivity
3. Validate VDA 5050 messages
4. Integration testing
5. Production deployment

---

## Essential Links / Liên kết Thiết yếu

| Link | Description | Priority |
|------|-------------|----------|
| [Documentation Map](DOCUMENTATION_MAP.md) | Find any documentation | |
| [AI Guide](ai-guide/README.md) | AI agent handbook | (AI) |
| [Development Guide](development/README.md) | Complete dev setup | (Dev) |
| [Architecture](architecture/README.md) | System design | |
| [VDA 5050](vda5050/README.md) | Protocol spec | |

---

## Quick Tips / Mẹo Nhanh

**For Everyone**:
- Use [Documentation Map](DOCUMENTATION_MAP.md) to find docs
- Search across docs when stuck
- Ask questions when unclear
- ✅ Validate VDA 5050 compliance

**For AI**:
- Read AI Guide first (non-negotiable)
- Follow established patterns
- Use async/await everywhere
- Structured logging always

**For Developers**:
- Setup takes 30-45 min (be patient)
- Run MQTT broker first
- Use `dotnet watch` for hot reload
- Check logs when debugging

**For Integrators**:
- Test MQTT connectivity first
- Validate message formats
- Use QoS correctly
- Monitor topics during testing

---

**Ready to start? Choose your role above and follow the guide!**

**Need more details?** → [Documentation Map](DOCUMENTATION_MAP.md)

---

**Last Updated**: 2026-03-15
**Purpose**: Get started in 5-15 minutes
**Version**: 2.1 (Added ScriptEngine DLL setup instructions)
