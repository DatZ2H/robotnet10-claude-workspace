---
description: Build shortcut — /build [target]. Targets: all (default), robotapp, fleet, or project name
---

# Build Command

Build the RobotNet10 solution or a specific project.

## Parse the argument: $ARGUMENTS

- If empty or "all": build the full solution
  ```bash
  dotnet build srcs/RobotNet10/RobotNet10.slnx
  ```

- If "robotapp": build RobotApp project
  ```bash
  dotnet build srcs/RobotNet10/RobotApp/RobotNet10.RobotApp/
  ```

- If "fleet" or "fleetmanager": build FleetManager project
  ```bash
  dotnet build srcs/RobotNet10/FleetManager/RobotNet10.FleetManager/
  ```

- Otherwise, treat the argument as a project name and search for a matching .csproj:
  1. Search with `Glob` for `**/*{argument}*.csproj`
  2. If exactly one match found, build it
  3. If multiple matches, list them and ask user to pick
  4. If no match, report error and suggest running `/build` with no args

## After build

- Report build result (success/failure)
- If build failed, show the first error and suggest fix
- If building full solution, report number of projects built
