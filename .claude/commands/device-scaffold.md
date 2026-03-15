---
description: Scaffold a new device following DeviceBase pattern — /device-scaffold [DeviceName]
---

# Device Scaffold

Generate boilerplate for a new device following the RobotNet10 device pattern.

## Parse the argument: $ARGUMENTS

The argument is the device name in PascalCase (e.g., "UltrasonicSensor", "GripperModule").
If no argument provided, ask the user for the device name.

## Pattern to follow

```
DeviceBase (abstract)
  -> DeviceAttribute (metadata)
  -> IDeviceProvider (DI registration)
  -> SignalR Hub (real-time UI updates)
  -> Blazor Component (UI rendering)
```

## Files to generate

For a device named `{Name}`:

### 1. Device class: `RobotApp/Devices/{Name}Device.cs`
```csharp
namespace RobotNet10.RobotApp.Devices;

[Device(DeviceType.{Type}, Brand = "{Brand}", DriverName = "{Name}")]
public class {Name}Device : DeviceBase
{
    // Constructor with DI dependencies
    // Initialize/Dispose lifecycle methods
    // Device-specific properties and methods
}
```

### 2. Device provider: `RobotApp/Devices/{Name}DeviceProvider.cs`
```csharp
namespace RobotNet10.RobotApp.Devices;

public class {Name}DeviceProvider : IDeviceProvider
{
    // CreateDevice, GetDeviceType, etc.
}
```

### 3. SignalR hub: `RobotApp/Hubs/{Name}Hub.cs`
```csharp
namespace RobotNet10.RobotApp.Hubs;

public class {Name}Hub : Hub
{
    // Real-time data methods
    // Status query methods
}
```

### 4. Blazor component: `RobotApp/Components/{Name}Panel.razor`
Basic UI component with hub connection setup.

## Steps

1. Ask user for: device name, DeviceType enum value, Brand, any specific interfaces to implement
2. Search existing devices in `RobotApp/Devices/` to confirm current patterns
3. Generate files with TODO markers where user input is needed for business logic
4. Register the device provider in `Program.cs` DI setup
5. Map the SignalR hub endpoint
6. Report all files created and next steps
