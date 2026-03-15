# CartographerSharp Conversion Tasks - Tiến độ Chuyển đổi

##Tổng quan Tiến độ

**Ngày bắt đầu**: 2024  
**Trạng thái hiện tại**: Phase 7 - Advanced Constraints ✅ **HOÀN THÀNH**
**Tiến độ tổng thể**: Phase 1 ✅, Phase 2 ✅, Phase 3 ✅ (Mapping 2D), CeresSharp Integration ✅, Phase 4 ✅ 100%, Phase 5 ✅ 100% (Mapping 3D), Phase 6 ✅ 100%, Phase 7 ✅ 100%

### Phân bổ theo Module

| Module | Trạng thái | Tiến độ | Ghi chú |
|--------|-----------|---------|---------|
| **Common** | ✅ Hoàn thành | 100% | Math, Time, Threading |
| **Transform** | ✅ Hoàn thành | 100% | Rigid2/3, TransformOperations |
| **Protocol Buffers** | ✅ Hoàn thành | 100% | Tất cả proto files cơ bản đã convert |
| **Sensor** | ✅ Hoàn thành | 100% | Tất cả sensor data processing đã hoàn thành |
| **Mapping** | ✅ Hoàn thành | 100% | **Chi tiết:**<br/>✅ Common (IDs, ProbabilityValues, ValueConversionTables, Submap base, MapById, TrajectoryNode) - 100%<br/>✅ 2D Core (CellLimits, MapLimits, XYIndex, Grid2D, ProbabilityGrid, Submap2D) - 100%<br/>✅ Range Data Inserter 2D (RayToPixelMask, ProbabilityGridRangeDataInserter2D) - 100%<br/>✅ Pose Graph (Interface, Base, 2D implementation với đầy đủ methods) - 100%<br/>✅ Trajectory Builder (Interface, MotionFilter, RangeDataCollator, ActiveSubmaps2D) - 100%<br/>✅ Scan Matching (Correlative, Real-time Correlative, Ceres với CeresSharp integration) - 100%<br/>✅ Local Trajectory Builder 2D (PoseExtrapolator, scan matching integration, range data accumulation) - 100%<br/>✅ Optimization & Constraints (OptimizationProblem2D với CeresSharp, SpaCostFunction2D, ConstraintBuilder2D) - 100%<br/>✅ Map Builder (Interface và implementation với trajectory management) - 100%<br/>✅ 3D Core (HybridGrid ✅, Submap3D ✅, RangeDataInserter3D ✅, ActiveSubmaps3D ✅) - 100%<br/>✅ 3D Pose Graph (PoseGraph3D ✅, OptimizationProblem3D ✅, SpaCostFunction3D ✅) - 100%<br/>✅ 3D Trajectory Builder (LocalTrajectoryBuilder3D ✅, ConstraintBuilder3D ✅, TrajectoryBuilder3DAdapter ✅) - 100%<br/>✅ 3D Scan Matching (CeresScanMatcher3D ✅, RealTimeCorrelativeScanMatcher3D ✅, tất cả cost functions ✅) - 100%<br/>**Lưu ý:** Mapping 3D đã hoàn thành 100% trong Phase 5. Tất cả components đã được implement đầy đủ. |
| **IO** | ✅ Hoàn thành | 100% | **Chi tiết:**<br/>✅ ProtoStreamWriter/Reader Interfaces - 100%<br/>✅ ProtoStreamWriter/Reader Implementations - 100%<br/>✅ MappingStateSerialization - 100%<br/>✅ SerializationProto structs - 100%<br/>✅ MapBuilder.SerializeState/SerializeStateToFile - 100%<br/>✅ ProtoStreamDeserializer - 100%<br/>✅ MapBuilder.LoadState/LoadStateFromFile - 100%<br/>✅ Deserialization logic cho pose graph, submaps, nodes, trajectory data - 100% |
| **Ground Truth** | ✅ Hoàn thành | 100% | RelationsProto, RelationsTextFile, AutogenerateGroundTruth, ComputeRelationsMetrics |
| **Metrics** | ✅ Hoàn thành | 100% | Counter, Gauge, Histogram, FamilyFactory, Register |
| **Advanced Constraints** | ✅ Hoàn thành | 100% | Landmark constraints (2D & 3D), Odometry constraints, Fixed frame pose constraints |

---

## Phase 1: Foundation (Cao nhất)

### ✅ Common Utilities

#### 1. Math Utilities (`Common/Math/MathUtils.cs`)
- [x] `Clamp<T>` - Generic clamp function
- [x] `Power<T>` - Generic power function
- [x] `Pow2<T>` - Square function
- [x] `DegToRad` - Degree to radian conversion
- [x] `RadToDeg` - Radian to degree conversion
- [x] `NormalizeAngleDifference<T>` - Angle normalization
- [x] `Atan2` - Atan2 for Vector2
- [x] `QuaternionProduct` - Quaternion multiplication

**Ghi chú**: 
- Sử dụng `System.Math` thay vì `Math` để tránh conflict với namespace `CartographerSharp.Common.Math`
- Sử dụng generic constraints để hỗ trợ nhiều kiểu số

#### 2. Time Utilities (`Common/Time/TimeUtils.cs`)
- [x] Universal Time Scale constants
- [x] `FromSeconds` / `ToSeconds` - Time conversion
- [x] `FromMilliseconds` / `ToMilliseconds` - Time conversion
- [x] `FromUniversal` / `ToUniversal` - Universal time conversion
- [x] `GetThreadCpuTimeSeconds` - Linux `clock_gettime` P/Invoke

**Ghi chú**:
- Sử dụng `DllImport` cho `libc` để gọi `clock_gettime` trên Linux
- Constants: `UtsEpochOffsetFromUnixEpochInSeconds`, `TicksPerSecond`

#### 3. Threading (`Common/Threading/`)
- [x] `Task.cs` - Task implementation với dependency management
  - [x] Task states (New, Dispatched, DependenciesCompleted, Running, Completed)
  - [x] Dependency tracking
  - [x] Thread-safe state management
  - [x] `SetWorkItem`, `AddDependency`, `Execute`
  
- [x] `ThreadPool.cs` - Thread pool implementation
  - [x] `ThreadPoolInterface` - Abstract base class
  - [x] `ThreadPool` - Concrete implementation
  - [x] Worker threads management
  - [x] Task queue với `ConcurrentQueue`
  - [x] Linux `nice` system call P/Invoke

**Ghi chú**:
- Sử dụng `ConcurrentQueue<Task>` cho thread-safe task queue
- `NotifyDependenciesCompleted` được đổi từ `protected` sang `internal` để cho phép `Task` gọi
- Sử dụng `DllImport` cho `libc` để gọi `nice` trên Linux

### ✅ Transform Operations

#### 1. Rigid2D Transform (`Transform/Rigid2.cs`)
- [x] `Rigid2d` struct (double precision)
  - [x] Identity transformation
  - [x] Constructors (translation + rotation)
  - [x] Static factory methods: `FromRotation`, `FromTranslation`
  - [x] Properties: `Translation`, `Rotation`
  - [x] `NormalizedAngle()` - Angle normalization
  - [x] `Inverse()` - Inverse transformation
  - [x] `TransformPoint()` - Point transformation
  - [x] Operator overloads: `*` (composition, point transform)

- [x] `Rigid2f` struct (single precision)
  - [x] Tương tự `Rigid2d` nhưng với `float`

**Ghi chú**:
- Sử dụng `System.Numerics.Vector2` cho translation
- Rotation là angle (radians) cho 2D
- Đổi tên static methods từ `Translation()`/`Rotation()` thành `FromTranslation()`/`FromRotation()` để tránh conflict với properties

#### 2. Rigid3D Transform (`Transform/Rigid3.cs`)
- [x] `Rigid3d` struct (double precision)
  - [x] Identity transformation
  - [x] Constructors (translation + rotation)
  - [x] Static factory methods: `FromRotation`, `FromTranslation`
  - [x] Properties: `Translation`, `Rotation`
  - [x] `Inverse()` - Inverse transformation
  - [x] `TransformPoint()` - Point transformation
  - [x] `IsValid()` - Validation check
  - [x] Operator overloads: `*` (composition, point transform)

- [x] `Rigid3f` struct (single precision)
  - [x] Tương tự `Rigid3d` nhưng với `float`

- [x] `QuaternionUtils` class
  - [x] `RollPitchYaw()` - Convert Euler angles to quaternion

**Ghi chú**:
- Sử dụng `System.Numerics.Vector3` cho translation
- Sử dụng `System.Numerics.Quaternion` cho rotation
- Quaternion được normalize trong constructor

#### 3. Transform Operations (`Transform/TransformOperations.cs`)
- [x] `GetAngle` - Get angle from quaternion
- [x] `GetYaw` - Get yaw from quaternion/Rigid3d
- [x] `RotationQuaternionToAngleAxisVector` - Quaternion to angle-axis
- [x] `AngleAxisVectorToRotationQuaternion` - Angle-axis to quaternion
- [x] `Project2D` - Project 3D transform to 2D
- [x] `Embed3D` - Embed 2D transform to 3D

### Protocol Buffers

#### ✅ Transform Proto (`Proto/Transform/`)
- [x] `TransformProto.cs`
  - [x] `Vector2d`, `Vector2f` - 2D vectors
  - [x] `Vector3d`, `Vector3f` - 3D vectors
  - [x] `Vector4f` - 4D vector
  - [x] `Quaterniond`, `Quaternionf` - Quaternions
  - [x] `Rigid2dProto`, `Rigid2fProto` - 2D rigid transforms
  - [x] `Rigid3dProto`, `Rigid3fProto` - 3D rigid transforms
  - [x] Implicit operators cho conversion với `System.Numerics` types
  - [x] `System.Text.Json.Serialization` attributes

- [x] `TimestampedTransformProto.cs`
  - [x] `TimestampedTransform` struct
  - [x] `FromDateTime` / `ToDateTime` helpers
  - [x] Integration với `TimeUtils`

#### ✅ Common Proto (`Proto/Common/`)
- [x] `ceres_solver_options.proto` → `CeresSolverOptionsProto.cs`
  - [x] `CeresSolverOptions` struct với UseNonmonotonicSteps, MaxNumIterations, NumThreads

#### ✅ Sensor Proto (`Proto/Sensor/`)
- [x] `sensor.proto` → `SensorProto.cs`
  - [x] `RangefinderPoint`, `TimedRangefinderPoint`
  - [x] `CompressedPointCloud`
  - [x] `TimedPointCloudData`
  - [x] `RangeData`
  - [x] `ImuData`, `OdometryData`, `FixedFramePoseData`
  - [x] `LandmarkData` với nested `LandmarkObservation`
- [x] `adaptive_voxel_filter_options.proto` → `AdaptiveVoxelFilterOptionsProto.cs`
  - [x] `AdaptiveVoxelFilterOptions` struct

#### ✅ Mapping Proto (`Proto/Mapping/`) - Core Files
- [x] `motion_filter_options.proto` → `MotionFilterOptionsProto.cs`
- [x] `hybrid_grid.proto` → `HybridGridProto.cs`
- [x] `trajectory.proto` → `TrajectoryProto.cs`
  - [x] `Trajectory` với nested `Node` và `Submap`
- [x] `pose_graph.proto` → `PoseGraphProto.cs`
  - [x] `PoseGraph` với `SubmapId`, `NodeId`, `Constraint`, `LandmarkPose`
- [x] `submap.proto` → `SubmapProto.cs`
  - [x] `Submap2D`, `Submap3D`
- [x] `trajectory_builder_options.proto` → `TrajectoryBuilderOptionsProto.cs`
  - [x] `InitialTrajectoryPose`, `TrajectoryBuilderOptions`
  - [x] `SensorId`, `TrajectoryBuilderOptionsWithSensorIds`, `AllTrajectoryBuilderOptions`
- [x] Supporting proto files:
  - [x] `cell_limits_2d.proto` → `CellLimits2DProto.cs`
  - [x] `map_limits.proto` → `MapLimitsProto.cs`
  - [x] `probability_grid.proto` → `ProbabilityGridProto.cs`
  - [x] `tsdf_2d.proto` → `TSDF2DProto.cs`
  - [x] `grid_2d.proto` → `Grid2DProto.cs`

**Ghi chú**: Một số proto files phức tạp hơn (như `local_trajectory_builder_options_2d/3d`) sẽ được implement trong các phase sau.

---

##Vấn đề đã gặp và Giải pháp

### 1. Lỗi CS0102: Duplicate Definition
**Vấn đề**: Compiler báo lỗi duplicate definition cho `Translation` và `Rotation` properties trong `Rigid2d`, `Rigid2f`, `Rigid3d`, `Rigid3f`.

**Nguyên nhân**: Static methods `Translation()` và `Rotation()` trùng tên với properties `Translation` và `Rotation`, gây conflict trong compiler.

**Giải pháp**: Đổi tên static factory methods:
- `Translation()` → `FromTranslation()`
- `Rotation()` → `FromRotation()`

**Files đã sửa**:
- `Transform/Rigid2.cs`
- `Transform/Rigid3.cs`

### 2. Lỗi CS0234: Namespace Conflict với Math
**Vấn đề**: Compiler không tìm thấy `Math.PI` và `Math.Atan2` trong `MathUtils.cs`.

**Nguyên nhân**: Namespace `CartographerSharp.Common.Math` conflict với `System.Math`.

**Giải pháp**: Sử dụng fully qualified name `System.Math.PI` và `System.Math.Atan2`.

**Files đã sửa**:
- `Common/Math/MathUtils.cs`

### 3. Lỗi CS0122: Inaccessible Method
**Vấn đề**: `Task.cs` không thể gọi `NotifyDependenciesCompleted` vì method là `protected`.

**Nguyên nhân**: `NotifyDependenciesCompleted` được định nghĩa là `protected abstract` trong `ThreadPoolInterface`, nhưng `Task` cần gọi từ bên ngoài class hierarchy.

**Giải pháp**: Đổi access modifier từ `protected` sang `internal`:
- `ThreadPoolInterface.NotifyDependenciesCompleted` → `internal abstract`
- `ThreadPool.NotifyDependenciesCompleted` → `internal override`

**Files đã sửa**:
- `Common/Threading/ThreadPool.cs`

### 4. Lỗi CS1061/CS1503: Nullable Struct Handling trong ProtoStreamDeserializer
**Vấn đề**: Compiler báo lỗi `'SerializedData' does not contain a definition for 'HasValue'` và `cannot convert from 'out SerializedData?' to 'out SerializedData'` khi xử lý nullable structs.

**Nguyên nhân**: Khi sử dụng `out var` với generic method `ReadProto<T>(out T? proto)`, compiler không tự động infer nullable struct type (`SerializedData?`) cho struct types.

**Giải pháp**: Sử dụng `ReadNextSerializedData()` method pattern thay vì gọi `ReadProto` trực tiếp trong constructor, vì `ReadNextSerializedData` có explicit `out SerializedData?` parameter type.

**Files đã sửa**:
- `IO/ProtoStreamDeserializer.cs`

### 5. Lỗi CS0117: Naming Conflict giữa PoseGraph Class và Proto Struct
**Vấn đề**: Compiler không thể resolve `PoseGraph.FromProto()` vì có naming conflict giữa `CartographerSharp.Mapping.PoseGraph` (class) và `CartographerSharp.Proto.Mapping.PoseGraph` (struct).

**Nguyên nhân**: `using CartographerSharp.Proto.Mapping;` statement gây conflict khi reference `PoseGraph` trong cùng namespace.

**Giải pháp**: Sử dụng reflection để gọi static method `FromProto` từ `CartographerSharp.Mapping.PoseGraph` class để tránh naming conflict.

**Files đã sửa**:
- `Mapping/MapBuilder.cs`

---

##Cấu trúc Files đã tạo

```
CartographerSharp/
├── Common/
│   ├── Math/
│   │   ├── MathUtils.cs ✅
│   │   ├── Array2i.cs ✅
│   │   └── Array3i.cs ✅ (Phase 5)
│   ├── Time/
│   │   └── TimeUtils.cs ✅
│   └── Threading/
│       ├── Task.cs ✅
│       └── ThreadPool.cs ✅
├── Transform/
│   ├── Rigid2.cs ✅
│   ├── Rigid3.cs ✅
│   └── TransformOperations.cs ✅
├── Mapping/
│   ├── 2D/
│   │   ├── ActiveSubmaps2D.cs ✅
│   │   ├── CellLimits.cs ✅
│   │   ├── Grid2D.cs ✅
│   │   ├── MapLimits.cs ✅
│   │   ├── ProbabilityGrid.cs ✅
│   │   ├── ProbabilityGridRangeDataInserter2D.cs ✅
│   │   ├── Submap2D.cs ✅
│   │   └── XYIndex.cs ✅
│   ├── 3D/ (Phase 5)
│   │   ├── ActiveSubmaps3D.cs ✅
│   │   ├── HybridGrid.cs ✅
│   │   ├── RangeDataInserter3D.cs ✅
│   │   └── Submap3D.cs ✅
│   ├── Internal/
│   │   ├── 2D/
│   │   │   ├── LocalTrajectoryBuilder2D.cs ✅
│   │   │   ├── PoseGraph2D.cs ✅
│   │   │   ├── RayToPixelMask.cs ✅
│   │   │   ├── ScanMatching/
│   │   │   │   ├── CeresScanMatcher2D.cs ✅
│   │   │   │   ├── CorrelativeScanMatcher2D.cs ✅
│   │   │   │   ├── OccupiedSpaceCostFunction2D.cs ✅
│   │   │   │   ├── ProbabilityGridAdapter.cs ✅
│   │   │   │   ├── RealTimeCorrelativeScanMatcher2D.cs ✅
│   │   │   │   ├── RotationDeltaCostFunctor2D.cs ✅
│   │   │   │   └── TranslationDeltaCostFunctor2D.cs ✅
│   │   │   └── TrajectoryBuilder2DAdapter.cs ✅
│   │   ├── Constraints/
│   │   │   └── ConstraintBuilder2D.cs ✅
│   │   ├── MotionFilter.cs ✅
│   │   ├── Optimization/
│   │   │   ├── OptimizationProblem2D.cs ✅
│   │   │   └── SpaCostFunction2D.cs ✅
│   │   └── RangeDataCollator.cs ✅
│   ├── Id.cs ✅
│   ├── MapBuilder.cs ✅
│   ├── MapBuilderInterface.cs ✅
│   ├── MapById.cs ✅
│   ├── PoseExtrapolator.cs ✅
│   ├── PoseExtrapolatorInterface.cs ✅
│   ├── PoseGraph.cs ✅
│   ├── PoseGraphInterface.cs ✅
│   ├── ProbabilityValues.cs ✅
│   ├── RangeDataInserterInterface.cs ✅
│   ├── Submap.cs ✅
│   ├── TrajectoryBuilderInterface.cs ✅
│   ├── TrajectoryNode.cs ✅
│   └── ValueConversionTables.cs ✅
├── IO/
│   ├── IProtoStreamReader.cs ✅
│   ├── IProtoStreamWriter.cs ✅
│   ├── MappingStateSerialization.cs ✅
│   ├── ProtoStreamDeserializer.cs ✅
│   ├── ProtoStreamReader.cs ✅
│   ├── ProtoStreamWriter.cs ✅
│   └── SerializationProto.cs ✅
└── Proto/
    ├── Common/
    │   └── CeresSolverOptionsProto.cs ✅
    ├── Mapping/
    │   ├── HybridGridProto.cs ✅
    │   ├── SubmapProto.cs ✅ (có Submap2D và Submap3D)
    │   └── ... (nhiều proto files khác)
    ├── Sensor/
    │   └── SensorProto.cs ✅
    └── Transform/
        ├── TransformProto.cs ✅
        └── TimestampedTransformProto.cs ✅
```

---

##Các bước tiếp theo

### ✅ Phase 1 - Foundation (HOÀN THÀNH)
1. [x] Convert Common proto files (`ceres_solver_options.proto`)
2. [x] Convert Sensor proto files (`sensor.proto`, `adaptive_voxel_filter_options.proto`)
3. [x] Convert Mapping proto files (core proto files đã hoàn thành)

### ✅ Phase 2 - Sensor Data Processing (HOÀN THÀNH)
1. [x] Sensor data structures
   - [x] `RangefinderPoint`, `TimedRangefinderPoint`
   - [x] `PointCloud`, `TimedPointCloud`
   - [x] `RangeData`
   - [x] `TimedPointCloudData`
   - [x] `ImuData`, `OdometryData`, `FixedFramePoseData`, `LandmarkData`
2. [x] Point cloud processing
   - [x] `PointCloudOperations.Transform` (PointCloud, TimedPointCloud)
   - [x] `PointCloudOperations.Crop`
   - [x] `RangeDataOperations.Transform`, `RangeDataOperations.Crop`
3. [x] Voxel filter
   - [x] `VoxelFilter.Filter` - Randomized voxel filtering với reservoir sampling
   - [x] Support cho `List<RangefinderPoint>`, `PointCloud`, `TimedPointCloud`, `RangeMeasurement`
4. [x] Adaptive voxel filter
   - [x] `AdaptiveVoxelFilter.Filter` - Binary search để tìm resolution phù hợp
   - [x] Max range filtering
5. [x] Compressed point cloud
   - [x] `CompressedPointCloud` class với block-based encoding
   - [x] `Decompress()` method
   - [x] `ToProto()` / constructor from proto

### ✅ Phase 3 - Mapping Core (HOÀN THÀNH)
1. [x] Mapping Common
   - [x] `Id.cs` - NodeId, SubmapId structs với operators và IIdType interface
   - [x] `ProbabilityValues.cs` - Probability/correspondence cost conversions
   - [x] `ValueConversionTables.cs` - Lazy lookup table computation
   - [x] `Submap.cs` - Abstract base class cho submaps
   - [x] `RangeDataInserterInterface.cs` - Interface cho range data insertion
   - [x] `MapById.cs` - Generic container cho ID-based data storage (tương đương C++ template)
   - [x] `TrajectoryNode.cs` - TrajectoryNode và TrajectoryNodePose structs
   - [x] `TrajectoryNodeDataProto.cs` - Proto cho trajectory node data
2. [x] Mapping 2D - Core Components
   - [x] `CellLimits.cs` - Cell limits struct
   - [x] `MapLimits.cs` - Map limits class với cell indexing
   - [x] `XYIndex.cs` - XY index range iterator
   - [x] `Grid2D.cs` - Base class cho 2D grids
   - [x] `ProbabilityGrid.cs` - Probability grid implementation
   - [x] `Submap2D.cs` - 2D Submap với grid management
3. [x] Mapping 2D - Range Data Inserter ✅
   - [x] `RayToPixelMask.cs` - Ray casting utility với subpixel accuracy
   - [x] `ProbabilityGridRangeDataInserter2D.cs` - Range data insertion vào probability grid
   - [x] `ProbabilityGridRangeDataInserterOptions2DProto.cs` - Proto cho inserter options
4. [x] Mapping 2D - Pose Graph ✅
   - [x] `PoseGraphInterface.cs` - Interface với Constraint, LandmarkNode, SubmapPose, SubmapData, TrajectoryData structs
   - [x] `PoseGraph.cs` - Base class với InitialTrajectoryPose, PoseGraphTrimmer, Trimmable interface
   - [x] `PoseGraph2D.cs` - Skeleton implementation cho 2D pose graph
   - [x] `PoseGraphOptionsProto.cs` - Proto cho pose graph options
   - [x] `TrajectoryDataProto.cs` - Proto cho trajectory data
   - [x] `SerializationProto.cs` - Node proto struct
   - [x] `ConstraintOperations.cs` - Conversion utilities cho constraints
5. [x] Mapping 2D - Trajectory Builder Infrastructure ✅
   - [x] `TrajectoryBuilderInterface.cs` - Interface với InsertionResult, SensorId, LocalSlamResultCallback
   - [x] `MotionFilter.cs` - Motion filtering để giảm số lượng poses
   - [x] `RangeDataCollator.cs` - Synchronize TimedPointCloudData từ nhiều sensors
   - [x] `ActiveSubmaps2D.cs` - Quản lý active submaps (2 submaps: old và new)
   - [x] `MotionFilterOptionsProto.cs` - Proto cho motion filter options
   - [x] `SubmapsOptions2DProto.cs` - Proto cho submaps options
   - [x] `GridOptions2DProto.cs` - Proto cho grid options
   - [x] `RangeDataInserterOptionsProto.cs` - Proto cho range data inserter options
6. [x] Mapping 2D - Scan Matching ✅
   - [x] `CorrelativeScanMatcher2D.cs` - SearchParameters, Candidate2D, DiscreteScan2D, GenerateRotatedScans, DiscretizeScans
   - [x] `RealTimeCorrelativeScanMatcher2D.cs` - Real-time correlative scan matching implementation
   - [x] `CeresScanMatcher2D.cs` - Complete implementation với CeresSharp integration
   - [x] `RealTimeCorrelativeScanMatcherOptionsProto.cs` - Proto cho scan matcher options
   - [x] `CeresScanMatcherOptions2DProto.cs` - Proto cho Ceres scan matcher options
7. [x] Mapping 2D - Local Trajectory Builder ✅
   - [x] `LocalTrajectoryBuilder2D.cs` - Local SLAM stack với pose extrapolator, scan matching, submap insertion
   - [x] `PoseExtrapolatorInterface.cs` - Interface cho pose extrapolation
   - [x] `PoseExtrapolator.cs` - Implementation với velocity estimation từ poses
   - [x] `LocalTrajectoryBuilderOptions2DProto.cs` - Proto cho local trajectory builder options
   - [x] `PoseExtrapolatorOptionsProto.cs` - Proto cho pose extrapolator options
8. [x] Mapping 2D - Optimization & Constraints ✅
   - [x] `OptimizationProblem2D.cs` - Complete implementation với CeresSharp integration (Solve method, parameter blocks, constraints, frozen trajectories)
   - [x] `SpaCostFunction2D.cs` - SPA cost function cho pose graph optimization với AutoDiffCostFunction
   - [x] `ConstraintBuilder2D.cs` - Complete implementation với scan matching integration (MaybeAddConstraint, MaybeAddGlobalConstraint, RealTimeCorrelativeScanMatcher2D, CeresScanMatcher2D)
   - [x] `OptimizationProblemOptionsProto.cs` - Proto cho optimization problem options
   - [x] `ConstraintBuilderOptionsProto.cs` - Proto cho constraint builder options
5. [x] Mapping Common - Advanced ✅
   - [x] `PoseGraphInterface.cs` - Complete interface với tất cả structs và methods (100%)
   - [x] `TrajectoryBuilderInterface.cs` - Complete interface với InsertionResult, SensorId, LocalSlamResultCallback (100%)
   - [x] `MapBuilderInterface.cs` - Interface cho complete SLAM stack wiring (100%)
   - [x] `MapBuilder.cs` - Implementation với trajectory builder management, pose graph integration (100%)
   - [x] `MapBuilderOptionsProto.cs` - Proto cho map builder options (100%)
   - [x] `SubmapQueryProto.cs` - Proto cho submap query response (100%)
   - [x] `TrajectoryBuilder2DAdapter.cs` - Adapter để LocalTrajectoryBuilder2D implement TrajectoryBuilderInterface (100%)

### ✅ Phase 4 - IO Operations (HOÀN THÀNH)
1. [x] IO Interfaces
   - [x] `ProtoStreamWriterInterface.cs` - Interface cho proto stream writer
   - [x] `ProtoStreamReaderInterface.cs` - Interface cho proto stream reader
2. [x] IO Implementations
   - [x] `ProtoStreamWriter.cs` - File writer với GZip compression, magic number, little-endian size encoding
   - [x] `ProtoStreamReader.cs` - File reader với GZip decompression, magic number validation
3. [x] Serialization Logic
   - [x] `MappingStateSerialization.cs` - Serialization logic cho mapping state (header, pose graph, trajectory options, submaps, nodes, trajectory data)
   - [x] `SerializationProto.cs` - SerializedData struct với SerializationHeader, Submap, Node, SerializedImuData, SerializedOdometryData, SerializedFixedFramePoseData, SerializedLandmarkData, SerializedTrajectoryData
4. [x] MapBuilder Integration
   - [x] `SerializeState()` - Complete với IProtoStreamWriter integration
   - [x] `SerializeStateToFile()` - Complete với file operations
   - [x] `LoadState()` - Complete với deserialization logic, trajectory remapping, submaps, nodes, trajectory data
   - [x] `LoadStateFromFile()` - Complete với file operations
5. [x] Deserialization Logic (HOÀN THÀNH)
   - [x] `ProtoStreamDeserializer.cs` - Complete class với header reading, version validation, pose graph và trajectory options reading
   - [x] Deserialize pose graph, submaps, nodes, trajectory data - Complete trong LoadState()
   - [x] Handle format version migration - Complete với version validation (format version 1 và 2)
   - [x] Trajectory ID remapping - Complete trong LoadState() với dictionary mapping old → new trajectory IDs
   - [x] Support cho frozen state loading - Complete với proper constraint và node-to-submap relationship handling
   - [x] Deserialization của IMU, odometry, fixed frame pose, và landmark data - Complete với proper trajectory remapping

### ✅ Phase 5 - Mapping 3D (HOÀN THÀNH)
1. [x] Common Utilities cho 3D
   - [x] `Array3i.cs` - 3D integer array struct (equivalent to Eigen::Array3i) với operators và methods
   - [x] `FixedRatioSampler.cs` - Utility class cho fixed-ratio sampling
2. [x] HybridGrid Implementation (100% complete)
   - [x] `HybridGridUtils` - Utility functions cho indexing (ToFlatIndex, To3DIndex, IsDefaultValue)
   - [x] `FlatGrid<TValueType>` - Flat grid với 8x8x8 voxels (kBits=3), iterator support
   - [x] `NestedGrid<TValueType>` - Nested grid với wrapped FlatGrids (8x8x8 meta cells, each containing 8x8x8 FlatGrid)
   - [x] `DynamicGrid<TValueType>` - Dynamic grid với grow functionality (supports negative indices, grows 2x per dimension, max bits=8)
   - [x] `HybridGridBase<TValueType>` - Base class với resolution và cell indexing (GetCellIndex, GetCenterOfCell, GetOctant, GetEnumerator)
   - [x] `HybridGrid` - Main class với probability values (ushort), SetProbability, GetProbability, ApplyLookupTable, FinishUpdate, ToProto, constructor from proto
   - [x] `IntensityHybridGrid` - Hybrid grid cho intensity data với AverageIntensityData (AddIntensity, GetIntensity)
3. [x] Submap3D (100% complete)
   - [x] `Submap3D.cs` - 3D submap với high/low resolution hybrid grids, intensity grid, rotational histogram
   - [x] `RangeDataInserter3D.cs` - Range data insertion vào hybrid grids với hit/miss tables, ray casting, intensity insertion
   - [x] `ActiveSubmaps3D.cs` - Active submaps management cho 3D với automatic finishing và memory management
4. [x] Pose Graph 3D (100% complete)
   - [x] `PoseGraph3D.cs` - 3D pose graph implementation với đầy đủ methods
   - [x] `OptimizationProblem3D.cs` - 3D optimization problem với CeresSharp integration
   - [x] `SpaCostFunction3D.cs` - 3D SPA cost function cho pose graph optimization
5. [x] Trajectory Builder 3D (100% complete)
   - [x] `LocalTrajectoryBuilder3D.cs` - Local SLAM stack cho 3D với pose extrapolator, scan matching, submap insertion
   - [x] `CeresScanMatcher3D.cs` - 3D Ceres scan matcher với đầy đủ cost functions (OccupiedSpaceCostFunction3D, IntensityCostFunction3D, TranslationDeltaCostFunctor3D, RotationDeltaCostFunctor3D)
   - [x] `RealTimeCorrelativeScanMatcher3D.cs` - 3D real-time correlative scan matcher với full branch-and-bound algorithm
   - [x] `ConstraintBuilder3D.cs` - Constraint builder cho 3D
   - [x] `TrajectoryBuilder3DAdapter.cs` - Adapter để LocalTrajectoryBuilder3D implement TrajectoryBuilderInterface
6. [x] Scan Matching 3D Components (100% complete)
   - [x] `InterpolatedGrid.cs` - InterpolatedProbabilityGrid và InterpolatedIntensityGrid với tricubic interpolation
   - [x] `OccupiedSpaceCostFunction3D.cs` - Cost function cho occupied space matching
   - [x] `IntensityCostFunction3D.cs` - Cost function cho intensity matching
   - [x] `TranslationDeltaCostFunctor3D.cs` - Cost functor cho translation delta
   - [x] `RotationDeltaCostFunctor3D.cs` - Cost functor cho rotation delta
   - [x] `PrecomputationGrid3D.cs` - Precomputation grid cho branch-and-bound (8-bit values)
   - [x] `PrecomputationGridStack3D.cs` - Stack of precomputation grids với multiple depths
   - [x] `RotationalScanMatcher.cs` - Rotational scan matcher với histogram matching
7. [x] MapBuilder Integration (100% complete)
   - [x] Support cho 3D trajectory builders trong MapBuilder
   - [x] 3D serialization/deserialization support (đã có sẵn thông qua PoseGraph interface)

### ✅ Phase 6 - Ground Truth & Metrics (HOÀN THÀNH 100%)
1. [x] Ground Truth tools ✅ **HOÀN THÀNH**
   - [x] `RelationsProto.cs` - Proto structs cho Relation và GroundTruth
   - [x] `RelationsTextFile.cs` - Reader cho relations text file format (Unix timestamps)
   - [x] `AutogenerateGroundTruth.cs` - Generate ground truth từ pose graph với outlier filtering
   - [x] `ComputeRelationsMetrics.cs` - Compute metrics (translational/rotational errors) từ pose graph và ground truth
2. [x] Metrics ✅ **HOÀN THÀNH**
   - [x] `Counter.cs` - Counter metric với Null implementation
   - [x] `Gauge.cs` - Gauge metric với Null implementation
   - [x] `Histogram.cs` - Histogram metric với Null implementation và bucket boundaries utilities (FixedWidth, ScaledPowersOf)
   - [x] `FamilyFactory.cs` - Factory cho creating metric families với labels support
   - [x] `Register.cs` - Metrics registration system (skeleton, ready for component integration)

**Tổng kết Phase 6:**
- ✅ **Ground Truth Tools**: 100% hoàn thành - Tất cả components đã được implement đầy đủ
- ✅ **Metrics System**: 100% hoàn thành - Tất cả metric types và factory đã được implement
- ✅ Build thành công với 0 errors, 0 warnings

### ✅ Phase 7 - Advanced Constraints (HOÀN THÀNH 100%)
**Lưu ý:** Các features này đã được implement đầy đủ cho cả 2D và 3D.
   - [x] Landmark constraints (đã implement trong OptimizationProblem2D và OptimizationProblem3D)
   - [x] Odometry constraints giữa consecutive nodes (đã implement trong optimization problems)
   - [x] Fixed frame pose constraints (đã implement trong optimization problems)

**Files đã tạo/cập nhật:**
- `Mapping/Internal/Optimization/CostHelpers.cs` - Helper functions cho interpolation và error computation
- `Mapping/Internal/Optimization/LandmarkCostFunction2D.cs` - Landmark cost function cho 2D
- `Mapping/Internal/Optimization/LandmarkCostFunction3D.cs` - Landmark cost function cho 3D
- `Mapping/Internal/Optimization/OptimizationProblem2D.cs` - Đã thêm landmark, odometry, và fixed frame pose constraints
- `Mapping/Internal/Optimization/OptimizationProblem3D.cs` - Đã thêm landmark, odometry, và fixed frame pose constraints
- `Mapping/Internal/Optimization/OptimizationProblem2D.cs` - Đã cập nhật NodeSpec2D với Time, LocalPose2D, và GravityAlignment
- `Transform/TransformOperations.cs` - Đã thêm Interpolate method cho Rigid3d
- `Proto/Mapping/OptimizationProblemOptionsProto.cs` - Đã thêm các options cho weights và loss functions
- `Mapping/Internal/2D/PoseGraph2D.cs` - Đã cập nhật để truyền đầy đủ thông tin node vào OptimizationProblem2D

**Tổng số dòng code:** ~1500+ lines

---

##Ghi chú Kỹ thuật

### ✅ Tối ưu Performance - Thay thế Tuple bằng Array2i Struct
- **Vấn đề**: Ban đầu sử dụng `(int x, int y)` tuple để thay thế `Eigen::Array2i`
- **Giải pháp**: Tạo struct `Array2i` tương đương `Eigen::Array2i` với:
  - Value type semantics (tối ưu memory allocation)
  - Operators (+, -, *, /, <, <=, >, >=, ==, !=)
  - Methods (ToVector2, FromVector2, Deconstruct)
  - Zero static property
- **Lợi ích**:
  - Tối ưu performance hơn tuple (struct value type)
  - Rõ ràng về semantic (tương đương với Eigen)
  - Dễ dàng mở rộng với operators và methods
- **Files đã cập nhật**:
  - `Common/Math/Array2i.cs` - Struct definition
  - `Mapping/2D/MapLimits.cs` - GetCellIndex, GetCellCenter, Contains
  - `Mapping/2D/Grid2D.cs` - GetCorrespondenceCost, IsKnown, ToFlatIndex, ComputeCroppedLimits
  - `Mapping/2D/ProbabilityGrid.cs` - SetProbability, ApplyLookupTable, GetProbability, UpdateKnownCellsBox
  - `Mapping/2D/XYIndex.cs` - XYIndexRangeIterator, XYIndexRange
  - `Mapping/Internal/2D/RayToPixelMask.cs` - Ray casting algorithm
  - `Mapping/2D/ProbabilityGridRangeDataInserter2D.cs` - Range data insertion

##Ghi chú Kỹ thuật (tiếp)

### Dependencies đã sử dụng
- ✅ `Microsoft.Extensions.Logging` (v10.0.0) - Logging framework
- ✅ `NLog.Extensions.Logging` (v5.4.0) - NLog integration
- ✅ `SkiaSharp` (v2.88.9) - Graphics/visualization
- ✅ `CeresSharp` (ProjectReference) - Ceres Solver 2.2.0 P/Invoke wrapper cho optimization

### P/Invoke đã implement
- ✅ `clock_gettime` (Linux) - Thread CPU time
- ✅ `nice` (Linux) - Thread priority adjustment

### Design Decisions
1. **Generic Math Functions**: Sử dụng generic constraints (`IFloatingPoint<T>`, `IMultiplyOperators<T>`) để hỗ trợ nhiều kiểu số
2. **Struct over Class**: Sử dụng `struct` cho `Rigid2d/f`, `Rigid3d/f` để tối ưu performance
3. **Implicit Operators**: Sử dụng implicit operators trong proto structs để seamless conversion với `System.Numerics` types
4. **Thread Safety**: Sử dụng `lock` và `ConcurrentQueue` cho thread-safe operations

---

## ✅ Checklist Build

- [x] Project file (`CartographerSharp.csproj`) configured
- [x] Target framework: .NET 10
- [x] NuGet packages restored
- [x] Common utilities compile successfully
- [x] Transform operations compile successfully
- [x] Protocol Buffers (Transform) compile successfully
- [x] Protocol Buffers (Common) compile successfully
- [x] Protocol Buffers (Sensor) compile successfully
- [x] Protocol Buffers (Mapping) compile successfully
- [x] Mapping 3D Core (HybridGrid, Submap3D, RangeDataInserter3D, ActiveSubmaps3D) compile successfully
- [x] Pose Graph 3D (PoseGraph3D, OptimizationProblem3D, SpaCostFunction3D) compile successfully
- [x] Trajectory Builder 3D (LocalTrajectoryBuilder3D, CeresScanMatcher3D, RealTimeCorrelativeScanMatcher3D, ConstraintBuilder3D) compile successfully
- [x] Scan Matching 3D Components (Cost Functions, PrecomputationGrid3D, PrecomputationGridStack3D, RotationalScanMatcher) compile successfully
- [x] MapBuilder Integration 3D compile successfully
- [x] **Build thành công với 0 errors, 0 warnings** ✅

---

**Cập nhật lần cuối**: 2025-12-14  
**Trạng thái**: ✅ **Phase 7 - Advanced Constraints HOÀN THÀNH (100%)**

### ✅ Chi tiết Phase 5 đã hoàn thành (100%):

#### 1. Common Utilities cho 3D (100%)
- ✅ **Array3i.cs** (`Common/Math/Array3i.cs`)
  - 3D integer array struct (equivalent to Eigen::Array3i)
  - Operators: +, -, *, /, <, <=, >, >=, ==, !=
  - Methods: ToVector3, FromVector3, Deconstruct
  - Zero static property

#### 2. HybridGrid Implementation (100%)
- ✅ **HybridGrid.cs** (`Mapping/3D/HybridGrid.cs`)
  - **HybridGridUtils**: Utility functions (ToFlatIndex, To3DIndex, IsDefaultValue)
  - **FlatGrid<TValueType>**: Flat grid 8x8x8 voxels (kBits=3), iterator support
  - **NestedGrid<TValueType>**: Nested grid với 512 meta cells, each containing 8x8x8 FlatGrid, lazy initialization
  - **DynamicGrid<TValueType>**: Dynamic grid với auto-grow (2x per dimension, max bits=8), negative indices support
  - **HybridGridBase<TValueType>**: Base class với resolution, GetCellIndex, GetCenterOfCell, GetOctant, GetEnumerator
  - **HybridGrid**: Main class với probability values (ushort), SetProbability, GetProbability, ApplyLookupTable, FinishUpdate, ToProto, constructor from proto
  - **IntensityHybridGrid**: Hybrid grid cho intensity data với AverageIntensityData struct (AddIntensity, GetIntensity)

#### 3. Submap3D (100%)
- ✅ **Submap3D.cs** (`Mapping/3D/Submap3D.cs`)
  - HighResolutionHybridGrid và LowResolutionHybridGrid
  - HighResolutionIntensityHybridGrid (optional, có thể forget để giảm memory)
  - RotationalScanMatcherHistogram (List<float>)
  - InsertData method với range data transformation
  - Finish, ToProto, UpdateFromProto methods
  - FilterRangeDataByMaxRange helper method

- ✅ **RangeDataInserter3D.cs** (`Mapping/3D/RangeDataInserter3D.cs`)
  - RangeDataInserterOptions3D struct
  - RangeDataInserter3D class với hit/miss lookup tables
  - Insert method cho HybridGrid và IntensityHybridGrid
  - InsertMissesIntoGrid - ray casting cho free space (equi-distant sampling)
  - InsertIntensitiesIntoGrid - intensity data insertion với threshold filtering

- ✅ **ActiveSubmaps3D.cs** (`Mapping/3D/ActiveSubmaps3D.cs`)
  - SubmapsOptions3D struct
  - ActiveSubmaps3D class với 2 active submaps management
  - InsertData method - insert range data vào all active submaps
  - AddSubmap method - tạo submap mới với gravity alignment
  - Automatic submap finishing khi đạt 2 * num_range_data
  - Memory management - ForgetIntensityHybridGrid khi remove submap

### ✅ Đã hoàn thành trong Phase 5 (100%):

#### 4. Pose Graph 3D (100%)
- [x] `PoseGraph3D.cs` - 3D pose graph implementation với đầy đủ methods
- [x] `OptimizationProblem3D.cs` - 3D optimization problem với CeresSharp integration
- [x] `SpaCostFunction3D.cs` - 3D SPA cost function cho pose graph optimization

#### 5. Trajectory Builder 3D (100%)
- [x] `LocalTrajectoryBuilder3D.cs` - Local SLAM stack cho 3D với pose extrapolator, scan matching, submap insertion
- [x] `CeresScanMatcher3D.cs` - 3D Ceres scan matcher với đầy đủ cost functions (OccupiedSpaceCostFunction3D, IntensityCostFunction3D, TranslationDeltaCostFunctor3D, RotationDeltaCostFunctor3D)
- [x] `RealTimeCorrelativeScanMatcher3D.cs` - 3D real-time correlative scan matcher với full branch-and-bound algorithm
- [x] `ConstraintBuilder3D.cs` - Constraint builder cho 3D
- [x] `TrajectoryBuilder3DAdapter.cs` - Adapter để LocalTrajectoryBuilder3D implement TrajectoryBuilderInterface

#### 6. MapBuilder Integration (100%)
- [x] Support cho 3D trajectory builders trong MapBuilder
- [x] 3D serialization/deserialization support (đã có sẵn thông qua PoseGraph interface)

#### 7. Scan Matching 3D Components (100%)

##### Cost Functions cho 3D Scan Matching (100%)
- [x] `InterpolatedGrid.cs` - InterpolatedProbabilityGrid và InterpolatedIntensityGrid với tricubic interpolation
- [x] `OccupiedSpaceCostFunction3D.cs` - Cost function cho occupied space matching với InterpolatedProbabilityGrid
- [x] `IntensityCostFunction3D.cs` - Cost function cho intensity matching với InterpolatedIntensityGrid
- [x] `TranslationDeltaCostFunctor3D.cs` - Cost functor cho translation delta
- [x] `RotationDeltaCostFunctor3D.cs` - Cost functor cho rotation delta
- [x] `CeresScanMatcher3D.cs` - Đã cập nhật để sử dụng các cost functions mới

##### Fast Correlative Scan Matcher 3D (100%)
- [x] `PrecomputationGrid3D.cs` - Precomputation grid cho branch-and-bound (8-bit values thay vì 16-bit)
- [x] `PrecomputationGridStack3D.cs` - Stack of precomputation grids với multiple depths
- [x] `RotationalScanMatcher.cs` - Rotational scan matcher cho 3D với histogram matching
- [x] `RealTimeCorrelativeScanMatcher3D.cs` - Hoàn thiện với đầy đủ branch-and-bound algorithm:
  - [x] `SearchParameters` struct
  - [x] `CreateLowResolutionMatcher` function
  - [x] `DiscretizeScan` method
  - [x] `GenerateDiscreteScans` method
  - [x] `GenerateLowestResolutionCandidates` method
  - [x] `ScoreCandidates` method
  - [x] `ComputeLowestResolutionCandidates` method
  - [x] `GetPoseFromCandidate` method
  - [x] `BranchAndBound` method (recursive implementation)
  - [x] `MatchWithSearchParameters` method
  - [x] `Match` và `MatchFullSubmap` methods với full implementation

###Files đã tạo trong Phase 5:
- `Common/Math/Array3i.cs` ✅ (~173 lines)
- `Common/FixedRatioSampler.cs` ✅ (~76 lines)
- `Mapping/3D/HybridGrid.cs` ✅ (~832 lines) - Bao gồm: HybridGridUtils, FlatGrid, NestedGrid, DynamicGrid, HybridGridBase, HybridGrid, IntensityHybridGrid
- `Mapping/3D/Submap3D.cs` ✅ (~256 lines)
- `Mapping/3D/RangeDataInserter3D.cs` ✅ (~172 lines)
- `Mapping/3D/ActiveSubmaps3D.cs` ✅ (~120 lines)
- `Mapping/Internal/3D/PoseGraph3D.cs` ✅ (~753 lines)
- `Mapping/Internal/3D/Optimization/OptimizationProblem3D.cs` ✅ (~350 lines)
- `Mapping/Internal/3D/Optimization/SpaCostFunction3D.cs` ✅ (~180 lines)
- `Mapping/Internal/3D/LocalTrajectoryBuilder3D.cs` ✅ (~357 lines)
- `Mapping/Internal/3D/ScanMatching/CeresScanMatcher3D.cs` ✅ (~210 lines)
- `Mapping/Internal/3D/ScanMatching/RealTimeCorrelativeScanMatcher3D.cs` ✅ (~650 lines) - Hoàn thiện với full branch-and-bound algorithm:
  - SearchParameters struct
  - CreateLowResolutionMatcher function
  - DiscretizeScan, GenerateDiscreteScans methods
  - GenerateLowestResolutionCandidates, ScoreCandidates methods
  - ComputeLowestResolutionCandidates, GetPoseFromCandidate methods
  - BranchAndBound recursive algorithm
  - MatchWithSearchParameters, Match, MatchFullSubmap methods
- `Mapping/Internal/3D/ScanMatching/InterpolatedGrid.cs` ✅ (~250 lines) - InterpolatedProbabilityGrid và InterpolatedIntensityGrid với tricubic interpolation
- `Mapping/Internal/3D/ScanMatching/OccupiedSpaceCostFunction3D.cs` ✅ (~140 lines) - Cost function cho occupied space matching
- `Mapping/Internal/3D/ScanMatching/IntensityCostFunction3D.cs` ✅ (~150 lines) - Cost function cho intensity matching
- `Mapping/Internal/3D/ScanMatching/TranslationDeltaCostFunctor3D.cs` ✅ (~80 lines) - Cost functor cho translation delta
- `Mapping/Internal/3D/ScanMatching/RotationDeltaCostFunctor3D.cs` ✅ (~90 lines) - Cost functor cho rotation delta
- `Mapping/Internal/3D/ScanMatching/PrecomputationGrid3D.cs` ✅ (~160 lines) - Precomputation grid với 8-bit values
- `Mapping/Internal/3D/ScanMatching/PrecomputationGridStack3D.cs` ✅ (~80 lines) - Stack of precomputation grids với multiple depths
- `Mapping/Internal/3D/ScanMatching/RotationalScanMatcher.cs` ✅ (~120 lines) - Rotational scan matcher với histogram matching
- `Mapping/Internal/Constraints/ConstraintBuilder3D.cs` ✅ (~420 lines)
- `Mapping/Internal/3D/TrajectoryBuilder3DAdapter.cs` ✅ (~66 lines)
- `Proto/Mapping/CeresScanMatcherOptions3DProto.cs` ✅ (~95 lines)
- `Proto/Mapping/FastCorrelativeScanMatcherOptions3DProto.cs` ✅ (~60 lines)
- `Proto/Mapping/LocalTrajectoryBuilderOptions3DProto.cs` ✅ (~145 lines)
- `Common/FixedRatioSampler.cs` ✅ (~76 lines)

**Tổng số dòng code Phase 5**: ~6,000+ lines (không tính comments và blank lines)

###Files đã tạo trong Phase 6:
- `Proto/GroundTruth/RelationsProto.cs` ✅ (~50 lines) - Relation và GroundTruth proto structs
- `GroundTruth/RelationsTextFile.cs` ✅ (~115 lines) - Reader cho relations text file format
- `GroundTruth/AutogenerateGroundTruth.cs` ✅ (~210 lines) - Generate ground truth từ pose graph
- `GroundTruth/ComputeRelationsMetrics.cs` ✅ (~250 lines) - Compute metrics từ pose graph và ground truth
- `Metrics/Counter.cs` ✅ (~50 lines) - Counter metric với Null implementation
- `Metrics/Gauge.cs` ✅ (~70 lines) - Gauge metric với Null implementation
- `Metrics/Histogram.cs` ✅ (~90 lines) - Histogram metric với Null implementation và bucket boundaries
- `Metrics/FamilyFactory.cs` ✅ (~80 lines) - Factory cho creating metric families với labels
- `Metrics/Register.cs` ✅ (~30 lines) - Metrics registration system

**Tổng số dòng code Phase 6**: ~900+ lines (không tính comments và blank lines)

### Technical Details Phase 5:

#### HybridGrid Architecture:
- **FlatGrid**: Fixed-size 8x8x8 = 512 voxels, contiguous memory
- **NestedGrid**: 8x8x8 = 512 meta cells, each containing 8x8x8 FlatGrid = 64x64x64 total voxels
- **DynamicGrid**: Starts with 2x2x2 = 8 meta cells, grows to 4x4x4, 8x8x8, etc. (max bits=8)
- **Indexing**: Z-major order (z, y, x) để tối ưu cache locality
- **Memory**: Lazy initialization - chỉ tạo meta cells khi cần

#### Key Features:
- **Negative Indices Support**: DynamicGrid sử dụng index shifting để support negative indices (symmetric around origin)
- **Update Markers**: HybridGrid sử dụng update markers (bit 15) để track cells đã được update trong một batch
- **Intensity Support**: IntensityHybridGrid lưu average intensity với Sum và Count
- **Memory Management**: ActiveSubmaps3D tự động forget intensity grids khi remove submap để giảm memory usage

#### 3D Scan Matching Architecture:
- **InterpolatedGrid**: Tricubic interpolation cho probability và intensity grids (InterpolatedProbabilityGrid, InterpolatedIntensityGrid)
- **Cost Functions**: OccupiedSpaceCostFunction3D, IntensityCostFunction3D, TranslationDeltaCostFunctor3D, RotationDeltaCostFunctor3D
- **PrecomputationGrid3D**: 8-bit precomputation grid cho branch-and-bound algorithm (thay vì 16-bit để tiết kiệm memory)
- **PrecomputationGridStack3D**: Stack of precomputation grids với multiple depths cho hierarchical search
- **RotationalScanMatcher**: Histogram-based rotational matching với linear interpolation
- **RealTimeCorrelativeScanMatcher3D**: Hoàn thiện với full branch-and-bound algorithm:
  - **DiscretizeScan**: Discretize point cloud ở các resolutions khác nhau cho hierarchical search
  - **GenerateDiscreteScans**: Generate discrete scans cho các rotation angles dựa trên rotational scan matcher scores
  - **Branch-and-Bound**: Recursive algorithm để tìm best candidate efficiently:
    - Generate candidates ở lowest resolution
    - Score candidates và sort theo score
    - Recursively refine candidates ở higher resolutions
    - Prune candidates với score thấp hơn best score hiện tại
    - Apply low resolution matcher filter ở depth 0
  - **ScoreCandidates**: Compute probability scores bằng cách sum precomputation grid values
  - **GetPoseFromCandidate**: Convert candidate offset và scan index thành final pose estimate

### Tổng kết Phase 1: ✅ HOÀN THÀNH
- ✅ Common Utilities: Math, Time, Threading (100%)
- ✅ Transform Operations: Rigid2/3, TransformOperations (100%)
- ✅ Protocol Buffers: Transform, Common, Sensor, Mapping core (100%)
- ✅ Build thành công với 0 errors

### Tổng kết Phase 2: ✅ HOÀN THÀNH
- ✅ Sensor Data Structures: RangefinderPoint, PointCloud, RangeData, TimedPointCloudData (100%)
- ✅ Sensor Data Types: ImuData, OdometryData, FixedFramePoseData, LandmarkData (100%)
- ✅ Point Cloud Processing: Transform, Crop operations (100%)
- ✅ Voxel Filter: Randomized voxel filtering với reservoir sampling (100%)
- ✅ Adaptive Voxel Filter: Binary search để tìm resolution phù hợp (100%)
- ✅ Compressed Point Cloud: Block-based encoding với decompression (100%)
- ✅ Build thành công với 0 errors, 0 warnings

### ✅ CeresSharp Integration (HOÀN THÀNH)
- ✅ Phase 1: Setup Dependencies - ProjectReference đến CeresSharp, build verification (100%)
- ✅ Phase 2: Cost Functions - OccupiedSpaceCostFunction2D, TranslationDeltaCostFunctor2D, RotationDeltaCostFunctor2D, ProbabilityGridAdapter (100%)
- ✅ Phase 3: CeresScanMatcher2D - Complete Match() method với Problem setup, cost functions integration, SolverOptions (100%)
- ✅ Phase 4: OptimizationProblem2D - Complete Solve() method với SpaCostFunction2D, parameter blocks, constraints, frozen trajectories (100%)
- ✅ Phase 5: Integration - Complete integration với PoseGraph2D.RunFinalOptimization(), data sync và pose updates (100%)
- [ ] Optional: End-to-end tests và performance benchmarks (có thể làm sau)

### Tổng kết Phase 3: ✅ HOÀN THÀNH (100%)
- ✅ Mapping Common: NodeId, SubmapId, ProbabilityValues, ValueConversionTables, Submap base, RangeDataInserterInterface, MapById, TrajectoryNode (100%)
- ✅ Mapping 2D Core: CellLimits, MapLimits, XYIndex, Grid2D, ProbabilityGrid, Submap2D (100%)
- ✅ Range Data Inserter 2D: RayToPixelMask utility, ProbabilityGridRangeDataInserter2D với ray casting (100%)
- ✅ Pose Graph Interface: Complete interface với tất cả structs và methods (100%)
- ✅ Pose Graph Base: Base class với InitialTrajectoryPose, PoseGraphTrimmer, Trimmable interface (100%)
- ✅ Pose Graph 2D: Complete implementation với trajectory management, constraint handling, trimming, serialization (100%)
- ✅ Trajectory Builder Interface: Complete interface với InsertionResult, SensorId, LocalSlamResultCallback (100%)
- ✅ Motion Filter: Filter poses dựa trên time, distance, và angle thresholds (100%)
- ✅ Range Data Collator: Synchronize TimedPointCloudData từ nhiều sensors (100%)
- ✅ Active Submaps 2D: Quản lý 2 active submaps (old và new) với automatic finishing và creation (100%)
- ✅ Real-time Correlative Scan Matcher 2D: Complete implementation với exhaustive search và scoring (100%)
- ✅ Correlative Scan Matcher 2D: SearchParameters, Candidate2D, DiscreteScan2D, scan generation utilities (100%)
- ✅ Ceres Scan Matcher 2D: Complete implementation với CeresSharp integration (Problem setup, cost functions: OccupiedSpaceCostFunction2D, TranslationDeltaCostFunctor2D, RotationDeltaCostFunctor2D, ProbabilityGridAdapter, SolverOptions với DENSE_QR) (100%)
- ✅ Local Trajectory Builder 2D: Complete implementation với range data accumulation, pose extrapolator, scan matching, submap insertion (100%)
- ✅ Pose Extrapolator: Interface và implementation với velocity estimation từ poses và sensor data, angular velocity computation (100%)
- ✅ Optimization Problem 2D: Complete implementation với CeresSharp integration (Solve method với Problem setup, parameter blocks, constraints, frozen trajectories, SpaCostFunction2D, HuberLoss cho loop closure, integration với PoseGraph2D.RunFinalOptimization) (100%)
- ✅ Constraint Builder 2D: Complete implementation với scan matching integration (MaybeAddConstraint, MaybeAddGlobalConstraint, RealTimeCorrelativeScanMatcher2D cho initial estimate, CeresScanMatcher2D cho refinement, constraint transform computation) (100%)
- ✅ Map Builder: Complete implementation với trajectory builder management, pose graph integration, serialization support (100%)
- ✅ Pose Graph 2D Methods: Hoàn thiện DeleteTrajectory, GetAllSubmapPoses, ToProto, GetConnectedTrajectories, SetInitialTrajectoryPose, AddTrimmer (100%)
- ✅ Build thành công với 0 errors, 0 warnings

### Tổng kết Phase 4: ✅ HOÀN THÀNH (100%)
- ✅ IO Interfaces: ProtoStreamWriterInterface, ProtoStreamReaderInterface (100%)
- ✅ IO Implementations: ProtoStreamWriter, ProtoStreamReader với GZip compression/decompression, magic number validation (100%)
- ✅ Serialization Logic: MappingStateSerialization với header, pose graph, trajectory options, submaps, nodes, trajectory data (100%)
- ✅ SerializationProto: SerializedData struct với tất cả data types (SerializationHeader, Submap, Node, SerializedImuData, SerializedOdometryData, SerializedFixedFramePoseData, SerializedLandmarkData, SerializedTrajectoryData) (100%)
- ✅ MapBuilder Serialization: SerializeState(), SerializeStateToFile() với IProtoStreamWriter integration (100%)
- ✅ ProtoStreamDeserializer: Complete class với header reading, version validation, pose graph và trajectory options reading, ReadNextSerializedData() method (100%)
- ✅ MapBuilder Deserialization: LoadState(), LoadStateFromFile() với complete deserialization logic (100%)
- ✅ Trajectory Remapping: Dictionary mapping old → new trajectory IDs khi load state (100%)
- ✅ Data Deserialization: Pose graph, submaps, nodes, trajectory data, IMU, odometry, fixed frame pose, landmark data (100%)
- ✅ Format Version Support: Validation và support cho format version 1 và 2 (100%)
- ✅ Frozen State Support: Proper handling cho frozen trajectories với constraint và node-to-submap relationships (100%)
- ✅ Build thành công với 0 errors, 0 warnings

### Tổng kết Phase 5: ✅ HOÀN THÀNH (100%)
- ✅ Common Utilities 3D: Array3i struct với operators và methods (100%)
- ✅ FixedRatioSampler: Utility class cho fixed-ratio sampling (100%)
- ✅ HybridGrid Implementation: Complete implementation với FlatGrid, NestedGrid, DynamicGrid, HybridGridBase, HybridGrid, IntensityHybridGrid (100%)
  - ✅ HybridGridUtils: ToFlatIndex, To3DIndex, IsDefaultValue
  - ✅ FlatGrid: 8x8x8 voxels với iterator support
  - ✅ NestedGrid: 512 meta cells, each containing 8x8x8 FlatGrid
  - ✅ DynamicGrid: Auto-grow functionality, negative indices support, max bits=8
  - ✅ HybridGridBase: Resolution, GetCellIndex, GetCenterOfCell, GetOctant, GetEnumerator
  - ✅ HybridGrid: Probability values (ushort), SetProbability, GetProbability, ApplyLookupTable, FinishUpdate, ToProto
  - ✅ IntensityHybridGrid: AverageIntensityData, AddIntensity, GetIntensity
- ✅ Submap3D: Complete implementation với high/low resolution grids, intensity grid, rotational histogram (100%)
  - ✅ Submap3D class: InsertData, Finish, ToProto, UpdateFromProto, FilterRangeDataByMaxRange
  - ✅ RangeDataInserter3D: Hit/miss tables, ray casting, intensity insertion
  - ✅ ActiveSubmaps3D: 2 active submaps management, automatic finishing, memory management
- ✅ Pose Graph 3D: Hoàn thành (PoseGraph3D, OptimizationProblem3D, SpaCostFunction3D) (100%)
- ✅ Optimization Problem 3D: Hoàn thành với CeresSharp integration (100%)
- ✅ Scan Matching 3D Components: Hoàn thành (100%)
  - ✅ **Cost Functions**: InterpolatedGrid (InterpolatedProbabilityGrid, InterpolatedIntensityGrid với tricubic interpolation), OccupiedSpaceCostFunction3D, IntensityCostFunction3D, TranslationDeltaCostFunctor3D, RotationDeltaCostFunctor3D
  - ✅ **CeresScanMatcher3D**: Đã tích hợp đầy đủ cost functions
  - ✅ **PrecomputationGrid3D**: Precomputation grid với 8-bit values cho branch-and-bound algorithm
  - ✅ **PrecomputationGridStack3D**: Stack of precomputation grids với multiple depths cho hierarchical search
  - ✅ **RotationalScanMatcher**: Rotational scan matcher với histogram matching
  - ✅ **RealTimeCorrelativeScanMatcher3D**: Hoàn thiện với đầy đủ branch-and-bound algorithm:
    - ✅ DiscretizeScan: Discretize scan ở các resolutions khác nhau
    - ✅ GenerateDiscreteScans: Generate discrete scans cho các rotation angles
    - ✅ GenerateLowestResolutionCandidates: Generate candidates ở lowest resolution
    - ✅ ScoreCandidates: Score candidates ở một depth cụ thể
    - ✅ ComputeLowestResolutionCandidates: Compute và score candidates ở lowest resolution
    - ✅ GetPoseFromCandidate: Convert candidate thành pose
    - ✅ BranchAndBound: Recursive branch-and-bound algorithm
    - ✅ MatchWithSearchParameters: Main matching method với search parameters
    - ✅ Match và MatchFullSubmap: Public methods với full implementation
- ✅ Trajectory Builder 3D: Hoàn thành (LocalTrajectoryBuilder3D, CeresScanMatcher3D với cost functions, RealTimeCorrelativeScanMatcher3D với full branch-and-bound algorithm, ConstraintBuilder3D, TrajectoryBuilder3DAdapter) (100%)
- ✅ MapBuilder Integration 3D: Hoàn thành (support cho 3D trajectory builders) (100%)
- ✅ Build thành công với 0 errors, 0 warnings

### Tổng kết Phase 6: ✅ HOÀN THÀNH (100%)
- ✅ Ground Truth Tools: Hoàn thành (100%)
  - ✅ RelationsProto: Proto structs cho Relation và GroundTruth
  - ✅ RelationsTextFile: Reader cho relations text file format (Unix timestamps)
  - ✅ AutogenerateGroundTruth: Generate ground truth từ pose graph với outlier filtering
  - ✅ ComputeRelationsMetrics: Compute metrics (translational/rotational errors) từ pose graph và ground truth
- ✅ Metrics System: Hoàn thành (100%)
  - ✅ Counter: Counter metric với Null implementation
  - ✅ Gauge: Gauge metric với Null implementation
  - ✅ Histogram: Histogram metric với Null implementation, FixedWidth và ScaledPowersOf bucket boundaries
  - ✅ FamilyFactory: Factory cho creating metric families với labels support
  - ✅ Register: Metrics registration system (skeleton, ready for component integration)
- ✅ Build thành công với 0 errors, 0 warnings

### Tổng kết Phase 7: ✅ HOÀN THÀNH (100%)
- ✅ **Landmark Constraints (2D & 3D)**: Hoàn thành (100%)
  - ✅ **LandmarkCostFunction2D**: Cost function cho landmark constraints trong 2D optimization
    - Interpolate nodes 2D embedded in 3D space với gravity alignment
    - Compute error giữa observed landmark pose và interpolated tracking pose
    - Support cho weighted translation và rotation errors
  - ✅ **LandmarkCostFunction3D**: Cost function cho landmark constraints trong 3D optimization
    - Interpolate nodes 3D với SLERP cho rotation và linear cho translation
    - Compute 6D error (translation + rotation angle-axis)
    - Full integration với OptimizationProblem3D
  - ✅ **Integration**: Đã tích hợp vào `OptimizationProblem2D.Solve()` và `OptimizationProblem3D.Solve()`
    - Add landmark parameter blocks (quaternion + translation)
    - Set QuaternionManifold cho rotation parameters
    - Support frozen landmarks
    - Use HuberLoss cho robustness

- ✅ **Odometry Constraints**: Hoàn thành (100%)
  - ✅ **Helper Methods**: 
    - `InterpolateOdometry()`: Interpolate odometry data tại thời điểm cụ thể
    - `CalculateOdometryBetweenNodes()`: Tính relative odometry giữa 2 nodes với gravity alignment (2D) hoặc direct (3D)
  - ✅ **2D Implementation**: 
    - Add constraints giữa consecutive nodes dựa trên odometry data (nếu có)
    - Always add local SLAM pose constraints giữa consecutive nodes
    - Sử dụng `SpaCostFunction2D` với odometry/local SLAM weights
  - ✅ **3D Implementation**:
    - Tương tự 2D nhưng sử dụng `SpaCostFunction3D`
    - Support cho 3D quaternion rotations

- ✅ **Fixed Frame Pose Constraints**: Hoàn thành (100%)
  - ✅ **Helper Methods**:
    - `InterpolateFixedFramePose()`: Interpolate fixed frame pose data (như GPS) tại thời điểm cụ thể
  - ✅ **2D Implementation**:
    - Add fixed frame pose parameter blocks (2D pose: x, y, theta)
    - Constraints giữa fixed frame origin và node poses
    - Support `TolerantLoss` nếu được cấu hình
    - Initialize từ `TrajectoryData.FixedFrameOriginInMap` hoặc từ node pose
  - ✅ **3D Implementation**:
    - Add fixed frame pose parameter blocks (3D pose: quaternion + translation)
    - Set QuaternionManifold cho rotation
    - Full 3D constraint support

- ✅ **Helper Functions & Infrastructure**: Hoàn thành (100%)
  - ✅ **CostHelpers.cs**: 
    - `SlerpQuaternions()`: Spherical linear interpolation cho quaternions
    - `InterpolateNodes2D()`: Interpolate 2D nodes embedded in 3D với gravity alignment
    - `InterpolateNodes3D()`: Interpolate 3D nodes với SLERP và linear interpolation
    - `ComputeUnscaledError3D()`: Compute error giữa observed và computed relative poses
    - `ScaleError3D()`: Scale error với translation và rotation weights
  - ✅ **TransformOperations.Interpolate()**: 
    - Interpolate giữa 2 Rigid3d transforms tại different times
    - Linear interpolation cho translation
    - SLERP cho rotation
  - ✅ **NodeSpec2D Updates**:
    - Added `Time` field (Universal Time Scale ticks)
    - Added `LocalPose2D` field (local SLAM pose)
    - Added `GravityAlignment` field (Quaternion)
    - Updated constructor và all usages
  - ✅ **OptimizationProblemOptions Updates**:
    - Added `HuberScale` cho landmark constraints
    - Added `OdometryTranslationWeight` và `OdometryRotationWeight`
    - Added `LocalSlamPoseTranslationWeight` và `LocalSlamPoseRotationWeight`
    - Added `FixedFramePoseTranslationWeight` và `FixedFramePoseRotationWeight`
    - Added `FixedFramePoseUseTolerantLoss`, `FixedFramePoseTolerantLossParamA/B`
    - Added `LogSolverSummary`

- ✅ **Integration Updates**: Hoàn thành (100%)
  - ✅ **PoseGraph2D**: Updated để truyền đầy đủ node data (Time, LocalPose2D, GravityAlignment) vào OptimizationProblem2D
  - ✅ **OptimizationProblem2D.Solve()**: 
    - Added landmark cost functions với proper parameter management
    - Added odometry constraints cho consecutive nodes
    - Added fixed frame pose constraints
    - Update landmark và fixed frame poses sau optimization
  - ✅ **OptimizationProblem3D.Solve()**:
    - Added landmark cost functions với 3D parameter blocks
    - Added odometry constraints cho consecutive nodes
    - Added fixed frame pose constraints với 3D poses
    - Update landmark và fixed frame poses sau optimization

- ✅ **Files Created/Updated**:
  - ✅ `Mapping/Internal/Optimization/CostHelpers.cs` (~150 lines) - NEW
  - ✅ `Mapping/Internal/Optimization/LandmarkCostFunction2D.cs` (~150 lines) - NEW
  - ✅ `Mapping/Internal/Optimization/LandmarkCostFunction3D.cs` (~150 lines) - NEW
  - ✅ `Mapping/Internal/Optimization/OptimizationProblem2D.cs` (~800 lines) - UPDATED
  - ✅ `Mapping/Internal/Optimization/OptimizationProblem3D.cs` (~950 lines) - UPDATED
  - ✅ `Transform/TransformOperations.cs` - UPDATED (added Interpolate method)
  - ✅ `Proto/Mapping/OptimizationProblemOptionsProto.cs` - UPDATED (added all options)
  - ✅ `Mapping/Internal/2D/PoseGraph2D.cs` - UPDATED (pass full node data)

- ✅ **Build Status**: ✅ Build thành công với 0 errors, 0 warnings
- ✅ **Tổng số dòng code**: ~1500+ lines (new + updated)
- **Lưu ý:** Phase 6 đã hoàn thành 100% với tất cả các component:
  - ✅ **Ground Truth**: RelationsProto, RelationsTextFile, AutogenerateGroundTruth, ComputeRelationsMetrics
  - ✅ **Metrics**: Counter, Gauge, Histogram, FamilyFactory, Register (skeleton implementation, ready for integration với các components)
- **Lưu ý:** Phase 5 đã hoàn thành 100% với tất cả các component:
  - ✅ **3D Core**: HybridGrid, Submap3D, RangeDataInserter3D, ActiveSubmaps3D
  - ✅ **Pose Graph 3D**: PoseGraph3D, OptimizationProblem3D, SpaCostFunction3D
  - ✅ **Trajectory Builder 3D**: LocalTrajectoryBuilder3D, CeresScanMatcher3D (với đầy đủ cost functions), RealTimeCorrelativeScanMatcher3D (với full branch-and-bound algorithm), ConstraintBuilder3D, TrajectoryBuilder3DAdapter
  - ✅ **MapBuilder Integration**: Support cho 3D trajectory builders, serialization/deserialization
  - ✅ **Cost Functions 3D**: OccupiedSpaceCostFunction3D, IntensityCostFunction3D, TranslationDeltaCostFunctor3D, RotationDeltaCostFunctor3D, InterpolatedGrid
  - ✅ **Fast Correlative Scan Matcher 3D**: PrecomputationGrid3D, PrecomputationGridStack3D, RotationalScanMatcher, RealTimeCorrelativeScanMatcher3D với full branch-and-bound algorithm
  - ✅ **Branch-and-Bound Algorithm**: Hoàn chỉnh với tất cả methods (DiscretizeScan, GenerateDiscreteScans, BranchAndBound, ScoreCandidates, và supporting methods)
