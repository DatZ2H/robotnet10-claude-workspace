# LAYERS 2-3: APPLICATION SERVICES & DOMAIN LOGIC

**Document:** Part 2 of Robot Tuning System Architecture  
**Layers Covered:** Application Services (Layer 2) and Domain Logic (Layer 3)

---

## LAYER 2: APPLICATION SERVICES

Application Services orchestrate business workflows and coordinate between the UI layer and domain logic. They handle cross-cutting concerns like transaction management, event publishing, and data transformation.

---

### 1. TuningOrchestrator Service

**File:** `Application/Services/TuningOrchestrator.cs`

**Responsibility:** Master coordinator for all tuning operations.

#### Interface Definition

```csharp
public interface ITuningOrchestrator
{
    // Test execution
    Task<TestResult> RunSingleTest(
        TestScenario scenario, 
        ParameterSet parameters, 
        string? connectionId = null
    );
    
    Task<BatchTestResult> RunBatchTests(
        List<TestScenario> scenarios, 
        ParameterSet parameters,
        CancellationToken cancellationToken = default
    );
    
    Task<ComparisonResult> CompareConfigurations(
        List<ParameterSet> parameterSets, 
        TestScenario scenario
    );
    
    // Real-time control
    Task StartTestAsync(
        TestScenario scenario, 
        ParameterSet parameters, 
        string connectionId
    );
    Task PauseTestAsync(string connectionId);
    Task ResumeTestAsync(string connectionId);
    Task StopTestAsync(string connectionId);
    Task EmergencyStopAsync(string connectionId);
    
    // State queries
    TuningState GetCurrentState(string connectionId);
    TestProgress GetProgress(string connectionId);
    
    // Optimization
    Task<OptimizationResult> RunManualTuning(ManualTuningSession session);
    Task<OptimizationResult> RunAutoTuning(
        AutoTuningConfig config,
        IProgress<OptimizationProgress> progress,
        CancellationToken cancellationToken = default
    );
}
```

#### Implementation Details

```csharp
public class TuningOrchestrator : ITuningOrchestrator
{
    private readonly ITestExecutor _testExecutor;
    private readonly IParameterManager _parameterManager;
    private readonly IMetricAnalyzer _metricAnalyzer;
    private readonly IEventPublisher _eventPublisher;
    private readonly ITestRepository _testRepository;
    private readonly ILogger<TuningOrchestrator> _logger;
    
    // Active test sessions keyed by connectionId
    private readonly ConcurrentDictionary<string, TestSession> _activeSessions;
    
    public async Task<TestResult> RunSingleTest(
        TestScenario scenario, 
        ParameterSet parameters, 
        string? connectionId = null)
    {
        // 1. Validate inputs
        var validationResult = await _parameterManager.ValidateAsync(parameters);
        if (!validationResult.IsValid)
        {
            throw new InvalidParameterException(validationResult.Errors);
        }
        
        // 2. Create test session
        var session = new TestSession
        {
            Id = Guid.NewGuid(),
            Scenario = scenario,
            Parameters = parameters,
            ConnectionId = connectionId,
            State = TestState.Preparing
        };
        
        if (connectionId != null)
        {
            _activeSessions.TryAdd(connectionId, session);
        }
        
        try
        {
            // 3. Initialize test
            await PublishStatusAsync(session, TestState.Preparing);
            await _testExecutor.InitializeAsync(scenario, parameters);
            
            // 4. Execute test
            await PublishStatusAsync(session, TestState.Running);
            var executionResult = await _testExecutor.ExecuteAsync(
                onStateUpdate: state => PublishStateAsync(session, state),
                onSafetyViolation: violation => HandleSafetyViolationAsync(session, violation)
            );
            
            // 5. Analyze results
            await PublishStatusAsync(session, TestState.Analyzing);
            var metrics = await _metricAnalyzer.AnalyzeAsync(executionResult);
            
            // 6. Create test result
            var testResult = new TestResult
            {
                Id = Guid.NewGuid(),
                SessionId = session.Id,
                Scenario = scenario,
                Parameters = parameters,
                ExecutionData = executionResult,
                Metrics = metrics,
                StartTime = executionResult.StartTime,
                EndTime = executionResult.EndTime,
                Status = executionResult.Status
            };
            
            // 7. Persist to database
            await _testRepository.SaveAsync(testResult);
            
            // 8. Notify completion
            await PublishStatusAsync(session, TestState.Completed);
            await PublishResultAsync(session, testResult);
            
            return testResult;
        }
        catch (SafetyViolationException ex)
        {
            _logger.LogError(ex, "Safety violation during test");
            await PublishStatusAsync(session, TestState.Aborted);
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during test execution");
            await PublishStatusAsync(session, TestState.Error);
            throw;
        }
        finally
        {
            if (connectionId != null)
            {
                _activeSessions.TryRemove(connectionId, out _);
            }
            
            await _testExecutor.CleanupAsync();
        }
    }
    
    public async Task<BatchTestResult> RunBatchTests(
        List<TestScenario> scenarios, 
        ParameterSet parameters,
        CancellationToken cancellationToken = default)
    {
        var results = new List<TestResult>();
        var batchId = Guid.NewGuid();
        
        _logger.LogInformation(
            "Starting batch test with {Count} scenarios", 
            scenarios.Count
        );
        
        for (int i = 0; i < scenarios.Count; i++)
        {
            if (cancellationToken.IsCancellationRequested)
            {
                _logger.LogWarning("Batch test cancelled at scenario {Index}", i);
                break;
            }
            
            var scenario = scenarios[i];
            
            try
            {
                var result = await RunSingleTest(scenario, parameters);
                results.Add(result);
                
                _logger.LogInformation(
                    "Completed scenario {Index}/{Total}: {Name}", 
                    i + 1, 
                    scenarios.Count, 
                    scenario.Name
                );
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex, 
                    "Failed scenario {Index}/{Total}: {Name}", 
                    i + 1, 
                    scenarios.Count, 
                    scenario.Name
                );
                
                // Continue with remaining scenarios
            }
        }
        
        var batchResult = new BatchTestResult
        {
            BatchId = batchId,
            Parameters = parameters,
            Results = results,
            SuccessCount = results.Count(r => r.Status == TestStatus.Completed),
            FailureCount = results.Count(r => r.Status != TestStatus.Completed),
            AverageScore = results.Average(r => r.Metrics.OverallScore)
        };
        
        return batchResult;
    }
    
    public async Task<ComparisonResult> CompareConfigurations(
        List<ParameterSet> parameterSets, 
        TestScenario scenario)
    {
        var results = new Dictionary<string, TestResult>();
        
        foreach (var parameters in parameterSets)
        {
            var result = await RunSingleTest(scenario, parameters);
            results[parameters.Name] = result;
        }
        
        var comparison = new ComparisonResult
        {
            Scenario = scenario,
            Configurations = parameterSets,
            Results = results,
            BestConfiguration = results
                .OrderByDescending(r => r.Value.Metrics.OverallScore)
                .First()
                .Key
        };
        
        return comparison;
    }
    
    // Real-time control methods
    public async Task StartTestAsync(
        TestScenario scenario, 
        ParameterSet parameters, 
        string connectionId)
    {
        // Run test asynchronously and stream updates via SignalR
        _ = Task.Run(async () =>
        {
            await RunSingleTest(scenario, parameters, connectionId);
        });
    }
    
    public async Task PauseTestAsync(string connectionId)
    {
        if (_activeSessions.TryGetValue(connectionId, out var session))
        {
            await _testExecutor.PauseAsync();
            await PublishStatusAsync(session, TestState.Paused);
        }
    }
    
    public async Task ResumeTestAsync(string connectionId)
    {
        if (_activeSessions.TryGetValue(connectionId, out var session))
        {
            await _testExecutor.ResumeAsync();
            await PublishStatusAsync(session, TestState.Running);
        }
    }
    
    public async Task StopTestAsync(string connectionId)
    {
        if (_activeSessions.TryGetValue(connectionId, out var session))
        {
            await _testExecutor.StopAsync();
            await PublishStatusAsync(session, TestState.Stopped);
        }
    }
    
    public async Task EmergencyStopAsync(string connectionId)
    {
        if (_activeSessions.TryGetValue(connectionId, out var session))
        {
            await _testExecutor.EmergencyStopAsync();
            await PublishStatusAsync(session, TestState.EmergencyStopped);
        }
    }
    
    // Helper methods
    private async Task PublishStateAsync(TestSession session, RobotState state)
    {
        if (session.ConnectionId != null)
        {
            await _eventPublisher.PublishAsync(
                "ReceiveState", 
                state, 
                session.ConnectionId
            );
        }
    }
    
    private async Task PublishStatusAsync(TestSession session, TestState state)
    {
        session.State = state;
        
        if (session.ConnectionId != null)
        {
            await _eventPublisher.PublishAsync(
                "ReceiveTestStatus", 
                new TestStatus 
                { 
                    State = state,
                    Timestamp = DateTime.UtcNow
                }, 
                session.ConnectionId
            );
        }
    }
    
    private async Task PublishResultAsync(TestSession session, TestResult result)
    {
        if (session.ConnectionId != null)
        {
            await _eventPublisher.PublishAsync(
                "ReceiveTestResult", 
                result, 
                session.ConnectionId
            );
        }
    }
    
    private async Task HandleSafetyViolationAsync(
        TestSession session, 
        SafetyViolation violation)
    {
        _logger.LogWarning(
            "Safety violation: {Type} at {Timestamp}", 
            violation.Type, 
            violation.Timestamp
        );
        
        if (session.ConnectionId != null)
        {
            await _eventPublisher.PublishAsync(
                "ReceiveSafetyEvent", 
                violation, 
                session.ConnectionId
            );
        }
        
        // Trigger emergency stop if critical
        if (violation.Severity == ViolationSeverity.Critical)
        {
            await EmergencyStopAsync(session.ConnectionId!);
        }
    }
}
```

---

### 2. ParameterManager Service

**File:** `Application/Services/ParameterManager.cs`

**Responsibility:** Manage parameter configurations with validation, versioning, and persistence.

#### Interface Definition

```csharp
public interface IParameterManager
{
    // Configuration management
    Task<ParameterSet> GetCurrentAsync();
    Task SetCurrentAsync(ParameterSet parameters);
    Task<ParameterSet> GetByNameAsync(string name);
    Task<List<ParameterSet>> GetAllAsync();
    
    // CRUD operations
    Task<string> SaveAsync(string name, ParameterSet parameters, string description = "");
    Task UpdateAsync(string name, ParameterSet parameters);
    Task DeleteAsync(string name);
    
    // Validation
    Task<ValidationResult> ValidateAsync(ParameterSet parameters);
    ParameterSet ClampToValidRanges(ParameterSet parameters);
    
    // Versioning
    Task CreateSnapshotAsync(string name, string description);
    Task<ParameterSet> RollbackToSnapshotAsync(Guid snapshotId);
    Task<List<ParameterSnapshot>> GetHistoryAsync(string name);
    
    // Presets
    ParameterSet GetDefaultPreset();
    ParameterSet GetConservativePreset();
    ParameterSet GetAggressivePreset();
    ParameterSet GetSmoothPreset();
    
    // Import/Export
    Task ExportToJsonAsync(string name, string filePath);
    Task<ParameterSet> ImportFromJsonAsync(string filePath);
}
```

#### Implementation Highlights

```csharp
public class ParameterManager : IParameterManager
{
    private readonly IParameterRepository _repository;
    private readonly IParameterValidator _validator;
    private ParameterSet _currentParameters;
    
    public async Task<ValidationResult> ValidateAsync(ParameterSet parameters)
    {
        var result = new ValidationResult { IsValid = true };
        
        // 1. Validate individual parameter bounds
        if (!ParameterBounds.KpRange.Contains(parameters.PID.Kp))
        {
            result.AddError($"Kp must be between {ParameterBounds.KpRange.Min} and {ParameterBounds.KpRange.Max}");
        }
        
        // ... validate all parameters
        
        // 2. Validate inter-parameter constraints
        if (parameters.PurePursuit.LookaheadMax <= parameters.PurePursuit.LookaheadMin)
        {
            result.AddError("LookaheadMax must be greater than LookaheadMin");
        }
        
        if (parameters.Estimator.GoodTrackingBlend > parameters.Estimator.PoorTrackingBlend)
        {
            result.AddError("GoodTrackingBlend should be less than PoorTrackingBlend");
        }
        
        // 3. Validate against physical limits
        if (parameters.PID.MaxVelocity > parameters.Physical.MaxLinearVelocity)
        {
            result.AddError($"PID MaxVelocity cannot exceed physical limit of {parameters.Physical.MaxLinearVelocity} m/s");
        }
        
        // 4. Check for dangerous combinations
        if (parameters.PID.Kp > 3.0f && parameters.PID.Ki > 1.0f)
        {
            result.AddWarning("High Kp and Ki together may cause oscillation");
        }
        
        return result;
    }
    
    public ParameterSet ClampToValidRanges(ParameterSet parameters)
    {
        var clamped = parameters.Clone();
        
        clamped.PID.Kp = ParameterBounds.KpRange.Clamp(clamped.PID.Kp);
        clamped.PID.Ki = ParameterBounds.KiRange.Clamp(clamped.PID.Ki);
        clamped.PID.Kd = ParameterBounds.KdRange.Clamp(clamped.PID.Kd);
        
        clamped.Estimator.AlphaFilter = ParameterBounds.AlphaFilterRange.Clamp(clamped.Estimator.AlphaFilter);
        // ... clamp all parameters
        
        return clamped;
    }
    
    public async Task CreateSnapshotAsync(string name, string description)
    {
        var current = await GetByNameAsync(name);
        
        var snapshot = new ParameterSnapshot
        {
            Id = Guid.NewGuid(),
            ParameterSetName = name,
            ConfigJson = JsonSerializer.Serialize(current),
            Description = description,
            CreatedAt = DateTime.UtcNow
        };
        
        await _repository.SaveSnapshotAsync(snapshot);
    }
    
    public ParameterSet GetDefaultPreset()
    {
        return new ParameterSet
        {
            Name = "Default",
            Physical = DefaultConfigurations.Physical,
            Timing = DefaultConfigurations.Timing,
            PID = DefaultConfigurations.PID,
            Estimator = DefaultConfigurations.Estimator,
            PurePursuit = DefaultConfigurations.PurePursuit,
            PathFollowing = DefaultConfigurations.PathFollowing,
            Safety = DefaultConfigurations.Safety
        };
    }
    
    public ParameterSet GetAggressivePreset()
    {
        var preset = GetDefaultPreset();
        preset.Name = "Aggressive";
        preset.PID.Kp = 1.5f;  // High response
        preset.PID.Ki = 0.2f;
        preset.PID.Kd = 0.02f; // Low damping
        preset.PurePursuit.Kdd = 0.8f; // Shorter lookahead → tighter tracking
        return preset;
    }
    
    public ParameterSet GetSmoothPreset()
    {
        var preset = GetDefaultPreset();
        preset.Name = "Smooth";
        preset.PID.Kp = 0.6f;  // Gentle response
        preset.PID.Ki = 0.05f;
        preset.PID.Kd = 0.3f;  // High damping
        preset.PurePursuit.Kdd = 1.5f; // Longer lookahead → smoother
        preset.Estimator.AlphaFilter = 0.2f; // More filtering
        return preset;
    }
}
```

---

### 3. MetricAnalyzer Service

**File:** `Application/Services/MetricAnalyzer.cs`

**Responsibility:** Calculate, aggregate, and analyze performance metrics.

#### Interface Definition

```csharp
public interface IMetricAnalyzer
{
    // Core analysis
    Task<TestMetrics> AnalyzeAsync(ExecutionResult executionResult);
    Task<TrackingAccuracyMetrics> CalculateTrackingAccuracyAsync(List<ControlCycleData> data, Path referencePath);
    Task<SmoothnessMetrics> CalculateSmoothnessAsync(List<ControlCycleData> data);
    Task<EfficiencyMetrics> CalculateEfficiencyAsync(ExecutionResult result, Path referencePath);
    
    // Statistical analysis
    StatisticalSummary GetStatistics(List<TestResult> results);
    TrendAnalysis AnalyzeTrends(List<TestResult> historicalResults);
    
    // Evaluation
    PassFailResult EvaluateAgainstCriteria(TestMetrics metrics, AcceptanceCriteria criteria);
    float CalculateOverallScore(TestMetrics metrics, ScoringWeights weights);
    
    // Comparison
    ComparisonReport CompareResults(TestResult baseline, TestResult current);
    RankingReport RankConfigurations(List<TestResult> results, ScoringWeights weights);
}
```

#### Key Calculation Methods

```csharp
public class MetricAnalyzer : IMetricAnalyzer
{
    public async Task<TrackingAccuracyMetrics> CalculateTrackingAccuracyAsync(
        List<ControlCycleData> data, 
        Path referencePath)
    {
        var cteValues = new List<float>();
        var headingErrors = new List<float>();
        
        foreach (var cycle in data)
        {
            // Calculate cross-track error
            var closestPoint = referencePath.GetClosestPoint(cycle.Position);
            var cte = Vector2.Distance(cycle.Position, closestPoint.Position);
            cteValues.Add(cte);
            
            // Calculate heading error
            var pathHeading = closestPoint.Tangent.Angle();
            var headingError = NormalizeAngle(cycle.Heading - pathHeading);
            headingErrors.Add(Math.Abs(headingError));
        }
        
        // Calculate RMS errors
        var cteRMS = CalculateRMS(cteValues);
        var ctePeak = cteValues.Max();
        var headingRMS = CalculateRMS(headingErrors);
        
        // Goal accuracy (last 10 data points)
        var finalPoints = data.TakeLast(10).ToList();
        var goalPosition = referencePath.Points.Last().Position;
        var goalPositionError = finalPoints
            .Average(p => Vector2.Distance(p.Position, goalPosition));
        
        return new TrackingAccuracyMetrics
        {
            CrossTrackErrorRMS = cteRMS,
            CrossTrackErrorPeak = ctePeak,
            CrossTrackErrorMean = cteValues.Average(),
            CrossTrackErrorStdDev = CalculateStdDev(cteValues),
            HeadingErrorRMS = headingRMS,
            HeadingErrorPeak = headingErrors.Max(),
            GoalPositionError = goalPositionError
        };
    }
    
    public async Task<SmoothnessMetrics> CalculateSmoothnessAsync(
        List<ControlCycleData> data)
    {
        var velocities = data.Select(d => d.LinearVelocity).ToList();
        var angularVelocities = data.Select(d => d.AngularVelocity).ToList();
        
        var dt = data[1].TimeFromStart - data[0].TimeFromStart;
        
        // Calculate accelerations
        var accelerations = new List<float>();
        for (int i = 1; i < velocities.Count; i++)
        {
            var accel = (velocities[i] - velocities[i-1]) / dt;
            accelerations.Add(accel);
        }
        
        // Calculate jerks
        var jerks = new List<float>();
        for (int i = 1; i < accelerations.Count; i++)
        {
            var jerk = (accelerations[i] - accelerations[i-1]) / dt;
            jerks.Add(Math.Abs(jerk));
        }
        
        // Angular jerk
        var angularAccelerations = new List<float>();
        for (int i = 1; i < angularVelocities.Count; i++)
        {
            var angAccel = (angularVelocities[i] - angularVelocities[i-1]) / dt;
            angularAccelerations.Add(angAccel);
        }
        
        var angularJerks = new List<float>();
        for (int i = 1; i < angularAccelerations.Count; i++)
        {
            var angJerk = (angularAccelerations[i] - angularAccelerations[i-1]) / dt;
            angularJerks.Add(Math.Abs(angJerk));
        }
        
        return new SmoothnessMetrics
        {
            MaxJerk = jerks.Max(),
            AverageJerk = jerks.Average(),
            MaxAngularJerk = angularJerks.Max(),
            VelocityStdDev = CalculateStdDev(velocities),
            AccelerationStdDev = CalculateStdDev(accelerations)
        };
    }
    
    public float CalculateOverallScore(TestMetrics metrics, ScoringWeights weights)
    {
        float score = 100f;
        
        // Tracking accuracy penalties (weighted 50%)
        score -= weights.TrackingAccuracy * (
            NormalizePenalty(metrics.CrossTrackErrorRMS, 0.10f, 20f) +
            NormalizePenalty(metrics.HeadingErrorRMS, 10f * Deg2Rad, 20f) +
            NormalizePenalty(metrics.GoalPositionError, 0.05f, 10f)
        );
        
        // Smoothness penalties (weighted 30%)
        score -= weights.Smoothness * (
            NormalizePenalty(metrics.MaxJerk, 5.0f, 15f) +
            NormalizePenalty(metrics.MaxAngularJerk, 10.0f, 15f)
        );
        
        // Efficiency penalties (weighted 20%)
        score -= weights.Efficiency * (
            NormalizePenalty(metrics.PathLengthRatio - 1.0f, 0.15f, 20f)
        );
        
        return Math.Max(0, score);
    }
    
    private float NormalizePenalty(float actual, float threshold, float maxPenalty)
    {
        if (actual <= threshold) return 0;
        
        var excess = actual - threshold;
        var penalty = (excess / threshold) * maxPenalty;
        return Math.Min(penalty, maxPenalty);
    }
    
    private float CalculateRMS(List<float> values)
    {
        return MathF.Sqrt(values.Average(v => v * v));
    }
    
    private float CalculateStdDev(List<float> values)
    {
        var mean = values.Average();
        var variance = values.Average(v => (v - mean) * (v - mean));
        return MathF.Sqrt(variance);
    }
    
    private float NormalizeAngle(float angle)
    {
        while (angle > MathF.PI) angle -= 2 * MathF.PI;
        while (angle < -MathF.PI) angle += 2 * MathF.PI;
        return angle;
    }
}
```

---

### 4. ReportGenerator Service

**File:** `Application/Services/ReportGenerator.cs`

**Responsibility:** Generate reports and export data in various formats.

#### Interface Definition

```csharp
public interface IReportGenerator
{
    // Report generation
    Task<byte[]> GeneratePdfReportAsync(TestResult result);
    Task<string> GenerateHtmlReportAsync(TestResult result);
    Task<string> GenerateMarkdownSummaryAsync(TestResult result);
    
    // Data export
    Task ExportToCsvAsync(TestResult result, string filePath);
    Task ExportToMatlabAsync(TestResult result, string filePath);
    Task ExportRawDataAsync(TestResult result, string filePath);
    
    // Batch reports
    Task<string> GenerateComparisonReportAsync(ComparisonResult comparison);
    Task<string> GenerateBatchSummaryAsync(BatchTestResult batchResult);
}
```

---

## LAYER 3: DOMAIN LOGIC

Domain logic contains the core business rules and algorithms. This layer is framework-agnostic and contains no infrastructure dependencies.

---

### 1. Test Execution Engine

**File:** `Domain/Services/TestExecutor.cs`

#### Interface Definition

```csharp
public interface ITestExecutor
{
    // Lifecycle
    Task InitializeAsync(TestScenario scenario, ParameterSet parameters);
    Task<ExecutionResult> ExecuteAsync(
        Action<RobotState>? onStateUpdate = null,
        Action<SafetyViolation>? onSafetyViolation = null
    );
    Task CleanupAsync();
    
    // Control
    Task PauseAsync();
    Task ResumeAsync();
    Task StopAsync();
    Task EmergencyStopAsync();
    
    // State
    ExecutionState GetCurrentState();
    float GetProgress();
}
```

#### Implementation Core Logic

```csharp
public class TestExecutor : ITestExecutor
{
    private readonly IPIDController _pidController;
    private readonly IVelocityEstimator _velocityEstimator;
    private readonly IPurePursuitController _purePursuitController;
    private readonly IMotorDriver _motorDriver;
    private readonly IEncoderReader _encoderReader;
    private readonly IRobotStateManager _stateManager;
    private readonly ISafetyMonitor _safetyMonitor;
    private readonly IDataLogger _dataLogger;
    
    private Path _referencePath;
    private ParameterSet _parameters;
    private ExecutionState _state;
    private CancellationTokenSource _cts;
    
    public async Task<ExecutionResult> ExecuteAsync(
        Action<RobotState>? onStateUpdate = null,
        Action<SafetyViolation>? onSafetyViolation = null)
    {
        _state = ExecutionState.Running;
        _cts = new CancellationTokenSource();
        
        var startTime = DateTime.UtcNow;
        var result = new ExecutionResult
        {
            StartTime = startTime,
            Status = TestStatus.Running
        };
        
        try
        {
            // Main control loop (50Hz)
            var dt = 1.0f / _parameters.Timing.ControlLoopFrequency;
            var cycleTime = TimeSpan.FromSeconds(dt);
            
            while (!IsGoalReached() && !_cts.Token.IsCancellationRequested)
            {
                var cycleStart = DateTime.UtcNow;
                
                // 1. Read sensors
                var encoderData = _encoderReader.ReadEncoders();
                _stateManager.UpdateFromEncoders(encoderData, dt);
                var robotState = _stateManager.GetCurrentPose();
                var robotTwist = _stateManager.GetCurrentTwist();
                
                // 2. Calculate distance to goal
                var goalPosition = _referencePath.Points.Last().Position;
                var distanceToGoal = Vector2.Distance(robotState.Position, goalPosition);
                
                // 3. PID: distance → v_max
                float vMax;
                if (distanceToGoal > 5.0f)
                {
                    vMax = _parameters.PID.MaxVelocity;
                }
                else
                {
                    var pidOutput = _pidController.Calculate(distanceToGoal, dt);
                    vMax = Math.Max(pidOutput, _parameters.PID.MinVelocity);
                }
                
                // 4. Velocity Estimator: estimate v_hybrid
                var vCmd = vMax; // Current command
                var vEncoder = robotTwist.Linear;
                var vHybrid = _velocityEstimator.EstimateVelocity(vCmd, vEncoder, dt);
                var confidence = _velocityEstimator.GetConfidence();
                
                // 5. Pure Pursuit: (v_hybrid, path) → ω
                var omega = _purePursuitController.Calculate(
                    robotState,
                    vHybrid,
                    confidence,
                    _referencePath
                );
                
                // 6. Combine velocities
                var vLinear = Math.Min(vMax, _parameters.Physical.MaxLinearVelocity);
                var omegaClamped = Math.Clamp(
                    omega,
                    -_parameters.Physical.MaxAngularVelocity,
                    _parameters.Physical.MaxAngularVelocity
                );
                
                // 7. Convert to wheel commands
                var (leftWheel, rightWheel) = DifferentialKinematics.