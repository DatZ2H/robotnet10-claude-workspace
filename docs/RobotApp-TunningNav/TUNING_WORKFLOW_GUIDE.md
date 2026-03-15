# HƯỚNG DẪN TUNING NAVIGATION - COMPLETE GUIDE

**Document:** Robot Navigation Tuning System - Comprehensive Guide
**Last Updated:** 2026-02-01
**Version:** 2.0 (Updated with Adaptive Pure Pursuit)
**Status:** Manual Tuning + Parameter Documentation

---

## MỤC LỤC

1. [Tổng Quan Hệ Thống](#tổng-quan-hệ-thống)
2. [Quick Start - Workflow Cơ Bản](#quick-start)
3. [Parameter Reference](#parameter-reference)
4. [Troubleshooting Scenarios](#troubleshooting-scenarios)
5. [Advanced Tuning Techniques](#advanced-tuning)
6. [Best Practices](#best-practices)

---

## TỔNG QUAN HỆ THỐNG

### Loại Tuning Hiện Tại: **MANUAL TUNING** ✅

**Tính năng đã có:**
- ✅ Manual parameter adjustment UI
- ✅ Single test execution
- ✅ Batch testing (nhiều scenarios)
- ✅ Configuration comparison
- ✅ Real-time visualization
- ✅ Metrics calculation và scoring
- ✅ **NEW:** Adaptive Pure Pursuit (distance + curvature based)
- ✅ **NEW:** 3-Phase Final Approach Controller
- ✅ **NEW:** Comprehensive parameter documentation

**Tính năng chưa có (Future):**
- ❌ Automated optimization (Bayesian, Grid Search)
- ❌ Auto-tuning algorithms
- ❌ AI-based parameter suggestion

---

## QUICK START

### Workflow 1: First-Time Setup (15 phút)

```
┌─────────────────────────────────────┐
│ 1. Load Default Configuration      │
│    - Access: /navigation/tuning     │
│    - Select "Balanced Default"      │
│    Time: 2 phút                     │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│ 2. Baseline Test                    │
│    - Scenario: "Straight Line 10m" │
│    - Click "Start Test"             │
│    - Observe visualization          │
│    Time: 3 phút                     │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│ 3. Review Metrics                   │
│    Overall Score: ____/100          │
│    - CTE RMS: ____m                 │
│    - Heading Error: ____°           │
│    - Jerk: ____m/s³                 │
│    Time: 5 phút                     │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│ 4. Decision Tree                    │
│    Score > 80  → Test more scenarios│
│    Score 60-80 → Manual tuning      │
│    Score < 60  → Check hardware     │
│    Time: 5 phút                     │
└─────────────────────────────────────┘
```

**Kết quả mong đợi:** Hiểu được performance baseline của robot

---

### Workflow 2: Multi-Scenario Validation (20 phút)

```
1. Setup Batch Test
   Scenarios:
   ☑ Straight Line 10m
   ☑ Circle 2m Radius
   ☑ Circle 0.5m Radius (challenging)

2. Run & Monitor (15 phút)
   - Auto run từng scenario
   - Track progress bar
   - View real-time plots

3. Compare Results (5 phút)
   Scenario           Score  CTE RMS  Decision
   ─────────────────  ─────  ───────  ────────
   Straight Line      85     0.05m    ✓ Pass
   Circle 2m          78     0.08m    ⚠ Tune
   Circle 0.5m        65     0.12m    ✗ Need work
```

---

## PARAMETER REFERENCE

### Pure Pursuit Configuration

#### **Basic Lookahead Parameters**

##### `LookaheadMin` (meters)
**Default:** 0.3m
**Meaning:** Điểm gần nhất phía trước mà robot hướng đến

**↑ Tăng (0.4-0.6m):**
- ✓ Smoother tracking trên đường thẳng
- ✓ Ít reactive, predictive hơn
- ✗ Có thể cắt góc trên curves
- ✗ Kém chính xác ở low speed

**↓ Giảm (0.2-0.25m):**
- ✓ Tracking curves chặt hơn
- ✓ Chính xác hơn ở low speed
- ✗ Jittery/oscillation nhiều hơn
- ✗ Nhạy với noise

**Tuning Tips:**
- Warehouse AGV: 0.4-0.5m (smooth)
- Tight spaces: 0.25-0.3m (precision)
- Start: 0.3m (balanced)

**UI Location:** `Pure Pursuit Tab > Basic Lookahead > LookaheadMin`

---

##### `Kdd` (seconds)
**Default:** 1.0s
**Formula:** `lookahead = LookaheadMin + Kdd × |velocity|`

**↑ Tăng (1.2-1.5s):**
- ✓ Look xa hơn ở high speed → smoother
- ✓ Tốt cho fast robots (>1.5 m/s)
- ✗ Có thể quá predictive (overshoot)

**↓ Giảm (0.7-0.9s):**
- ✓ Reactive control hơn
- ✓ Tốt cho slow robots
- ✗ Jittery ở high speed

**Tuning Tips:**
- Check formula: At 1.0m/s → lookahead = 0.3 + 1.0×1.0 = 1.3m
- Slow robot (<0.5 m/s): Kdd = 0.8-1.0
- Fast robot (>1.5 m/s): Kdd = 1.2-1.5

**UI Location:** `Pure Pursuit Tab > Basic Lookahead > Kdd`

---

##### `LookaheadMax` (meters)
**Default:** 2.0m
**Meaning:** Upper limit cho lookahead distance

**↑ Tăng (2.5-3.0m):**
- ✓ Very smooth ở high speed
- ✓ Tốt cho long straight paths
- ✗ Cắt góc aggressive
- ✗ Phản ứng chậm với path changes

**↓ Giảm (1.5-1.8m):**
- ✓ Tighter path following
- ✓ Tốt cho complex paths
- ✗ Kém smooth ở high speed

**Tuning Tips:**
- Must be: `LookaheadMax > LookaheadMin + Kdd × MaxVelocity`
- Example: MaxVel=1.5m/s → need ≥ 0.3+1.0×1.5 = 1.8m

**UI Location:** `Pure Pursuit Tab > Basic Lookahead > LookaheadMax`

---

#### **Adaptive Lookahead Parameters** (NEW in v2.0)

##### `GoalRegionDistance` (meters)
**Default:** 1.5m
**Meaning:** Bắt đầu giảm lookahead khi trong khoảng này từ goal

**How it works:**
```
Distance > 1.5m: lookahead = 100% (normal)
Distance = 1.0m: lookahead = 83%
Distance = 0.5m: lookahead = 67%
Distance = 0.0m: lookahead = 50%
```

**↑ Tăng (2.0-3.0m):**
- ✓ Earlier precision mode
- ✓ Smoother deceleration
- ✗ Slower overall

**↓ Giảm (0.8-1.2m):**
- ✓ Faster approach
- ✗ Abrupt gần goal

**Tuning Tips:**
- Fast robot: Tăng (need more brake distance)
- Short paths: 1.0-1.5m
- Long paths: 2.0-2.5m

**UI Location:** `Pure Pursuit Tab > Adaptive > GoalRegionDistance`

---

##### `KCurvature`
**Default:** 2.0
**Formula:** `curvatureFactor = 1 / (1 + KCurvature × curvature)`

**How it works:**
```
Straight path (k=0):   curvatureFactor = 1.0 (100% lookahead)
Gentle curve (k=0.5):  curvatureFactor = 0.67 (67% lookahead)
Sharp curve (k=1.0):   curvatureFactor = 0.33 (33% lookahead)
```

**↑ Tăng (3.0-5.0):**
- ✓ Tighter tracking trên curves
- ✓ Ít cắt góc
- ✗ Có thể quá reactive
- ✗ Oscillation trên curves

**↓ Giảm (1.0-1.5):**
- ✓ Smoother trên curves
- ✗ Cắt góc nhiều hơn
- ✗ Kém precise

**Tuning Tips:**
- Warehouse (gentle curves): 1.5-2.0
- Tight spaces (sharp curves): 3.0-4.0
- If cutting corners: Tăng KCurvature

**UI Location:** `Pure Pursuit Tab > Adaptive > KCurvature`

---

#### **Final Approach Parameters**

##### `FinalApproachThreshold` (meters)
**Default:** 0.2m
**Meaning:** Khoảng cách activate final approach mode

**Behavior:**
- Distance > 0.2m: Normal Pure Pursuit tracking
- Distance ≤ 0.2m: Switch to 3-phase final approach controller

**3 Phases:**
1. **Phase 1:** Approach position (distance > 3cm)
2. **Phase 2:** Align heading (position OK, heading error > 3°)
3. **Phase 3:** Goal reached (both OK)

**↑ Tăng (0.3-0.5m):**
- ✓ Earlier slow down → smoother
- ✗ Takes longer

**↓ Giảm (0.1-0.15m):**
- ✓ Faster approach
- ✗ Abrupt/jerky

**Tuning Tips:**
- Should be: `> PositionTolerance × 3`
- High precision: 0.3-0.5m
- Speed priority: 0.15-0.2m

**UI Location:** `Pure Pursuit Tab > Final Approach > Threshold`

---

##### `PositionTolerance` (meters)
**Default:** 0.03m (3cm)
**Meaning:** Robot cần ở gần goal bao nhiêu

**↑ Tăng (0.05-0.08m):**
- ✓ Faster goal reaching
- ✗ Lower precision

**↓ Giảm (0.01-0.02m):**
- ✓ Higher precision
- ✗ May never reach (nếu localization error lớn)

**Critical Constraint:**
```
PositionTolerance >= 2 × Localization_RMS_Error
```

**Tuning Tips:**
- Typical localization: 1-2cm → use 0.03-0.05m
- High precision app: 0.02m (if localization allows)
- Cannot be < localization capability

**UI Location:** `Pure Pursuit Tab > Final Approach > PositionTolerance`

---

##### `HeadingTolerance` (degrees)
**Default:** 3.0°
**Meaning:** Robot heading phải align trong khoảng này

**Phase 2 Behavior:**
- Position đạt → Stop linear motion
- Rotate in-place để align heading
- Khi heading error < 3° → Done

**↑ Tăng (5-10°):**
- ✓ Faster completion
- ✗ Robot may face wrong direction

**↓ Giảm (1-2°):**
- ✓ Very precise alignment
- ✗ Takes much longer
- ✗ May oscillate

**Tuning Tips:**
- Docking/charging: 2-3° (precision critical)
- General navigation: 5-8°
- No heading requirement: 10-15° (fast)

**UI Location:** `Pure Pursuit Tab > Final Approach > HeadingTolerance`

---

### Navigation Limits

##### `MaxLinearVelocity` (m/s)
**Default:** 1.5 m/s
**Meaning:** Top speed during navigation

**Safety Check:**
```
Braking distance = v/ (2 × deceleration)
At 1.5 m/s, 0.5 m/sdecel → 2.25m braking distance
```

**Tuning Tips:**
- MUST match motor controller limits
- Warehouse AGV: 1.0-1.5 m/s
- Outdoor: 2.0-3.0 m/s
- Crowded areas: 0.5-0.8 m/s

**UI Location:** `Navigation Limits Tab > MaxLinearVelocity`

---

## TROUBLESHOOTING SCENARIOS

### Scenario 1: Robot Oscillates (Dao động)

**Triệu chứng:**
- ✗ Robot swing qua lại
- ✗ Angular velocity thay đổi liên tục
- ✗ Path không smooth
- **Metrics:** High velocity StdDev, high jerk

**Root Causes & Solutions:**

| Cause | Parameter | Action | Priority |
|-------|-----------|--------|----------|
| Lookahead quá ngắn | `LookaheadMin` | 0.3 → 0.4m | |
| Curvature sensitivity cao | `KCurvature` | 2.0 → 1.5 | |
| Angular gain lớn | `MaxAngularVelocity` | 1.5 → 1.2 rad/s | |
| Signal noise | `AlphaFilter` | 0.3 → 0.2 | |
| PID Kd thấp | `MovePidConfig.Kd` | +0.1-0.2 | |

**Step-by-Step Fix:**
```
1. Tăng LookaheadMin: 0.3 → 0.4m
   └─> Test → Still oscillate?
2. Giảm KCurvature: 2.0 → 1.5
   └─> Test → Still oscillate?
3. Giảm MaxAngularVelocity: 1.5 → 1.2 rad/s
   └─> Test → Still oscillate?
4. Increase damping: MovePidConfig.Kd +0.1
```

**Expected Improvement:**
- Velocity StdDev: 0.3 → 0.15 m/s
- Max Jerk: 6.0 → 3.5 m/s³
- Overall Score: +10-15 points

---

### Scenario 2: Robot Cuts Corners (Cắt góc)

**Triệu chứng:**
- ✗ Robot không follow đường cong chặt
- ✗ Cross-track error lớn trên curves
- ✗ Shortcut qua góc
- **Metrics:** CTE RMS > 0.10m, Path Length Ratio < 1.0

**Root Causes & Solutions:**

| Cause | Parameter | Action | Priority |
|-------|-----------|--------|----------|
| Lookahead quá dài | `LookaheadMax` | 2.0 → 1.5m | |
| Không adapt curvature | `KCurvature` | 2.0 → 3.0-4.0 | |
| Lookahead time lớn | `MaxLookaheadTimeRatio` | 2.0 → 1.5s | |

**Step-by-Step Fix:**
```
1. Tăng KCurvature: 2.0 → 3.0
   └─> Test on sharp curve
2. Vẫn cut? → Giảm LookaheadMax: 2.0 → 1.8m
   └─> Check CTE RMS improvement
3. Fine-tune: MaxLookaheadTimeRatio: 2.0 → 1.7s
```

**Test Case:**
- Circle 0.5m Radius (challenging)
- Goal: CTE RMS < 0.08m

---

### Scenario 3: Poor Goal Precision

**Triệu chứng:**
- ✗ Robot không dừng đúng vị trí
- ✗ Heading sai khi đến goal
- ✗ Overshoot hoặc undershoot
- **Metrics:** Final position error > 5cm, heading error > 5°

**Diagnosis:**
```
Check Phase Logs:
FA-P1: DTG=0.085m, AErr=8.3°, LV=0.15, AV=0.12
                    ^^^^^ Heading error cao
FA-P2: HErr=2.1°, AV=0.08 (Aligning heading)
                    ^^^^^ Good alignment
FA-P3: Goal reached! DTG=0.02m, HErr=1.5°
                           ^^^^^ Position OK
```

**Root Causes & Solutions:**

| Cause | Parameter | Action | Priority |
|-------|-----------|--------|----------|
| Position tolerance lớn | `PositionTolerance` | 0.03 → 0.02m | |
| Final approach xa | `FinalApproachThreshold` | 0.2 → 0.15m | |
| Angular gain thấp | `FinalKdAngular` | 2.0 → 2.5-3.0 | |
| Goal region lớn | `GoalRegionDistance` | 1.5 → 1.0m | |

**Special Case: Heading Issues**
```
If position OK but heading wrong:
1. Check CalculateGoalHeading() logic
2. Tăng FinalKdAngular: 2.0 → 3.0
3. Giảm HeadingTolerance: 3° → 2° (stricter)
4. Increase FinalApproachMaxAngularVel: 0.3 → 0.4 rad/s (faster rotation)
```

---

### Scenario 4: High Speed Instability

**Triệu chứng:**
- ✗ Không stable ở tốc độ cao
- ✗ Overshoot nhiều
- ✗ Hard braking
- **Metrics:** High jerk ở cuối path, position overshoot

**Root Causes & Solutions:**

| Cause | Parameter | Action | Priority |
|-------|-----------|--------|----------|
| Lookahead không đủ xa | `LookaheadMax` | 2.0 → 2.5-3.0m | |
| Kdd quá nhỏ | `Kdd` | 1.0 → 1.2-1.5s | |
| Goal region ngắn | `GoalRegionDistance` | 1.5 → 2.0-2.5m | |

**Formula Check:**
```
Braking Distance = v/ (2 × decel)
At 1.5 m/s, 0.5 m/s→ 2.25m

GoalRegionDistance should be ≥ Braking Distance
→ Set GoalRegionDistance = 2.5m (safety margin)
```

---

## ADVANCED TUNING

### Tuning Hierarchy (Làm theo thứ tự này)

**Priority 1: Basic Lookahead**
```
1. LookaheadMin → Base stability
2. KCurvature → Curve handling
3. Kdd → Velocity scaling
4. LookaheadMax → High-speed limit
```

**Priority 2: Final Approach**
```
1. PositionTolerance → Must match localization
2. FinalApproachThreshold → When to slow down
3. FinalKdAngular → Heading control gain
4. HeadingTolerance → Strictness
```

**Priority 3: Adaptive Features**
```
1. GoalRegionDistance → Brake distance
2. KCurvature → Curve tightness
3. Time ratios → Preview distance
```

---

### Parameter Interactions (Quan trọng!)

#### Interaction 1: LookaheadMin ↔ KCurvature
```
Combination               Result              When to Use
─────────────────────     ─────────────────   ──────────────
High LookaheadMin +       Cut corners         ✗ Avoid
Low KCurvature            severely

Low LookaheadMin +        May oscillate       ⚠ Careful
High KCurvature           on curves

Medium LookaheadMin +     Balanced            ✓ Recommended
Medium KCurvature         (0.3-0.4m, 2.0)
```

#### Interaction 2: MaxLinearVelocity ↔ GoalRegionDistance
```
Speed    Goal Region    Result
───────  ─────────────  ───────────────────────────
1.5 m/s  1.0m           ✗ Insufficient brake distance
1.5 m/s  2.5m           ✓ Safe, smooth approach
0.5 m/s  2.5m           ⚠ Too early slow down
```

**Formula:**
```csharp
GoalRegionDistance ≥ MaxLinearVelocity/ (2 × deceleration)
```

---

### Preset Configurations (Quick Start)

#### **Preset 1: Warehouse Standard**
```json
{
  "Name": "Warehouse Standard",
  "Description": "Smooth, wide corridors, medium speed",
  "PurePursuitConfig": {
    "LookaheadMin": 0.4,
    "Kdd": 1.0,
    "LookaheadMax": 2.0,
    "KCurvature": 1.5,
    "MaxAngularVelocity": 1.2,
    "FinalApproachThreshold": 0.2,
    "PositionTolerance": 0.04,
    "HeadingTolerance": 5.0,
    "GoalRegionDistance": 1.5
  },
  "NavigationConfig": {
    "MaxLinearVelocity": 1.2
  }
}
```
**Use case:** Kho hàng rộng, ít chướng ngại

---

#### **Preset 2: Tight Precision**
```json
{
  "Name": "Tight Precision",
  "Description": "Narrow spaces, docking, high precision",
  "PurePursuitConfig": {
    "LookaheadMin": 0.25,
    "Kdd": 0.8,
    "LookaheadMax": 1.5,
    "KCurvature": 3.0,
    "MaxAngularVelocity": 1.0,
    "FinalApproachThreshold": 0.3,
    "PositionTolerance": 0.02,
    "HeadingTolerance": 2.0,
    "GoalRegionDistance": 1.0
  },
  "NavigationConfig": {
    "MaxLinearVelocity": 0.8
  }
}
```
**Use case:** Docking, charging, tight spaces

---

#### **Preset 3: High Speed**
```json
{
  "Name": "High Speed",
  "Description": "Fast navigation, long straight paths",
  "PurePursuitConfig": {
    "LookaheadMin": 0.5,
    "Kdd": 1.5,
    "LookaheadMax": 3.0,
    "KCurvature": 2.0,
    "MaxAngularVelocity": 2.0,
    "FinalApproachThreshold": 0.15,
    "PositionTolerance": 0.05,
    "HeadingTolerance": 8.0,
    "GoalRegionDistance": 2.5
  },
  "NavigationConfig": {
    "MaxLinearVelocity": 2.0
  }
}
```
**Use case:** Outdoor, tốc độ cao, đường thẳng dài

---

## COMPARISON WORKFLOW

### How to Compare Two Configurations

**Step 1: Setup Comparison**
```
UI: Configuration Comparison Tab
├─ Config A: "Balanced Default"
├─ Config B: "Tuned_v1"
└─ Scenario: "Circle 2m Radius"

Click: "Run Comparison"
```

**Step 2: Monitor Execution**
```
Progress:
[████████████░░░░░░░░] 60% (Config A Complete)

Real-time Plot:
- Blue line: Config A trajectory
- Red line: Config B trajectory
- Green line: Reference path
```

**Step 3: Review Results**
```
Metric               Config A    Config B    Improvement
───────────────────  ──────────  ──────────  ───────────
Overall Score        72          84          +12 ✓
CTE RMS (m)          0.095       0.062       -35% ✓
Heading Error (°)    4.2         2.8         -33% ✓
Max Jerk (m/s³)      5.8         3.9         -33% ✓
Completion Time (s)  12.5        11.8        -6% ✓
```

**Decision:**
- All metrics improved → ✓ Config B is better, save it
- Mixed results → Need further tuning
- Worse results → Revert, try different approach

---

## ⚠️ BEST PRACTICES & SAFETY

### 1. Tuning Safety

**Safety Monitoring (Auto Abort):**
```
Test sẽ stop nếu:
- Cross-track error > 0.5m
- Heading error > 45°
- Sustained tracking error > 3s
- Velocity exceeds motor limits
```

**Before Tuning:**
- ✓ Check hardware health
- ✓ Verify sensor calibration
- ✓ Test in safe environment
- ✓ Have emergency stop ready

### 2. Parameter Validation

**Automatic Constraints:**
```csharp
// System validates these automatically:
LookaheadMax > LookaheadMin
GoodTrackingBlend < PoorTrackingBlend
MaxLinearVelocity <= Motor_Max_Velocity
PositionTolerance >= 2 × Localization_Error
```

**If validation fails:**
- Red border on parameter field
- Tooltip shows violation
- Cannot save until fixed

### 3. Incremental Changes

**Rule of Thumb:**
```
Change 1-2 parameters per iteration
Max change: ±30% of current value
Test after each change
```

**Example:**
```
❌ Bad:
  LookaheadMin: 0.3 → 0.6 (+100%)
  Kdd: 1.0 → 1.5 (+50%)
  KCurvature: 2.0 → 4.0 (+100%)
  → Too many changes, can't isolate effect

✓ Good:
  LookaheadMin: 0.3 → 0.35 (+17%)
  Test → Evaluate → Next change
```

### 4. Documentation

**Every Configuration Should Have:**
```json
{
  "Name": "Tuned_2026-02-01_v3",
  "Description": "Increased KCurvature to 3.0 to reduce corner cutting on tight curves. Improved CTE RMS from 0.095m to 0.062m on Circle 2m scenario.",
  "CreatedBy": "User Name",
  "BaseConfig": "Balanced Default",
  "TestResults": [
    {
      "Scenario": "Circle 2m",
      "Score": 84,
      "CTE_RMS": 0.062
    }
  ]
}
```

### 5. Multi-Scenario Validation

**Minimum Test Matrix:**
```
Scenario             Min Score  Critical Metrics
───────────────────  ─────────  ────────────────────
Straight Line 10m    > 80       CTE RMS < 0.05m
Circle 2m Radius     > 75       CTE RMS < 0.08m
Circle 0.5m Radius   > 65       CTE RMS < 0.12m
```

**Full Validation (Before Deployment):**
- All 3 scenarios > thresholds
- No safety violations
- Smooth trajectories (visual check)
- Repeatable results (run 3 times)

---

## WORKFLOW EXAMPLES

### Example 1: Fix Oscillation Issue

**Initial State:**
```
Scenario: Straight Line 10m
Score: 68/100
Issues:
- Velocity StdDev: 0.32 m/s (high)
- Max Jerk: 6.2 m/s³ (high)
- Visual: Robot swings left-right
```

**Iteration 1:**
```
Change: LookaheadMin: 0.3 → 0.4m
Reason: Increase preview distance
Result:
  Score: 68 → 75 (+7)
  Velocity StdDev: 0.32 → 0.22 (-31%)
  Still some oscillation → Continue
```

**Iteration 2:**
```
Change: KCurvature: 2.0 → 1.5
Reason: Less aggressive on curves
Result:
  Score: 75 → 79 (+4)
  Max Jerk: 6.2 → 4.5 (-27%)
  Better but not perfect → Continue
```

**Iteration 3:**
```
Change: MovePidConfig.Kd: 0.6 → 0.8
Reason: Add damping
Result:
  Score: 79 → 83 (+4)
  Velocity StdDev: 0.22 → 0.15 (-32%)
  Visual: Smooth tracking ✓
  PASS! Save as "Smooth_v1"
```

**Total Time:** 25 phút (3 iterations × ~8 phút/iteration)

---

### Example 2: Improve Goal Precision

**Initial State:**
```
Scenario: Docking Test
Issues:
- Final position error: 8cm (target: <3cm)
- Final heading error: 6° (target: <3°)
```

**Analysis:**
```
Phase Logs:
FA-P1: DTG=0.18m, AErr=12°, LV=0.20
      └─> Slow approach OK
FA-P2: HErr=6.2°, AV=0.15
      └─> Heading alignment too slow
FA-P3: Not reached (timeout)
```

**Iteration 1:**
```
Change: FinalKdAngular: 2.0 → 3.0
Reason: Faster heading correction
Result:
  Final heading error: 6° → 3.5°
  Better but still over target
```

**Iteration 2:**
```
Changes:
  - HeadingTolerance: 3° → 2° (stricter)
  - FinalApproachMaxAngularVel: 0.3 → 0.4 (faster rotation)
Result:
  Final heading error: 3.5° → 2.1° ✓
  Final position: 8cm → 2.5cm ✓
  PASS!
```

---

## 🔮 FUTURE FEATURES

### Planned: Automated Optimization (Phase 3)

**Status:** Not yet implemented

**Algorithms Under Consideration:**
- Bayesian Optimization (most promising)
- Grid Search (exhaustive but slow)
- Genetic Algorithm (for multi-objective)

**Estimated Workflow:**
```
1. Select parameters to optimize
   ☑ LookaheadMin, Kdd, KCurvature
   ☐ (Lock other parameters)

2. Define objective function
   Minimize: 0.6×CTE_RMS + 0.2×Jerk + 0.2×Time

3. Set constraints
   LookaheadMin: [0.2, 0.6]
   Kdd: [0.7, 1.5]
   ...

4. Run optimization (30-60 phút)
   Progress: [████░░░░] 50% (25/50 iterations)

5. Review best parameters
   Best Score: 87 (iteration 38)

6. Validate on test scenarios
```

**Timeline:** Q2 2026 (planned)

---

## FAQ

**Q: Nên tune bao nhiêu parameters cùng lúc?**
A: 1-2 parameters per iteration. Tune theo nhóm (Pure Pursuit → PID → Velocity).

**Q: Làm sao biết tuning có hiệu quả?**
A: Use Comparison tool. Overall Score tăng ≥5 điểm + visual improvement.

**Q: Robot vẫn oscillate sau khi tăng LookaheadMin?**
A: Try giảm KCurvature hoặc tăng PID Kd (damping).

**Q: Goal precision kém dù đã giảm PositionTolerance?**
A: Check localization error. PositionTolerance không thể < 2× localization RMS error.

**Q: Cần test bao nhiêu scenarios?**
A: Minimum 3 (Straight, Circle 2m, Circle 0.5m). Recommend 5+ for robustness.

**Q: Làm sao load preset vào UI?**
A: Configuration dropdown → Select preset name → Click "Load".

**Q: Configuration comparison cho kết quả khác nhau mỗi lần?**
A: Check randomness in test scenario. Some scenarios có stochastic elements. Run multiple times và average.

**Q: Tôi có thể export configuration không?**
A: Yes, click "Export JSON" button. File có thể import vào hệ thống khác.

---

## RELATED DOCUMENTATION

- **Parameter XML Docs:** Hover over any parameter in code to see inline documentation
- **Architecture:** `# ROBOT TUNING SYSTEM - COMPLETE ARCHITE.md`
- **Database Schema:** `# DATABASE SCHEMA & API SPECIFICATIONS.md`
- **Implementation Progress:** `IMPLEMENTATION_PROGRESS.md`
- **Algorithm Details:** `PurePursuitSimplified.cs` (inline comments)

---

## METRICS REFERENCE

### Tracking Accuracy Metrics

**CTE RMS (Cross-Track Error):**
- Measure: Khoảng cách vuông góc từ robot đến path
- Unit: meters
- Target: < 0.08m (good), < 0.05m (excellent)

**Heading Error RMS:**
- Measure: Sai số góc giữa robot heading và path tangent
- Unit: degrees
- Target: < 5° (good), < 3° (excellent)

**Goal Position Error:**
- Measure: Khoảng cách từ final position đến goal
- Unit: meters
- Target: < 0.05m (good), < 0.03m (excellent)

### Smoothness Metrics

**Max Jerk:**
- Measure: Tốc độ thay đổi acceleration lớn nhất
- Unit: m/s³
- Target: < 5.0 (good), < 3.0 (excellent)

**Velocity StdDev:**
- Measure: Độ ổn định của velocity
- Unit: m/s
- Target: < 0.2 (good), < 0.1 (excellent)

### Efficiency Metrics

**Path Length Ratio:**
- Measure: Actual path length / Reference path length
- Target: 1.0-1.05 (good), 1.0-1.02 (excellent)

**Completion Time:**
- Measure: Thời gian hoàn thành so với expected
- Depends on: MaxLinearVelocity, path complexity

---

**Document Version:** 2.0
**Last Updated:** 2026-02-01
**Changelog:**
- v2.0 (2026-02-01): Added Adaptive PP parameters, 3-phase final approach, comprehensive parameter docs
- v1.0 (2026-01-27): Initial manual tuning workflow
