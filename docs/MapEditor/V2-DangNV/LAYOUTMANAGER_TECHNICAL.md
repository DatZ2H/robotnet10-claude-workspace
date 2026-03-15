# LayoutManager - Technical Documentation

**Version:** 1.0  
**Last Updated:** 2024-12-02  
**Target Audience:** Developers  

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Component Structure](#component-structure)
3. [State Management](#state-management)
4. [API Integration](#api-integration)
5. [Implementation Details](#implementation-details)
6. [Extension Guide](#extension-guide)

---

## Architecture Overview

### Tech Stack

```
┌─────────────────────────────────────────────────┐
│              Frontend (Blazor WASM)             │
├─────────────────────────────────────────────────┤
│  RobotNet10.RobotApp.Client (Host)             │
│    └─ RobotNet10.MapEditor (Component Library) │
│       ├─ Pages/                                 │
│       │  └─ LayoutManager.razor (Route)        │
│       ├─ Components/                            │
│       │  ├─ LayoutManagerComponent.razor       │
│       │  ├─ LayoutTreePanel.razor              │
│       │  ├─ LayoutPreviewPanel.razor           │
│       │  ├─ SvgPreviewCanvas.razor             │
│       │  └─ Dialogs/                            │
│       ├─ Services/                              │
│       │  ├─ State/                              │
│       │  │  └─ LayoutManagerState.cs           │
│       │  └─ API/                                │
│       │     └─ MapManagerApiService.cs         │
│       └─ Models/                                │
│          └─ TreeItemModel.cs                   │
└─────────────────────────────────────────────────┘
                     ↕ HTTP/REST
┌─────────────────────────────────────────────────┐
│           Backend (ASP.NET Core API)            │
├─────────────────────────────────────────────────┤
│  RobotNet10.MapManager                         │
│    ├─ Controllers/                              │
│    │  ├─ LayoutManagerController.cs            │
│    │  ├─ LayoutDataController.cs               │
│    │  └─ ImagesController.cs                   │
│    ├─ Services/                                 │
│    │  ├─ LayoutService.cs                      │
│    │  ├─ IImageStorageService.cs               │
│    │  └─ FileSystemImageStorageService.cs      │
│    └─ Data/                                     │
│       └─ MapManagerDbContext.cs                │
└─────────────────────────────────────────────────┘
                     ↕
┌─────────────────────────────────────────────────┐
│              Database (SQLite)                  │
│  - Layouts, LayoutVersions, LayoutLevels       │
│  - Nodes, Edges, Stations                      │
│  - LayoutLevelEditorSettings                   │
└─────────────────────────────────────────────────┘
```

### Design Patterns

1. **Component Pattern:** Separation of Page vs Component
   - `LayoutManager.razor` (Page): Routing, render mode, providers
   - `LayoutManagerComponent.razor` (Component): Business logic, UI

2. **State Management:** Centralized state with event notification
   - `LayoutManagerState`: Single source of truth
   - `OnStateChanged` event for reactive updates

3. **API Service:** HTTP client wrapper
   - `MapManagerApiService`: Encapsulates all API calls
   - Typed DTOs for request/response

4. **Repository Pattern:** Backend data access
   - `ILayoutService`: Business logic interface
   - EF Core for data persistence

---

## Component Structure

### File Organization

```
RobotNet10.MapEditor/
├─ Pages/
│  └─ LayoutManager.razor              ← Route entry point
│
├─ Components/
│  └─ LayoutManager/
│     ├─ LayoutManagerComponent.razor  ← Main component
│     ├─ LayoutTreePanel.razor         ← Hierarchical tree
│     ├─ LayoutPreviewPanel.razor      ← Preview + actions
│     └─ Dialogs/
│        ├─ CreateLayoutDialog.razor
│        ├─ CreateVersionDialog.razor
│        ├─ CreateLevelDialog.razor
│        ├─ EditLevelDialog.razor
│        ├─ ImportLayoutDialog.razor
│        └─ ExportLayoutDialog.razor
│
├─ Components/Shared/
│  └─ SvgPreviewCanvas.razor           ← SVG rendering
│
├─ Services/
│  ├─ State/
│  │  └─ LayoutManagerState.cs         ← State management
│  └─ API/
│     └─ MapManagerApiService.cs       ← HTTP client
│
└─ Models/
   └─ TreeItemModel.cs                 ← Tree node model
```

### Component Hierarchy

```
LayoutManager.razor (Page)
  └─ LayoutManagerComponent.razor
      ├─ LayoutTreePanel.razor
      │   ├─ CreateLayoutDialog (MudDialog)
      │   ├─ CreateVersionDialog (MudDialog)
      │   ├─ CreateLevelDialog (MudDialog)
      │   └─ EditLevelDialog (MudDialog)
      │
      └─ LayoutPreviewPanel.razor
          ├─ SvgPreviewCanvas.razor
          ├─ ImportLayoutDialog (MudDialog)
          └─ ExportLayoutDialog (MudDialog)
```

---

## State Management

### LayoutManagerState.cs

**Responsibilities:**
- Hold current UI state (selected layout/version/level)
- Load data from API
- Cache preview data and images
- Notify components of changes via events

**Key Properties:**

```csharp
public class LayoutManagerState
{
    // Data
    public List<LayoutDto> Layouts { get; private set; }
    public LayoutDto? SelectedLayout { get; private set; }
    public LayoutVersionDto? SelectedVersion { get; private set; }
    public LayoutLevelDto? SelectedLevel { get; private set; }
    
    // Preview Data
    public LayoutDataDto? PreviewData { get; private set; }
    public byte[]? PreviewImage { get; private set; }
    
    // Loading States
    public bool IsLoading { get; private set; }
    public bool IsLoadingPreview { get; private set; }
    
    // Event for reactive updates
    public event Action? OnStateChanged;
}
```

**Key Methods:**

```csharp
// Load all layouts from API
public async Task LoadLayoutsAsync(string? search = null)

// Select a level and load its preview
public async Task SelectLevelAsync(LayoutLevelDto level)

// CRUD operations
public async Task CreateLayoutAsync(CreateLayoutRequest request)
public async Task CreateVersionAsync(Guid layoutId, CreateLayoutVersionRequest request)
public async Task CreateLevelAsync(Guid versionId, CreateLayoutLevelRequest request)
public async Task DeleteLayoutAsync(Guid layoutId)
public async Task DeleteVersionAsync(Guid versionId)
public async Task DeleteLevelAsync(Guid levelId)
```

**Usage Pattern:**

```csharp
@inject LayoutManagerState State
@implements IDisposable

protected override async Task OnInitializedAsync()
{
    // Subscribe to state changes
    State.OnStateChanged += StateHasChanged;
    
    // Load initial data
    await State.LoadLayoutsAsync();
}

public void Dispose()
{
    // Unsubscribe to prevent memory leaks
    State.OnStateChanged -= StateHasChanged;
}
```

---

## API Integration

### MapManagerApiService.cs

**Base Configuration:**

```csharp
// Program.cs
builder.Services.AddHttpClient<MapManagerApiService>(client =>
{
    var baseUrl = builder.Configuration["MapManagerApi:BaseUrl"] ?? "https://localhost:5001";
    client.BaseAddress = new Uri(baseUrl);
});

builder.Services.AddScoped<LayoutManagerState>();
```

**API Methods:**

```csharp
public class MapManagerApiService
{
    // Layouts
    Task<List<LayoutDto>> SearchLayoutsAsync(string? search = null)
    Task<LayoutDto> CreateLayoutAsync(CreateLayoutRequest request)
    Task<LayoutDto> UpdateLayoutAsync(Guid layoutId, UpdateLayoutRequest request)
    Task DeleteLayoutAsync(Guid layoutId)
    Task<LayoutDto> ActivateLayoutAsync(Guid layoutId)
    Task<LayoutDto> DeactivateLayoutAsync(Guid layoutId)
    
    // Versions
    Task<LayoutVersionDto> CreateVersionAsync(Guid layoutId, CreateLayoutVersionRequest request)
    Task<List<LayoutVersionDto>> GetVersionsAsync(Guid layoutId)
    Task DeleteVersionAsync(Guid versionId)
    
    // Levels
    Task<LayoutLevelDto> CreateLevelAsync(Guid versionId, CreateLayoutLevelRequest request)
    Task<LayoutLevelDto> CreateLevelWithImageAsync(
        Guid versionId, string layoutLevelId, int levelOrder,
        double resolution, double originX, double originY,
        Stream imageStream, string fileName)
    Task<LayoutLevelDto> UpdateLevelAsync(Guid levelId, UpdateLayoutLevelRequest request)
    Task DeleteLevelAsync(Guid levelId)
    
    // Layout Data
    Task<LayoutDataDto> GetLayoutDataAsync(Guid layoutLevelId)
    
    // Images
    Task<byte[]?> GetLayoutImageAsync(Guid layoutLevelId)
    Task UploadLayoutImageAsync(Guid layoutLevelId, Stream imageStream, string fileName)
    Task DeleteLayoutImageAsync(Guid layoutLevelId)
}
```

### HTTP Request Flow

**Example: Create Level with Image**

```
1. Frontend: User fills CreateLevelDialog
   ↓
2. Frontend: Call CreateLevelWithImageAsync()
   ↓
3. HTTP: POST /api/layouts/versions/{versionId}/levels/with-image
   Content-Type: multipart/form-data
   Body:
     - layoutLevelId: "floor_1"
     - levelOrder: 0
     - resolution: 0.05
     - originX: 0
     - originY: 0
     - file: [PNG binary]
   ↓
4. Backend: LayoutManagerController.CreateLevelWithImage()
   a. Extract image dimensions (ImageSharp)
   b. Create LayoutLevel entity
   c. Create LayoutLevelEditorSettings entity
   d. Save to database
   e. Upload image to storage
   f. (Rollback if image upload fails)
   ↓
5. Backend: Return 201 Created with LayoutLevelDto
   ↓
6. Frontend: Update state, refresh UI
   ↓
7. Frontend: Show success notification
```

---

## Implementation Details

### 1. Tree View Implementation

**Challenge:** MudBlazor `MudTreeView` has complex data binding.

**Solution:** Custom tree rendering with nested MudPaper + MudStack

```razor
@foreach (var layout in State.Layouts)
{
    <MudPaper>
        <MudStack Row="true">
            <MudIconButton Icon="..." OnClick="() => ToggleLayout(layout.Id)" />
            <MudIcon Icon="@Icons.Material.Filled.Map" />
            <MudText>@layout.LayoutName</MudText>
            <MudMenu>...</MudMenu>
        </MudStack>
    </MudPaper>
    
    @if (expandedLayouts.Contains(layout.Id))
    {
        <MudStack Class="ml-6">
            @foreach (var version in layout.Versions)
            {
                <!-- Nested version rendering -->
            }
        </MudStack>
    }
}
```

**State:**
```csharp
private HashSet<Guid> expandedLayouts = new();
private HashSet<Guid> expandedVersions = new();

private void ToggleLayout(Guid layoutId)
{
    if (expandedLayouts.Contains(layoutId))
        expandedLayouts.Remove(layoutId);
    else
        expandedLayouts.Add(layoutId);
}
```

---

### 2. SVG Preview Canvas

**Challenge:** Responsive SVG that fits container without overflow.

**Solution:** Dynamic viewBox calculation

```razor
<svg width="100%" height="100%" viewBox="@ViewBoxString" ...>
    <image href="@GetImageDataUrl()" 
           x="0" y="0"
           width="@GetImageWidth()" 
           height="@GetImageHeight()" />
    
    <!-- Nodes, Edges, Stations -->
</svg>
```

**ViewBox Logic:**
```csharp
private string ViewBoxString
{
    get
    {
        // If image exists, use physical size (meters)
        if (EditorSettings?.ImageWidth.HasValue == true)
        {
            var width = EditorSettings.ImageWidth.Value * EditorSettings.Resolution;
            var height = EditorSettings.ImageHeight.Value * EditorSettings.Resolution;
            return $"0 0 {width:F2} {height:F2}";
        }
        
        // Otherwise, calculate from nodes
        if (LayoutData?.Nodes.Count > 0)
        {
            var minX = LayoutData.Nodes.Min(n => n.X);
            var maxX = LayoutData.Nodes.Max(n => n.X);
            var minY = LayoutData.Nodes.Min(n => n.Y);
            var maxY = LayoutData.Nodes.Max(n => n.Y);
            var padding = Math.Max((maxX - minX), (maxY - minY)) * 0.1;
            return $"{minX - padding:F2} {minY - padding:F2} ...";
        }
        
        // Default
        return "0 0 100 50";
    }
}
```

**Key Points:**
- `width="100%" height="100%"` → SVG scales to container
- `viewBox` defines coordinate system (meters, not pixels)
- Image dimensions in meters: `PixelSize × Resolution`
- `preserveAspectRatio="none"` → Image stretches to fill viewBox

---

### 3. Image Upload with Dimension Extraction

**Frontend (Client-Side):**

```csharp
private async Task OnImageSelected(InputFileChangeEventArgs e)
{
    var file = e.File;
    
    // Read file as byte array
    using var stream = file.OpenReadStream(maxAllowedSize: 10 * 1024 * 1024);
    using var ms = new MemoryStream();
    await stream.CopyToAsync(ms);
    var bytes = ms.ToArray();
    
    // Extract dimensions from PNG header (bytes 16-23)
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47)
    {
        imageWidth = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
        imageHeight = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
    }
}
```

**Backend (Server-Side with ImageSharp):**

```csharp
// In FileSystemImageStorageService.cs
public async Task<(int width, int height)> GetImageDimensionsAsync(Stream imageStream)
{
    if (imageStream.CanSeek)
        imageStream.Position = 0;
    
    using var image = await Image.LoadAsync(imageStream);
    return (image.Width, image.Height);
}

// In LayoutManagerController.cs
[HttpPost("versions/{versionId:guid}/levels/with-image")]
public async Task<ActionResult<LayoutLevelDto>> CreateLevelWithImage(
    Guid versionId, [FromForm] string layoutLevelId, ... , IFormFile file)
{
    // Step 1: Extract dimensions
    int imageWidth, imageHeight;
    using (var stream = file.OpenReadStream())
    {
        (imageWidth, imageHeight) = await _imageStorageService.GetImageDimensionsAsync(stream);
    }
    
    // Step 2: Create level with dimensions
    var request = new CreateLayoutLevelRequest
    {
        LayoutLevelId = layoutLevelId,
        CoordinateSystem = new CoordinateSystemInfo
        {
            Resolution = resolution,
            OriginX = originX,
            OriginY = originY,
            ImageWidth = imageWidth,
            ImageHeight = imageHeight,
            BoundsMinX = 0,
            BoundsMaxX = imageWidth * resolution,
            BoundsMinY = 0,
            BoundsMaxY = imageHeight * resolution
        }
    };
    
    var level = await _layoutService.CreateLevelAsync(versionId, request);
    
    // Step 3: Upload image
    try
    {
        using (var stream = file.OpenReadStream())
        {
            await _imageStorageService.SaveImageAsync(level.Id, stream);
        }
    }
    catch
    {
        // Rollback: Delete created level
        await _layoutService.DeleteLevelAsync(level.Id);
        throw;
    }
    
    return CreatedAtAction(nameof(GetLevel), new { levelId = level.Id }, dto);
}
```

---

### 4. File Download (JavaScript Interop)

**Challenge:** Download byte[] as file from Blazor WASM.

**Solution:** Generate data URL and trigger download via JS

```csharp
private async Task DownloadImage()
{
    if (State.PreviewImage == null) return;
    
    var base64 = Convert.ToBase64String(State.PreviewImage);
    var fileName = $"{State.SelectedLevel.LayoutLevelId}_background.png";
    
    await JS.InvokeVoidAsync("eval", 
        $@"
        const link = document.createElement('a');
        link.href = 'data:image/png;base64,{base64}';
        link.download = '{fileName}';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        ");
}
```

**Alternative (Cleaner):**

Create `wwwroot/download.js`:
```javascript
window.downloadFile = (fileName, base64Data) => {
    const link = document.createElement('a');
    link.href = `data:image/png;base64,${base64Data}`;
    link.download = fileName;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
};
```

Then in Blazor:
```csharp
await JS.InvokeVoidAsync("downloadFile", fileName, base64);
```

---

## Extension Guide

### Adding New Dialog

1. **Create Dialog Component:**

```razor
@* NewFeatureDialog.razor *@
@inject MapManagerApiService ApiService
@inject ISnackbar Snackbar

<MudDialog>
    <DialogContent>
        <!-- Form fields -->
    </DialogContent>
    <DialogActions>
        <MudButton OnClick="Cancel">Cancel</MudButton>
        <MudButton Color="Color.Primary" OnClick="Submit">Submit</MudButton>
    </DialogActions>
</MudDialog>

@code {
    [CascadingParameter] private IMudDialogInstance? MudDialog { get; set; }
    [Parameter] public SomeDto Data { get; set; }
    
    private void Cancel() => MudDialog?.Cancel();
    
    private async Task Submit()
    {
        // Call API
        // Close dialog
        MudDialog?.Close(DialogResult.Ok(result));
    }
}
```

2. **Register in Parent Component:**

```csharp
private async Task OpenNewFeatureDialog()
{
    var dialog = await DialogService.ShowAsync<NewFeatureDialog>(
        "Title",
        new DialogParameters { ["Data"] = someData });
    
    var result = await dialog.Result;
    
    if (result != null && !result.Canceled)
    {
        Snackbar.Add("Success!", Severity.Success);
        await RefreshData();
    }
}
```

---

### Adding New API Endpoint

1. **Backend Controller:**

```csharp
[HttpPost("custom-action")]
public async Task<IActionResult> CustomAction([FromBody] CustomRequest request)
{
    var result = await _service.DoSomethingAsync(request);
    return Ok(result);
}
```

2. **Frontend API Service:**

```csharp
public async Task<CustomResponse> CustomActionAsync(CustomRequest request)
{
    var response = await _httpClient.PostAsJsonAsync(
        $"{_baseUrl}api/layouts/custom-action", request);
    response.EnsureSuccessStatusCode();
    return await response.Content.ReadFromJsonAsync<CustomResponse>();
}
```

3. **Use in State:**

```csharp
public async Task PerformCustomActionAsync(CustomRequest request)
{
    IsLoading = true;
    NotifyStateChanged();
    
    try
    {
        var result = await _apiService.CustomActionAsync(request);
        // Update state
    }
    finally
    {
        IsLoading = false;
        NotifyStateChanged();
    }
}
```

---

### Performance Optimization

**1. Debounce Search:**

```csharp
private Timer? searchTimer;

private void OnSearchKeyUp(KeyboardEventArgs e)
{
    searchTimer?.Dispose();
    searchTimer = new Timer(async _ =>
    {
        await InvokeAsync(async () =>
        {
            await State.LoadLayoutsAsync(searchText);
        });
    }, null, 500, Timeout.Infinite); // 500ms debounce
}
```

**2. Lazy Load Images:**

```csharp
// Only load image when level selected
public async Task SelectLevelAsync(LayoutLevelDto level)
{
    SelectedLevel = level;
    IsLoadingPreview = true;
    NotifyStateChanged();
    
    // Load preview data
    PreviewData = await _apiService.GetLayoutDataAsync(level.Id);
    
    // Load image separately (can be large)
    PreviewImage = await _apiService.GetLayoutImageAsync(level.Id);
    
    IsLoadingPreview = false;
    NotifyStateChanged();
}
```

**3. Cache API Responses:**

```csharp
private Dictionary<Guid, LayoutDataDto> _previewCache = new();

public async Task<LayoutDataDto> GetLayoutDataCachedAsync(Guid levelId)
{
    if (_previewCache.TryGetValue(levelId, out var cached))
        return cached;
    
    var data = await _apiService.GetLayoutDataAsync(levelId);
    _previewCache[levelId] = data;
    return data;
}
```

---

## Testing

### Unit Tests

```csharp
[Fact]
public async Task CreateLevel_WithImage_ShouldExtractDimensions()
{
    // Arrange
    var service = new FileSystemImageStorageService(logger);
    using var stream = File.OpenRead("test_1024x768.png");
    
    // Act
    var (width, height) = await service.GetImageDimensionsAsync(stream);
    
    // Assert
    Assert.Equal(1024, width);
    Assert.Equal(768, height);
}
```

### Integration Tests

```csharp
[Fact]
public async Task E2E_CreateLayoutWithLevel()
{
    // Create layout
    var layout = await apiService.CreateLayoutAsync(new CreateLayoutRequest
    {
        LayoutId = "test",
        LayoutName = "Test"
    });
    
    // Create version
    var version = await apiService.CreateVersionAsync(layout.Id, new CreateLayoutVersionRequest
    {
        Version = "1.0"
    });
    
    // Create level with image
    using var imageStream = File.OpenRead("test.png");
    var level = await apiService.CreateLevelWithImageAsync(
        version.Id, "floor_1", 0, 0.05, 0, 0, imageStream, "test.png");
    
    // Assert
    Assert.NotNull(level);
    Assert.Equal("floor_1", level.LayoutLevelId);
    Assert.NotNull(level.EditorSettings);
    Assert.True(level.EditorSettings.ImageWidth > 0);
}
```

---

## Troubleshooting

### Common Issues

**1. CORS Errors:**
```
Access to XMLHttpRequest at 'https://localhost:5001/api/layouts' from origin 'https://localhost:5002' 
has been blocked by CORS policy
```

**Fix:** Configure CORS in backend `Program.cs`:
```csharp
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins("https://localhost:5002")
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

app.UseCors();
```

**2. Image Upload 413 Payload Too Large:**

**Fix:** Increase max request size:
```csharp
// Program.cs
builder.Services.Configure<FormOptions>(options =>
{
    options.MultipartBodyLengthLimit = 10 * 1024 * 1024; // 10 MB
});

// Also in web.config for IIS
<system.webServer>
  <security>
    <requestFiltering>
      <requestLimits maxAllowedContentLength="10485760" />
    </requestFiltering>
  </security>
</system.webServer>
```

**3. State Not Updating:**

Check:
- Subscribed to `OnStateChanged` event?
- Calling `StateHasChanged()` in event handler?
- Disposed subscription to prevent memory leaks?

```csharp
protected override async Task OnInitializedAsync()
{
    State.OnStateChanged += StateHasChanged; // ✅
    await State.LoadLayoutsAsync();
}

public void Dispose()
{
    State.OnStateChanged -= StateHasChanged; // ✅ Important!
}
```

---

## Best Practices

1. **Always validate input before API calls**
2. **Handle exceptions and show user-friendly messages**
3. **Use loading indicators for async operations**
4. **Dispose subscriptions and timers**
5. **Keep components small and focused**
6. **Extract reusable logic into services**
7. **Use typed DTOs, avoid magic strings**
8. **Log errors for debugging**
9. **Test with real data (large images, many nodes)**
10. **Profile performance for bottlenecks**

---

## Future Improvements

- [ ] Batch operations (delete multiple levels)
- [ ] Undo/Redo for state changes
- [ ] Keyboard shortcuts
- [ ] Drag & drop image upload
- [ ] Image cropping/editing in browser
- [ ] Multi-select in tree (Ctrl+Click)
- [ ] Export selected layouts to ZIP
- [ ] Real-time collaboration (SignalR)
- [ ] Offline support (IndexedDB cache)
- [ ] Mobile-responsive layout

---

## References

- [MudBlazor Documentation](https://mudblazor.com/)
- [Blazor WebAssembly Guide](https://learn.microsoft.com/en-us/aspnet/core/blazor/)
- [ImageSharp Documentation](https://docs.sixlabors.com/api/ImageSharp/)
- [SVG Specification](https://www.w3.org/TR/SVG2/)
- [VDMA LIF Standard](../VDMA_LIF_Standard.md)

---

**Questions? Contact: dev-team@phenikaa.com**

