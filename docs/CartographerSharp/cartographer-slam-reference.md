# Google Cartographer SLAM — Tài liệu Tham khảo

Tổng hợp từ paper gốc, source code C++ gốc, và CartographerSharp C# port.

> [!NOTE]
> Tài liệu này dành cho developer làm việc trên CartographerSharp trong RobotNet10.
> Mục tiêu: hiểu thuật toán gốc để debug, tuning, và mở rộng bản port C#.

**Nguồn chính:**
- Paper: "Real-Time Loop Closure in 2D LIDAR SLAM" (Hess, Kohler, Rapp, Andor — Google, 2016)
- Source: `cartographer-master/` (C++ gốc, 481 files)
- Port: `CartographerSharp/` (C# .NET 10, 162 files)

---

## 1. Tổng quan kiến trúc

Cartographer sử dụng kiến trúc **2 tầng** tách biệt Local SLAM (frontend) và Global SLAM (backend):

```
┌─────────────────────────────────────────────────────────┐
│                    SENSOR INPUT                         │
│              LiDAR scans + IMU + Odometry               │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│              LOCAL SLAM (Frontend)                       │
│                                                         │
│  1. Voxel Filter (downsampling)                         │
│  2. Pose Extrapolation (IMU/Odom/constant velocity)     │
│  3. Scan Matching (CSM → Ceres refinement)              │
│  4. Submap insertion (probability grid update)           │
│                                                         │
│  Output: local pose + node cho pose graph               │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│              GLOBAL SLAM (Backend)                       │
│                                                         │
│  1. Constraint building (scan-to-submap matching)       │
│  2. Loop closure detection (Branch & Bound)             │
│  3. Pose graph optimization (Ceres solver, SPA)         │
│                                                         │
│  Output: globally consistent poses                      │
└─────────────────────────────────────────────────────────┘
```

### Tại sao kiến trúc này quan trọng cho AMR

- **Local SLAM** chạy real-time (5-20 Hz), đảm bảo pose estimation liên tục cho navigation
- **Global SLAM** chạy background, sửa drift tích lũy mà không block control loop
- Tách biệt cho phép tune riêng: Local SLAM ưu tiên tốc độ, Global SLAM ưu tiên chính xác

---

## 2. Local SLAM — Chi tiết thuật toán

### 2.1 Scan representation

Mỗi scan là tập hợp điểm `H = {h_k}` trong tọa độ sensor. Pose `ξ = (ξ_x, ξ_y, ξ_θ)` biến đổi scan points vào tọa độ submap:

```
T_ξ p = R_ξ p + t_ξ
```

Trong đó `R_ξ` là ma trận xoay 2D, `t_ξ` là vector tịnh tiến.

### 2.2 Submap và Probability Grid

Submaps là **probability grids** rời rạc với resolution `r` (mặc định 5 cm):

```
M : rZ × rZ → [p_min, p_max]
```

Mỗi cell lưu xác suất có vật cản. Khi insert scan:
- **Hit points**: grid point gần nhất với scan point → tăng xác suất
- **Miss points**: grid points trên ray từ origin đến scan point → giảm xác suất

Cập nhật dùng **odds representation**:

```
odds(p) = p / (1 - p)
M_new(x) = clamp(odds⁻¹(odds(M_old(x)) odds(p_hit)))
```

> [!IMPORTANT]
> Odds update là phép nhân, không phải cộng — đây là Bayesian update.
> Trong CartographerSharp: xem `ProbabilityGrid` class và `ProbabilityValues` utility.

### 2.3 Active Submaps

Hệ thống duy trì **2 submaps đồng thời**:

| Submap | Trạng thái | Vai trò |
|--------|-----------|---------|
| Old Submap | Đang hoàn thiện | Dùng cho scan matching (ổn định hơn) |
| New Submap | Đang xây dựng | Đảm bảo continuity khi Old hoàn thành |

Khi Old Submap đủ scans → trở thành "finished" → tham gia loop closure → New Submap thành Old → tạo New Submap mới.

### 2.4 Scan Matching — Chiến lược 2 bước

**Bước 1: Real-Time Correlative Scan Matcher (CSM)**

- Brute-force search trong search window nhỏ xung quanh predicted pose
- Thử tất cả `(Δx, Δy, Δθ)` combinations, tính score = tổng probability tại scan points
- Mạnh mẽ, tránh local minima
- Chậm nếu window lớn → chỉ dùng cho local matching

**Bước 2: Ceres Scan Matcher (refinement)**

Tối ưu phi tuyến (Non-linear Least Squares):

```
argmin_ξ Σ_k (1 - M_smooth(T_ξ h_k))```

- `M_smooth`: bicubic interpolation của probability grid → cho phép sub-pixel accuracy
- Cost function bao gồm:
  - **Map term**: scan points phải khớp vùng có xác suất cao
  - **Translation weight**: penalty cho deviation từ predicted position
  - **Rotation weight**: penalty cho deviation từ predicted orientation (IMU)

> [!NOTE]
> Trong CartographerSharp:
> - `RealTimeCorrelativeScanMatcher2D` → Bước 1
> - `CeresScanMatcher2D` → Bước 2 (qua CeresSharp interop)
> - `FastCorrelativeScanMatcher2D` → Dùng cho loop closure (xem Section 3)

### 2.5 Pose Extrapolation

`PoseExtrapolator` dự đoán pose trước khi scan matching:

| Input | Dùng cho | Độ chính xác |
|-------|---------|-------------|
| IMU | Rotation (gravity direction) | Cao |
| Odometry | Translation | Trung bình |
| Constant velocity model | Cả hai (fallback) | Thấp |

Thứ tự ưu tiên: IMU rotation > Odometry translation > Constant velocity.

---

## 3. Global SLAM — Loop Closure

### 3.1 Vấn đề drift

Local SLAM tích lũy error theo thời gian. Với vài chục scans liên tiếp, error nhỏ. Nhưng sau hàng trăm scans qua không gian lớn, drift đáng kể.

### 3.2 Constraint types

| Type | Mô tả | Khi nào tạo |
|------|--------|-------------|
| Intra-submap | Ràng buộc giữa node và submap chứa nó | Tự động khi insert scan |
| Inter-submap (Loop closure) | Ràng buộc giữa node và submap cũ | Khi phát hiện revisit location |

### 3.3 Branch-and-Bound Scan Matching (B&B)

Đy là **đóng góp chính** của paper — cho phép loop closure real-time.

**Bài toán:** Tìm pose tối ưu `ξ*` maximize tổng probability:

```
ξ* = argmax_{ξ ∈ W} Σ_k M_nearest(T_ξ h_k)
```

**Naive approach:** Thử tất cả poses trong search window → O(w_x × w_y × w_θ × K) — quá chậm.

**B&B approach:**

1. Chia search space thành tree: root = toàn bộ window, leaf = single pose
2. Mỗi inner node có **upper bound** score (tính nhanh qua precomputed grids)
3. DFS với pruning: nếu upper bound < best score hiện tại → cắt nhánh

**Precomputed grids** — chìa khóa hiệu năng:

```
M^h_precomp(x, y) = max{M_nearest(x', y') : x' ∈ [x, x+r(2^h-1)], y' ∈ [y, y+r(2^h-1)]}
```

- Mỗi level `h`: lưu maximum probability trong vùng `2^h × 2^h` pixels
- Tính trong O(n) qua sliding window maximum (deque-based)
- Cho phép tính upper bound của inner node trong O(K) — linear theo số scan points

**Angular step size** được chọn để scan points ở `d_max` không di chuyển quá 1 pixel:

```
δ_θ = arccos(1 - r/ (2 d_max))
```

> [!IMPORTANT]
> Trong CartographerSharp: `FastCorrelativeScanMatcher2D` implement B&B.
> `PrecomputationGrid2D` implement precomputed grids.
> Performance constraint: loop closure matching phải nhanh hơn tốc độ thêm scan mới.

### 3.4 Pose Graph Optimization (SPA)

Sau khi có constraints, giải bài toán tối ưu Sparse Pose Adjustment:

```
argmin_{Ξ^m, Ξ^s} (1/2) Σ_{ij} ρ(E(ξ^m_i, ξ^s_j; Σ_ij, ξ_ij))
```

- `Ξ^m`: poses của tất cả submaps
- `Ξ^s`: poses của tất cả scans
- `ξ_ij`: relative pose constraint (từ scan matching)
- `Σ_ij`: covariance matrix
- `ρ`: Huber loss — giảm ảnh hưởng của false positive constraints

Chạy mỗi vài giy qua Ceres solver. Typical: ~3 iterations, ~0.3s.

> [!NOTE]
> Huber loss rất quan trọng — trong thực nghiệm, loop closure precision dao động 77-99%.
> Không có Huber loss, false positives sẽ kéo map sai lệch nghiêm trọng.

---

## 4. Mapping từ Paper sang CartographerSharp

### 4.1 Class mapping

| Paper concept | C++ class | CartographerSharp class |
|--------------|-----------|----------------------|
| MapBuilder | `MapBuilder` | `MapBuilder` : `IMapBuilder` |
| TrajectoryBuilder | `LocalTrajectoryBuilder2D` | `LocalTrajectoryBuilder2D` : `ITrajectoryBuilder` |
| Submap | `Submap2D` | `Submap2D` |
| Probability Grid | `ProbabilityGrid` | `ProbabilityGrid` |
| CSM (local) | `RealTimeCorrelativeScanMatcher2D` | `RealTimeCorrelativeScanMatcher2D` |
| B&B (loop closure) | `FastCorrelativeScanMatcher2D` | `FastCorrelativeScanMatcher2D` |
| Ceres Scan Matcher | `CeresScanMatcher2D` | `CeresScanMatcher2D` |
| Pose Graph | `PoseGraph2D` | `PoseGraph2D` : `IPoseGraph` |
| Precomputed Grid | `PrecomputationGrid2D` | `PrecomputationGrid2D` |
| Pose Extrapolator | `PoseExtrapolator` | `PoseExtrapolator` |

### 4.2 Khác biệt chính C++ → C#

| Aspect | C++ (gốc) | CartographerSharp (port) |
|--------|----------|------------------------|
| Serialization | Protocol Buffers | System.Text.Json + .pbstream compatibility |
| Memory | Raw pointers, RAII | SafeHandle (CeresSharp), GC |
| Math | Eigen | System.Numerics.Vector3 + custom |
| Concurrency | std::mutex, std::thread | Lock (spin lock), Task, Thread |
| Performance-critical | Templates, inline | `unsafe` blocks, Span\<T\>, SIMD |
| Config | Proto messages (Lua wrapper) | C# options classes |

### 4.3 Namespace mapping

```
cartographer::mapping           → CartographerSharp.Mapping
cartographer::mapping::internal → CartographerSharp.Mapping.Internal  (private)
cartographer::sensor            → CartographerSharp.Sensor
cartographer::common            → CartographerSharp.Common
cartographer::io                → CartographerSharp.IO
```

---

## 5. Integration trong RobotNet10

### 5.1 Kiến trúc 3 tầng

```
CartographerSharp (lib, 162 files)     ← SLAM core
    └── CeresSharp (lib, 53 files)     ← Ceres solver (native interop)
         └── RobotApp/SLAM/ (47 files) ← Integration layer
              ├── CartographerService  ← State machine (Idle → Ready → Localizing/ScanMapping)
              ├── LocalizationService  ← Định vị từ map có sẵn
              ├── ScanMappingService   ← Tạo map mới
              ├── MapStorageService    ← Lưu/load map (.pbstream, .pgm, .png)
              └── OccupancyGridProvider ← Cung cấp occupancy grid cho navigation
```

### 5.2 Sensor pipeline trong RobotApp

```
LiDAR driver (Olei/SICK)
    → LidarDataAdapter
    → CartographerSensorManager.SetTrajectoryBuilder()
    → MapBuilder.AddSensorData()
    → LocalTrajectoryBuilder2D
    → Scan matching + submap update
    → PoseGraph2D (background)
```

IMU và Odometry follow tương tự qua `ImuDataAdapter` và `OdometryDataAdapter`.

### 5.3 State machine flow

```
CartographerService: Idle → Initializing → Ready → Localizing (dùng map)
                                                 → ScanMapping (tạo map)
```

Chi tiết state machine: xem `docs/Localization/Localization_Services_Architecture.md`

---

## 6. Hiệu năng và giới hạn

### 6.1 Benchmark từ paper

| Test case | Data duration | Wall clock | Real-time factor |
|-----------|-------------|-----------|-----------------|
| Deutsches Museum | 1,913 s | 360 s | 5.3x |
| Aces | 1,366 s | 41 s | 33x |
| Intel | 2,691 s | 179 s | 15x |
| MIT Killian Court | 7,678 s | 190 s | 40x |

### 6.2 Loop closure precision

| Test case | Constraints | Precision |
|-----------|------------|-----------|
| Aces | 971 | 98.1% |
| Intel | 5,786 | 97.2% |
| Freiburg bldg 79 | 412 | 99.8% |
| Freiburg hospital | 554 | 77.3% |

### 6.3 Giới hạn quan trọng cho AMR

| Giới hạn | Tác động | Cách xử lý |
|----------|---------|-----------|
| Scan matching < 50 ms | Block navigation nếu chậm hơn | Tune VoxelFilterSize, giảm MaxRange |
| Memory tăng theo map size | Precomputed grids × số submaps | Trimmer giới hạn active submaps |
| False positive loop closure | Map corruption | Tune MinScore, Huber loss |
| CeresSharp native crash | Process crash (không phải exception) | SafeHandle, validate P/Invoke |

---

## 7. Điểm cần lưu ý khi debug/tune

### 7.1 Triệu chứng và nguyên nhân phổ biến

| Triệu chứng | Nguyên nhân có thể | Kiểm tra |
|-------------|-------------------|---------|
| Map bị "rách" hoặc lệch | Scan matching thất bại (local minima) | Tăng CSM search window, kiểm tra IMU |
| Drift dần sau khi đi xa | Loop closure không kích hoạt | Kiểm tra MinScore threshold, sampling ratio |
| Map có "bóng ma" (ghost) | False positive loop closure | Tăng MinScore, kiểm tra Huber loss weight |
| CPU quá cao | Precomputed grids lớn hoặc search window rộng | Giảm search window, tăng VoxelFilterSize |
| Robot "nhảy" vị trí đột ngột | Optimization kéo pose quá mạnh | Kiểm tra constraint weights, covariance |

### 7.2 Quy trình debug đề xuất

1. **Kiểm tra input**: LiDAR data rate, IMU availability, timestamp synchronization
2. **Kiểm tra local SLAM**: scan matching scores, submap quality
3. **Kiểm tra global SLAM**: constraint count, loop closure events, optimization residuals
4. **Kiểm tra integration**: CartographerService state, sensor subscriptions

---

## Tài liệu liên quan

- [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) — Hướng dẫn kỹ thuật chuyên su
- [cartographer-parameters-guide.md](cartographer-parameters-guide.md) — Bảng tham số đầy đủ và hướng dẫn tuning
- [ASSESSMENT.md](ASSESSMENT.md) — Đánh giá chất lượng source code
- [Localization Services Architecture](../Localization/Localization_Services_Architecture.md) — Kiến trúc integration layer

---

*Biên soạn từ paper gốc (2016) + CartographerSharp source code analysis. Cập nhật: 2026-03.*
