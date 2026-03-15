# LayoutEditor Implementation - Development Log
_Last Updated: 2024-12-03_

## Overview

Tài liệu này ghi lại quá trình xây dựng **LayoutEditor** - trang chỉnh sửa bản đồ cho robot AGV/AMR. LayoutEditor cho phép người dùng vẽ và chỉnh sửa nodes, edges, stations trên canvas SVG với background image.

**Note:** Quá trình xây dựng LayoutManager đã được lưu riêng trước đó.

---

## Design Specifications (From Initial Discussion)

### **1. Coordinate System**
| Item | Value |
|------|-------|
| Web Origin | Top-Left (0,0) |
| Layout Origin | Bottom-Left (0,0) |
| Transform | `WebY = ImageHeight - LayoutY` |
| Mouse Display | World Coordinates (meters) - góc trên trái |

### **2. SVG Layers (Bottom → Top)**
1. Background Image (SLAM Map)
2. Grid
3. Edges + Trajectories
4. Trajectory Control Points (khi edit)
5. Nodes
6. Station Overlays
7. Selection Highlights
8. Temporary Drawing (create edge preview)

### **3. Node Properties**
| Property | Editable | Type |
|----------|----------|------|
| NodeId | ✅ | string |
| NodeName | ✅ | string |
| NodeDescription | ✅ | string |
| X, Y | ✅ | double (meters) |
| MapId | ✅ | string? |
| Station Info | ❌ (read-only) | display |
| VehicleProperties | ✅ | per VehicleType |

### **4. Edge Properties**
| Property | Editable | Type |
|----------|----------|------|
| EdgeId | ✅ | string |
| EdgeName | ✅ | string |
| EdgeDescription | ✅ | string |
| StartNodeId | ❌ | Guid (read-only) |
| EndNodeId | ❌ | Guid (read-only) |
| Length | ❌ | double (auto-calc) |
| VehicleProperties | ✅ | per VehicleType |

### **5. Edge Vehicle Properties**
| Property | Type |
|----------|------|
| VehicleOrientation | double? |
| OrientationType | enum (GLOBAL, TANGENTIAL) |
| RotationAllowed | bool? |
| RotationAtStartNodeAllowed | enum (NONE, CCW, CW, BOTH) |
| RotationAtEndNodeAllowed | enum (NONE, CCW, CW, BOTH) |
| MaxSpeed, MaxRotationSpeed | double? |
| MinHeight, MaxHeight | double? |
| LoadRestriction_* | bool?, string? |
| Trajectory | JSON (NURBS) |

### **6. Node Vehicle Properties**
| Property | Type |
|----------|------|
| Theta | double? (radians) |
| Actions | JSON (Form Builder) |

### **7. Display Settings**
| Setting | Default | Persist |
|---------|---------|---------|
| Show Edge Names | ✅ | Session |
| Show Node Names | ✅ | Session |
| Show Grid | ✅ | Session |
| Show Background | ✅ | Session |
| Grid Spacing | 1.0m | Session |
| Selected VehicleType | First | Session |

### **8. Visual Representations**
| Element | Style |
|---------|-------|
| Node (normal) | Circle, scale with zoom |
| Node (with Station) | Circle, different color (green) |
| Edge | Line with arrow at end |
| Edge Direction | Arrow at EndNode |
| Edge Name | Text above, center of edge |
| Node Name | Text below, center of node |
| Selection | Highlight ring/glow |
| Trajectory | NURBS curve (selected VehicleType only) |
| Control Points | Small circles (when editing) |
| Create Edge Preview | Dashed line from node1 to mouse (Option B) |

### **9. Operations**
| Operation | Behavior |
|-----------|----------|
| Select | Click = select single, Ctrl+Click = add to selection |
| Scanner | Drag rectangle to multi-select (objects **completely** within rectangle - Option C) |
| CreateEdge 1-Way | Click node1 → node2, creates 1 edge |
| CreateEdge 2-Way | Click node1 → node2, creates 2 edges (A→B, B→A) |
| Copy | Duplicate nodes with new IDs, duplicate edges, NO stations |
| Move | Drag selected nodes (no snap to grid) |
| Merge | Combine selected nodes at center position |
| Split | Split 1 node into N nodes (N = edge count), auto offset |
| Align H-Left | Align selected nodes to leftmost X |
| Align H-Right | Align selected nodes to rightmost X |
| Align H-Center | Align selected nodes to average X |
| Align V-Top | Align selected nodes to topmost Y |
| Align V-Bottom | Align selected nodes to bottommost Y |
| Align V-Center | Align selected nodes to average Y |

### **10. Undo/Redo**
| Supported | Not Supported |
|-----------|---------------|
| Move operations | Create/Delete |
| Alignment operations | Property changes |

### **11. Keyboard Shortcuts**
| Key | Action |
|-----|--------|
| Ctrl+Z | Undo |
| Ctrl+Y | Redo |
| Ctrl+S | Save |
| Ctrl+C | Copy selected nodes/edges |
| Ctrl+M | Move mode (if nodes selected) |
| Delete | Delete selected |
| Escape | Cancel current operation (CreateEdge, Copy) |

### **12. Viewport**
| Setting | Value |
|---------|-------|
| Initial | Zoom to fit image bounds |
| Pan | Middle mouse drag OR toolbar button |
| Zoom | Mouse wheel OR toolbar buttons (zoom at cursor position) |
| Fit | Toolbar button |

### **13. Trajectory Editor**
| Setting | Value |
|---------|-------|
| Display | Only when edge selected (single select mode, not multi-select) |
| VehicleType | Show trajectory of selected VehicleType |
| Degree | User selectable (1, 2, 3) |
| Control Points | Managed via Right Panel buttons |
| Edit | Drag control points on canvas |
| Default Creation | Auto-generate: 2 control points tại StartNode và EndNode (straight line) - Option A |

### **14. Trajectory Degree Change Logic**
**Khi TĂNG Degree (thêm control points):**
- **Degree 1 → Degree 2:** Thêm 1 point tại giữa curve (t = 0.5)
- **Degree 2 → Degree 3:** Thêm 1 point tại t = 0.33 hoặc t = 0.67
- Chèn điểm mới ở giữa 2 điểm có khoảng cách lớn nhất để giữ biên dạng ít thay đổi

**Khi GIẢM Degree (xóa control points):**
- **Degree 3 → Degree 2:** Giữ P0 và P_last, tính P_middle = weighted average của các control points cũ
- **Degree 2 → Degree 1:** Chỉ giữ P0 và P_last, curve thành đường thẳng
- Giảm từ n points xuống n-1 points bằng cách tính trung bình các cặp điểm liền kề

### **15. Actions Form Builder**
| Feature | Behavior |
|---------|----------|
| ActionType | Dropdown (VehicleType ActionDefaults) + Custom text input |
| Parameters | Key-Value pairs, add/remove individual parameters |
| Defaults | Pre-filled from VehicleType ActionDefaults, có thể thêm/xóa tiếp |
| Validation | JSON syntax + structure |

### **16. CheckLayout Validations**
| Check | Description |
|-------|-------------|
| Edge Min Length | Edge length < EdgeMinLengthCreate in settings |
| (More to be added) | ... |

### **17. Toolbar Order (Final)**
```
[Scanner][CreateEdge 1-Way▼][Select] │ [Zoom][Fit] │ 
[H-Left][H-Right][H-Center][V-Top][V-Bottom][V-Center] [Copy][Move] │ 
[Merge][Split] │ 
VehicleType: [AMR-T800 ▼] │ 
[Undo][Redo] [Save] [Delete] [Check] [Exit]
```

**Note:** Display Options và Grid Spacing đã được chuyển vào Settings Tab (không còn trên Toolbar).

### **18. Exit Button**
- **Behavior:** Quay về LayoutManager page (Option A)

### **19. Component Structure**
```
RobotNet10.MapEditor/
├─ Components/
│   └─ LayoutEditor/
│       ├─ LayoutEditorComponent.razor       ← Main container
│       ├─ LayoutEditorComponent.razor.css
│       ├─ EditorToolbar.razor               ← Toolbar with all buttons
│       ├─ EditorToolbar.razor.css
│       ├─ MousePositionDisplay.razor        ← World coordinates display
│       ├─ SvgEditorCanvas.razor             ← Main SVG canvas
│       ├─ SvgEditorCanvas.razor.css
│       ├─ RightPanel/
│       │   ├─ EditorRightPanel.razor        ← Container for tabs
│       │   ├─ PropertiesTab.razor           ← Selected object properties
│       │   ├─ NodePropertiesEditor.razor
│       │   ├─ EdgePropertiesEditor.razor
│       │   ├─ VehiclePropertiesEditor.razor
│       │   ├─ TrajectoryEditor.razor        ← NURBS control points
│       │   └─ SettingsTab.razor             ← Layout level settings
│       └─ Dialogs/
│           ├─ ActionsFormDialog.razor       ← Actions form builder
│           ├─ CheckLayoutResultDialog.razor ← Validation results
│           └─ UnsavedChangesDialog.razor    ← Confirm leave
│
├─ Services/
│   └─ State/
│       ├─ LayoutEditorState.cs              ← Centralized state
│       ├─ EditorCommand.cs                  ← For Undo/Redo
│       └─ EditorMode.cs                     ← Enum: Select, CreateEdge, etc.
│
└─ wwwroot/
    └─ js/
        └─ svgEditor.js                      ← JavaScript for SVG interactions
```

### **20. Host Page**
```
RobotNet10.RobotApp.Client/
└─ Pages/
    └─ LayoutEditor.razor                    ← Host page with route
        @page "/layout-editor/{LevelId:guid}"
```

---

## Key Design Decisions (Q&A Summary)

### **Q8: Trajectory Display**
- **Q8.1:** Hiển thị khi edge được select ở chế độ edit (không phải multi-select ở scanner)
- **Q8.2:** Option B - Trajectory chỉ hiển thị cho VehicleType được chọn
- **Q8.3:** Degree có thể thay đổi (1, 2, 3), số lượng control points tương ứng với degree

### **Q9: Node Properties**
- **Q9.1:** Option B - Station info hiển thị trong Node Properties Tab

### **Q10: Edge/Node Names**
- **Q10.1:** Option D - Edge names hiển thị ở trên, center của edge
- **Q10.2:** Scale với zoom level

### **Q11: Station Info Display**
- **Q11.1:** Option B - Station info trong Node Properties Tab
- **Q11.2:** Tab Node Properties, trong đó sẽ có cả thông tin của Station

### **Q12: Actions Form Builder**
- **Q12.1:** Option C - VehicleType có ActionDefaults, dropdown hiển thị defaults + cho phép nhập custom text
- **Q12.2:** Có thể thêm/xóa từng parameter. Nếu ActionDefault đã có parameters thì sẽ thêm/xóa tiếp vào những parameters default đó

### **Q13: Keyboard Shortcuts**
- **Q13.1:** Có các shortcuts: Ctrl+Z (Undo), Ctrl+Y (Redo), Ctrl+S (Save), Delete (Delete selected)

### **Q14: Selection Behavior**
- **Q14.1:** Option A - Nếu chỉ Click thì sẽ select sang đối tượng mới và unselect đối tượng cũ

### **Q15: Box Select**
- **Q15.1:** Option A - Box select trong Scanner mode

### **Q16: NURBS Degree Change**
- **Q16.1:** Khi thay đổi Degree, control points được thêm/xóa tự động với logic giữ biên dạng ít thay đổi nhất (xem section 14 ở trên)

### **Q17: Default Trajectory**
- **Q17.1:** Option A - Auto-generate: 2 control points tại StartNode và EndNode (straight line)

### **Q18: Box Select Behavior**
- **Q18.1:** Option C - Objects **hoàn toàn** nằm trong rectangle

### **Q19: Exit Button**
- **Q19:** Option A - Quay về LayoutManager page

### **Q20: Create Edge Preview**
- **Q20:** Option B - Đường nét liền màu khác (e.g., gray) từ node đầu tiên đến vị trí mouse

---

## Implementation Phases

### **Phase 1: Foundation (Core Structure)** ✅ COMPLETE
**Status:** Hoàn thành trong cuộc hội thoại ban đầu

**Deliverables:**
- `LayoutEditorComponent.razor` - Main container với left canvas, right panel
- `EditorToolbar.razor` - Full toolbar với tất cả buttons
- `LayoutEditorState.cs` - Centralized state management
- Host page: `RobotApp.Client/Pages/LayoutEditor.razor` với route `/layout-editor/{LevelId:guid}`
- Navigation từ LayoutManager page

**Key Features:**
- State management với data loading (Level, Nodes, Edges, Stations, VehicleTypes)
- Selection management (single/multi-select)
- Viewport control structure (`ViewportState` class)
- Coordinate transforms (SVG ↔ World)
- Undo/Redo stack (Command pattern với `EditorCommand` abstract class)
- Editor modes enum (`Select`, `Scanner`, `CreateEdge1Way`, `CreateEdge2Way`, `Pan`, `Move`, `Copy`)

**State Management Structure:**
- `LayoutEditorState` - Centralized state với:
  - Data: `Level`, `Nodes`, `Edges`, `Stations`, `VehicleTypes`
  - Selection: `SelectedNodeIds`, `SelectedEdgeIds`
  - Viewport: `ViewportState` (ViewBoxX, ViewBoxY, ViewBoxWidth, ViewBoxHeight, ZoomLevel)
  - Display options: `ShowEdgeNames`, `ShowNodeNames`, `ShowGrid`, `ShowBackgroundImage`, `GridSpacing`
  - Undo/Redo: `UndoStack`, `RedoStack`
  - Editor mode: `CurrentMode`
  - Methods: `InitializeAsync()`, `Pan()`, `Zoom()`, `FitToScreen()`, `SelectNodes()`, `SelectEdges()`, etc.

**Command Pattern:**
- `EditorCommand` abstract class với `Execute()` và `Undo()` methods
- `MoveNodesCommand` - Example command cho move operations
- Commands được push vào `UndoStack` khi execute

---

### **Phase 2: SVG Canvas (Basic)** ✅ COMPLETE
**Status:** Hoàn thành trong cuộc hội thoại ban đầu

**Deliverables:**
- `SvgEditorCanvas.razor` - SVG rendering component
- `MousePositionDisplay.razor` - World coordinates display (góc trên trái)
- `svgEditor.js` - JavaScript interop module

**Key Features:**
- Background image rendering (Y-axis flip để match world coordinates)
- Grid rendering (togglable, configurable spacing)
- Nodes rendering (circles, green color for nodes with stations)
- Edges rendering (lines with direction arrows at EndNode)
- Edge/Node names (togglable, scale with zoom level)
- Box select rectangle visualization (Scanner mode)
- Create edge preview line (dashed/gray line from start node to mouse)
- Mouse position tracking (world coordinates in meters, displayed top-left)

**Coordinate System:**
- **World Coordinates:** Bottom-left origin (0,0), Y increases upward (meters)
- **SVG Coordinates:** Top-left origin (0,0), Y increases downward (pixels)
- **Transform:** `svgY = physicalHeight - worldY` (flip Y axis)

**JavaScript Interop (`svgEditor.js`):**
- Mouse events: `mousemove`, `mousedown`, `mouseup`, `wheel`
- Keyboard shortcuts: `keydown` (Ctrl+Z/Y/S, Delete, Escape)
- Coordinate conversion: `screenToSvg()`, `screenToSvgArray()` (exported for Blazor)
- SVG element reference management

**Rendering Layers (implemented):**
1. Background Image (if available)
2. Grid (if `ShowGrid` = true)
3. Edges (with arrows and names if enabled)
4. Nodes (circles with names if enabled)
5. Selection highlights (rings around selected nodes)
6. Box select rectangle (when in Scanner mode)
7. Create edge preview line (when creating edge)

**Event Handling:**
- `OnMouseMove` - Updates mouse position, handles box select, pan, create edge preview
- `OnMouseDown` - Handles selection, starts pan, starts create edge
- `OnMouseUp` - Ends pan, completes box select, completes create edge
- `OnWheel` - Handles zoom (with cursor position preservation)

---

### **Phase 3: Viewport Controls** [ ] IN PROGRESS
**Status:** Đã implement cơ bản, đang polish và fix bugs

#### **3.1. Pan (Middle Mouse Drag)** ✅ FIXED
**Vấn đề ban đầu:**
- Pan bị giật và không di chuyển đúng theo chuột
- Delta bị cộng dồn khi di chuyển chuột

**Nguyên nhân:**
- Tính delta từ điểm bắt đầu pan mỗi lần mouse move
- Khi ViewBox thay đổi sau mỗi lần pan, việc convert `panStartScreen` sang SVG cho giá trị khác
- Gây ra việc cộng dồn delta

**Giải pháp:**
- Thay đổi từ tính delta từ điểm bắt đầu sang **incremental delta**
- Lưu `panLastScreen` (vị trí screen của lần move trước)
- Mỗi lần mouse move:
  1. Convert `panLastScreen` và `currentScreen` sang SVG (dùng ViewBox hiện tại)
  2. Tính delta = `lastSvg - currentSvg`
  3. Pan ViewBox theo delta
  4. Update `panLastScreen = currentScreen`

**Code Changes:**
```csharp
// Thêm panLastScreen để track vị trí trước đó
private (double X, double Y)? panLastScreen;

// Trong OnMouseMove:
if (isPanning && panLastScreen.HasValue)
{
    // Tính incremental delta từ lần move trước
    _ = PanIncrementalAsync(panLastScreen.Value.X, panLastScreen.Value.Y, screenX, screenY);
    panLastScreen = (screenX, screenY);
}

// Trong OnMouseDown (button == 1):
panStartScreen = (screenX, screenY);
panLastScreen = (screenX, screenY); // Initialize
```

**JavaScript Changes:**
- Thêm `screenToSvgArray()` function để export cho Blazor
- `OnMouseMove` và `OnMouseDown` nhận thêm `screenX, screenY` parameters

#### **3.2. Zoom (Mouse Wheel)** ✅ FIXED
**Vấn đề ban đầu:**
- Zoom không giữ tọa độ mouse không đổi
- Zoom không chính xác tại vị trí cursor

**Giải pháp:**
- Tính tỷ lệ vị trí cursor trong viewBox hiện tại
- Giữ điểm cursor không đổi trong world coordinates khi zoom
- Logic:
  ```csharp
  // Tính ratio của cursor trong viewBox
  var ratioX = (svgCenterX - ViewBoxX) / ViewBoxWidth;
  var ratioY = (svgCenterY - ViewBoxY) / ViewBoxHeight;
  
  // New dimensions
  var newWidth = ViewBoxWidth / factor;
  var newHeight = ViewBoxHeight / factor;
  
  // Adjust ViewBox để giữ cursor tại cùng vị trí world
  ViewBoxX = svgCenterX - ratioX * newWidth;
  ViewBoxY = svgCenterY - ratioY * newHeight;
  ```

#### **3.3. Grid Rendering** ✅ FIXED
**Thay đổi:**
- `stroke="#999"` (đậm hơn, từ #ccc)
- `stroke-width="0.04"` (đậm gấp đôi, từ 0.02)
- `opacity="0.7"` (rõ hơn, từ 0.5)
- Thêm `stroke-dasharray="0.1,0.1"` (nét đứt)

---

### **Phase 4: Selection** [ ] PARTIAL
**Status:** Cơ bản đã có, cần enhancement

**Đã có:**
- Single select (click)
- Multi-select (Ctrl+click)
- Box select (Scanner mode)
- Selection visual feedback

**Cần làm:**
- Enhancement và polish
- Better visual feedback

---

### **Phase 5: Create Edge** ✅ COMPLETE
**Status:** Đã hoàn thành

**Đã implement:**
- CreateEdge 1-Way mode với API call (`CreateEdgeAsync`)
- CreateEdge 2-Way mode với API call (tạo 2 edges ngược chiều)
- Edge preview while creating (preview line + preview nodes)
- Smart node detection (tích hợp API - tự động tìm node trong `NodeProximityRadius` hoặc tạo mới)
- Preview node hiển thị tại vị trí click đầu tiên và vị trí mouse
- Escape key để cancel CreateEdge operation

**API Integration:**
- `POST /api/edges` - Create edge với smart node detection
- Backend tự động tìm hoặc tạo nodes tại tọa độ start/end
- Nếu điểm nằm trong `NodeProximityRadius` của node hiện có → kết nối với node đó
- Nếu không → tạo node mới tại tọa độ đó

**Visual Features:**
- Preview line: dashed line từ start node đến mouse position
- Preview nodes: semi-transparent circles tại start và end positions
- 2-way edges: hiển thị thành 2 đường song song với offset

---

### **Phase 6: Edit Operations** [ ] PARTIAL
**Status:** Đã implement một phần

#### **6.1. Move Nodes** ✅ COMPLETE
- **Trigger:** Ctrl + Drag (hoặc Move mode với Ctrl+M)
- **Behavior:** Di chuyển node theo chuột, khi thả Ctrl thì giữ nguyên vị trí hiện tại
- **Undo/Redo:** Hỗ trợ qua `MoveNodesCommand`
- **Change Tracking:** Đánh dấu nodes đã modified để Save sau

#### **6.2. Copy Nodes/Edges** ✅ COMPLETE
- **Trigger:** Toolbar button hoặc Ctrl+C (khi có selection)
- **Mode:** `EditorMode.Copy` - dedicated mode với preview
- **Behavior:**
  - Click và drag để định offset
  - Preview nodes và edges tại vị trí mới
  - Thả chuột để hoàn thành copy
  - Escape để cancel
- **API:** `POST /api/layout-data/copy-nodes` - Backend xử lý toàn bộ logic
- **Logic:**
  - Tạo tất cả nodes mới với offset trước (validate coordinates, copy vehicle properties)
  - Sau đó tạo tất cả edges mới (sử dụng node ID mapping)
  - Xử lý 2-way edges: copy cả forward và reverse edge
  - Không copy stations
- **Selection:** Tự động select các nodes/edges mới sau khi copy

#### **6.3. Delete Selected** ✅ COMPLETE
- **Trigger:** Delete button hoặc Delete key
- **API:** `DELETE /api/edges/{id}` hoặc batch delete
- **Behavior:** Xóa edges, backend tự động xóa orphaned nodes
- **Confirmation:** Dialog xác nhận trước khi xóa

#### **6.4. Merge Nodes** ✅ COMPLETE
- **Trigger:** Toolbar button (khi có 2+ nodes selected)
- **API:** `POST /api/layout-data/merge-nodes`
- **Behavior:**
  - Gộp tất cả selected nodes thành 1 node tại vị trí center
  - Redirect tất cả edges đến node mới
  - Gộp vehicle properties từ tất cả nodes
  - Nếu nhiều nodes có stations → dialog chọn node giữ station
  - Distance check: nếu nodes ngoài `NodeProximityRadius` → confirmation dialog
- **Selection:** Tự động select node mới sau khi merge

#### **6.5. Split Node** ✅ COMPLETE
- **Trigger:** Toolbar button (khi có 1 node selected với 2+ edges)
- **API:** `POST /api/layout-data/split-node`
- **Behavior:**
  - Split 1 node thành N nodes (N = số edges connected)
  - Mỗi edge được redirect đến node mới tương ứng
  - Copy vehicle properties đến tất cả nodes mới
  - Nếu node có station → dialog chọn node nhận station
  - Validation: node phải có ít nhất 2 edges mới được split
- **Selection:** Tự động select tất cả nodes mới sau khi split

#### **6.6. Alignment Functions** ❌ NOT STARTED
- **Status:** Buttons đã có, chưa implement logic

---

### **Phase 7: Right Panel - Properties** [ ] PARTIAL
**Status:** UI đã có, cần tích hợp API

#### **7.1. Settings Tab** ✅ FIXED & ENHANCED
**Thay đổi trong cuộc hội thoại này:**

**a) Chuyển Display Options về Settings Tab:**
- Xóa Display Options khỏi Toolbar
- Thêm Display Options vào Settings Tab (sau Grid Settings)
- Bao gồm: Show Edge Names, Show Node Names, Show Grid, Show Background Map
- Là session state (không lưu vào database)

**b) Auto-generation Settings - Editable:**
- Chuyển từ read-only sang editable
- Thêm local state để quản lý giá trị chỉnh sửa:
  - `nodeNameAutoGenerate` (bool)
  - `edgeNameAutoGenerate` (bool)
  - `edgeMinLengthCreate` (double)
  - `nodeProximityRadius` (double)
- Thêm nút "Save Settings" với loading indicator
- Tích hợp với API để lưu settings

**c) Thứ tự sections:**
1. Grid Settings
2. Display Options
3. Auto-generation Settings (editable với Save button)
4. Layout Level Info (read-only)
5. Statistics

**d) API Integration:**
- Tạo `EditorSettingsInfo` model mới
- Thêm `EditorSettings` property vào `UpdateLayoutLevelRequest`
- Cập nhật `LayoutService.UpdateLevelAsync()` để xử lý editor settings
- Settings được lưu vào database khi click Save

**Code Structure:**
```csharp
// Local editable state
private bool nodeNameAutoGenerate;
private bool edgeNameAutoGenerate;
private double edgeMinLengthCreate;
private double nodeProximityRadius;

// Initialize từ settings khi component load
protected override void OnParametersSet()
{
    if (State.Level?.EditorSettings != null)
    {
        var settings = State.Level.EditorSettings;
        nodeNameAutoGenerate = settings.NodeNameAutoGenerate;
        // ... initialize other fields
    }
}

// Save to API
private async Task SaveEditorSettings()
{
    var request = new UpdateLayoutLevelRequest
    {
        EditorSettings = new EditorSettingsInfo
        {
            NodeNameAutoGenerate = nodeNameAutoGenerate,
            // ... other fields
        }
    };
    var updatedLevel = await ApiService.UpdateLevelAsync(State.Level.Id, request);
    State.Level = updatedLevel; // Update state
}
```

**Đã có:**
- Node properties editor (UI)
- Edge properties editor (UI)
- VehicleType dropdown
- Vehicle properties editor (UI)
- Station info display

**Cần làm:**
- Save properties to API
- Validation
- Error handling

---

### **Phase 8: Trajectory Editor** ❌ NOT STARTED
**Status:** Chưa thực hiện

**Cần implement:**
- Display trajectory (NURBS curve)
- Control points visualization
- Drag control points
- Add/Remove control points
- Change degree (với logic giữ biên dạng ít thay đổi)

---

### **Phase 9: Actions Form Builder** ❌ NOT STARTED
**Status:** Chưa thực hiện

**Cần implement:**
- Actions form dialog
- ActionType dropdown (VehicleType defaults + custom text)
- Parameters key-value editor
- Validation

---

### **Phase 10: Undo/Redo & Save** [ ] PARTIAL
**Status:** Structure đã có, Save API đã implement

**Đã có:**
- Command pattern structure
- Undo stack
- Redo stack
- Save button (UI)
- Save API: `POST /api/layout-data/save` - Batch save với transaction
- Change tracking: `_modifiedNodeIds`, `_modifiedEdgeIds`
- `HasUnsavedChanges` flag

**Save API Details:**
- **Endpoint:** `POST /api/layout-data/save`
- **Request:** `SaveLayoutDataRequest` với:
  - `NodesToCreate`, `NodesToUpdate`, `NodesToDelete`
  - `EdgesToCreate`, `EdgesToUpdate`, `EdgesToDelete`
- **Conflict Handling:** Force Overwrite (Option D)
- **Transaction:** Toàn bộ operation trong 1 transaction, rollback nếu có lỗi
- **Response:** `SaveLayoutDataResponse` với số lượng items created/updated

**Change Tracking:**
- `MarkNodeModified(Guid nodeId)` - Đánh dấu node đã thay đổi
- `MarkEdgeModified(Guid edgeId)` - Đánh dấu edge đã thay đổi
- `SaveAsync()` - Thu thập tất cả modified/new/deleted items và gọi API
- **Note:** Các API calls trực tiếp (CreateEdge, DeleteEdge, CopyNodes, MergeNodes, SplitNode) KHÔNG set `HasUnsavedChanges` vì đã lưu vào database

**Cần làm:**
- Unsaved changes warning khi exit
- Undo/Redo cho các operations khác (Align, etc.)

---

### **Phase 11: Polish** [ ] PARTIAL
**Status:** Một phần đã có

**Đã có:**
- Keyboard shortcuts (Ctrl+Z/Y/S/C/M, Delete, Escape)
- Display options
- Settings tab (đã sửa và enhance)
- Exit button
- Text rendering với fontSize phụ thuộc ZoomLevel và Resolution
- 2-way edges visualization (2 đường song song)
- Box select trong Scanner mode (select cả nodes và edges)

**Text Font Size:**
- **Formula:** `fontSizeSVG = baseFontSizeWorld / (Resolution * ZoomLevel)`
- **baseFontSizeWorld:** 0.24 meters (cho node names và edge names)
- **Resolution:** meters per pixel (từ `EditorSettings.Resolution`)
- **ZoomLevel:** hệ số zoom hiện tại
- **Result:** Text có cùng kích thước visual với mọi Resolution, zoom theo ZoomLevel

**Cần làm:**
- CheckLayout validation logic
- Performance optimization

---

## Architecture Overview

### **Component Hierarchy**
```
LayoutManager (click Edit) 
    → Navigate to /layout-editor/{levelId}
        → LayoutEditorComponent
            ├── EditorToolbar (top)
            ├── SVG Canvas (left) + MousePositionDisplay
            └── Right Panel
                ├── Properties Tab
                │   ├── NodePropertiesEditor (single node)
                │   └── EdgePropertiesEditor (single edge)
                └── Settings Tab
                    ├── Grid Settings
                    ├── Display Options
                    ├── Auto-generation Settings
                    ├── Layout Level Info
                    └── Statistics
```

### **Data Flow**
1. **Initialization:**
   - User clicks "Edit" on LayoutManager
   - Navigate to `/layout-editor/{levelId}`
   - `LayoutEditorComponent` loads
   - `LayoutEditorState.InitializeAsync()` fetches:
     - Level info (with EditorSettings)
     - Layout data (Nodes, Edges, Stations)
     - VehicleTypes
     - Background image (if available)
   - Viewport initialized to fit image bounds

2. **User Interactions:**
   - Mouse events → JavaScript (`svgEditor.js`) → Blazor (`SvgEditorCanvas.razor`)
   - State changes → `LayoutEditorState` → Notify components via `OnStateChanged` event
   - UI updates → Blazor re-renders affected components

3. **Save Operations:**
   - User edits properties → Local state changes
   - Click "Save Settings" → API call (`MapManagerApiService.UpdateLevelEditorSettingsAsync`)
   - Backend updates database → Returns updated Level
   - State updated → UI refreshed

### **State Management Pattern**
- **Centralized State:** `LayoutEditorState` (scoped service)
- **Event-driven:** Components subscribe to `OnStateChanged` event
- **Immutable Updates:** State methods return new state or update properties and notify
- **Command Pattern:** Undo/Redo via `EditorCommand` abstract class

### **Coordinate Transformation**
- **World → SVG:** `WorldToSvg(worldX, worldY)` → `(worldX, physicalHeight - worldY)`
- **SVG → World:** `SvgToWorld(svgX, svgY)` → `(svgX, physicalHeight - svgY)`
- **Screen → SVG:** JavaScript `screenToSvgArray(screenX, screenY)` using `getScreenCTM()`

### **API Integration**
- **Service:** `MapManagerApiService` (injected)
- **Endpoints Used:**
  - `GET /api/layouts/{layoutId}/levels/{levelId}` - Get level info
  - `GET /api/layouts/{layoutId}/levels/{levelId}/data` - Get layout data
  - `PUT /api/layouts/{layoutId}/levels/{levelId}` - Update level (including editor settings)
  - `GET /api/layouts/{layoutId}/levels/{levelId}/background-image` - Get background image
  - `POST /api/edges` - Create edge (with smart node detection)
  - `DELETE /api/edges/{id}` - Delete edge (single)
  - `DELETE /api/edges/batch` - Delete edges (batch)
  - `POST /api/layout-data/save` - Batch save nodes/edges (transactional)
  - `POST /api/layout-data/copy-nodes` - Copy nodes/edges with offset
  - `POST /api/layout-data/merge-nodes` - Merge multiple nodes into one
  - `POST /api/layout-data/split-node` - Split one node into multiple nodes

---

## Technical Details

### **Coordinate System**
- **World Coordinates:** Bottom-left origin (0,0), Y increases upward, units in meters
- **SVG Coordinates:** Top-left origin (0,0), Y increases downward, units in pixels
- **Transform:** `svgY = physicalHeight - worldY` (flip Y axis)

### **Pan Logic (Fixed)**
- Sử dụng incremental delta thay vì delta từ điểm bắt đầu
- Lưu `panLastScreen` để track vị trí trước đó
- Convert screen coordinates sang SVG mỗi lần để đảm bảo chính xác khi ViewBox thay đổi

### **Zoom Logic (Fixed)**
- Zoom tại vị trí cursor
- Giữ tọa độ mouse không đổi trong world space
- Tính ratio của cursor trong viewBox và adjust ViewBox position

### **Grid Styling**
- Stroke: `#999` (đậm)
- Stroke width: `0.04` (đậm gấp đôi)
- Opacity: `0.7` (rõ)
- Stroke dasharray: `0.1,0.1` (nét đứt)

### **Text Rendering (Node/Edge Names)**
- **Font Size Formula:** `fontSizeSVG = baseFontSizeWorld / (Resolution * ZoomLevel)`
  - `baseFontSizeWorld`: 0.24 meters
  - `Resolution`: meters per pixel (from `EditorSettings.Resolution`)
  - `ZoomLevel`: current zoom factor
- **Result:** Text có cùng kích thước visual với mọi Resolution, zoom theo ZoomLevel
- **Color:** Red (#f44336)
- **Font:** Segoe UI, font-weight 500
- **Letter Spacing:** -0.02em (characters gần nhau hơn)
- **Position:**
  - Node names: Below node center
  - Edge names: Above edge center

### **Settings Tab Structure**
1. Grid Settings (editable)
2. Display Options (session state)
3. Auto-generation Settings (editable với Save button)
4. Layout Level Info (read-only)
5. Statistics (read-only)

---

## Implementation Status Summary

| Phase | Status | Progress |
|-------|--------|----------|
| Phase 1: Foundation | ✅ Complete | 100% |
| Phase 2: SVG Canvas | ✅ Complete | 100% |
| Phase 3: Viewport Controls | ✅ Complete | 100% |
| Phase 4: Selection | [ ] Partial | ~80% |
| Phase 5: Create Edge | ✅ Complete | 100% |
| Phase 6: Edit Operations | [ ] Partial | ~70% |
| Phase 7: Properties | [ ] Partial | ~70% |
| Phase 8: Trajectory Editor | ❌ Not Started | 0% |
| Phase 9: Actions Form Builder | ❌ Not Started | 0% |
| Phase 10: Undo/Redo & Save | [ ] Partial | ~70% |
| Phase 11: Polish | [ ] Partial | ~60% |

**Overall Progress:** ~65-70%

---

## Bugs Fixed in This Session

### **1. Pan Logic - Cộng Dồn Delta**
**Problem:** Pan bị cộng dồn quãng đường di chuyển
**Root Cause:** Tính delta từ điểm bắt đầu mỗi lần thay vì incremental
**Solution:** Chuyển sang incremental delta từ lần move trước

### **2. Zoom Logic - Tọa Độ Mouse Thay Đổi**
**Problem:** Zoom không giữ tọa độ mouse không đổi
**Solution:** Tính ratio và adjust ViewBox để giữ cursor tại cùng vị trí world

### **3. Grid Styling**
**Problem:** Grid quá nhạt và nét liền
**Solution:** Đậm hơn, opacity cao hơn, thêm stroke-dasharray

### **4. Settings Tab - Display Options**
**Problem:** Display Options ở Toolbar thay vì Settings
**Solution:** Chuyển về Settings Tab, xóa khỏi Toolbar

### **5. Settings Tab - Auto-generation Settings Read-only**
**Problem:** Auto-generation Settings chỉ hiển thị, không thể edit
**Solution:** Làm editable với local state và Save button, tích hợp API

### **6. Create Edge - Smart Node Detection**
**Problem:** CreateEdge không hoạt động, chỉ tạo được trên nodes đã có
**Solution:** 
- Backend API tự động detect nodes trong `NodeProximityRadius` hoặc tạo mới
- Frontend chỉ cần gửi world coordinates, backend xử lý logic

### **7. 2-Way Edges Visualization**
**Problem:** 2-way edges hiển thị thành 1 line với 2 arrowheads
**Solution:** Tính toán offset để hiển thị thành 2 đường song song riêng biệt

### **8. Text Font Size - Resolution Independence**
**Problem:** Text size thay đổi khi Resolution thay đổi
**Solution:** Công thức `fontSizeSVG = baseFontSizeWorld / (Resolution * ZoomLevel)` để text có cùng kích thước visual với mọi Resolution

### **9. HasUnsavedChanges - Direct API Calls**
**Problem:** `HasUnsavedChanges` được set sau các API calls trực tiếp (CreateEdge, DeleteEdge, etc.)
**Solution:** Xóa `HasUnsavedChanges = true` sau các API calls trực tiếp vì đã lưu vào database rồi

### **10. CopyNodesAsync - Refactor**
**Problem:** Copy logic phức tạp ở frontend, dùng temp edges
**Solution:** 
- Refactor để backend xử lý toàn bộ logic
- Tạo nodes trực tiếp vào database (validate coordinates, copy vehicle properties)
- Tạo edges trực tiếp với node ID mapping
- Xử lý 2-way edges tự động

---

## Key Files Modified in This Session

### **Components:**
- `Components/LayoutEditor/RightPanel/SettingsTab.razor` - Editable settings với Save
- `Components/LayoutEditor/SvgEditorCanvas.razor` - Fixed pan/zoom logic, CreateEdge, Copy preview, text rendering
- `Components/LayoutEditor/EditorToolbar.razor` - Removed Display Options, added Move mode button

### **Services:**
- `Services/State/LayoutEditorState.cs` - Fixed zoom logic, CreateEdgeAsync, DeleteEdgesAsync, CompleteCopyAsync, MergeNodesAsync, SplitNodeAsync, SaveAsync, change tracking

### **JavaScript:**
- `wwwroot/js/svgEditor.js` - Added screenToSvgArray export, screen coordinates, Ctrl+C/M handlers

### **Shared Models:**
- `RobotNet10.MapEditor.Shared/Models/EditorSettingsInfo.cs` - New model
- `RobotNet10.MapEditor.Shared/DTOs/Requests/UpdateLayoutLevelRequest.cs` - Added EditorSettings
- `RobotNet10.MapEditor.Shared/DTOs/Requests/SaveLayoutDataRequest.cs` - New model
- `RobotNet10.MapEditor.Shared/DTOs/Responses/SaveLayoutDataResponse.cs` - New model
- `RobotNet10.MapEditor.Shared/DTOs/Requests/CopyNodesRequest.cs` - New model
- `RobotNet10.MapEditor.Shared/DTOs/Responses/CopyNodesResponse.cs` - New model
- `RobotNet10.MapEditor.Shared/DTOs/Requests/MergeNodesRequest.cs` - New model
- `RobotNet10.MapEditor.Shared/DTOs/Requests/SplitNodeRequest.cs` - New model

### **Backend:**
- `Commons/RobotNet10.MapManager/Services/LayoutService.cs` - Update editor settings logic
- `Commons/RobotNet10.MapManager/Services/LayoutDataService.cs` - SaveLayoutDataAsync, CopyNodesAsync (refactored), MergeNodesAsync, SplitNodeAsync
- `Commons/RobotNet10.MapManager/Controllers/LayoutDataController.cs` - New endpoints: save, copy-nodes, merge-nodes, split-node

---

## Next Steps

### **Immediate (Phase 3 completion):**
- [ ] Test pan/zoom thoroughly
- [ ] Verify no accumulation issues
- [ ] Performance testing

### **Short-term (Phase 4-6):**
- [x] Enhance selection features (Shift+Click multi-select, box select edges)
- [x] Implement Create Edge với API
- [x] Implement Edit Operations (Move, Copy, Delete, Merge, Split)
- [ ] Implement Alignment functions (6 directions)

### **Medium-term (Phase 7-9):**
- [x] Properties save to API (via Save button - batch save)
- [ ] Trajectory Editor (NURBS)
- [ ] Actions Form Builder

### **Long-term (Phase 10-11):**
- [x] Save API với transaction và change tracking
- [ ] Complete Undo/Redo cho tất cả operations
- [ ] CheckLayout validation
- [ ] Performance optimization
- [ ] Additional polish

---

## References

- **Database Design:** `DATABASE_DESIGN_DISCUSSION.md`
- **API Guide:** `API_IMPLEMENTATION_GUIDE.md`
- **LayoutManager Implementation:** `LAYOUTMANAGER_TECHNICAL.md` (đã lưu trước đó)

---

**Last Updated:** 2024-12-XX  
**Session Focus:** CreateEdge, Copy/Move/Delete/Merge/Split operations, Save API, Text rendering with Resolution independence, CopyNodesAsync refactor

