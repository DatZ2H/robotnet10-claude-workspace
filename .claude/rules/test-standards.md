---
globs:
  - "srcs/**/Tests/**"
  - "srcs/**/*.Test/**"
  - "srcs/**/*Tests*/**"
---

# Test Standards

## Framework stack
- **Test framework:** NUnit 4.x
- **Mocking:** Moq
- **Database:** EF Core InMemory provider (for integration tests)
- **Assertions:** NUnit Assert + constraint model

## Existing test projects (5)

| Project | Tests for |
|---------|-----------|
| RobotNet10.GlobalPathPlanner.Test | Path planning algorithms (A*, graph traversal) |
| RobotNet10.MapManager.Test | Map data operations (CRUD, VDMA LIF) |
| RobotNet10.RobotManager.Test | Robot state management |
| RobotNet10.ScriptEngine.Test | Script compilation, execution, variables |
| RobotNet10.StorageManager.Test | Storage operations |

## Naming convention

```csharp
// Test class: {ClassUnderTest}Tests
public class GlobalPathPlannerTests

// Test method: {Method}_{Scenario}_{Expected}
[Test]
public void FindPath_WithValidNodes_ReturnsShortestPath()

[Test]
public void FindPath_WithUnreachableNode_ReturnsNull()
```

## Test structure (Arrange-Act-Assert)

```csharp
[Test]
public async Task ProcessOrderAsync_WithValidOrder_ReturnsSuccess()
{
    // Arrange
    var mockValidator = new Mock<IVda5050Validator>();
    mockValidator.Setup(v => v.ValidateOrder(It.IsAny<Order>()))
        .Returns(ValidationResult.Success);
    var processor = new OrderProcessor(mockValidator.Object);

    // Act
    var result = await processor.ProcessOrderAsync(validOrder);

    // Assert
    Assert.That(result.IsSuccess, Is.True);
}
```

## Guidelines
- One assert per test (prefer focused tests over multi-assert)
- Use `[SetUp]` and `[TearDown]` for shared setup/cleanup
- Use `[TestCase]` for parameterized tests
- Mock external dependencies (CANOpen, MQTT, file system)
- Do NOT mock the class under test
- Test both happy path and error cases
- Async tests: use `async Task` return type (not `async void`)
