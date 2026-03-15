---
description: Test by domain — /test-domain [domain]. Maps domain names to test projects
---

# Test Domain

Run tests for a specific domain without needing to remember project paths or frameworks.

## Parse the argument: $ARGUMENTS

## Domain-to-project mapping

| Domain keyword | Test project | Framework | Path |
|---------------|-------------|-----------|------|
| pathplanning, path, gpp | GlobalPathPlanner.Test | xUnit | srcs/RobotNet10/Tests/RobotNet10.GlobalPathPlanner.Test/ |
| map, mapmanager | MapManager.Test | NUnit | srcs/RobotNet10/Tests/RobotNet10.MapManager.Test/ |
| nav, navtune, navigation | NavigationTune.Test | xUnit | srcs/RobotNet10/Tests/RobotNet10.NavigationTune.Test/ |
| robot, robotmanager | RobotManager.Test | NUnit | srcs/RobotNet10/Tests/RobotNet10.RobotManager.Test/ |
| script, scriptengine | ScriptEngine.Test | NUnit | srcs/RobotNet10/Tests/RobotNet10.ScriptEngine.Test/ |
| storage, storagemanager | StorageManager.Test | xUnit | srcs/RobotNet10/Tests/RobotNet10.StorageManager.Test/ |
| slam, ceres | CeresSharp.Test | NUnit | srcs/RobotNet10/RobotApp/Communication/CeresSharp.Test/ |
| robotapp, app | RobotApp.Tests | xUnit | srcs/RobotNet10/RobotApp/RobotNet10.RobotApp.Tests/ |
| all | (all test projects) | mixed | srcs/RobotNet10/RobotNet10.slnx |

## Steps

1. Match the argument (case-insensitive) against the domain keywords above
2. If no match, list all available domains and ask user to pick
3. If "all", run: `dotnet test srcs/RobotNet10/RobotNet10.slnx`
4. Otherwise, run: `dotnet test <path>`
5. Report results: passed/failed/skipped counts
6. If failures, show the first 3 failure details
