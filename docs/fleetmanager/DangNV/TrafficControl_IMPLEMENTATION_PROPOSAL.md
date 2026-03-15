# Traffic Control Implementation Proposal
## Đề xuất Triển khai Hệ thống Điều khiển Giao thông

**Version:** 1.0  
**Date:** 2025-01-XX  
**Status:** Proposal Phase

---

## Tổng quan / Overview

Tài liệu này đề xuất giải pháp xây dựng hệ thống **Traffic Control** cho nhiều robot với các yêu cầu:
- Bản đồ dạng Graph (Node, Edge) với hỗ trợ bidirectional edges (EdgeAB và EdgeBA)
- Đường đi robot là lộ trình với n Node và n-1 Edge
- Xử lý xung đột real-time
- Tích hợp với quản lý Order theo VDA5050
- Robot nhận lệnh di chuyển theo VDA5050

---

## Mục tiêu / Goals

1. **Route Planning**: Tính toán tuyến đường tối ưu giữa các nodes
2. **Conflict Detection**: Phát hiện xung đột real-time giữa các robot
3. **Conflict Resolution**: Giải quyết xung đột bằng cách điều chỉnh routes
4. **Base/Horizon Management**: Quản lý phần order đã release (base) và chưa release (horizon)
5. **Order Updates**: Gửi OrderUpdate để điều chỉnh route khi cần

---

## Kiến trúc Tổng thể / System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    FleetManager                              │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         TrafficControl Service                       │   │
│  │  - Route Planning (A*)                               │   │
│  │  - Conflict Detection                                │   │
│  │  - Conflict Resolution                               │   │
│  │  - Base/Horizon Management                          │   │
│  └──────────┬───────────────────────┬───────────────────┘   │
│             │                       │                        │
│  ┌──────────▼──────────┐  ┌────────▼──────────┐             │
│  │  RobotManager       │  │  GlobalPathPlanner│             │
│  │  - Robot states     │  │  - A* Algorithm   │             │
│  │  - Current routes   │  │  - Graph data     │             │
│  └──────────┬──────────┘  └───────────────────┘             │
│             │                                                │
│  ┌──────────▼──────────────────────────────────────────┐   │
│  │         RobotController (per robot)                 │   │
│  │  - Send OrderUpdate via MQTT                        │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Models / Mô hình Dữ liệu

### 1. Robot Route / Lộ trình Robot

```csharp
public class RobotRoute
{
    public string RobotId { get; set; }
    public string OrderId { get; set; }
    public int OrderUpdateId { get; set; }
    
    // Full route (base + horizon)
    public List<RouteSegment> FullRoute { get; set; } = new();
    
    // Base: Đã release, robot đang thực hiện
    public List<RouteSegment> Base { get; set; } = new();
    
    // Horizon: Chưa release, đang chờ điều kiện
    public List<RouteSegment> Horizon { get; set; } = new();
    
    // Current position trong route
    public int CurrentSegmentIndex { get; set; }
    
    // Timestamp
    public DateTime CreatedAt { get; set; }
    public DateTime LastUpdated { get; set; }
}

public class RouteSegment
{
    public Guid NodeId { get; set; }
    public string NodeIdString { get; set; }  // VDMA LIF nodeId
    public Guid? EdgeId { get; set; }          // Null nếu là node cuối
    public string? EdgeIdString { get; set; } // VDMA LIF edgeId
    public int SequenceId { get; set; }        // VDA5050 sequenceId
    public bool Released { get; set; }        // Đã release vào base chưa
    public DateTime? ReservedUntil { get; set; } // Thời gian reserve edge này
}
```

### 2. Edge Reservation / Đặt chỗ Edge

```csharp
public class EdgeReservation
{
    public Guid EdgeId { get; set; }
    public string EdgeIdString { get; set; }
    public Guid StartNodeId { get; set; }      // Node bắt đầu của edge
    public Guid EndNodeId { get; set; }        // Node kết thúc của edge
    public string RobotId { get; set; }
    public string OrderId { get; set; }
    public DateTime ReservedAt { get; set; }
    public DateTime ReservedUntil { get; set; }  // Dựa trên tốc độ và chiều dài edge
    public ReservationStatus Status { get; set; }
}

public enum ReservationStatus
{
    Reserved,      // Đã đặt chỗ
    InUse,         // Robot đang sử dụng
    Released       // Đã giải phóng
}
```

**Lưu ý**: Không giới hạn số robot trên 1 edge cùng lúc. Nhiều robot có thể sử dụng cùng edge nếu không có xung đột.

### 3. Conflict / Xung đột

```csharp
public class Conflict
{
    public ConflictType Type { get; set; }
    public List<string> InvolvedRobots { get; set; } = new();
    public List<Guid> ConflictingEdges { get; set; } = new();
    public List<Guid> ConflictingNodes { get; set; } = new();
    public DateTime DetectedAt { get; set; }
    public ConflictSeverity Severity { get; set; }
    public ConflictResolution? Resolution { get; set; }
    
    // Thông tin chi tiết về xung đột
    public Dictionary<string, object> ConflictDetails { get; set; } = new();
    
    // Đánh giá tác động khi giải quyết conflict này
    public int EstimatedNewConflicts { get; set; }  // Số xung đột mới có thể phát sinh
    public List<string> CanResolveConflicts { get; set; } = new();  // Các conflict khác có thể giải quyết được
}

public enum ConflictType
{
    /// <summary>
    /// Xảy ra khi hai robot sử dụng cùng một cạnh (edge) trong biểu đồ đường đi (graph) 
    /// trong khoảng thời gian trùng lặp, đồng thời lộ trình tiếp theo của robot chồng lên nhau.
    /// </summary>
    Confrontation,

    /// <summary>
    /// Xảy ra khi hai robot sử dụng cùng một cạnh (edge) trong biểu đồ đường đi (graph) 
    /// trong khoảng thời gian trùng lặp nhưng lộ trình tiếp theo của 2 robot không chồng lấn lên nhau.
    /// </summary>
    Edge,

    /// <summary>
    /// Xảy ra khi hai robot chiếm cùng một nút (vertex/node) trong biểu đồ đường đi 
    /// tại cùng một thời điểm hoặc trong khoảng thời gian trùng lặp.
    /// </summary>
    Vertex,

    /// <summary>
    /// Xảy ra khi hai robot ở quá gần nhau (dựa trên khoảng cách Euclidean) trong không gian liên tục, 
    /// vi phạm khoảng cách an toàn (minDistance).
    /// </summary>
    Proximity,

    /// <summary>
    /// Xảy ra khi hai robot di chuyển qua một hành lang hẹp (thường được biểu diễn bằng một chuỗi cạnh hoặc node) 
    /// theo hướng ngược nhau, dẫn đến tình trạng không thể vượt qua nhau.
    /// </summary>
    Corridor,

    /// <summary>
    /// Xảy ra khi hai robot có lộ trình giao nhau về mặt thời gian, nhưng không nhất thiết ở cùng một cạnh hoặc nút, 
    /// mà ở các vị trí khiến chúng không thể di chuyển tiếp mà không va chạm.
    /// </summary>
    Temporal,

    /// <summary>
    /// Xảy ra khi hai robot cần xoay tại một điểm (thường là node) và không gian xoay bị chồng lấn, 
    /// dẫn đến va chạm hoặc cản trở.
    /// </summary>
    Rotation,

    /// <summary>
    /// Xảy ra khi các robot cạnh tranh cho một tài nguyên chung (ví dụ: một khu vực làm việc, điểm sạc, hoặc thiết bị nng)
    /// </summary>
    Resource,

    /// <summary>
    /// Xảy ra lỗi khi kiểm tra xung đột
    /// </summary>
    None
}

public enum ConflictSeverity
{
    Low,      // Có thể giải quyết bằng cách đợi
    Medium,   // Cần điều chỉnh route
    High      // Cần route lại hoàn toàn
}

public class ConflictResolution
{
    public ResolutionStrategy Strategy { get; set; }
    public string ActionRobotId { get; set; }  // Robot cần thực hiện action
    public ResolutionAction Action { get; set; }
    public DateTime? WaitUntil { get; set; }    // Nếu action là Wait
    public RobotRoute? NewRoute { get; set; }    // Nếu action là Reroute
}

public enum ResolutionStrategy
{
    WaitAtNode,      // Robot đợi tại node (chỉ có thể thêm wait node vào Horizon, KHÔNG thể thêm vào Base)
    Reroute          // Robot route lại (chỉ có thể reroute Horizon, KHÔNG thể reroute Base)
}

public enum ResolutionAction
{
    Wait,             // Đợi tại node (thêm wait node vào Horizon)
    Reroute           // Route lại (tính toán route mới cho Horizon)
}
```

**Lưu ý quan trọng:**
- **KHÔNG can thiệp vào Speed của robot**
- **Base đã gửi xuống robot KHÔNG được phép can thiệp thêm** (không thể thêm WaitAtNode vào Base)
- Chỉ can thiệp vào **Horizon** (phần chưa release):
  - **WaitAtNode**: Thêm wait node vào Horizon, robot sẽ đợi tại node đó khi đến phần Horizon
  - **Reroute**: Tính toán route mới và cập nhật Horizon
- **Base phải được tính toán an toàn ngay từ đầu** để đảm bảo không có conflict (vì không thể chỉnh sửa sau)
```

### 4. Robot Priority / Hệ thống Ưu tiên

```csharp
public class RobotPriority
{
    public string RobotId { get; set; }
    public int PriorityLevel { get; set; }  // Số càng cao, ưu tiên càng cao
    public PriorityReason Reason { get; set; }
    public DateTime? ValidUntil { get; set; }  // Ưu tiên có thời hạn
}

public enum PriorityReason
{
    Emergency,        // Tình huống khẩn cấp
    HighValueOrder,   // Order có giá trị cao
    TimeCritical,     // Yêu cầu thời gian nghiêm ngặt
    ManualOverride,   // Người dùng chỉ định
    Default           // Mặc định
}
```

### 5. Robot Information / Thông tin Robot

**Thông tin robot cần thiết cho Conflict Detection:**

```csharp
public class RobotInfo
{
    public string RobotId { get; set; }
    
    // Physical dimensions (từ RobotModel)
    public double Length { get; set; }           // Chiều dài robot (m)
    public double Width { get; set; }            // Chiều rộng robot (m)
    
    // Navigation point (từ RobotModel)
    public double NavigationPointX { get; set; }  // Offset X của navigation point (m)
    public double NavigationPointY { get; set; }  // Offset Y của navigation point (m)
    
    // Current state (từ State message)
    public double CurrentX { get; set; }        // Vị trí X hiện tại
    public double CurrentY { get; set; }        // Vị trí Y hiện tại
    public double CurrentTheta { get; set; }    // Góc orientation hiện tại
    public string LastNodeId { get; set; }      // Node cuối cùng đã đi qua
}
```

**Sử dụng:**
- **Rotation Conflict**: Cần `Length`, `Width`, `NavigationPointX`, `NavigationPointY` để tính không gian xoay
- **Corridor Conflict**: Cần `Width` để xác định hành lang có đủ rộng cho 2 robot không
- **Proximity Conflict**: Có thể cần `Length`, `Width` để tính khoảng cách an toàn chính xác hơn

---

## Core Components / Các Thành phần Chính

### 1. ITrafficControlService Interface

```csharp
public interface ITrafficControlService
{
    // Route Planning
    Task<RobotRoute?> PlanRouteAsync(
        string robotId, 
        Guid startNodeId, 
        Guid goalNodeId, 
        CancellationToken cancellationToken = default);
    
    // Conflict Detection
    Task<List<Conflict>> DetectConflictsAsync(CancellationToken cancellationToken = default);
    
    // Conflict Resolution
    Task<bool> ResolveConflictAsync(Conflict conflict, CancellationToken cancellationToken = default);
    
    // Base/Horizon Management
    Task<bool> ReleaseHorizonSegmentAsync(
        string robotId, 
        int segmentCount, 
        CancellationToken cancellationToken = default);
    
    // Route Updates
    Task<bool> UpdateRobotRouteAsync(
        string robotId, 
        RobotRoute newRoute, 
        CancellationToken cancellationToken = default);
    
    // Monitoring
    Task<Dictionary<string, RobotRoute>> GetAllActiveRoutesAsync();
    Task<RobotRoute?> GetRobotRouteAsync(string robotId);
}
```

### 2. Route Planning / Tính toán Tuyến đường

**Workflow:**
1. Nhận yêu cầu: `robotId`, `startNodeId`, `goalNodeId`
2. Lấy current position của robot từ RobotManager
3. Sử dụng `IPathPlanner` (A*) để tính route
4. Chuyển đổi kết quả A* thành `RobotRoute` với nodes và edges
5. **Tính toán Base an toàn:**
   - Kiểm tra conflicts với tất cả routes hiện tại
   - Tính toán Base size sao cho Base không có conflict
   - Nếu có conflict trong Base → điều chỉnh Base size hoặc route lại
6. Chia route thành Base (an toàn, không có conflict) và Horizon (phần còn lại)
7. Reserve edges cho Base
8. Lưu route vào in-memory storage

**Quan trọng:**
- **Base phải được tính toán để đảm bảo không có conflict** (vì Base đã gửi xuống robot không thể chỉnh sửa)
- **Chỉ Horizon mới được phép chỉnh sửa** khi có conflict

**Implementation:**
```csharp
public async Task<RobotRoute?> PlanRouteAsync(
    string robotId, 
    Guid startNodeId, 
    Guid goalNodeId, 
    CancellationToken cancellationToken = default)
{
    // 1. Get robot current state
    var robotController = _robotManager.GetRobotController(robotId);
    if (robotController == null) return null;
    
    var currentState = robotController.RobotData.State;
    if (currentState == null) return null;
    
    // 2. Get graph data from MapManager
    var nodes = await _mapService.GetNodesAsync(levelId);
    var edges = await _mapService.GetEdgesAsync(levelId);
    
    // 3. Setup path planner
    _pathPlanner.SetData(nodes, edges);
    
    // 4. Calculate path
    var (pathNodes, pathEdges) = _pathPlanner.PathPlanning(
        startNodeId, 
        currentState.AgvPosition.Theta, 
        goalNodeId, 
        cancellationToken);
    
    // 5. Convert to RobotRoute
    var route = ConvertToRobotRoute(robotId, pathNodes, pathEdges);
    
    // 6. Calculate Base size based on traffic and conflicts
    var baseSize = await CalculateSafeBaseSizeAsync(route, robotId, cancellationToken);
    
    // 7. Split into Base and Horizon
    SplitRouteIntoBaseAndHorizon(route, baseSize);
    
    // 8. Verify Base has no conflicts (critical - Base cannot be modified after sending)
    var baseConflicts = await CheckConflictsForBaseAsync(route.Base, robotId, cancellationToken);
    if (baseConflicts.Count > 0)
    {
        // Base has conflicts - need to reduce Base size or reroute
        // Try reducing Base size
        baseSize = Math.Max(1, baseSize - 1);
        SplitRouteIntoBaseAndHorizon(route, baseSize);
        
        // Check again
        baseConflicts = await CheckConflictsForBaseAsync(route.Base, robotId, cancellationToken);
        if (baseConflicts.Count > 0)
        {
            // Still has conflicts - need to reroute
            // This is a complex case - may need to wait or find alternative route
            _logger.LogWarning($"Cannot find conflict-free Base for robot {robotId}. Conflicts: {baseConflicts.Count}");
            return null; // Or implement retry with different route
        }
    }
    
    // 9. Reserve edges for Base
    await ReserveEdgesAsync(route.Base, robotId, cancellationToken);
    
    // 10. Store route
    _activeRoutes[robotId] = route;
    
    return route;
}

/// <summary>
/// Tính toán kích thước Base an toàn dựa trên traffic hiện tại
/// Base phải đảm bảo không có conflict vì không thể chỉnh sửa sau khi gửi xuống robot
/// </summary>
private async Task<int> CalculateSafeBaseSizeAsync(
    RobotRoute route, 
    string robotId, 
    CancellationToken cancellationToken)
{
    var activeRoutes = GetAllActiveRoutes()
        .Where(r => r.RobotId != robotId)
        .ToList();
    
    if (activeRoutes.Count == 0)
    {
        // No other robots - can use default base size
        return 2; // Default: 2 segments
    }
    
    // Start with default base size
    int baseSize = 2;
    int maxBaseSize = route.FullRoute.Count - 1; // At least 1 segment in Horizon
    
    // Check conflicts for increasing base sizes
    for (int size = 2; size <= maxBaseSize; size++)
    {
        var testBase = route.FullRoute.Take(size).ToList();
        var conflicts = await CheckConflictsForSegmentsAsync(testBase, robotId, activeRoutes, cancellationToken);
        
        if (conflicts.Count == 0)
        {
            // No conflicts - can use this size
            baseSize = size;
        }
        else
        {
            // Has conflicts - stop here, use previous safe size
            break;
        }
    }
    
    return baseSize;
}
```

### 3. Conflict Detection / Phát hiện Xung đột

**Các loại xung đột cần phát hiện:**

#### 3.1. Confrontation (Đối đầu)
- **Điều kiện**: 2 robot sử dụng cùng edge trong thời gian trùng lặp, và lộ trình tiếp theo chồng lấn
- **Phát hiện**: 
  - Cùng edge (có thể EdgeAB và EdgeBA - ngược chiều)
  - Thời gian sử dụng edge trùng lặp
  - Lộ trình tiếp theo (next edges/nodes) có giao nhau
- **Ví dụ**: Robot A đi EdgeAB (A→B), Robot B đi EdgeBA (B→A), và cả 2 đều cần đi tiếp đến cùng node C

#### 3.2. Edge Conflict (Xung đột Edge)
- **Điều kiện**: 2 robot sử dụng cùng edge trong thời gian trùng lặp, nhưng lộ trình tiếp theo không chồng lấn
- **Phát hiện**: 
  - Cùng edge, thời gian trùng lặp
  - Lộ trình tiếp theo không giao nhau
- **Ví dụ**: Robot A và B cùng đi EdgeAB, nhưng A đi tiếp đến node C, B đi tiếp đến node D

#### 3.3. Vertex Conflict (Xung đột Node)
- **Điều kiện**: 2 robot chiếm cùng node tại cùng thời điểm hoặc trong khoảng thời gian trùng lặp
- **Phát hiện**: 
  - Cùng target node
  - Thời gian đến gần nhau (trong threshold)
- **Ví dụ**: Robot A và B cùng cần đến node C trong khoảng thời gian 5 giy

#### 3.4. Proximity Conflict (Xung đột Khoảng cách)
- **Điều kiện**: 2 robot quá gần nhau trong không gian liên tục, vi phạm khoảng cách an toàn
- **Phát hiện**: 
  - Tính khoảng cách Euclidean giữa 2 robot
  - So sánh với `minDistance` (khoảng cách an toàn tối thiểu)
- **Ví dụ**: Robot A ở (10, 20), Robot B ở (10.5, 20.3), khoảng cách < minDistance (ví dụ: 1m)

#### 3.5. Corridor Conflict (Xung đột Hành lang)
- **Điều kiện**: 2 robot di chuyển qua hành lang hẹp (chuỗi edges/nodes) theo hướng ngược nhau
- **Phát hiện**: 
  - Xác định hành lang (narrow passage - chuỗi edges hẹp)
  - Robot đi ngược chiều trong hành lang
  - Không thể vượt qua nhau
- **Thông tin robot cần thiết**: 
  - **Có thể cần**: Chiều rộng robot (width) để xác định hành lang có đủ rộng cho 2 robot không
  - **Có thể cần**: Chiều dài robot (length) để tính toán không gian cần thiết
  - **Có thể cần**: Kích thước hành lang (edge width) từ map data
- **Ví dụ**: Robot A đi A→B→C→D, Robot B đi D→C→B→A trong hành lang hẹp

#### 3.6. Temporal Conflict (Xung đột Thời gian)
- **Điều kiện**: Lộ trình giao nhau về mặt thời gian, nhưng không ở cùng edge/node
- **Phát hiện**: 
  - Tính toán thời gian robot sẽ ở các vị trí khác nhau
  - Phát hiện giao điểm thời gian trong không gian liên tục
- **Ví dụ**: Robot A sẽ ở vị trí (10, 20) lúc 10:00:05, Robot B sẽ ở vị trí (10.2, 20.1) lúc 10:00:05

#### 3.7. Rotation Conflict (Xung đột Xoay)
- **Điều kiện**: 2 robot cần xoay tại cùng node và không gian xoay bị chồng lấn
- **Phát hiện**: 
  - Cùng node
  - Cả 2 cần xoay (thay đổi orientation)
  - Không gian xoay (rotation space) bị chồng lấn
- **Thông tin robot cần thiết**: 
  - **Cần**: Chiều dài robot (length) - để tính bán kính xoay
  - **Cần**: Chiều rộng robot (width) - để tính không gian xoay
  - **Cần**: Góc xoay cần thiết (rotation angle) - từ route segments
  - **Có thể cần**: Navigation point offset (navigationPointX, navigationPointY) - điểm xoay của robot
- **Ví dụ**: Robot A cần xoay 90° tại node C, Robot B cần xoay 180° tại node C, không gian xoay chồng lấn

#### 3.8. Resource Conflict (Xung đột Tài nguyên)
- **Điều kiện**: Các robot cạnh tranh cho tài nguyên chung (khu vực làm việc, điểm sạc, thiết bị nng)
- **Phát hiện**: 
  - Xác định resource nodes (nodes có tài nguyên)
  - Nhiều robot cần sử dụng cùng resource trong thời gian trùng lặp
- **Ví dụ**: Robot A và B cùng cần sử dụng charging station tại node X

**Edge Direction Detection:**
- Sử dụng `StartNodeId` và `EndNodeId` từ Edge entity
- EdgeAB = Edge có StartNodeId = A, EndNodeId = B
- EdgeBA = Edge có StartNodeId = B, EndNodeId = A
- Xác định direction của robot dựa trên route segments và current position

**Implementation:**
```csharp
public async Task<List<Conflict>> DetectConflictsAsync(CancellationToken cancellationToken = default)
{
    var conflicts = new List<Conflict>();
    var activeRoutes = GetAllActiveRoutes();
    var robotStates = GetAllRobotStates();  // Lấy từ RobotManager
    
    // Check all pairs of robots
    for (int i = 0; i < activeRoutes.Count; i++)
    {
        for (int j = i + 1; j < activeRoutes.Count; j++)
        {
            var route1 = activeRoutes[i];
            var route2 = activeRoutes[j];
            var state1 = robotStates[route1.RobotId];
            var state2 = robotStates[route2.RobotId];
            
            // Check Confrontation
            var confrontation = DetectConfrontation(route1, route2, state1, state2);
            if (confrontation != null) conflicts.Add(confrontation);
            
            // Check Edge conflict
            var edgeConflict = DetectEdgeConflict(route1, route2, state1, state2);
            if (edgeConflict != null) conflicts.Add(edgeConflict);
            
            // Check Vertex conflict
            var vertexConflict = DetectVertexConflict(route1, route2, state1, state2);
            if (vertexConflict != null) conflicts.Add(vertexConflict);
            
            // Check Proximity conflict
            var proximityConflict = DetectProximityConflict(route1, route2, state1, state2);
            if (proximityConflict != null) conflicts.Add(proximityConflict);
            
            // Check Corridor conflict
            var corridorConflict = DetectCorridorConflict(route1, route2, state1, state2);
            if (corridorConflict != null) conflicts.Add(corridorConflict);
            
            // Check Temporal conflict
            var temporalConflict = DetectTemporalConflict(route1, route2, state1, state2);
            if (temporalConflict != null) conflicts.Add(temporalConflict);
            
            // Check Rotation conflict
            var rotationConflict = DetectRotationConflict(route1, route2, state1, state2);
            if (rotationConflict != null) conflicts.Add(rotationConflict);
            
            // Check Resource conflict
            var resourceConflict = DetectResourceConflict(route1, route2, state1, state2);
            if (resourceConflict != null) conflicts.Add(resourceConflict);
        }
    }
    
    // Evaluate conflicts for resolution optimization
    EvaluateConflictsForResolution(conflicts);
    
    return conflicts;
}

private void EvaluateConflictsForResolution(List<Conflict> conflicts)
{
    foreach (var conflict in conflicts)
    {
        // Simulate resolution và đếm số conflict mới phát sinh
        conflict.EstimatedNewConflicts = SimulateResolutionImpact(conflict);
        
        // Tìm các conflict khác có thể được giải quyết khi giải quyết conflict này
        conflict.CanResolveConflicts = FindResolvableConflicts(conflict, conflicts);
    }
}

/// <summary>
/// Simulate resolution của conflict và đếm số conflict mới có thể phát sinh
/// </summary>
private int SimulateResolutionImpact(Conflict conflict)
{
    var newConflicts = 0;
    
    // Determine resolution action
    var resolution = DetermineResolutionStrategy(conflict);
    
    // Simulate resolution
    if (resolution.Strategy == ResolutionStrategy.Reroute)
    {
        // Simulate reroute cho action robot
        var newRoute = SimulateReroute(conflict.ActionRobotId, conflict);
        
        // Check conflicts với route mới
        var otherRoutes = GetAllActiveRoutes()
            .Where(r => r.RobotId != conflict.ActionRobotId)
            .ToList();
        
        foreach (var otherRoute in otherRoutes)
        {
            // Check các loại conflict với route mới
            if (WouldCauseConfrontation(newRoute, otherRoute))
                newConflicts++;
            if (WouldCauseEdgeConflict(newRoute, otherRoute))
                newConflicts++;
            if (WouldCauseVertexConflict(newRoute, otherRoute))
                newConflicts++;
            // ... check các loại conflict khác
        }
    }
    else if (resolution.Strategy == ResolutionStrategy.WaitAtNode)
    {
        // Wait thường không gây conflict mới, nhưng có thể delay và gây conflict với robot khác
        var waitTime = EstimateWaitTime(conflict);
        // Check nếu wait time gây conflict với robot khác
        newConflicts = CheckWaitTimeConflicts(conflict.ActionRobotId, waitTime);
    }
    
    return newConflicts;
}

/// <summary>
/// Tìm các conflict khác có thể được giải quyết khi giải quyết conflict này
/// </summary>
private List<string> FindResolvableConflicts(Conflict conflict, List<Conflict> allConflicts)
{
    var resolvableConflicts = new List<string>();
    
    // Nếu conflict này liên quan đến robot A và B
    // Và có conflict khác cũng liên quan đến A hoặc B
    // Thì giải quyết conflict này có thể giải quyết conflict kia
    
    foreach (var otherConflict in allConflicts)
    {
        if (otherConflict == conflict) continue;
        
        // Check nếu conflict này và otherConflict có robot chung
        var commonRobots = conflict.InvolvedRobots
            .Intersect(otherConflict.InvolvedRobots)
            .ToList();
        
        if (commonRobots.Count > 0)
        {
            // Simulate: Nếu giải quyết conflict này, otherConflict có còn tồn tại không?
            if (WouldResolveOtherConflict(conflict, otherConflict))
            {
                resolvableConflicts.Add(GetConflictKey(otherConflict));
            }
        }
    }
    
    return resolvableConflicts;
}
```

### 4. Conflict Resolution / Giải quyết Xung đột

**Conflict Resolution Optimization / Tối ưu hóa Giải quyết Xung đột:**

Hệ thống cần phải **chọn conflict nào giải quyết** để:
1. **Gây ra ít xung đột tiếp theo nhất** (`EstimatedNewConflicts` thấp)
2. **Giúp giải quyết các xung đột khác** (`CanResolveConflicts.Count` cao)

**Quy trình:**
1. Phát hiện tất cả conflicts
2. Với mỗi conflict, simulate resolution và đánh giá:
   - Số conflict mới có thể phát sinh
   - Các conflict khác có thể được giải quyết
3. Sắp xếp conflicts theo priority:
   - Ưu tiên 1: `CanResolveConflicts.Count` cao (giải quyết được nhiều conflict khác)
   - Ưu tiên 2: `EstimatedNewConflicts` thấp (gây ra ít conflict mới)
   - Ưu tiên 3: `Severity` cao (High > Medium > Low)
   - Ưu tiên 4: Robot có priority cao hơn
4. Giải quyết conflicts theo thứ tự đã sắp xếp
5. Skip conflicts đã được giải quyết bởi conflict trước đó

**Chiến lược giải quyết tùy theo loại xung đột:**

#### 4.1. Confrontation (Đối đầu)
- **Strategy**: 
  - Kiểm tra priority của các robot
  - Robot có priority cao hơn được ưu tiên
  - Nếu cùng priority, robot gần node hơn được ưu tiên
- **Action**: 
  - Robot ưu tiên thấp hơn: **Reroute** (route lại để tránh)
  - Hoặc **WaitAtNode** nếu reroute không khả thi

#### 4.2. Edge Conflict (Xung đột Edge)
- **Strategy**: 
  - Vì lộ trình tiếp theo không chồng lấn, có thể cho phép cùng sử dụng edge
  - Nếu cần thiết, robot sau đợi tại node trước edge
- **Action**: 
  - **WaitAtNode** (robot sau đợi tại node trước edge để tránh trùng lặp thời gian)
  - Hoặc **Reroute** nếu wait quá lu

#### 4.3. Vertex Conflict (Xung đột Node)
- **Strategy**: 
  - First-come-first-served hoặc priority
  - Robot đến trước hoặc có priority cao hơn được ưu tiên
- **Action**: 
  - Robot đến sau: **WaitAtNode** (đợi tại node trước đó)
  - Hoặc **Reroute** nếu wait quá lu

#### 4.4. Proximity Conflict (Xung đột Khoảng cách)
- **Strategy**: 
  - Một robot đợi tại node gần nhất
  - Robot có priority cao hơn tiếp tục
- **Action**: 
  - Robot ưu tiên thấp: **WaitAtNode** (đợi tại node gần nhất)
  - Hoặc **Reroute** nếu wait quá lu

#### 4.5. Corridor Conflict (Xung đột Hành lang)
- **Strategy**: 
  - Một robot phải route lại để tránh hành lang
  - Hoặc đợi robot kia đi qua hết hành lang
- **Action**: 
  - **Reroute** (route lại để tránh hành lang)
  - Hoặc **WaitAtNode** (đợi tại đầu hành lang)

#### 4.6. Temporal Conflict (Xung đột Thời gian)
- **Strategy**: 
  - Điều chỉnh timing của một robot bằng cách delay
- **Action**: 
  - **WaitAtNode** (delay tại node để tránh giao điểm thời gian)
  - Hoặc **Reroute** nếu delay quá lu

#### 4.7. Rotation Conflict (Xung đột Xoay)
- **Strategy**: 
  - Một robot đợi robot kia xoay xong
  - Hoặc route lại để tránh node xoay
- **Action**: 
  - **WaitAtNode** (đợi tại node trước khi xoay)
  - Hoặc **Reroute** (route lại để tránh node)

#### 4.8. Resource Conflict (Xung đột Tài nguyên)
- **Strategy**: 
  - First-come-first-served hoặc priority
  - Robot đến trước hoặc có priority cao hơn được sử dụng resource
- **Action**: 
  - Robot đến sau: **WaitAtNode** (đợi tại node trước resource)
  - Hoặc **Reroute** nếu có resource thay thế

**Quyết định Wait vs Reroute:**
- **WaitAtNode**: 
  - **CHỈ có thể thêm wait node vào Horizon** (KHÔNG thể thêm vào Base)
  - Thêm wait node vào Horizon của robot
  - Robot sẽ đợi tại node đó khi đến phần Horizon
  - Sử dụng khi conflict có thể giải quyết nhanh (thời gian đợi < threshold)
  - Cập nhật Horizon bằng cách thêm wait node segment
- **Reroute**: 
  - **CHỈ có thể reroute Horizon** (KHÔNG thể reroute Base)
  - Tính toán route mới từ vị trí hiện tại (hoặc từ node cuối của Base) đến goal
  - Cập nhật Horizon với route mới
  - Sử dụng khi đợi quá lu hoặc không khả thi, hoặc reroute sẽ hiệu quả hơn
  - Base được giữ nguyên, chỉ Horizon được cập nhật

**Lưu ý quan trọng:**
- **KHÔNG can thiệp vào Speed của robot**
- **Base đã gửi xuống robot KHÔNG được phép can thiệp thêm**
- Chỉ can thiệp vào **Horizon** (phần chưa release) thông qua:
  - Thêm wait node vào Horizon (WaitAtNode)
  - Tính toán và cập nhật route mới cho Horizon (Reroute)
- **Base phải được tính toán an toàn ngay từ đầu** để đảm bảo không có conflict

**Conflict Resolution Optimization:**
- Trước khi giải quyết conflict, đánh giá tác động:
  - Số conflict mới có thể phát sinh (`EstimatedNewConflicts`)
  - Các conflict khác có thể được giải quyết (`CanResolveConflicts`)
- Ưu tiên giải quyết conflict:
  1. Có thể giải quyết nhiều conflict khác (`CanResolveConflicts.Count` cao)
  2. Gây ra ít conflict mới (`EstimatedNewConflicts` thấp)
  3. Có severity cao (High > Medium > Low)
  4. Có priority cao (robot có priority cao hơn)

**Implementation:**
```csharp
public async Task<bool> ResolveConflictsAsync(List<Conflict> conflicts, CancellationToken cancellationToken = default)
{
    if (conflicts.Count == 0) return true;
    
    // Sort conflicts by resolution priority
    var sortedConflicts = conflicts
        .OrderByDescending(c => c.CanResolveConflicts.Count)  // Giải quyết được nhiều conflict khác
        .ThenBy(c => c.EstimatedNewConflicts)                 // Gây ra ít conflict mới
        .ThenByDescending(c => c.Severity)                    // Severity cao
        .ToList();
    
    var resolvedConflicts = new HashSet<string>();
    
    foreach (var conflict in sortedConflicts)
    {
        // Skip nếu đã được giải quyết bởi conflict trước đó
        if (resolvedConflicts.Contains(GetConflictKey(conflict)))
            continue;
        
        // Resolve conflict
        var success = await ResolveConflictAsync(conflict, cancellationToken);
        
        if (success)
        {
            resolvedConflicts.Add(GetConflictKey(conflict));
            
            // Mark các conflict được giải quyết
            foreach (var resolvedKey in conflict.CanResolveConflicts)
            {
                resolvedConflicts.Add(resolvedKey);
            }
        }
    }
    
    return true;
}

public async Task<bool> ResolveConflictAsync(Conflict conflict, CancellationToken cancellationToken = default)
{
    // Determine resolution strategy based on conflict type
    var strategy = DetermineResolutionStrategy(conflict);
    
    switch (strategy.Strategy)
    {
        case ResolutionStrategy.WaitAtNode:
            return await ResolveByWaitAtNodeAsync(conflict, strategy, cancellationToken);
        
        case ResolutionStrategy.Reroute:
            return await ResolveByRerouteAsync(conflict, strategy, cancellationToken);
        
        default:
            return false;
    }
}

private ResolutionStrategy DetermineResolutionStrategy(Conflict conflict)
{
    // Determine which robot should take action
    var actionRobot = DetermineActionRobot(conflict);
    
    // Determine action based on conflict type
    ResolutionAction action;
    switch (conflict.Type)
    {
        case ConflictType.Confrontation:
            // Reroute nếu có thể, nếu không thì wait
            action = CanRerouteQuickly(conflict, actionRobot) 
                ? ResolutionAction.Reroute 
                : ResolutionAction.Wait;
            break;
        
        case ConflictType.Edge:
            // Wait tại node trước edge
            action = ResolutionAction.Wait;
            break;
        
        case ConflictType.Vertex:
        case ConflictType.Resource:
            // Wait at node
            action = ResolutionAction.Wait;
            break;
        
        case ConflictType.Proximity:
            // Wait tại node gần nhất
            action = ResolutionAction.Wait;
            break;
        
        case ConflictType.Corridor:
            // Reroute để tránh hành lang
            action = ResolutionAction.Reroute;
            break;
        
        case ConflictType.Temporal:
            // Wait tại node để delay
            action = ResolutionAction.Wait;
            break;
        
        case ConflictType.Rotation:
            // Wait tại node trước khi xoay
            action = ResolutionAction.Wait;
            break;
        
        default:
            action = ResolutionAction.Wait;
            break;
    }
    
    return new ResolutionStrategy
    {
        Strategy = action == ResolutionAction.Reroute 
            ? ResolutionStrategy.Reroute 
            : ResolutionStrategy.WaitAtNode,
        ActionRobotId = actionRobot,
        Action = action
    };
}

private string DetermineActionRobot(Conflict conflict)
{
    // Check priority first
    var robot1 = conflict.InvolvedRobots[0];
    var robot2 = conflict.InvolvedRobots[1];
    
    var priority1 = GetRobotPriority(robot1);
    var priority2 = GetRobotPriority(robot2);
    
    if (priority1.PriorityLevel > priority2.PriorityLevel)
        return robot2;  // Robot có priority thấp hơn phải action
    
    if (priority2.PriorityLevel > priority1.PriorityLevel)
        return robot1;
    
    // Same priority, check distance to conflict point
    var route1 = GetRobotRoute(robot1);
    var route2 = GetRobotRoute(robot2);
    
    var distance1 = CalculateDistanceToConflictPoint(route1, conflict);
    var distance2 = CalculateDistanceToConflictPoint(route2, conflict);
    
    return distance1 < distance2 ? robot2 : robot1;  // Robot xa hơn phải action
}
```

### 5. Base/Horizon Management / Quản lý Base và Horizon

**Concept:**
- **Base**: Phần order đã release, robot đang thực hiện
- **Horizon**: Phần order chưa release, đang chờ điều kiện

**Release Logic:**
1. Monitor robot progress (từ State messages)
2. Khi robot gần hoàn thành Base (còn 1-2 segments)
3. Check conflicts cho phần Horizon tiếp theo
4. Nếu không có conflict → Release thêm segments vào Base
5. Gửi OrderUpdate với `orderUpdateId++`

**WaitAtNode Implementation:**
- Khi cần robot đợi tại node:
  1. Xác định node hiện tại của robot (từ State message)
  2. Kiểm tra robot đang ở Base hay Horizon:
     - **Nếu đang ở Base**: KHÔNG thể thêm wait node (Base không được phép chỉnh sửa)
     - **Nếu đang ở Horizon**: Có thể thêm wait node vào Horizon
  3. Tạo wait node segment với thời gian đợi
  4. **Thêm wait node vào Horizon** (chèn vào Horizon trước segments tiếp theo)
  5. Gửi OrderUpdate với wait node mới trong Horizon
  6. Robot sẽ đợi tại node đó khi đến phần Horizon

**Reroute Implementation:**
- Khi cần robot route lại:
  1. Xác định vị trí hiện tại của robot (từ State message)
  2. Kiểm tra robot đang ở Base hay Horizon:
     - **Nếu đang ở Base**: KHÔNG thể reroute Base (Base không được phép chỉnh sửa)
     - **Nếu đang ở Horizon**: Có thể reroute Horizon
  3. Xác định điểm bắt đầu reroute:
     - Nếu robot chưa đi vào Base: Từ vị trí hiện tại
     - Nếu robot đã đi vào Base: Từ node cuối của Base
  4. Tính toán route mới từ điểm bắt đầu đến goal
  5. **Cập nhật Horizon với route mới** (Base được giữ nguyên)
  6. Gửi OrderUpdate với Horizon mới
  7. Robot sẽ tiếp tục với route mới khi đến phần Horizon

**Implementation:**
```csharp
public async Task<bool> ReleaseHorizonSegmentAsync(
    string robotId, 
    int segmentCount, 
    CancellationToken cancellationToken = default)
{
    var route = GetRobotRoute(robotId);
    if (route == null || route.Horizon.Count == 0) return false;
    
    // Get next segments from horizon
    var segmentsToRelease = route.Horizon.Take(segmentCount).ToList();
    
    // Check conflicts
    var conflicts = await CheckConflictsForSegmentsAsync(segmentsToRelease, robotId, cancellationToken);
    if (conflicts.Count > 0)
    {
        // Có conflict, chưa release được
        return false;
    }
    
    // Reserve edges
    await ReserveEdgesAsync(segmentsToRelease, robotId, cancellationToken);
    
    // Move from horizon to base
    route.Base.AddRange(segmentsToRelease);
    route.Horizon.RemoveRange(0, segmentCount);
    
    // Send OrderUpdate
    await SendOrderUpdateAsync(robotId, segmentsToRelease, cancellationToken);
    
    return true;
}
```

### 6. OrderUpdate Generation / Tạo OrderUpdate

**VDA5050 OrderUpdate:**
- Giữ nguyên `orderId`
- Tăng `orderUpdateId`
- Thêm nodes/edges mới vào order
- Set `released = true` cho segments mới

**Implementation:**
```csharp
private async Task<bool> SendOrderUpdateAsync(
    string robotId, 
    List<RouteSegment> newSegments, 
    CancellationToken cancellationToken = default)
{
    var robotController = _robotManager.GetRobotController(robotId);
    if (robotController == null) return false;
    
    var currentOrder = robotController.RobotData.Order;
    if (currentOrder == null) return false;
    
    // Create OrderUpdate
    var orderUpdate = new OrderMsg
    {
        OrderId = currentOrder.OrderId,
        OrderUpdateId = currentOrder.OrderUpdateId + 1,
        // ... copy other fields from currentOrder
    };
    
    // Add new nodes and edges
    foreach (var segment in newSegments)
    {
        // Add node
        orderUpdate.Nodes = orderUpdate.Nodes
            .Concat(new[] { CreateNodeFromSegment(segment) })
            .ToArray();
        
        // Add edge if exists
        if (segment.EdgeId.HasValue)
        {
            orderUpdate.Edges = orderUpdate.Edges
                .Concat(new[] { CreateEdgeFromSegment(segment) })
                .ToArray();
        }
    }
    
    // Send via RobotController
    return await robotController.SendOrderAsync(orderUpdate, cancellationToken);
}
```

---

## Real-time Conflict Detection Loop / Vòng lặp Phát hiện Xung đột

**Background Service:**
```csharp
public class TrafficControlService : BackgroundService, ITrafficControlService
{
    private readonly PeriodicTimer _conflictDetectionTimer;
    private const int DetectionIntervalMs = 500; // 2 Hz
    
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (await _conflictDetectionTimer.WaitForNextTickAsync(stoppingToken))
        {
            try
            {
                // 1. Detect conflicts
                var conflicts = await DetectConflictsAsync(stoppingToken);
                
                // 2. Resolve conflicts
                foreach (var conflict in conflicts)
                {
                    await ResolveConflictAsync(conflict, stoppingToken);
                }
                
                // 3. Check for horizon release
                await CheckAndReleaseHorizonsAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in conflict detection loop");
            }
        }
    }
}
```

---

## 📡 Integration với VDA5050 / Tích hợp VDA5050

### 1. Order Creation Flow

```
ScriptEngine/WebUI
    → TrafficControl.PlanRouteAsync()
    → Create OrderMsg với Base segments
    → RobotController.SendOrderAsync()
    → MQTT → Robot
```

### 2. OrderUpdate Flow

```
TrafficControl (Conflict Resolution / Horizon Release)
    → Create OrderUpdate (orderUpdateId++)
    → RobotController.SendOrderAsync()
    → MQTT → Robot
    → Robot continues with extended route
```

### 3. State Monitoring

```
Robot → MQTT → RobotManager
    → Update RobotData.State
    → TrafficControl monitors state
    → Check progress, detect conflicts
```

---

## Graph Structure Support / Hỗ trợ Cấu trúc Graph

### Bidirectional Edges

**Database Structure:**
- Edge table có `StartNodeId` và `EndNodeId`
- EdgeAB = Edge có `StartNodeId = NodeA`, `EndNodeId = NodeB` (A→B)
- EdgeBA = Edge có `StartNodeId = NodeB`, `EndNodeId = NodeA` (B→A)
- Hai edges này là riêng biệt trong database (không phải 1 edge với direction)

**Path Planning:**
- A* algorithm tự động xử lý bidirectional edges
- Chọn edge phù hợp với direction của robot dựa trên `StartNodeId` và `EndNodeId`
- Khi tính route từ NodeA đến NodeB:
  - Nếu có EdgeAB → sử dụng EdgeAB
  - Nếu không có EdgeAB nhưng có EdgeBA → không thể đi trực tiếp (cần route qua nodes khác)

**Conflict Detection:**
- Xác định direction của robot dựa trên `StartNodeId` và `EndNodeId` của edge trong route
- Detect Confrontation: Robot A đi EdgeAB (A→B), Robot B đi EdgeBA (B→A) = ngược chiều
- Detect Edge conflict: Cả 2 robot cùng đi EdgeAB hoặc cùng đi EdgeBA = cùng chiều
- Không giới hạn số robot trên 1 edge, nhưng cần check conflicts về timing và proximity

---

## Configuration / Cấu hình

```json
{
  "TrafficControl": {
    "ConflictDetection": {
      "IntervalMs": 500,
      "VertexConflictThreshold": 2.0,      // meters - khoảng cách tối thiểu tại node
      "ProximityMinDistance": 1.0,          // meters - khoảng cách an toàn tối thiểu
      "TimeConflictThreshold": 5.0,         // seconds - threshold thời gian trùng lặp
      "RotationSpaceRadius": 0.5,            // meters - bán kính không gian xoay
      "CorridorWidthThreshold": 2.0         // meters - chiều rộng tối đa để coi là hành lang hẹp
    },
    "BaseHorizon": {
      "InitialBaseSegments": 2,
      "ReleaseAheadSegments": 2,
      "MinHorizonSegments": 1
    },
    "ConflictResolution": {
      "WaitTimeAtNode": 5.0,                // seconds - thời gian đợi tối đa tại node
      "RerouteOnConflict": true,            // Có cho phép reroute khi conflict không
      "MaxRerouteAttempts": 3,               // Số lần reroute tối đa cho 1 conflict
      "ResolutionOptimization": true,        // Bật tối ưu hóa giải quyết conflict
      "MaxResolutionSimulationDepth": 2      // Độ su simulation khi đánh giá resolution
    },
    "Priority": {
      "DefaultPriority": 0,                  // Priority mặc định
      "EmergencyPriority": 100,              // Priority khẩn cấp
      "HighValueOrderPriority": 50,          // Priority order giá trị cao
      "TimeCriticalPriority": 30             // Priority yêu cầu thời gian nghiêm ngặt
    }
  }
}
```

---

## Implementation Phases / Các Giai đoạn Triển khai

### Phase 1: Foundation - Data Models & Interfaces
**Mục tiêu:** Thiết lập nền tảng cơ bản với data models và interfaces

- [ ] Create data models:
  - [ ] `RobotRoute` class với Base, Horizon, FullRoute
  - [ ] `RouteSegment` class
  - [ ] `EdgeReservation` class với StartNodeId, EndNodeId
  - [ ] `Conflict` class với tất cả conflict types
  - [ ] `ConflictResolution` class
  - [ ] `RobotPriority` class
  - [ ] `RobotInfo` class (Length, Width, NavigationPoint)
- [ ] Create enums:
  - [ ] `ConflictType` (Confrontation, Edge, Vertex, Proximity, Corridor, Temporal, Rotation, Resource, None)
  - [ ] `ConflictSeverity` (Low, Medium, High)
  - [ ] `ResolutionStrategy` (WaitAtNode, Reroute)
  - [ ] `ResolutionAction` (Wait, Reroute)
  - [ ] `ReservationStatus` (Reserved, InUse, Released)
  - [ ] `PriorityReason` (Emergency, HighValueOrder, TimeCritical, ManualOverride, Default)
- [ ] Create `ITrafficControlService` interface với tất cả methods
- [ ] Create `TrafficControlService` class skeleton
- [ ] Register service in DI container (Singleton)
- [ ] Add configuration models cho TrafficControl settings

**Deliverables:**
- Data models hoàn chỉnh
- Interface và class skeleton
- Service registration

---

### Phase 2: Route Planning - Basic Path Planning
**Mục tiêu:** Tích hợp A* path planner và tính toán route cơ bản

- [ ] Integrate with `IPathPlanner` (A*)
- [ ] Implement `PlanRouteAsync()` - basic version (chưa tính Base an toàn)
- [ ] Convert A* result (GlobalNode[], GlobalEdge[]) to `RobotRoute`
- [ ] Implement route conversion:
  - [ ] Convert nodes to RouteSegments
  - [ ] Convert edges to RouteSegments
  - [ ] Set sequence IDs (even for nodes, odd for edges)
- [ ] Implement basic Base/Horizon split (fixed size, chưa check conflict)
- [ ] Test basic route planning

**Deliverables:**
- Route planning cơ bản working
- Conversion từ A* result sang RobotRoute

---

### Phase 3: Robot Information Integration
**Mục tiêu:** Tích hợp thông tin robot từ RobotModel cho conflict detection

- [ ] Create service/helper để lấy robot information:
  - [ ] Get robot Length, Width từ RobotModel
  - [ ] Get NavigationPointX, NavigationPointY từ RobotModel
  - [ ] Cache robot information để tránh query nhiều lần
- [ ] Implement `GetRobotInfoAsync(string robotId)` method
- [ ] Integrate với IRobotService hoặc IRobotModelService
- [ ] Test robot information retrieval

**Deliverables:**
- Robot information service
- Có thể lấy thông tin robot (dimensions, navigation point)

---

### Phase 4: Edge Reservation System
**Mục tiêu:** Hệ thống đặt chỗ edge để track robot usage

- [ ] Implement edge reservation data structure:
  - [ ] Dictionary<Guid, List<EdgeReservation>> để track reservations per edge
  - [ ] Thread-safe operations
- [ ] Implement `ReserveEdgesAsync()` - reserve edges cho Base
- [ ] Implement `CalculateReservationDuration()` - tính thời gian reserve dựa trên edge length và robot speed
- [ ] Implement `ReleaseReservationsAsync()` - release khi robot hoàn thành
- [ ] Implement `GetEdgeReservationsAsync()` - lấy reservations cho 1 edge
- [ ] Test edge reservation system

**Deliverables:**
- Edge reservation system hoàn chỉnh
- Track và release reservations

---

### Phase 5: Base Safety Calculation
**Mục tiêu:** Tính toán Base an toàn, không có conflict

- [ ] Implement `CalculateSafeBaseSizeAsync()`:
  - [ ] Lấy tất cả active routes
  - [ ] Check conflicts cho từng base size (từ 2 đến max)
  - [ ] Tìm base size lớn nhất không có conflict
- [ ] Implement `CheckConflictsForBaseAsync()` - check conflicts cho Base segments
- [ ] Integrate với conflict detection (sẽ implement ở phase sau, tạm thời dùng basic check)
- [ ] Update `PlanRouteAsync()` để sử dụng safe base calculation
- [ ] Handle case Base có conflict → reduce size hoặc reroute
- [ ] Test Base safety calculation

**Deliverables:**
- Base được tính toán an toàn
- Không có conflict trong Base

---

### Phase 6: Conflict Detection - Basic Conflicts
**Mục tiêu:** Phát hiện các loại conflict cơ bản (không cần robot info)

- [ ] Implement `DetectConflictsAsync()` - main method
- [ ] Implement Confrontation detection:
  - [ ] Check cùng edge, ngược chiều (EdgeAB vs EdgeBA)
  - [ ] Check lộ trình tiếp theo chồng lấn
- [ ] Implement Edge conflict detection:
  - [ ] Check cùng edge, cùng chiều
  - [ ] Check lộ trình tiếp theo không chồng lấn
- [ ] Implement Vertex conflict detection:
  - [ ] Check cùng target node
  - [ ] Check thời gian đến gần nhau
- [ ] Implement Proximity conflict detection:
  - [ ] Tính khoảng cách Euclidean
  - [ ] So sánh với minDistance
- [ ] Implement Temporal conflict detection:
  - [ ] Tính toán thời gian robot ở các vị trí
  - [ ] Phát hiện giao điểm thời gian
- [ ] Test basic conflict detection

**Deliverables:**
- 5 loại conflict detection cơ bản working

---

### Phase 7: Conflict Detection - Advanced Conflicts
**Mục tiêu:** Phát hiện các loại conflict cần thông tin robot

- [ ] Implement Corridor conflict detection:
  - [ ] Xác định hành lang hẹp (chuỗi edges/nodes)
  - [ ] Check robot width vs edge width
  - [ ] Check ngược chiều trong hành lang
- [ ] Implement Rotation conflict detection:
  - [ ] Lấy robot info (Length, Width, NavigationPoint)
  - [ ] Tính không gian xoay (rotation space)
  - [ ] Check chồng lấn không gian xoay tại cùng node
- [ ] Implement Resource conflict detection:
  - [ ] Xác định resource nodes (nodes có tài nguyên)
  - [ ] Check nhiều robot cần cùng resource
- [ ] Integrate robot information vào conflict detection
- [ ] Test advanced conflict detection

**Deliverables:**
- 3 loại conflict detection advanced working
- Tích hợp robot information

---

### Phase 8: Conflict Evaluation & Optimization
**Mục tiêu:** Đánh giá conflicts để tối ưu hóa resolution

- [ ] Implement `EvaluateConflictsForResolution()`:
  - [ ] Simulate resolution cho mỗi conflict
  - [ ] Tính `EstimatedNewConflicts` (số conflict mới có thể phát sinh)
  - [ ] Tìm `CanResolveConflicts` (conflicts khác có thể được giải quyết)
- [ ] Implement `SimulateResolutionImpact()`:
  - [ ] Simulate reroute → check conflicts mới
  - [ ] Simulate wait → check conflicts mới
- [ ] Implement `FindResolvableConflicts()`:
  - [ ] Tìm conflicts có robot chung
  - [ ] Check nếu giải quyết conflict này có giải quyết conflict kia không
- [ ] Implement conflict sorting/prioritization:
  - [ ] Sort by CanResolveConflicts.Count (descending)
  - [ ] Sort by EstimatedNewConflicts (ascending)
  - [ ] Sort by Severity (descending)
  - [ ] Sort by robot priority
- [ ] Test conflict evaluation

**Deliverables:**
- Conflict evaluation system
- Optimization logic

---

### Phase 9: Priority System
**Mục tiêu:** Hệ thống ưu tiên cho robots

- [ ] Implement priority management:
  - [ ] Set robot priority
  - [ ] Get robot priority
  - [ ] Priority levels: Emergency (100), HighValueOrder (50), TimeCritical (30), Default (0)
- [ ] Integrate priority vào conflict resolution:
  - [ ] Determine action robot dựa trên priority
  - [ ] Robot có priority cao hơn được ưu tiên
- [ ] Implement priority persistence (nếu cần)
- [ ] Test priority system

**Deliverables:**
- Priority system working
- Tích hợp vào conflict resolution

---

### Phase 10: Conflict Resolution - Strategy Determination
**Mục tiêu:** Xác định strategy giải quyết conflict (Wait vs Reroute)

- [ ] Implement `DetermineResolutionStrategy()`:
  - [ ] Determine action robot (dựa trên priority, distance)
  - [ ] Determine action (Wait vs Reroute) dựa trên conflict type
- [ ] Implement conflict type → action mapping:
  - [ ] Confrontation → Reroute (hoặc Wait nếu không khả thi)
  - [ ] Edge → Wait
  - [ ] Vertex → Wait
  - [ ] Proximity → Wait
  - [ ] Corridor → Reroute
  - [ ] Temporal → Wait
  - [ ] Rotation → Wait
  - [ ] Resource → Wait
- [ ] Implement `DetermineActionRobot()`:
  - [ ] Check priority
  - [ ] Check distance to conflict point
- [ ] Test strategy determination

**Deliverables:**
- Strategy determination working
- Action robot selection

---

### Phase 11: Conflict Resolution - WaitAtNode Implementation
**Mục tiêu:** Implement WaitAtNode resolution (chỉ vào Horizon)

- [ ] Implement `ResolveByWaitAtNodeAsync()`:
  - [ ] Check robot position (Base vs Horizon)
  - [ ] Nếu đang ở Base → return false (không thể can thiệp)
  - [ ] Nếu đang ở Horizon → thêm wait node
- [ ] Implement wait node creation:
  - [ ] Tạo wait node segment với thời gian đợi
  - [ ] Chèn vào Horizon (trước segments tiếp theo)
- [ ] Implement `CheckRobotPosition()` - xác định robot đang ở Base hay Horizon
- [ ] Update Horizon với wait node
- [ ] Generate OrderUpdate với wait node
- [ ] Test WaitAtNode resolution

**Deliverables:**
- WaitAtNode resolution working
- Chỉ can thiệp vào Horizon

---

### Phase 12: Conflict Resolution - Reroute Implementation
**Mục tiêu:** Implement Reroute resolution (chỉ reroute Horizon)

- [ ] Implement `ResolveByRerouteAsync()`:
  - [ ] Check robot position (Base vs Horizon)
  - [ ] Nếu đang ở Base → return false (không thể can thiệp)
  - [ ] Nếu đang ở Horizon → reroute
- [ ] Implement reroute logic:
  - [ ] Xác định điểm bắt đầu reroute (từ node cuối của Base hoặc vị trí hiện tại)
  - [ ] Tính toán route mới từ điểm bắt đầu đến goal
  - [ ] Cập nhật Horizon với route mới
  - [ ] Giữ nguyên Base
- [ ] Implement `CalculateRerouteStartPoint()`:
  - [ ] Nếu robot chưa đi vào Base → từ vị trí hiện tại
  - [ ] Nếu robot đã đi vào Base → từ node cuối của Base
- [ ] Generate OrderUpdate với Horizon mới
- [ ] Test Reroute resolution

**Deliverables:**
- Reroute resolution working
- Chỉ reroute Horizon, giữ nguyên Base

---

### Phase 13: Base/Horizon Management
**Mục tiêu:** Quản lý Base và Horizon, release Horizon khi an toàn

- [ ] Implement robot progress monitoring:
  - [ ] Subscribe to State messages từ RobotManager
  - [ ] Track robot position trong route (Base vs Horizon)
  - [ ] Detect khi robot gần hoàn thành Base (còn 1-2 segments)
- [ ] Implement `ReleaseHorizonSegmentAsync()`:
  - [ ] Get next segments from Horizon
  - [ ] Check conflicts cho segments
  - [ ] Nếu không có conflict → release vào Base
  - [ ] Reserve edges cho segments mới
  - [ ] Generate OrderUpdate
- [ ] Implement `CheckAndReleaseHorizonsAsync()` - check tất cả robots
- [ ] Test Base/Horizon management

**Deliverables:**
- Base/Horizon management working
- Auto-release Horizon khi an toàn

---

### Phase 14: OrderUpdate Generation
**Mục tiêu:** Tạo OrderUpdate messages theo VDA5050

- [ ] Implement `SendOrderUpdateAsync()`:
  - [ ] Get current order từ RobotController
  - [ ] Create OrderUpdate (giữ nguyên orderId, tăng orderUpdateId)
  - [ ] Add new nodes/edges vào order
  - [ ] Set released = true cho segments mới
- [ ] Implement `CreateNodeFromSegment()` - convert RouteSegment to VDA5050 Node
- [ ] Implement `CreateEdgeFromSegment()` - convert RouteSegment to VDA5050 Edge
- [ ] Implement sequence ID management (even for nodes, odd for edges)
- [ ] Send OrderUpdate via RobotController
- [ ] Test OrderUpdate generation

**Deliverables:**
- OrderUpdate generation working
- VDA5050 compliant

---

### Phase 15: Real-time Conflict Detection Loop
**Mục tiêu:** Background service để detect và resolve conflicts real-time

- [ ] Implement `TrafficControlService` as BackgroundService:
  - [ ] PeriodicTimer với interval 500ms (2 Hz)
  - [ ] Conflict detection loop
  - [ ] Conflict resolution loop
  - [ ] Horizon release check
- [ ] Implement `ExecuteAsync()`:
  - [ ] Detect conflicts
  - [ ] Resolve conflicts (với optimization)
  - [ ] Check and release horizons
  - [ ] Error handling
- [ ] Integrate với RobotManager:
  - [ ] Subscribe to robot state changes
  - [ ] Update routes khi robot progress
- [ ] Test real-time loop

**Deliverables:**
- Real-time conflict detection working
- Background service running

---

### Phase 16: Integration & Testing
**Mục tiêu:** Tích hợp toàn bộ và kiểm thử

- [ ] Integration với RobotController:
  - [ ] Test PlanRouteAsync → SendOrder
  - [ ] Test OrderUpdate → SendOrderUpdate
- [ ] Integration với MQTT:
  - [ ] Test Order messages
  - [ ] Test OrderUpdate messages
  - [ ] Test State message monitoring
- [ ] End-to-end testing:
  - [ ] Test với 2 robots (simple conflicts)
  - [ ] Test với nhiều robots (complex conflicts)
  - [ ] Test Base safety calculation
  - [ ] Test conflict resolution (Wait vs Reroute)
  - [ ] Test Horizon release
- [ ] Performance testing:
  - [ ] Test với 10+ robots
  - [ ] Test conflict detection performance
  - [ ] Test resolution optimization performance
- [ ] Edge cases testing:
  - [ ] Robot ở Base khi có conflict
  - [ ] Robot ở Horizon khi có conflict
  - [ ] Multiple conflicts cùng lúc
  - [ ] No path found scenarios
- [ ] Documentation:
  - [ ] Update API documentation
  - [ ] Update architecture documentation
  - [ ] Create user guide

**Deliverables:**
- System fully integrated
- All tests passing
- Documentation complete

---

## Service Refactoring / Tái cấu trúc Service

### Tổng quan

Sau khi implementation hoàn tất, `TrafficControlService` đã phát triển thành một file rất lớn (4221 dòng code), gây khó khăn cho việc bảo trì và mở rộng. Để cải thiện code quality và maintainability, hệ thống đã được refactor thành các service riêng biệt theo nguyên tắc **Separation of Concerns**.

### Kiến trúc mới sau Refactoring

```
TrafficControl/
├── TrafficControlService.cs (428 dòng - Orchestrator)
│   └── Điều phối các service, BackgroundService loop, Event handling
│
└── Services/
    ├── EdgeReservationService.cs (290 dòng)
    │   └── Quản lý edge reservations, kiểm tra edge availability
    │
    ├── PriorityService.cs (153 dòng)
    │   └── Quản lý robot priorities, cleanup expired priorities
    │
    ├── RobotInfoService.cs (102 dòng)
    │   └── Cache robot information từ RobotModel
    │
    ├── OrderUpdateService.cs (340 dòng)
    │   └── Generate và send OrderUpdate messages
    │
    ├── BaseHorizonManagementService.cs (475 dòng)
    │   └── Quản lý Base/Horizon segments, release horizon khi safe
    │
    ├── RouteStorageService.cs (41 dòng)
    │   └── Quản lý active routes storage (in-memory)
    │
    ├── ConflictDetectionService.cs (997 dòng)
    │   └── Detect tất cả các loại conflicts giữa robots
    │
    ├── ConflictResolutionService.cs (1140 dòng)
    │   └── Resolve conflicts (WaitAtNode, Reroute), evaluate conflicts
    │
    └── RoutePlanningService.cs (178 dòng)
        └── Route planning logic, tính toán safe base size
```

### Các Service đã được tạo

#### 1. EdgeReservationService
**Trách nhiệm:**
- Quản lý edge reservations (reserve, release, check availability)
- Tính toán reservation duration dựa trên edge length và robot speed
- Kiểm tra edge availability trong khoảng thời gian cụ thể

**Dependencies:**
- `INodeService`, `IEdgeService`
- `IRobotInfoService`
- `IServiceScopeFactory` (để get levelId)
- `Logger<EdgeReservationService>`

**Methods:**
- `ReserveEdgesAsync()` - Reserve edges cho route segments
- `ReleaseReservationsAsync()` - Release reservations cho robot/order
- `GetEdgeReservationsAsync()` - Get tất cả reservations cho một edge
- `IsEdgeAvailableAsync()` - Kiểm tra edge có available không

#### 2. PriorityService
**Trách nhiệm:**
- Quản lý robot priorities
- Map PriorityReason sang PriorityLevel
- Cleanup expired priorities

**Dependencies:**
- `Logger<PriorityService>`

**Methods:**
- `SetRobotPriorityAsync()` - Set priority cho robot
- `GetRobotPriorityAsync()` - Get priority của robot
- `RemoveRobotPriorityAsync()` - Remove priority (reset về default)
- `CleanupExpiredPriorities()` - Cleanup priorities đã hết hạn

#### 3. RobotInfoService
**Trách nhiệm:**
- Cache robot information từ RobotModel
- Get robot dimensions (length, width), navigation point
- Cache với expiry time để tránh query database liên tục

**Dependencies:**
- `IServiceScopeFactory` (để get IRobotService, IRobotModelService)
- `IRobotManagerService` (để get robot state)
- `Logger<RobotInfoService>`

**Methods:**
- `GetRobotInfoAsync()` - Get robot info (có cache)
- `ClearRobotInfoCache()` - Clear cache cho một robot
- `ClearAllRobotInfoCache()` - Clear tất cả cache

#### 4. OrderUpdateService
**Trách nhiệm:**
- Generate OrderUpdate messages từ Horizon segments
- Send OrderUpdate đến robot qua RobotController
- Tạo VDA5050 Node và Edge từ RouteSegment

**Dependencies:**
- `IRobotManagerService` (để get RobotController)
- `Logger<OrderUpdateService>`

**Methods:**
- `GenerateAndSendOrderUpdateAsync()` - Generate và send OrderUpdate từ Horizon
- `SendOrderUpdateAsync()` - Send OrderUpdate với new segments
- `SendInitialOrderAsync()` - Send initial Order (Base segments only)

#### 5. BaseHorizonManagementService
**Trách nhiệm:**
- Quản lý Base/Horizon segments
- Check robot position (Base vs Horizon)
- Release horizon segments khi safe
- Calculate safe base size

**Dependencies:**
- `IRouteStorageService`
- `IRobotManagerService`
- `IEdgeReservationService`
- `IOrderUpdateService`
- `IRobotInfoService`
- `IConflictDetectionService`
- `INodeService`, `IEdgeService`
- `IServiceScopeFactory`
- `TrafficControlConfig`

**Methods:**
- `CheckRobotPositionAsync()` - Check robot đang ở Base hay Horizon
- `ReleaseHorizonSegmentAsync()` - Release horizon segments khi safe
- `CheckAndReleaseHorizonsAsync()` - Check và release horizons cho tất cả robots
- `CalculateSafeBaseSizeAsync()` - Calculate safe base size không có conflicts
- `CountRemainingBaseSegments()` - Count remaining Base segments

#### 6. RouteStorageService
**Trách nhiệm:**
- Quản lý active routes storage (in-memory)
- Thread-safe access với lock

**Dependencies:**
- Không có (độc lập)

**Methods:**
- `GetAllActiveRoutesAsync()` - Get tất cả active routes
- `GetRobotRouteAsync()` - Get route cho một robot
- `UpdateRobotRouteAsync()` - Update route cho robot

#### 7. ConflictDetectionService
**Trách nhiệm:**
- Detect tất cả các loại conflicts giữa robots
- Check conflicts cho specific route segments

**Dependencies:**
- `IRouteStorageService`
- `IRobotManagerService`
- `INodeService`, `IEdgeService`
- `IRobotInfoService`
- `IEdgeReservationService`
- `IServiceScopeFactory`
- `TrafficControlConfig`

**Methods:**
- `DetectConflictsAsync()` - Detect tất cả conflicts
- `CheckConflictsForSegmentsAsync()` - Check conflicts cho segments cụ thể

**Conflict Types Detected:**
- Confrontation
- Edge Conflict
- Vertex Conflict
- Proximity Conflict
- Temporal Conflict
- Corridor Conflict
- Rotation Conflict
- Resource Conflict

#### 8. ConflictResolutionService
**Trách nhiệm:**
- Resolve conflicts bằng WaitAtNode hoặc Reroute
- Evaluate conflicts để tối ưu resolution order
- Simulate resolution impact

**Dependencies:**
- `IRouteStorageService`
- `IRobotManagerService`
- `IBaseHorizonManagementService`
- `IOrderUpdateService`
- `IPriorityService`
- `IConflictDetectionService`
- `IPathPlannerFactory`
- `INodeService`, `IEdgeService`
- `IServiceScopeFactory`
- `TrafficControlConfig`

**Methods:**
- `ResolveConflictAsync()` - Resolve một conflict
- `EvaluateConflictsForResolutionAsync()` - Evaluate conflicts để tối ưu

**Resolution Strategies:**
- `WaitAtNode` - Thêm wait node vào Horizon
- `Reroute` - Tính toán route mới tránh conflict

#### 9. RoutePlanningService
**Trách nhiệm:**
- Plan route từ start node đến goal node
- Sử dụng A* algorithm từ GlobalPathPlanner
- Calculate safe base size
- Reserve edges và send initial Order

**Dependencies:**
- `IRobotManagerService`
- `INodeService`, `IEdgeService`
- `IPathPlannerFactory`
- `IServiceScopeFactory`
- `IBaseHorizonManagementService`
- `IEdgeReservationService`
- `IRouteStorageService`
- `IOrderUpdateService`
- `TrafficControlConfig`

**Methods:**
- `PlanRouteAsync()` - Plan route cho robot

### TrafficControlService (Orchestrator)

Sau refactoring, `TrafficControlService` trở thành một **orchestrator** đơn giản:

**Trách nhiệm:**
- Điều phối các service
- BackgroundService loop (real-time conflict detection)
- Event handling (State message received)
- Configuration loading

**Methods (delegate đến các service):**
- `PlanRouteAsync()` → `RoutePlanningService`
- `DetectConflictsAsync()` → `ConflictDetectionService`
- `ResolveConflictAsync()` → `ConflictResolutionService`
- `ReleaseHorizonSegmentAsync()` → `BaseHorizonManagementService`
- `SetRobotPriorityAsync()` → `PriorityService`
- `ReserveEdgesAsync()` → `EdgeReservationService`
- `GetRobotInfoAsync()` → `RobotInfoService`
- Và các methods khác...

**Kết quả:**
- **Trước refactoring:** 4221 dòng code
- **Sau refactoring:** 428 dòng code (giảm ~90%)
- **Tổng code trong các service:** ~3716 dòng (tổ chức tốt hơn)

### Lợi ích của Refactoring

1. **Separation of Concerns**
   - Mỗi service có trách nhiệm rõ ràng
   - Dễ hiểu và maintain

2. **Testability**
   - Có thể test từng service độc lập
   - Mock dependencies dễ dàng hơn

3. **Reusability**
   - Các service có thể được sử dụng ở nơi khác
   - Ví dụ: `EdgeReservationService` có thể được dùng bởi các module khác

4. **Maintainability**
   - Thay đổi một service không ảnh hưởng các service khác
   - Dễ tìm và fix bugs

5. **Scalability**
   - Dễ thêm tính năng mới
   - Có thể optimize từng service riêng biệt

### Dependency Injection Setup

Tất cả services được register trong `Program.cs`:

```csharp
// Register TrafficControl Configuration
builder.Services.AddSingleton<TrafficControlConfig>(sp =>
{
    var config = sp.GetRequiredService<IConfiguration>()
        .GetSection("TrafficControl").Get<TrafficControlConfig>();
    return config ?? new TrafficControlConfig();
});

// Register TrafficControl Sub-Services (order matters due to dependencies)
builder.Services.AddSingleton<IRouteStorageService, RouteStorageService>();
builder.Services.AddSingleton<IPriorityService, PriorityService>();
builder.Services.AddSingleton<IRobotInfoService, RobotInfoService>();
builder.Services.AddSingleton<IEdgeReservationService, EdgeReservationService>();
builder.Services.AddSingleton<IOrderUpdateService, OrderUpdateService>();
builder.Services.AddSingleton<IConflictDetectionService, ConflictDetectionService>();
builder.Services.AddSingleton<IConflictResolutionService, ConflictResolutionService>();
builder.Services.AddSingleton<IBaseHorizonManagementService, BaseHorizonManagementService>();
builder.Services.AddSingleton<IRoutePlanningService, RoutePlanningService>();

// Register TrafficControl Service (Orchestrator) - Must be registered after all sub-services
builder.Services.AddSingleton<TrafficControlService>();
builder.Services.AddSingleton<ITrafficControlService>(sp => sp.GetRequiredService<TrafficControlService>());
builder.Services.AddHostedService(sp => sp.GetRequiredService<TrafficControlService>());
```

### Migration Notes

Khi refactoring, các thay đổi sau đã được thực hiện:

1. **RouteConverter Helper:**
   - Updated để support generic logger (không chỉ `Logger<TrafficControlService>`)
   - Sử dụng reflection để call `Warning()` method

2. **Backward Compatibility:**
   - Tất cả public methods của `ITrafficControlService` vẫn giữ nguyên
   - Không có breaking changes cho external code

3. **Internal Implementation:**
   - Tất cả logic được move vào các service tương ứng
   - `TrafficControlService` chỉ delegate calls

---

## Design Decisions / Quyết định Thiết kế

### 1. Edge Capacity
- **Không giới hạn** số robot trên 1 edge cùng lúc
- Nhiều robot có thể sử dụng cùng edge nếu không có xung đột về timing, proximity, hoặc direction

### 2. Priority System
- **Có hệ thống ưu tiên** giữa các robot
- Priority levels: Emergency (100) > HighValueOrder (50) > TimeCritical (30) > Default (0)
- Robot có priority cao hơn được ưu tiên trong conflict resolution

### 3. Wait vs Reroute Strategy
- **Tùy vào loại xung đột** quyết định:
  - **WaitAtNode**: Khi conflict có thể giải quyết nhanh (thời gian đợi < threshold)
  - **Reroute**: Khi đợi quá lu hoặc không khả thi, hoặc reroute hiệu quả hơn
- Quyết định dựa trên:
  - Loại conflict (Confrontation → Reroute, Vertex → Wait)
  - Thời gian đợi ước tính
  - Khả năng reroute nhanh

### 4. Edge Direction Detection
- Sử dụng **StartNodeId và EndNodeId** từ Edge entity
- EdgeAB = Edge có StartNodeId = NodeA, EndNodeId = NodeB
- EdgeBA = Edge có StartNodeId = NodeB, EndNodeId = NodeA
- Xác định direction từ route segments và current robot position

### 6. Conflict Resolution Optimization
- **Kiểm tra xung đột nào giải quyết gây ra ít xung đột tiếp theo nhất**
- **Kiểm tra xung đột nào giải quyết có thể giúp giải quyết các xung đột khác**
- Ưu tiên giải quyết conflict:
  1. Có thể giải quyết nhiều conflict khác (`CanResolveConflicts.Count` cao)
  2. Gây ra ít conflict mới (`EstimatedNewConflicts` thấp)
  3. Có severity cao
  4. Liên quan đến robot có priority cao

### 7. Robot Information for Conflict Detection
- **Rotation Conflict**: 
  - **CẦN** thông tin robot: `Length`, `Width`, `NavigationPointX`, `NavigationPointY` (từ RobotModel)
  - Để tính toán không gian xoay (rotation space) và phát hiện chồng lấn
  - Cần góc xoay cần thiết từ route segments
- **Corridor Conflict**: 
  - **CẦN** thông tin robot: `Width` (chiều rộng robot, từ RobotModel)
  - **CẦN** thông tin edge: Edge width (từ map data, nếu có)
  - Để xác định hành lang có đủ rộng cho 2 robot không
  - Cần xác định chuỗi edges/nodes tạo thành hành lang hẹp
- **Proximity Conflict**: 
  - Có thể sử dụng thông tin robot (`Length`, `Width`) để tính khoảng cách an toàn chính xác hơn
  - Nhưng có thể phát hiện cơ bản chỉ với vị trí (X, Y) hiện tại từ State message

---

## Implementation Assumptions & Defaults / Giả định và Giá trị Mặc định

Phần này lưu lại các giả định và giá trị mặc định được sử dụng trong implementation hiện tại. Các giá trị này có thể được cải thiện trong tương lai khi có thêm dữ liệu từ database hoặc cấu hình.

### 1. Corridor Width / Chiều rộng Hành lang

**Vấn đề:** Edge entity trong database không có trường `Width` để xác định chiều rộng của edge/corridor.

**Giải pháp hiện tại:**
- Sử dụng giá trị mặc định: **2.0 meters** cho corridor width
- So sánh: `totalRobotWidth > defaultCorridorWidth * 0.8` (80% threshold) để xác định corridor conflict

**Cải thiện trong tương lai:**
- Thêm trường `Width` vào `Edge` entity trong database
- Hoặc thêm `CorridorWidth` vào `EdgeVehicleProperty` entity
- Hoặc tính toán từ khoảng cách giữa các node và robot dimensions

**File liên quan:**
- `TrafficControlService.cs` - Method `DetectCorridorConflictAsync()`
- `Edge.cs` - Entity definition (cần thêm trường Width)

---

### 2. Resource Node Detection / Phát hiện Resource Node

**Vấn đề:** Không có trường rõ ràng trong database để đánh dấu một node là resource node (charging station, work area, etc.).

**Giải pháp hiện tại:**
- Kiểm tra `Node.NodeName` và `Node.NodeDescription` cho các từ khóa:
  - "charge", "station", "work", "resource"
- Case-insensitive matching

**Cải thiện trong tương lai:**
- Thêm trường `IsResource` (boolean) vào `Node` entity
- Hoặc thêm `ResourceType` enum vào `Node` entity (None, ChargingStation, WorkArea, etc.)
- Hoặc kiểm tra `NodeVehicleProperty.Actions` để xác định resource nodes
- Hoặc tạo bảng riêng `ResourceNode` để quản lý resources

**File liên quan:**
- `TrafficControlService.cs` - Method `DetectResourceConflictAsync()`
- `Node.cs` - Entity definition (cần thêm trường IsResource hoặc ResourceType)

---

### 3. Rotation Space Calculation / Tính toán Không gian Xoay

**Vấn đề:** Cần tính toán không gian xoay chính xác dựa trên hình dạng robot và góc xoay.

**Giải pháp hiện tại:**
- Sử dụng công thức đơn giản: `rotationRadius = max(Length, Width) / 2.0 + 0.5m`
- Safety margin: **0.5 meters**
- Rotation time: **5 seconds** (mặc định)

**Cải thiện trong tương lai:**
- Xem xét góc xoay cụ thể từ route segments
- Sử dụng hình dạng robot thực tế (hình chữ nhật, hình tròn, etc.)
- Tính toán dựa trên `NavigationPointX`, `NavigationPointY` và góc xoay
- Rotation time có thể lấy từ `EdgeVehicleProperty.MaxRotationSpeed` và góc xoay cần thiết

**File liên quan:**
- `TrafficControlService.cs` - Method `DetectRotationConflictAsync()`
- `RobotInfo.cs` - Model chứa robot dimensions

---

### 4. Resource Usage Time / Thời gian Sử dụng Resource

**Vấn đề:** Không biết thời gian robot sẽ sử dụng resource (charging time, work time, etc.).

**Giải pháp hiện tại:**
- Sử dụng giá trị mặc định: **30 seconds** cho resource usage time

**Cải thiện trong tương lai:**
- Lấy từ `NodeVehicleProperty.Actions` - có thể có thông tin về duration
- Hoặc từ Order/OrderUpdate - có thể có thông tin về action duration
- Hoặc từ cấu hình resource-specific (charging time, work time, etc.)

**File liên quan:**
- `TrafficControlService.cs` - Method `DetectResourceConflictAsync()`

---

### 5. Edge Length Calculation / Tính toán Chiều dài Edge

**Giải pháp hiện tại:**
- Tính từ khoảng cách Euclidean giữa StartNode và EndNode:
  ```csharp
  length = sqrt((endNode.X - startNode.X)+ (endNode.Y - startNode.Y))
  ```

**Lưu ý:** 
- Nếu edge có trajectory (NURBS curve), chiều dài thực tế có thể khác
- Hiện tại chưa sử dụng `EdgeVehicleProperty.Trajectory` để tính chiều dài chính xác

**Cải thiện trong tương lai:**
- Tính chiều dài từ NURBS trajectory nếu có
- Hoặc lưu `Length` trực tiếp vào `Edge` entity

**File liên quan:**
- `TrafficControlService.cs` - Method `CalculateEdgeLength()`

---

### 6. Default Robot Speed / Tốc độ Robot Mặc định

**Giải pháp hiện tại:**
- Sử dụng giá trị mặc định: **1.0 m/s** cho robot speed
- Nếu có `EdgeVehicleProperty.MaxSpeed`, sử dụng giá trị đó

**Cải thiện trong tương lai:**
- Lấy từ State message của robot (nếu có)
- Hoặc từ RobotModel configuration
- Hoặc từ Order/OrderUpdate parameters

**File liên quan:**
- `TrafficControlService.cs` - Methods: `CalculateReservationDuration()`, `EstimateArrivalTime()`, `EstimatePositionAtTime()`

---

### 7. Proximity Conflict Detection / Phát hiện Xung đột Proximity

**Giải pháp hiện tại:**
- Sử dụng khoảng cách Euclidean giữa 2 robot
- Threshold: `ProximityMinDistance` từ config (mặc định có thể là 1.0m)

**Cải thiện trong tương lai:**
- Tính khoảng cách an toàn dựa trên robot dimensions:
  - `safeDistance = (robot1.Length + robot2.Length) / 2 + (robot1.Width + robot2.Width) / 2 + safetyMargin`
- Xem xét hướng di chuyển của robot

**File liên quan:**
- `TrafficControlService.cs` - Method `DetectProximityConflictAsync()`
- `TrafficControlConfig.cs` - Config `ProximityMinDistance`

---

### 8. Temporal Conflict Detection / Phát hiện Xung đột Temporal

**Giải pháp hiện tại:**
- Kiểm tra tại các time steps: **1s, 2s, 3s, 4s, 5s** trong tương lai
- Ước tính vị trí dựa trên vị trí hiện tại, hướng, và tốc độ mặc định

**Cải thiện trong tương lai:**
- Sử dụng route segments để ước tính vị trí chính xác hơn
- Xem xét tốc độ thực tế từ State message
- Tăng số lượng time steps hoặc sử dụng adaptive time steps

**File liên quan:**
- `TrafficControlService.cs` - Method `DetectTemporalConflictAsync()`

---

### 9. Corridor Conflict Detection / Phát hiện Xung đột Corridor

**Giải pháp hiện tại:**
- Tìm chuỗi edges tối thiểu: **2 consecutive edges** để xác định corridor
- Kiểm tra ngược chiều bằng cách so sánh sequence và reversed sequence

**Cải thiện trong tương lai:**
- Xác định corridor dựa trên edge width và robot width
- Có thể cần nhiều hơn 2 edges để xác định corridor
- Xem xét topology của graph để xác định corridor chính xác hơn

**File liên quan:**
- `TrafficControlService.cs` - Method `DetectCorridorConflictAsync()`

---

## Notes for Future Development / Ghi chú cho Phát triển Tương lai

1. **Database Schema Updates:**
   - Thêm `Width` vào `Edge` entity
   - Thêm `IsResource` hoặc `ResourceType` vào `Node` entity
   - Có thể cần thêm `CorridorWidth` vào `EdgeVehicleProperty`

2. **Configuration Enhancements:**
   - Thêm config cho default corridor width
   - Thêm config cho default rotation time
   - Thêm config cho default resource usage time
   - Thêm config cho default robot speed

3. **Robot Model Integration:**
   - Sử dụng đầy đủ thông tin từ RobotModel (shape, rotation characteristics, etc.)
   - Tích hợp với robot state để lấy tốc độ thực tế

4. **Trajectory Support:**
   - Sử dụng NURBS trajectory từ `EdgeVehicleProperty.Trajectory` để tính toán chính xác hơn

5. **Resource Management:**
   - Tạo hệ thống quản lý resources riêng (ResourceManager)
   - Tích hợp với Order/OrderUpdate để biết thời gian sử dụng resource

---

## Related Documents / Tài liệu Liên quan

- [TrafficControl.md](TrafficControl.md) - Existing documentation
- [RobotManager.md](RobotManager.md) - Robot state management
- [VDA5050_ROBOT_MANAGEMENT_ARCHITECTURE.md](DangNV/VDA5050_ROBOT_MANAGEMENT_ARCHITECTURE.md) - VDA5050 integration
- [PathFinding.md](../MapEditor/PathFinding.md) - A* algorithm details
- [VDA5050 README](../vda5050/README.md) - VDA5050 protocol

---

**Last Updated**: 2025-01-XX

