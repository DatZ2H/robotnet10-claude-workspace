# LayoutManager - User Guide

**Version:** 1.0  
**Last Updated:** 2024-12-02  
**Author:** AI Assistant  

---

## Table of Contents

1. [Overview](#overview)
2. [User Interface](#user-interface)
3. [Features](#features)
4. [Workflows](#workflows)
5. [Tips & Best Practices](#tips--best-practices)

---

## Overview

**LayoutManager** là công cụ quản lý bản đồ (layouts) cho robot AGV/AMR. Nó cho phép:
- Tạo và quản lý layouts với versioning
- Upload background images (floor plans, SLAM maps)
- Cấu hình coordinate system (resolution, origin)
- Preview layouts với nodes, edges, stations
- Export/Import VDMA LIF format

### Key Concepts

```
Layout (Warehouse, Factory, ...)
  └─ Version (v1.0, v2.0, ...)
      └─ Level (floor_1, floor_2, ...)
          ├─ Background Image (PNG)
          ├─ Coordinate System (Resolution, Origin)
          └─ Map Elements (Nodes, Edges, Stations)
```

**Terminology:**
- **Layout:** Container cao nhất (e.g., "Warehouse A", "Factory Floor")
- **Version:** Phiên bản của layout, hỗ trợ rollback/versioning
- **Level:** Tầng/lớp của map (e.g., "Ground Floor", "Basement")
- **Background Image:** Ảnh nền (floor plan hoặc SLAM map)
- **Resolution:** Tỷ lệ chuyển đổi pixels → meters
- **Origin:** Gốc tọa độ trong hệ thống (meters)

---

## User Interface

### Page Layout

```
┌─────────────────────────────────────────────────────────────┐
│  Layout Manager              [Search...] [Import] [Add]     │
├──────────────┬──────────────────────────────────────────────┤
│              │                                               │
│   TREE       │              PREVIEW                          │
│   PANEL      │              PANEL                            │
│              │                                               │
│   Layouts    │   ┌──────────────────────────────┐           │
│   ├─ Layout1 │   │                              │           │
│   │  └─ v1.0 │   │     Background Image         │           │
│   │     └─L1 │   │     + Nodes + Edges          │           │
│   └─ Layout2 │   │                              │           │
│              │   └──────────────────────────────┘           │
│              │   [Download] [Replace Image]                 │
│              │                                               │
│              │   Layout Info | Elements | Settings          │
│              │                                               │
│              │   [Edit Layout] [Export LIF] [Refresh]       │
└──────────────┴──────────────────────────────────────────────┘
```

### Components

#### **1. Toolbar**
- **Search Box:** Filter layouts by name
- **Import Button:** Import VDMA LIF files (coming soon)
- **Add Layout:** Create new layout

#### **2. Tree Panel (Left)**
Hierarchical view:
```
Layouts
├─ Factory Layout [Active]
│  └─  v1.0 [Active]
│     ├─  floor_1
│     └─  floor_2
└─ Warehouse
   └─  v1.0
      └─  ground_floor
```

**Icons:**
- Layout
-  Version
-  Level

**Context Menus:**
- **Layout:** Add Version, Activate/Deactivate, Delete
- **Version:** Add Level, Delete
- **Level:** Edit Settings, Delete

#### **3. Preview Panel (Right)**

**Preview Canvas:**
- Background image (if uploaded)
- Nodes (red circles)
- Edges (blue lines)
- Stations (green squares)

**Action Buttons:**
- **Download Image:** Download background PNG
- **Replace Image:** Upload new background PNG
- **Edit Layout:** Open LayoutEditor (coming soon)
- **Export LIF:** Export to VDMA LIF format (coming soon)
- **Refresh:** Reload preview data

**Information Grid:**
```
┌──────────────────────────────────────────────────────────┐
│ LAYOUT INFO          ELEMENTS         LAYOUT SETTINGS    │
│ Layout: Factory      Nodes: 45        Resolution: 0.05   │
│ Version: 1.0         Edges: 60        Origin: (0, 0) m   │
│ Level: floor_1       Stations: 12     Image: 1024×768    │
│                                        Physical: 51.2×38.4│
└──────────────────────────────────────────────────────────┘
```

---

## Features

### 1. Create Layout

**Steps:**
1. Click **"Add Layout"** button
2. Fill in dialog:
   - **Layout ID:** Unique identifier (e.g., `warehouse_a`)
   - **Layout Name:** Display name (e.g., "Warehouse A")
   - **Description:** Optional description
3. Click **"Create"**

**Result:** New layout appears in tree

**Notes:**
- Layout ID must be unique
- Default status: Inactive
- Created by current logged-in user

---

### 2. Create Version

**Steps:**
1. Right-click **Layout** → "Add Version"
2. Fill in dialog:
   - **Version:** Version number (e.g., `1.0`, `2.1`)
   - **Description:** Optional notes about this version
3. Click **"Create"**

**Result:** New version appears under layout

**Notes:**
- Version can be any string
- First version is automatically active
- Multiple versions can exist, but only one active per layout

---

### 3. Create Level with Image

**Steps:**
1. Right-click **Version** → "Add Level"
2. Fill in dialog:

**Basic Info:**
   - **Level ID:** Unique identifier (e.g., `floor_1`)
   - **Level Order:** Display order (0, 1, 2, ...)

**Image Upload (REQUIRED):**
   - Click **"Choose PNG File"**
   - Select PNG file (max 10MB)
   - ✅ Dimensions auto-extracted (e.g., 1024 × 768 px)

**Coordinate System:**
   - **Resolution:** Meters per pixel (default: 0.05 m/px)
   - **Origin X:** X coordinate of origin (default: 0 m)
   - **Origin Y:** Y coordinate of origin (default: 0 m)
   - Physical size calculated: `ImageSize × Resolution`

3. Click **"Create Level"**
4. [ ] Wait for upload (progress indicator shows)

**Result:** 
- Level created with image
- Preview shows background image
- Settings saved with image dimensions

**Notes:**
- Image upload is **REQUIRED** (cannot create level without image)
- Backend extracts ImageWidth, ImageHeight automatically
- Physical bounds calculated: `[0, 0] → [ImageWidth × Resolution, ImageHeight × Resolution]`

**Example:**
```
Image: 1024 × 768 pixels
Resolution: 0.05 m/px
→ Physical Size: 51.2 × 38.4 meters
→ Bounds: (0, 0) → (51.2, 38.4)
```

---

### 4. Edit Level Settings

**Steps:**
1. Right-click **Level** → "Edit Settings"
2. Modify:
   - **Resolution:** Change m/px ratio
   - **Origin X, Y:** Adjust coordinate system origin
3. See real-time physical size update
4. Click **"Save Changes"**

**Result:** 
- Settings updated
- Preview recalculates display
- Physical size reflects new resolution

**Use Cases:**
- Adjust resolution after measuring real-world distances
- Shift origin to align with building coordinates
- Recalibrate after finding measurement errors

**Notes:**
- Image dimensions NOT editable (fixed when uploaded)
- To change image, use "Replace Image" button

---

### 5. Download Background Image

**Steps:**
1. Select **Level** in tree
2. Preview shows image
3. Click **"Download Image"**
4. File saves to Downloads folder (e.g., `floor_1_background.png`)

**Use Cases:**
- Backup original images
- Share floor plans with team
- Use in other tools (CAD, graphics editors)

---

### 6. Replace Background Image

**Steps:**
1. Select **Level** in tree
2. Click **"Replace Image"**
3. Choose new PNG file
4. [ ] Upload progress
5. ✅ Preview automatically refreshes

**Result:**
- New image replaces old one
- Image dimensions updated
- Physical size recalculated

**Use Cases:**
- Update floor plan after renovations
- Replace low-res with high-res image
- Correct uploaded wrong file

**Notes:**
- Old image is overwritten (not versioned)
- Image dimensions can change
- Resolution/origin settings preserved

---

### 7. Activate/Deactivate Layout

**Steps:**
1. Right-click **Layout** → "Activate" or "Deactivate"
2. Badge updates (green "Active" or no badge)

**Active vs Inactive:**
- **Active:** Layout is currently in use, can be used by robots
- **Inactive:** Layout archived, cannot be used

**Rules:**
- Only one layout can be active at a time (future: multiple active)
- Must deactivate before deleting
- Active layouts have visual badge

---

### 8. Delete Operations

#### **Delete Level**
1. Right-click **Level** → "Delete"
2. Confirm dialog
3. Level removed, image deleted

#### **Delete Version**
1. Right-click **Version** → "Delete"
2. Confirm dialog
3. Version + all levels removed

#### **Delete Layout**
1. Must be **deactivated** first
2. Right-click **Layout** → "Delete"
3. Confirm dialog
4. Layout + all versions + levels removed

**Safety:**
- Cannot delete active layouts
- Confirmation dialog prevents accidents
- Cascade delete removes children

---

## Workflows

### Workflow 1: New Map from Floor Plan

**Scenario:** You have a PNG floor plan, need to create navigable map.

```
1. Prepare PNG floor plan (clean, high contrast)
   ↓
2. Create Layout ("Factory A")
   ↓
3. Create Version ("1.0")
   ↓
4. Create Level with Image
   - Upload floor plan PNG
   - Set resolution (measure 1 meter = X pixels)
   - Set origin (usually 0,0 or building corner)
   ↓
5. Open LayoutEditor (future)
   - Add nodes (waypoints)
   - Connect edges (paths)
   - Define stations (pickup/dropoff)
   ↓
6. Test & Deploy
```

**Tips:**
- Measure resolution: Put tape measure on floor, count pixels in photo
- Typical resolution: 0.01 - 0.1 m/px
- Origin at bottom-left corner simplifies coordinates

---

### Workflow 2: SLAM Map Integration

**Scenario:** Robot generated SLAM map, need to import.

```
1. Export SLAM map as PNG from robot software
   ↓
2. Note SLAM map metadata:
   - Resolution (from SLAM config)
   - Origin (from SLAM config)
   ↓
3. Create Layout → Version → Level
   - Upload SLAM map PNG
   - Enter exact resolution from SLAM
   - Enter exact origin from SLAM
   ↓
4. Verify alignment:
   - Real-world distances match calculated
   - Origin aligns with robot's coordinate system
   ↓
5. Add nodes at known positions
   ↓
6. Deploy
```

**Tips:**
- SLAM resolution usually in config file (e.g., `resolution: 0.05`)
- SLAM origin often in map YAML (e.g., `origin: [-10.0, -10.0, 0.0]`)
- Verify by measuring known features (doors, walls)

---

### Workflow 3: Update Existing Map

**Scenario:** Floor layout changed, need to update map.

```
1. Select existing Level
   ↓
2. Option A: Minor changes
   - Open LayoutEditor
   - Adjust nodes/edges
   ↓
   Option B: Major changes (new floor plan)
   - Click "Replace Image"
   - Upload new floor plan
   - Adjust resolution/origin if needed
   ↓
3. Update nodes/edges to match new layout
   ↓
4. Test with robot
   ↓
5. If good: Keep version
   If issues: Create new version, revert if needed
```

**Tips:**
- Always test after image replacement
- Consider creating new version for major changes
- Keep old version as backup

---

### Workflow 4: Multi-Floor Building

**Scenario:** Building with multiple floors.

```
Layout: "Building A"
└─ Version: "1.0"
   ├─ Level: "basement" (order: 0)
   │  - Image: basement_plan.png
   │  - Origin: (0, 0)
   ├─ Level: "ground_floor" (order: 1)
   │  - Image: ground_plan.png
   │  - Origin: (0, 0)
   └─ Level: "floor_2" (order: 2)
      - Image: floor2_plan.png
      - Origin: (0, 0)
```

**Key Points:**
- Use **Level Order** to sort floors (0 = lowest)
- Use **same resolution** for all floors if possible
- Use **same origin** convention (e.g., SW corner of building)
- Each level has independent image and coordinate system

---

## Tips & Best Practices

### Image Preparation

✅ **DO:**
- Use high-resolution images (at least 1024 px on shortest side)
- Clean floor plan (remove furniture, labels if possible)
- High contrast (walls dark, floor light or vice versa)
- Accurate scale (measure real-world distances)
- PNG format (lossless, supports transparency)

❌ **DON'T:**
- Use JPEG (lossy compression, artifacts)
- Include skewed/distorted photos (correct perspective first)
- Mix different scales in one image
- Use images with text overlays (remove first)

### Resolution Guidelines

| Environment | Typical Resolution | Notes |
|-------------|-------------------|-------|
| Small indoor | 0.01 - 0.02 m/px | High precision |
| Medium indoor | 0.05 m/px | Good balance |
| Large warehouse | 0.1 m/px | Larger area coverage |
| Outdoor | 0.2 - 0.5 m/px | Lower precision OK |

**How to measure:**
1. Place object of known size in scene (e.g., 1m ruler)
2. Count pixels in photo
3. Resolution = RealSize / PixelCount

**Example:**
- Ruler: 1 meter
- Pixels: 20 pixels
- Resolution: 1m / 20px = 0.05 m/px

### Naming Conventions

**Layout IDs:**
- Use lowercase, underscores
- Examples: `warehouse_a`, `factory_floor_1`, `office_building_a`

**Layout Names:**
- Use Title Case, spaces OK
- Examples: "Warehouse A", "Factory Floor 1", "Office Building A"

**Versions:**
- Semantic versioning: `Major.Minor` (e.g., 1.0, 1.1, 2.0)
- Or date-based: `2024.12.02`
- Or descriptive: `production`, `testing`, `backup`

**Level IDs:**
- Descriptive: `floor_1`, `basement`, `ground_floor`, `roof`
- Or numbered: `level_0`, `level_1`, `level_2`

### Version Management

**When to create new version:**
- Major layout changes (walls added/removed)
- Complete re-mapping
- Switching from floor plan to SLAM map
- Before risky changes (for rollback)

**When to update existing version:**
- Minor adjustments (node positions)
- Adding new nodes/edges
- Tweaking resolution/origin
- Bug fixes

### Data Organization

```
Production System:
└─ Warehouse Layout [Active]
   ├─ v2.1 [Active] ← Current production
   ├─ v2.0 ← Previous stable
   └─ v1.0 ← Original

Testing System:
└─ Warehouse Layout [Active]
   └─ v3.0-beta [Active] ← Testing new layout
```

**Strategy:**
- Keep 2-3 old versions for rollback
- Use testing layout for experiments
- Activate in production only after thorough testing

### Performance Tips

- **Image size:** Keep < 2048×2048 px for good performance
- **File size:** Keep < 5 MB for fast upload
- **Compression:** Use PNG with optimized compression
- **Lazy loading:** Only preview shows on selection (not all at once)

### Troubleshooting

**Problem: Image looks distorted**
- Cause: Wrong aspect ratio or preserveAspectRatio setting
- Fix: Check image dimensions, re-upload if needed

**Problem: Coordinates don't match reality**
- Cause: Wrong resolution or origin
- Fix: Measure real-world distance, recalculate resolution

**Problem: Upload fails**
- Cause: File too large (> 10 MB) or not PNG
- Fix: Compress image, convert to PNG

**Problem: Preview blank**
- Cause: No image uploaded or image load failed
- Fix: Check console for errors, re-upload image

---

## Keyboard Shortcuts (Future)

| Shortcut | Action |
|----------|--------|
| `Ctrl+N` | New Layout |
| `Ctrl+F` | Focus Search |
| `Del` | Delete Selected |
| `F5` | Refresh Preview |
| `Ctrl+E` | Edit Level Settings |

---

## Related Documentation

- [API Implementation Guide](./API_IMPLEMENTATION_GUIDE.md)
- [Database Design](./DATABASE_DESIGN_DISCUSSION.md)
- [Testing Guide](./TESTING_GUIDE.md)
- [LayoutEditor Guide](./LAYOUTEDITOR_USER_GUIDE.md) (coming soon)

---

**Need Help?**
- Check Console (F12) for error messages
- Review [Testing Guide](./TESTING_GUIDE.md) for common issues
- Contact: support@phenikaa.com

