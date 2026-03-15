# Vehicle Type API - Kiến Trúc & Thiết Kế

**Project:** RobotNet10.MapManager  
**Component:** Vehicle Type Management API  
**Version:** 1.0  
**Date:** 2024-12-01  
**Status:** Architecture Design Phase

---

## Mục Lục

1. [Tổng Quan](#tổng-quan)
2. [Phân Tích Tài Liệu](#phn-tích-tài-liệu)
3. [Kiến Trúc Hiện Tại](#kiến-trúc-hiện-tại)
4. [Kiến Trúc Đề Xuất](#kiến-trúc-đề-xuất)
5. [Chi Tiết Implementation](#chi-tiết-implementation)
6. [Business Rules](#business-rules)
7. [Validation Rules](#validation-rules)
8. [Error Handling](#error-handling)
9. [Testing Strategy](#testing-strategy)

---

## Tổng Quan

### Mục Đích

Vehicle Type API cung cấp các endpoint để quản lý **master data** về các loại robot/AGV/AMR trong hệ thống. Vehicle Type được sử dụng để:

1. **Định nghĩa loại robot**: AMR-T800, AMR-F100, Forklift-X1, etc.
2. **Cấu hình properties**: Mỗi Vehicle Type có thể có properties riêng cho Nodes và Edges
3. **VDMA LIF Compliance**: Tuân thủ chuẩn VDMA LIF 1.0.0

### Vai Trò Trong Hệ Thống

```
VehicleType (Master Data)
    ├── NodeVehicleProperties (Many-to-Many)
    │   └── Theta, Actions (JSON)
    └── EdgeVehicleProperties (Many-to-Many)
        └── Orientation, Speed Limits, Trajectory, etc.
```

**Quan hệ:**
- 1 VehicleType → N NodeVehicleProperties
- 1 VehicleType → N EdgeVehicleProperties
- VehicleType là **master data**, không phụ thuộc vào Layout/Level

---

## Phân Tích Tài Liệu

### Từ DATABASE_DESIGN_DISCUSSION.md

#### 1. VehicleType Entity Structure

```csharp
VehicleType {
    Id: Guid (PK)
    VehicleTypeId: string (unique, max 64 chars)  // VDMA LIF: vehicleTypeId
    VehicleTypeName: string (required, max 256 chars)
    Description: string? (ntext)
    Specifications: string? (JSON, ntext)  // Future extensions
    Actions: string? (JSON, ntext)  // VDMA LIF: actions array
    IsActive: bool (default: true)
    CreatedDate: DateTime (UTC)
}
```

**Key Points:**
- ✅ VehicleTypeId là unique identifier (không phải GUID)
- ✅ Actions là JSON array theo VDMA LIF format
- ✅ Specifications là JSON cho future extensions
- ✅ IsActive flag để soft delete
- ✅ Không có physical specs (width, length) - chỉ focus vào schema properties

#### 2. Business Rules từ Database Design

- **Master Data**: VehicleType độc lập với Layout/Level
- **Reference Check**: Không thể xóa nếu đang được sử dụng trong NodeVehicleProperties hoặc EdgeVehicleProperties
- **VDMA LIF Compliance**: VehicleTypeId phải unique, format theo chuẩn

### Từ API_IMPLEMENTATION_GUIDE.md

#### 1. Endpoints Đã Đề Cập

```http
POST   /api/vehicles              # Create VehicleType
GET    /api/vehicles              # Get all VehicleTypes
GET    /api/vehicles/{id:guid}    # Get by Id
PUT    /api/vehicles/{id:guid}    # Update VehicleType
DELETE /api/vehicles/{id:guid}    # Delete VehicleType
```

#### 2. DTOs Đã Đề Cập

**VehicleTypeDto:**
```csharp
{
    "id": "guid",
    "vehicleTypeId": "string (unique)",
    "vehicleTypeName": "string",
    "description": "string?",
    "specifications": "string? (JSON)",
    "isActive": true,
    "createdDate": "datetime"
}
```

**Note:** ❌ Thiếu field `Actions` trong DTO (nhưng có trong Entity)

#### 3. Business Rules từ API Guide

- VehicleTypeId must be unique
- Cannot delete if referenced by Node/Edge properties
- Soft delete via IsActive flag (recommended)

---

## Kiến Trúc Hiện Tại

### Code Structure

```
RobotNet10.MapManager/
├── Controllers/
│   └── VehiclesManagerController.cs ✅ (5 endpoints)
├── Services/
│   ├── IVehicleTypeService.cs ✅
│   └── VehicleTypeService.cs ✅
└── Data/
    └── VehicleType.cs ✅

RobotNet10.MapEditor.Shared/
└── DTOs/
    ├── VehicleType/
    │   └── VehicleTypeDto.cs ✅
    └── Requests/
        ├── CreateVehicleTypeRequest.cs ✅
        └── UpdateVehicleTypeRequest.cs ✅
```

### Endpoints Hiện Tại

| Method | Endpoint | Status | Notes |
|--------|----------|--------|-------|
| POST | `/api/vehicles` | ✅ | Create |
| GET | `/api/vehicles` | ✅ | Get all (no filtering) |
| GET | `/api/vehicles/{id}` | ✅ | Get by GUID |
| PUT | `/api/vehicles/{id}` | ✅ | Update |
| DELETE | `/api/vehicles/{id}` | ✅ | Delete (with reference check) |

### Gaps & Issues Phát Hiện

#### 1. **Missing Endpoints** ❌

- ❌ `GET /api/vehicles/vehicleTypeId/{vehicleTypeId}` - Get by VehicleTypeId string
- ❌ `GET /api/vehicles?isActive={bool}` - Filter by IsActive
- ❌ `GET /api/vehicles/search?query={text}` - Search by name/ID
- ❌ `GET /api/vehicles/{id}/usage` - Check usage (nodes/edges count)
- ❌ `PUT /api/vehicles/{id}/activate` - Activate
- ❌ `PUT /api/vehicles/{id}/deactivate` - Deactivate

#### 2. **DTO Issues** ❌

- ❌ VehicleTypeDto thiếu field `Actions` (có trong Entity)
- ❌ Không có DTO cho usage statistics
- ❌ Không có response DTO cho delete operation (usage info)

#### 3. **Validation Issues** ⚠️

- ⚠️ CreateVehicleTypeRequest không có validation attributes
- ⚠️ UpdateVehicleTypeRequest không có validation attributes
- ⚠️ Không validate JSON format cho Specifications và Actions

#### 4. **Service Layer Issues** ⚠️

- ⚠️ GetAllAsync() không hỗ trợ filtering
- ⚠️ Không có method để get usage statistics
- ⚠️ Không có method để search

#### 5. **Error Handling** ⚠️

- ⚠️ Error messages không consistent
- ⚠️ Không có structured error response DTO

---

## Kiến Trúc Đề Xuất

### 1. API Endpoints Architecture

```
┌─────────────────────────────────────────────────────────┐
│         VehiclesManagerController (REST API)             │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  CRUD Operations:                                        │
│  ├── POST   /api/vehicles                    [CREATE]   │
│  ├── GET    /api/vehicles                    [READ ALL] │
│  ├── GET    /api/vehicles/{id}               [READ ONE] │
│  ├── PUT    /api/vehicles/{id}               [UPDATE]   │
│  └── DELETE /api/vehicles/{id}               [DELETE]   │
│                                                          │
│  Query Operations:                                       │
│  ├── GET    /api/vehicles/vehicleTypeId/{id} [BY STRING]│
│  ├── GET    /api/vehicles/search?query={text} [SEARCH]   │
│  └── GET    /api/vehicles?isActive={bool}    [FILTER]   │
│                                                          │
│  State Management:                                       │
│  ├── PUT    /api/vehicles/{id}/activate      [ACTIVATE] │
│  └── PUT    /api/vehicles/{id}/deactivate    [DEACTIVATE]│
│                                                          │
│  Usage Information:                                       │
│  └── GET    /api/vehicles/{id}/usage         [USAGE]    │
│                                                          │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│              IVehicleTypeService (Interface)              │
├─────────────────────────────────────────────────────────┤
│  Task<VehicleType> CreateAsync(...)                      │
│  Task<List<VehicleType>> GetAllAsync(...)                │
│  Task<VehicleType?> GetByIdAsync(Guid id)                │
│  Task<VehicleType?> GetByVehicleTypeIdAsync(string id)   │
│  Task<List<VehicleType>> SearchAsync(string query)        │
│  Task<List<VehicleType>> GetByActiveStatusAsync(bool)    │
│  Task<VehicleType> UpdateAsync(...)                      │
│  Task<VehicleType> ActivateAsync(Guid id)                 │
│  Task<VehicleType> DeactivateAsync(Guid id)              │
│  Task<bool> DeleteAsync(Guid id)                         │
│  Task<VehicleTypeUsageInfo> GetUsageInfoAsync(Guid id)   │
│  Task<bool> ExistsAsync(string vehicleTypeId)            │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│            VehicleTypeService (Implementation)           │
├─────────────────────────────────────────────────────────┤
│  - MapDbContext (EF Core)                               │
│  - Business Logic                                        │
│  - Validation                                            │
│  - Reference Checking                                    │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│                  MapDbContext (EF Core)                   │
├─────────────────────────────────────────────────────────┤
│  DbSet<VehicleType>                                      │
│  DbSet<NodeVehicleProperty>                              │
│  DbSet<EdgeVehicleProperty>                              │
└─────────────────────────────────────────────────────────┘
```

### 2. DTOs Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Request DTOs                          │
├─────────────────────────────────────────────────────────┤
│  CreateVehicleTypeRequest                                │
│  ├── VehicleTypeId: string (required, max 64)           │
│  ├── VehicleTypeName: string (required, max 256)        │
│  ├── Description: string?                                │
│  ├── Specifications: string? (JSON)                      │
│  └── Actions: string? (JSON array)                       │
│                                                          │
│  UpdateVehicleTypeRequest                                │
│  ├── VehicleTypeName: string? (max 256)                 │
│  ├── Description: string?                                 │
│  ├── Specifications: string? (JSON)                      │
│  ├── Actions: string? (JSON array)                       │
│  └── IsActive: bool?                                     │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                    Response DTOs                          │
├─────────────────────────────────────────────────────────┤
│  VehicleTypeDto                                          │
│  ├── Id: Guid                                            │
│  ├── VehicleTypeId: string                               │
│  ├── VehicleTypeName: string                             │
│  ├── Description: string?                                │
│  ├── Specifications: string? (JSON)                     │
│  ├── Actions: string? (JSON array) [ADD]             │
│  ├── IsActive: bool                                      │
│  └── CreatedDate: DateTime                               │
│                                                          │
│  VehicleTypeUsageInfoDto [NEW]                        │
│  ├── VehicleTypeId: Guid                                 │
│  ├── VehicleTypeName: string                             │
│  ├── NodePropertiesCount: int                           │
│  ├── EdgePropertiesCount: int                            │
│  ├── TotalUsageCount: int                                │
│  └── CanDelete: bool                                     │
│                                                          │
│  ErrorResponseDto [NEW]                               │
│  ├── Error: string                                       │
│  ├── ErrorCode: string?                                  │
│  └── Details: Dictionary<string, object>?                 │
└─────────────────────────────────────────────────────────┘
```

### 3. Service Layer Architecture

```csharp
public interface IVehicleTypeService
{
    // CRUD Operations
    Task<VehicleType> CreateAsync(
        string vehicleTypeId, 
        string vehicleTypeName, 
        string? description, 
        string? specifications,
        string? actions);  // ADD
    
    Task<List<VehicleType>> GetAllAsync();
    Task<VehicleType?> GetByIdAsync(Guid id);
    Task<VehicleType?> GetByVehicleTypeIdAsync(string vehicleTypeId);
    
    Task<VehicleType> UpdateAsync(
        Guid id, 
        string? vehicleTypeName, 
        string? description, 
        string? specifications,
        string? actions,  // ADD
        bool? isActive);
    
    Task<bool> DeleteAsync(Guid id);
    
    // Query Operations NEW
    Task<List<VehicleType>> SearchAsync(string query);
    Task<List<VehicleType>> GetByActiveStatusAsync(bool isActive);
    
    // State Management NEW
    Task<VehicleType> ActivateAsync(Guid id);
    Task<VehicleType> DeactivateAsync(Guid id);
    
    // Usage Information NEW
    Task<VehicleTypeUsageInfo> GetUsageInfoAsync(Guid id);
    
    // Validation
    Task<bool> ExistsAsync(string vehicleTypeId);
}
```

---

## Chi Tiết Implementation

### 1. Endpoints Specification

#### 1.1. CREATE Vehicle Type

```http
POST /api/vehicles
Content-Type: application/json

Request Body:
{
    "vehicleTypeId": "AMR-T800",           // Required, max 64 chars, unique
    "vehicleTypeName": "AMR T800",         // Required, max 256 chars
    "description": "Heavy-duty AMR",      // Optional
    "specifications": "{...}",            // Optional, JSON
    "actions": "[{...}]"                   // Optional, JSON array (VDMA LIF)
}

Response: 201 Created
{
    "id": "guid",
    "vehicleTypeId": "AMR-T800",
    "vehicleTypeName": "AMR T800",
    "description": "Heavy-duty AMR",
    "specifications": "{...}",
    "actions": "[{...}]",
    "isActive": true,
    "createdDate": "2024-12-01T10:00:00Z"
}

Error: 400 Bad Request
{
    "error": "Vehicle type with ID 'AMR-T800' already exists"
}
```

#### 1.2. GET All Vehicle Types

```http
GET /api/vehicles
GET /api/vehicles?isActive=true
GET /api/vehicles?isActive=false

Response: 200 OK
[
    {
        "id": "guid",
        "vehicleTypeId": "AMR-T800",
        "vehicleTypeName": "AMR T800",
        "description": "...",
        "specifications": "{...}",
        "actions": "[{...}]",
        "isActive": true,
        "createdDate": "2024-12-01T10:00:00Z"
    }
]
```

#### 1.3. GET Vehicle Type by GUID

```http
GET /api/vehicles/{id:guid}

Response: 200 OK
{
    "id": "guid",
    "vehicleTypeId": "AMR-T800",
    ...
}

Error: 404 Not Found
{
    "error": "Vehicle type with ID '{id}' not found"
}
```

#### 1.4. GET Vehicle Type by VehicleTypeId String NEW

```http
GET /api/vehicles/vehicleTypeId/{vehicleTypeId}

Example:
GET /api/vehicles/vehicleTypeId/AMR-T800

Response: 200 OK
{
    "id": "guid",
    "vehicleTypeId": "AMR-T800",
    ...
}

Error: 404 Not Found
{
    "error": "Vehicle type with VehicleTypeId 'AMR-T800' not found"
}
```

#### 1.5. SEARCH Vehicle Types NEW

```http
GET /api/vehicles/search?query={text}

Example:
GET /api/vehicles/search?query=AMR

Response: 200 OK
[
    {
        "id": "guid",
        "vehicleTypeId": "AMR-T800",
        "vehicleTypeName": "AMR T800",
        ...
    },
    {
        "id": "guid",
        "vehicleTypeId": "AMR-F100",
        "vehicleTypeName": "AMR F100",
        ...
    }
]
```

**Search Logic:**
- Search trong `VehicleTypeId` (case-insensitive, contains)
- Search trong `VehicleTypeName` (case-insensitive, contains)
- Return kết quả match bất kỳ field nào

#### 1.6. UPDATE Vehicle Type

```http
PUT /api/vehicles/{id:guid}
Content-Type: application/json

Request Body:
{
    "vehicleTypeName": "AMR T800 Updated",  // Optional
    "description": "Updated description",    // Optional
    "specifications": "{...}",               // Optional
    "actions": "[{...}]",                    // Optional
    "isActive": false                        // Optional
}

Response: 200 OK
{
    "id": "guid",
    "vehicleTypeId": "AMR-T800",  // Cannot change
    "vehicleTypeName": "AMR T800 Updated",
    ...
}

Error: 404 Not Found
{
    "error": "Vehicle type with ID '{id}' not found"
}
```

**Business Rule:** ❌ Cannot update `VehicleTypeId` (immutable)

#### 1.7. ACTIVATE Vehicle Type NEW

```http
PUT /api/vehicles/{id:guid}/activate

Response: 200 OK
{
    "id": "guid",
    "vehicleTypeId": "AMR-T800",
    "isActive": true,
    ...
}

Error: 404 Not Found
{
    "error": "Vehicle type with ID '{id}' not found"
}
```

#### 1.8. DEACTIVATE Vehicle Type NEW

```http
PUT /api/vehicles/{id:guid}/deactivate

Response: 200 OK
{
    "id": "guid",
    "vehicleTypeId": "AMR-T800",
    "isActive": false,
    ...
}

Error: 404 Not Found
{
    "error": "Vehicle type with ID '{id}' not found"
}
```

#### 1.9. GET Usage Information NEW

```http
GET /api/vehicles/{id:guid}/usage

Response: 200 OK
{
    "vehicleTypeId": "guid",
    "vehicleTypeName": "AMR T800",
    "nodePropertiesCount": 15,
    "edgePropertiesCount": 42,
    "totalUsageCount": 57,
    "canDelete": false
}

Error: 404 Not Found
{
    "error": "Vehicle type with ID '{id}' not found"
}
```

**Use Case:** Check trước khi delete, hiển thị trong UI

#### 1.10. DELETE Vehicle Type

```http
DELETE /api/vehicles/{id:guid}

Response: 204 No Content

Error: 404 Not Found
{
    "error": "Vehicle type with ID '{id}' not found"
}

Error: 400 Bad Request
{
    "error": "Cannot delete vehicle type 'AMR-T800' because it is referenced by nodes or edges",
    "errorCode": "VEHICLE_TYPE_IN_USE",
    "details": {
        "nodePropertiesCount": 15,
        "edgePropertiesCount": 42
    }
}
```

---

## Business Rules

### 1. VehicleTypeId Rules

- ✅ **Unique**: VehicleTypeId phải unique trong toàn bộ hệ thống
- ✅ **Immutable**: Không thể thay đổi VehicleTypeId sau khi tạo
- ✅ **Format**: Max 64 characters, không có ký tự đặc biệt (recommended: alphanumeric + hyphen)
- ✅ **VDMA LIF Compliance**: Phải tuân thủ format trong VDMA LIF schema

### 2. Create Rules

- ✅ VehicleTypeId và VehicleTypeName là **required**
- ✅ VehicleTypeId phải **unique** (check trước khi create)
- ✅ IsActive mặc định là **true**
- ✅ CreatedDate tự động set là **DateTime.UtcNow**
- ✅ Specifications và Actions phải là **valid JSON** (nếu provided)

### 3. Update Rules

- ❌ **Cannot update** VehicleTypeId (immutable)
- ✅ Có thể update: VehicleTypeName, Description, Specifications, Actions, IsActive
- ✅ Partial update: Chỉ update các field được provide (null = không đổi)
- ✅ VehicleType phải tồn tại (404 nếu không tìm thấy)

### 4. Delete Rules

- ✅ **Cannot delete** nếu đang được sử dụng trong:
  - NodeVehicleProperties (bất kỳ node nào)
  - EdgeVehicleProperties (bất kỳ edge nào)
- ✅ Return 400 Bad Request với thông tin chi tiết về usage
- ✅ Nếu không có reference → Hard delete (xóa khỏi database)

### 5. Activate/Deactivate Rules

- ✅ Activate → Set IsActive = true
- ✅ Deactivate → Set IsActive = false
- ✅ Không check reference khi deactivate (chỉ là soft delete)
- ✅ Có thể activate/deactivate nhiều lần

### 6. Search & Filter Rules

- ✅ Search: Case-insensitive, contains match
- ✅ Filter by IsActive: Exact match
- ✅ Empty query → Return all (hoặc return empty nếu muốn strict)
- ✅ Sort: OrderBy VehicleTypeName (ascending)

---

## ✅ Validation Rules

### 1. CreateVehicleTypeRequest Validation

```csharp
public class CreateVehicleTypeRequest
{
    [Required(ErrorMessage = "VehicleTypeId is required")]
    [StringLength(64, ErrorMessage = "VehicleTypeId must not exceed 64 characters")]
    [RegularExpression(@"^[a-zA-Z0-9\-_]+$", 
        ErrorMessage = "VehicleTypeId must contain only alphanumeric characters, hyphens, and underscores")]
    public string VehicleTypeId { get; set; } = string.Empty;
    
    [Required(ErrorMessage = "VehicleTypeName is required")]
    [StringLength(256, ErrorMessage = "VehicleTypeName must not exceed 256 characters")]
    public string VehicleTypeName { get; set; } = string.Empty;
    
    [MaxLength(10000, ErrorMessage = "Description must not exceed 10000 characters")]
    public string? Description { get; set; }
    
    [JsonSchemaValidation]  // Custom attribute
    public string? Specifications { get; set; }  // Must be valid JSON
    
    [JsonArrayValidation]  // Custom attribute
    public string? Actions { get; set; }  // Must be valid JSON array
}
```

### 2. UpdateVehicleTypeRequest Validation

```csharp
public class UpdateVehicleTypeRequest
{
    [StringLength(256, ErrorMessage = "VehicleTypeName must not exceed 256 characters")]
    public string? VehicleTypeName { get; set; }
    
    [MaxLength(10000, ErrorMessage = "Description must not exceed 10000 characters")]
    public string? Description { get; set; }
    
    [JsonSchemaValidation]
    public string? Specifications { get; set; }
    
    [JsonArrayValidation]
    public string? Actions { get; set; }
    
    public bool? IsActive { get; set; }
}
```

### 3. JSON Validation

**Specifications:**
- Must be valid JSON object (not array, not string)
- Optional: Validate against schema nếu có

**Actions:**
- Must be valid JSON array
- Each element must be object với structure:
  ```json
  {
    "actionType": "string",
    "actionDescription": "string?",
    "required": "bool?",
    "blockingType": "string?",
    "actionParameters": "array?"
  }
  ```

---

## Error Handling

### Error Response Structure

```csharp
public class ErrorResponseDto
{
    public string Error { get; set; } = string.Empty;
    public string? ErrorCode { get; set; }
    public Dictionary<string, object>? Details { get; set; }
}
```

### Error Codes

| Error Code | HTTP Status | Description |
|------------|-------------|-------------|
| `VEHICLE_TYPE_NOT_FOUND` | 404 | Vehicle type không tồn tại |
| `VEHICLE_TYPE_ALREADY_EXISTS` | 400 | VehicleTypeId đã tồn tại |
| `VEHICLE_TYPE_IN_USE` | 400 | Không thể xóa vì đang được sử dụng |
| `INVALID_JSON_FORMAT` | 400 | Specifications hoặc Actions không phải valid JSON |
| `VALIDATION_ERROR` | 400 | Validation failed |
| `VEHICLE_TYPE_ID_IMMUTABLE` | 400 | Không thể thay đổi VehicleTypeId |

### Error Handling Flow

```
Controller
    ↓
Service Layer
    ↓
Validation → InvalidOperationException
    ↓
Reference Check → InvalidOperationException
    ↓
Database → DbUpdateException
    ↓
Controller catches → Map to ErrorResponseDto
    ↓
Return appropriate HTTP status
```

---

## Testing Strategy

### Unit Tests

1. **VehicleTypeService Tests**
   - ✅ CreateAsync: Success, Duplicate ID, Invalid data
   - ✅ GetAllAsync: Empty, Multiple items, Ordering
   - ✅ GetByIdAsync: Found, Not found
   - ✅ GetByVehicleTypeIdAsync: Found, Not found
   - ✅ SearchAsync: Match by ID, Match by name, No match
   - ✅ GetByActiveStatusAsync: Active only, Inactive only
   - ✅ UpdateAsync: Success, Not found, Partial update
   - ✅ ActivateAsync: Success, Not found
   - ✅ DeactivateAsync: Success, Not found
   - ✅ DeleteAsync: Success, Not found, Has references
   - ✅ GetUsageInfoAsync: No usage, Has usage
   - ✅ ExistsAsync: True, False

2. **VehiclesManagerController Tests**
   - ✅ All endpoints: Success cases
   - ✅ All endpoints: Error cases (404, 400)
   - ✅ Validation: ModelState validation
   - ✅ Response mapping: DTO correctness

### Integration Tests

1. **Database Integration**
   - ✅ Create → Read → Update → Delete flow
   - ✅ Reference checking với real database
   - ✅ Transaction rollback on error

2. **API Integration**
   - ✅ Full CRUD flow via HTTP
   - ✅ Error responses
   - ✅ Status codes correctness

### Test Data

```csharp
public static class VehicleTypeTestData
{
    public static CreateVehicleTypeRequest ValidCreateRequest => new()
    {
        VehicleTypeId = "AMR-T800",
        VehicleTypeName = "AMR T800",
        Description = "Heavy-duty AMR",
        Specifications = "{\"maxWeight\": 800}",
        Actions = "[{\"actionType\":\"pick\"}]"
    };
    
    public static CreateVehicleTypeRequest DuplicateIdRequest => new()
    {
        VehicleTypeId = "AMR-T800",  // Same as above
        VehicleTypeName = "AMR T800 Duplicate"
    };
}
```

---

## Implementation Checklist

### Phase 1: Core Enhancements ✅ COMPLETED

- [x] **Add Actions field to VehicleTypeDto**
- [x] **Add Actions field to CreateVehicleTypeRequest**
- [x] **Add Actions field to UpdateVehicleTypeRequest**
- [x] **Update VehicleTypeService.CreateAsync to handle Actions**
- [x] **Update VehicleTypeService.UpdateAsync to handle Actions**
- [x] **Update VehiclesManagerController.MapToDto to include Actions**

**Note:** Actions field uses `requirementType` (enum RequirementType) instead of `required` (boolean)

### Phase 2: New Endpoints ✅ COMPLETED

- [x] **GET /api/vehicles/vehicleTypeId/{vehicleTypeId}**
- [x] **GET /api/vehicles/search?query={text}**
- [x] **GET /api/vehicles?isActive={bool}**
- [x] **GET /api/vehicles/{id}/usage**

**Note:** State management endpoints (activate/deactivate) were excluded per user request

### Phase 3: Service Layer Enhancements ✅ COMPLETED

- [x] **Add SearchAsync method to IVehicleTypeService**
- [x] **Add GetByActiveStatusAsync method to IVehicleTypeService**
- [x] **Add GetUsageInfoAsync method to IVehicleTypeService**
- [x] **Update GetAllAsync to support filtering**

**Note:** ActivateAsync and DeactivateAsync were excluded per user request

### Phase 4: DTOs & Validation ✅ COMPLETED

- [x] **Create VehicleTypeUsageInfoDto**
- [x] **Create ErrorResponseDto**
- [x] **Add validation attributes to CreateVehicleTypeRequest**
- [x] **Add validation attributes to UpdateVehicleTypeRequest**
- [x] **Update error handling to use ErrorResponseDto**

**Note:** JSON validation attributes (JsonSchemaValidation, JsonArrayValidation) were cancelled - using MaxLength instead

### Phase 5: Testing ✅ COMPLETED

- [x] **Unit tests for new service methods** (VehicleTypeServiceTests.cs)
- [x] **Test project created** (RobotNet10.MapManager.Test)
- [x] **12 test cases implemented**

**Note:** Controller tests and integration tests can be added later

---

## Performance Considerations

### 1. Query Optimization

- ✅ **Index on VehicleTypeId**: Unique index (already exists)
- ✅ **Index on IsActive**: For filtering (consider if needed)
- ✅ **Index on VehicleTypeName**: For search (consider if needed)

### 2. Caching Strategy (Future)

- [ ] Cache VehicleType list (rarely changes)
- [ ] Cache by VehicleTypeId lookup
- [ ] Invalidate on create/update/delete

### 3. Pagination (Future)

- [ ] Nếu có > 1000 vehicle types → Add pagination
- [ ] Use `skip` and `take` parameters

---

## Integration Points

### 1. NodeVehicleProperties

- VehicleType được reference trong NodeVehicleProperties
- Check reference khi delete VehicleType

### 2. EdgeVehicleProperties

- VehicleType được reference trong EdgeVehicleProperties
- Check reference khi delete VehicleType

### 3. VDMA LIF Import/Export

- VehicleType được export trong VDMA LIF JSON
- VehicleType được import từ VDMA LIF JSON

---

## Summary

### Current State ✅ COMPLETED
- ✅ **9 endpoints** implemented (5 CRUD + 4 query operations)
- ✅ **Service layer** fully implemented
- ✅ **All DTOs** implemented with validation
- ✅ **Actions field** added to all DTOs (with requirementType enum)
- ✅ **Advanced endpoints** (search, filter, usage) implemented
- ✅ **Validation attributes** added
- ✅ **Error handling** with ErrorResponseDto
- ✅ **Unit tests** created

### Implementation Summary
- ✅ **Phase 1:** Core Enhancements (Actions field) - COMPLETED
- ✅ **Phase 2:** New Endpoints (4 endpoints) - COMPLETED
- ✅ **Phase 3:** Service Layer Enhancements - COMPLETED
- ✅ **Phase 4:** DTOs & Validation - COMPLETED
- ✅ **Phase 5:** Testing (Basic unit tests) - COMPLETED

### Next Steps
1. ✅ API Implementation - COMPLETED
2. [ ] **UI Implementation** - VehicleType Management Page
3. [ ] **UI Integration** - VehicleType selector in LayoutEditor
4. [ ] **Actions Editor UI** - JSON editor for Actions field

---

**Status:** ✅ API Implementation Complete - Ready for UI Implementation  
**Version:** 2.0  
**Last Updated:** 2024-12-01

---

## UI Architecture Design

### Overview

VehicleType Management UI will be implemented as a **separate page** with integration into LayoutEditor for Node/Edge properties editing.

### UI Structure

```
VehicleTypeManagerComponent.razor (Main Page)
├── VehicleTypeListPanel.razor (Left Panel - Table)
│   ├── SearchBar.razor
│   ├── FilterBar.razor (Active/Inactive toggle)
│   └── VehicleTypeTable.razor
│       ├── Columns: VehicleTypeId, VehicleTypeName, IsActive, Usage Count, Actions
│       └── Row Actions: View Details, Edit, Delete, View Usage
│
├── VehicleTypeDetailsPanel.razor (Right Panel - Preview)
│   ├── Basic Info Display
│   ├── Usage Statistics
│   ├── Actions Preview (JSON formatted)
│   └── Quick Actions
│
└── Dialogs/
    ├── CreateVehicleTypeDialog.razor
    │   ├── Form fields (VehicleTypeId, VehicleTypeName, Description, Specifications)
    │   └── ActionsEditor.razor (JSON editor with form builder)
    │
    ├── EditVehicleTypeDialog.razor
    │   ├── Same as CreateDialog (pre-filled)
    │   └── ActionsEditor.razor
    │
    └── DeleteVehicleTypeDialog.razor
        ├── Confirmation message
        └── Usage warning (if in use)

Services/
├── API/MapManagerApiService.cs (extend with VehicleType methods)
└── State/VehicleTypeManagerState.cs (state management)

Components/Shared/
└── ActionsEditor.razor (Reusable JSON editor for Actions)
    ├── Form builder UI
    ├── JSON text editor (advanced mode)
    └── Preview panel
```

### Integration Points

**LayoutEditor Integration:**
- VehicleType selector already exists in `NodePropertiesEditor.razor` and `EdgePropertiesEditor.razor`
- Need to add Actions editor dialog for Node/Edge VehicleProperties
- Actions editor will be shared component

### Features

1. **VehicleType Management Page:**
   - Table view with search and filter
   - Create/Edit/Delete dialogs
   - Usage statistics display
   - Actions preview

2. **Actions Editor:**
   - Form builder for creating Actions
   - JSON text editor (advanced mode)
   - Validation against RequirementType enum
   - Preview panel

3. **LayoutEditor Integration:**
   - VehicleType selector (already exists)
   - Actions editor dialog for Node/Edge properties
   - Real-time validation

