# CeresSharp Integration Tasks - Chi tiết Công việc

##Tổng quan

Tài liệu này mô tả **cụ thể** những gì cần làm để tích hợp CeresSharp vào CartographerSharp, hoàn thiện các components còn thiếu.

## ✅ Trạng thái hiện tại

- **CeresSharp**: ✅ Đã có sẵn (100% complete - 216+ APIs)
- **Ceres Solver Version**: 2.2.0
- **CartographerSharp**: [ ] Đang chờ CeresSharp integration

##Nơi Triển Khai: **CartographerSharp**

**Quan trọng**: Tất cả implementation sẽ được làm **trong CartographerSharp**, không phải CeresSharp.

### Lý do:
- **CeresSharp** = Generic optimization library (cung cấp building blocks)
- **CartographerSharp** = Application layer (sử dụng CeresSharp để implement Cartographer algorithms)
- Các cost functions là **Cartographer-specific**, không phải generic Ceres functionality

### Cấu trúc Files:

```
CartographerSharp/
├── Mapping/
│   ├── Internal/
│   │   ├── 2D/
│   │   │   └── ScanMatching/
│   │   │       ├── CeresScanMatcher2D.cs ✅ (skeleton)
│   │   │       ├── OccupiedSpaceCostFunction2D.cs [ ] (cần implement)
│   │   │       ├── TranslationDeltaCostFunctor2D.cs [ ] (cần implement)
│   │   │       └── RotationDeltaCostFunctor2D.cs [ ] (cần implement)
│   │   └── Optimization/
│   │       ├── OptimizationProblem2D.cs ✅ (skeleton)
│   │       └── SpaCostFunction2D.cs [ ] (cần implement)
│   └── ...
└── CartographerSharp.csproj [ ] (cần thêm ProjectReference đến CeresSharp)
```

##Dependencies

### 1. Project Reference

**File**: `CartographerSharp.csproj`

Thêm reference đến CeresSharp:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <LangVersion>preview</LangVersion>
  </PropertyGroup>

  <ItemGroup>
    <!-- Reference to CeresSharp -->
    <ProjectReference Include="../CeresSharp/CeresSharp.csproj" />
    
    <!-- Existing dependencies -->
    <PackageReference Include="Microsoft.Extensions.Logging" Version="10.0.0" />
    <PackageReference Include="NLog.Extensions.Logging" Version="5.4.0" />
    <PackageReference Include="SkiaSharp" Version="2.88.9" />
  </ItemGroup>
</Project>
```

### 2. Using Directives

Thêm vào các files cần dùng CeresSharp:

```csharp
using CeresSharp;
using CeresSharp.Core;
using CeresSharp.Enums;
```

---

##Các Components Cần Hoàn Thiện

### 1. CeresScanMatcher2D [ ]

**File**: `Mapping/Internal/2D/ScanMatching/CeresScanMatcher2D.cs`

**Trạng thái hiện tại**: Skeleton implementation với TODOs

**Cần implement**:

#### 1.1. Cost Functions cho Scan Matching

##### a) OccupiedSpaceCostFunction2D
**File mới**: `Mapping/Internal/2D/ScanMatching/OccupiedSpaceCostFunction2D.cs`

**Mục đích**: Tính cost dựa trên occupied space trong grid

**C++ Reference**: `refs/cartographer/cartographer/mapping/internal/2d/scan_matching/occupied_space_cost_function_2d.h/cc`

**Cần làm**:
1. Tạo class `OccupiedSpaceCostFunction2D` implement `CeresSharp.CostFunction`
2. Sử dụng `CeresSharp.BiCubicInterpolator` để interpolate grid values
3. Transform point cloud points theo pose estimate
4. Tính residual = 1.0 - interpolated_probability cho mỗi point
5. Weight = `occupied_space_weight / sqrt(point_cloud.size())`

**CeresSharp APIs cần dùng**:
- `CeresSharp.BiCubicInterpolator` - Cho grid interpolation
- `CeresSharp.AutoDiffCostFunction` - Cho automatic differentiation
- `CeresSharp.Problem.AddResidualBlock()` - Thêm cost function vào problem

**Code structure**:
```csharp
// File: Mapping/Internal/2D/ScanMatching/OccupiedSpaceCostFunction2D.cs
using CeresSharp;
using CeresSharp.Core;
using CartographerSharp.Mapping.D2D;
using CartographerSharp.Sensor;

namespace CartographerSharp.Mapping.Internal.D2D.ScanMatching;

public class OccupiedSpaceCostFunction2D : CostFunction
{
    private readonly BiCubicInterpolator _interpolator;
    private readonly PointCloud _pointCloud;
    private readonly double _weight;
    
    // Implement Evaluate() method
    // Transform points, interpolate, compute residuals
}
```

##### b) TranslationDeltaCostFunctor2D
**File mới**: `Mapping/Internal/2D/ScanMatching/TranslationDeltaCostFunctor2D.cs`

**Mục đích**: Penalize translation deviation từ target translation

**C++ Reference**: `refs/cartographer/cartographer/mapping/internal/2d/scan_matching/translation_delta_cost_functor_2d.h/cc`

**Cần làm**:
1. Tạo functor class với `target_translation` và `weight`
2. Residual = `weight * (current_translation - target_translation)`
3. Sử dụng `AutoDiffCostFunction` với 3 parameters (x, y, theta)

**Code structure**:
```csharp
// File: Mapping/Internal/2D/ScanMatching/TranslationDeltaCostFunctor2D.cs
using System.Numerics;
using CeresSharp;
using CeresSharp.Core;

namespace CartographerSharp.Mapping.Internal.D2D.ScanMatching;

public class TranslationDeltaCostFunctor2D
{
    private readonly Vector2 _targetTranslation;
    private readonly double _weight;
    
    public static AutoDiffCostFunction CreateAutoDiffCostFunction(
        double scalingFactor, Vector2 targetTranslation)
    {
        return new AutoDiffCostFunction<TranslationDeltaCostFunctor2D, 2, 3>(
            new TranslationDeltaCostFunctor2D(scalingFactor, targetTranslation)
        );
    }
    
    public void Evaluate(double[] parameters, double[] residuals, double[][] jacobians)
    {
        // parameters[0] = x, parameters[1] = y
        // residuals[0] = weight * (x - targetX)
        // residuals[1] = weight * (y - targetY)
    }
}
```

##### c) RotationDeltaCostFunctor2D
**File mới**: `Mapping/Internal/2D/ScanMatching/RotationDeltaCostFunctor2D.cs`

**Mục đích**: Penalize rotation deviation từ initial rotation

**C++ Reference**: `refs/cartographer/cartographer/mapping/internal/2d/scan_matching/rotation_delta_cost_functor_2d.h/cc`

**Cần làm**:
1. Tạo functor class với `initial_rotation` và `weight`
2. Residual = `weight * (current_rotation - initial_rotation)`
3. Sử dụng `AutoDiffCostFunction` với 1 parameter (theta)

**Code structure**:
```csharp
// File: Mapping/Internal/2D/ScanMatching/RotationDeltaCostFunctor2D.cs
using CeresSharp;
using CeresSharp.Core;

namespace CartographerSharp.Mapping.Internal.D2D.ScanMatching;

public class RotationDeltaCostFunctor2D
{
    private readonly double _initialRotation;
    private readonly double _weight;
    
    public static AutoDiffCostFunction CreateAutoDiffCostFunction(
        double scalingFactor, double targetAngle)
    {
        return new AutoDiffCostFunction<RotationDeltaCostFunctor2D, 1, 3>(
            new RotationDeltaCostFunctor2D(scalingFactor, targetAngle)
        );
    }
    
    public void Evaluate(double[] parameters, double[] residuals, double[][] jacobians)
    {
        // parameters[0] = theta
        // residuals[0] = weight * (theta - initialRotation)
    }
}
```

#### 1.2. CeresScanMatcher2D.Match() Implementation

**File**: `Mapping/Internal/2D/ScanMatching/CeresScanMatcher2D.cs`

**Cần làm**:
1. Khởi tạo `CeresSharp.Problem`
2. Setup `CeresSharp.SolverOptions`:
   - `LinearSolverType = LinearSolverType.DenseQr` (cho 2D scan matching)
   - Configure từ `CeresSolverOptions` proto
3. Tạo parameter block: `double[3]` = `[x, y, theta]`
4. Add cost functions:
   - OccupiedSpaceCostFunction2D (cho ProbabilityGrid hoặc TSDF2D)
   - TranslationDeltaCostFunctor2D
   - RotationDeltaCostFunctor2D
5. Solve: `CeresSharp.Solver.Solve(options, problem, out summary)`
6. Extract result: `poseEstimate = new Rigid2d(x, y, theta)`

---

### 2. OptimizationProblem2D [ ]

**File**: `Mapping/Internal/Optimization/OptimizationProblem2D.cs`

**Trạng thái hiện tại**: Skeleton implementation với data structures

**Cần implement**:

#### 2.1. Cost Functions cho Pose Graph Optimization

##### a) SpaCostFunction2D
**File mới**: `Mapping/Internal/Optimization/SpaCostFunction2D.cs`

**Mục đích**: Sparse Pose Adjustment (SPA) cost function cho constraints

**C++ Reference**: `refs/cartographer/cartographer/mapping/internal/optimization/cost_functions/spa_cost_function_2d.h/cc`

**Cần làm**:
1. Tạo `SpaCostFunction2D` class
2. Residual = `relative_pose - (submap_pose^-1 * node_pose)`
3. Weight bằng `translation_weight` và `rotation_weight` từ constraint
4. Sử dụng `HuberLoss` cho loop closure constraints (robust với outliers)

#### 2.2. OptimizationProblem2D.Solve() Implementation

**File**: `Mapping/Internal/Optimization/OptimizationProblem2D.cs`

**Cần làm**:
1. Khởi tạo `CeresSharp.Problem`
2. Setup `CeresSharp.SolverOptions`:
   - `LinearSolverType = LinearSolverType.SparseSchur` (cho large problems)
   - Configure từ `OptimizationProblemOptions`
3. Add parameter blocks:
   - Mỗi submap: `double[3]` = `[x, y, theta]`
   - Mỗi node: `double[3]` = `[x, y, theta]`
4. Set frozen trajectories: `problem.SetParameterBlockConstant(poseParams)`
5. Add constraints:
   - Loop closure constraints: Sử dụng `HuberLoss`
   - Intra-submap constraints: Không dùng loss function
6. Solve: `Solver.Solve(options, problem, out summary)`
7. Update poses: Extract từ parameter blocks và update `_submapData` và `_nodeData`

---

##Migration Notes - Ceres 2.2.0

### Deprecated APIs

Cartographer C++ sử dụng Ceres cũ với các APIs đã deprecated:

| API Cũ (Cartographer) | API Mới (Ceres 2.2.0) | Status trong CeresSharp |
|----------------------|----------------------|------------------------|
| `ceres::QuaternionParameterization` | `ceres::QuaternionManifold` | ✅ Có sẵn |
| `ceres::LocalParameterization` | `ceres::Manifold` | ✅ Có sẵn |
| `ceres::AutoDiffLocalParameterization` | `ceres::AutoDiffManifold` | ✅ Có sẵn |
| `problem.SetParameterization()` | `problem.SetManifold()` | ✅ Có sẵn |

**Lưu ý**: Khi implement, sử dụng **Manifold APIs** thay vì LocalParameterization (nếu cần cho 3D).

---

##Checklist Implementation

### Phase 1: Setup Dependencies ✅
- [x] Thêm `ProjectReference` đến CeresSharp trong `CartographerSharp.csproj`
- [x] Verify build thành công với CeresSharp reference

### Phase 2: Cost Functions ✅
- [x] Implement `OccupiedSpaceCostFunction2D.cs` - Complete với BiCubicInterpolator integration
- [x] Implement `TranslationDeltaCostFunctor2D.cs` - Complete với AutoDiffCostFunction
- [x] Implement `RotationDeltaCostFunctor2D.cs` - Complete với AutoDiffCostFunction
- [x] Implement `ProbabilityGridAdapter` cho BiCubicInterpolator - Complete với padding và grid data conversion
- [ ] Tests cho cost functions (có thể làm sau khi integrate vào CeresScanMatcher2D)

### Phase 3: CeresScanMatcher2D ✅
- [x] Complete `CeresScanMatcher2D.Match()` method - Complete với Problem setup, cost functions integration, và Solver
- [x] Initialize `SolverOptions` với DENSE_QR linear solver cho 2D scan matching
- [x] Integrate với `LocalTrajectoryBuilder2D` - Đã có integration, signature đã match
- [ ] Tests cho scan matching (có thể làm sau)

### Phase 4: OptimizationProblem2D ✅
- [x] Implement `SpaCostFunction2D.cs` - Complete với AutoDiffCostFunction, ComputeUnscaledError, ScaleError
- [x] Complete `OptimizationProblem2D.Solve()` method - Complete với Problem setup, parameter blocks, constraints, frozen trajectories
- [x] Handle frozen trajectories - Complete với SetParameterBlockConstant
- [x] Integrate với `PoseGraph2D.RunFinalOptimization()` - Complete với data sync
- [ ] Tests cho pose graph optimization (có thể làm sau)

### Phase 5: Integration ✅
- [x] Update `PoseGraph2D.RunFinalOptimization()` để gọi `OptimizationProblem2D.Solve()` - Complete với data sync và pose updates
- [ ] End-to-end tests (optional - có thể làm sau)
- [ ] Performance benchmarks (optional - có thể làm sau)

---

##Kết quả Mong đợi

Sau khi hoàn thành:

1. ✅ **CeresScanMatcher2D**: Fine alignment của scans với submap grids
2. ✅ **OptimizationProblem2D**: Global pose graph optimization với loop closure
3. ✅ **CartographerSharp**: Hoàn thiện Phase 3 (100%)

---

##Tài liệu Tham khảo

- `CERES_USAGE.md` - Chi tiết cách Ceres được sử dụng trong Cartographer
- `CERES_READINESS_EVALUATION.md` - Đánh giá mức độ sẵn sàng của CeresSharp
- `refs/cartographer/` - C++ source code reference
- [Ceres Solver Documentation](http://ceres-solver.org/)
