# ROBOT TUNING SYSTEM - COMPLETE ARCHITECTURE DOCUMENT

**Version:** 1.0  
**Date:** 2026-01-26  
**Target Platform:** .NET 10 + Blazor  
**Robot Type:** Differential Drive Mobile Robot  

---

## TABLE OF CONTENTS

1. [Executive Summary](#1-executive-summary)
2. [System Context](#2-system-context)
3. [Requirements](#3-requirements)
4. [Architecture Overview](#4-architecture-overview)
5. [Layer 1: Presentation (Blazor Dashboard)](#5-layer-1-presentation)
6. [Layer 2: Application Services](#6-layer-2-application-services)
7. [Layer 3: Domain Logic](#7-layer-3-domain-logic)
8. [Layer 4: Robot Control](#8-layer-4-robot-control)
9. [Layer 5: Hardware Abstraction](#9-layer-5-hardware-abstraction)
10. [Data Models](#10-data-models)
11. [Database Schema](#11-database-schema)
12. [Control Flow & Data Flow](#12-control-flow-data-flow)
13. [Configuration Management](#13-configuration-management)
14. [Tuning Workflows](#14-tuning-workflows)
15. [Technology Stack](#15-technology-stack)
16. [Deployment Architecture](#16-deployment-architecture)
17. [Implementation Phases](#17-implementation-phases)
18. [API Specifications](#18-api-specifications)
19. [Performance Requirements](#19-performance-requirements)
20. [Security & Safety](#20-security-safety)
21. [Testing Strategy](#21-testing-strategy)
22. [Appendices](#22-appendices)

---

## 1. EXECUTIVE SUMMARY

### 1.1. Purpose
This document defines the complete architecture for a **Robot Tuning System** designed to optimize control parameters for differential drive mobile robots. The system enables:
- Interactive parameter tuning via web dashboard
- Automated test execution and performance evaluation
- Comparative analysis of parameter configurations
- Historical tracking and reporting

### 1.2. System Goals
**Primary Goal:** Find optimal parameter sets for PID velocity control, Pure Pursuit path tracking, and Velocity Estimator that minimize tracking error while maintaining smooth motion.

**Secondary Goals:**
- Reduce tuning time from days to hours
- Enable reproducible, data-driven parameter selection
- Support multiple test scenarios (straight lines, circles, complex paths)
- Provide intuitive visualization and analysis tools

### 1.3. Key Stakeholders
- **Robot Developers:** Configure and tune robot behavior
- **Test Engineers:** Run validation tests and generate reports
- **AI Systems:** Process and analyze this architecture document

### 1.4. Success Metrics
- **Tracking Accuracy:** Cross-track error RMS < 10cm
- **Smoothness:** Max jerk < 5 m/s³
- **Efficiency:** Path length ratio < 1.15
- **Tuning Speed:** Find acceptable parameters within 2 hours
- **Reproducibility:** Result variance < 5% across runs

---

## 2. SYSTEM CONTEXT

### 2.1. Robot Overview

**Robot Type:** Differential Drive Mobile Robot  
**Physical Characteristics:**
- Wheelbase: 0.35m (distance between left/right wheels)
- Wheel radius: 0.075m
- Mass: ~25kg
- Max linear velocity: 1.5 m/s
- Max angular velocity: 6 rad/s
- Max linear acceleration: 1.0 m/s- Max angular acceleration: 1.0 rad/s
**Operating Environment:**
- Indoor spaces (smooth floors)
- Test area: 10m × 20m
- No dynamic obstacles during tuning

### 2.2. Control System Architecture

The robot uses a **hierarchical control structure**:

```
Goal Position
    ↓
[Distance-based PID] → Linear Velocity (v_max)
    ↓
[Velocity Estimator] → Estimated Velocity (v_hybrid)
    ↓                          ↓
    └───────→ [Pure Pursuit] ←─┘
                  ↓
            Angular Velocity (ω)
                  ↓
    [Combine (v_max, ω)] → (v_cmd, ω_cmd)
                  ↓
    [Differential Kinematics] → (wheel_left, wheel_right)
                  ↓
            Motor Commands
```

**Controller Descriptions:**

1. **Distance-based PID Controller:**
   - **Input:** Distance to goal (error = distance_to_goal)
   - **Output:** Maximum linear velocity (v_max)
   - **Logic:** 
     - If distance > 5m: return max velocity (1.5 m/s)
     - If distance ≤ 5m: PID control
     - If velocity < min velocity: return min velocity
   - **Parameters to tune:** Kp, Ki, Kd

2. **Velocity Estimator:**
   - **Purpose:** Combine encoder measurements with kinematic model for accurate velocity estimation
   - **Method:** Adaptive blending based on tracking quality
   - **Model:** First-order system response
     ```
     v_predicted = v_actual + (v_cmd - v_actual) × (1 - e^(-t_eff/τ))
     where t_eff = t_ahead - delay
     ```
   - **Blending:** 
     ```
     v_hybrid = blend_ratio × v_model + (1 - blend_ratio) × v_encoder
     ```
   - **Adaptive Logic:**
     - Good tracking (error < 12%): blend_ratio = 0.3 (trust encoder 70%)
     - Moderate tracking (error < 30%): blend_ratio = 0.5
     - Poor tracking (error ≥ 30%): blend_ratio = 0.7 (trust model 70%)
   - **Parameters to tune:** AlphaFilter, blend ratios, confidence decay rate

3. **Pure Pursuit Controller:**
   - **Input:** Current position, v_hybrid, reference path
   - **Output:** Angular velocity (ω)
   - **Lookahead calculation:**
     ```
     lookahead = clamp(
         LookaheadMin + Kdd × |v_hybrid|,
         LookaheadMin,
         LookaheadMax
     )
     lookahead *= confidence  // Reduce if estimator confidence is low
     ```
   - **Parameters to tune:** Kdd, LookaheadMin, LookaheadMax

### 2.3. Tuning Challenges

**Current State:**
- Manual tuning takes days per robot
- No systematic approach to parameter selection
- Difficult to validate performance across scenarios
- Parameters tuned for one trajectory may fail on others

**Desired State:**
- Semi-automated tuning process
- Data-driven parameter optimization
- Cross-scenario validation
- Reproducible results with confidence metrics

---

## 3. REQUIREMENTS

### 3.1. Functional Requirements

**FR-1: Test Execution**
- FR-1.1: System shall execute single test runs with specified parameters
- FR-1.2: System shall execute batch tests across multiple configurations
- FR-1.3: System shall support at least 3 trajectory types: straight line, large circle (2m radius), small circle (0.5m radius)
- FR-1.4: System shall log all telemetry data at 50Hz during test execution
- FR-1.5: System shall detect and abort tests on safety violations

**FR-2: Parameter Management**
- FR-2.1: System shall allow users to configure all tunable parameters via UI
- FR-2.2: System shall validate parameters against physical constraints
- FR-2.3: System shall save/load parameter configurations with versioning
- FR-2.4: System shall support parameter presets (default, aggressive, smooth)

**FR-3: Metrics & Analysis**
- FR-3.1: System shall calculate tracking accuracy metrics (CTE RMS, heading error)
- FR-3.2: System shall calculate smoothness metrics (jerk, velocity variance)
- FR-3.3: System shall calculate efficiency metrics (path length ratio, time)
- FR-3.4: System shall compute overall score based on weighted metrics
- FR-3.5: System shall compare multiple configurations side-by-side

**FR-4: Visualization**
- FR-4.1: System shall display real-time 2D trajectory during test execution
- FR-4.2: System shall stream live telemetry charts (velocity, CTE, etc.)
- FR-4.3: System shall visualize post-test analysis with interactive charts
- FR-4.4: System shall support trajectory replay from logged data

**FR-5: Reporting**
- FR-5.1: System shall export test results to CSV format
- FR-5.2: System shall generate HTML summary reports
- FR-5.3: System shall maintain test history in database

**FR-6: Safety**
- FR-6.1: System shall monitor cross-track error continuously
- FR-6.2: System shall trigger emergency stop if CTE > 0.5m
- FR-6.3: System shall trigger emergency stop if heading error > 45°
- FR-6.4: System shall log all safety violations with timestamps

### 3.2. Non-Functional Requirements

**NFR-1: Performance**
- NFR-1.1: Control loop shall execute at 50Hz (±2ms jitter)
- NFR-1.2: UI updates shall occur at ≥10Hz with <200ms lag
- NFR-1.3: Data logging shall not impact control loop performance
- NFR-1.4: Test completion time shall be <2× trajectory duration

**NFR-2: Usability**
- NFR-2.1: Non-technical users shall be able to run basic tests
- NFR-2.2: Parameter controls shall provide immediate visual feedback
- NFR-2.3: Error messages shall be clear and actionable
- NFR-2.4: Dashboard shall be accessible via web browser

**NFR-3: Reliability**
- NFR-3.1: System shall recover from SignalR disconnections automatically
- NFR-3.2: Test data shall not be lost on application crash
- NFR-3.3: System shall handle encoder noise and wheel slip gracefully

**NFR-4: Maintainability**
- NFR-4.1: Code shall follow SOLID principles
- NFR-4.2: Each layer shall have clear interfaces and minimal coupling
- NFR-4.3: Unit test coverage shall be >80% for domain logic

**NFR-5: Scalability**
- NFR-5.1: System shall support multiple test scenarios (target: 10+)
- NFR-5.2: Database shall handle 1000+ test runs without degradation
- NFR-5.3: Architecture shall allow future addition of optimization algorithms

### 3.3. Acceptance Criteria

**Primary Metric (Tracking Accuracy):**
- Cross-track error RMS < 0.10m (10cm)
- Cross-track error peak < 0.20m (20cm)
- Heading error RMS < 10° (0.174 rad)
- Goal position error < 0.05m (5cm)

**Secondary Metric (Smoothness):**
- Max jerk < 5.0 m/s³
- Max angular jerk < 10.0 rad/s³
- Velocity standard deviation < 0.15 m/s

**Tertiary Metric (Efficiency):**
- Path length ratio < 1.15 (actual path < 115% of optimal)
- Success rate > 90% (9 out of 10 runs pass)

---

## 4. ARCHITECTURE OVERVIEW

### 4.1. Architectural Style
**Layered Architecture** with clean separation between presentation, application logic, domain logic, and infrastructure.

**Key Patterns:**
- **Repository Pattern:** Data access abstraction
- **Service Layer Pattern:** Application-level orchestration
- **Domain-Driven Design:** Rich domain models
- **CQRS (Light):** Separate read/write models for optimization
- **Event-Driven:** Real-time updates via SignalR

### 4.2. Layer Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│ LAYER 1: PRESENTATION                                                │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ Blazor Dashboard (Web UI)                                        │ │
│ │ - Real-time Monitoring Pages                                    │ │
│ │ - Parameter Tuning Controls                                     │ │
│ │ - Analysis & Visualization                                      │ │
│ │ - Configuration Management                                      │ │
│ └─────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────┬─────────────────────────────────────┘
                                │ SignalR Hubs / REST API
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ LAYER 2: APPLICATION SERVICES                                        │
│ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│ │   Tuning     │  │  Parameter   │  │   Metric     │              │
│ │ Orchestrator │  │   Manager    │  │  Analyzer    │              │
│ └──────────────┘  └──────────────┘  └──────────────┘              │
│ ┌──────────────┐  ┌──────────────┐                                 │
│ │    Report    │  │    Event     │                                 │
│ │  Generator   │  │  Publisher   │                                 │
│ └──────────────┘  └──────────────┘                                 │
└───────────────────────────────┬─────────────────────────────────────┘
                                │ Domain Interfaces
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ LAYER 3: DOMAIN LOGIC                                                │
│ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│ │     Test     │  │  Trajectory  │  │  Parameter   │              │
│ │   Executor   │  │  Generator   │  │  Optimizer   │              │
│ └──────────────┘  └──────────────┘  └──────────────┘              │
│ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│ │    Metric    │  │    Safety    │  │   Scoring    │              │
│ │  Calculator  │  │   Monitor    │  │    Engine    │              │
│ └──────────────┘  └──────────────┘  └──────────────┘              │
└───────────────────────────────┬─────────────────────────────────────┘
                                │ Control Interfaces
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ LAYER 4: ROBOT CONTROL                                               │
│ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│ │     PID      │  │   Velocity   │  │     Pure     │              │
│ │  Controller  │  │  Estimator   │  │   Pursuit    │              │
│ └──────────────┘  └──────────────┘  └──────────────┘              │
│ ┌──────────────┐  ┌──────────────┐                                 │
│ │     Data     │  │    State     │                                 │
│ │    Logger    │  │   Manager    │                                 │
│ └──────────────┘  └──────────────┘                                 │
└───────────────────────────────┬─────────────────────────────────────┘
                                │ Hardware Interfaces
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ LAYER 5: HARDWARE ABSTRACTION                                        │
│ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│ │    Motor     │  │   Encoder    │  │    Robot     │              │
│ │    Driver    │  │    Reader    │  │    State     │              │
│ └──────────────┘  └──────────────┘  └──────────────┘              │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                ▼
                        [Physical Hardware]
                        - Motors
                        - Encoders
                        - Emergency Stop
```

### 4.3. Component Interactions

**Typical Test Execution Flow:**

```
User → UI → TuningOrchestrator → TestExecutor → Controllers → Hardware
                ↓                      ↓             ↓
           ParameterManager      SafetyMonitor   DataLogger
                                       ↓             ↓
                                   [Abort?]      [Database]
                                                     ↓
UI ← SignalR ← EventPublisher ← MetricAnalyzer ← [Results]
```

### 4.4. Project Structure

```
RobotTuning.sln
├── src/
│   ├── RobotTuning.Domain/              # Layer 3: Domain Logic
│   │   ├── Models/                       # Domain entities
│   │   ├── Services/                     # Domain services
│   │   ├── Interfaces/                   # Abstractions
│   │   └── ValueObjects/                 # Value objects
│   │
│   ├── RobotTuning.Application/          # Layer 2: Application Services
│   │   ├── Services/                     # Orchestrators, managers
│   │   ├── DTOs/                         # Data transfer objects
│   │   ├── Interfaces/                   # Service contracts
│   │   └── Mapping/                      # AutoMapper profiles
│   │
│   ├── RobotTuning.Infrastructure/       # Layer 4 & 5: Control & Hardware
│   │   ├── Controllers/                  # PID, Estimator, PurePursuit
│   │   ├── Hardware/                     # Motor drivers, encoder readers
│   │   ├── Logging/                      # Data logger implementation
│   │   ├── Persistence/                  # Database context, repositories
│   │   └── Configuration/                # Config file handling
│   │
│   ├── RobotTuning.Web/                  # Layer 1: Presentation
│   │   ├── Pages/                        # Blazor pages
│   │   ├── Components/                   # Reusable UI components
│   │   ├── Hubs/                         # SignalR hubs
│   │   ├── wwwroot/                      # Static files, JS libraries
│   │   └── Program.cs                    # Application entry point
│   │
│   └── RobotTuning.Shared/               # Shared utilities
│       ├── Constants/
│       ├── Extensions/
│       └── Helpers/
│
└── tests/
    ├── RobotTuning.Domain.Tests/
    ├── RobotTuning.Application.Tests/
    └── RobotTuning.Integration.Tests/
```

---

## 5. LAYER 1: PRESENTATION

### 5.1. Page Structure

```
/Pages
├── Index.razor                          # Landing page
├── Dashboard/
│   ├── RealTimeMonitor.razor            # Live test monitoring
│   │   ├── TrajectoryView.razor         # 2D path visualization
│   │   ├── TelemetryPanel.razor         # Live metrics
│   │   └── StatusIndicators.razor       # State, warnings
│   └── LiveCharts.razor                 # Streaming charts
├── Tuning/
│   ├── ManualTuning.razor               # Interactive parameter adjustment
│   │   ├── ParameterSliders.razor       # PID, PP, Estimator controls
│   │   ├── QuickActions.razor           # Run, Stop, Reset buttons
│   │   └── SuggestionPanel.razor        # AI-powered suggestions
│   ├── AutoTuning.razor                 # Automated optimization
│   │   ├── OptimizationConfig.razor     # Algorithm selection, constraints
│   │   └── ProgressView.razor           # Optimization progress
│   └── ParameterComparison.razor        # A/B testing
│       ├── ConfigSelector.razor         # Select configs to compare
│       ├── ComparisonTable.razor        # Side-by-side metrics
│       └── ComparisonCharts.razor       # Visual comparison
├── Analysis/
│   ├── MetricsAnalysis.razor            # Deep-dive metrics
│   │   ├── TrackingAccuracy.razor       # CTE, heading analysis
│   │   ├── SmoothnessAnalysis.razor     # Jerk, acceleration plots
│   │   └── EfficiencyAnalysis.razor     # Path length, time metrics
│   ├── TrajectoryVisualization.razor    # Post-test trajectory viewer
│   │   ├── PathOverlay.razor            # Actual vs reference path
│   │   ├── ErrorHeatmap.razor           # CTE along path
│   │   └── PlaybackControls.razor       # Replay timeline
│   └── PerformanceReport.razor          # Summary reports
│       ├── ScoreCard.razor              # Overall scores
│       ├── MetricsSummary.razor         # Key metrics table
│       └── ExportOptions.razor          # PDF, CSV export
├── Configuration/
│   ├── TestScenarios.razor              # Define test trajectories
│   │   ├── TrajectoryBuilder.razor      # Visual trajectory editor
│   │   └── ScenarioLibrary.razor        # Saved scenarios
│   ├── RobotSettings.razor              # Physical parameters
│   │   ├── PhysicalParams.razor         # Wheelbase, mass, etc.
│   │   └── TimingConfig.razor           # Control loop frequency
│   └── AcceptanceCriteria.razor         # Pass/fail thresholds
│       ├── MetricThresholds.razor       # Set limits
│       └── WeightingConfig.razor        # Metric weights for scoring
└── History/
    ├── TestHistory.razor                # Historical test runs
    │   ├── TestList.razor               # Filterable list
    │   ├── TestDetails.razor            # Drill-down view
    │   └── SearchAndFilter.razor        # Date, config, trajectory filters
    └── ParameterEvolution.razor         # Parameter changes over time
        ├── EvolutionTimeline.razor      # Visual timeline
        └── ChangeLog.razor              # Detailed change log
```

### 5.2. Key UI Components

#### 5.2.1. Real-Time Monitoring Panel

**Component:** `RealTimeMonitor.razor`

**Features:**
- **Trajectory View:** 2D canvas showing robot position, reference path, lookahead point
- **Telemetry Gauges:** Speed, angular velocity, CTE, heading error (updated 10Hz)
- **Progress Bar:** Distance completed / total distance
- **Status Indicators:** Running, Paused, Warning, Error states
- **Control Buttons:** Pause, Resume, Stop, Emergency Stop

**Data Binding:**
```csharp
@code {
    [Inject] IHubConnection HubConnection { get; set; }
    
    private RobotState currentState;
    private List<Vector2> trajectoryHistory = new();
    
    protected override async Task OnInitializedAsync()
    {
        HubConnection.On<RobotState>("ReceiveState", state =>
        {
            currentState = state;
            trajectoryHistory.Add(state.Position);
            StateHasChanged();
        });
        
        await HubConnection.StartAsync();
    }
}
```

**SignalR Messages:**
- `ReceiveState`: Full robot state (50Hz → throttled to 10Hz)
- `ReceiveMetrics`: Current metrics (CTE, heading error, etc.)
- `ReceiveSafetyEvent`: Safety violations or warnings
- `ReceiveTestStatus`: Test lifecycle events (started, paused, completed, aborted)

#### 5.2.2. Parameter Tuning Panel

**Component:** `ParameterSliders.razor`

**Features:**
- **Grouped Sliders:** PID (Kp, Ki, Kd), Pure Pursuit (Kdd, lookahead), Estimator (alpha, blends)
- **Real-time Validation:** Show red border if value out of bounds
- **Value Input:** Slider + numeric input for precise control
- **Reset Button:** Revert to last saved or default values
- **Presets Dropdown:** Quick load (Conservative, Balanced, Aggressive)

**Example Markup:**
```razor
<MudCard>
    <MudCardHeader>PID Controller</MudCardHeader>
    <MudCardContent>
        <MudSlider T="double" 
                   @bind-Value="parameters.PID.Kp" 
                   Min="@Bounds.KpRange.Min" 
                   Max="@Bounds.KpRange.Max"
                   Step="0.1"
                   ValueLabel="true">
            Kp: @parameters.PID.Kp.ToString("F2")
        </MudSlider>
        
        <MudTextField @bind-Value="parameters.PID.Kp" 
                      Label="Kp (Precise)" 
                      Variant="Variant.Outlined" 
                      Validation="@ValidateKp" />
        
        <!-- Repeat for Ki, Kd -->
    </MudCardContent>
</MudCard>
```

#### 5.2.3. Metrics Dashboard

**Component:** `MetricsSummary.razor`

**Layout:**
```
┌─────────────────────────────────────────────────────────┐
│ TRACKING ACCURACY ☆ (92/100)                     │
├─────────────────────────────────────────────────────────┤
│ Cross-Track Error RMS    0.087m  ✅  (< 0.10m)        │
│ Cross-Track Error Peak   0.152m  ✅  (< 0.20m)        │
│ Heading Error RMS        8.3°    ✅  (< 10°)          │
│ Goal Position Error      0.042m  ✅  (< 0.05m)        │
├─────────────────────────────────────────────────────────┤
│ SMOOTHNESS ☆ (88/100)                            │
├─────────────────────────────────────────────────────────┤
│ Max Jerk                 3.2 m/s³ ✅  (< 5.0)         │
│ Velocity Std Dev         0.08 m/s ✅                   │
│ Angular Jerk             6.1 r/s³ ✅  (< 10.0)        │
├─────────────────────────────────────────────────────────┤
│ EFFICIENCY ☆ (85/100)                            │
├─────────────────────────────────────────────────────────┤
│ Path Length Ratio        1.08     ✅  (< 1.15)        │
│ Completion Time          8.5s                          │
│ Average Speed            1.18 m/s                      │
└─────────────────────────────────────────────────────────┘
```

**Color Coding:**
- Green ✅: Metric passes acceptance criteria
- Yellow ⚠️: Metric close to threshold (within 10%)
- Red ❌: Metric fails acceptance criteria

#### 5.2.4. Trajectory Visualization

**Component:** `TrajectoryView.razor`

**Canvas Rendering (using Blazor.Extensions.Canvas or Plotly):**
- **Reference Path:** Solid blue line
- **Actual Path:** Dashed green line (updates real-time)
- **Robot Icon:** Oriented triangle at current position
- **Lookahead Point:** Red circle on reference path
- **Target Goal:** Flag icon
- **Error Bars:** Perpendicular lines showing CTE at sample points

**Interactive Features:**
- Zoom/pan
- Click to see metrics at specific point
- Toggle layers (reference, actual, errors)

### 5.3. SignalR Hub Definition

**File:** `Hubs/TuningHub.cs`

```csharp
public class TuningHub : Hub
{
    private readonly ITuningOrchestrator _orchestrator;
    
    public TuningHub(ITuningOrchestrator orchestrator)
    {
        _orchestrator = orchestrator;
    }
    
    // Client → Server
    public async Task StartTest(TestScenario scenario, ParameterSet parameters)
    {
        await _orchestrator.StartTest(scenario, parameters, Context.ConnectionId);
    }
    
    public async Task PauseTest()
    {
        await _orchestrator.PauseTest(Context.ConnectionId);
    }
    
    public async Task StopTest()
    {
        await _orchestrator.StopTest(Context.ConnectionId);
    }
    
    public async Task EmergencyStop()
    {
        await _orchestrator.EmergencyStop(Context.ConnectionId);
    }
    
    // Server → Client (called by orchestrator)
    // Clients.Caller.SendAsync("ReceiveState", state);
    // Clients.Caller.SendAsync("ReceiveMetrics", metrics);
    // Clients.Caller.SendAsync("ReceiveTestStatus", status);
    // Clients.Caller.SendAsync("ReceiveSafetyEvent", safetyEvent);
}
```

**Client-side Connection:**
```csharp
@code {
    private HubConnection hubConnection;
    
    protected override async Task OnInitializedAsync()
    {
        hubConnection = new HubConnectionBuilder()
            .WithUrl(NavigationManager.ToAbsoluteUri("/tuninghub"))
            .WithAutomaticReconnect()
            .Build();
        
        hubConnection.On<RobotState>("ReceiveState", HandleStateUpdate);
        hubConnection.On<TestMetrics>("ReceiveMetrics", HandleMetricsUpdate);
        hubConnection.On<TestStatus>("ReceiveTestStatus", HandleStatusUpdate);
        hubConnection.On<SafetyEvent>("ReceiveSafetyEvent", HandleSafetyEvent);
        
        await hubConnection.StartAsync();
    }
}
```

---

## 6. LAYER 2: APPLICATION SERVICES

### 6.1. TuningOrchestrator

**Responsibility:** Coordinate the entire tuning workflow from test initiation to result storage.

**Interface:**
```csharp
public interface ITuningOrchestrator
{
    // Test execution
    Task<TestResult> RunSingleTest(
        TestScenario scenario, 
        ParameterSet parameters, 
        string connectionId = null
    );
    
    Task<BatchTestResult> RunBatchTests(
        List<TestScenario> scenarios, 
        ParameterSet parameters
    );
    
    Task<ComparisonResult> CompareConfigurations(
        List<ParameterSet> parameterSets, 
        TestScenario scenario
    );
    
    // Real-time control
    Task StartTest(TestScenario scenario, ParameterSet parameters, string connectionId);
    Task PauseTest(string connectionId);
    Task ResumeTest(string connectionId);
    Task StopTest(string connectionId);
    Task EmergencyStop(string connectionId