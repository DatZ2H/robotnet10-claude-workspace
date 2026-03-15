# Cartographer C/C++ → C# Conversion Guide

##Tổng quan Dự án

### Mục tiêu
Chuyển đổi thư viện Cartographer từ C/C++ sang C# để tạo một class library C# native.

### Thông tin Dự án
- **Nguồn C/C++**: `/home/anhnv/projects/RobotNet10/refs/cartographer`
- **Project C# đích**: `CartographerSharp.csproj`
- **Target Framework**: **.NET 10** (C# 14)
- **Mô tả**: Cartographer là hệ thống SLAM (Simultaneous Localization and Mapping) cung cấp khả năng định vị và lập bản đồ thời gian thực trong 2D và 3D trên nhiều nền tảng và cấu hình cảm biến khác nhau.

### .NET 10 Features Sử dụng
- ✅ **C# 14** - Latest language features
- ✅ **System.Numerics** - SIMD support cho performance
- ✅ **Native AOT** support (nếu cần)
- ✅ **System.Text.Json** - High-performance JSON serialization
- ✅ **Memory<T>**, **Span<T>** - Zero-allocation operations
- ✅ **Async/await** - Modern asynchronous programming
- ✅ **Record types**, **Primary constructors** - Modern C# syntax

### ⚠️ Scope - Core Library Only

**Lưu ý quan trọng**: Dự án này chỉ chuyển đổi **core SLAM library** của Cartographer.

✅ **Có**:
- Common utilities
- Transform operations
- Sensor data processing
- Mapping (2D và 3D)
- IO operations
- Ground Truth tools
- Metrics

❌ **Không có**:
- Cloud services (`cartographer/cloud/`)
- gRPC server
- Distributed/cloud features

### Thống kê Tổng quan

- **43 file .proto** - Protocol Buffer definitions
- **260 file .cc** - Source code C++
- **217 file .h** - Header files C++
- **Tổng cộng**: ~520 files cần phân tích và chuyển đổi

---

##Danh mục các Module cần Chuyển đổi

### 1. **Common** (`cartographer/common/`)
**Mục đích**: Các tiện ích và công cụ dùng chung

**Các thành phần chính:**
- ✅ **Lua Configuration** (`lua_parameter_dictionary.h/cc`)
  - Lua parameter dictionary parser
  - Configuration file resolver
  - → **C#**: JSON Configuration với `System.Text.Json`

- ✅ **Math Utilities** (`math.h`)
  - Các hàm toán học cơ bản (transform, rotation, vector operations)
  - → **C#**: `System.Numerics`

- ✅ **Time** (`time.h/cc`)
  - Timestamp handling, Duration calculations
  - → **C#**: `System.DateTime`, `System.TimeSpan`

- ✅ **Thread Pool** (`thread_pool.h/cc`)
  - Thread pool implementation, Task scheduling
  - → **C#**: `System.Threading.Tasks`, `TaskScheduler`

- ✅ **Fixed Ratio Sampler** (`fixed_ratio_sampler.h/cc`)
  - Sampling utilities

- ✅ **Histogram** (`histogram.h/cc`)
  - Statistical histogram implementation

- ✅ **Blocking Queue** (`internal/blocking_queue.h`)
  - Thread-safe queue

- ✅ **Rate Timer** (`internal/rate_timer.h/cc`)
  - Rate limiting utilities

### 2. **Transform** (`cartographer/transform/`)
**Mục đích**: Xử lý các phép biến đổi tọa độ

**Các thành phần chính:**
- ✅ **Transform Operations** (`transform.h/cc`)
  - 2D/3D transformations, Rotation, translation, scaling, Quaternion operations
  - → **C#**: `System.Numerics` (Matrix4x4, Quaternion, Vector3)

- ✅ **Timestamped Transform** (`timestamped_transform.h/cc`)
  - Transform với timestamp
  - Proto: `proto/timestamped_transform.proto`
  - → **C#**: Class với DateTime/TimeSpan

### 3. **Sensor** (`cartographer/sensor/`)
**Mục đích**: Xử lý dữ liệu cảm biến

**Các thành phần chính:**
- ✅ **Sensor Data Types**
  - Point clouds, Range data, IMU data, Odometry data
  - → **C#**: Custom classes cho các loại sensor data

- ✅ **Adaptive Voxel Filter** (`internal/adaptive_voxel_filter.h/cc`)
  - Point cloud filtering
  - Proto: `proto/adaptive_voxel_filter_options.proto`

- ✅ **Sensor Proto** (`proto/sensor.proto`)
  - Protocol buffer definitions cho sensor data

### 4. **Mapping** (`cartographer/mapping/`)
**Mục đích**: Core SLAM algorithms - **phần quan trọng nhất**

#### 4.1. **Mapping 2D** (`mapping/2d/`)
- ✅ **Submap 2D** - Grid map representation, Probability grid, TSDF
- ✅ **Pose Graph 2D** - Graph-based SLAM optimization, Constraint building
- ✅ **Trajectory Builder 2D** - Local SLAM, Scan matching, Submap insertion

#### 4.2. **Mapping 3D** (`mapping/3d/`)
- ✅ **Submap 3D** - Hybrid grid, 3D map representation
- ✅ **Pose Graph 3D** - 3D optimization, Constraint building in 3D
- ✅ **Trajectory Builder 3D** - 3D local SLAM, 3D scan matching

#### 4.3. **Mapping Common**
- ✅ **Pose Graph** (`internal/pose_graph/`)
  - Graph optimization (sử dụng Ceres Solver)
  - **⚠️ Quan trọng**: Cần thay thế Ceres Solver bằng thư viện C#
- ✅ **Trajectory Builder Options** - Configuration cho trajectory building
- ✅ **Proto files**: `submap.proto`, `pose_graph/*.proto`, `trajectory.proto`, `grid_2d_options.proto`, `hybrid_grid.proto`, `tsdf_2d.proto`, etc.

### 5. **IO** (`cartographer/io/`)
**Mục đích**: Input/Output operations

**Các thành phần chính:**
- ✅ **PBStream** (`io/`) - Protocol buffer stream handling, Map serialization/deserialization
- ✅ **PCD** (`io/internal/`) - Point Cloud Data file I/O
- ✅ **XRay** (`io/`) - Visualization utilities
- ✅ **Image** (`io/`) - Image processing và visualization
  - Submap rendering, Trajectory drawing, X-Ray visualization
  - → **C#**: **SkiaSharp** - Modern 2D graphics library

### 6. **Ground Truth** (`cartographer/ground_truth/`)
**Mục đích**: Ground truth validation

**Các thành phần chính:**
- ✅ **Autogenerate Ground Truth** (`autogenerate_ground_truth.h/cc`)
- ✅ **Relations** (`relations_text_file.h/cc`)
- ✅ **Proto**: `proto/relations.proto`

### 7. **Metrics** (`cartographer/metrics/`)
**Mục đích**: Performance metrics

**Các thành phần chính:**
- ✅ **Counter** (`counter.cc`) - Metrics collection

---

##Dependencies và Phương án Thay thế

### 1. **Google Abseil (absl)** Medium

**C/C++**: Google Abseil C++ libraries
- `absl::memory`, `absl::strings`, `absl::container::flat_hash_map`, `absl::synchronization::mutex`, `absl::types::optional`, etc.

**Thay thế C# - .NET 10 Standard Library:**
- ✅ `System.Collections.Generic.Dictionary<TKey, TValue>` - Thay cho `flat_hash_map`
- ✅ `System.Collections.Generic.HashSet<T>` - Thay cho `flat_hash_set`
- ✅ `System.Threading.Mutex` hoặc `System.Threading.Monitor` - Thay cho `absl::synchronization::mutex`
- ✅ `T?` (C# 14) - Nullable reference types, thay cho `absl::types::optional`
- ✅ `System.DateTime`, `System.TimeSpan` - Thay cho `absl::time`
- ✅ `System.Text.StringBuilder` - String utilities
- ✅ `Memory<T>`, `Span<T>` - Zero-allocation memory utilities (.NET 10 optimized)
- ✅ `System.Linq` - Algorithm utilities với LINQ improvements trong .NET 10

**NuGet Packages**: Không cần - tất cả có trong .NET 10

---

### 2. **Google Glog (glog)** Medium

**C/C++**: Google logging library
- `LOG(INFO)`, `LOG(WARNING)`, `LOG(ERROR)`, `LOG(FATAL)`

**Thay thế C#:**
- ✅ **Microsoft.Extensions.Logging.ILogger** + **NLog**
  - `ILogger` là abstraction interface (dependency injection friendly)
  - NLog là implementation provider với nhiều features

**Ví dụ chuyển đổi:**
```cpp
// C++
LOG(INFO) << "Message: " << value;
LOG(ERROR) << "Error occurred";
```

```csharp
// C#
_logger.LogInformation("Message: {Value}", value);
_logger.LogError("Error occurred");

// Constructor injection
public class SomeClass
{
    private readonly ILogger<SomeClass> _logger;
    
    public SomeClass(ILogger<SomeClass> logger)
    {
        _logger = logger;
    }
}
```

**NuGet Packages (.NET 10):**
- `Microsoft.Extensions.Logging` (built-in với .NET 10)
- `NLog.Extensions.Logging` (NLog provider cho ILogger - latest version for .NET 10)

---

### 3. **Google gflags** Low

**C/C++**: Command-line flag library
- `DEFINE_string`, `DEFINE_int32`, `DEFINE_bool`, etc.

**⚠️ Lưu ý quan trọng**: 
- CartographerSharp là **C# Library**, không phải executable application
- Không cần command-line argument parsing
- Thay vào đó: **Constructor parameters** + **Configuration objects**

**Thay thế C#:**
- ✅ **Constructor Parameters** - Cho các tham số đơn giản, bắt buộc
- ✅ **Configuration Classes** - Cho các tham số phức tạp, có default values
  - Sử dụng strongly-typed configuration classes
  - Load từ JSON configuration

**Ví dụ:**
```csharp
public class MapBuilderOptions
{
    public string InputFile { get; set; } = string.Empty;
    public int Port { get; set; } = 8080;
    public bool Verbose { get; set; } = false;
}

public class MapBuilder
{
    private readonly MapBuilderOptions _options;
    
    public MapBuilder(MapBuilderOptions options)
    {
        _options = options ?? throw new ArgumentNullException(nameof(options));
    }
}

// Sử dụng
var options = new MapBuilderOptions { InputFile = "map.pbstream", Port = 8080 };
var mapBuilder = new MapBuilder(options);
```

**NuGet Packages**: Không cần package đặc biệt

---

### 4. **Ceres Solver** High (Critical - Phức tạp nhất)

**C/C++**: Nonlinear optimization library
- Sử dụng rộng rãi cho: Scan matching (2D và 3D), Pose graph optimization, IMU-based pose extrapolation
- **⚠️ Lưu ý quan trọng**: Cartographer source code (`refs/cartographer`) sử dụng Ceres phiên bản cũ với `LocalParameterization` API
- **CeresSharp sử dụng Ceres 2.2.0** với `Manifold` API (thay thế `LocalParameterization`)

**Thay thế C# - CeresSharp (Đã Implement):**

#### ✅ Phương án Đã Chọn: CeresSharp (P/Invoke Ceres 2.2.0)
- ✅ **Tích hợp native Ceres 2.2.0** qua P/Invoke wrapper
- ✅ **Giữ nguyên thuật toán và kết quả** - 100% tương thích với Ceres C++ API
- ✅ **220+ APIs đã implement** - Đầy đủ cho Cartographer (bao gồm AutoDiffManifold)
- ✅ **Test coverage 99%+** - 100 tests, tất cả pass
- ✅ **Production ready** - Đã fix memory management issues
- ✅ **API tương thích cao** - Dễ dàng convert từ C++ code
- ✅ **AutoDiffManifold đã hoàn thành** - Sẵn sàng cho ConstantYawQuaternion use case
- **Location**: `srcs/RobotNet10/RobotApp/Communication/CeresSharp/`
- **Documentation**: Xem `CeresSharp/README.md` và `CERES_READINESS_EVALUATION.md`

**Migration từ Ceres Cũ lên Ceres 2.2.0:**

| API Cũ (Cartographer) | API Mới (Ceres 2.2.0) | Status |
|----------------------|----------------------|--------|
| `ceres::QuaternionParameterization` ⚠️ **DEPRECATED** | `ceres::QuaternionManifold` | ✅ **Có sẵn** trong CeresSharp |
| `ceres::LocalParameterization` ⚠️ **DEPRECATED** | `ceres::Manifold` | ✅ **Có sẵn** (base class) |
| `ceres::AutoDiffLocalParameterization` ⚠️ **DEPRECATED** | `ceres::AutoDiffManifold` | ✅ **Có sẵn** (callback-based API) |
| `problem.SetParameterization()` ⚠️ **DEPRECATED** | `problem.SetManifold()` | ✅ **Có sẵn** |

**Chi tiết Migration:**
- **QuaternionParameterization → QuaternionManifold**: ✅ **Trực tiếp** - Chỉ cần thay tên class
- **AutoDiffLocalParameterization → AutoDiffManifold**: ✅ **Có sẵn** - Sử dụng callback-based API trong CeresSharp
  - Example: `new AutoDiffManifold(ambientSize, tangentSize, plus, minus)`
  - Sẵn sàng cho ConstantYawQuaternion use case trong Cartographer's IMU extrapolation
- **SetParameterization() → SetManifold()**: ✅ **Trực tiếp** - Chỉ cần thay method name
  - `SetParameterization()` đã bị **DEPRECATED** trong Ceres 2.1.0 và **REMOVED** trong Ceres 2.2.0
- Xem chi tiết trong `CERES_READINESS_EVALUATION.md` phần "Migration từ Ceres Cũ lên Ceres 2.2.0"
- Xem implementation details trong `AUTODIFF_MANIFOLD_IMPLEMENTATION_TASKS.md`

**Các thành phần cần chuyển đổi:**
- `CeresScanMatcher2D` / `CeresScanMatcher3D`
- `OptimizationProblem2D` / `OptimizationProblem3D`
- `CeresPose`
- Cubic interpolation functions

**NuGet Packages**: 
- Không cần - CeresSharp là internal library
- Native library: `libceres_wrapper.so` (Linux only)

---

### 5. **Eigen3** Medium-High

**C/C++**: Linear algebra library
- Vectors, matrices, quaternions, rotations, transforms

**Thay thế C# - Standard Library:**
- ✅ **System.Numerics**
  - `Vector2`, `Vector3`, `Vector4`
  - `Matrix3x2`, `Matrix4x4`
  - `Quaternion`
  - Built-in với .NET, SIMD support
  - Đủ cho hầu hết use cases trong Cartographer

**Ví dụ:**
```csharp
var v = new Vector3(1, 2, 3);
var m = Matrix4x4.Identity;
var q = Quaternion.Identity;
var result = Vector3.Transform(v, m);

// Matrix operations
var rotation = Matrix4x4.CreateRotationX(MathF.PI / 4);
var translation = Matrix4x4.CreateTranslation(new Vector3(10, 20, 30));
var transform = rotation * translation;
```

**NuGet Packages**: `System.Numerics` (built-in với .NET 10 - không cần package)
- .NET 10 có SIMD improvements và vectorization optimizations

---

### 6. **LuaGoogle (Lua)** Medium

**C/C++**: Lua scripting language for configuration
- Configuration files: `.lua` files trong `configuration_files/`
- `LuaParameterDictionary` class

**Thay thế C# - Standard Library:**
- ✅ **JSON Configuration** + **System.Text.Json**
  - Chuyển đổi `.lua` config files sang JSON
  - Sử dụng `System.Text.Json` (built-in với .NET)
  - Tạo strongly-typed configuration classes

**Ví dụ chuyển đổi:**

**Config Lua:**
```lua
TRAJECTORY_BUILDER_2D = {
  max_range = 60.0,
  min_range = 0.5,
  num_accumulated_range_data = 1,
  voxel_filter_size = 0.025,
}
```

**Config JSON:**
```json
{
  "TrajectoryBuilder2D": {
    "MaxRange": 60.0,
    "MinRange": 0.5,
    "NumAccumulatedRangeData": 1,
    "VoxelFilterSize": 0.025
  }
}
```

**C# Class:**
```csharp
public class TrajectoryBuilder2DConfig
{
    [JsonPropertyName("max_range")]
    public double MaxRange { get; set; }
    
    [JsonPropertyName("min_range")]
    public double MinRange { get; set; }
    
    [JsonPropertyName("num_accumulated_range_data")]
    public int NumAccumulatedRangeData { get; set; }
    
    [JsonPropertyName("voxel_filter_size")]
    public double VoxelFilterSize { get; set; }
}

// Loading
var json = File.ReadAllText("config.json");
var config = JsonSerializer.Deserialize<TrajectoryBuilder2DConfig>(json);
```

**NuGet Packages**: `System.Text.Json` (built-in với .NET 10 - không cần package)
- .NET 10 có performance improvements cho JSON serialization
- Source generators cho better performance

---

### 7. **Protocol Buffers (Protobuf)** Medium-High

**C/C++**: Google Protocol Buffers
- 43 `.proto` files trong Cartographer
- Message types và Service definitions

**Thay thế C# - Manual Conversion:**
- ✅ **Chuyển đổi trực tiếp** (không dùng code generation)
  - **Message Proto** → **C# struct/class** với attributes cho serialization
  - **Service Proto** → **C# interface**
  - Sử dụng `System.Text.Json` hoặc `BinaryFormatter` cho serialization

**Ví dụ:**

**Proto Message:**
```protobuf
message Rigid2d {
  double translation_x = 1;
  double translation_y = 2;
  double rotation = 3;
}
```

**C# Struct:**
```csharp
public struct Rigid2d
{
    [JsonPropertyName("translation_x")]
    public double TranslationX { get; set; }
    
    [JsonPropertyName("translation_y")]
    public double TranslationY { get; set; }
    
    [JsonPropertyName("rotation")]
    public double Rotation { get; set; }
}
```

**Lợi ích:**
- ✅ Không phụ thuộc vào Google.Protobuf NuGet package
- ✅ Code C# native, dễ đọc và maintain
- ✅ Full control over serialization format

**NuGet Packages**: `System.Text.Json` (built-in)

---

### 8. **gRPC** ❌ (Không cần cho Core Library)

**Quyết định:**
- ❌ **Không chuyển đổi** - Phần gRPC server và cloud services nằm trong `cartographer/cloud/`
- ✅ **Chỉ chuyển đổi Core Library** - Không bao gồm server/distributed services

**NuGet Packages**: Không cần cho core library

---

### 9. **Boost** Low

**C/C++**: Boost C++ libraries
- I/O streams, Compression (zlib)

**Thay thế C# - Standard Library:**
- ✅ **System.IO.Compression** - `GZipStream`, `DeflateStream`
- ✅ **System.IO** - File I/O, streams

**NuGet Packages**: Không cần - tất cả có trong .NET

---

### 10. **Cairo** Low → **SkiaSharp** ✅

**C/C++**: 2D graphics library
- Image rendering (`io/image.h/cc`)
- Submap painting (`io/submap_painter.h/cc`)
- Trajectory drawing (`io/draw_trajectories.h`)
- X-Ray visualization (`io/xray_points_processor.cc`)

**Thay thế C# - SkiaSharp:**
- ✅ **SkiaSharp** - Modern 2D graphics library cho .NET
  - Cross-platform (Windows, Linux, macOS, iOS, Android)
  - High-performance rendering
  - Tương thích với Google's Skia graphics engine
  - Support ARGB32 format (tương tự Cairo's CAIRO_FORMAT_ARGB32)

**Mục đích sử dụng:**
1. **Image Rendering** - Tạo và xử lý hình ảnh từ map data
2. **Submap Painting** - Vẽ submap slices với transformations
3. **Trajectory Visualization** - Vẽ đường đi của robot
4. **X-Ray Cuts** - Visualization 3D point clouds dưới dạng 2D slices
5. **PNG Export** - Export maps ra file hình ảnh

**Ví dụ chuyển đổi:**

**Cairo (C++):**
```cpp
auto surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, width, height);
auto cr = cairo_create(surface);
cairo_set_source_rgba(cr, r, g, b, a);
cairo_fill(cr);
cairo_surface_write_to_png(surface, "output.png");
```

**SkiaSharp (C#):**
```csharp
using SkiaSharp;

// Tạo surface tương tự Cairo
var info = new SKImageInfo(width, height, SKColorType.Bgra8888, SKAlphaType.Premul);
using var surface = SKSurface.Create(info);
var canvas = surface.Canvas;

// Vẽ
var paint = new SKPaint { Color = new SKColor(r, g, b, a) };
canvas.DrawRect(rect, paint);

// Export PNG
using var image = surface.Snapshot();
using var data = image.Encode(SKEncodedImageFormat.Png, 100);
await File.WriteAllBytesAsync("output.png", data.ToArray());
```

**Lợi ích:**
- ✅ Modern API, dễ sử dụng hơn Cairo
- ✅ Cross-platform native
- ✅ High performance với hardware acceleration
- ✅ Active development và community support

**NuGet Packages**: 
- `SkiaSharp` (latest version compatible with .NET 10)
- `SkiaSharp.NativeAssets.Linux.NoDependencies` (nếu cần Linux support)

---

### 11-14. **Prometheus, ZLIB, pthread, GMock/GTest**

- **Prometheus**: ❌ Không cần cho core library
- **ZLIB**: ✅ `System.IO.Compression` (built-in)
- **pthread**: ✅ `System.Threading` (built-in)
- **GMock/GTest**: ✅ **xUnit** cho testing
  - NuGet: `xunit`, `xunit.runner.visualstudio`, `Moq`

---

##NuGet Packages Summary

### Core Dependencies (Required)
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <!-- Logging -->
    <PackageReference Include="Microsoft.Extensions.Logging" Version="10.0.0" />
    <PackageReference Include="NLog.Extensions.Logging" Version="5.4.0" />
    
    <!-- Graphics - SkiaSharp for visualization -->
    <PackageReference Include="SkiaSharp" Version="2.88.9" />
  </ItemGroup>
</Project>
```

### Optional Dependencies
```xml
  <ItemGroup>
    <!-- Configuration (nếu dùng IConfiguration pattern) -->
    <PackageReference Include="Microsoft.Extensions.Configuration.Json" Version="10.0.0" />

    <!-- Optimization (Ceres) -->
    <!-- ✅ CeresSharp đã implement đầy đủ - Không cần NuGet package -->
    <!-- Native library: libceres_wrapper.so (Linux only) -->

    <!-- Testing -->
    <PackageReference Include="xunit" Version="2.9.0" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.8.2" />
    <PackageReference Include="Moq" Version="4.20.72" />
  </ItemGroup>
```

### Standard Library (Không cần NuGet)
- `System.Collections.Generic` - Collections
- `System.Numerics` - Math operations
- `System.Text.Json` - JSON serialization
- `System.IO`, `System.IO.Compression` - File I/O
- `System.Threading`, `System.Threading.Tasks` - Threading

---

##Cấu trúc Thư mục C# đề xuất

```
CartographerSharp/
├── CartographerSharp.csproj
├── Common/
│   ├── Math/
│   ├── Time/
│   ├── Threading/
│   ├── Configuration/
│   └── Proto/
├── Transform/
│   ├── Transform2D.cs
│   ├── Transform3D.cs
│   └── Proto/
├── Sensor/
│   ├── PointCloud.cs
│   ├── RangeData.cs
│   └── Proto/
├── Mapping/
│   ├── Common/
│   ├── Mapping2D/
│   ├── Mapping3D/
│   ├── PoseGraph/
│   └── Proto/
├── Io/
│   ├── PbStream/
│   ├── Pcd/
│   └── Visualization/
└── GroundTruth/
```

---

##Chiến lược Chuyển đổi

### Phase 1: Foundation Low (Cao nhất)
1. ✅ Common utilities (math, time, thread pool)
2. ✅ Transform operations
3. ✅ Protocol Buffers (tất cả .proto files → structs/interfaces)

### Phase 2: Core Data Structures Low
1. ✅ Sensor data types
2. ✅ Basic mapping structures
3. ✅ Submap representations

### Phase 3: Core Algorithms Medium (Quan trọng nhất)
1. ⚠️ Trajectory builder (2D và 3D)
2. ⚠️ Pose graph optimization (⚠️ Ceres Solver decision needed)
3. ⚠️ Scan matching

### Phase 4: I/O và Utilities Low
1. ✅ IO operations
   - PBStream serialization/deserialization
   - PCD file I/O
   - Image rendering với SkiaSharp
   - X-Ray visualization
2. ✅ Ground truth tools

---

##Priority Matrix

| Dependency | Priority | Complexity | Status |
|------------|----------|------------|--------|
| Google Abseil | Medium | Low | ✅ Standard .NET Libraries |
| Google Glog | Medium | Low | ✅ ILogger + NLog |
| Google gflags | Low | Low | ✅ Constructor/Configuration |
| **Ceres Solver** | High | **Very High** | ⚠️ **Needs decision** |
| Eigen3 | Medium-High | Medium | ✅ System.Numerics (Standard) |
| Lua | Medium | Medium | ✅ JSON + System.Text.Json |
| Protocol Buffers | Medium-High | Medium | ✅ Manual conversion |
| gRPC | ❌ | N/A | ❌ Không chuyển đổi |
| Boost | Low | Low | ✅ System.IO.Compression |
| Cairo | Low | Medium | ✅ SkiaSharp (replacement) |

---

##Các Bước Tiếp theo

1. ✅ Tạo tài liệu conversion guide (đã hoàn thành)
2. [ ] Phân tích chi tiết từng module
3. [ ] Thiết lập project structure C#
4. [ ] Chuyển đổi Protocol Buffers (.proto → C# structs/interfaces)
5. [ ] Chuyển đổi Common utilities
6. [ ] Chuyển đổi Transform operations
7. [ ] Chuyển đổi Sensor data structures
8. [ ] Chuyển đổi Mapping core (2D)
9. [ ] Chuyển đổi Mapping core (3D)
10. [ ] Chuyển đổi IO operations
11. [ ] Testing và validation

---

##Ghi chú Quan trọng

### Cho AI Agent / Developers

1. **Luôn tham chiếu source code C/C++** trong `refs/cartographer/` khi chuyển đổi
2. **Giữ nguyên logic và thuật toán**, chỉ thay đổi syntax và patterns theo C#
3. **Ưu tiên type safety** - sử dụng strong typing của C#
4. **Sử dụng async/await** cho I/O operations
5. **Xem xét memory management** - C# garbage collection vs C++ manual
6. **Test từng module** sau khi chuyển đổi

### Key Decisions

1. **Ceres Solver** - ✅ **Đã quyết định**: Sử dụng **CeresSharp** (P/Invoke Ceres 2.2.0)
   - ✅ **Đã implement đầy đủ** - 220+ APIs (bao gồm AutoDiffManifold), 99%+ test coverage
   - ✅ **100 tests, tất cả pass** - Comprehensive test coverage
   - ✅ **Production ready** - Đã fix memory management issues
   - ✅ **API tương thích cao** - Dễ dàng convert từ C++ code
   - ✅ **AutoDiffManifold đã hoàn thành** - Sẵn sàng cho Cartographer integration
   - ⚠️ **Migration cần thiết**: Từ `LocalParameterization` (Ceres cũ) → `Manifold` (Ceres 2.2.0)
     - ✅ **Tất cả APIs đã có sẵn** - QuaternionManifold, AutoDiffManifold, SetManifold()
   - **Chi tiết**: Xem `CERES_READINESS_EVALUATION.md`, `CERES_USAGE.md`, và `AUTODIFF_MANIFOLD_IMPLEMENTATION_TASKS.md`

2. **Ưu tiên Standard Library** - Trừ Ceres Solver, tất cả dependencies khác nên ưu tiên standard .NET libraries trước khi dùng third-party packages.

3. **Protocol Buffers** - Manual conversion (proto → structs/interfaces) giúp code C# native hơn, không phụ thuộc vào Google.Protobuf package.

4. **Lua Configuration** - Chuyển sang JSON với System.Text.Json (standard library) sẽ đơn giản và type-safe hơn.

5. **Google gflags** - Vì CartographerSharp là Library, không cần command-line parsing. Dùng constructor parameters và configuration objects.

6. **Cairo → SkiaSharp** - Đã quyết định sử dụng SkiaSharp thay cho Cairo cho tất cả visualization tasks. SkiaSharp cung cấp modern API và cross-platform support tốt hơn.

7. **Performance** - SLAM là real-time, cần performance cao. .NET 10 cung cấp:
   - SIMD improvements trong System.Numerics
   - Better vectorization và JIT optimizations
   - Source generators cho JSON serialization
   - Xem xét unsafe code nếu cần performance cực cao

---

##Tài liệu Tham khảo

### Chi tiết Ceres Solver Usage
- **[CERES_USAGE.md](./CERES_USAGE.md)** - Tổng hợp chi tiết tất cả thành phần Ceres được sử dụng trong Cartographer
- **[CERES_READINESS_EVALUATION.md](./CERES_READINESS_EVALUATION.md)** - Đánh giá mức độ sẵn sàng của CeresSharp, bao gồm migration guide từ Ceres cũ lên 2.2.0
- **[AUTODIFF_MANIFOLD_IMPLEMENTATION_TASKS.md](./AUTODIFF_MANIFOLD_IMPLEMENTATION_TASKS.md)** - Chi tiết implementation của AutoDiffManifold (đã hoàn thành)

---

### Cartographer
- [Cartographer Documentation](https://google-cartographer.readthedocs.io/)
- [Google Cartographer GitHub](https://github.com/cartographer-project/cartographer)

### .NET 10 & C# 14
- [.NET 10 Documentation](https://learn.microsoft.com/en-us/dotnet/core/whats-new/dotnet-10)
- [C# 14 Features](https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-14)
- [System.Numerics](https://docs.microsoft.com/en-us/dotnet/api/system.numerics) - SIMD support

### Dependencies
- [Microsoft.Extensions.Logging](https://docs.microsoft.com/en-us/dotnet/core/extensions/logging)
- [NLog Documentation](https://nlog-project.org/)
- [System.Text.Json](https://docs.microsoft.com/en-us/dotnet/standard/serialization/system-text-json-overview)
- [SkiaSharp Documentation](https://learn.microsoft.com/en-us/xamarin/xamarin-forms/user-interface/graphics/skiasharp/)
- [SkiaSharp GitHub](https://github.com/mono/SkiaSharp)

---

**Last Updated**: Generated for Cartographer C# Port  
**Target Framework**: .NET 10 (C# 14)  
**Status**: Planning phase - Conversion guide ready  
**Scope**: Core SLAM library only - excludes `cartographer/cloud/` module  
**Graphics**: SkiaSharp thay cho Cairo cho tất cả visualization tasks
