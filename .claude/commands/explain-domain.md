# /explain-domain — Domain Concept Explainer

Explain a domain concept by tracing its implementation through the codebase.

## Input

The user provides a concept name, e.g.:
- "CiA402 state machine"
- "VDA 5050 order processing"
- "differential drive kinematics"
- "script engine compilation"
- "device abstraction pattern"

## Process

1. **Identify relevant files** — search the codebase for the concept (interfaces, classes, services)
2. **Trace the code path** — from entry point to implementation:
   - Where does the concept enter the system? (API, MQTT message, SignalR hub, timer)
   - What interfaces define the contract?
   - What classes implement the logic?
   - What dependencies are involved?
3. **Map the flow** — create a simple text-based flow diagram
4. **Highlight safety** — if the concept touches safety-critical code, note the constraints

## Output format

```
## {Concept Name}

### What it does
{1-2 sentence explanation}

### Code path
{Entry point} -> {Interface} -> {Implementation} -> {Output/Effect}

### Key files
1. {file path} — {role in the flow}
2. ...

### Flow
{Text-based sequence or data flow}

### Dependencies
- Depends on: {list}
- Used by: {list}

### Safety notes (if applicable)
{Safety constraints from safety-critical.md}

### Related concepts
{Links to related domain concepts}
```

## Guidelines
- Read actual source code, do not guess
- If the concept spans multiple domains, trace the full path
- Use Vietnamese with English technical terms
- Keep explanations practical — focus on "how it works" not theory
