# LAYERS 4-5: ROBOT CONTROL & HARDWARE ABSTRACTION

**Document:** Part 3 of Robot Tuning System Architecture  
**Layers Covered:** Robot Control (Layer 4) and Hardware Abstraction (Layer 5)

---

## LAYER 4: ROBOT CONTROL

This layer contains the actual control algorithms that drive the robot. All controllers implement tunable interfaces to support dynamic parameter updates.

---

### 1. PID Controller

**File:** `Infrastructure/Controllers/PIDController.cs`

#### Interface Definition

```csharp
public interface IPIDController : ITunableController
{
    float Calculate(float error, float dt);
    void Reset();
    PIDState GetState();
}

public class PIDState
{
    public float ProportionalTerm { get; set; }
    public float IntegralTerm { get; set; }
    public float DerivativeTerm { get; set; }
    public float Output { get; set; }
    public float Error { get; set; }
    public float PreviousError { get; set; }
}
```

#### Implementation

```csharp
public class PIDController : IPIDController
{
    private VelocityPIDConfig _config;
    private float _integral;
    private float _previousError;
    private bool _firstRun = true;
    
    public PIDController(VelocityPIDConfig config)
    {
        _config = config;
    }
    
    public float Calculate(float error, float dt)
    {
        // Proportional term
        var pTerm = _config.Kp * error;
        
        // Integral term with anti-windup
        _integral += error * dt;
        _integral = Math.Clamp(
            _integral,
            -_config.IntegralWindupLimit,
            _config.IntegralWindupLimit
        );
        var iTerm = _config.Ki * _integral;
        
        // Derivative term with filtering
        float dTerm = 0;
        if (!_firstRun)
        {
            var derivative = (error - _previousError) / dt;
            dTerm = _config.Kd * derivative;
        }
        
        _firstRun = false;
        _previousError = error;
        
        // Combined output
        var output = pTerm + iTerm + dTerm;
        
        // Apply saturation if enabled
        if (_config.OutputSaturationEnabled)
        {
            output = Math.Clamp(
                output,
                _config.MinVelocity,
                _config.MaxVelocity
            );
        }
        
        return output;
    }
    
    public void Reset()
    {
        _integral = 0;
        _previousError = 0;
        _firstRun = true;
    }
    
    public void UpdateParameters(ParameterSet parameters)
    {
        _config = parameters.PID;
        // Optionally reset integral term when parameters change
        _integral = 0;
    }
    
    public ParameterSet GetCurrentParameters()
    {
        return new ParameterSet { PID = _config };
    }
    
    public PIDState GetState()
    {
        return new PIDState
        {
            ProportionalTerm = _config.Kp * _previousError,
            IntegralTerm = _config.Ki * _integral,
            DerivativeTerm = 0, // Would need to track
            Output = Calculate(_previousError, 0),
            Error = _previousError,
            PreviousError = _previousError
        };
    }
    
    public TelemetryData GetTelemetry()
    {
        var state = GetState();
        return new TelemetryData
        {
            ControllerType = "PID",
            Data = new Dictionary<string, float>
            {
                ["Error"] = state.Error,
                ["P_Term"] = state.ProportionalTerm,
                ["I_Term"] = state.IntegralTerm,
                ["D_Term"] = state.DerivativeTerm,
                ["Output"] = state.Output,
                ["Integral_Accumulator"] = _integral
            }
        };
    }
}
```

---

### 2. Velocity Estimator

**File:** `Infrastructure/Controllers/VelocityEstimator.cs`

#### Interface Definition

```csharp
public interface IVelocityEstimator : ITunableController
{
    float EstimateVelocity(float vCmd, float vActual, float dt);
    float GetConfidence();
    void Reset();
    EstimatorState GetState();
}

public class EstimatorState
{
    public float ModelVelocity { get; set; }
    public float EncoderVelocity { get; set; }
    public float FilteredEncoderVelocity { get; set; }
    public float HybridVelocity { get; set; }
    public float BlendRatio { get; set; }
    public float Confidence { get; set; }
    public float TrackingError { get; set; }
}
```

#### Implementation (Based on User's Formula)

```csharp
public class VelocityEstimator : IVelocityEstimator
{
    private VelocityEstimatorConfig _config;
    private VelocitySignalProcessingConfig _signalConfig;
    
    // State variables
    private float _filteredEncoderVel;
    private float _confidence = 1.0f;
    private float _blendRatio;
    
    // Model parameters (from user's code)
    private const float Tau = 0.3f;      // Time constant for first-order model
    private const float Delta = 0.05f;   // System delay
    
    public VelocityEstimator(
        VelocityEstimatorConfig config,
        VelocitySignalProcessingConfig signalConfig)
    {
        _config = config;
        _signalConfig = signalConfig;
        _blendRatio = config.DefaultBlendRatio;
    }
    
    public float EstimateVelocity(float vCmd, float vActual, float dt)
    {
        // 1. Filter encoder velocity (exponential moving average)
        _filteredEncoderVel = _signalConfig.AlphaFilter * vActual +
                              (1 - _signalConfig.AlphaFilter) * _filteredEncoderVel;
        
        // 2. Predict velocity using model (user's formula)
        var timeAhead = dt;
        float vModel;
        
        if (timeAhead < Delta)
        {
            vModel = vActual;
        }
        else
        {
            var effectiveTime = timeAhead - Delta;
            var response = 1.0f - MathF.Exp(-effectiveTime / Tau);
            vModel = vActual + (vCmd - vActual) * response;
        }
        
        // 3. Calculate tracking error
        var trackingError = Math.Abs(vModel - vActual) / 
                           (Math.Abs(vActual) + 0.01f); // Avoid division by zero
        
        // 4. Adaptive blending based on tracking quality
        _blendRatio = CalculateBlendRatio(trackingError);
        
        // 5. Update confidence
        UpdateConfidence(trackingError);
        
        // 6. Hybrid estimation
        var vHybrid = _blendRatio * vModel + (1 - _blendRatio) * _filteredEncoderVel;
        
        return vHybrid;
    }
    
    private float CalculateBlendRatio(float trackingError)
    {
        if (trackingError < _config.GoodTrackingThreshold)
        {
            // Good tracking → trust encoder more
            return _config.GoodTrackingBlend;
        }
        else if (trackingError < _config.ModerateTrackingThreshold)
        {
            // Moderate tracking → balanced
            return _config.ModerateTrackingBlend;
        }
        else
        {
            // Poor tracking (possible wheel slip) → trust model more
            return _config.PoorTrackingBlend;
        }
    }
    
    private void UpdateConfidence(float trackingError)
    {
        if (trackingError < _config.GoodTrackingThreshold)
        {
            // Increase confidence (but cap at 1.0)
            _confidence = Math.Min(1.0f, _confidence + 0.01f);
        }
        else
        {
            // Decay confidence
            _confidence *= _config.ConfidenceDecayRate;
            _confidence = Math.Max(_config.MinConfidence, _confidence);
        }
    }
    
    public float GetConfidence()
    {
        return _confidence;
    }
    
    public void Reset()
    {
        _filteredEncoderVel = 0;
        _confidence = 1.0f;
        _blendRatio = _config.DefaultBlendRatio;
    }
    
    public void UpdateParameters(ParameterSet parameters)
    {
        _config = parameters.Estimator;
        _signalConfig = parameters.SignalProcessing;
    }
    
    public EstimatorState GetState()
    {
        return new EstimatorState
        {
            EncoderVelocity = _filteredEncoderVel,
            FilteredEncoderVelocity = _filteredEncoderVel,
            BlendRatio = _blendRatio,
            Confidence = _confidence
        };
    }
    
    public TelemetryData GetTelemetry()
    {
        var state = GetState();
        return new TelemetryData
        {
            ControllerType = "VelocityEstimator",
            Data = new Dictionary<string, float>
            {
                ["Encoder_Velocity"] = state.EncoderVelocity,
                ["Filtered_Encoder"] = state.FilteredEncoderVelocity,
                ["Hybrid_Velocity"] = state.HybridVelocity,
                ["Blend_Ratio"] = state.BlendRatio,
                ["Confidence"] = state.Confidence
            }
        };
    }
}
```

---

### 3. Pure Pursuit Controller

**File:** `Infrastructure/Controllers/PurePursuitController.cs`

#### Interface Definition

```csharp
public interface IPurePursuitController : ITunableController
{
    float Calculate(
        Pose2D robotPose,
        float velocity,
        float confidence,
        Path referencePath
    );
    
    Vector2 GetTargetPoint();
    float GetLookaheadDistance();
    PurePursuitState GetState();
}

public class PurePursuitState
{
    public Vector2 TargetPoint { get; set; }
    public float LookaheadDistance { get; set; }
    public float Curvature { get; set; }
    public float AngularVelocity { get; set; }
}
```

#### Implementation (Based on User's Formula)

```csharp
public class PurePursuitController : IPurePursuitController
{
    private PurePursuitConfig _config;
    private Vector2 _targetPoint;
    private float _lookaheadDistance;
    
    public PurePursuitController(PurePursuitConfig config)
    {
        _config = config;
    }
    
    public float Calculate(
        Pose2D robotPose,
        float velocity,
        float confidence,
        Path referencePath)
    {
        // 1. Calculate lookahead distance (user's formula)
        _lookaheadDistance = _config.LookaheadMin + _config.Kdd * Math.Abs(velocity);
        _lookaheadDistance = Math.Clamp(
            _lookaheadDistance,
            _config.LookaheadMin,
            _config.LookaheadMax
        );
        
        // 2. Adjust lookahead based on confidence
        _lookaheadDistance *= confidence;
        _lookaheadDistance = Math.Clamp(
            _lookaheadDistance,
            _config.LookaheadMin * 0.5f,
            _config.LookaheadMax
        );
        
        // 3. Find target point on path
        _targetPoint = FindTargetPoint(robotPose.Position, referencePath);
        
        // 4. Transform target to robot frame
        var targetLocal = TransformToRobotFrame(robotPose, _targetPoint);
        
        // 5. Calculate curvature (Pure Pursuit formula)
        // κ = 2 * x / L where x is lateral offset, L is lookahead
        var curvature = 2.0f * targetLocal.Y / 
                       (_lookaheadDistance * _lookaheadDistance);
        
        // 6. Calculate angular velocity: ω = v * κ
        var omega = velocity * curvature;
        
        return omega;
    }
    
    private Vector2 FindTargetPoint(Vector2 robotPos, Path referencePath)
    {
        // Find point on path that is approximately lookahead distance ahead
        var closestPoint = referencePath.GetClosestPoint(robotPos);
        var distanceAlongPath = closestPoint.DistanceFromStart;
        
        // Look ahead
        var targetDistance = distanceAlongPath + _lookaheadDistance;
        
        // Handle end of path
        if (targetDistance >= referencePath.TotalLength)
        {
            return referencePath.Points.Last().Position;
        }
        
        var targetPathPoint = referencePath.GetPointAtDistance(targetDistance);
        return targetPathPoint.Position;
    }
    
    private Vector2 TransformToRobotFrame(Pose2D robotPose, Vector2 worldPoint)
    {
        // Translate to robot origin
        var translated = worldPoint - robotPose.Position;
        
        // Rotate by -heading to align with robot frame
        var cos = MathF.Cos(-robotPose.Heading);
        var sin = MathF.Sin(-robotPose.Heading);
        
        return new Vector2(
            translated.X * cos - translated.Y * sin,
            translated.X * sin + translated.Y * cos
        );
    }
    
    public Vector2 GetTargetPoint() => _targetPoint;
    public float GetLookaheadDistance() => _lookaheadDistance;
    
    public void UpdateParameters(ParameterSet parameters)
    {
        _config = parameters.PurePursuit;
    }
    
    public PurePursuitState GetState()
    {
        return new PurePursuitState
        {
            TargetPoint = _targetPoint,
            LookaheadDistance = _lookaheadDistance
        };
    }
    
    public TelemetryData GetTelemetry()
    {
        var state = GetState();
        return new TelemetryData
        {
            ControllerType = "PurePursuit",
            Data = new Dictionary<string, float>
            {
                ["Lookahead_Distance"] = state.LookaheadDistance,
                ["Target_X"] = state.TargetPoint.X,
                ["Target_Y"] = state.TargetPoint.Y,
                ["Curvature"] = state.Curvature,
                ["Angular_Velocity"] = state.AngularVelocity
            }
        };
    }
}
```

---

### 4. Data Logger

**File:** `Infrastructure/Logging/DataLogger.cs`

#### Interface Definition

```csharp
public interface IDataLogger
{
    Task StartLoggingAsync(string testId);
    void LogCycle(ControlCycleData data);
    Task<string> StopLoggingAsync();
    Task<List<ControlCycleData>> LoadLogAsync(string filePath);
}
```

#### Implementation with High-Frequency Logging

```csharp
public class DataLogger : IDataLogger
{
    private readonly string _logDirectory;
    private BlockingCollection<ControlCycleData> _buffer;
    private Task _writerTask;
    private CancellationTokenSource _cts;
    private string _currentLogFile;
    
    public DataLogger(string logDirectory)
    {
        _logDirectory = logDirectory;
        Directory.CreateDirectory(logDirectory);
    }
    
    public Task StartLoggingAsync(string testId)
    {
        _currentLogFile = Path.Combine(
            _logDirectory,
            $"test_{testId}_{DateTime.UtcNow:yyyyMMdd_HHmmss}.msgpack"
        );
        
        _buffer = new BlockingCollection<ControlCycleData>(
            boundedCapacity: 10000  // Buffer up to 10k samples (200 seconds at 50Hz)
        );
        
        _cts = new CancellationTokenSource();
        
        // Start async writer task
        _writerTask = Task.Run(async () => await WriteLoopAsync(_cts.Token));
        
        return Task.CompletedTask;
    }
    
    public void LogCycle(ControlCycleData data)
    {
        // Non-blocking add to buffer
        if (!_buffer.TryAdd(data, millisecondsTimeout: 10))
        {
            // Buffer full - drop oldest data (or implement overflow strategy)
            Console.WriteLine("WARNING: Data logger buffer overflow");
        }
    }
    
    public async Task<string> StopLoggingAsync()
    {
        // Signal completion
        _buffer.CompleteAdding();
        
        // Wait for writer to flush all data
        await _writerTask;
        
        _cts.Dispose();
        
        return _currentLogFile;
    }
    
    private async Task WriteLoopAsync(CancellationToken cancellationToken)
    {
        using var fileStream = File.OpenWrite(_currentLogFile);
        
        // Write header
        var header = new LogFileHeader
        {
            Version = 1,
            Frequency = 50,
            StartTime = DateTime.UtcNow
        };
        await MessagePackSerializer.SerializeAsync(fileStream, header);
        
        // Write data as it arrives
        foreach (var data in _buffer.GetConsumingEnumerable(cancellationToken))
        {
            await MessagePackSerializer.SerializeAsync(fileStream, data);
        }
        
        await fileStream.FlushAsync();
    }
    
    public async Task<List<ControlCycleData>> LoadLogAsync(string filePath)
    {
        var data = new List<ControlCycleData>();
        
        using var fileStream = File.OpenRead(filePath);
        
        // Read header
        var header = await MessagePackSerializer.DeserializeAsync<LogFileHeader>(fileStream);
        
        // Read all data
        while (fileStream.Position < fileStream.Length)
        {
            var cycle = await MessagePackSerializer.DeserializeAsync<ControlCycleData>(fileStream);
            data.Add(cycle);
        }
        
        return data;
    }
}
```

---

### 5. Safety Monitor

**File:** `Infrastructure/Safety/SafetyMonitor.cs`

#### Interface Definition

```csharp
public interface ISafetyMonitor
{
    bool CheckSafety(RobotState state, Path referencePath);
    List<SafetyViolation> GetViolations();
    void Reset();
}
```

#### Implementation

```csharp
public class SafetyMonitor : ISafetyMonitor
{
    private readonly SafetyConfig _config;
    private readonly List<SafetyViolation> _violations = new();
    private DateTime? _trackingErrorStart;
    
    public SafetyMonitor(SafetyConfig config)
    {
        _config = config;
    }
    
    public bool CheckSafety(RobotState state, Path referencePath)
    {
        var isSafe = true;
        
        // 1. Check cross-track error
        var closestPoint = referencePath.GetClosestPoint(state.Position);
        var cte = Vector2.Distance(state.Position, closestPoint.Position);
        
        if (cte > _config.MaxCrossTrackError)
        {
            LogViolation(new SafetyViolation
            {
                Type = ViolationType.CrossTrackError,
                Severity = ViolationSeverity.Critical,
                Value = cte,
                Threshold = _config.MaxCrossTrackError,
                Message = $"CTE {cte:F3}m exceeds limit {_config.MaxCrossTrackError:F3}m"
            });
            isSafe = false;
        }
        
        // 2. Check heading error
        var pathHeading = closestPoint.Tangent.Angle();
        var headingError = Math.Abs(NormalizeAngle(state.Heading - pathHeading));
        
        if (headingError > _config.MaxHeadingError)
        {
            LogViolation(new SafetyViolation
            {
                Type = ViolationType.HeadingError,
                Severity = ViolationSeverity.Critical,
                Value = headingError,
                Threshold = _config.MaxHeadingError,
                Message = $"Heading error {headingError * 180 / MathF.PI:F1}° exceeds limit"
            });
            isSafe = false;
        }
        
        // 3. Check velocity limits
        if (Math.Abs(state.LinearVelocity) > _config.MaxLinearVelocity * 1.1f)
        {
            LogViolation(new SafetyViolation
            {
                Type = ViolationType.VelocityLimit,
                Severity = ViolationSeverity.Warning,
                Value = state.LinearVelocity,
                Threshold = _config.MaxLinearVelocity,
                Message = $"Linear velocity {state.LinearVelocity:F2} m/s exceeds limit"
            });
        }
        
        // 4. Check sustained tracking error
        if (cte > _config.MaxCrossTrackError * 0.5f)
        {
            _trackingErrorStart ??= DateTime.UtcNow;
            
            var duration = (DateTime.UtcNow - _trackingErrorStart.Value).TotalMilliseconds;
            if (duration > _config.MaxTrackingErrorDuration)
            {
                LogViolation(new SafetyViolation
                {
                    Type = ViolationType.SustainedTrackingError,
                    Severity = ViolationSeverity.Critical,
                    Value = (float)duration,
                    Threshold = _config.MaxTrackingErrorDuration,
                    Message = $"Tracking error sustained for {duration:F0}ms"
                });
                isSafe = false;
            }
        }
        else
        {
            _trackingErrorStart = null;
        }
        
        return isSafe;
    }
    
    private void LogViolation(SafetyViolation violation)
    {
        violation.Timestamp = DateTime.UtcNow;
        _violations.Add(violation);
    }
    
    public List<SafetyViolation> GetViolations() => _violations;
    
    public void Reset()
    {
        _violations.Clear();
        _trackingErrorStart = null;
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

## LAYER 5: HARDWARE ABSTRACTION

This layer provides interfaces to physical hardware. Implementations will vary based on actual robot hardware.

---

### 1. Motor Driver Interface

**File:** `Infrastructure/Hardware/IMotorDriver.cs`

```csharp
public interface IMotorDriver
{
    // Initialization
    Task InitializeAsync();
    Task ShutdownAsync();
    
    // Commands
    void SetVelocity(float leftWheelVelocity, float rightWheelVelocity);
    void SetVelocityRampRate(float maxAcceleration);
    void Stop();
    void EmergencyStop();
    
    // Status
    MotorStatus GetStatus();
    bool IsReady();
    bool IsError();
    string GetErrorMessage();
    
    // Configuration
    void SetMaxVelocity(float maxVel);
    void SetAccelerationLimit(float maxAccel);
    void EnableSoftStart(bool enable);
}

public class MotorStatus
{
    public bool IsReady { get; set; }
    public bool IsMoving { get; set; }
    public bool IsError { get; set; }
    public float LeftWheelActualVelocity { get; set; }
    public float RightWheelActualVelocity { get; set; }
    public float LeftWheelCurrent { get; set; }
    public float RightWheelCurrent { get; set; }
    public float BatteryVoltage { get; set; }
}
```

#### Example Implementation (Mock for Testing)

```csharp
public class MockMotorDriver : IMotorDriver
{
    private float _leftCmd, _rightCmd;
    private float _leftActual, _rightActual;
    private bool _isReady = true;
    private float _maxAccel = 1.0f;
    
    public Task InitializeAsync()
    {
        Console.WriteLine("MockMotorDriver: Initialized");
        return Task.CompletedTask;
    }
    
    public void SetVelocity(float leftWheelVelocity, float rightWheelVelocity)
    {
        _leftCmd = leftWheelVelocity;
        _rightCmd = rightWheelVelocity;
        
        // Simulate first-order lag
        _leftActual += (_leftCmd - _leftActual) * 0.3f;
        _rightActual += (_rightCmd - _rightActual) * 0.3f;
    }
    
    public void Stop()
    {
        SetVelocity(0, 0);
    }
    
    public void EmergencyStop()
    {
        _leftCmd = _rightCmd = 0;
        _leftActual = _rightActual = 0;
        Console.WriteLine("MockMotorDriver: EMERGENCY STOP");
    }
    
    public MotorStatus GetStatus()
    {
        return new MotorStatus
        {
            IsReady = _isReady,
            IsMoving = Math.Abs(_leftActual) > 0.01f || Math.Abs(_rightActual) > 0.01f,
            LeftWheelActualVelocity = _leftActual,
            RightWheelActualVelocity = _rightActual,
            BatteryVoltage = 24.0f
        };
    }
    
    public bool IsReady() => _isReady;
    public bool IsError() => false;
    public string GetErrorMessage() => "";
    
    public void SetMaxVelocity(float maxVel) { }
    public void SetAccelerationLimit(float maxAccel) => _maxAccel = maxAccel;
    public void SetVelocityRampRate(float maxAcceleration) => _maxAccel = maxAcceleration;
    public void EnableSoftStart(bool enable) { }
    public Task ShutdownAsync() => Task.CompletedTask;
}
```

---

### 2. Encoder Reader Interface

**File:** `Infrastructure/Hardware/IEncoderReader.cs`

```csharp
public interface IEncoderReader
{
    // Initialization
    Task InitializeAsync();
    Task ShutdownAsync();
    
    // Reading
    EncoderData ReadEncoders();
    (float left, float right) GetWheelVelocities();
    (int left, int right) GetCounts();
    
    // Configuration
    void SetResolution(int pulsesPerRevolution);
    void SetWheelRadius(float radius);
    void ResetCounters();
    
    // Calibration
    Task CalibrateAsync();
    EncoderCalibration GetCalibration();
}

[MessagePackObject]
public class EncoderData
{
    [Key(0)]
    public long TimestampMs { get; set; }
    
    [Key(1)]
    public int LeftCount { get; set; }
    
    [Key(2)]
    public int RightCount { get; set; }
    
    [Key(3)]
    public float LeftVelocity { get; set; }  // m/s
    
    [Key(4)]
    public float RightVelocity { get; set; } // m/s
    
    [Key(5)]
    public float DeltaTime { get; set; }     // seconds since last read
}

public class EncoderCalibration
{
    public float LeftScale { get; set; } = 1.0f;
    public float RightScale { get; set; } = 1.0f;
    public float LeftOffset { get; set; } = 0.0f;
    public float RightOffset { get; set; } = 0.0f;
}
```

---

### 3. Robot State Manager

**File:** `Infrastructure/State/RobotStateManager.cs`

```csharp
public interface IRobotStateManager
{
    // Odometry
    Pose2D GetCurrentPose();
    Twist2D GetCurrentTwist();
    void ResetPose(Pose2D initialPose);
    
    // Updates
    void UpdateFromEncoders(EncoderData encoderData, float dt);
    void UpdateFromIMU(IMUData imuData); // Optional
    
    // Transforms
    Vector2 RobotToWorld(Vector2 localPoint);
    Vector2 WorldToRobot(Vector2 worldPoint);
    float GetTotalDistance();
}

[MessagePackObject]
public struct Pose2D
{
    [Key(0)]
    public Vector2 Position { get; set; }
    
    [Key(1)]
    public float Heading { get; set; }  // radians
    
    public Pose2D(float x, float y, float heading)
    {
        Position = new Vector2(x, y);
        Heading = heading;
    }
}

[MessagePackObject]
public struct Twist2D
{
    [Key(0)]
    public float Linear { get; set; }   // m/s
    
    [Key(1)]
    public float Angular { get; set; }  // rad/s
}
```

#### Implementation

```csharp
public class RobotStateManager : IRobotStateManager
{
    private readonly RobotPhysicalConfig _config;
    private Pose2D _pose;
    private Twist2D _twist;
    private float _totalDistance;
    
    public RobotStateManager(RobotPhysicalConfig config)
    {
        _config = config;
        _pose = new Pose2D(0, 0, 0);
    }
    
    public void UpdateFromEncoders(EncoderData encoderData, float dt)
    {
        // Differential drive kinematics
        // v = (v_left + v_right) / 2
        // ω = (v_right - v_left) / wheelbase
        
        var vLeft = encoderData.LeftVelocity;