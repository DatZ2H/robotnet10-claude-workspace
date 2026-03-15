---
globs:
  - "srcs/**/CartographerSharp/**"
  - "srcs/**/CeresSharp/**"
  - "srcs/**/SLAM/**"
  - "srcs/**/Localization/**"
---

# SLAM & Localization Context

> [!WARNING]
> Domain lớn nhất trong codebase (~262 files, ~21K LOC, ~20% codebase).
> Sai pose estimation -> robot va chạm. Safety-critical.

## Architecture 3 tầng

```
CartographerSharp (lib, 162 files)  -- SLAM core, Google Cartographer port
    └── CeresSharp (lib, 53 files)  -- Ceres solver wrapper, native interop
         └── RobotApp/SLAM/ (47 files) -- Integration layer
              ├── CartographerService  -- State machine: Idle -> Initializing -> Ready -> Localizing/ScanMapping
              ├── LocalizationService  -- ISLAMService, ILocalizationService
              └── ScanMappingService   -- IScanMappingService
```

## Key interfaces

| Interface | Purpose |
|-----------|---------|
| `IMapBuilder` | Map construction from sensor data |
| `ITrajectoryBuilder` | Trajectory estimation and management |
| `ISLAMService` | High-level SLAM orchestration |
| `ILocalizationService` | Pose estimation from existing map |
| `IScanMappingService` | Build new map from LiDAR scans |

## CartographerService state machine

```
Idle -> Initializing -> Ready -> Localizing (using existing map)
                            └-> ScanMapping (building new map)
```

## Sensor pipeline

```
LiDAR + IMU -> SensorPipeline -> MapBuilder.AddSensorData()
```

- Pose extrapolation: 20-100 Hz (real-time constraint)
- Scan matching: 5-20 Hz

## CeresSharp native interop

- Uses `SafeHandle` for native resource management
- P/Invoke calls to Ceres C++ solver
- Crash risk: incorrect P/Invoke signatures or memory management -> process crash (not just exception)
- Build requires native Ceres library on target platform

## Safety constraints

- Sai pose estimation -> robot va chạm vật cản
- Loop closure false positive -> map corruption -> navigation sai
- Sensor data dropout -> pose drift -> cần fallback behavior

## Namespace pattern

- `CartographerSharp.Mapping.Internal.*` — private implementation, KHÔNG gọi trực tiếp
- `CartographerSharp.Mapping.*` — public API
- `CeresSharp.*` — solver API (thin wrapper over native)

## Key algorithms (from paper)

- **Scan matching 2 bước**: Real-Time CSM (brute-force local) → Ceres (refinement, sub-pixel)
- **Loop closure**: Branch & Bound với precomputed grids — exact match, không phải heuristic
- **Precomputed grids**: mỗi level h lưu max probability trong vùng 2^h × 2^h pixels → O(K) upper bound
- **Odds update**: Bayesian — `M_new(x) = clamp(odds⁻¹(odds(M_old(x)) · odds(p_hit)))` — nhân, KHÔNG cộng
- **Pose graph optimization**: Sparse Pose Adjustment (SPA) qua Ceres, Huber loss cho outlier rejection

## Reference docs

- `docs/CartographerSharp/cartographer-slam-reference.md` — Paper analysis + algorithm details + class mapping
- `docs/CartographerSharp/cartographer-parameters-guide.md` — Bảng tham số + tuning profiles cho AMR
- `docs/CartographerSharp/DEVELOPER_GUIDE.md` — Vòng đời dữ liệu, scan matching logic, performance tuning
- `docs/Localization/Localization_Services_Architecture.md` — State machines + DI + event flow

## When editing SLAM code

- Test với cả Localizing VÀ ScanMapping states
- Verify pose output accuracy sau thay đổi (small drift = dangerous)
- CeresSharp: mọi thay đổi P/Invoke phải verify memory safety
- CartographerService state transitions phải handle error states gracefully
- Check real-time constraints: scan matching loop KHÔNG được block quá 50ms
- Khi tune parameters: tham khảo tuning profiles trong `cartographer-parameters-guide.md`
