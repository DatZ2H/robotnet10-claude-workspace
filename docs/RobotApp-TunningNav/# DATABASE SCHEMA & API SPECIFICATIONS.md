# DATABASE SCHEMA & API SPECIFICATIONS

**Document:** Part 4 of Robot Tuning System Architecture  
**Coverage:** Complete database design and REST API/SignalR specifications

---

## DATABASE SCHEMA

Using Entity Framework Core with SQLite for development, PostgreSQL for production.

---

### 1. Core Tables

#### 1.1. TestScenarios Table

```csharp
[Table("test_scenarios")]
public class TestScenario
{
    [Key]
    public Guid Id { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string Name { get; set; }
    
    [Required]
    public TrajectoryType Type { get; set; }
    
    [Column(TypeName = "jsonb")] // PostgreSQL jsonb, TEXT for SQLite
    public string ConfigJson { get; set; }
    
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    
    [MaxLength(500)]
    public string Description { get; set; }
    
    public bool IsDefault { get; set; }
    public bool IsActive { get; set; }
    
    // Navigation properties
    public virtual ICollection<TestRun> TestRuns { get; set; }
}

public enum TrajectoryType
{
    StraightLine = 1,
    Circle = 2,
    Square = 3,
    SCurve = 4,
    Custom = 99
}
```

**Indexes:**
```sql
CREATE INDEX idx_test_scenarios_type ON test_scenarios(Type);
CREATE INDEX idx_test_scenarios_name ON test_scenarios(Name);
CREATE INDEX idx_test_scenarios_created_at ON test_scenarios(CreatedAt);
```

---

#### 1.2. ParameterSets Table

```csharp
[Table("parameter_sets")]
public class ParameterSet
{
    [Key]
    public Guid Id { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string Name { get; set; }
    
    [Column(TypeName = "jsonb")]
    public string ConfigJson { get; set; }
    
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    
    [MaxLength(500)]
    public string Description { get; set; }
    
    public bool IsDefault { get; set; }
    public bool IsActive { get; set; }
    
    // Version tracking
    public int Version { get; set; }
    public Guid? ParentId { get; set; }
    
    // Navigation properties
    public virtual ICollection<TestRun> TestRuns { get; set; }
    public virtual ICollection<ParameterHistory> History { get; set; }
}
```

**Indexes:**
```sql
CREATE INDEX idx_parameter_sets_name ON parameter_sets(Name);
CREATE INDEX idx_parameter_sets_parent_id ON parameter_sets(ParentId);
CREATE INDEX idx_parameter_sets_version ON parameter_sets(Version);
```

---

#### 1.3. TestRuns Table

```csharp
[Table("test_runs")]
public class TestRun
{
    [Key]
    public Guid Id { get; set; }
    
    [Required]
    public Guid TestScenarioId { get; set; }
    
    [Required]
    public Guid ParameterSetId { get; set; }
    
    public DateTime StartTime { get; set; }
    public DateTime? EndTime { get; set; }
    
    public TestStatus Status { get; set; }
    
    [MaxLength(500)]
    public string RawDataPath { get; set; }
    
    public float Duration { get; set; } // seconds
    
    [MaxLength(1000)]
    public string Notes { get; set; }
    
    [MaxLength(500)]
    public string ErrorMessage { get; set; }
    
    // Foreign keys
    [ForeignKey(nameof(TestScenarioId))]
    public virtual TestScenario TestScenario { get; set; }
    
    [ForeignKey(nameof(ParameterSetId))]
    public virtual ParameterSet ParameterSet { get; set; }
    
    // Navigation properties
    public virtual TestMetrics Metrics { get; set; }
    public virtual ICollection<SafetyViolation> SafetyViolations { get; set; }
}

public enum TestStatus
{
    Preparing = 0,
    Running = 1,
    Paused = 2,
    Completed = 3,
    Aborted = 4,
    Error = 5,
    EmergencyStopped = 6
}
```

**Indexes:**
```sql
CREATE INDEX idx_test_runs_scenario_id ON test_runs(TestScenarioId);
CREATE INDEX idx_test_runs_parameter_id ON test_runs(ParameterSetId);
CREATE INDEX idx_test_runs_start_time ON test_runs(StartTime DESC);
CREATE INDEX idx_test_runs_status ON test_runs(Status);
```

---

#### 1.4. TestMetrics Table

```csharp
[Table("test_metrics")]
public class TestMetrics
{
    [Key]
    public Guid Id { get; set; }
    
    [Required]
    public Guid TestRunId { get; set; }
    
    // Tracking Accuracy
    [Column(TypeName = "decimal(8,6)")]
    public decimal CrossTrackErrorRMS { get; set; }
    
    [Column(TypeName = "decimal(8,6)")]
    public decimal CrossTrackErrorPeak { get; set; }
    
    [Column(TypeName = "decimal(8,6)")]
    public decimal CrossTrackErrorMean { get; set; }
    
    [Column(TypeName = "decimal(8,6)")]
    public decimal CrossTrackErrorStdDev { get; set; }
    
    [Column(TypeName = "decimal(8,6)")]
    public decimal HeadingErrorRMS { get; set; }
    
    [Column(TypeName = "decimal(8,6)")]
    public decimal HeadingErrorPeak { get; set; }
    
    [Column(TypeName = "decimal(8,6)")]
    public decimal GoalPositionError { get; set; }
    
    // Smoothness
    [Column(TypeName = "decimal(8,4)")]
    public decimal MaxJerk { get; set; }
    
    [Column(TypeName = "decimal(8,4)")]
    public decimal AverageJerk { get; set; }
    
    [Column(TypeName = "decimal(8,4)")]
    public decimal MaxAngularJerk { get; set; }
    
    [Column(TypeName = "decimal(8,4)")]
    public decimal VelocityStdDev { get; set; }
    
    [Column(TypeName = "decimal(8,4)")]
    public decimal AccelerationStdDev { get; set; }
    
    // Efficiency
    [Column(TypeName = "decimal(8,4)")]
    public decimal PathLengthRatio { get; set; }
    
    [Column(TypeName = "decimal(8,2)")]
    public decimal CompletionTime { get; set; }
    
    [Column(TypeName = "decimal(8,4)")]
    public decimal AverageSpeed { get; set; }
    
    [Column(TypeName = "decimal(8,4)")]
    public decimal MaxSpeed { get; set; }
    
    // Scores
    [Column(TypeName = "decimal(5,2)")]
    public decimal OverallScore { get; set; }
    
    [Column(TypeName = "decimal(5,2)")]
    public decimal TrackingScore { get; set; }
    
    [Column(TypeName = "decimal(5,2)")]
    public decimal SmoothnessScore { get; set; }
    
    [Column(TypeName = "decimal(5,2)")]
    public decimal EfficiencyScore { get; set; }
    
    public bool PassedCriteria { get; set; }
    
    // Foreign key
    [ForeignKey(nameof(TestRunId))]
    public virtual TestRun TestRun { get; set; }
}
```

**Indexes:**
```sql
CREATE INDEX idx_test_metrics_test_run_id ON test_metrics(TestRunId);
CREATE INDEX idx_test_metrics_overall_score ON test_metrics(OverallScore DESC);
CREATE INDEX idx_test_metrics_passed ON test_metrics(PassedCriteria);
```

---

#### 1.5. SafetyViolations Table

```csharp
[Table("safety_violations")]
public class SafetyViolation
{
    [Key]
    public Guid Id { get; set; }
    
    [Required]
    public Guid TestRunId { get; set; }
    
    public DateTime Timestamp { get; set; }
    
    public ViolationType Type { get; set; }
    public ViolationSeverity Severity { get; set; }
    
    [Column(TypeName = "decimal(10,4)")]
    public decimal Value { get; set; }
    
    [Column(TypeName = "decimal(10,4)")]
    public decimal Threshold { get; set; }
    
    [MaxLength(500)]
    public string Message { get; set; }
    
    // Foreign key
    [ForeignKey(nameof(TestRunId))]
    public virtual TestRun TestRun { get; set; }
}

public enum ViolationType
{
    CrossTrackError = 1,
    HeadingError = 2,
    VelocityLimit = 3,
    AccelerationLimit = 4,
    SustainedTrackingError = 5,
    ObstacleProximity = 6
}

public enum ViolationSeverity
{
    Info = 0,
    Warning = 1,
    Critical = 2
}
```

---

#### 1.6. ParameterHistory Table

```csharp
[Table("parameter_history")]
public class ParameterHistory
{
    [Key]
    public Guid Id { get; set; }
    
    [Required]
    public Guid ParameterSetId { get; set; }
    
    public DateTime ChangedAt { get; set; }
    
    [MaxLength(200)]
    public string ChangedBy { get; set; }
    
    [MaxLength(1000)]
    public string ChangeDescription { get; set; }
    
    [Column(TypeName = "jsonb")]
    public string PreviousConfigJson { get; set; }
    
    [Column(TypeName = "jsonb")]
    public string NewConfigJson { get; set; }
    
    // Foreign key
    [ForeignKey(nameof(ParameterSetId))]
    public virtual ParameterSet ParameterSet { get; set; }
}
```

---

### 2. Database Context

```csharp
public class TuningDbContext : DbContext
{
    public DbSet<TestScenario> TestScenarios { get; set; }
    public DbSet<ParameterSet> ParameterSets { get; set; }
    public DbSet<TestRun> TestRuns { get; set; }
    public DbSet<TestMetrics> TestMetrics { get; set; }
    public DbSet<SafetyViolation> SafetyViolations { get; set; }
    public DbSet<ParameterHistory> ParameterHistory { get; set; }
    
    public TuningDbContext(DbContextOptions<TuningDbContext> options)
        : base(options)
    {
    }
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        // Configure relationships
        modelBuilder.Entity<TestRun>()
            .HasOne(tr => tr.TestScenario)
            .WithMany(ts => ts.TestRuns)
            .HasForeignKey(tr => tr.TestScenarioId)
            .OnDelete(DeleteBehavior.Restrict);
        
        modelBuilder.Entity<TestRun>()
            .HasOne(tr => tr.ParameterSet)
            .WithMany(ps => ps.TestRuns)
            .HasForeignKey(tr => tr.ParameterSetId)
            .OnDelete(DeleteBehavior.Restrict);
        
        modelBuilder.Entity<TestRun>()
            .HasOne(tr => tr.Metrics)
            .WithOne(tm => tm.TestRun)
            .HasForeignKey<TestMetrics>(tm => tm.TestRunId)
            .OnDelete(DeleteBehavior.Cascade);
        
        // Seed default data
        SeedDefaultData(modelBuilder);
    }
    
    private void SeedDefaultData(ModelBuilder modelBuilder)
    {
        // Default scenarios
        var straightLineId = Guid.NewGuid();
        var circle2mId = Guid.NewGuid();
        var circle05mId = Guid.NewGuid();
        
        modelBuilder.Entity<TestScenario>().HasData(
            new TestScenario
            {
                Id = straightLineId,
                Name = "Straight Line 10m",
                Type = TrajectoryType.StraightLine,
                ConfigJson = JsonSerializer.Serialize(new { Length = 10.0 }),
                CreatedAt = DateTime.UtcNow,
                IsDefault = true,
                IsActive = true
            },
            new TestScenario
            {
                Id = circle2mId,
                Name = "Circle 2m Radius",
                Type = TrajectoryType.Circle,
                ConfigJson = JsonSerializer.Serialize(new { Radius = 2.0 }),
                CreatedAt = DateTime.UtcNow,
                IsDefault = true,
                IsActive = true
            },
            new TestScenario
            {
                Id = circle05mId,
                Name = "Circle 0.5m Radius",
                Type = TrajectoryType.Circle,
                ConfigJson = JsonSerializer.Serialize(new { Radius = 0.5 }),
                CreatedAt = DateTime.UtcNow,
                IsDefault = true,
                IsActive = true
            }
        );
        
        // Default parameter set
        var defaultParamsId = Guid.NewGuid();
        modelBuilder.Entity<ParameterSet>().HasData(
            new ParameterSet
            {
                Id = defaultParamsId,
                Name = "Default",
                ConfigJson = JsonSerializer.Serialize(DefaultConfigurations.GetDefaultPreset()),
                CreatedAt = DateTime.UtcNow,
                IsDefault = true,
                IsActive = true,
                Version = 1
            }
        );
    }
}
```

---

### 3. Repository Interfaces

```csharp
public interface ITestRepository
{
    Task<TestRun> GetByIdAsync(Guid id);
    Task<List<TestRun>> GetAllAsync();
    Task<List<TestRun>> GetByScenarioAsync(Guid scenarioId);
    Task<List<TestRun>> GetByParameterSetAsync(Guid parameterSetId);
    Task<List<TestRun>> GetByDateRangeAsync(DateTime from, DateTime to);
    Task<TestRun> SaveAsync(TestRun testRun);
    Task UpdateAsync(TestRun testRun);
    Task DeleteAsync(Guid id);
}

public interface IParameterRepository
{
    Task<ParameterSet> GetByIdAsync(Guid id);
    Task<ParameterSet> GetByNameAsync(string name);
    Task<List<ParameterSet>> GetAllAsync();
    Task<ParameterSet> SaveAsync(ParameterSet parameterSet);
    Task UpdateAsync(ParameterSet parameterSet);
    Task DeleteAsync(Guid id);
    Task<List<ParameterHistory>> GetHistoryAsync(Guid parameterSetId);
    Task SaveSnapshotAsync(ParameterSnapshot snapshot);
}
```

---

## REST API SPECIFICATIONS

Base URL: `https://robot.local:5000/api/v1`

---

### 1. Test Scenarios API

#### GET /scenarios
Get all test scenarios.

**Response:**
```json
{
  "scenarios": [
    {
      "id": "uuid",
      "name": "Straight Line 10m",
      "type": "StraightLine",
      "config": { "length": 10.0 },
      "createdAt": "2026-01-26T10:00:00Z",
      "isDefault": true
    }
  ]
}
```

#### GET /scenarios/{id}
Get specific scenario.

#### POST /scenarios
Create new scenario.

**Request:**
```json
{
  "name": "Custom Path",
  "type": "Custom",
  "config": {
    "waypoints": [
      { "x": 0, "y": 0 },
      { "x": 5, "y": 0 },
      { "x": 5, "y": 5 }
    ]
  },
  "description": "L-shaped path"
}
```

#### PUT /scenarios/{id}
Update scenario.

#### DELETE /scenarios/{id}
Delete scenario.

---

### 2. Parameter Sets API

#### GET /parameters
Get all parameter sets.

#### GET /parameters/{id}
Get specific parameter set.

#### GET /parameters/presets
Get built-in presets.

**Response:**
```json
{
  "presets": [
    {
      "name": "Default",
      "config": { ... }
    },
    {
      "name": "Aggressive",
      "config": { ... }
    },
    {
      "name": "Smooth",
      "config": { ... }
    }
  ]
}
```

#### POST /parameters
Save new parameter set.

**Request:**
```json
{
  "name": "MyCustomConfig",
  "config": {
    "pid": {
      "kp": 1.2,
      "ki": 0.1,
      "kd": 0.05
    },
    "purePursuit": {
      "kdd": 1.0,
      "lookaheadMin": 0.3,
      "lookaheadMax": 2.0
    },
    "estimator": {
      "alphaFilter": 0.3,
      "goodTrackingBlend": 0.4
    }
  },
  "description": "Tuned for warehouse"
}
```

#### PUT /parameters/{id}
Update parameter set.

#### POST /parameters/{id}/snapshot
Create version snapshot.

**Request:**
```json
{
  "description": "Before optimization run"
}
```

#### GET /parameters/{id}/history
Get version history.

---

### 3. Test Execution API

#### POST /tests/run
Start a single test.

**Request:**
```json
{
  "scenarioId": "uuid",
  "parameterSetId": "uuid",
  "notes": "Testing new PID values"
}
```

**Response:**
```json
{
  "testRunId": "uuid",
  "status": "Preparing"
}
```

#### POST /tests/batch
Run batch tests.

**Request:**
```json
{
  "scenarioIds": ["uuid1", "uuid2", "uuid3"],
  "parameterSetId": "uuid"
}
```

#### POST /tests/compare
Compare multiple configurations.

**Request:**
```json
{
  "scenarioId": "uuid",
  "parameterSetIds": ["uuid1", "uuid2", "uuid3"]
}
```

#### GET /tests/{id}
Get test run details.

#### GET /tests
Get all test runs (paginated).

**Query Parameters:**
- `page`: int (default: 1)
- `pageSize`: int (default: 20)
- `scenarioId`: uuid (optional filter)
- `parameterSetId`: uuid (optional filter)
- `status`: enum (optional filter)
- `fromDate`: datetime (optional filter)
- `toDate`: datetime (optional filter)

#### GET /tests/{id}/metrics
Get detailed metrics for a test run.

#### GET /tests/{id}/download
Download raw test data.

---

### 4. Analysis API

#### GET /analysis/summary
Get summary statistics across all tests.

**Response:**
```json
{
  "totalTests": 150,
  "successRate": 0.92,
  "averageScore": 85.3,
  "bestConfiguration": {
    "name": "Optimized_v3",
    "score": 95.2
  }
}
```

#### GET /analysis/trends
Get performance trends over time.

#### POST /analysis/compare
Detailed comparison between test runs.

**Request:**
```json
{
  "testRunIds": ["uuid1", "uuid2"]
}
```

#### GET /analysis/rankings
Get ranked configurations.

**Query Parameters:**
- `scenarioId`: uuid (optional)
- `metric`: enum (overall, tracking, smoothness, efficiency)
- `limit`: int (default: 10)

---

## SIGNALR HUB SPECIFICATIONS

Hub URL: `https://robot.local:5000/tuninghub`

---

### Client → Server Methods

```typescript
// Start test
await connection.invoke("StartTest", {
  scenarioId: "uuid",
  parameterSetId: "uuid"
});

// Control
await connection.invoke("PauseTest");
await connection.invoke("ResumeTest");
await connection.invoke("StopTest");
await connection.invoke("EmergencyStop");

// Real-time parameter updates
await connection.invoke("UpdateParameters", {
  pid: { kp: 1.5, ki: 0.1, kd: 0.05 }
});
```

---

### Server → Client Messages

```typescript
// State updates (10Hz)
connection.on("ReceiveState", (state: RobotState) => {
  // state: { position, heading, linearVelocity, angularVelocity, timestamp }
});

// Metrics updates (1Hz)
connection.on("ReceiveMetrics", (metrics: CurrentMetrics) => {
  // metrics: { cte, headingError, velocity, etc. }
});

// Test status
connection.on("ReceiveTestStatus", (status: TestStatusUpdate) => {
  // status: { state, message, progress, timestamp }
});

// Safety events
connection.on("ReceiveSafetyEvent", (event: SafetyEvent) => {
  // event: { type, severity, message, timestamp }
});

// Test completed
connection.on("ReceiveTestResult", (result: TestResult) => {
  // result: { testRunId, metrics, status, duration }
});
```

---

### Data Transfer Objects

```csharp
public class RobotState
{
    public Vector2 Position { get; set; }
    public float Heading { get; set; }
    public float LinearVelocity { get; set; }
    public float AngularVelocity { get; set; }
    public long TimestampMs { get; set; }
}

public class CurrentMetrics
{
    public float CrossTrackError { get; set; }
    public float HeadingError { get; set; }
    public float LookaheadDistance { get; set; }
    public Vector2 TargetPoint { get; set; }
    public float DistanceToGoal { get; set; }
}

public class TestStatusUpdate
{
    public TestState State { get; set; }
    public string Message { get; set; }
    public float Progress { get; set; }  // 0.0 - 1.0
    public DateTime Timestamp { get; set; }
}
```

---

## AUTHENTICATION & AUTHORIZATION

For MVP: Basic authentication (optional).
For Production: JWT tokens with role-based access.

```csharp
public enum UserRole
{
    Viewer,      // Read-only access
    Operator,    // Can run tests
    Engineer,    // Can modify parameters
    Admin        // Full access
}
```

Endpoint Permissions:
- GET endpoints: Viewer+
- POST /tests/run: Operator+
- POST /parameters: Engineer+
- DELETE endpoints: Admin only

---

## ERROR HANDLING

Standard error response format:

```json
{
  "error": {
    "code": "INVALID_PARAMETERS",
    "message": "Kp value must be between 0.1 and 5.0",
    "details": {
      "field": "pid.kp",
      "value": 10.5,
      "min": 0.1,
      "max": 5.0
    },
    "timestamp": "2026-01-26T10:30:00Z"
  }
}
```

HTTP Status Codes:
- 200: Success
- 201: Created
- 400: Bad Request (validation errors)
- 404: Not Found
- 409: Conflict (e.g., duplicate name)
- 500: Internal Server Error
- 503: Service Unavailable (robot not ready)

---

This completes the database and API specification document.