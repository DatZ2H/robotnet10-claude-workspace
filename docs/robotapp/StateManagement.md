# RobotApp - State Management Architecture

> AI Reference Document - Last updated: 2026-02-07 (v2 - state management implemented)
> This document describes the complete state management system of the RobotApp.

## 1. Architecture Overview

The robot state management system is built with 4 layers:

```
FLEET MANAGER (External) ── MQTT/VDA5050 ──► EVENT BUS ──► ROBOT CONTROLLER ──► STATE MACHINE + ORDER/ACTION
                                                                                        │
                                                                              HARDWARE (PLC, IK, Navigation)
```

### Key Components

| Component | File | Role |
|---|---|---|
| `RobotStateMachine` | `Services/State/RobotStateMachine.cs` | Hierarchical State Machine (Appccelerate lib) |
| `RobotStateMachineExecute` | `Services/State/RobotStateMachineExecute.cs` | Entry/Exit action handlers for states |
| `RobotStateType` | `Services/State/RobotStateType.cs` | Enum defining all states |
| `RobotEventType` | `Services/State/RobotEventType.cs` | Enum defining all events |
| `RobotController` | `Services/Robot/RobotController.cs` | Orchestrator - bridges PLC events to StateMachine |
| `RobotOrderController` | `Services/Robot/RobotOrderController.cs` | Order execution engine (IOrder) |
| `RobotActionController` | `Services/Robot/RobotActionController.cs` | Action execution engine (IAction) |
| `RobotPlcController` | `Services/Robot/Modules/RobotPlcController.cs` | PLC/Modbus hardware communication (IPlcController) |
| `ManualControlService` | `Motion/ManualControlService.cs` | RF Handle / Keyboard manual control |
| `RobotStates` | `Services/Robot/RobotStates.cs` | VDA5050 state publisher (MQTT, 1s interval) |
| `RobotActionProvider` | `Services/Robot/Actions/RobotActionProvider.cs` | Auto-discovers RobotAction subclasses via reflection |

---

## 2. State Hierarchy (HSM)

Uses `Appccelerate.StateMachine` with `AsyncPassiveStateMachine`. All hierarchical states use `HistoryType.Deep`.

```
ROOT
├── System (initial=Initializing)
│   ├── Initializing          ← Entry: ModuleInitializeAsync() (waits PlcController + DeviceProvider only)
│   ├── Standby               ← Entry: SetSystemState(IDLE), RobotStates.Start(), RobotVisualization.Start()
│   └── Shutting_Down          ← Entry: StopHandler()
│
├── Auto (initial=Idle)
│   ├── Idle                   ← Entry: SetSystemState(IDLE)
│   ├── Executing (initial=Moving)
│   │   ├── Moving             ← Entry: EntryMoving(), Exit: StopRobot()
│   │   └── ACT (initial=Docking)
│   │       ├── Docking        ← Entry: EntryDocking() (placeholder delay)
│   │       ├── Docked         ← Entry: EntryDocked() (TODO)
│   │       ├── Charging       ← Entry: EntryCharging() (placeholder), Exit: ExitCharging()
│   │       ├── Undocking      ← Entry: EntryUndocking() (placeholder delay)
│   │       ├── Loading        ← Entry: EntryLoading() (placeholder delay)
│   │       ├── Unloading      ← Entry: EntryUnloading() (placeholder delay)
│   │       └── TechAction     ← Entry: EntryTechAction() (placeholder delay)
│   ├── Paused                 ← Entry: StopRobot()
│   ├── Canceling              ← Entry: StopRobot()
│   └── Recovering             ← Entry: EntryRecovering() (placeholder delay)
│
├── Manual                     ← Entry: StopRobot(), Exit: ExitManual() (TODO)
│
├── Service                    ← Entry: StopRobot() + ManualControlService.SetState(Maintenance)
│                                 Exit: ManualControlService.ClearExternalState()
│
├── Remote_Override            ← Entry: StopRobot() + ManualControlService.SetState(Override)
│                                 Exit: ManualControlService.ClearExternalState()
│
├── Stop                       ← Entry: EmergencyStop() (zero velocity + disable IK)
│
└── Fault                      ← Entry: EmergencyStop() (zero velocity + disable IK)
```

### IsInState() Helper

`IsInState(state)` traverses the hierarchy upward. Example:
- If `CurrentState = Charging`, then `IsInState(ACT) = true`, `IsInState(Executing) = true`, `IsInState(Auto) = true`

---

## 3. Complete State Transition Table

### 3.1 Root Level (Mode Switching)

| From | Event | To | Triggered By |
|---|---|---|---|
| System | `EnterAuto` | Auto | `RobotController.SwichModeChanged(AUTOMATIC)` |
| System | `EnterManual` | Manual | `RobotController.SwichModeChanged(MANUAL)` |
| System | `EnterService` | Service | `RobotController.SwichModeChanged(SERVICE)` |
| System | `RemoteOverride` | Remote_Override | `ManualControlService.HandleRfModeChange()` |
| System | `EnterStop` | Stop | `RobotController.OnStop(state != None)` |
| System | `EnterFault` | Fault | `RobotController.OnNewFatalError()` / WatchThread |
| Auto | `EnterManual` | Manual | PLC switch change → SwichModeChanged (pauses order first) |
| Auto | `EnterService` | Service | PLC switch / RF Handle mode change (pauses order first) |
| Auto | `RemoteOverride` | Remote_Override | RF Handle → ManualControlService (pauses order first) |
| Auto | `EnterStop` | Stop | PLC safety sensors → OnStop (pauses order first) |
| Auto | `EnterFault` | Fault | Fatal error detected → OnNewFatalError / WatchThread |
| Manual | `EnterAuto` | Auto | PLC switch change → SwichModeChanged (resumes order) |
| Manual | `EnterService` | Service | PLC switch / RF Handle |
| Manual | `RemoteOverride` | Remote_Override | RF Handle → ManualControlService |
| Manual | `EnterStop` | Stop | PLC safety |
| Manual | `EnterFault` | Fault | Fatal error → OnNewFatalError / WatchThread |
| Service | `EnterAuto` | Auto | PLC switch / RF Handle mode → Default/None (resumes order) |
| Service | `EnterManual` | Manual | PLC switch |
| Service | `RemoteOverride` | Remote_Override | RF Handle → ManualControlService |
| Service | `EnterStop` | Stop | PLC safety |
| Service | `EnterFault` | Fault | Fatal error → OnNewFatalError / WatchThread |
| Remote_Override | `EnterAuto` | Auto | RF Handle mode → Default/None or PLC switch |
| Remote_Override | `EnterManual` | Manual | PLC switch |
| Remote_Override | `EnterService` | Service | PLC switch / RF Handle |
| Remote_Override | `EnterStop` | Stop | PLC safety |
| Remote_Override | `EnterFault` | Fault | Fatal error → OnNewFatalError / WatchThread |
| Stop | `ReleaseStop` | System* | `RobotController.OnButtonPressed(Start)` when safety cleared |
| Stop | `EnterFault` | Fault | Fatal error → WatchThread (not checked while in Stop) |
| Fault | `ExitFault` | System* | (manual intervention - not yet fully implemented) |

> *System uses HistoryType.Deep, returns to last active sub-state (e.g., Standby)

### 3.2 System Sub-states

| From | Event | To | Triggered By |
|---|---|---|---|
| Initializing | `InitializeCompleted` | Standby | `RobotController.ModuleInitializeAsync()` (line 82) |
| Initializing | `EnterFault` | Fault | (not yet triggered) |
| Standby | `Shutdown` | Shutting_Down | (not yet triggered) |
| Shutting_Down | `ShutdownCompleted` | Standby | (not yet triggered) |

### 3.3 Auto Sub-states

| From | Event | To | Triggered By |
|---|---|---|---|
| Idle | `StartExecution` | Executing | `RobotOrderController.HandleOrder()` (line 358) |
| Executing | `PauseExecution` | Paused | (available - Paused state reserved for future use) |
| Executing | `CancelExecution` | Canceling | `RobotCancelOrderAction` via StopOrder() |
| Executing | `CompleteExecution` | Idle | `RobotOrderController.HandleOrderStop()` |
| Paused | `ResumeExecution` | Executing | (available - Paused state reserved for future use) |
| Paused | `CancelExecution` | Canceling | (available) |
| Canceling | `CompleteExecution` | Idle | (not yet triggered) |
| Recovering | `CompleteRecovery` | Idle | (not yet triggered) |

### 3.4 Executing Sub-states

| From | Event | To | Triggered By |
|---|---|---|---|
| Moving | `StartACT` | ACT | `RobotOrderController.HandleNewOrder()` (line 260, single-node order with actions) |
| Moving | `CompleteMoving` | Idle | (not yet triggered) |
| ACT | `StartMoving` | Moving | (not yet triggered) |
| ACT | `CompleteACT` | Idle | (not yet triggered) |

### 3.5 ACT Sub-states

| From | Event | To | Triggered By |
|---|---|---|---|
| Docking | `CompleteDocking` | Docked | (not yet triggered) |
| Docked | `StartCharging` | Charging | (not yet triggered) |
| Docked | `StartUndocking` | Undocking | (not yet triggered) |
| Docked | `StartLoading` | Loading | (not yet triggered) |
| Docked | `StartUnloading` | Unloading | (not yet triggered) |
| Charging | `CompleteCharging` | Docked | (not yet triggered) |
| Undocking | `CompleteUndocking` | Docking | (not yet triggered) |
| Loading | `CompleteLoading` | Docked | (not yet triggered) |
| Unloading | `CompleteUnloading` | Docked | (not yet triggered) |
| TechAction | `CompleteTechAction` | Docked | (not yet triggered) |

---

## 4. Event Trigger Sources

### 4.1 PLC Hardware → StateMachine

```
PLC Modbus Registers ─── ModbusDataChanged() ───┐
                                                  │
    ReadSwitch() ──► OnPeripheralModeChanged ────►│──► RobotController.OnPlcModeChanged()
        - AUTOMATIC, MANUAL, SERVICE              │        → if _rfHandleHasPriority: IGNORED
                                                  │        → else: SwichModeChanged(mode)
                                                  │            → Pause order if leaving Auto
                                                  │            → Fire(EnterAuto/EnterManual/EnterService)
                                                  │            → Resume order if entering Auto
                                                  │            → PLC sync via Entry handlers
                                                  │
    ReadSafetyProtect() ──► OnStop ──────────────►│──► RobotController.OnStop()
        - EMC, Bumper, FrontProtective,            │        → state != None: Pause + Fire(EnterStop)
          BackProtective, TimProtective, None       │        → state == None: _stopCleared = true
                                                  │
    ReadButton() ──► OnButtonPressed ────────────►│──► RobotController.OnButtonPressed()
        - Start, Reset, Stop                      │        → Start + IsInStop + _stopCleared
                                                  │          + safety clear → Fire(ReleaseStop)
                                                  │
    ReadSafetySpeed() ──► OnSafetySpeedChanged ──►│──► RobotOrderController.OnSafetySpeedChanged()
        - Very_Slow..Very_Fast                          → NavigationManager.SetSpeed(speed)
```

### 4.2 RF Handle → RobotController → StateMachine

```
RF Handle Mode Changes (detected in ManualControlService.UpdateFromDeviceLoop):

ManualControlService.HandleRfModeChange():
    Detects RF Mode change → raises OnRfModeChanged event (does NOT fire StateMachine directly)

ManualControlService disconnect detection:
    RF Handle loses connection (RemoteReady=false) → fires OnRfModeChanged(RFMode.None)
    → RobotController releases RF priority and transitions to PLC mode

ManualControlService EStop handling:
    RF Handle EStop pressed → ManualControlService enters SafeStop internally (stops robot)
    → Does NOT clear _externallySetState → StateMachine stays in Service/Remote_Override
    → When EStop released → ManualControlService recovers to Maintenance/Override automatically

RobotController.OnRfModeChanged(rfMode):
    RFMode.Maintenance  → _rfHandleHasPriority=true → Pause if in Auto → Fire(EnterService)
    RFMode.Override     → _rfHandleHasPriority=true → Pause if in Auto → Fire(RemoteOverride)
    RFMode.Default/None → _rfHandleHasPriority=false → SwichModeChanged(PlcController.PeripheralMode)
                           (returns to PLC-determined mode: Auto with resume, Manual, etc.)

ModeSelect Button Hold (2 seconds):
    Active state     + hold 2s → PlcController.SetRFMode(Maintenance)
    Maintenance state + hold 2s → PlcController.SetRFMode(Override)
    → PLC changes → RF reads new mode → OnRfModeChanged → RobotController handles transition
```

> **Design**: All state transitions go through `RobotController` to ensure Pause/Resume and PLC sync.
> `ManualControlService` never fires `RobotStateMachine` directly.

### 4.4 RF Handle Priority & Thread Safety

```
_rfHandleHasPriority flag (in RobotController):
    Set to true  when OnRfModeChanged(Maintenance/Override)
    Set to false when OnRfModeChanged(Default/None) or RF Handle disconnect

Protection:
    - OnPlcModeChanged: checks _rfHandleHasPriority → ignores PLC switch changes when RF active
    - WatchThread mode mismatch: skipped when _rfHandleHasPriority (backup stop still runs)

_stateTransitionLock (in RobotController):
    All state transition methods use lock(_stateTransitionLock):
    - OnPlcModeChanged, OnRfModeChanged, OnStop, OnButtonPressed, OnNewFatalError, WatchThreadCallback
    → Prevents race conditions between PLC Modbus thread, RF Handle 20Hz thread, WatchThread 5Hz

ClearExternalState (in ManualControlService):
    Called from ExitService/ExitRemoteOverride → resets _previousRfMode=None
    → Next UpdateFromDeviceLoop cycle detects current RF mode as "changed"
    → Fires OnRfModeChanged → RobotController re-enters Service/Remote_Override if RF still active
```

### 4.3 Fleet Manager → StateMachine (indirect, via Order/Action)

```
Fleet Manager ─── MQTT ───► IRobotEventBus
    │                            │
    ├── OrderMsg ────────────────┼──► RobotController.NewOrderUpdated()
    │                            │        (only when IsInState(Auto))
    │                            │    → RobotOrderController.UpdateOrder()
    │                            │    → eventually Fire(StartExecution) or Fire(StartACT)
    │                            │
    └── InstantActionsMsg ───────┼──► RobotController.NewInstantActionUpdated()
                                 │    → RobotActionController.AddInstantAction()
                                 │    → Action runs immediately (INSTANT scope)
```

---

## 5. Order Execution Flow

### 5.1 RobotOrderController (IOrder)

Timer-based execution engine running at 100ms intervals.

```
UpdateOrder(OrderMsg) ─┬─ [first time] → HandleOrderStart() → Timer(100ms, OrderHandler)
                       └─ [update] → lock(NewOrder = order)

OrderHandler() every 100ms:
    1. If NewOrder exists:
       - New order ID → HandleNewOrder():
           a. ClearOldOrder()
           b. ValidateNodes() → check sequence IDs, collect actions per node
           c. ValidateEdges() → check startNode/endNode, build trajectory
           d. ActionManager.AddOrderActions(collected actions)
           e. If single-node with actions → NavigationFinished(Completed), Fire(StartACT)
       - Same order ID, higher updateId → HandleUpdateOrder():
           a. Merge new nodes/edges with existing base
           b. Same validation logic

    2. If HasNewOrder (after validation):
       - First node has actions? → StartActionTerminal() (run actions first)
       - No actions? → NavigationManager.Move(Nodes, Edges)
                     → Fire(StartExecution) if not already Executing
                     → Subscribe OnNavigationFinished, OnSafetySpeedChanged

    3. If IsCancelOrder → NavigationManager.CancelMovement()

    4. If IsNavigationFinished:
       - Canceled → HandleOrderStop()
       - Completed → run terminal actions on last node, then HandleOrderStop()
       - Error → HandleOrderStop()

    5. Track current node position:
       - GetCurrentNode() checks robot distance to each node
       - When arriving at node → update LastNode, ClearLastNode()
       - If node has SOFT/HARD actions → Pause navigation, enqueue actions
       - Run actions sequentially (HARD blocks until done)
       - All actions done → Resume navigation

HandleOrderStop():
    - Dispose timer
    - Clear all order data
    - Unsubscribe events
    - Fire(CompleteExecution) → Executing → Idle
```

### 5.2 Action Blocking Types During Navigation

| BlockingType | Behavior |
|---|---|
| `NONE` | Action runs in parallel, navigation continues |
| `SOFT` | Navigation pauses at node, all SOFT+HARD actions enqueued, navigation resumes after all done |
| `HARD` | Same as SOFT but each HARD action must complete before next action starts |

---

## 6. Action System

### 6.1 RobotAction Base Class

Each action has its own internal state machine:

```
WAITING ──► INITIALIZING ──► RUNNING ──► FINISHED
   │              │              │
   └──► FAILED    └──► FAILED   └──► FAILED
   │              │              │
   └──► PAUSED    └──► PAUSED   └──► PAUSED ──► WAITING (resume)
```

**Lifecycle:**
1. `RobotActionProvider.GetRobotAction(type)` creates instance via `ActivatorUtilities`
2. `Initialize(scope, action)` validates ActionType, BlockingType, ActionScope, parameters
3. `Start()` → timer 200ms → `ActionHandler()` loop:
   - `INITIALIZING` → calls `StartAction()`
   - `RUNNING` → calls `ExecuteAction()` repeatedly
   - `PAUSED` → calls `PauseAction()`
   - Cancel requested → calls `StopAction()`
4. When `IsCompleted` (FINISHED or FAILED) → `DisposeAsync()`

### 6.2 Action Discovery

`RobotActionProvider` scans all assemblies starting with "RobotNet10.RobotApp" for classes:
- Inheriting `RobotAction`
- Having `[RobotActionAttribute]`
- Maps `ActionType → Type` for factory creation

### 6.3 Available Actions

| ActionType | Class | Scope | Blocking | Implementation Status |
|---|---|---|---|---|
| `CANCEL_ORDER` | `RobotCancelOrderAction` | INSTANT | ALL | Implemented - calls StopOrder() + StopOrderAction(), polls until cleared |
| `START_PAUSE` | `RobotStartPauseAction` | INSTANT | ALL | Calls IRobotController.Pause() (body is empty) |
| `STOP_PAUSE` | `RobotStopPauseAction` | INSTANT | ALL | Calls IRobotController.Resume() (body is empty) |
| `START_CHARGING` | `RobotStartChargingAction` | ALL | HARD | Placeholder - finishes immediately |
| `STOP_CHARGING` | `RobotStopChargingAction` | ALL | HARD | Placeholder - finishes immediately |
| `PICK` | `RobotPickAction` | ALL | HARD | Waits 10 cycles (~2s) → LoadManager.ClearLoad() |
| `DROP` | `RobotDropAction` | ALL | HARD | Waits 10 cycles (~2s) → LoadManager.ClearLoad() |
| `ROTATE` | `RobotRotateAction` | ALL | HARD | Calls NavigationManager.Rotate(angle), polls NavigationState |
| `LIFT_ROTATE` | `RobotLiftRotateAction` | ALL | HARD | Placeholder - finishes immediately |
| `DOCK_TO` | `RobotDockToAction` | ALL | HARD | Not implemented (empty StartAction/ExecuteAction) |
| `MOVE_STRAIGHT_TO_COOR` | `RobotMoveStraightToCoorAction` | INSTANT | HARD | Not implemented |
| `MOVE_STRAIGHT_WITH_DISTANCE` | `RobotMoveStraightWithDistanceAction` | INSTANT | HARD | Not implemented |
| `SCRIPT` | `RobotScriptAction` | ALL | ALL | Not implemented (has bug in Initialize: `!string.IsNullOrEmpty` should be `string.IsNullOrEmpty`) |
| `INIT_POSITION` | `RobotInitPositionAction` | INSTANT | HARD | (needs verification) |
| `STATE_REQUEST` | `RobotStateRequestAction` | INSTANT | ALL | (needs verification) |
| `FACTSHEET_REQUEST` | `RobotFactsheetRequestAction` | INSTANT | ALL | (needs verification) |
| `MUTED_BASE_ON/OFF` | `RobotMutedBaseOnAction/OffAction` | INSTANT | ALL | (needs verification) |
| `MUTED_LOAD_ON/OFF` | `RobotMutedLoadOnAction/OffAction` | INSTANT | ALL | (needs verification) |

---

## 7. SystemState (PLC Level)

The PLC has its own state representation written via Modbus coils.

```csharp
public enum SystemState { INIT, PAUSED, IDLE, PROCCESSING, DOCKING, MAINTENANCE, MANUAL, OVERRIDE, CHARGING, ERROR }
```

### Mapping: RobotStateMachine → PLC SystemState

Set directly in each Entry handler of `RobotStateMachineExecute` via `PlcController.SetSystemState()`.

| Robot State | SystemState | Notes |
|---|---|---|
| `Initializing` | `INIT` | Set directly in ModuleInitializeAsync() |
| `Standby` | `IDLE` | |
| `Idle` | `IDLE` | |
| `Moving` | `PROCCESSING` | |
| `Loading` / `Unloading` / `TechAction` | `PROCCESSING` | |
| `Stop` | `PAUSED` | |
| `Manual` | `MANUAL` | |
| `Service` | `MAINTENANCE` | |
| `Fault` | `ERROR` | |
| `Docking` / `Docked` / `Undocking` | `DOCKING` | |
| `Charging` | `CHARGING` | |
| `Remote_Override` | `OVERRIDE` | |

---

## 8. ManualControlService State Machine

Separate from RobotStateMachine. Runs on dedicated high-priority thread at configurable UpdateRate (e.g., 20Hz).

```csharp
public enum ManualControlState
{
    Initialization,  // RF Handle not connected
    Disabled,        // RemoteReady == false (no signal)
    SafeStop,        // EStop pressed
    Active,          // Has signal + no EStop, waiting for RobotStateMachine to set mode
    Maintenance,     // Allows robot control (set by RobotStateMachine via EntryService)
    Override,        // Full override control (set by RobotStateMachine via EntryRemoteOverride)
    Default          // Reserved
}
```

### State Determination Priority (every cycle)

1. RF Handle not connected → `Initialization`
2. `RemoteReady == false` → `Disabled` (resets external state)
3. `EStop == true` → `SafeStop` (resets external state)
4. External state set (by RobotStateMachine) → use that state (`Maintenance` or `Override`)
5. Otherwise → `Active`

### Bidirectional Interaction with RobotStateMachine

```
RobotStateMachine ──EntryService()──► ManualControlService.SetState(Maintenance)
RobotStateMachine ──ExitService()──► ManualControlService.ClearExternalState()
RobotStateMachine ──EntryRemoteOverride()──► ManualControlService.SetState(Override)
RobotStateMachine ──ExitRemoteOverride()──► ManualControlService.ClearExternalState()

ManualControlService ──HandleRfModeChange()──► RobotStateMachine.Fire(EnterService/RemoteOverride/EnterAuto)
```

### Control Actions (only in Maintenance/Override/Active states)

- **Velocity**: RF Handle Forward/Backward → linear, Left/Right → angular
- **Lift**: RF Handle LiftUp/LiftDown → ILiftModule.LiftUpAsync/LiftDownAsync
- **Rotation**: RF Handle RotateLeft/RotateRight → IRotationModule.RotateOffsetAsync(+/-90)
- Speed controlled by RF Handle Speed potentiometer (0-100%)

---

## 9. VDA5050 State Publishing

`RobotStates` (IState) publishes `StateMsg` every 1 second via MQTT:

```csharp
StateMsg includes:
    - HeaderId, Manufacturer, Version, SerialNumber
    - OrderId, OrderUpdateId, ZoneSetId
    - LastNodeId, LastNodeSequenceId
    - Driving (based on velocity > 0)
    - OperatingMode (from PlcController.PeripheralMode)
    - NodeStates[], EdgeStates[] (from OrderManager)
    - ActionStates[] (from ActionManager)
    - AgvPosition { X, Y, Theta, MapId, LocalizationScore, DeviationRange }
    - BatteryState (currently commented out)
    - Velocity { Vx, Vy, Omega }
    - SafetyState { FieldViolation, EStop }
    - Information[] includes:
        - General info with ReferenceKey=STATE, ReferenceValue=CurrentState.ToString()
```

---

## 10. Interfaces Summary

### IOrder (RobotOrderController)
```csharp
string OrderId, int OrderUpdateId, string LastNodeId, int LastNodeSequenceId
NodeState[] NodeStates, EdgeState[] EdgeStates
void UpdateOrder(OrderMsg), void StopOrder(), void PauseOrder(), void ResumeOrder()
```

### IAction (RobotActionController)
```csharp
ActionState[] ActionStates, bool HasActionRunning, bool HasActionWaitting
RobotAction? this[string actionId]
void AddOrderActions(Action[]), void AddInstantAction(Action[])
void StartOrderAction(string), void StopOrderAction(string="")
void ClearActions(), void PauseActions(), void ResumeActions()
```

### INavigation
```csharp
event Action<NavigationState>? OnNavigationFinished
bool IsReady, bool Driving, double VelocityX/VelocityY/Omega
NavigationState State { None, Idle, Initializing, Waiting, Moving, Rotating, Completed, Canceled, Paused, Error }
void Move(Node[], Edge[]), void MoveStraight(x, y), void Rotate(angle)
void Pause(), void Resume(), void UpdateOrder(lastBaseNodeId)
void CancelMovement(), void SetSpeed(speed), void Start(), void Stop()
```

### IPlcController (RobotPlcController)
```csharp
event OnPeripheralModeChanged(OperatingMode), OnButtonPressed(PeripheralButton)
event OnStop(StopStateType), OnSafetySpeedChanged(SafetySpeed)
bool IsReady, OperatingMode PeripheralMode, SafetySpeed SafetySpeed
bool Emergency, Bumper, LidarFrontProtectField, LidarBackProtectField, LidarFrontTimProtectField
bool LiftedUp, LiftedDown, LiftHome, LeftMotorReady, RightMotorReady, LiftMotorReady
bool ButtonStart, ButtonStop, ButtonReset, HasLoad, EnabledCharger, Charging, MutedBase, MutedLoad
void SetSystemState(SystemState), SetOperationState(OperationState)
void SetEnableCharger(bool), SetHorizontalLoad(bool), SetMutedBase(bool), SetMutedLoad(bool), SetRFMode(RFMode)
```

### IRobotController
```csharp
void Pause()   // → OrderManager.PauseOrder() + ActionManager.PauseActions()
void Resume()  // → OrderManager.ResumeOrder() + ActionManager.ResumeActions()
```

---

## 11. WatchThread (5Hz Background Monitor)

`RobotController` starts a `WatchTimer<RobotController>` at 200ms (5Hz) after initialization. All operations run inside `lock(_stateTransitionLock)`. Responsibilities:

1. **Fatal error detection**: Checks `ErrorManager.HasFatalError` → if true and not in Fault → `Pause()` + `Fire(EnterFault)`.
   Also triggered reactively by `ErrorManager.OnNewFatalError` event.

2. **PLC mode backup sync**: Detects missed `OnPeripheralModeChanged` events:
   - If in `Standby` (after ReleaseStop or init) → calls `SwichModeChanged(plcMode)` to enter correct mode
   - If PLC mode doesn't match current state → calls `SwichModeChanged(plcMode)` to correct
   - **Skipped when `_rfHandleHasPriority`** — RF Handle mode takes precedence over PLC switch

3. **Backup stop detection**: Reads PLC safety properties (`Emergency`, `Bumper`) directly. If any active and not in Stop → enters Stop state. **Always runs, even when RF Handle has priority** — safety overrides everything.

### Stop Release Flow

```
1. Safety triggers (EMC, Bumper, etc.) → OnStop(state!=None) → Pause + EnterStop
2. Safety clears → OnStop(None) → _stopCleared = true (wait for Start button)
3. Operator presses Start → OnButtonPressed(Start) checks:
   - IsInState(Stop) && _stopCleared
   - Double-checks all PLC safety properties are false
   → Fire(ReleaseStop) → System/Standby (Deep History)
4. WatchThread detects Standby → SwichModeChanged(plcMode) → Auto (Deep History)
   → Resumes order/navigation from where it was interrupted
```

### Mode Change Flow (with Order Preservation)

```
Auto/Executing/Moving → PLC switch to MANUAL
    → SwichModeChanged(MANUAL):
      1. IsInState(Auto) → Pause() → NavigationManager.Pause()
      2. Unsubscribe order events
      3. Fire(EnterManual) → exits Auto (Auto remembers Deep History: Executing/Moving)
      → State: Manual

PLC switch back to AUTOMATIC
    → SwichModeChanged(AUTOMATIC):
      1. Fire(EnterAuto) → Auto (Deep History: Executing/Moving restored)
      2. Subscribe order events (prevent duplicates: unsub then sub)
      3. Resume() → NavigationManager.Resume()
      → State: Auto/Executing/Moving (resumed)
```

---

## 12. Known Issues and TODOs

1. ~~**Pause/Resume not implemented**~~: **FIXED** - `Pause()` calls `OrderManager.PauseOrder()` + `ActionManager.PauseActions()`, `Resume()` calls `OrderManager.ResumeOrder()` + `ActionManager.ResumeActions()`. Used for Stop, mode changes, and fleet Pause/Resume via `START_PAUSE`/`STOP_PAUSE` actions.

2. ~~**HandleOrderStop fires EnterAuto**~~: **FIXED** - Now fires `CompleteExecution` for proper `Executing → Idle` transition.

3. **Many ACT sub-state events never triggered**: `StartDocking`, `CompleteDocking`, `StartCharging`, etc. are defined in the state machine but no code fires them. Actions are still placeholder implementations.

4. ~~**ReleaseStop not triggered**~~: **FIXED** - `OnButtonPressed(Start)` fires `ReleaseStop` when safety cleared + Start pressed. `ExitFault` is not yet triggered (manual intervention path TBD).

5. **Many actions are placeholders**: `DOCK_TO`, `START_CHARGING`, `STOP_CHARGING`, `SCRIPT`, `MOVE_STRAIGHT_TO_COOR`, `LIFT_ROTATE` either finish immediately or have empty implementations.

6. **RobotScriptAction has a bug**: In `Initialize()`, line 43: `if(!string.IsNullOrEmpty(para.Value))` should be `if(string.IsNullOrEmpty(para.Value))` - the logic is inverted.

7. **StopRobot vs EmergencyStop**: Two different stop methods:
   - `StopRobot()`: Sends zero velocity via `IInverseKinematics.SetVelocity(zeroTwist)` - used in Paused, Canceling, Manual, Service, Remote_Override, ACT, ExitMoving
   - `EmergencyStop()`: Sends zero velocity + calls `IInverseKinematics.Disable()` - used only in Stop and Fault states
   - Note: `ExitStop()` does not re-enable IK. This may need to be added for proper Stop release.

8. **Async blocking pattern**: Many async operations use `.GetAwaiter().GetResult()` which blocks threads. This is a known trade-off for state machine entry actions that must be synchronous.

9. **Paused state reserved for future use**: The `Paused` state (sub-state of Auto) with `PauseExecution`/`ResumeExecution` events exists in the state machine but is intentionally not used yet. Current pause/resume is done at order level (NavigationManager.Pause/Resume) without changing the state machine state.

10. ~~**WatchThread overrides RF Handle's Service state**~~: **FIXED** - Added `_rfHandleHasPriority` flag. WatchThread mode mismatch check is skipped when RF Handle has priority. Backup stop detection always runs.

11. ~~**PLC OnPeripheralModeChanged overrides RF Handle**~~: **FIXED** - PLC mode changes go through `OnPlcModeChanged()` wrapper which checks `_rfHandleHasPriority` before delegating to `SwichModeChanged()`.

12. ~~**RF Handle EStop doesn't sync StateMachine**~~: **FIXED** - `DetermineStateFromRfHandle()` no longer clears `_externallySetState` on EStop. ManualControlService stays in SafeStop but remembers Maintenance/Override state for recovery. RF Handle disconnect fires `OnRfModeChanged(None)` to release priority.

13. ~~**Race conditions between multiple threads**~~: **FIXED** - All state transition methods in RobotController use `lock(_stateTransitionLock)`: `OnPlcModeChanged`, `OnRfModeChanged`, `OnStop`, `OnButtonPressed`, `OnNewFatalError`, `WatchThreadCallback`.

---

## 12. Complete Flow Example: Order A→B(PICK)→C(DROP)

```
1. Fleet Manager sends OrderMsg [A→B→C] via MQTT
2. IRobotEventBus.PublishOrderMessageReceived()
3. RobotController.NewOrderUpdated()
   - Checks StateManager.IsInState(Auto) → true
   - Calls RobotOrderController.UpdateOrder(order)
4. HandleNewOrder():
   - ValidateNodes: A (no action), B (+PICK), C (+DROP)
   - ValidateEdges: A→B, B→C
   - AddAction(PICK, nodeB), AddAction(DROP, nodeC)
   - ActionManager.AddOrderActions([PICK, DROP])
5. OrderHandler() cycle:
   - HasNewOrder=true, Nodes[0] (A) has no actions
   - NavigationManager.Move(Nodes, Edges)
   - Fire(StartExecution) → State becomes Executing/Moving
   - Subscribe OnNavigationFinished, OnSafetySpeedChanged
6. Robot navigates A→B...
7. GetCurrentNode() detects robot at B:
   - LastNode = B, ClearLastNode()
   - B has PICK (HARD) → NavigationManager.Pause(), IsWaitingPaused=true
   - Enqueue PICK action
8. Navigation paused confirmed:
   - ActionManager.StartOrderAction("PICK")
   - ActionHard = PICK
9. PICK runs (200ms timer):
   - StartAction(): count=0
   - ExecuteAction() x10 cycles (~2s): count > 10 → LoadManager.ClearLoad() → FINISHED
10. PICK done, ActionHard = null
    - ActionWaitingRunning empty, IsWaitingPaused → NavigationManager.Resume()
11. Robot navigates B→C...
12. Same flow for DROP at C
13. NavigationFinished(Completed):
    - Last node C, no more actions
    - HandleOrderStop() → Dispose timer, Fire(CompleteExecution) → State = Auto/Idle
```

---

## 13. Enums Reference

### RobotStateType
```
System, Auto, Manual, Service, Remote_Override, Stop, Fault,
Initializing, Standby, Shutting_Down,
Idle, Executing, Paused, Canceling, Recovering,
Moving, ACT,
Docking, Docked, Charging, Undocking, Loading, Unloading, TechAction
```

### RobotEventType
```
// System: Initialize, InitializeCompleted, Shutdown, ShutdownCompleted
// Mode: EnterAuto, EnterManual, EnterService, EnterStop, EnterFault, ExitFault
// Auto: StartExecution, PauseExecution, ResumeExecution, CancelExecution, CompleteExecution, StartRecovery, CompleteRecovery, RemoteOverride
// Moving: StartMoving, StartNavigation, StartAvoidance, StartApproach, StartTracking, StartRepositioning, CompleteMoving
// ACT: StartACT, StartDocking, CompleteDocking, StartCharging, CompleteCharging, StartUndocking, CompleteUndocking, StartLoading, CompleteLoading, StartUnloading, CompleteUnloading, StartTechAction, CompleteTechAction, CompleteACT
// Stop: EmergencyStop, BumperTriggered, ProtectiveStop, ManualStop, ReleaseStop
// Fault: NavigationFault, LocalizationFault, ShielfFault, BatteryFault, DriverFault, PeripheralsFault, SafetyFault, CommunicationFault, FaultResolved
```

### OperatingMode (VDA5050)
```
AUTOMATIC, SEMIAUTOMATIC, MANUAL, SERVICE, TEACHIN
```

### SystemState (PLC)
```
INIT, PAUSED, IDLE, PROCCESSING, DOCKING, MAINTENANCE, MANUAL, OVERRIDE, CHARGING, ERROR
```

### StopStateType
```
EMC, Bumper, FrontProtective, BackProtective, TimProtective, None
```

### NavigationState
```
None, Idle, Initializing, Waiting, Moving, Rotating, Completed, Canceled, Paused, Error
```

### ActionType (VDA5050)
```
START_PAUSE, STOP_PAUSE, START_CHARGING, STOP_CHARGING, INIT_POSITION,
DOWNLOAD_MAP, ENABLE_MAP, DELETE_MAP, STATE_REQUEST, LOG_REPORT,
PICK, DROP, DETECT_OBJECT, FINE_POSITIONING, WAIT_FOR_TRIGGER,
CANCEL_ORDER, FACTSHEET_REQUEST, LIFT_ROTATE, ROTATE, ROTATE_KEEP_LIFT,
MUTED_BASE_ON, MUTED_BASE_OFF, MUTED_LOAD_ON, MUTED_LOAD_OFF,
DOCK_TO, MOVE_STRAIGHT_TO_COOR, MOVE_STRAIGHT_WITH_DISTANCE, EXAMPLE, SCRIPT
```

### ManualControlState
```
Initialization, Disabled, SafeStop, Active, Maintenance, Override, Default
```
