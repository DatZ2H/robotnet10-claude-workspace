---
description: Check backward compatibility of Shared/ changes — list consumers, verify build
---

# Check Shared Contracts

Verify that changes to Shared/ projects don't break consumers.

## Steps

1. Run `git diff --name-only` to find changed files in Shared/ directories:
   - `Shared/RobotNet.VDA5050/`
   - `Shared/RobotNet10.Shared/`
   - `Shared/RobotNet10.MapEditor.Shared/`
   - `Shared/RobotNet10.NavigationTune.Shared/`
   - `Shared/RobotNet10.ScriptEngine.Shared/`

2. If no Shared/ files changed, report "No shared contract changes detected" and exit

3. For each changed Shared/ file:
   - Read the diff to identify what changed (added/removed/modified fields, methods, types)
   - Search for consumers using Grep: find all files that `using` the changed namespace or reference the changed type
   - Categorize consumers: RobotApp, FleetManager, Commons, Components, Tests

4. Assess breaking change risk:
   - **Breaking**: removed public field/method, changed type signature, renamed public member
   - **Safe**: added new optional field, added new method, internal changes
   - **Needs review**: changed default values, modified serialization attributes

5. Build the full solution to verify:
   ```bash
   dotnet build srcs/RobotNet10/RobotNet10.slnx
   ```

6. Run all tests:
   ```bash
   dotnet test srcs/RobotNet10/RobotNet10.slnx
   ```

7. Output report:
   ```
   ## Shared Contract Check

   ### Changed files
   - <list>

   ### Consumers affected
   - RobotApp: <list of files>
   - FleetManager: <list of files>
   - Tests: <list of files>

   ### Breaking change assessment
   - <per-change assessment>

   ### Build: PASS/FAIL
   ### Tests: PASS/FAIL (X passed, Y failed)
   ```
