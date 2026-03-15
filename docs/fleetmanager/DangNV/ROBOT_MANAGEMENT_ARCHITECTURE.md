# Robot Management Module - Architecture Design

**Module:** Robot Management System  
**Version:** 1.0  
**Date:** 2025-01-XX  
**Status:** Architecture Design Phase

---

## Mục Lục

1. [Tổng Quan](#tổng-quan)
2. [Cấu Trúc Database](#cấu-trúc-database)
3. [Cấu Trúc Backend](#cấu-trúc-backend)
4. [Cấu Trúc Frontend](#cấu-trúc-frontend)
5. [API Endpoints](#api-endpoints)
6. [VDA5050 Integration](#vda5050-integration)

---

## Tổng Quan

### Mục Đích

Xây dựng hệ thống quản lý thông tin robot bao gồm:
- **RobotModel Management**: Quản lý các chủng loại robot (thêm, sửa, xóa, preview)
- **Robot Management**: Quản lý thông tin robot (thêm, sửa, xóa, preview)
- **Robot Detail**: Hiển thị thông tin robot theo tiêu chuẩn VDA5050 và manual actions

### Quan Hệ Dữ Liệu

```
RobotModel (1) ──< (N) Robot
```

- 1 RobotModel có thể có nhiều Robot
- 1 Robot chỉ thuộc về 1 RobotModel

---

## Cấu Trúc Database

### 1. Bảng RobotModels

```sql
CREATE TABLE [RobotModels] (
    [Id] uniqueidentifier PRIMARY KEY DEFAULT NEWID(),
    [ModelName] nvarchar(256) NOT NULL,
    [Length] decimal(18,2) NOT NULL,              -- Chiều dài robot (m)
    [Width] decimal(18,2) NOT NULL,                -- Chiều rộng robot (m)
    [ImageWidth] int NOT NULL,                     -- Chiều rộng ảnh (pixels)
    [ImageHeight] int NOT NULL,                    -- Chiều cao ảnh (pixels)
    [NavigationPointX] decimal(18,2) NOT NULL,     -- Tọa độ X điểm navigation (m)
    [NavigationPointY] decimal(18,2) NOT NULL,     -- Tọa độ Y điểm navigation (m)
    [NavigationType] int NOT NULL,                 -- Enum: Differential, Forklift, OmniDrive
    [CreatedDate] datetime2 NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedDate] datetime2 NULL
);

-- Indexes
CREATE INDEX IX_RobotModels_ModelName ON [RobotModels]([ModelName]);
CREATE INDEX IX_RobotModels_NavigationType ON [RobotModels]([NavigationType]);
```

**Fields:**
- `Id`: GUID primary key
- `ModelName`: Tên model robot (unique, có thể thêm constraint)
- `Length`, `Width`: Kích thước robot (mét)
- `ImageWidth`, `ImageHeight`: Kích thước ảnh hiển thị
- `NavigationPointX`, `NavigationPointY`: Điểm navigation tương đối so với tâm robot
- `NavigationType`: Enum (0=Differential, 1=Forklift, 2=OmniDrive)
- `CreatedDate`, `UpdatedDate`: Timestamps

### 2. Bảng Robots

```sql
CREATE TABLE [Robots] (
    [Id] uniqueidentifier PRIMARY KEY DEFAULT NEWID(),
    [RobotId] nvarchar(64) NOT NULL UNIQUE,        -- Robot identifier (serial number)
    [Name] nvarchar(256) NOT NULL,                 -- Tên hiển thị
    [ModelId] uniqueidentifier NOT NULL,            -- FK to RobotModels
    [MapId] uniqueidentifier NULL,                  -- FK to Maps (có thể nullable)
    [CreatedDate] datetime2 NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedDate] datetime2 NULL,
    
    CONSTRAINT FK_Robots_RobotModels FOREIGN KEY ([ModelId]) 
        REFERENCES [RobotModels]([Id]) ON DELETE RESTRICT
);

-- Indexes
CREATE INDEX IX_Robots_RobotId ON [Robots]([RobotId]);
CREATE INDEX IX_Robots_ModelId ON [Robots]([ModelId]);
CREATE INDEX IX_Robots_MapId ON [Robots]([MapId]);
CREATE UNIQUE INDEX UX_Robots_RobotId ON [Robots]([RobotId]);
```

**Fields:**
- `Id`: GUID primary key
- `RobotId`: Serial number hoặc identifier duy nhất của robot
- `Name`: Tên hiển thị của robot
- `ModelId`: Foreign key đến RobotModels
- `MapId`: Foreign key đến Maps (có thể null nếu chưa gán map)
- `CreatedDate`, `UpdatedDate`: Timestamps

### 3. Entity Relationship Diagram

```
┌─────────────────┐
│  RobotModels    │
├─────────────────┤
│ Id (PK)         │
│ ModelName       │
│ Length          │
│ Width           │
│ ImageWidth      │
│ ImageHeight     │
│ NavPointX       │
│ NavPointY       │
│ NavigationType  │
│ CreatedDate     │
│ UpdatedDate     │
└────────┬────────┘
         │ 1
         │
         │ N
┌────────▼────────┐
│    Robots       │
├─────────────────┤
│ Id (PK)         │
│ RobotId (UK)    │
│ Name            │
│ ModelId (FK)    │──┐
│ MapId (FK)      │  │
│ CreatedDate     │  │
│ UpdatedDate     │  │
└─────────────────┘  │
                     │
                     │ (optional)
                     │
         ┌───────────┘
         │
         ▼
    [Maps Table]
```

---

## Cấu Trúc Backend

### 1. Folder Structure

```
RobotNet10.FleetManager/
├── Data/
│   ├── NavigationType.cs          ✅ (Enum)
│   ├── RobotModel.cs              ✅ (Entity)
│   ├── Robot.cs                   ✅ (Entity)
│   └── ApplicationDbContext.cs    (Update: Add DbSets)
│
├── Services/
│   ├── IRobotModelService.cs      (Interface)
│   ├── RobotModelService.cs       (Implementation)
│   ├── IRobotService.cs           (Interface)
│   ├── RobotService.cs            (Implementation)
│   ├── IRobotModelImageStorageService.cs  (Image storage interface)
│   └── RobotModelImageStorageService.cs   (FileSystem implementation)
│
├── Controllers/
│   ├── RobotModelController.cs    (API endpoints)
│   ├── RobotController.cs         (API endpoints)
│   └── RobotModelImagesController.cs  (Image upload/download)
│
└── Hubs/
    └── RobotStateHub.cs           (SignalR Hub cho VDA5050 State)

RobotNet10.FleetManager.Shared/
├── DTOs/
│   ├── RobotModel/
│   │   ├── RobotModelDto.cs
│   │   ├── CreateRobotModelRequest.cs
│   │   ├── UpdateRobotModelRequest.cs
│   │   └── RobotModelUsageInfoDto.cs
│   └── Robot/
│       ├── RobotDto.cs
│       ├── CreateRobotRequest.cs
│       └── UpdateRobotRequest.cs
```

### 2. Services Interface

#### IRobotModelService

```csharp
public interface IRobotModelService
{
    Task<RobotModel> CreateAsync(CreateRobotModelRequest request);
    Task<List<RobotModel>> GetAllAsync();
    Task<RobotModel?> GetByIdAsync(Guid id);
    Task<RobotModel> UpdateAsync(Guid id, UpdateRobotModelRequest request);
    Task<bool> DeleteAsync(Guid id);
    Task<List<RobotModel>> SearchAsync(string query);
    Task<bool> ExistsAsync(string modelName);
    Task<RobotModelUsageInfo> GetUsageInfoAsync(Guid id);
}
```

#### IRobotService

```csharp
public interface IRobotService
{
    Task<Robot> CreateAsync(CreateRobotRequest request);
    Task<List<Robot>> GetAllAsync();
    Task<Robot?> GetByIdAsync(Guid id);
    Task<Robot?> GetByRobotIdAsync(string robotId);
    Task<Robot> UpdateAsync(Guid id, UpdateRobotRequest request);
    Task<bool> DeleteAsync(Guid id);
    Task<List<Robot>> GetByModelIdAsync(Guid modelId);
    Task<List<Robot>> SearchAsync(string query);
    Task<bool> ExistsAsync(string robotId);
}
```

### 3. DTOs Structure

#### RobotModelDto

```csharp
public class RobotModelDto
{
    public Guid Id { get; set; }
    public string ModelName { get; set; }
    public decimal Length { get; set; }
    public decimal Width { get; set; }
    public int ImageWidth { get; set; }
    public int ImageHeight { get; set; }
    public decimal NavigationPointX { get; set; }
    public decimal NavigationPointY { get; set; }
    public NavigationType NavigationType { get; set; }
    public DateTime CreatedDate { get; set; }
    public DateTime? UpdatedDate { get; set; }
    public int RobotCount { get; set; } // Số lượng robot sử dụng model này
}
```

#### RobotDto

```csharp
public class RobotDto
{
    public Guid Id { get; set; }
    public string RobotId { get; set; }
    public string Name { get; set; }
    public Guid ModelId { get; set; }
    public string? ModelName { get; set; } // Include từ RobotModel
    public Guid? MapId { get; set; }
    public DateTime CreatedDate { get; set; }
    public DateTime? UpdatedDate { get; set; }
}
```

---

## Cấu Trúc Frontend

### 1. Folder Structure

```
RobotNet10.FleetManager.Client/
├── Pages/
│   ├── RobotModelManager.razor        (Main page: /robot-models)
│   ├── RobotManager.razor             (Main page: /robots)
│   └── RobotDetail.razor               (Detail page: /robots/{robotId}/detail)
│
└── Components/                         (Optional: nếu tách components)
    ├── RobotModelManager/
    │   ├── RobotModelManagerComponent.razor
    │   ├── RobotModelListPanel.razor
    │   ├── RobotModelDetailsPanel.razor
    │   └── Dialogs/
    │       ├── CreateRobotModelDialog.razor
    │       ├── EditRobotModelDialog.razor
    │       └── DeleteRobotModelDialog.razor
    │
    ├── RobotManager/
    │   ├── RobotManagerComponent.razor
    │   ├── RobotListPanel.razor
    │   ├── RobotDetailsPanel.razor
    │   └── Dialogs/
    │       ├── CreateRobotDialog.razor
    │       ├── EditRobotDialog.razor
    │       └── DeleteRobotDialog.razor
    │
    └── RobotDetail/
        ├── RobotDetailComponent.razor
        ├── VDA5050StatePanel.razor
        ├── ManualActionsPanel.razor
        └── RobotInfoCard.razor
```

### 2. Layout Design

#### 2.1. RobotModelManager Page Layout

```
┌─────────────────────────────────────────────────────────────┐
│  Header (MudPaper)                                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Robot Model Management          [Search] [Add]      │  │
│  └───────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│  Main Content (MudGrid)                                      │
│  ┌──────────────────────┬─────────────────────────────────┐ │
│  │  Left Panel (60%)   │  Right Panel (40%)              │ │
│  │                     │                                  │ │
│  │  RobotModelList     │  RobotModelDetails              │ │
│  │  ┌──────────────┐   │  ┌──────────────────────────┐  │ │
│  │  │ Search Bar   │   │  │ Image Preview             │  │ │
│  │  └──────────────┘   │  │ ┌──────────────────────┐ │  │ │
│  │                     │  │ │ [Image Canvas]        │ │  │ │
│  │  ┌──────────────┐   │  │ │ + NavigationPoint    │ │  │ │
│  │  │ MudTable     │   │  │ │   (mũi tên X, Y)     │ │  │ │
│  │  │ - ModelName  │   │  │ └──────────────────────┘ │  │ │
│  │  │ - NavType    │   │  │                          │  │ │
│  │  │ - Dimensions │   │  │ Dimensions              │  │ │
│  │  │ - RobotCount │   │  │ - Length x Width        │  │ │
│  │  │ - Actions    │   │  │ - Image Size            │  │ │
│  │  └──────────────┘   │  │                          │  │ │
│  │                     │  │ Navigation Point        │  │ │
│  │                     │  │ - X, Y coordinates      │  │ │
│  │                     │  │                          │  │ │
│  │                     │  │ Usage Statistics         │  │ │
│  │                     │  │ - Robot Count            │  │ │
│  │                     │  │                          │  │ │
│  │                     │  │ Actions                  │  │ │
│  │                     │  │ [Edit] [Delete]          │  │ │
│  │                     │  └──────────────────────────┘  │ │
│  └──────────────────────┴─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**Lưu ý:**
- Left Panel: Chỉ hiển thị danh sách (ModelName, NavType, Dimensions, RobotCount)
- Right Panel: Preview ảnh với NavigationPoint overlay, thông tin chi tiết, không lặp lại thông tin từ Left Panel

#### 2.2. RobotManager Page Layout

```
┌─────────────────────────────────────────────────────────────┐
│  Header (MudPaper)                                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Robot Management              [Search] [Add]         │  │
│  └───────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│  Main Content (MudContainer)                                │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Search & Filters                                      │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │ [Search] [Filter by Model] [Filter by Map]    │  │ │
│  │  └──────────────────────────────────────────────────┘  │ │
│  │                                                        │ │
│  │  Robot Table (MudTable)                                │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │ RobotId │ Name │ Model │ Map │ Actions          │  │ │
│  │  │ ────────┼──────┼───────┼─────┼─────────────────│  │ │
│  │  │ ROBOT01 │ R1   │ AMR-T │ M1  │ [Detail][Edit]  │  │ │
│  │  │ ROBOT02 │ R2   │ AMR-F │ M2  │ [Detail][Edit]  │  │ │
│  │  │ ...     │ ...  │ ...   │ ... │ ...             │  │ │
│  │  └──────────────────────────────────────────────────┘  │ │
│  │                                                        │ │
│  │  Pagination                                            │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**Lưu ý:**
- Bỏ Right Panel vì thông tin robot ít
- Chỉ có 1 bảng với đầy đủ thông tin
- Actions: View Detail (link đến RobotDetail page), Edit, Delete

#### 2.3. RobotDetail Page Layout

```
┌─────────────────────────────────────────────────────────────┐
│  Header (MudPaper)                                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Robot Detail: {RobotName}        [Back] [Refresh]    │  │
│  └───────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│  Main Content (MudGrid)                                      │
│  ┌──────────────────────┬─────────────────────────────────┐ │
│  │  Left Panel (60%)   │  Right Panel (40%)              │ │
│  │                     │                                  │ │
│  │  VDA5050 State     │  Manual Actions                  │ │
│  │  ┌──────────────┐   │  ┌──────────────────────────┐  │ │
│  │  │ Robot Info   │   │  │ Action List               │  │ │
│  │  │ Card         │   │  │ ┌──────────────────────┐  │  │ │
│  │  └──────────────┘   │  │ │ Action Type          │  │  │ │
│  │                     │  │ │ [Select]              │  │  │ │
│  │  ┌──────────────┐   │  │ └──────────────────────┘  │  │ │
│  │  │ Position     │   │  │                          │  │ │
│  │  │ - X, Y, θ    │   │  │ Action Parameters       │  │ │
│  │  │ - MapId      │   │  │ ┌──────────────────────┐  │  │ │
│  │  └──────────────┘   │  │ │ Key-Value pairs      │  │  │ │
│  │                     │  │ │ [Add] [Remove]        │  │  │ │
│  │  ┌──────────────┐   │  │ └──────────────────────┘  │  │ │
│  │  │ Battery      │   │  │                          │  │ │
│  │  │ - Charge %   │   │  │ [Send Action]           │  │  │ │
│  │  │ - Voltage    │   │  └──────────────────────────┘  │ │
│  │  └──────────────┘   │                                  │ │
│  │                     │  Robot Status                   │ │
│  │  ┌──────────────┐   │  ┌──────────────────────────┐  │ │
│  │  │ Order Info   │   │  │ - Operating Mode         │  │ │
│  │  │ - OrderId    │   │  │ - Driving Status         │  │ │
│  │  │ - NodeId     │   │  │ - Paused                 │  │ │
│  │  └──────────────┘   │  └──────────────────────────┘  │ │
│  │                     │                                  │ │
│  │  ┌──────────────┐   │  Errors & Warnings               │ │
│  │  │ Errors       │   │  ┌──────────────────────────┐  │ │
│  │  │ - List       │   │  │ Error List              │  │ │
│  │  └──────────────┘   │  │ [Clear]                 │  │ │
│  │                     │  └──────────────────────────┘  │ │
│  └──────────────────────┴─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 3. Component Details

#### 3.1. RobotModelListPanel

**Features:**
- MudTable với sorting
- Search functionality
- Pagination
- Row selection
- Actions: Edit, Delete, View Details

**Columns:**
- ModelName (sortable)
- NavigationType (Chip)
- Dimensions (Length x Width) - formatted display
- Robot Count (Badge)
- Actions (Icon buttons: Edit, Delete, View Details)

#### 3.2. RobotModelDetailsPanel

**Sections:**
- **Image Preview** (Canvas/SVG với NavigationPoint overlay)
  - Hiển thị ảnh robot model
  - Vẽ mũi tên tại NavigationPoint (X, Y)
  - Mũi tên hướng lên trên (Y+) và sang phải (X+)
- **Dimensions**
  - Length x Width (m)
  - Image Size (pixels)
- **Navigation Point**
  - X, Y coordinates (m)
- **Usage Statistics**
  - Robot Count (số robot đang sử dụng model này)
- **Actions**
  - Edit, Delete buttons

#### 3.3. RobotManager Table

**Features:**
- MudTable với sorting
- Search functionality (search by RobotId, Name)
- Filter by Model (MudSelect dropdown)
- Filter by Map (MudSelect dropdown)
- Pagination
- Inline actions trong table

**Columns:**
- RobotId (sortable, link to detail page)
- Name (sortable)
- Model (link to model, hiển thị ModelName)
- Map (link to map, nullable, hiển thị MapName nếu có)
- Actions (Icon buttons: View Detail, Edit, Delete)

**Lưu ý:** Không có Right Panel, tất cả thông tin hiển thị trong table

#### 3.5. RobotDetailComponent (VDA5050)

**Real-time Data:**
- SignalR Hub Client kết nối đến RobotStateHub
- Subscribe to robot khi vào page
- Nhận events: `OnStateUpdate`, `OnVisualizationUpdate`
- Manual refresh button
- Auto-disconnect khi rời page

**VDA5050 State Sections (từ StateMsg):**
1. **Header Info Card**
   - HeaderId
   - Timestamp
   - Version
   - Manufacturer
   - SerialNumber

2. **Position Card** (từ agvPosition)
   - X, Y, Theta
   - MapId
   - PositionInitialized
   - LocalizationScore
   - DeviationRange

3. **Velocity Card** (từ velocity)
   - vx, vy, omega

4. **Battery Card** (từ batteryState)
   - BatteryCharge (%)
   - BatteryVoltage
   - BatteryHealth
   - Charging status
   - Reach (estimated)

5. **Order Info Card**
   - OrderId
   - OrderUpdateId
   - ZoneSetId
   - LastNodeId
   - LastNodeSequenceId
   - Driving status
   - Paused status
   - NewBaseRequest
   - DistanceSinceLastNode
   - OperatingMode

6. **Maps Card** (từ maps array)
   - MapId, MapDescription, MapVersion

7. **Node States** (từ nodeStates array)
   - MudTable: NodeId, SequenceId, Released, NodePosition

8. **Edge States** (từ edgeStates array)
   - MudTable: EdgeId, SequenceId, Released

9. **Action States** (từ actionStates array)
   - MudTable: ActionId, ActionType, ActionStatus, ResultDescription

10. **Loads Card** (từ loads array)
    - MudTable: LoadId, LoadType, LoadPosition, Weight, Dimensions

11. **Errors Card** (từ errors array)
    - MudTable: ErrorType, ErrorLevel, ErrorDescription, ErrorReferences
    - Color coding (ERROR/WARNING/INFO)

12. **Information Card** (từ information array) **MỚI**
    - MudTable: InfoType, InfoLevel, InfoDescription, InfoReferences
    - Color coding (INFO/WARNING/DEBUG)

13. **Safety State Card** (từ safetyState)
    - EStop status (enum: NONE, SOFT, HARD)
    - FieldViolation (bool)

**VDA5050 Visualization Sections (từ VisualizationMsg):**
14. **Visualization Position** (từ visualization.agvPosition)
    - X, Y, Theta, MapId, PositionInitialized

15. **Visualization Velocity** (từ visualization.velocity)
    - vx, vy, omega

#### 3.6. ManualActionsPanel

**Features:**
- Action Type selector (MudSelect với ActionType enum)
- Action Parameters editor (Key-Value pairs)
- Send Action button
- Action History (recent actions sent)

**Action Types:**
- startPause / stopPause
- startCharging / stopCharging
- cancelOrder
- stateRequest
- initPosition
- etc. (theo VDA5050 ActionType enum)

---

## API Endpoints

### RobotModelController

**Base Route:** `/api/robot-models`

| Method | Endpoint | Description | Request | Response |
|--------|----------|-------------|---------|----------|
| GET | `/api/robot-models` | Get all robot models | - | `List<RobotModelDto>` |
| GET | `/api/robot-models/{id}` | Get robot model by ID | - | `RobotModelDto` |
| GET | `/api/robot-models/search?query={text}` | Search robot models | - | `List<RobotModelDto>` |
| GET | `/api/robot-models/{id}/usage` | Get usage info | - | `RobotModelUsageInfoDto` |
| POST | `/api/robot-models` | Create robot model | `CreateRobotModelRequest` | `RobotModelDto` (201) |
| PUT | `/api/robot-models/{id}` | Update robot model | `UpdateRobotModelRequest` | `RobotModelDto` |
| DELETE | `/api/robot-models/{id}` | Delete robot model | - | 204 No Content |
| GET | `/api/robot-models/{id}/image` | Get robot model image | - | Image file (PNG) |
| POST | `/api/robot-models/{id}/image` | Upload robot model image | `multipart/form-data` | Success message |
| DELETE | `/api/robot-models/{id}/image` | Delete robot model image | - | 204 No Content |

### RobotController

**Base Route:** `/api/robots`

| Method | Endpoint | Description | Request | Response |
|--------|----------|-------------|---------|----------|
| GET | `/api/robots` | Get all robots | `?modelId={guid}&mapId={guid}` | `List<RobotDto>` |
| GET | `/api/robots/{id}` | Get robot by ID | - | `RobotDto` |
| GET | `/api/robots/robotId/{robotId}` | Get robot by RobotId | - | `RobotDto` |
| GET | `/api/robots/search?query={text}` | Search robots | - | `List<RobotDto>` |
| GET | `/api/robots/model/{modelId}` | Get robots by model | - | `List<RobotDto>` |
| POST | `/api/robots` | Create robot | `CreateRobotRequest` | `RobotDto` (201) |
| PUT | `/api/robots/{id}` | Update robot | `UpdateRobotRequest` | `RobotDto` |
| DELETE | `/api/robots/{id}` | Delete robot | - | 204 No Content |

---

## VDA5050 Integration

### 1. SignalR Hub Architecture

**RobotStateHub:**
- Hub chạy trên FleetManager Server
- Nhận State và Visualization messages từ RobotApp (qua MQTT hoặc direct)
- HubServer chủ động gửi updates theo chu kỳ đến connected clients
- Frontend kết nối SignalR và lắng nghe events

**Flow:**
```
RobotApp → MQTT/HTTP → FleetManager Backend → RobotStateHub → Frontend (SignalR Client)
```

**Hub Methods:**
- `SubscribeToRobot(string robotId)`: Client subscribe để nhận updates của robot cụ thể
- `UnsubscribeFromRobot(string robotId)`: Client unsubscribe

**Hub Events (Server → Client):**
- `OnStateUpdate(string robotId, StateMsg state)`: Khi có State message mới
- `OnVisualizationUpdate(string robotId, VisualizationMsg visualization)`: Khi có Visualization message mới

**Hub Configuration:**
- HubServer gửi updates theo chu kỳ (configurable, ví dụ: mỗi 500ms)
- Frontend chỉ cập nhật khi nhận được event hoặc manual refresh

### 2. Image Storage (RobotModel)

**Service:** `IRobotModelImageStorageService`
- Tương tự `IImageStorageService` trong MapManager
- FileSystem-based storage
- File naming: `{robotModelId}.png`
- Location: `{AppBaseDirectory}/RobotModelImages/`

**API Endpoints:**
```
GET    /api/robot-models/{id}/image     - Get image
POST   /api/robot-models/{id}/image     - Upload image (multipart/form-data)
DELETE /api/robot-models/{id}/image     - Delete image
```

**Image Upload Flow:**
1. User chọn file ảnh trong Create/Edit dialog
2. Frontend upload ảnh qua API
3. Backend lưu ảnh và extract dimensions (ImageWidth, ImageHeight)
4. Backend lưu dimensions vào database
5. Frontend hiển thị preview với NavigationPoint overlay

**Image Preview với NavigationPoint:**
- Sử dụng HTML5 Canvas hoặc SVG overlay
- Vẽ mũi tên tại tọa độ (NavigationPointX, NavigationPointY)
- Mũi tên hướng lên trên (Y+) và sang phải (X+) như gốc tọa độ
- Scale tọa độ từ mét sang pixels dựa trên ImageWidth/ImageHeight và Length/Width

### 3. Manual Actions

**API Endpoint:**
```
POST /api/robots/{robotId}/actions
Body: {
    "actionType": "startPause",
    "actionParameters": [
        {"key": "duration", "value": "60"}
    ]
}
```

**Flow:**
1. User chọn action type và parameters
2. Frontend gửi request đến FleetManager API
3. FleetManager chuyển tiếp action đến robot (MQTT/HTTP)
4. Robot thực hiện action và báo cáo qua State message

### 4. Data Storage

**State & Visualization Messages:**
- In-memory storage trong HubServer
- Lưu latest state per robot
- Mất khi restart (không persist)
- Có thể thêm option lưu vào DB nếu cần history (future enhancement)

---

## Implementation Steps

### Phase 1: Database & Entities (Foundation)

#### 1.1. Create Enum
- [ ] Create `NavigationType.cs` enum với 3 values: Differential, Forklift, OmniDrive
- [ ] Location: `RobotNet10.FleetManager/Data/NavigationType.cs`

#### 1.2. Create Entities
- [ ] Create `RobotModel.cs` entity với đầy đủ properties
  - Id, ModelName, Length, Width, ImageWidth, ImageHeight
  - NavigationPointX, NavigationPointY, NavigationType
  - CreatedDate, UpdatedDate
  - Navigation property: Robots collection
- [ ] Create `Robot.cs` entity với đầy đủ properties
  - Id, RobotId, Name, ModelId, MapId
  - CreatedDate, UpdatedDate
  - Navigation property: RobotModel

#### 1.3. Update Database Context
- [ ] Update `ApplicationDbContext.cs`
  - Add `DbSet<RobotModel> RobotModels`
  - Add `DbSet<Robot> Robots`
  - Configure entity relationships trong `OnModelCreating`
  - Configure indexes

#### 1.4. Database Migration
- [ ] Create EF Core migration: `AddRobotManagementTables`
- [ ] Review migration script
- [ ] Apply migration to database
- [ ] Verify tables và indexes được tạo đúng

**Deliverables:**
- NavigationType enum
- RobotModel entity
- Robot entity
- Database migration
- Tables trong database

---

### Phase 2: Shared DTOs (Data Transfer Objects)

#### 2.1. RobotModel DTOs
- [ ] Create `RobotModelDto.cs` trong `RobotNet10.FleetManager.Shared/DTOs/RobotModel/`
- [ ] Create `CreateRobotModelRequest.cs` với validation attributes
- [ ] Create `UpdateRobotModelRequest.cs` với validation attributes
- [ ] Create `RobotModelUsageInfoDto.cs` cho usage statistics

#### 2.2. Robot DTOs
- [ ] Create `RobotDto.cs` trong `RobotNet10.FleetManager.Shared/DTOs/Robot/`
- [ ] Create `CreateRobotRequest.cs` với validation attributes
- [ ] Create `UpdateRobotRequest.cs` với validation attributes

#### 2.3. Error Response DTOs
- [ ] Create `ErrorResponseDto.cs` (nếu chưa có) cho API error responses

**Deliverables:**
- Tất cả DTOs trong RobotNet10.FleetManager.Shared
- Validation attributes đầy đủ

---

### Phase 3: Backend Services Layer

#### 3.1. RobotModel Service
- [ ] Create `IRobotModelService.cs` interface
  - Methods: CreateAsync, GetAllAsync, GetByIdAsync, UpdateAsync, DeleteAsync
  - Methods: SearchAsync, ExistsAsync, GetUsageInfoAsync
- [ ] Create `RobotModelService.cs` implementation
  - Implement tất cả methods
  - Add validation logic
  - Add error handling
  - Check foreign key constraints khi delete

#### 3.2. Robot Service
- [ ] Create `IRobotService.cs` interface
  - Methods: CreateAsync, GetAllAsync, GetByIdAsync, GetByRobotIdAsync
  - Methods: UpdateAsync, DeleteAsync, GetByModelIdAsync, SearchAsync, ExistsAsync
- [ ] Create `RobotService.cs` implementation
  - Implement tất cả methods
  - Add validation logic
  - Add error handling

#### 3.3. Image Storage Service
- [ ] Create `IRobotModelImageStorageService.cs` interface
  - Methods: SaveImageAsync, GetImageAsync, DeleteImageAsync, ImageExistsAsync, GetImageDimensionsAsync
- [ ] Create `RobotModelImageStorageService.cs` implementation
  - FileSystem-based storage
  - Folder: `{AppBaseDirectory}/RobotModelImages/`
  - File naming: `{robotModelId}.png`
  - Use ImageSharp để extract dimensions

#### 3.4. Service Registration
- [ ] Register services trong `Program.cs`
  - AddScoped IRobotModelService, RobotModelService
  - AddScoped IRobotService, RobotService
  - AddScoped IRobotModelImageStorageService, RobotModelImageStorageService

**Deliverables:**
- 3 Service interfaces
- 3 Service implementations
- Services registered trong DI container

---

### Phase 4: API Controllers

#### 4.1. RobotModel Controller
- [ ] Create `RobotModelController.cs`
  - GET `/api/robot-models` - GetAll
  - GET `/api/robot-models/{id}` - GetById
  - GET `/api/robot-models/search?query={text}` - Search
  - GET `/api/robot-models/{id}/usage` - GetUsageInfo
  - POST `/api/robot-models` - Create
  - PUT `/api/robot-models/{id}` - Update
  - DELETE `/api/robot-models/{id}` - Delete
- [ ] Add error handling và validation
- [ ] Add proper HTTP status codes
- [ ] Add API documentation comments

#### 4.2. Robot Controller
- [ ] Create `RobotController.cs`
  - GET `/api/robots` - GetAll (với filters: modelId, mapId)
  - GET `/api/robots/{id}` - GetById
  - GET `/api/robots/robotId/{robotId}` - GetByRobotId
  - GET `/api/robots/search?query={text}` - Search
  - GET `/api/robots/model/{modelId}` - GetByModelId
  - POST `/api/robots` - Create
  - PUT `/api/robots/{id}` - Update
  - DELETE `/api/robots/{id}` - Delete
- [ ] Add error handling và validation
- [ ] Add proper HTTP status codes
- [ ] Add API documentation comments

#### 4.3. RobotModel Images Controller
- [ ] Create `RobotModelImagesController.cs`
  - GET `/api/robot-models/{id}/image` - GetImage
  - POST `/api/robot-models/{id}/image` - UploadImage (multipart/form-data)
  - DELETE `/api/robot-models/{id}/image` - DeleteImage
- [ ] Add file validation (PNG only, max size)
- [ ] Extract và update ImageWidth, ImageHeight trong database

#### 4.4. API Testing
- [ ] Test tất cả endpoints với Postman/curl
- [ ] Verify error handling
- [ ] Verify validation rules

**Deliverables:**
- 3 Controllers với đầy đủ endpoints
- API documentation
- Tested và verified

---

### Phase 5: SignalR Hub (VDA5050 Integration)

#### 5.1. RobotState Hub
- [ ] Create `RobotStateHub.cs` trong `RobotNet10.FleetManager/Hubs/`
  - Hub class kế thừa Hub
  - Methods: SubscribeToRobot, UnsubscribeFromRobot
  - Events: OnStateUpdate, OnVisualizationUpdate
- [ ] Create HubContext service để manage robot subscriptions
- [ ] Implement logic để nhận State/Visualization từ backend
- [ ] Implement periodic broadcast đến clients

#### 5.2. Hub Registration
- [ ] Register Hub trong `Program.cs`
  - MapHub<RobotStateHub>("/hubs/robot-state")
- [ ] Configure SignalR options nếu cần

#### 5.3. Backend Integration (Future)
- [ ] Note: Integration với MQTT/HTTP để nhận messages từ RobotApp
- [ ] Note: Sẽ implement trong phase sau khi có RobotConnections module

**Deliverables:**
- RobotStateHub
- Hub registered và accessible
- Ready để integrate với frontend

---

### Phase 6: Frontend - RobotModel Management

#### 6.1. API Service Client
- [ ] Create `RobotModelApiService.cs` trong Client project
  - Methods để call tất cả RobotModel endpoints
  - Methods để upload/download images
- [ ] Create `RobotApiService.cs` trong Client project
  - Methods để call tất cả Robot endpoints

#### 6.2. State Management (Optional)
- [ ] Create `RobotModelManagerState.cs` (nếu cần state management)
  - SelectedRobotModel
  - RobotModels list
  - Loading states

#### 6.3. RobotModelManager Page
- [ ] Create `RobotModelManager.razor` page
  - Route: `/robot-models`
  - Layout: Header với Search và Add button
  - Two-column layout (60% List, 40% Details)

#### 6.4. RobotModelListPanel Component
- [ ] Create `RobotModelListPanel.razor`
  - MudTable với columns: ModelName, NavigationType, Dimensions, RobotCount, Actions
  - Search functionality
  - Sorting
  - Pagination
  - Row selection để hiển thị details
  - Actions: Edit, Delete buttons

#### 6.5. RobotModelDetailsPanel Component
- [ ] Create `RobotModelDetailsPanel.razor`
  - Image Preview section với Canvas/SVG
  - NavigationPoint overlay (mũi tên X+, Y+)
  - Dimensions display
  - Navigation Point coordinates
  - Usage Statistics (Robot Count)
  - Actions: Edit, Delete buttons

#### 6.6. Image Preview với NavigationPoint
- [ ] Create component để render image với overlay
  - Load image từ API
  - Calculate scale từ Length/Width và ImageWidth/ImageHeight
  - Draw arrow tại NavigationPoint coordinates
  - Arrow direction: up (Y+) và right (X+)

#### 6.7. Create RobotModel Dialog
- [ ] Create `CreateRobotModelDialog.razor`
  - Form fields: ModelName, Length, Width, NavigationPointX, NavigationPointY, NavigationType
  - Image upload input (file picker)
  - Image preview
  - Validation
  - Submit handler

#### 6.8. Edit RobotModel Dialog
- [ ] Create `EditRobotModelDialog.razor`
  - Pre-fill form với existing data
  - Image upload/replace
  - Image preview với NavigationPoint
  - Validation
  - Submit handler

#### 6.9. Delete RobotModel Dialog
- [ ] Create `DeleteRobotModelDialog.razor`
  - Confirmation message
  - Show usage info (Robot count)
  - Warning nếu có robots đang sử dụng
  - Delete handler

**Deliverables:**
- Complete RobotModel management UI
- Image upload và preview
- NavigationPoint visualization
- CRUD operations working

---

### Phase 7: Frontend - Robot Management

#### 7.1. RobotManager Page
- [ ] Create `RobotManager.razor` page
  - Route: `/robots`
  - Layout: Header với Search, Filters, và Add button
  - Single table layout (no Right Panel)

#### 7.2. RobotTable Component
- [ ] Create `RobotTable.razor` component
  - MudTable với columns: RobotId, Name, Model, Map, Actions
  - Search functionality (by RobotId, Name)
  - Filter by Model (MudSelect dropdown)
  - Filter by Map (MudSelect dropdown)
  - Sorting
  - Pagination
  - Actions: View Detail (link), Edit, Delete buttons

#### 7.3. Create Robot Dialog
- [ ] Create `CreateRobotDialog.razor`
  - Form fields: RobotId, Name, ModelId (dropdown), MapId (dropdown, optional)
  - Validation
  - Submit handler

#### 7.4. Edit Robot Dialog
- [ ] Create `EditRobotDialog.razor`
  - Pre-fill form với existing data
  - ModelId và MapId dropdowns
  - Validation
  - Submit handler

#### 7.5. Delete Robot Dialog
- [ ] Create `DeleteRobotDialog.razor`
  - Confirmation message
  - Delete handler

**Deliverables:**
- Complete Robot management UI
- Table với search và filters
- CRUD operations working

---

### Phase 8: Frontend - RobotDetail (VDA5050)

#### 8.1. SignalR Hub Client
- [ ] Create `RobotStateHubClient.cs` trong Client project
  - Connect to `/hubs/robot-state`
  - Methods: SubscribeToRobot, UnsubscribeFromRobot
  - Event handlers: OnStateUpdate, OnVisualizationUpdate
  - Connection management (connect, disconnect)

#### 8.2. RobotDetail Page
- [ ] Create `RobotDetail.razor` page
  - Route: `/robots/{robotId}/detail`
  - Header với Robot name, Back button, Refresh button
  - Two-column layout (60% State, 40% Manual Actions)
  - Initialize SignalR connection
  - Subscribe to robot khi vào page
  - Unsubscribe khi rời page

#### 8.3. VDA5050 State Cards
- [ ] Create `HeaderInfoCard.razor` - Header info
- [ ] Create `PositionCard.razor` - AgvPosition
- [ ] Create `VelocityCard.razor` - Velocity
- [ ] Create `BatteryCard.razor` - BatteryState
- [ ] Create `OrderInfoCard.razor` - Order information
- [ ] Create `MapsCard.razor` - Maps array
- [ ] Create `NodeStatesCard.razor` - NodeStates table
- [ ] Create `EdgeStatesCard.razor` - EdgeStates table
- [ ] Create `ActionStatesCard.razor` - ActionStates table
- [ ] Create `LoadsCard.razor` - Loads table
- [ ] Create `ErrorsCard.razor` - Errors table với color coding
- [ ] Create `InformationCard.razor` - Information array với color coding
- [ ] Create `SafetyStateCard.razor` - SafetyState

#### 8.4. VDA5050 Visualization Cards
- [ ] Create `VisualizationPositionCard.razor` - Visualization agvPosition
- [ ] Create `VisualizationVelocityCard.razor` - Visualization velocity

#### 8.5. Manual Actions Panel
- [ ] Create `ManualActionsPanel.razor`
  - Action Type selector (MudSelect với ActionType enum)
  - Action Parameters editor (Key-Value pairs với Add/Remove)
  - Send Action button
  - Action History (recent actions sent)
  - Call API endpoint để send action

#### 8.6. State Update Integration
- [ ] Integrate SignalR events vào RobotDetail page
  - Handle OnStateUpdate event
  - Update tất cả State cards
  - Handle OnVisualizationUpdate event
  - Update Visualization cards
  - Error handling cho connection issues

**Deliverables:**
- Complete RobotDetail page
- Real-time State và Visualization updates
- Manual Actions functionality
- All VDA5050 fields displayed

---

### Phase 9: Testing & Polish

#### 9.1. Unit Tests (Optional)
- [ ] Test Services (RobotModelService, RobotService)
- [ ] Test Controllers
- [ ] Test Image Storage Service

#### 9.2. Integration Testing
- [ ] Test full flow: Create RobotModel → Upload Image → Create Robot → View Detail
- [ ] Test SignalR connection và updates
- [ ] Test error scenarios

#### 9.3. UI/UX Polish
- [ ] Verify responsive design
- [ ] Add loading states
- [ ] Add error messages
- [ ] Add success notifications
- [ ] Verify navigation flows

#### 9.4. Documentation
- [ ] Update API documentation
- [ ] Add code comments
- [ ] Create user guide (nếu cần)

**Deliverables:**
- Fully tested module
- Polished UI/UX
- Documentation complete

---

### Phase 10: Manual Actions API (Future)

#### 10.1. Manual Actions Endpoint
- [ ] Create endpoint: POST `/api/robots/{robotId}/actions`
- [ ] Validate action type và parameters
- [ ] Forward action đến robot (MQTT/HTTP)
- [ ] Return response

**Note:** Phase này sẽ implement sau khi có RobotConnections module để forward actions đến robot.

---

## Implementation Summary

| Phase | Description | Estimated Tasks | Status |
|-------|-------------|-----------------|--------|
| Phase 1 | Database & Entities | 4 tasks | [ ] Pending |
| Phase 2 | Shared DTOs | 3 tasks | [ ] Pending |
| Phase 3 | Backend Services | 4 tasks | [ ] Pending |
| Phase 4 | API Controllers | 4 tasks | [ ] Pending |
| Phase 5 | SignalR Hub | 3 tasks | [ ] Pending |
| Phase 6 | Frontend - RobotModel | 9 tasks | [ ] Pending |
| Phase 7 | Frontend - Robot | 5 tasks | [ ] Pending |
| Phase 8 | Frontend - RobotDetail | 6 tasks | [ ] Pending |
| Phase 9 | Testing & Polish | 4 tasks | [ ] Pending |
| Phase 10 | Manual Actions API | 1 task | [ ] Future |

**Total:** ~43 tasks across 10 phases

---

## Notes & Considerations

### Validation Rules

**RobotModel:**
- ModelName: Required, unique, max 256 chars
- Length, Width: Required, > 0
- ImageWidth, ImageHeight: Required, > 0
- NavigationPointX, Y: Required
- NavigationType: Required

**Robot:**
- RobotId: Required, unique, max 64 chars
- Name: Required, max 256 chars
- ModelId: Required, must exist
- MapId: Optional, must exist if provided

### Business Rules

1. **Delete RobotModel:**
   - Không được xóa nếu có Robot đang sử dụng
   - Phải xóa tất cả Robot trước

2. **Delete Robot:**
   - Có thể xóa bất cứ lúc nào
   - Cn nhắc xóa các dữ liệu liên quan (orders, history, etc.)

3. **Update RobotModel:**
   - Có thể update bất cứ lúc nào
   - Các Robot hiện tại không bị ảnh hưởng

### Performance Considerations

1. **Pagination:** Sử dụng pagination cho list views
2. **Lazy Loading:** Load details khi cần
3. **Caching:** Cache RobotModel list (ít thay đổi)
4. **SignalR:** Limit frequency của State messages

---

## ✅ Checklist

### Database
- [ ] NavigationType enum
- [ ] RobotModel entity
- [ ] Robot entity
- [ ] ApplicationDbContext update
- [ ] Migration
- [ ] Indexes

### Backend
- [ ] IRobotModelService
- [ ] RobotModelService
- [ ] IRobotService
- [ ] RobotService
- [ ] IRobotModelImageStorageService
- [ ] RobotModelImageStorageService
- [ ] DTOs (trong RobotNet10.FleetManager.Shared)
- [ ] RobotModelController
- [ ] RobotController
- [ ] RobotModelImagesController
- [ ] RobotStateHub (SignalR)
- [ ] Service registration

### Frontend - RobotModel
- [ ] RobotModelManager page
- [ ] RobotModelListPanel
- [ ] RobotModelDetailsPanel (với Image Preview & NavigationPoint)
- [ ] CreateDialog (với image upload)
- [ ] EditDialog (với image upload)
- [ ] DeleteDialog

### Frontend - Robot
- [ ] RobotManager page (table only, no Right Panel)
- [ ] RobotTable component
- [ ] CreateDialog
- [ ] EditDialog
- [ ] DeleteDialog

### Frontend - RobotDetail
- [ ] RobotDetail page
- [ ] RobotStateHubClient (SignalR client)
- [ ] VDA5050StatePanel (đầy đủ State & Visualization)
- [ ] InformationCard component
- [ ] ManualActionsPanel
- [ ] SignalR event handlers (OnStateUpdate, OnVisualizationUpdate)

---

**End of Architecture Document**
