# RobotMonitor Architecture - Design Document
_Last Updated: 2024-12-XX_

## Overview

Tài liệu này mô tả cấu trúc và thiết kế cho **RobotMonitor** - trang giám sát robot trên layout map. RobotMonitor cho phép người dùng xem vị trí và trạng thái của các robot trong thời gian thực trên layout map với background image.

**Framework:** MudBlazor  
**Note:** Tài liệu này tập trung vào cấu trúc và thiết kế, chưa triển khai code.

---

## Requirements Summary

### **1. Layout Base (từ LayoutEditor)**
- Sử dụng cơ chế zoom, pan tương tự LayoutEditor
- Hiển thị background image (SLAM Map)
- Hiển thị grid (tùy chọn)
- Hiển thị nodes và edges của layout
- **KHÔNG** có các event click hay scanner như LayoutEditor

### **2. Robot Display**
- Mỗi robot được hiển thị như một image (từ robot model)
- Image được lấy từ model của robot đó
- Robot được đặt tại vị trí từ StateMsg (x, y, theta)

### **3. SignalR Integration**
- Thông tin robot được lấy bằng SignalR
- **Subscribe đến HubServer và hiển thị theo broadcast từ phía Server**
- Chỉ hiển thị những robot có dữ liệu từ bản tin
- Thêm robot nếu bản tin có robot chưa được hiển thị
- Xóa robot nếu bản tin không còn thông tin về robot đó

### **4. Robot Selection**
- Có cơ chế click vào robot để hiển thị thông tin của robot đó (Selected robot)
- Hiển thị thông tin robot selected ở panel bên phải

### **5. Layout Structure**
Layout gồm 3 phần:
- **Bên trái:**
  - **Bên trên:** Thanh công cụ (Toolbar)
  - **Bên dưới:** Layout monitor (SVG Canvas)
- **Bên phải:** Thông tin về robot đang được selected (Robot Info Panel)

### **6. Toolbar Components**
- **Buttons:**
  - ZoomIn
  - ZoomOut
  - FitScale (fit to screen)
  - Focus (tìm kiếm robot đang được selected, đưa view về giữa robot selected)
  - **Expand/Collapse RobotInfoPanel** (cạnh phía InfoPanel)
- **Checkboxes:**
  - FollowRobot(Selected) - Tự động follow robot selected khi di chuyển
  - Show Path - Hiển thị path của robot (nếu có)
  - Show Name - Hiển thị tên robot
  - Show Grid - Hiển thị grid
- **SelectBox:**
  - Chọn Layout
  - Chọn Version
  - Chọn Level
  - Chọn Robot (Selected Robot)

### **7. Robot Information Display**
Thông tin về robot selected sẽ hiển thị:
- **BatteryState** - Trạng thái pin (charge, voltage, health, charging)
- **Visualization** - Thông tin visualization từ VisualizationMsg
- **Errors** - Danh sách lỗi từ StateMsg.Errors
- **Informations** - Danh sách thông tin từ StateMsg.Information

---

## Architecture Overview

### **Component Hierarchy**
```
RobotMonitor (Page)
    → RobotMonitorComponent
        ├── MonitorToolbar (top left)
        ├── SvgMonitorCanvas (left, below toolbar)
        └── RobotInfoPanel (right)
            └── SelectedRobotInfo
                ├── BatteryStateCard
                ├── VisualizationCard
                ├── ErrorsCard
                └── InformationCard
```

### **Component Structure**
```
RobotNet10.FleetManager.Client/
└─ Components/
    └─ RobotMonitor/
        ├─ RobotMonitorComponent.razor       ← Main container (MudBlazor)
        ├─ RobotMonitorComponent.razor.css
        ├─ MonitorToolbar.razor               ← Toolbar with controls (MudBlazor)
        ├─ MonitorToolbar.razor.css
        ├─ SvgMonitorCanvas.razor             ← Main SVG canvas
        ├─ SvgMonitorCanvas.razor.css
        └─ RobotInfoPanel/
            ├─ RobotInfoPanel.razor           ← Container for robot info (MudBlazor)
            └─ SelectedRobotInfo.razor        ← Selected robot details
                ├─ BatteryStateCard.razor      ← Battery state display
                ├─ VisualizationCard.razor     ← Visualization display
                ├─ ErrorsCard.razor            ← Errors display
                └─ InformationCard.razor      ← Information display
```

### **Services Structure**
```
RobotNet10.FleetManager.Client/
└─ Services/
    └─ State/
        └─ RobotMonitorState.cs               ← Centralized state
```

---

## Design Specifications

### **1. Coordinate System**
| Item | Value |
|------|-------|
| Web Origin | Top-Left (0,0) |
| Layout Origin | Bottom-Left (0,0) |
| Transform | `WebY = ImageHeight - LayoutY` |
| Robot Position | Từ StateMsg (x, y, theta) trong world coordinates |

### **2. SVG Layers (Bottom → Top)**
1. Background Image (SLAM Map)
2. Grid (optional)
3. Edges (layout edges)
4. Nodes (layout nodes)
5. Robot Paths (optional, nếu Show Path = true)
6. Robots (robot images với position và rotation)
7. Robot Names (optional, nếu Show Name = true)
8. Selection Highlight (ring around selected robot)

### **3. Robot Display**
| Property | Source | Type |
|----------|--------|------|
| RobotId | StateMsg.SerialNumber | string |
| Position (X, Y) | StateMsg.Pose.X, StateMsg.Pose.Y | double (meters) |
| Orientation (Theta) | StateMsg.Pose.Theta | double (radians) |
| Image | RobotModel.Image (từ RobotModelId) | base64 string |
| Model Info | RobotDto.ModelId → RobotModelDto | DTO |
| BatteryState | StateMsg.BatteryState | BatteryState |
| Visualization | VisualizationMsg | VisualizationMsg |
| Errors | StateMsg.Errors | Error[] |
| Informations | StateMsg.Information | Information[] |

### **4. Viewport Controls**
| Control | Behavior |
|--------|----------|
| Pan | Middle mouse drag |
| Zoom | Mouse wheel (zoom at cursor position) |
| ZoomIn | Toolbar button (zoom at center) |
| ZoomOut | Toolbar button (zoom at center) |
| FitScale | Fit to image bounds |
| Focus | Center view on selected robot |

### **5. Display Settings**
| Setting | Default | Persist |
|---------|---------|---------|
| Show Grid | ✅ | Session |
| Show Background | ✅ | Session |
| Show Path | ❌ | Session |
| Show Name | ✅ | Session |
| FollowRobot | ❌ | Session |
| RobotInfoPanelExpanded | ✅ | Session |
| Selected Layout | - | Session |
| Selected Version | - | Session |
| Selected Level | - | Session |
| Selected Robot | - | Session |

---

## Data Flow

### **1. Initialization Flow**
```
User navigates to /robot-monitor
    → RobotMonitorComponent loads
    → RobotMonitorState.InitializeAsync()
        ├── Load Layouts (from API)
        ├── Load Versions (from selected Layout)
        ├── Load Levels (from selected Version)
        ├── Load Layout Data (Nodes, Edges, Background Image)
        ├── Load Robots (from API)
        ├── Load Robot Models (from API, for images)
        └── Connect SignalR
            └── Subscribe to all robots
    → Viewport initialized to fit image bounds
```

### **2. SignalR Update Flow (Broadcast từ Server)**
```
Server broadcasts StateMsg và VisualizationMsg (1Hz)
    → RobotStateHubClient.OnStateUpdate event
    → RobotStateHubClient.OnVisualizationUpdate event
    → RobotMonitorState.HandleStateUpdate(StateMsg)
    → RobotMonitorState.HandleVisualizationUpdate(VisualizationMsg)
        ├── Update robot position/state
        ├── Update robot visualization
        ├── Add robot if not exists
        └── Remove robot if timeout (no update for X seconds)
    → NotifyStateChanged()
    → UI updates (robot position, info panel)
```

### **3. Robot Selection Flow**
```
User clicks robot on canvas
    → SvgMonitorCanvas.HandleRobotClick(robotId)
    → RobotMonitorState.SelectRobot(robotId)
    → NotifyStateChanged()
    → RobotInfoPanel displays robot info
        ├── BatteryStateCard.Update(state)
        ├── VisualizationCard.Update(visualization)
        ├── ErrorsCard.Update(state)
        └── InformationCard.Update(state)
    → If FollowRobot = true → Focus on selected robot
```

### **4. Toolbar Actions Flow**
```
User clicks toolbar button
    → MonitorToolbar.HandleAction(action)
    → RobotMonitorState.Action(action)
        ├── ZoomIn/Out → Viewport.Zoom()
        ├── FitScale → Viewport.FitToScreen()
        ├── Focus → Viewport.FocusOnRobot(selectedRobotId)
        ├── ToggleExpandPanel → Toggle RobotInfoPanel visibility
        └── Toggle settings → Update display options
    → NotifyStateChanged()
    → UI updates
```

---

## State Management

### **RobotMonitorState Class Structure**

```csharp
public class RobotMonitorState
{
    // ===== DATA =====
    public Guid? SelectedLayoutId { get; set; }
    public Guid? SelectedVersionId { get; set; }
    public Guid? SelectedLevelId { get; set; }
    public LayoutLevelDto? Level { get; private set; }
    public List<NodeDto> Nodes { get; private set; } = new();
    public List<EdgeDto> Edges { get; private set; } = new();
    public byte[]? BackgroundImage { get; private set; }
    
    // ===== ROBOTS =====
    public Dictionary<string, RobotMonitorData> Robots { get; private set; } = new();
    public string? SelectedRobotId { get; set; }
    
    // ===== DISPLAY OPTIONS =====
    public bool ShowGrid { get; set; } = true;
    public bool ShowBackgroundImage { get; set; } = true;
    public bool ShowPath { get; set; } = false;
    public bool ShowName { get; set; } = true;
    public bool FollowRobot { get; set; } = false;
    public bool RobotInfoPanelExpanded { get; set; } = true;
    
    // ===== VIEWPORT =====
    public ViewportState Viewport { get; } = new();
    
    // ===== SIGNALR =====
    private RobotStateHubClient? _hubClient;
    
    // ===== EVENTS =====
    public event Action? OnStateChanged;
    
    // ===== METHODS =====
    public async Task InitializeAsync();
    public void HandleStateUpdate(StateMsg state);
    public void HandleVisualizationUpdate(VisualizationMsg visualization);
    public void SelectRobot(string? robotId);
    public void ZoomIn();
    public void ZoomOut();
    public void FitToScreen();
    public void FocusOnRobot(string robotId);
    public void ToggleFollowRobot();
    public void ToggleRobotInfoPanel();
    // ... other methods
}
```

### **RobotMonitorData Class**

```csharp
public class RobotMonitorData
{
    public string RobotId { get; set; } = string.Empty;
    public Guid? ModelId { get; set; }
    public string? ModelImageBase64 { get; set; }
    public double X { get; set; }
    public double Y { get; set; }
    public double Theta { get; set; } // radians
    public StateMsg? LastState { get; set; }
    public VisualizationMsg? LastVisualization { get; set; }
    public DateTime LastUpdateTime { get; set; }
    public List<(double X, double Y)>? Path { get; set; } // For path visualization
}
```

---

## Component Details (MudBlazor)

### **1. RobotMonitorComponent.razor**
**Purpose:** Main container component using MudBlazor

**Structure:**
```razor
<MudContainer MaxWidth="MaxWidth.False" Class="robot-monitor-container">
    <MudGrid Spacing="0">
        <!-- Left: Toolbar + Canvas -->
        <MudItem xs="12" md="@(State.RobotInfoPanelExpanded ? 8 : 12)">
            <MudStack Spacing="0">
                <!-- Toolbar -->
                <MonitorToolbar State="@State" />
                
                <!-- Canvas -->
                <SvgMonitorCanvas State="@State" />
            </MudStack>
        </MudItem>
        
        <!-- Right: Robot Info Panel -->
        @if (State.RobotInfoPanelExpanded)
        {
            <MudItem xs="12" md="4">
                <RobotInfoPanel State="@State" />
            </MudItem>
        }
    </MudGrid>
</MudContainer>
```

**Responsibilities:**
- Initialize state
- Setup SignalR connection
- Handle component lifecycle
- Subscribe/unsubscribe to SignalR events

---

### **2. MonitorToolbar.razor**
**Purpose:** Toolbar with all controls using MudBlazor

**Components:**
- **Buttons:** ZoomIn, ZoomOut, FitScale, Focus, Expand/Collapse Panel
- **Checkboxes:** FollowRobot, Show Path, Show Name, Show Grid
- **SelectBoxes:** Layout, Version, Level, Robot

**Layout:**
```razor
<MudPaper Class="pa-2" Elevation="2">
    <MudStack Row="true" AlignItems="AlignItems.Center" Spacing="2">
        <!-- Viewport Controls -->
        <MudButtonGroup>
            <MudIconButton Icon="@Icons.Material.Filled.ZoomIn" 
                          OnClick="HandleZoomIn" />
            <MudIconButton Icon="@Icons.Material.Filled.ZoomOut" 
                          OnClick="HandleZoomOut" />
            <MudIconButton Icon="@Icons.Material.Filled.FitScreen" 
                          OnClick="HandleFitScale" />
            <MudIconButton Icon="@Icons.Material.Filled.CenterFocusStrong" 
                          OnClick="HandleFocus" />
        </MudButtonGroup>
        
        <MudDivider Vertical="true" />
        
        <!-- Display Options -->
        <MudCheckBox @bind-Checked="State.FollowRobot" 
                     Label="Follow Robot" />
        <MudCheckBox @bind-Checked="State.ShowPath" 
                     Label="Show Path" />
        <MudCheckBox @bind-Checked="State.ShowName" 
                     Label="Show Name" />
        <MudCheckBox @bind-Checked="State.ShowGrid" 
                     Label="Show Grid" />
        
        <MudDivider Vertical="true" />
        
        <!-- SelectBoxes -->
        <MudSelect @bind-Value="State.SelectedLayoutId" 
                   Label="Layout" 
                   T="Guid?" />
        <MudSelect @bind-Value="State.SelectedVersionId" 
                   Label="Version" 
                   T="Guid?" />
        <MudSelect @bind-Value="State.SelectedLevelId" 
                   Label="Level" 
                   T="Guid?" />
        <MudSelect @bind-Value="State.SelectedRobotId" 
                   Label="Robot" 
                   T="string?" />
        
        <!-- Expand/Collapse Panel Button (cạnh phía InfoPanel) -->
        <MudSpacer />
        <MudIconButton Icon="@(State.RobotInfoPanelExpanded ? Icons.Material.Filled.ChevronRight : Icons.Material.Filled.ChevronLeft)" 
                      OnClick="HandleTogglePanel" />
    </MudStack>
</MudPaper>
```

**Responsibilities:**
- Handle toolbar button clicks
- Handle checkbox toggles
- Handle selectbox changes
- Update state accordingly

---

### **3. SvgMonitorCanvas.razor**
**Purpose:** SVG canvas for rendering layout and robots

**Rendering Layers:**
1. Background Image
2. Grid (if ShowGrid = true)
3. Edges
4. Nodes
5. Robot Paths (if ShowPath = true)
6. Robots (images with rotation)
7. Robot Names (if ShowName = true)
8. Selection Highlight

**Event Handling:**
- **Mouse Wheel:** Zoom
- **Middle Mouse Drag:** Pan
- **Robot Click:** Select robot
- **No other interactions** (unlike LayoutEditor)

**Robot Rendering:**
- Robot image positioned at (X, Y) from StateMsg
- Rotated by Theta (radians)
- Image from RobotModel (cached in state)
- Scale based on robot model dimensions and zoom level

**Responsibilities:**
- Render layout (background, grid, nodes, edges)
- Render robots with correct position and rotation
- Handle viewport interactions (zoom, pan)
- Handle robot selection

---

### **4. RobotInfoPanel.razor**
**Purpose:** Display information about selected robot using MudBlazor

**Structure:**
```razor
<MudPaper Class="pa-4" Elevation="2" Style="height: calc(100vh - 100px); overflow-y: auto;">
    <MudText Typo="Typo.h6" Class="mb-4">Robot Information</MudText>
    
    @if (State.SelectedRobotId != null && State.Robots.TryGetValue(State.SelectedRobotId, out var robot))
    {
        <SelectedRobotInfo RobotData="robot" State="State" />
    }
    else
    {
        <MudAlert Severity="Severity.Info">
            No robot selected. Click on a robot to view its information.
        </MudAlert>
    }
</MudPaper>
```

**Responsibilities:**
- Display selected robot information
- Update when selection changes
- Show robot state details

---

### **5. SelectedRobotInfo.razor**
**Purpose:** Display detailed robot information using MudBlazor Expansion Panels

**Structure:**
```razor
<MudExpansionPanels Dense="true" Elevation="0">
    <!-- Battery State Panel -->
    <MudExpansionPanel Text="Battery State" Icon="@Icons.Material.Filled.BatteryChargingFull" Expanded="true">
        <BatteryStateCard State="@robotData.LastState" />
    </MudExpansionPanel>
    
    <!-- Visualization Panel -->
    <MudExpansionPanel Text="Visualization" Icon="@Icons.Material.Filled.Visibility" Expanded="false">
        <VisualizationCard Visualization="@robotData.LastVisualization" />
    </MudExpansionPanel>
    
    <!-- Errors Panel -->
    <MudExpansionPanel Text="Errors" Icon="@Icons.Material.Filled.Error" Expanded="false">
        <ErrorsCard State="@robotData.LastState" />
    </MudExpansionPanel>
    
    <!-- Information Panel -->
    <MudExpansionPanel Text="Information" Icon="@Icons.Material.Filled.Info" Expanded="false">
        <InformationCard State="@robotData.LastState" />
    </MudExpansionPanel>
</MudExpansionPanels>
```

**Information Displayed:**
- **BatteryState:** Charge, Voltage, Health, Charging status (từ StateMsg.BatteryState)
- **Visualization:** Visualization data (từ VisualizationMsg)
- **Errors:** Error list (từ StateMsg.Errors)
- **Informations:** Information list (từ StateMsg.Information)

**Responsibilities:**
- Format and display robot data in tabs
- Update in real-time when state changes
- Reuse existing card components (BatteryCard, ErrorsCard, InformationCard)

---

### **6. BatteryStateCard.razor**
**Purpose:** Display battery state information

**Reuse:** Similar to `RobotDetail/BatteryCard.razor`

**Display:**
- Battery Charge (progress bar + percentage)
- Battery Voltage
- Battery Health
- Charging status (chip)

---

### **7. VisualizationCard.razor**
**Purpose:** Display visualization information from VisualizationMsg

**Display:**
- Visualization data from VisualizationMsg
- Format similar to other cards

---

### **8. ErrorsCard.razor**
**Purpose:** Display errors list

**Reuse:** Similar to `RobotDetail/ErrorsCard.razor`

**Display:**
- MudTable với columns: Error Type, Level, Description, Hint, References
- Color coding by ErrorLevel (NONE=Success, WARNING=Warning, FATAL=Error)

---

### **9. InformationCard.razor**
**Purpose:** Display information list

**Reuse:** Similar to `RobotDetail/InformationCard.razor`

**Display:**
- MudTable với columns: Info Type, Level, Description, References
- Color coding by InfoLevel (INFO=Info, DEBUG=Default)

---

## SignalR Integration

### **Subscription Strategy**

**Subscribe to All Robots (Broadcast từ Server)**
- Get list of all robots from API
- Subscribe to each robot individually
- Handle add/remove robots dynamically
- **Server broadcasts StateMsg và VisualizationMsg đến tất cả subscribed clients**

**Implementation:**
```csharp
private async Task SubscribeToAllRobots()
{
    // Get all robots from API
    var robots = await RobotApiService.GetAllAsync();
    
    foreach (var robot in robots)
    {
        await _hubClient.SubscribeToRobotAsync(robot.RobotId);
    }
}
```

### **Update Handling (Broadcast từ Server)**

```csharp
private void HandleStateUpdate(StateMsg state)
{
    var robotId = state.SerialNumber;
    
    // Get or create robot data
    if (!Robots.TryGetValue(robotId, out var robotData))
    {
        // Load robot model image
        robotData = new RobotMonitorData
        {
            RobotId = robotId,
            ModelId = GetRobotModelId(robotId), // From RobotDto
            ModelImageBase64 = await LoadRobotModelImage(robotId)
        };
        Robots[robotId] = robotData;
    }
    
    // Update position and state
    robotData.X = state.Pose?.X ?? 0;
    robotData.Y = state.Pose?.Y ?? 0;
    robotData.Theta = state.Pose?.Theta ?? 0;
    robotData.LastState = state;
    robotData.LastUpdateTime = DateTime.UtcNow;
    
    // Update path if ShowPath = true
    if (ShowPath)
    {
        UpdateRobotPath(robotData);
    }
    
    // If FollowRobot and this is selected robot, update viewport
    if (FollowRobot && SelectedRobotId == robotId)
    {
        FocusOnRobot(robotId);
    }
    
    NotifyStateChanged();
}

private void HandleVisualizationUpdate(VisualizationMsg visualization)
{
    var robotId = visualization.SerialNumber;
    
    if (Robots.TryGetValue(robotId, out var robotData))
    {
        robotData.LastVisualization = visualization;
        robotData.LastUpdateTime = DateTime.UtcNow;
        NotifyStateChanged();
    }
}
```

### **Robot Timeout (Remove Inactive Robots)**

```csharp
private void RemoveInactiveRobots()
{
    var timeout = TimeSpan.FromSeconds(10); // 10 seconds timeout
    var now = DateTime.UtcNow;
    
    var inactiveRobots = Robots
        .Where(kvp => now - kvp.Value.LastUpdateTime > timeout)
        .Select(kvp => kvp.Key)
        .ToList();
    
    foreach (var robotId in inactiveRobots)
    {
        Robots.Remove(robotId);
        if (SelectedRobotId == robotId)
        {
            SelectedRobotId = null;
        }
    }
    
    if (inactiveRobots.Count > 0)
    {
        NotifyStateChanged();
    }
}
```

---

## Viewport Operations

### **Zoom**
- Similar to LayoutEditor
- Zoom at cursor position (mouse wheel)
- Zoom at center (toolbar buttons)
- Limit zoom level (0.1x to 10x)

### **Pan**
- Middle mouse drag
- Incremental delta (like LayoutEditor fix)

### **FitToScreen**
- Fit viewport to image bounds
- Similar to LayoutEditor

### **FocusOnRobot**
- Center viewport on selected robot position
- Optional: Zoom to fit robot (or keep current zoom)

```csharp
public void FocusOnRobot(string robotId)
{
    if (!Robots.TryGetValue(robotId, out var robot))
        return;
    
    // Center viewport on robot
    var (physicalWidth, physicalHeight) = GetPhysicalDimensions();
    var svgX = WorldToSvg(robot.X, robot.Y).X;
    var svgY = WorldToSvg(robot.X, robot.Y).Y;
    
    Viewport.ViewBoxX = svgX - Viewport.ViewBoxWidth / 2;
    Viewport.ViewBoxY = svgY - Viewport.ViewBoxHeight / 2;
    
    NotifyStateChanged();
}
```

---

## Robot Image Rendering

### **Image Loading**
- Load robot model image when robot is first added
- Cache images in state (Dictionary<Guid, string> for base64)
- Load from API: `RobotModelApiService.GetImageAsync(modelId)`

### **Image Positioning**
- Position at (X, Y) from StateMsg
- Convert world coordinates to SVG coordinates
- Apply rotation by Theta (radians)

### **Image Scaling**
- Scale based on robot model dimensions (Length, Width)
- Adjust for zoom level
- Maintain aspect ratio

### **SVG Implementation**
```xml
<g transform="translate(@svgX, @svgY) rotate(@degrees)">
    <image href="data:image/png;base64,@robotData.ModelImageBase64"
           x="@(-robotModel.Length/2)"
           y="@(-robotModel.Width/2)"
           width="@robotModel.Length"
           height="@robotModel.Width"
           preserveAspectRatio="xMidYMid" />
</g>
```

---

## Key Design Decisions

### **1. Robot Data Management**
- **Decision:** Store robot data in Dictionary<string, RobotMonitorData>
- **Rationale:** Fast lookup by robotId, easy add/remove

### **2. SignalR Subscription**
- **Decision:** Subscribe to all robots individually, receive broadcast từ Server
- **Rationale:** More control, can unsubscribe specific robots, Server broadcasts to all subscribed clients

### **3. Robot Timeout**
- **Decision:** Remove robots after 10 seconds of no updates
- **Rationale:** Clean up inactive robots, avoid stale data

### **4. Follow Robot**
- **Decision:** Auto-update viewport when selected robot moves (if enabled)
- **Rationale:** Better UX for tracking specific robot

### **5. Path Visualization**
- **Decision:** Store path as list of (X, Y) points
- **Rationale:** Simple, can draw as polyline

### **6. MudBlazor Components**
- **Decision:** Use MudBlazor for all UI components
- **Rationale:** Consistent with existing codebase, faster development

### **7. Panel Expand/Collapse**
- **Decision:** Button on toolbar to toggle RobotInfoPanel visibility
- **Rationale:** More screen space for canvas when needed

---

## API Integration

### **APIs Used**
1. **Layout APIs:**
   - `GET /api/layouts` - Get all layouts
   - `GET /api/layouts/{layoutId}/versions` - Get versions
   - `GET /api/layouts/{layoutId}/versions/{versionId}/levels` - Get levels
   - `GET /api/layouts/{layoutId}/levels/{levelId}` - Get level info
   - `GET /api/layouts/{layoutId}/levels/{levelId}/data` - Get layout data
   - `GET /api/layouts/{layoutId}/levels/{levelId}/background-image` - Get background image

2. **Robot APIs:**
   - `GET /api/robots` - Get all robots
   - `GET /api/robots/{id}` - Get robot by ID

3. **Robot Model APIs:**
   - `GET /api/robot-models/{id}` - Get robot model
   - `GET /api/robot-models/{id}/image` - Get robot model image

---

## Implementation Phases

### **Phase 1: Foundation (Core Structure)**
**Status:** ❌ Not Started

**Deliverables:**
- [ ] `RobotMonitorState.cs` - Centralized state management
- [ ] `RobotMonitorComponent.razor` - Main container với MudBlazor layout
- [ ] Basic layout structure (left: toolbar+canvas, right: info panel)
- [ ] Host page: `RobotMonitor.razor` với route `/robot-monitor`
- [ ] CSS files for styling

**Key Features:**
- State management structure
- MudBlazor container và grid layout
- Basic component hierarchy

---

### **Phase 2: Toolbar**
**Status:** ❌ Not Started

**Deliverables:**
- [ ] `MonitorToolbar.razor` - Full toolbar với MudBlazor components
- [ ] Layout/Version/Level/Robot selectboxes (MudSelect)
- [ ] Zoom/Pan/FitScale/Focus buttons (MudIconButton)
- [ ] Display options checkboxes (MudCheckBox)
- [ ] Expand/Collapse Panel button

**Key Features:**
- All toolbar controls
- Event handlers
- State updates

---

### **Phase 3: SVG Canvas (Basic Layout)**
**Status:** ❌ Not Started

**Deliverables:**
- [ ] `SvgMonitorCanvas.razor` - SVG rendering component
- [ ] Background image rendering
- [ ] Grid rendering (togglable)
- [ ] Nodes and edges rendering
- [ ] Viewport controls (zoom, pan) - reuse logic from LayoutEditor

**Key Features:**
- Layout rendering
- Viewport interactions
- Coordinate transformations

---

### **Phase 4: Robot Display**
**Status:** ❌ Not Started

**Deliverables:**
- [ ] Robot image loading and caching
- [ ] Robot rendering with position and rotation
- [ ] Robot selection (click to select)
- [ ] Selection highlight

**Key Features:**
- Robot image display
- Position và rotation
- Click selection

---

### **Phase 5: SignalR Integration**
**Status:** ❌ Not Started

**Deliverables:**
- [ ] SignalR connection setup
- [ ] Subscribe to all robots
- [ ] Handle StateMsg updates (broadcast từ Server)
- [ ] Handle VisualizationMsg updates (broadcast từ Server)
- [ ] Add/remove robots dynamically
- [ ] Robot timeout handling

**Key Features:**
- Real-time updates
- Broadcast handling
- Dynamic robot management

---

### **Phase 6: Robot Info Panel - Basic**
**Status:** ❌ Not Started

**Deliverables:**
- [ ] `RobotInfoPanel.razor` - Container với MudBlazor
- [ ] `SelectedRobotInfo.razor` - Main info component với MudTabs
- [ ] Basic structure for tabs

**Key Features:**
- Panel layout
- Tab structure

---

### **Phase 7: Robot Info Panel - Content**
**Status:** ❌ Not Started

**Deliverables:**
- [ ] `BatteryStateCard.razor` - Battery state display (reuse từ RobotDetail)
- [ ] `VisualizationCard.razor` - Visualization display
- [ ] `ErrorsCard.razor` - Errors display (reuse từ RobotDetail)
- [ ] `InformationCard.razor` - Information display (reuse từ RobotDetail)
- [ ] Real-time updates khi state changes

**Key Features:**
- All information cards
- Real-time updates
- MudBlazor components

---

### **Phase 8: Advanced Features**
**Status:** ❌ Not Started

**Deliverables:**
- [ ] Follow Robot mode
- [ ] Path visualization
- [ ] Robot name display
- [ ] Focus on robot
- [ ] Panel expand/collapse animation

**Key Features:**
- Advanced viewport features
- Path tracking
- UX improvements

---

### **Phase 9: Polish**
**Status:** ❌ Not Started

**Deliverables:**
- [ ] Error handling
- [ ] Loading states
- [ ] Performance optimization
- [ ] UI/UX improvements
- [ ] Responsive design

**Key Features:**
- Production-ready features
- Performance tuning
- User experience

---

## Next Steps

1. **Review and approve architecture**
2. **Start Phase 1: Foundation**
3. **Iterate through phases**

---

**Last Updated:** 2024-12-XX  
**Status:** Design Phase - Awaiting Approval  
**Framework:** MudBlazor
