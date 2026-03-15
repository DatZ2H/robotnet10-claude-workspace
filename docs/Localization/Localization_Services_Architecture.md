# Localization Services Architecture

Tài liệu mô tả kiến trúc và mối quan hệ giữa các service trong module Localization.

## 1. Dependency Injection Diagram

```mermaid
graph TB
    subgraph "Dependency Injection Container"
        CS[CartographerService]
        LS[LocalizationService]
        SMS[ScanMappingService]
        MSS[MapStorageService]
        OGP[OccupancyGridProvider]
        CSM[CartographerSensorManager]
    end
    
    subgraph "Interfaces"
        ICS[ICartographerService]
        ILS[ILocalizationService]
        ISMS[IScanMappingService]
        IMSS[IMapStorageService]
        IOGP[IOccupancyGridProvider]
    end
    
    subgraph "Dependencies"
        CFG[CartographerConfiguration]
        DP[IDeviceProvider]
        HUB[IHubContext CartographerHub]
        LOG[ILogger]
        OE[IOdometryEstimator]
    end
    
    subgraph "Adapters"
        LDA[LidarDataAdapter]
        IDA[ImuDataAdapter]
        ODA[OdometryDataAdapter]
    end
    
    %% Implementations
    CS -.->|implements| ICS
    LS -.->|implements| ILS
    SMS -.->|implements| ISMS
    MSS -.->|implements| IMSS
    OGP -.->|implements| IOGP
    
    %% Dependencies
    LS -->|injects| ICS
    SMS -->|injects| ICS
    CS -->|injects| CSM
    CS -->|injects| IMSS
    CS -->|injects| IOGP
    CS -->|injects| CFG
    CS -->|injects| DP
    CS -->|injects| HUB
    CS -->|injects| LOG
    CSM -->|injects| DP
    CSM -->|injects| OE
    CSM -->|injects| CFG
    CSM -->|injects| LDA
    CSM -->|injects| IDA
    CSM -->|injects| ODA
    CSM -->|injects| LOG
    MSS -->|injects| CFG
    MSS -->|injects| LOG
    OGP -->|injects| ICS
    OGP -->|injects| IMSS
    OGP -->|injects| CFG
    OGP -->|injects| LOG
    
    %% Service Registration
    CS -.->|Singleton| CS
    LS -.->|Singleton| LS
    SMS -.->|Singleton| SMS
    MSS -.->|Singleton| MSS
    OGP -.->|Singleton| OGP
    CSM -.->|Singleton| CSM
    
    style CS fill:#e1f5ff
    style LS fill:#fff4e1
    style SMS fill:#fff4e1
    style MSS fill:#e8f5e9
    style OGP fill:#e8f5e9
    style CSM fill:#f3e5f5
```

## 2. Service Relationships Diagram

```mermaid
graph LR
    subgraph "High-Level Services"
        LS[LocalizationService]
        SMS[ScanMappingService]
    end
    
    subgraph "Core Service"
        CS[CartographerService]
    end
    
    subgraph "Supporting Services"
        CSM[CartographerSensorManager]
        MSS[MapStorageService]
        OGP[OccupancyGridProvider]
    end
    
    %% Main dependencies
    LS -->|uses| CS
    SMS -->|uses| CS
    
    %% CartographerService dependencies
    CS -->|owns| CSM
    CS -->|delegates to| MSS
    CS -->|notifies| OGP
    
    %% OccupancyGridProvider dependencies
    OGP -->|reads from| CS
    OGP -->|loads from| MSS
    
    %% CartographerService exposes SensorManager
    CS -.->|exposes| CSM
    
    style CS fill:#4CAF50,color:#fff
    style LS fill:#FF9800,color:#fff
    style SMS fill:#FF9800,color:#fff
    style CSM fill:#9C27B0,color:#fff
    style MSS fill:#2196F3,color:#fff
    style OGP fill:#2196F3,color:#fff
```

## 3. State Machine Overview

```mermaid
stateDiagram-v2
    [*] --> CartographerService
    [*] --> LocalizationService
    [*] --> ScanMappingService
    [*] --> MapStorageService
    [*] --> OccupancyGridProvider
    
    state CartographerService {
        [*] --> Idle
        Idle --> Initializing: Start
        Initializing --> Ready: InitializationComplete
        Initializing --> Error: InitializationFailed
        Ready --> Localizing: StartLocalization
        Ready --> ScanMapping: StartScanMapping
        Localizing --> Ready: StopLocalization
        ScanMapping --> SavingMap: SaveMap
        SavingMap --> Ready: MapSaved
        Error --> Idle: Reset
    }
    
    state LocalizationService {
        [*] --> Idle
        Idle --> Starting: Start
        Starting --> Localizing: Started
        Starting --> Error: ErrorOccurred
        Localizing --> Stopping: Stop
        Stopping --> Idle: Stopped
        Error --> Idle: Reset
    }
    
    state ScanMappingService {
        [*] --> Idle
        Idle --> Starting: Start
        Starting --> Mapping: Started
        Starting --> Error: ErrorOccurred
        Mapping --> Saving: Save
        Saving --> Idle: Saved
        Mapping --> Stopping: Stop
        Stopping --> Idle: Stopped
        Error --> Idle: Reset
    }
    
    state MapStorageService {
        [*] --> Idle
        Idle --> Saving: StartSaving
        Idle --> Loading: StartLoading
        Saving --> Idle: SavingComplete
        Saving --> Error: SavingFailed
        Loading --> Idle: LoadingComplete
        Loading --> Error: LoadingFailed
        Error --> Idle: Reset
    }
    
    state OccupancyGridProvider {
        [*] --> Idle
        Idle --> Ready: GridReady
        Idle --> Fault: ErrorOccurred
        Ready --> Idle: GridCleared
        Ready --> Fault: ErrorOccurred
        Fault --> Idle: Reset
        Fault --> Ready: GridReady
    }
```

## 4. State Machine Interactions

```mermaid
sequenceDiagram
    participant LS as LocalizationService
    participant CS as CartographerService
    participant CSM as CartographerSensorManager
    participant MSS as MapStorageService
    participant OGP as OccupancyGridProvider
    
    Note over LS,OGP: Start Localization Flow
    
    LS->>CS: LoadMapAsync(mapName)
    CS->>MSS: LoadMapAsync(mapName)
    MSS-->>CS: IMapBuilder
    CS-->>LS: IMapBuilder
    
    LS->>CS: StartLocalization()
    CS->>CS: Fire(StartLocalization)
    CS->>CSM: SetTrajectoryBuilder(trajectoryBuilder)
    CS->>OGP: NotifyLocalizationStarted(mapName)
    OGP->>OGP: Fire(GridReady)
    OGP->>MSS: Load PGM file
    MSS-->>OGP: OccupancyGrid
    
    Note over LS,OGP: Stop Localization Flow
    
    LS->>CS: StopLocalization()
    CS->>CS: Fire(StopLocalization)
    CS->>CSM: ClearTrajectoryBuilder()
    CS->>OGP: (implicit via state change)
    OGP->>OGP: Fire(GridCleared)
```

## 5. Scan Mapping Flow

```mermaid
sequenceDiagram
    participant SMS as ScanMappingService
    participant CS as CartographerService
    participant CSM as CartographerSensorManager
    participant MSS as MapStorageService
    participant OGP as OccupancyGridProvider
    
    Note over SMS,OGP: Start Scan Mapping Flow
    
    SMS->>CS: Check State == Ready
    SMS->>CS: StartScanMapping()
    CS->>CS: Fire(StartScanMapping)
    CS->>CSM: SetTrajectoryBuilder(trajectoryBuilder)
    CS->>OGP: NotifyScanMappingStarted()
    OGP->>OGP: Fire(GridReady)
    
    Note over SMS,OGP: During Mapping - Submap Updates
    
    CS->>CS: SubmapsUpdated event
    CS->>OGP: (via event subscription)
    OGP->>OGP: Enqueue submap update
    OGP->>OGP: Generate OccupancyGrid from submaps
    
    Note over SMS,OGP: Save Map Flow
    
    SMS->>CS: SaveMapAsync(mapName, mapBuilder)
    CS->>MSS: SaveMapAsync(mapName, mapBuilder)
    MSS->>MSS: Fire(StartSaving)
    MSS->>MSS: Save .pbstream, .pgm, .png, .json
    MSS->>MSS: Fire(SavingComplete)
    MSS-->>CS: mapPath
    CS->>CS: Fire(MapSaved)
    CS->>CS: Fire(StopScanMapping)
    CS->>CSM: ClearTrajectoryBuilder()
    CS->>OGP: (implicit via state change)
    OGP->>OGP: Fire(GridCleared)
```

## 6. Class Hierarchy

```mermaid
classDiagram
    class ICartographerService {
        <<interface>>
        +IMapBuilder MapBuilder
        +int TrajectoryId
        +CartographerState State
        +CartographerSensorManager SensorManager
        +LoadMapAsync()
        +SaveMapAsync()
        +StartLocalization()
        +StartScanMapping()
        +StopLocalization()
        +StopScanMapping()
    }
    
    class ILocalizationService {
        <<interface>>
        +bool IsLocalizing
        +Pose CurrentPose
        +StartLocalizationAsync()
        +StopLocalizationAsync()
        +SetInitialPoseAsync()
    }
    
    class IScanMappingService {
        <<interface>>
        +bool IsMapping
        +string CurrentMapName
        +Pose CurrentPose
        +StartMappingAsync()
        +SaveMapAsync()
    }
    
    class IMapStorageService {
        <<interface>>
        +SaveMapAsync()
        +LoadMapAsync()
        +ListMapsAsync()
        +DeleteMapAsync()
        +TransformMapOriginAsync()
    }
    
    class IOccupancyGridProvider {
        <<interface>>
        +OccupancyGrid GetOccupancyGrid()
        +event OccupancyGridUpdated
    }
    
    class CartographerService {
        -PassiveStateMachine stateMachine
        -MapBuilder mapBuilder
        -CartographerSensorManager sensorManager
        -IMapStorageService mapStorageService
        -IOccupancyGridProvider occupancyGridProvider
        +LoadMapAsync()
        +SaveMapAsync()
        +StartLocalization()
        +StartScanMapping()
    }
    
    class LocalizationService {
        -PassiveStateMachine stateMachine
        -ICartographerService cartographerService
        -IMapBuilder localizationMapBuilder
        -ITrajectoryBuilder localizationTrajectoryBuilder
        +StartLocalizationAsync()
        +StopLocalizationAsync()
    }
    
    class ScanMappingService {
        -PassiveStateMachine stateMachine
        -ICartographerService cartographerService
        +StartMappingAsync()
        +SaveMapAsync()
    }
    
    class MapStorageService {
        -PassiveStateMachine stateMachine
        +SaveMapAsync()
        +LoadMapAsync()
        +ListMapsAsync()
    }
    
    class OccupancyGridProvider {
        -PassiveStateMachine stateMachine
        -ICartographerService cartographerService
        -IMapStorageService mapStorageService
        -OccupancyGrid currentOccupancyGrid
        +GetOccupancyGrid()
    }
    
    class CartographerSensorManager {
        -SensorManagerState state
        -ITrajectoryBuilder currentTrajectoryBuilder
        -List~ILidar~ subscribedLidars
        -IInertialMeasurementUnit subscribedImu
        +SetTrajectoryBuilder()
        +ClearTrajectoryBuilder()
        +InitializeAsync()
    }
    
    ICartographerService <|.. CartographerService
    ILocalizationService <|.. LocalizationService
    IScanMappingService <|.. ScanMappingService
    IMapStorageService <|.. MapStorageService
    IOccupancyGridProvider <|.. OccupancyGridProvider
    
    CartographerService --> CartographerSensorManager : owns
    CartographerService --> IMapStorageService : delegates to
    CartographerService --> IOccupancyGridProvider : notifies
    LocalizationService --> ICartographerService : uses
    ScanMappingService --> ICartographerService : uses
    OccupancyGridProvider --> ICartographerService : reads from
    OccupancyGridProvider --> IMapStorageService : loads from
```

## 7. State Machine States Detail

### CartographerService States

```mermaid
stateDiagram-v2
    [*] --> Idle
    
    Idle --> Initializing: Start trigger
    Initializing --> Ready: InitializationComplete
    Initializing --> Error: InitializationFailed
    
    Ready --> Localizing: StartLocalization trigger
    Ready --> ScanMapping: StartScanMapping trigger
    
    Localizing --> Ready: StopLocalization trigger
    ScanMapping --> SavingMap: SaveMap trigger
    
    SavingMap --> Ready: MapSaved trigger
    
    Error --> Idle: Reset trigger
    Ready --> Error: ErrorOccurred trigger
    Localizing --> Error: ErrorOccurred trigger
    ScanMapping --> Error: ErrorOccurred trigger
    
    note right of Ready
        State machine initialized
        Sensor manager ready
        Waiting for localization/mapping request
    end note
    
    note right of Localizing
        Map loaded
        Trajectory builder active
        Processing sensor data for localization
    end note
    
    note right of ScanMapping
        Creating new map
        Trajectory builder active
        Processing sensor data for SLAM
    end note
```

### LocalizationService States

```mermaid
stateDiagram-v2
    [*] --> Idle
    
    Idle --> Starting: Start trigger
    Starting --> Localizing: Started trigger
    Starting --> Error: ErrorOccurred trigger
    
    Localizing --> Stopping: Stop trigger
    Stopping --> Idle: Stopped trigger
    
    Error --> Idle: Reset trigger
    Localizing --> Error: ErrorOccurred trigger
    
    note right of Starting
        Loading map via CartographerService
        Setting up trajectory builder
    end note
    
    note right of Localizing
        Actively localizing
        Updating pose from Cartographer
        Publishing pose updates
    end note
```

### ScanMappingService States

```mermaid
stateDiagram-v2
    [*] --> Idle
    
    Idle --> Starting: Start trigger
    Starting --> Mapping: Started trigger
    Starting --> Error: ErrorOccurred trigger
    
    Mapping --> Saving: Save trigger
    Saving --> Idle: Saved trigger
    
    Mapping --> Stopping: Stop trigger
    Stopping --> Idle: Stopped trigger
    
    Error --> Idle: Reset trigger
    Mapping --> Error: ErrorOccurred trigger
    
    note right of Mapping
        Actively creating map
        Collecting sensor data
        Building submaps
    end note
    
    note right of Saving
        Saving map to storage
        Generating PGM/PNG files
        Reporting progress
    end note
```

### MapStorageService States

```mermaid
stateDiagram-v2
    [*] --> Idle
    
    Idle --> Saving: StartSaving trigger
    Idle --> Loading: StartLoading trigger
    
    Saving --> Idle: SavingComplete trigger
    Saving --> Error: SavingFailed trigger
    
    Loading --> Idle: LoadingComplete trigger
    Loading --> Error: LoadingFailed trigger
    
    Error --> Idle: Reset trigger
    
    note right of Saving
        Saving .pbstream file
        Generating PGM occupancy grid
        Creating PNG visualization
        Writing JSON metadata
    end note
    
    note right of Loading
        Loading .pbstream file
        Validating map data
        Returning IMapBuilder instance
    end note
```

### OccupancyGridProvider States

```mermaid
stateDiagram-v2
    [*] --> Idle
    
    Idle --> Ready: GridReady trigger
    Idle --> Fault: ErrorOccurred trigger
    
    Ready --> Idle: GridCleared trigger
    Ready --> Fault: ErrorOccurred trigger
    
    Fault --> Idle: Reset trigger
    Fault --> Ready: GridReady trigger
    
    note right of Idle
        No occupancy grid available
        Waiting for localization/mapping to start
    end note
    
    note right of Ready
        Occupancy grid available
        - Localizing: Loaded from PGM file
        - ScanMapping: Generated from submaps
    end note
    
    note right of Fault
        Error occurred while
        loading or generating grid
    end note
```

## 8. Event Flow Diagram

```mermaid
graph TB
    subgraph "CartographerService Events"
        CS_LSR[LocalSlamResult]
        CS_SU[SubmapsUpdated]
    end
    
    subgraph "LocalizationService Events"
        LS_PU[PoseUpdated]
    end
    
    subgraph "ScanMappingService Events"
        SMS_PU[PoseUpdated]
        SMS_TNA[TrajectoryNodeAdded]
        SMS_PU2[ProgressUpdated]
    end
    
    subgraph "OccupancyGridProvider Events"
        OGP_OGU[OccupancyGridUpdated]
    end
    
    CS_LSR -->|subscribes| LS
    CS_LSR -->|subscribes| SMS
    CS_SU -->|subscribes| OGP
    
    CS -.->|fires| CS_LSR
    CS -.->|fires| CS_SU
    
    LS -.->|fires| LS_PU
    SMS -.->|fires| SMS_PU
    SMS -.->|fires| SMS_TNA
    SMS -.->|fires| SMS_PU2
    OGP -.->|fires| OGP_OGU
```

## 9. Resource Lifecycle

```mermaid
graph TB
    subgraph "Initialization"
        A[Application Start] --> B[CartographerService.StartAsync]
        B --> C[CartographerSensorManager.InitializeAsync]
        C --> D[Subscribe to sensors]
        D --> E[State Machine: Idle]
    end
    
    subgraph "Localization Lifecycle"
        E --> F[LocalizationService.StartLocalizationAsync]
        F --> G[CartographerService.LoadMapAsync]
        G --> H[MapStorageService.LoadMapAsync]
        H --> I[CartographerService.StartLocalization]
        I --> J[Set TrajectoryBuilder]
        J --> K[State: Localizing]
        K --> L[Process sensor data]
        L --> M[LocalizationService.StopLocalizationAsync]
        M --> N[CartographerService.StopLocalization]
        N --> O[Clear TrajectoryBuilder]
        O --> E
    end
    
    subgraph "Scan Mapping Lifecycle"
        E --> P[ScanMappingService.StartMappingAsync]
        P --> Q[CartographerService.StartScanMapping]
        Q --> R[Set TrajectoryBuilder]
        R --> S[State: ScanMapping]
        S --> T[Process sensor data]
        T --> U[Build submaps]
        U --> V[ScanMappingService.SaveMapAsync]
        V --> W[CartographerService.SaveMapAsync]
        W --> X[MapStorageService.SaveMapAsync]
        X --> Y[State: SavingMap]
        Y --> Z[State: Ready]
        Z --> AA[Clear TrajectoryBuilder]
        AA --> E
    end
    
    subgraph "Disposal"
        E --> AB[Application Shutdown]
        AB --> AC[Dispose all services]
        AC --> AD[Stop state machines]
        AD --> AE[Clear resources]
    end
```

## 10. Key Design Principles

### Dependency Inversion
- `LocalizationService` và `ScanMappingService` chỉ phụ thuộc vào `ICartographerService`
- `CartographerService` là trung tâm quản lý dependencies: `CartographerSensorManager`, `MapStorageService`, `OccupancyGridProvider`

### State Machine Pattern
- Tất cả services sử dụng `Appccelerate.StateMachine` để quản lý lifecycle
- States và triggers được định nghĩa rõ ràng trong các enum riêng biệt
- State transitions được kiểm soát chặt chẽ để tránh race conditions

### Single Responsibility
- `CartographerService`: Quản lý Cartographer core và state machine chính
- `LocalizationService`: Quản lý localization lifecycle
- `ScanMappingService`: Quản lý scan mapping lifecycle
- `MapStorageService`: Quản lý lưu/load maps
- `OccupancyGridProvider`: Cung cấp occupancy grid từ maps
- `CartographerSensorManager`: Quản lý sensor subscriptions và routing

### Thread Safety
- Sử dụng `Lock` (spin lock) cho các critical sections
- Thread-safe event invocation với lock objects
- State machines được khởi tạo lazy với `field` keyword (C# 14)

### Resource Management
- Tất cả services implement `IDisposable` để cleanup resources
- State machines được stop trong `Dispose()`
- Background threads được cancel và join trong `Dispose()`

## 11. Notes

- **CartographerService** là `IHostedService`, tự động start khi application start
- **CartographerSensorManager** được inject vào `CartographerService` và expose qua property `SensorManager`
- **OccupancyGridProvider** tự động chuyển sang `Ready` state khi `CartographerService` ở `Localizing` hoặc `ScanMapping` state
- Tất cả services được đăng ký là `Singleton` trong DI container
- State machines sử dụng lazy initialization với `field` keyword (C# 14 feature)

