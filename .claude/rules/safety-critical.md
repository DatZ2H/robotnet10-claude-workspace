---
globs:
  - "srcs/**/CANOpen/**"
  - "srcs/**/CiA402/**"
  - "srcs/**/Motion/**"
  - "srcs/**/Services/Navigation/**"
  - "srcs/**/Services/State/**"
  - "srcs/**/Devices/ISafety.cs"
  - "srcs/**/Devices/ICiA402Servo.cs"
  - "srcs/**/SLAM/**"
  - "srcs/**/CartographerSharp/**"
  - "srcs/**/CeresSharp/**"
---

# Safety-Critical Code — CAUTION

> [!WARNING]
> Code in this path controls PHYSICAL MOTORS and ROBOT MOVEMENT.
> Incorrect changes can cause collisions, equipment damage, or injury.

## Mandatory checklist before suggesting edits

Before proposing ANY change to safety-critical code, verify:

- [ ] **E-Stop path**: Emergency stop logic is NOT blocked or bypassed
- [ ] **CiA402 state transitions**: Changes follow CiA402 state machine spec (Not Ready -> Switch On Disabled -> Ready To Switch On -> Switched On -> Operation Enabled)
- [ ] **Velocity limits**: No hardcoded velocity values bypass IVelocityController limits
- [ ] **Unit test coverage**: Change is covered by existing or new unit tests
- [ ] **Timeout handling**: Async operations have appropriate timeouts
- [ ] **Error recovery**: Failure paths transition to safe state (motor disabled)
- [ ] **Pose accuracy**: SLAM/Localization changes do NOT degrade pose estimation (sai pose -> collision)
- [ ] **Native interop**: CeresSharp P/Invoke changes use SafeHandle, no memory leaks

## NEVER do

- Remove or weaken safety checks (ISafety interface methods)
- Bypass ISafety interface (handles E-Stop and safety chain)
- Hardcode velocity, acceleration, or torque values (use configuration)
- Change CiA402 state transitions without understanding the full spec
- Remove timeout guards on motor commands
- Catch and swallow exceptions in motor control paths

## Required patterns

- All velocity commands MUST go through `IVelocityController`
- Motor enable/disable MUST use CiA402 state machine transitions
- Emergency stop MUST be handled at every control layer
- All CANOpen SDO/PDO operations MUST have timeout handling
- State changes MUST be logged with structured logging

## Context for AI

- **CiA402**: CANOpen device profile for drives and motion control
- **CSV mode**: Cyclic Synchronous Velocity — IPC sends velocity targets every 20ms (50 Hz)
- **EDS file**: Electronic Data Sheet defining CANOpen object dictionary — see `eds/` folder
- **Driver**: MBDV-2X-520AC-F02 (dual-axis servo, MOONS brand)
- **Motor**: MSD180-10-075-20GSL (750W, gear ratio 10:1, no brake)
