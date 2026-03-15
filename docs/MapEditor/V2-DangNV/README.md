# MapEditor Documentation (V2)

**Version:** 4.0  
**Date:** 2024-12-02  
**Status:** ✅ Backend Complete | [ ] Frontend In Progress

---

## Documentation Files

### **Backend Documentation**

#### 1. **DATABASE_DESIGN_DISCUSSION.md** 

**Purpose:** Database schema design & rationale

**Contents:**
- Discussion summary with user (DangNV)
- Complete database schema (11 tables, 79 columns)
- Design evolution (counter → GUID naming)
- Coordinate system design
- Key decision points with rationale
- Alternative approaches considered
- Implementation phases and status
- VDMA LIF compliance details

**Size:** ~800 lines  
**Audience:** Database designers, architects, developers  
**Use Case:** Understanding database design decisions

---

#### 2. **API_IMPLEMENTATION_GUIDE.md** 

**Purpose:** REST API implementation for MapEditor

**Contents:**
- 7 Controllers (42+ endpoints) detailed documentation
- Services layer architecture (14 services)
- Smart edge creation logic (auto node detection)
- Cascade delete logic (orphan cleanup)
- Enum types (OrientationType, RotationDirection)
- DTOs & Shared project (31 files)
- Configuration & dependency injection
- Deployment guide

**Size:** ~650 lines  
**Audience:** Backend developers, API consumers, AI assistants  
**Use Case:** Implementing/consuming the REST API

---

### **Frontend Documentation** 
#### 3. **LAYOUTMANAGER_USER_GUIDE.md** NEW

**Purpose:** User guide for LayoutManager page

**Contents:**
- UI overview & component layout
- Step-by-step feature guides
  - Create Layout/Version/Level
  - Upload & manage images
  - Edit level settings
  - Download/replace images
- Workflows (floor plan, SLAM map, multi-floor)
- Tips & best practices
- Troubleshooting guide

**Size:** ~650 lines  
**Audience:** End users, QA testers, product managers  
**Use Case:** Learning how to use LayoutManager

---

#### 4. **LAYOUTMANAGER_TECHNICAL.md** NEW

**Purpose:** Technical documentation for developers

**Contents:**
- Architecture overview (Blazor + ASP.NET Core)
- Component structure & hierarchy
- State management (LayoutManagerState)
- API integration (MapManagerApiService)
- Implementation details:
  - Custom tree view rendering
  - SVG preview with responsive viewBox
  - Image upload with dimension extraction
  - File download via JavaScript interop
- Extension guide (adding dialogs, endpoints)
- Performance optimization tips
- Testing strategies

**Size:** ~750 lines  
**Audience:** Frontend developers, AI assistants  
**Use Case:** Understanding & extending LayoutManager code

---

#### 5. **TESTING_GUIDE.md** 
**Purpose:** Testing checklist & troubleshooting

**Contents:**
- Quick start (run backend + frontend)
- Comprehensive test checklist (50+ test cases)
- Common issues & fixes
- Expected results & benchmarks
- Test data recommendations

**Size:** ~300 lines  
**Audience:** QA testers, developers  
**Use Case:** Testing LayoutManager functionality

---

## Quick Start

### For End Users

1. **Learn the UI:** Read `LAYOUTMANAGER_USER_GUIDE.md`
2. **Test the App:** Follow `TESTING_GUIDE.md`
3. **Access App:** Navigate to `/layout-manager` in browser

### For AI Assistants

**Backend:**
1. Database Design → `DATABASE_DESIGN_DISCUSSION.md`
2. API Implementation → `API_IMPLEMENTATION_GUIDE.md`

**Frontend:**
1. UI Architecture → `LAYOUTMANAGER_TECHNICAL.md`
2. User Workflows → `LAYOUTMANAGER_USER_GUIDE.md`

### For Backend Developers

1. **Understand the System:**
   - Database: Read `DATABASE_DESIGN_DISCUSSION.md`
   - API: Read `API_IMPLEMENTATION_GUIDE.md`

2. **Implement Features:**
   - Controllers: See `API_IMPLEMENTATION_GUIDE.md` → Controllers section
   - Services: See `API_IMPLEMENTATION_GUIDE.md` → Services section
   - Database: See `DATABASE_DESIGN_DISCUSSION.md` → Schema section

3. **Deploy:**
   - Apply migrations: `dotnet ef database update`
   - Configure `appsettings.json`
   - Run: `dotnet run`

### For Frontend Developers

1. **API Reference:** Read `API_IMPLEMENTATION_GUIDE.md`
2. **Component Architecture:** Read `LAYOUTMANAGER_TECHNICAL.md`
3. **DTOs:** Use types from `RobotNet10.MapEditor.Shared` project
4. **Extend UI:** See `LAYOUTMANAGER_TECHNICAL.md` → Extension Guide

### For QA/Testers

1. **Testing Checklist:** Read `TESTING_GUIDE.md`
2. **User Guide:** Read `LAYOUTMANAGER_USER_GUIDE.md`
3. **Report Issues:** Use TESTING_GUIDE troubleshooting section

---

## Project Statistics

### Backend

| Metric | Value |
|--------|-------|
| **Database Tables** | 11 |
| **Database Columns** | 79 |
| **Foreign Keys** | 14 |
| **Indexes** | 28 |
| **API Controllers** | 7 |
| **API Endpoints** | 42+ |
| **Service Classes** | 14 |
| **DTO Classes** | 31 |
| **Enum Types** | 3 |
| **Migrations** | 4 |
| **Backend Code** | ~6,000 lines |

### Frontend (LayoutManager)

| Metric | Value |
|--------|-------|
| **Pages** | 1 |
| **Components** | 8 |
| **Dialogs** | 5 |
| **Services** | 2 |
| **State Classes** | 1 |
| **Models** | 1 |
| **Frontend Code** | ~2,500 lines |
| **Documentation** | ~2,400 lines |

---

## Key Features

### Backend
- ✅ VDMA LIF 1.0.0 Compliant
- ✅ Multi-level layout support
- ✅ Version control
- ✅ Smart edge creation (auto node detection)
- ✅ Cascade delete with orphan cleanup
- ✅ Type-safe enums
- ✅ Dual coordinate system (World meters + Image pixels)
- ✅ Image management with ImageSharp
- ✅ Auto dimension extraction from PNG
- ✅ Scalable (100k+ nodes/edges per level)
- ✅ Import/Export VDMA LIF JSON

### Frontend (LayoutManager)
- ✅ Hierarchical tree view (Layout → Version → Level)
- ✅ Create layouts with image upload (single request)
- ✅ Auto-extract image dimensions (client + server)
- ✅ Edit coordinate system (Resolution, Origin)
- ✅ SVG preview canvas (responsive, no overflow)
- ✅ Download/Replace background images
- ✅ Real-time preview refresh
- ✅ Context menus for quick actions
- ✅ Search & filter layouts
- ✅ Activate/Deactivate layouts
- ✅ Clean, modern UI (MudBlazor)

---

## Related Files

### Implementation
- **Backend (MapManager):** `srcs/RobotNet10/Commons/RobotNet10.MapManager/`
- **Frontend (MapEditor):** `srcs/RobotNet10/Components/RobotNet10.MapEditor/`
- **Host App (RobotApp):** `srcs/RobotNet10/RobotApp/RobotNet10.RobotApp.Client/`
- **Shared DTOs:** `srcs/RobotNet10/RobotNet10.MapEditor.Shared/`

### Documentation (This Folder)
- **Database Design:** `DATABASE_DESIGN_DISCUSSION.md`
- **API Implementation:** `API_IMPLEMENTATION_GUIDE.md`
- **User Guide:** `LAYOUTMANAGER_USER_GUIDE.md` - **Technical Guide:** `LAYOUTMANAGER_TECHNICAL.md` - **Testing Guide:** `TESTING_GUIDE.md` 
### Other
- **VDMA LIF Schema:** `srcs/RobotNet10/Commons/RobotNet10.MapManager/lif-schema.json`
- **Integration Guide:** `srcs/RobotNet10/Components/RobotNet10.MapEditor/INTEGRATION_GUIDE.md`

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | 2024-11-26 | Initial schema (10 tables) |
| 2.0 | 2024-11-26 | GUID naming + EditorSettings |
| 2.5 | 2024-11-26 | Coordinate system |
| 3.0 | 2024-11-26 | Complete REST API (7 controllers) |
| 3.1 | 2024-11-26 | Enum types + Documentation consolidation |
| **4.0** | **2024-12-02** | **LayoutManager Frontend + Comprehensive Docs**  |

---

## ✅ Status

### Backend
**Database:** ✅ Complete (11 tables, 4 migrations)  
**API:** ✅ Complete (7 controllers, 42+ endpoints)  
**Services:** ✅ Complete (14 services)  
**DTOs:** ✅ Complete (31 DTOs, 3 enums)  
**Image Processing:** ✅ Complete (ImageSharp integration)  
**Build:** ✅ SUCCESS (0 warnings, 0 errors)  

### Frontend
**LayoutManager Page:** ✅ Complete  
**Components:** ✅ Complete (8 components, 5 dialogs)  
**State Management:** ✅ Complete  
**API Integration:** ✅ Complete  
**SVG Preview:** ✅ Complete (responsive, no overflow)  
**Image Upload:** ✅ Complete (with dimension extraction)  
**Build:** ✅ SUCCESS (0 warnings, 0 errors)  

### Documentation
**Database Design:** ✅ Complete  
**API Guide:** ✅ Complete  
**User Guide:** ✅ Complete (650 lines)   
**Technical Guide:** ✅ Complete (750 lines)   
**Testing Guide:** ✅ Complete (300 lines)   
**Total Docs:** ~2,400 lines   

---

## [ ] Next Steps

- [ ] LayoutEditor page (SVG canvas editor)
- [ ] Import/Export VDMA LIF (UI)
- [ ] Real-time collaboration (SignalR)
- [ ] Undo/Redo functionality
- [ ] Keyboard shortcuts
- [ ] Mobile-responsive improvements

---

**Last Updated:** 2024-12-02  
**Maintained by:** AI Assistant & DangNV  
**Status:** ✅ LayoutManager Ready for Production Testing

