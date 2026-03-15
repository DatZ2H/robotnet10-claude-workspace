# Documentation Map / Bản đồ Tài liệu

## Quick Navigation / Điều hướng Nhanh

Tài liệu này giúp bạn tìm nhanh tài liệu cần thiết cho từng vai trò và nhiệm vụ cụ thể.

## By Role / Theo Vai trò

### For AI Agents
**Start here**: [AI Collaboration Guide](ai-guide/README.md) — **REQUIRED READING**

Essential documents:
1. [AI Guide](ai-guide/README.md) - How to work on this project — **REQUIRED**
2. [Architecture Overview](architecture/README.md) - System design
3. [FleetManager Docs](fleetmanager/README.md) - Core modules overview
   - [Identity Module](fleetmanager/Identity.md)
   - [MapEditor Module](fleetmanager/MapEditor.md)
   - [RobotConnections Module](fleetmanager/RobotConnections.md)
   - [RobotManager Module](fleetmanager/RobotManager.md)
   - [TrafficControl Module](fleetmanager/TrafficControl.md)
   - [ScriptEngine Module](fleetmanager/ScriptEngine.md)
   - [FleetManagerConfig Module](fleetmanager/FleetManagerConfig.md)
4. [ScriptEngine Docs](ScriptEngine/README.md) - Shared scripting library
5. [MapEditor Docs](MapEditor/README.md) - Shared map editor library
6. [VDA 5050 Integration](vda5050/README.md) - Protocol details

Then choose based on task:
- Working on robot: [RobotApp Docs](robotapp/README.md)
- Working on fleet manager: [FleetManager Docs](fleetmanager/README.md)
- Setting up environment: [Development Guide](development/README.md)

### For Developers (Human)
**Start here**: [Development Guide](development/README.md)

Recommended reading order:
1. [Project README](../README.md) - Project overview
2. [Development Guide](development/README.md) - Setup environment
3. [Architecture Overview](architecture/README.md) - Understand system
4. Choose component:
   - [RobotApp Docs](robotapp/README.md)
   - [FleetManager Docs](fleetmanager/README.md)
5. [VDA 5050 Integration](vda5050/README.md) - Protocol implementation

### For System Integrators
**Start here**: [Architecture Overview](architecture/README.md)

Essential documents:
1. [Architecture Overview](architecture/README.md) - System architecture
2. [VDA 5050 Integration](vda5050/README.md) - Integration protocol
3. [RobotApp Docs](robotapp/README.md) - Robot-side details
4. [FleetManager Docs](fleetmanager/README.md) - Server-side details

### For Learning
**Start here**: [Project README](../README.md)

Learning path:
1. [Project README](../README.md) - What is RobotNet10?
2. [Architecture Overview](architecture/README.md) - How does it work?
3. [VDA 5050 Integration](vda5050/README.md) - What is VDA 5050?
4. [Development Guide](development/README.md) - How to develop?

## By Task / Theo Nhiệm vụ

### Task: Implement VDA 5050 Feature
**Primary docs**:
- [VDA 5050 Integration](vda5050/README.md) - Protocol spec
- [AI Guide](ai-guide/README.md) - Implementation patterns

**Related docs**:
- [RobotApp](robotapp/README.md) or [FleetManager](fleetmanager/README.md) - Where to implement

### Task: Develop RobotApp Feature
**Primary docs**:
- [RobotApp Documentation](robotapp/README.md)
- [Development Guide](development/README.md)

**Related docs**:
- [Architecture Overview](architecture/README.md) - System context
- [VDA 5050 Integration](vda5050/README.md) - If feature involves communication

### Task: Develop FleetManager Feature
**Primary docs**:
- [FleetManager Documentation](fleetmanager/README.md)
- [Development Guide](development/README.md)

**Related docs**:
- [Architecture Overview](architecture/README.md) - System context
- [VDA 5050 Integration](vda5050/README.md) - If feature involves communication

### Task: Setup Development Environment
**Primary docs**:
- [Development Guide](development/README.md)
- [Project Structure & Conventions](development/ProjectStructure.md) - Project structure, libraries, naming conventions
- [Appccelerate.StateMachine Guide](development/AppccelerateStateMachine.md) - State machine library usage

### Task: Understand System Architecture
**Primary docs**:
- [Architecture Overview](architecture/README.md)

**Related docs**:
- [RobotApp Documentation](robotapp/README.md)
- [FleetManager Documentation](fleetmanager/README.md)

### Task: Debug MQTT/VDA 5050 Issues
**Primary docs**:
- [VDA 5050 Integration](vda5050/README.md)

**Related docs**:
- [Development Guide](development/README.md) - Debugging section
- [RobotApp](robotapp/README.md) or [FleetManager](fleetmanager/README.md) - Troubleshooting

### Task: Write Tests
**Primary docs**:
- [Development Guide](development/README.md) - Testing section
- [AI Guide](ai-guide/README.md) - Testing patterns

### Task: Work on SLAM / Cartographer
**Primary docs**:
- [Cartographer SLAM Reference](CartographerSharp/cartographer-slam-reference.md) - Algorithm details
- [Cartographer Parameters Guide](CartographerSharp/cartographer-parameters-guide.md) - Tuning

**Related docs**:
- [CartographerSharp Developer Guide](CartographerSharp/DEVELOPER_GUIDE.md) - Code internals
- [Localization Services Architecture](Localization/Localization_Services_Architecture.md) - Integration
- [CartographerSharp Assessment](CartographerSharp/ASSESSMENT.md) - Code quality

### Task: Deploy Application
**Primary docs**:
- [Development Guide](development/README.md) - Deployment section

**Related docs**:
- [RobotApp Documentation](robotapp/README.md) - RobotApp deployment
- [FleetManager Documentation](fleetmanager/README.md) - FleetManager deployment

## All Documents / Tất cả Tài liệu

### Core Documentation

| Document | Description | Audience |
|----------|-------------|----------|
| [README.md](../README.md) | Project overview | Everyone |
| [docs/README.md](README.md) | Documentation hub | Everyone |
| [DOCUMENTATION_MAP.md](DOCUMENTATION_MAP.md) | This file | Everyone |

### Technical Documentation

| Document | Description | Audience | Priority |
|----------|-------------|----------|----------|
| [Architecture Overview](architecture/README.md) | System architecture | Dev, AI, Integrator | High |
| [RobotApp Docs](robotapp/README.md) | Robot application | Dev, AI, Integrator | High |
| [FleetManager Docs](fleetmanager/README.md) | Fleet management | Dev, AI, Integrator | High |
| [VDA 5050 Integration](vda5050/README.md) | Protocol spec | Dev, AI, Integrator | High |
| [Development Guide](development/README.md) | Dev setup & workflow | Dev, AI | High |
| [Project Structure & Conventions](development/ProjectStructure.md) | Project structure, libraries, conventions | Dev, AI | Medium |
| [Appccelerate.StateMachine Guide](development/AppccelerateStateMachine.md) | State machine library usage | Dev, AI | Medium |
| [Realtime Integration Guide](development/RealtimeIntegration.md) | Linux realtime integration | Dev, AI | Medium |
| [AI Collaboration Guide](ai-guide/README.md) | AI agent guide | AI | High |

### SLAM & Cartographer Documentation

| Document | Description | Audience | Priority |
|----------|-------------|----------|----------|
| [Cartographer SLAM Reference](CartographerSharp/cartographer-slam-reference.md) | Paper analysis, algorithm details, class mapping | Dev, AI | High |
| [Cartographer Parameters Guide](CartographerSharp/cartographer-parameters-guide.md) | Parameter tables, tuning profiles for AMR | Dev, AI | High |
| [CartographerSharp Developer Guide](CartographerSharp/DEVELOPER_GUIDE.md) | Data lifecycle, scan matching, performance | Dev, AI | Medium |
| [CartographerSharp Assessment](CartographerSharp/ASSESSMENT.md) | Source code quality evaluation | Dev, AI | Medium |
| [Localization Services Architecture](Localization/Localization_Services_Architecture.md) | DI, state machines, event flow | Dev, AI | Medium |

## By Technology / Theo Công nghệ

### .NET 10 / C#
- [Development Guide](development/README.md) - .NET 10 setup
- [Project Structure & Conventions](development/ProjectStructure.md) - Project structure, libraries, conventions
- [AI Guide](ai-guide/README.md) - C# patterns

### Blazor
- [RobotApp Documentation](robotapp/README.md) - Blazor UI for robot
- [FleetManager Documentation](fleetmanager/README.md) - Blazor UI for fleet

### MQTT
- [VDA 5050 Integration](vda5050/README.md) - MQTT usage
- [Architecture Overview](architecture/README.md) - MQTT broker setup

### Database
- **SQL Server** (FleetManager): [FleetManager Documentation](fleetmanager/README.md) - Database schema
- **SQLite** (RobotApp): [RobotApp Documentation](robotapp/README.md) - Local database
- [Development Guide](development/README.md) - Database setup

### VDA 5050 v2.1.0
- [VDA 5050 Integration](vda5050/README.md) - Complete guide (v2.1.0)
- [AI Guide](ai-guide/README.md) - Implementation patterns
- **New in 2.1.0**: Corridors, Map Distribution & Management
- **Backward Compatible**: Works with v2.0.0 systems

### VDMA LIF
- [MapEditor Documentation](MapEditor/README.md) - Map standard
- [MapEditor VDMA LIF Standard](MapEditor/VDMA_LIF_Standard.md) - Standard details

## Reading Paths / Lộ trình Đọc

### Path 1: Quick Start (AI Agent)
**Time**: 30-45 minutes

1. [AI Guide](ai-guide/README.md) - 15 min
2. [Architecture Overview](architecture/README.md) - Skim (10 min)
3. [VDA 5050 Integration](vda5050/README.md) - Skim (10 min)
4. Task-specific docs - 10 min

**Outcome**: Ready to start coding

### Path 2: Quick Start (Developer)
**Time**: 1-2 hours

1. [Project README](../README.md) - 5 min
2. [Development Guide](development/README.md) - Follow setup (45 min)
3. [Architecture Overview](architecture/README.md) - 20 min
4. [VDA 5050 Integration](vda5050/README.md) - Skim (15 min)
5. Component docs - 20 min

**Outcome**: Environment setup, ready to code

### Path 3: Deep Dive (Complete Understanding)
**Time**: 4-6 hours

1. [Project README](../README.md) - 10 min
2. [Architecture Overview](architecture/README.md) - 60 min
3. [VDA 5050 Integration](vda5050/README.md) - 90 min
4. [RobotApp Documentation](robotapp/README.md) - 60 min
5. [FleetManager Documentation](fleetmanager/README.md) - 60 min
6. [Development Guide](development/README.md) - 45 min
7. [AI Guide](ai-guide/README.md) - 30 min (if AI)

**Outcome**: Complete system understanding

### Path 4: Integration Focus
**Time**: 2-3 hours

1. [Architecture Overview](architecture/README.md) - 30 min
2. [VDA 5050 Integration](vda5050/README.md) - 90 min
3. [RobotApp Documentation](robotapp/README.md) - MQTT section (20 min)
4. [FleetManager Documentation](fleetmanager/README.md) - MQTT section (20 min)

**Outcome**: Ready to integrate with third-party systems

## Documentation Updates / Cập nhật Tài liệu

### When to Update Documentation

Update docs when:
- Adding new feature
- Changing architecture
- Modifying VDA 5050 implementation
- Changing development workflow
- Finding errors or gaps

### How to Update

1. Identify which document(s) need updates
2. Make changes following documentation style
3. Update "Last Updated" date
4. Update this map if adding/removing documents
5. Commit with clear message: `docs: update [document name] - [reason]`

## Help / Trợ giúp

**Can't find what you need?**
1. Search across all docs using IDE/editor search
2. Check [docs/README.md](README.md) for overview
3. Ask project maintainers
4. Check git commit history for recent changes

**Documentation issues?**
- Found error? Create issue or fix directly
- Missing information? Request addition
- Unclear explanation? Request clarification

## Quick Reference / Tham khảo Nhanh

**I want to...**
- ✅ Understand the project → [Project README](../README.md)
- ✅ Setup environment → [Development Guide](development/README.md)
- ✅ Understand VDA 5050 → [VDA 5050 Integration](vda5050/README.md)
- ✅ Work on robot → [RobotApp Docs](robotapp/README.md)
- ✅ Work on fleet manager → [FleetManager Docs](fleetmanager/README.md)
- ✅ See system design → [Architecture Overview](architecture/README.md)
- ✅ AI agent onboarding → [AI Guide](ai-guide/README.md)
- ✅ Debug MQTT → [VDA 5050 Integration](vda5050/README.md)
- ✅ Write tests → [Development Guide](development/README.md)
- ✅ Work on SLAM → [Cartographer SLAM Reference](CartographerSharp/cartographer-slam-reference.md)
- ✅ Tune Cartographer → [Cartographer Parameters Guide](CartographerSharp/cartographer-parameters-guide.md)
- ✅ Deploy → [Development Guide](development/README.md)

---

**Last Updated**: 2026-03-15
**Purpose**: Navigation guide for all documentation
**Version**: 3.0 (Added SLAM/Cartographer research docs, task entries, quick reference links)
