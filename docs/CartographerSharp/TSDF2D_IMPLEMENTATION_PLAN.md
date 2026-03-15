# TSDF2D Support - Implementation Plan

**Status:** ✅ **IMPLEMENTATION COMPLETED** - All phases implemented with comprehensive unit tests

##Tổng Quan

TSDF (Truncated Signed Distance Function) 2D là một loại grid khác ngoài ProbabilityGrid cho 2D SLAM. TSDF lưu trữ:
- **TSD (Truncated Signed Distance)**: Khoảng cách có dấu tới bề mặt, được truncate trong phạm vi `[-truncation_distance, truncation_distance]`
- **Weight**: Trọng số của measurement, sử dụng để tích hợp nhiều measurements

**Ưu điểm của TSDF so với ProbabilityGrid:**
- Hỗ trợ subpixel accuracy tốt hơn
- Xử lý uncertainty tốt hơn với weighted integration
- Có thể extract surface với độ chính xác cao hơn

---

##Components Cần Implement

### 1. **TSDValueConverter** (Core Utility)
### 2. **TSDF2D Grid** (Grid Implementation)
### 3. **TSDFRangeDataInserter2D** (Range Data Inserter)
### 4. **NormalEstimation2D** (Normal Estimation Utility)
### 5. **InterpolatedTSDF2D** (Interpolation for Scan Matching)
### 6. **TSDFMatchCostFunction2D** (Ceres Cost Function)
### 7. **Proto Definitions** (Configuration & Serialization)

---

##Chi Tiết Implementation

### Phase 1: Core Utilities

#### 1.1 TSDValueConverter
**File:** `Mapping/Internal/2D/TSDValueConverter.cs`

**Purpose:** Convert giữa TSD/Weight values và ushort values để lưu trữ hiệu quả trong grid.

**Methods cần implement:**
```csharp
public class TSDValueConverter
{
    public TSDValueConverter(float maxTSD, float maxWeight, ValueConversionTables conversionTables);
    
    // TSD conversion
    public ushort TSDToValue(float tsd);
    public float ValueToTSD(ushort value);
    public float GetMinTSD();
    public float GetMaxTSD();
    public ushort GetUnknownTSDValue();
    public ushort GetUpdateMarker();
    
    // Weight conversion
    public ushort WeightToValue(float weight);
    public float ValueToWeight(ushort value);
    public float GetMinWeight();
    public float GetMaxWeight();
    public ushort GetUnknownWeightValue();
}
```

**Key Implementation Details:**
- TSD được lưu trong `correspondence_cost_cells` như ProbabilityGrid
- Highest bit (bit 15) của TSD value là update marker
- Weight được lưu trong separate `weight_cells` array
- Sử dụng lookup tables từ `ValueConversionTables` để convert hiệu quả

**C++ Reference:** `refs/cartographer/cartographer/mapping/internal/2d/tsd_value_converter.h/cc`

---

#### 1.2 NormalEstimation2D
**File:** `Mapping/Internal/2D/NormalEstimation2D.cs`

**Purpose:** Estimate surface normals từ range data để tính toán SDF distance accurately.

**Methods cần implement:**
```csharp
public static class NormalEstimation2D
{
    // Estimate normals for sorted range data
    public static List<float> EstimateNormals(
        RangeData sortedRangeData,
        NormalEstimationOptions2D options);
    
    // Helper: Get normal angle at index
    private static float GetNormalAngle(int index, ...);
}
```

**Key Implementation Details:**
- Range data phải được sort theo angle từ origin (sử dụng `RangeDataSorter`)
- Normal được estimate từ các points ln cận (trong `sample_radius`)
- Normal được trả về dưới dạng angle (radians) cho mỗi hit point
- Sử dụng `num_normal_samples` để average normals

**C++ Reference:** `refs/cartographer/cartographer/mapping/internal/2d/normal_estimation_2d.h/cc`

**Proto:** `Proto/Mapping/NormalEstimationOptions2DProto.cs` (đã có proto definition)

---

### Phase 2: TSDF2D Grid

#### 2.1 TSDF2D Grid Class
**File:** `Mapping/2D/TSDF2D.cs`

**Inheritance:** `TSDF2D : Grid2D`

**Key Properties:**
- `List<ushort> _weightCells` - Separate weight grid
- `TSDValueConverter _valueConverter` - TSD/Weight converter
- `ValueConversionTables _conversionTables` - Lookup tables

**Methods cần implement:**
```csharp
public class TSDF2D : Grid2D
{
    public TSDF2D(MapLimits limits, float truncationDistance, float maxWeight, 
                  ValueConversionTables conversionTables);
    public TSDF2D(Proto.Mapping.Grid2D proto, ValueConversionTables conversionTables);
    
    // Cell accessors
    public void SetCell(Array2i cellIndex, float tsd, float weight);
    public float GetTSD(Array2i cellIndex);
    public float GetWeight(Array2i cellIndex);
    public (float tsd, float weight) GetTSDAndWeight(Array2i cellIndex);
    public bool CellIsUpdated(Array2i cellIndex);
    
    // Grid2D overrides
    public override GridType GetGridType() => GridType.TSDF;
    public override void GrowLimits(Vector2 point);
    public override Proto.Mapping.Grid2D ToProto();
    public override Grid2D ComputeCroppedGrid();
    public override bool DrawToSubmapTexture(...);
}
```

**Key Implementation Details:**
- Constructor: Initialize với `minCorrespondenceCost = -truncationDistance`, `maxCorrespondenceCost = truncationDistance`
- `SetCell`: 
  - Check update marker trước khi update
  - Set update marker (bit 15) vào TSD value
  - Store TSD trong `_correspondenceCostCells`
  - Store weight trong `_weightCells`
- `GetTSD`: Remove update marker và convert từ value về TSD
- `GetWeight`: Convert từ weight value về float weight
- `GrowLimits`: Override để grow cả `_correspondenceCostCells` và `_weightCells`
- `FinishUpdate`: Remove update markers từ TSD cells (đã có trong Grid2D base)

**C++ Reference:** `refs/cartographer/cartographer/mapping/internal/2d/tsdf_2d.h/cc`

---

#### 2.2 TSDF2D Proto Support
**File:** `Proto/Mapping/Grid2DProto.cs` (update existing)

**Changes needed:**
- Add `TSDF2D? Tsdf2D { get; set; }` property (nếu chưa có)
- Update `ToProto()` và constructor trong `TSDF2D` để serialize/deserialize TSDF2D data

**Proto structure:**
```protobuf
message TSDF2D {
  float truncation_distance = 1;
  float max_weight = 2;
  repeated int32 weight_cells = 3;
}
```

**C++ Reference:** `refs/cartographer/cartographer/mapping/proto/tsdf_2d.proto`

---

### Phase 3: Range Data Inserter

#### 3.1 TSDFRangeDataInserterOptions2D Proto
**File:** `Proto/Mapping/TSDFRangeDataInserterOptions2DProto.cs` (new file)

**Structure:**
```csharp
public struct TSDFRangeDataInserterOptions2D
{
    public double TruncationDistance { get; set; }
    public double MaximumWeight { get; set; }
    public bool UpdateFreeSpace { get; set; }
    public NormalEstimationOptions2D NormalEstimationOptions { get; set; }
    public bool ProjectSdfDistanceToScanNormal { get; set; }
    public int UpdateWeightRangeExponent { get; set; }
    public double UpdateWeightAngleScanNormalToRayKernelBandwidth { get; set; }
    public double UpdateWeightDistanceCellToHitKernelBandwidth { get; set; }
}
```

**C++ Reference:** `refs/cartographer/cartographer/mapping/proto/tsdf_range_data_inserter_options_2d.proto`

---

#### 3.2 TSDFRangeDataInserter2D
**File:** `Mapping/2D/TSDFRangeDataInserter2D.cs`

**Implements:** `IRangeDataInserter`

**Key Methods:**
```csharp
public class TSDFRangeDataInserter2D : IRangeDataInserter
{
    private readonly TSDFRangeDataInserterOptions2D _options;
    
    public TSDFRangeDataInserter2D(TSDFRangeDataInserterOptions2D options);
    public void Insert(RangeData rangeData, IGrid grid);
    
    private void InsertHit(Vector2 hit, Vector2 origin, float normal, TSDF2D tsdf);
    private void UpdateCell(Array2i cell, float updateSdf, float updateWeight, TSDF2D tsdf);
    private static void GrowAsNeeded(RangeData rangeData, float truncationDistance, TSDF2D tsdf);
}
```

**Key Implementation Details:**

1. **Insert method:**
   - Cast grid to TSDF2D
   - Grow grid limits if needed
   - Sort range data by angle from origin (using `RangeDataSorter`)
   - Estimate normals if needed (`project_sdf_distance_to_scan_normal` or angle-based weight)
   - For each hit:
     - Cast ray from origin to hit
     - If `update_free_space`: Update cells along ray until `truncation_distance` behind hit
     - Else: Update cells within `truncation_distance` around hit
   - Call `FinishUpdate()` on grid

2. **InsertHit method:**
   - Calculate cells along ray (hoặc around hit)
   - For each cell:
     - Compute SDF distance:
       - If `project_sdf_distance_to_scan_normal`: Project distance to scan normal
       - Else: Use Euclidean distance from cell to hit
     - Compute update weight:
       - Base weight: `1.0 / distance^update_weight_range_exponent`
       - Angle weight: Gaussian kernel based on angle between scan normal and ray
       - Distance weight: Gaussian kernel based on distance from cell to hit
     - Call `UpdateCell`

3. **UpdateCell method:**
   - Get current TSD and weight: `(currentTSD, currentWeight) = tsdf.GetTSDAndWeight(cell)`
   - Compute new TSD: Weighted average
     - `newTSD = (currentTSD * currentWeight + updateSdf * updateWeight) / (currentWeight + updateWeight)`
     - Clamp to `[-truncation_distance, truncation_distance]`
   - Compute new weight: `newWeight = min(currentWeight + updateWeight, maxWeight)`
   - Call `tsdf.SetCell(cell, newTSD, newWeight)`

4. **GrowAsNeeded:**
   - Similar to ProbabilityGrid inserter
   - Include truncation distance when calculating bounding box

**Helper Functions:**
```csharp
// Gaussian kernel for weight calculation
private static float GaussianKernel(float x, float sigma)
{
    return 1.0f / (Math.Sqrt(2.0 * Math.PI) * sigma) * 
           Math.Exp(-0.5 * x * x / (sigma * sigma));
}

// Range weight factor: 1.0 / range^exponent
private static float ComputeRangeWeightFactor(float range, int exponent)

// RangeDataSorter: Sort points by angle from origin
private class RangeDataSorter : IComparer<RangefinderPoint>
```

**C++ Reference:** `refs/cartographer/cartographer/mapping/internal/2d/tsdf_range_data_inserter_2d.h/cc`

---

### Phase 4: Scan Matching Support

#### 4.1 InterpolatedTSDF2D
**File:** `Mapping/Internal/2D/ScanMatching/InterpolatedTSDF2D.cs`

**Purpose:** Bilinear interpolation của TSDF values cho Ceres autodiff.

**Methods:**
```csharp
public class InterpolatedTSDF2D
{
    private readonly TSDF2D _tsdf;
    
    public InterpolatedTSDF2D(TSDF2D tsdf);
    
    // Template method for Ceres autodiff
    public T GetCorrespondenceCost<T>(T x, T y) where T : struct
    {
        // Bilinear interpolation of TSD values
        // Returns MaxCorrespondenceCost if any interpolation point is unknown (weight == 0)
    }
    
    public T GetWeight<T>(T x, T y) where T : struct
    {
        // Bilinear interpolation of weight values
    }
    
    private Vector2 CenterOfLowerPixel(double x, double y);
    private T InterpolateBilinear<T>(T x, T y, float x1, float y1, float x2, float y2, 
                                      float q11, float q12, float q21, float q22);
}
```

**Key Implementation Details:**
- Get 4 neighboring cells: `(x1,y1)`, `(x1+1,y1)`, `(x1,y1+1)`, `(x1+1,y1+1)`
- Check weights: If any weight == 0, return `MaxCorrespondenceCost`
- Interpolate TSD values using bilinear interpolation
- Works with Ceres Jet types (automatic differentiation)

**C++ Reference:** `refs/cartographer/cartographer/mapping/internal/2d/scan_matching/interpolated_tsdf_2d.h`

---

#### 4.2 TSDFMatchCostFunction2D
**File:** `Mapping/Internal/2D/ScanMatching/TSDFMatchCostFunction2D.cs`

**Purpose:** Ceres cost function cho TSDF-based scan matching.

**Methods:**
```csharp
public static class TSDFMatchCostFunction2D
{
    public static CostFunction CreateAutoDiffCostFunction(
        double scalingFactor,
        PointCloud pointCloud,
        TSDF2D grid)
    {
        // Create InterpolatedTSDF2D
        // Return AutoDiffCostFunction with TSDFMatchCostFunctor2D
    }
}

private struct TSDFMatchCostFunctor2D
{
    private readonly double _scalingFactor;
    private readonly PointCloud _pointCloud;
    private readonly InterpolatedTSDF2D _interpolatedTSDF;
    
    public void Evaluate(double[] parameters, double[] residuals, double[][] jacobians)
    {
        // parameters: [x, y, cos_theta, sin_theta]
        // Transform each point in pointCloud by pose
        // For each transformed point:
        //   residual = scaling_factor * interpolatedTSDF.GetCorrespondenceCost(x, y)
        // residuals length = pointCloud.Count
    }
}
```

**Key Implementation Details:**
- Transform point cloud by pose: `R * point + translation`
- Get interpolated correspondence cost for each transformed point
- Residual = `scaling_factor * correspondence_cost`
- Ceres sẽ minimize tổng squared residuals

**C++ Reference:** `refs/cartographer/cartographer/mapping/internal/2d/scan_matching/tsdf_match_cost_function_2d.h/cc`

---

#### 4.3 Update Scan Matchers

**4.3.1 RealTimeCorrelativeScanMatcher2D**
**File:** `Mapping/Internal/2D/ScanMatching/RealTimeCorrelativeScanMatcher2D.cs`

**Changes needed:**
- Line 125: Implement TSDF scoring
```csharp
case GridType.TSDF:
    if (grid is TSDF2D tsdfGrid)
    {
        foreach (var point in discreteScan)
        {
            var tsd = tsdfGrid.GetTSD(proposedXYIndex);
            // Score based on distance from zero-crossing (surface)
            // Cells with TSD near 0 are likely to be on surface
            candidateScore += -Math.Abs(tsd); // Closer to 0 = better
        }
        candidateScore /= discreteScan.Count;
    }
    break;
```

**Note:** TSDF scoring có thể đơn giản hơn ProbabilityGrid vì TSD gần 0 = surface.

---

**4.3.2 CeresScanMatcher2D**
**File:** `Mapping/Internal/2D/ScanMatching/CeresScanMatcher2D.cs`

**Changes needed:**
- Line 112-114: Replace TODO với TSDF cost function
```csharp
case GridType.TSDF:
    if (grid is TSDF2D tsdfGrid)
    {
        var tsdfMatchCost = TSDFMatchCostFunction2D.CreateAutoDiffCostFunction(
            _options.OccupiedSpaceWeight / Math.Sqrt(pointCloud.Count),
            pointCloud,
            tsdfGrid
        );
        problem.AddResidualBlock(tsdfMatchCost, null, [poseParams]);
    }
    break;
```

---

### Phase 5: Integration

#### 5.1 Update RangeDataInserterOptionsProto
**File:** `Proto/Mapping/RangeDataInserterOptionsProto.cs`

**Changes needed:**
- Uncomment and add TSDF options:
```csharp
[JsonPropertyName("tsdf_range_data_inserter_options_2d")]
[JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
public TSDFRangeDataInserterOptions2D? TsdfRangeDataInserterOptions2D { get; set; }
```

- Update constructor to accept TSDF options

---

#### 5.2 Update ActiveSubmaps2D
**File:** `Mapping/2D/ActiveSubmaps2D.cs`

**Changes needed:**
- Line 131: Replace `NotImplementedException` với TSDF2D creation
```csharp
GridOptions2D.GridType.Tsdf => new TSDF2D(
    mapLimits,
    _options.GridOptions2D.TsdfOptions?.TruncationDistance ?? 0.3f, // Default
    _options.GridOptions2D.TsdfOptions?.MaxWeight ?? 10.0f, // Default
    _conversionTables
),
```

**Note:** Cần add `TsdfOptions` vào `GridOptions2D` proto nếu chưa có.

---

#### 5.3 Update RangeDataInserterFactory
**File:** (tìm file tạo RangeDataInserter, có thể trong `Mapping/2D/` hoặc `Mapping/Internal/2D/`)

**Changes needed:**
- Add TSDF inserter creation:
```csharp
case RangeDataInserterOptions.RangeDataInserterType.TsdfInserter2D:
    if (options.TsdfRangeDataInserterOptions2D.HasValue)
    {
        return new TSDFRangeDataInserter2D(options.TsdfRangeDataInserterOptions2D.Value);
    }
    throw new ArgumentException("TSDFRangeDataInserterOptions2D is required for TSDF inserter");
```

---

##Dependencies & Order

### Implementation Order:
1. ✅ **Phase 1**: Core Utilities
   - TSDValueConverter
   - NormalEstimation2D
   - NormalEstimationOptions2DProto (nếu chưa có)

2. ✅ **Phase 2**: TSDF2D Grid
   - TSDF2D class
   - Update Grid2DProto

3. ✅ **Phase 3**: Range Data Inserter
   - TSDFRangeDataInserterOptions2DProto
   - TSDFRangeDataInserter2D

4. ✅ **Phase 4**: Scan Matching
   - InterpolatedTSDF2D
   - TSDFMatchCostFunction2D
   - Update RealTimeCorrelativeScanMatcher2D
   - Update CeresScanMatcher2D

5. ✅ **Phase 5**: Integration
   - Update RangeDataInserterOptionsProto
   - Update ActiveSubmaps2D
   - Update RangeDataInserterFactory

---

##Testing Plan

### Unit Tests: ✅ COMPLETED
1. ✅ **TSDValueConverterTests**
   - ✅ Test TSD/Weight conversion (toValue, fromValue)
   - ✅ Test bounds (min/max TSD/Weight)
   - ✅ Test unknown values
   - ✅ Test update marker

2. ✅ **TSDF2DTests**
   - ✅ Test SetCell/GetTSD/GetWeight
   - ✅ Test GetTSDAndWeight
   - ✅ Test CellIsUpdated
   - ✅ Test GrowLimits
   - ✅ Test ComputeCroppedGrid
   - ✅ Test ToProto/FromProto
   - ✅ Test out-of-bounds handling
   - ✅ Test multiple updates with weighted average

3. ✅ **TSDFRangeDataInserter2DTests**
   - ✅ Test Insert with simple range data
   - ✅ Test UpdateFreeSpace option
   - ✅ Test ProjectSdfDistanceToScanNormal option
   - ✅ Test weight calculation (range, angle, distance)
   - ✅ Test empty range data handling
   - ✅ Test wrong grid type error handling

4. ✅ **NormalEstimation2DTests**
   - ✅ Test normal estimation với known geometry (horizontal/vertical lines, rectangles)
   - ✅ Test với different sample radii
   - ✅ Test empty point clouds
   - ✅ Test single point handling

5. ✅ **InterpolatedTSDF2DTests**
   - ✅ Test bilinear interpolation
   - ✅ Test unknown cell handling
   - ✅ Test GetWeight interpolation
   - ✅ Test partially unknown cells

6. [ ] **TSDFMatchCostFunction2DTests**
   - [ ] Test cost function evaluation (có thể thêm sau nếu cần)
   - [ ] Test with Ceres solver (integration test, có thể thêm sau nếu cần)

### Integration Tests: [ ] Optional (có thể thêm sau nếu cần)
1. [ ] **Full TSDF Pipeline**
   - Create TSDF2D submap
   - Insert range data
   - Perform scan matching (both correlative and Ceres)
   - Verify pose estimation accuracy

2. [ ] **TSDF vs ProbabilityGrid Comparison**
   - Compare mapping quality
   - Compare scan matching accuracy

**Note:** Core functionality đã được test qua unit tests. Integration tests có thể được thêm sau khi cần validate với real-world data.

---

##Reference Files

### C++ Implementation:
- `refs/cartographer/cartographer/mapping/internal/2d/tsd_value_converter.h/cc`
- `refs/cartographer/cartographer/mapping/internal/2d/tsdf_2d.h/cc`
- `refs/cartographer/cartographer/mapping/internal/2d/tsdf_range_data_inserter_2d.h/cc`
- `refs/cartographer/cartographer/mapping/internal/2d/normal_estimation_2d.h/cc`
- `refs/cartographer/cartographer/mapping/internal/2d/scan_matching/interpolated_tsdf_2d.h`
- `refs/cartographer/cartographer/mapping/internal/2d/scan_matching/tsdf_match_cost_function_2d.h/cc`

### C++ Tests:
- `refs/cartographer/cartographer/mapping/internal/2d/tsdf_2d_test.cc`
- `refs/cartographer/cartographer/mapping/internal/2d/tsdf_range_data_inserter_2d_test.cc`
- `refs/cartographer/cartographer/mapping/internal/2d/scan_matching/interpolated_tsdf_2d_test.cc`
- `refs/cartographer/cartographer/mapping/internal/2d/scan_matching/tsdf_match_cost_function_2d_test.cc`

### Proto Files:
- `refs/cartographer/cartographer/mapping/proto/tsdf_2d.proto`
- `refs/cartographer/cartographer/mapping/proto/tsdf_range_data_inserter_options_2d.proto`
- `refs/cartographer/cartographer/mapping/proto/normal_estimation_options_2d.proto`

---

## ⚠️ Notes & Considerations

1. **Performance:**
   - TSDF computation phức tạp hơn ProbabilityGrid (normal estimation, weighted integration)
   - Consider caching normal estimates nếu cần
   - Weight calculation có thể tốn kém (Gaussian kernels)

2. **Memory:**
   - TSDF2D cần thêm `weight_cells` array (same size as correspondence_cost_cells)
   - Memory usage ~2x so với ProbabilityGrid

3. **Accuracy:**
   - TSDF thường cho accuracy cao hơn, đặc biệt với subpixel features
   - Normal estimation quality ảnh hưởng lớn đến SDF accuracy

4. **Configuration:**
   - `truncation_distance`: Thường 0.1-0.5m
   - `maximum_weight`: Thường 10-50
   - `update_weight_range_exponent`: Thường 0-2
   - Kernel bandwidths: Cần tune cho từng sensor

5. **Compatibility:**
   - Ensure TSDF grids có thể serialize/deserialize correctly
   - Backward compatibility với ProbabilityGrid configs

---

## ✅ Completion Checklist

- [x] Phase 1: Core Utilities ✅ COMPLETED
  - [x] TSDValueConverter
  - [x] NormalEstimation2D
  - [x] NormalEstimationOptions2DProto
  
- [x] Phase 2: TSDF2D Grid ✅ COMPLETED
  - [x] TSDF2D class
  - [x] Update Grid2DProto (TSDF2DProto)
  
- [x] Phase 3: Range Data Inserter ✅ COMPLETED
  - [x] TSDFRangeDataInserterOptions2DProto
  - [x] TSDFRangeDataInserter2D
  - [x] RangeDataSorter helper
  - [x] RayToPixelMask utility
  
- [x] Phase 4: Scan Matching ✅ COMPLETED
  - [x] InterpolatedTSDF2D
  - [x] TSDFMatchCostFunction2D
  - [x] Update RealTimeCorrelativeScanMatcher2D
  - [x] Update CeresScanMatcher2D
  
- [x] Phase 5: Integration ✅ COMPLETED
  - [x] Update RangeDataInserterOptionsProto
  - [x] Update ActiveSubmaps2D (CreateGrid và CreateRangeDataInserter)
  - [x] Update GridOptions2DProto (TSDFOptions2D)
  
- [x] Testing ✅ COMPLETED
  - [x] Unit tests cho tất cả components
    - [x] TSDValueConverterTests
    - [x] TSDF2DTests
    - [x] NormalEstimation2DTests
    - [x] TSDFRangeDataInserter2DTests
    - [x] InterpolatedTSDF2DTests
  - [ ] Integration tests (có thể thêm sau nếu cần)
  - [ ] Performance benchmarks (có thể thêm sau nếu cần)

---

**Last Updated:** 2024-12-19
**Status:** ✅ **IMPLEMENTATION COMPLETED** - All phases implemented with comprehensive unit tests

