# Cartographer Parameters Guide — Hướng dẫn Tham số và Tuning

Bảng tham số đầy đủ cho CartographerSharp, kèm hướng dẫn tuning cho môi trường nhà máy (AMR use case).

> [!NOTE]
> Tham số được chia theo 3 nhóm: Local SLAM, Global SLAM, và Sensor.
> Giá trị mẫu dựa trên paper gốc và thực nghiệm trên AMR T800.

---

## 1. Local SLAM — TrajectoryBuilder2DOptions

### 1.1 Sensor Input

| Tham số | Giá trị mẫu | Mô tả | Tuning cho nhà máy |
|---------|-------------|-------|-------------------|
| `MinRange` | 0.3 m | Bỏ scan points quá gần sensor | Tăng nếu thấy "thn robot" (0.5-1.0 m cho AMR) |
| `MaxRange` | 30.0 m | Bỏ scan points quá xa | Giảm xuống 15-20 m trong nhà máy (giảm noise xa) |
| `MissingDataRayLength` | 5.0 m | Chiều dài ray khi không có return | Giữ mặc định |
| `MinZ` | -0.8 m | Giới hạn chiều cao dưới (3D→2D) | Điều chỉnh theo chiều cao mount LiDAR |
| `MaxZ` | 2.0 m | Giới hạn chiều cao trên | Loại bỏ trần nhà, đèn treo |
| `UseImu` | true | Sử dụng IMU data | Luôn `true` nếu có IMU — cải thiện rotation estimate |
| `UseOdometry` | true | Sử dụng odometry data | `true` cho AMR — wheel encoder available |

### 1.2 Voxel Filter

| Tham số | Giá trị mẫu | Mô tả | Tuning |
|---------|-------------|-------|--------|
| `VoxelFilterSize` | 0.025 m | Kích thước voxel lọc point cloud | 0.025: chi tiết cao, CPU cao. 0.05: cn bằng. 0.1: nhanh nhưng thô |
| `AdaptiveVoxelFilterMaxLength` | 0.9 m | Kích thước voxel tối đa (adaptive) | Tăng nếu cần giảm CPU |
| `AdaptiveVoxelFilterMinNumPoints` | 100 | Số điểm tối thiểu sau filter | Giảm nếu LiDAR thưa |

> [!TIP]
> Với AMR trong nhà máy, `VoxelFilterSize = 0.05` thường là lựa chọn tốt:
> cn bằng giữa chi tiết bản đồ và hiệu năng real-time.

### 1.3 Real-Time Correlative Scan Matcher (CSM)

| Tham số | Giá trị mẫu | Mô tả | Tuning |
|---------|-------------|-------|--------|
| `UseOnlineCorrelativeScanMatching` | false | Bật CSM trước Ceres | `true` nếu không có IMU hoặc odometry kém |
| `LinearSearchWindow` | 0.1 m | Cửa sổ tìm kiếm tịnh tiến | Tăng nếu predicted pose kém (0.2-0.5 m) |
| `AngularSearchWindow` | 20° | Cửa sổ tìm kiếm xoay | Tăng nếu không có IMU |

> [!WARNING]
> CSM là brute-force — chi phí tính toán tỉ lệ với `window_size`.
> Chỉ bật khi thực sự cần (IMU kém hoặc khởi động lại từ vị trí không xác định).

### 1.4 Ceres Scan Matcher

| Tham số | Giá trị mẫu | Mô tả | Tuning cho nhà máy |
|---------|-------------|-------|-------------------|
| `OccupiedSpaceWeight` | 1.0 | Trọng số khớp bản đồ | Tăng → ưu tiên khớp scan với map (có thể trượt dọc hành lang) |
| `TranslationWeight` | 10.0 | Trọng số tin vào predicted position | Tăng → robot "bám" vào odometry hơn |
| `RotationWeight` | 40.0 | Trọng số tin vào predicted rotation | Tăng cao nếu IMU tốt (giữ hướng ổn định) |

**Công thức cost function:**

```
J = w_occ × Σ(1 - M_smooth(T_ξh_k))  + w_trans × ||t_ξ - t_predicted||  + w_rot × ||θ_ξ - θ_predicted||```

**Hướng dẫn cn chỉnh:**

| Tình huống | OccupiedSpaceWeight | TranslationWeight | RotationWeight |
|-----------|--------------------|--------------------|----------------|
| Hành lang dài, ít features | 1.0 | **20.0** (tăng) | 40.0 |
| Nhiều vật thể, features phong phú | **2.0** (tăng) | 10.0 | 40.0 |
| IMU chất lượng cao | 1.0 | 10.0 | **80.0** (tăng) |
| Không có IMU | 1.0 | 10.0 | **5.0** (giảm) |
| Sàn trơn, odometry trượt | **2.0** (tăng) | **5.0** (giảm) | 40.0 |

### 1.5 Submap

| Tham số | Giá trị mẫu | Mô tả | Tuning |
|---------|-------------|-------|--------|
| `NumRangeData` | 90 | Số scans trước khi hoàn thành submap | Giảm → submaps nhỏ hơn, nhiều hơn, loop closure nhanh hơn |
| `GridOptions.Resolution` | 0.05 m | Resolution bản đồ | 0.05 cho navigation. 0.02-0.03 cho bản đồ chi tiết |
| `RangeDataInserterOptions.HitProbability` | 0.55 | Xác suất cập nhật cho hit | Tăng → tin scan hơn (map update nhanh hơn) |
| `RangeDataInserterOptions.MissProbability` | 0.49 | Xác suất cập nhật cho miss | Giảm → xóa vật cản nhanh hơn (dynamic env) |

> [!IMPORTANT]
> `HitProbability` phải > 0.5, `MissProbability` phải < 0.5.
> Nếu ngược lại, map sẽ không hội tụ.

---

## 2. Global SLAM — PoseGraphOptions

### 2.1 Optimization

| Tham số | Giá trị mẫu | Mô tả | Tuning |
|---------|-------------|-------|--------|
| `OptimizeEveryNNodes` | 90 | Chạy optimization sau N nodes | 0 = tắt Global SLAM. Giảm → chạy thường xuyên (CPU cao) |
| `HuberScale` | 1e1 | Scale cho Huber loss | Giảm → khắt khe hơn với outliers |
| `MaxNumFinalIterations` | 200 | Số iterations tối đa cho final optimization | Giữ mặc định |

### 2.2 Constraint Builder

| Tham số | Giá trị mẫu | Mô tả | Tuning cho nhà máy |
|---------|-------------|-------|-------------------|
| `MinScore` | 0.55 | Ngưỡng score cho loop closure | **0.6-0.65** cho nhà máy (giảm false positive) |
| `GlobalLocalizationMinScore` | 0.6 | Ngưỡng cho global localization | Tăng nếu nhiều khu vực giống nhau |
| `SamplingRatio` | 0.3 | Tỉ lệ nodes check loop closure | 1.0 = check hết (chậm). 0.1 = 10% (nhanh nhưng bỏ sót) |
| `MaxConstraintDistance` | 15.0 m | Khoảng cách tối đa cho constraint | Giảm trong nhà máy nhỏ (5-10 m) |
| `LoopClosureTranslationWeight` | 1.1e4 | Trọng số translation constraint | Tăng → constraints mạnh hơn |
| `LoopClosureRotationWeight` | 1e5 | Trọng số rotation constraint | Tăng → constraints mạnh hơn |

### 2.3 Fast Correlative Scan Matcher (Loop Closure)

| Tham số | Giá trị mẫu | Mô tả | Tuning |
|---------|-------------|-------|--------|
| `LinearSearchWindow` | 7.0 m | Cửa sổ tìm kiếm tịnh tiến | Giảm cho nhà máy nhỏ (3-5 m) → nhanh hơn |
| `AngularSearchWindow` | 30° | Cửa sổ tìm kiếm xoay | Giữ mặc định |
| `BranchAndBoundDepth` | 7 | Độ su B&B tree | Giảm → nhanh hơn nhưng less accurate |

> [!WARNING]
> Search window lớn = thời gian matching tăng theo bình phương.
> Trong nhà máy, AMR hiếm khi drift > 3 m → giảm window giúp performance đáng kể.

---

## 3. Sensor Options

### 3.1 LiDAR

| Tham số | Giá trị khuyến nghị | Ghi chú |
|---------|-------------------|---------|
| Scan rate | 5-20 Hz | Lý tưởng cho real-time. > 100 Hz sẽ nghẽn queue |
| Range | 0.3-25 m | AMR indoor: 15-20 m là đủ |
| Angular resolution | 0.25-1° | Càng nhỏ càng chi tiết, nhưng nhiều points hơn |

### 3.2 IMU

| Tham số | Giá trị khuyến nghị | Ghi chú |
|---------|-------------------|---------|
| Rate | 100-200 Hz | Đủ cho rotation estimation |
| Gravity estimate | Required | Dùng cho 3D→2D projection |

### 3.3 Odometry

| Tham số | Giá trị khuyến nghị | Ghi chú |
|---------|-------------------|---------|
| Rate | 20-50 Hz | Khớp với IPC cycle (AMR: 50 Hz) |
| Source | Wheel encoder | AMR T800 sử dụng CSV mode encoder feedback |

---

## 4. Tuning Profiles cho AMR T800

### Profile 1: Navigation (Localization mode)

Ưu tiên: tốc độ pose estimation, ổn định, CPU thấp.

```
# Local SLAM
MinRange = 0.5           # Loại bỏ thn robot
MaxRange = 15.0          # Nhà máy indoor
VoxelFilterSize = 0.05   # Cn bằng
UseImu = true
UseOdometry = true
UseOnlineCorrelativeScanMatching = false  # Đã có odometry tốt

# Ceres Scan Matcher
OccupiedSpaceWeight = 1.0
TranslationWeight = 10.0
RotationWeight = 40.0

# Submap
NumRangeData = 90
Resolution = 0.05

# Global SLAM
OptimizeEveryNNodes = 0  # TẮT — dùng map có sẵn, không cần optimize
```

### Profile 2: Mapping (ScanMapping mode)

Ưu tiên: chất lượng bản đồ, loop closure chính xác.

```
# Local SLAM
MinRange = 0.5
MaxRange = 20.0          # Xa hơn để bắt features
VoxelFilterSize = 0.025  # Chi tiết hơn
UseImu = true
UseOdometry = true
UseOnlineCorrelativeScanMatching = false

# Ceres Scan Matcher
OccupiedSpaceWeight = 1.0
TranslationWeight = 10.0
RotationWeight = 40.0

# Submap
NumRangeData = 60        # Submaps nhỏ hơn → loop closure nhanh hơn
Resolution = 0.05

# Global SLAM
OptimizeEveryNNodes = 30  # Optimize thường xuyên
MinScore = 0.60           # Khắt khe hơn
SamplingRatio = 0.5       # Check nhiều hơn
LinearSearchWindow = 5.0  # Nhà máy
AngularSearchWindow = 30
```

### Profile 3: High-Performance (Hành lang dài)

Ưu tiên: chống drift trong hành lang dài, ít features.

```
# Local SLAM
MinRange = 0.5
MaxRange = 25.0           # Bắt features xa hơn
VoxelFilterSize = 0.025
UseImu = true
UseOdometry = true
UseOnlineCorrelativeScanMatching = true  # BẬT — hành lang cần CSM
LinearSearchWindow = 0.2
AngularSearchWindow = 20

# Ceres Scan Matcher
OccupiedSpaceWeight = 1.0
TranslationWeight = 20.0  # Tăng — bám odometry trong hành lang
RotationWeight = 40.0

# Submap
NumRangeData = 45         # Submaps nhỏ — loop closure sớm hơn
Resolution = 0.05

# Global SLAM
OptimizeEveryNNodes = 20
MinScore = 0.55           # Hạ — hành lang ít features → score thấp hơn
SamplingRatio = 0.8       # Check nhiều
LinearSearchWindow = 7.0
```

---

## 5. Mapping: Lua Config ↔ CartographerSharp C#

Google Cartographer gốc dùng Lua config files. CartographerSharp dùng C# options classes.

| Lua config path | C# property path | Type |
|----------------|------------------|------|
| `TRAJECTORY_BUILDER_2D.min_range` | `TrajectoryBuilder2DOptions.MinRange` | double |
| `TRAJECTORY_BUILDER_2D.max_range` | `TrajectoryBuilder2DOptions.MaxRange` | double |
| `TRAJECTORY_BUILDER_2D.voxel_filter_size` | `TrajectoryBuilder2DOptions.VoxelFilterSize` | double |
| `TRAJECTORY_BUILDER_2D.use_imu_data` | `TrajectoryBuilder2DOptions.UseImu` | bool |
| `TRAJECTORY_BUILDER_2D.ceres_scan_matcher.occupied_space_weight` | `CeresScanMatcherOptions2D.OccupiedSpaceWeight` | double |
| `TRAJECTORY_BUILDER_2D.ceres_scan_matcher.translation_weight` | `CeresScanMatcherOptions2D.TranslationWeight` | double |
| `TRAJECTORY_BUILDER_2D.ceres_scan_matcher.rotation_weight` | `CeresScanMatcherOptions2D.RotationWeight` | double |
| `TRAJECTORY_BUILDER_2D.submaps.num_range_data` | `SubmapOptions2D.NumRangeData` | int |
| `TRAJECTORY_BUILDER_2D.submaps.grid_options_2d.resolution` | `GridOptions2D.Resolution` | double |
| `TRAJECTORY_BUILDER_2D.submaps.range_data_inserter.hit_probability` | `RangeDataInserterOptions.HitProbability` | double |
| `TRAJECTORY_BUILDER_2D.submaps.range_data_inserter.miss_probability` | `RangeDataInserterOptions.MissProbability` | double |
| `POSE_GRAPH.optimize_every_n_nodes` | `PoseGraphOptions.OptimizeEveryNNodes` | int |
| `POSE_GRAPH.constraint_builder.min_score` | `ConstraintBuilderOptions.MinScore` | double |
| `POSE_GRAPH.constraint_builder.sampling_ratio` | `ConstraintBuilderOptions.SamplingRatio` | double |
| `POSE_GRAPH.constraint_builder.fast_correlative_scan_matcher.linear_search_window` | `FastCorrelativeScanMatcherOptions2D.LinearSearchWindow` | double |
| `POSE_GRAPH.constraint_builder.fast_correlative_scan_matcher.angular_search_window` | `FastCorrelativeScanMatcherOptions2D.AngularSearchWindow` | double |
| `POSE_GRAPH.constraint_builder.fast_correlative_scan_matcher.branch_and_bound_depth` | `FastCorrelativeScanMatcherOptions2D.BranchAndBoundDepth` | int |

> [!NOTE]
> Khi tham khảo Cartographer tuning guides online (ROS wiki, GitHub issues), convert Lua paths sang C# properties theo bảng trên.
> CartographerSharp property names match gần như 1:1, chỉ khác naming convention (snake_case → PascalCase).

---

## 6. Troubleshooting nhanh

| Vấn đề | Tham số điều chỉnh | Hướng |
|--------|-------------------|-------|
| Map bị lệch theo thời gian | `OptimizeEveryNNodes` | Giảm (chạy optimize thường xuyên hơn) |
| Loop closure sai (ghost walls) | `MinScore` | Tăng (0.6 → 0.7) |
| Loop closure bỏ sót | `MinScore`, `SamplingRatio` | Giảm MinScore, tăng SamplingRatio |
| Scan matching chậm (> 50 ms) | `VoxelFilterSize`, `MaxRange` | Tăng VoxelFilter, giảm MaxRange |
| Map "nhòe" (blurry) | `VoxelFilterSize`, `Resolution` | Giảm cả hai |
| Robot "trượt" dọc hành lang | `TranslationWeight` | Tăng (20-30) |
| Robot xoay sai hướng | `RotationWeight`, `UseImu` | Tăng RotationWeight, verify IMU |
| CPU quá cao | `SamplingRatio`, `NumRangeData` | Giảm SamplingRatio, tăng NumRangeData |
| Memory tăng liên tục | Trimmer options | Enable trimmer, giới hạn active submaps |

---

## Tài liệu liên quan

- [cartographer-slam-reference.md](cartographer-slam-reference.md) — Tổng quan thuật toán và kiến trúc
- [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) — Hướng dẫn kỹ thuật chuyên su
- [ASSESSMENT.md](ASSESSMENT.md) — Đánh giá chất lượng source code

---

*Biên soạn từ paper gốc + Cartographer docs + CartographerSharp source. Cập nhật: 2026-03.*
