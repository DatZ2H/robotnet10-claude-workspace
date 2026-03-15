# /onboard — Interactive Onboarding

You are onboarding a new developer to the RobotNet10 codebase. Guide them step by step.

## Step 1: Ask domain

Ask the developer which domain they will work on:

1. **Motion & Kinematics** — motor control, velocity, trajectory
2. **CANOpen/CiA402** — communication protocol, servo drives
3. **SLAM & Localization** — CartographerSharp, CeresSharp, localization, scan mapping
4. **Path Planning** — global/local path planning, A* algorithm
5. **State Machine** — robot state transitions, error handling
6. **Fleet/VDA5050** — fleet coordination, MQTT, VDA 5050 protocol
7. **Script Engine** — C# scripting, mission/task execution
8. **Map Editor** — map management, VDMA LIF, SVG canvas
9. **Nav Tuning** — navigation parameter tuning UI
10. **FleetManager general** — server-side, Docker, SQL Server
11. **RobotApp general** — robot-side, Ubuntu, real-time
12. **Full overview** — I need to understand everything

## Step 2: Read relevant files

Based on their choice, read:
- The domain's entry docs (see domain map in CLAUDE.md)
- Key source files (interfaces, main service classes)
- Related test files (to understand expected behavior)

> [!NOTE]
> Nếu domain không có entry docs trong domain map, thông báo cho dev và tập trung vào source code + interfaces thay thế.

## Step 3: Output summary

Provide a concise orientation:

1. **Domain overview** — what this domain does in 2-3 sentences
2. **Architecture** — how it fits in the 3-layer architecture
3. **Key files** — top 5-7 files to understand first (with paths)
4. **Key interfaces** — the main abstractions to know
5. **Dependencies** — what this domain depends on and what depends on it
6. **Safety notes** — if this domain is safety-critical, highlight the rules
7. **Start here** — recommend the single best file to open first and why

## Tone

Be welcoming but efficient. This developer wants to be productive quickly, not read an essay. Use Vietnamese with English technical terms.
