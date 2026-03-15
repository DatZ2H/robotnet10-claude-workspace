# Vehicle Type Management UI - Architecture Design

**Project:** RobotNet10.MapEditor  
**Component:** Vehicle Type Management UI  
**Version:** 1.0  
**Date:** 2024-12-01  
**Status:** Architecture Design Phase

---

## Mục Lục

1. [Tổng Quan](#tổng-quan)
2. [Cấu Trúc UI](#cấu-trúc-ui)
3. [Components Chi Tiết](#components-chi-tiết)
4. [Integration Points](#integration-points)
5. [State Management](#state-management)
6. [API Integration](#api-integration)
7. [Actions Editor Design](#actions-editor-design)

---

## Tổng Quan

### Mục Đích

Xây dựng giao diện web để quản lý VehicleType (thêm, sửa, xóa) với các tính năng:
- **CRUD Operations**: Create, Read, Update, Delete VehicleType
- **Search & Filter**: Tìm kiếm và lọc theo trạng thái
- **Usage Tracking**: Hiển thị thông tin sử dụng (Node/Edge properties)
- **Actions Editor**: UI để thêm/sửa/xóa Actions (JSON editor với form builder)
- **Integration**: Tích hợp vào LayoutEditor để quản lý Node/Edge VehicleProperties

### Vị Trí Trong Ứng Dụng

- **VehicleType Management**: Page riêng (`/vehicle-types`)
- **LayoutEditor Integration**: VehicleType selector và Actions editor trong Node/Edge properties panels

---

## Cấu Trúc UI

### 1. VehicleType Management Page

```
VehicleTypeManagerComponent.razor
├── Layout: MudContainer (Full width)
│   ├── Header Section
│   │   ├── Title: "Vehicle Type Management"
│   │   └── Create Button
│   │
│   ├── Main Content (MudGrid)
│   │   ├── Left Panel (MudGrid xs="12" md="8")
│   │   │   └── VehicleTypeListPanel.razor
│   │   │
│   │   └── Right Panel (MudGrid xs="12" md="4")
│   │       └── VehicleTypeDetailsPanel.razor
│   │
│   └── Dialogs
│       ├── CreateVehicleTypeDialog.razor
│       ├── EditVehicleTypeDialog.razor
│       └── DeleteVehicleTypeDialog.razor
```

### 2. Component Hierarchy

```
VehicleTypeManagerComponent.razor (Main Page)
│
├── VehicleTypeListPanel.razor (Left Panel)
│   ├── SearchBar.razor
│   │   ├── MudTextField (Search input)
│   │   └── MudButton (Clear)
│   │
│   ├── FilterBar.razor
│   │   ├── MudSelect (Filter by Active Status)
│   │   └── MudButton (Clear filters)
│   │
│   └── VehicleTypeTable.razor
│       ├── MudTable (Sortable)
│       │   ├── Columns:
│       │   │   - VehicleTypeId (sortable)
│       │   │   - VehicleTypeName (sortable)
│       │   │   - IsActive (Chip, sortable)
│       │   │   - Usage Count (Badge, sortable)
│       │   │   - Actions (Icon buttons)
│       │   └── Rows: VehicleTypeDto[]
│       │
│       └── MudPagination
│           └── Items per page selector
│
│   └── Import/Export Bar
│       ├── MudButton (Import JSON)
│       └── MudButton (Export JSON)
│
├── VehicleTypeDetailsPanel.razor (Right Panel)
│   ├── Basic Info Section
│   │   ├── VehicleTypeId (read-only)
│   │   ├── VehicleTypeName
│   │   ├── Description
│   │   └── IsActive (Chip)
│   │
│   ├── Usage Statistics Section
│   │   ├── Node Properties Count
│   │   ├── Edge Properties Count
│   │   ├── Total Usage Count
│   │   └── Can Delete indicator
│   │
│   ├── Specifications Section (expandable)
│   │   └── JSON viewer/formatted display
│   │
│   └── Actions Preview Section (expandable)
│       └── JSON viewer/formatted display
│
└── Dialogs/
    ├── CreateVehicleTypeDialog.razor
    │   ├── MudDialog
    │   ├── Form (MudForm)
    │   │   ├── VehicleTypeId (required, validated)
    │   │   ├── VehicleTypeName (required, validated)
    │   │   ├── Description (optional)
    │   │   └── ActionsEditor.razor (optional)
    │   │       ├── Form Builder Mode
    │   │       └── JSON Preview Panel
    │   │
    │   └── Actions (Cancel, Create)
    │
    ├── ImportVehicleTypesDialog.razor
    │   ├── MudDialog
    │   ├── File upload (JSON)
    │   ├── Preview imported data
    │   └── Actions (Cancel, Import)
    │
    ├── EditVehicleTypeDialog.razor
    │   ├── Same structure as CreateDialog
    │   ├── Pre-filled with existing data
    │   └── Confirmation dialog (if has unsaved changes)
    │
    └── DeleteVehicleTypeDialog.razor
        ├── MudDialog
        ├── Confirmation message
        ├── Usage warning (if in use)
        └── Actions (Cancel, Delete)
```

---

## Components Chi Tiết

### 1. VehicleTypeListPanel.razor

**Purpose:** Hiển thị danh sách VehicleType dạng table với search và filter

**Features:**
- Search bar (tìm trong VehicleTypeId và VehicleTypeName)
- Filter by Active Status (All, Active, Inactive)
- Table với sortable columns
- Row actions: View Details, Edit, Delete, View Usage
- Loading state
- Empty state

**Props:**
```csharp
[Parameter] public VehicleTypeManagerState State { get; set; } = null!;
[Parameter] public EventCallback<VehicleTypeDto> OnSelectVehicleType { get; set; }
[Parameter] public EventCallback<VehicleTypeDto> OnEdit { get; set; }
[Parameter] public EventCallback<VehicleTypeDto> OnDelete { get; set; }
```

### 2. VehicleTypeDetailsPanel.razor

**Purpose:** Hiển thị chi tiết VehicleType được chọn

**Features:**
- Basic info display
- Usage statistics (from usage API)
- Specifications preview (JSON formatted)
- Actions preview (JSON formatted với syntax highlighting)
- Quick actions (Edit, Delete buttons)

**Props:**
```csharp
[Parameter] public VehicleTypeDto? SelectedVehicleType { get; set; }
[Parameter] public VehicleTypeUsageInfoDto? UsageInfo { get; set; }
[Parameter] public EventCallback OnEdit { get; set; }
[Parameter] public EventCallback OnDelete { get; set; }
```

### 3. CreateVehicleTypeDialog.razor

**Purpose:** Dialog để tạo VehicleType mới

**Form Fields:**
- VehicleTypeId: TextField (required, max 64, regex validation)
- VehicleTypeName: TextField (required, max 256)
- Description: TextArea (optional, max 10000)
- Specifications: JSON Editor (optional, max 50000)
- Actions: ActionsEditor component (optional, max 50000)

**Validation:**
- Client-side validation với MudBlazor validation
- Real-time validation feedback
- Error messages từ API

### 4. EditVehicleTypeDialog.razor

**Purpose:** Dialog để sửa VehicleType

**Same as CreateDialog but:**
- Pre-filled với existing data
- VehicleTypeId is read-only (immutable)
- Can update IsActive status

### 5. DeleteVehicleTypeDialog.razor

**Purpose:** Dialog xác nhận xóa VehicleType

**Features:**
- Confirmation message
- Usage warning nếu đang được sử dụng
- Display usage details (NodePropertiesCount, EdgePropertiesCount)
- Disable delete button nếu có references

### 6. ActionsEditor.razor (Shared Component)

**Purpose:** Reusable component để edit Actions JSON

**Features:**
- **Form Builder Mode** (Primary - Default):
  - Add/Remove action items
  - Form fields cho mỗi action:
    - actionType (TextField)
    - actionDescription (TextArea)
    - requirementType (Select: REQUIRED, CONDITIONAL, OPTIONAL)
    - blockingType (TextField)
    - actionParameters (Key-value pairs editor)
  - **JSON Preview Panel** (below form):
    - Real-time JSON preview
    - Formatted display
    - Read-only
    - Copy to clipboard button
  
- **JSON Editor Mode** (Advanced - Optional):
  - TextArea với JSON formatting
  - Syntax highlighting (if possible)
  - JSON validation
  - Sync với Form Builder Mode

**Props:**
```csharp
[Parameter] public string? ActionsJson { get; set; }
[Parameter] public EventCallback<string?> ActionsJsonChanged { get; set; }
[Parameter] public bool ReadOnly { get; set; } = false;
[Parameter] public bool ShowAdvancedMode { get; set; } = true;
```

---

## Integration Points

### 1. LayoutEditor Integration

**NodePropertiesEditor.razor:**
- ✅ VehicleType selector đã có
- [ ] Cần thêm Actions editor dialog
- [ ] Cần load VehicleTypes từ API

**EdgePropertiesEditor.razor:**
- ✅ VehicleType selector đã có
- [ ] Cần thêm Actions editor dialog (nếu cần)
- [ ] Cần load VehicleTypes từ API

**Actions Editor Dialog:**
- Shared component `ActionsEditor.razor`
- Mở từ "Edit Actions" button trong NodePropertiesEditor
- Save về NodeVehiclePropertyDto.Actions (JSON string)

### 2. API Integration

**MapManagerApiService.cs:**
Cần thêm các methods:
```csharp
// VehicleType CRUD
Task<List<VehicleTypeDto>> GetVehicleTypesAsync(bool? isActive = null);
Task<VehicleTypeDto?> GetVehicleTypeAsync(Guid id);
Task<VehicleTypeDto?> GetVehicleTypeByStringIdAsync(string vehicleTypeId);
Task<List<VehicleTypeDto>> SearchVehicleTypesAsync(string query);
Task<VehicleTypeDto> CreateVehicleTypeAsync(CreateVehicleTypeRequest request);
Task<VehicleTypeDto> UpdateVehicleTypeAsync(Guid id, UpdateVehicleTypeRequest request);
Task DeleteVehicleTypeAsync(Guid id);
Task<VehicleTypeUsageInfoDto> GetVehicleTypeUsageAsync(Guid id);
```

---

## State Management

### VehicleTypeManagerState.cs

**Purpose:** Quản lý state cho VehicleType Management page

**Properties:**
```csharp
public class VehicleTypeManagerState
{
    // Data
    public List<VehicleTypeDto> VehicleTypes { get; private set; } = new();
    public VehicleTypeDto? SelectedVehicleType { get; private set; }
    public VehicleTypeUsageInfoDto? SelectedUsageInfo { get; private set; }
    
    // Filters
    public string? SearchQuery { get; set; }
    public bool? FilterIsActive { get; set; }
    
    // UI State
    public bool IsLoading { get; private set; }
    public bool IsSaving { get; private set; }
    public string? ErrorMessage { get; private set; }
    
    // Events
    public event Action? OnStateChanged;
    
    // Methods
    Task LoadVehicleTypesAsync();
    Task SearchVehicleTypesAsync(string query);
    Task FilterByActiveStatusAsync(bool? isActive);
    Task SelectVehicleTypeAsync(Guid id);
    Task CreateVehicleTypeAsync(CreateVehicleTypeRequest request);
    Task UpdateVehicleTypeAsync(Guid id, UpdateVehicleTypeRequest request);
    Task DeleteVehicleTypeAsync(Guid id);
    Task LoadUsageInfoAsync(Guid id);
}
```

---

## Actions Editor Design

### Form Builder Mode

**UI Structure:**
```
ActionsEditor.razor
├── Mode Toggle (Form Builder / JSON Editor)
│
├── Form Builder Mode
│   ├── Actions List (MudList)
│   │   └── ActionItem.razor (for each action)
│   │       ├── actionType (TextField)
│   │       ├── actionDescription (TextArea)
│   │       ├── requirementType (Select: REQUIRED/CONDITIONAL/OPTIONAL)
│   │       ├── blockingType (TextField)
│   │       └── actionParameters (KeyValueEditor)
│   │           ├── Add Parameter button
│   │           └── Parameter rows (key, value)
│   │
│   └── Add Action button
│
└── JSON Editor Mode (Advanced)
    ├── MudTextArea (JSON text)
    └── Validation feedback
```

**ActionItem.razor:**
- Collapsible card
- Form fields cho action properties
- Delete button
- Move up/down buttons (reorder)

**KeyValueEditor.razor:**
- Table với key-value pairs
- Add/Remove rows
- Validation

### JSON Structure

```json
[
  {
    "actionType": "pick",
    "actionDescription": "Pick up item",
    "requirementType": "REQUIRED",
    "blockingType": "HARD",
    "actionParameters": [
      {"key": "itemId", "value": "12345"},
      {"key": "height", "value": "1.5"}
    ]
  }
]
```

---

## Implementation Checklist

### Phase 1: API Service Extension
- [ ] Extend MapManagerApiService với VehicleType methods
- [ ] Test API calls

### Phase 2: State Management
- [ ] Create VehicleTypeManagerState.cs
- [ ] Implement state management methods
- [ ] Test state updates

### Phase 3: Main Page & List Panel
- [ ] Create VehicleTypeManagerComponent.razor
- [ ] Create VehicleTypeListPanel.razor
- [ ] Create SearchBar.razor
- [ ] Create FilterBar.razor
- [ ] Create VehicleTypeTable.razor (with sorting)
- [ ] Implement pagination
- [ ] Implement search & filter logic
- [ ] Implement sorting logic
- [ ] Implement import/export (JSON)

### Phase 4: Details Panel
- [ ] Create VehicleTypeDetailsPanel.razor
- [ ] Implement usage info display
- [ ] Implement Actions JSON preview

### Phase 5: Dialogs
- [ ] Create CreateVehicleTypeDialog.razor
- [ ] Create EditVehicleTypeDialog.razor (with confirmation)
- [ ] Create DeleteVehicleTypeDialog.razor
- [ ] Create ImportVehicleTypesDialog.razor
- [ ] Implement form validation

### Phase 6: Actions Editor
- [ ] Create ActionsEditor.razor
- [ ] Create ActionItem.razor
- [ ] Create KeyValueEditor.razor
- [ ] Implement form builder mode (primary)
- [ ] Implement JSON preview panel (real-time)
- [ ] Implement JSON editor mode (advanced, optional)
- [ ] Implement JSON validation

### Phase 7: LayoutEditor Integration
- [ ] Update NodePropertiesEditor với Actions editor dialog
- [ ] Update EdgePropertiesEditor (nếu cần)
- [ ] Load VehicleTypes trong LayoutEditorState
- [ ] Test integration

### Phase 8: Testing & Polish
- [ ] Test all CRUD operations
- [ ] Test search & filter
- [ ] Test Actions editor
- [ ] Test LayoutEditor integration
- [ ] UI/UX improvements

---

## Next Steps

1. **Clarify Requirements:**
   - Confirm "form khác" là form nào?
   - Confirm Actions editor requirements (form builder vs JSON editor)
   - Confirm UI/UX preferences

2. **Start Implementation:**
   - Begin with API service extension
   - Then state management
   - Then UI components

---

**Status:** Ready for Implementation  
**Version:** 1.0  
**Last Updated:** 2024-12-01

