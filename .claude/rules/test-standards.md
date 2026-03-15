---
globs:
  - "srcs/**/Tests/**"
  - "srcs/**/*.Test/**"
  - "srcs/**/*Tests*/**"
---

# Test Standards

## Framework stack
- **Test frameworks:** NUnit 4.x **AND** xUnit 2.9.x (mixed — check project before writing tests)
- **Mocking:** Moq
- **Database:** EF Core InMemory provider (for integration tests)
- **Assertions:** NUnit Assert + constraint model / xUnit Assert

## Existing test projects (8)

| Project | Location | Framework | Tests for |
|---------|----------|-----------|-----------|
| RobotNet10.GlobalPathPlanner.Test | Tests/ | **xUnit** | Path planning algorithms (A*, graph traversal) |
| RobotNet10.MapManager.Test | Tests/ | **NUnit** | Map data operations (CRUD, VDMA LIF) |
| RobotNet10.NavigationTune.Test | Tests/ | **xUnit** | Navigation tuning algorithms |
| RobotNet10.RobotManager.Test | Tests/ | **NUnit** | Robot state management |
| RobotNet10.ScriptEngine.Test | Tests/ | **NUnit** | Script compilation, execution, variables |
| RobotNet10.StorageManager.Test | Tests/ | **xUnit** | Storage operations |
| CeresSharp.Test | RobotApp/Communication/ | **NUnit** | Ceres solver native interop |
| RobotNet10.RobotApp.Tests | RobotApp/ | **xUnit** | RobotApp integration tests |

> [!IMPORTANT]
> Check the project's .csproj for `PackageReference` to confirm NUnit vs xUnit BEFORE writing tests.

## Naming convention

```csharp
// Test class: {ClassUnderTest}Tests
public class GlobalPathPlannerTests

// Test method: {Method}_{Scenario}_{Expected}
// NUnit:
[Test]
public void FindPath_WithValidNodes_ReturnsShortestPath()

// xUnit:
[Fact]
public void FindPath_WithValidNodes_ReturnsShortestPath()
```

## Test structure — NUnit (Arrange-Act-Assert)

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

## Test structure — xUnit (Arrange-Act-Assert)

```csharp
[Fact]
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
    Assert.True(result.IsSuccess);
}
```

## Guidelines — NUnit projects
- Use `[SetUp]` and `[TearDown]` for shared setup/cleanup
- Use `[TestCase]` for parameterized tests
- Assertions: `Assert.That(value, Is.EqualTo(expected))` (constraint model)

## Guidelines — xUnit projects
- Use constructor for setup, implement `IDisposable` for cleanup
- Use `[Theory]` + `[InlineData]` for parameterized tests
- Assertions: `Assert.Equal(expected, actual)`, `Assert.True(condition)`

## Guidelines — common
- One assert per test (prefer focused tests over multi-assert)
- Mock external dependencies (CANOpen, MQTT, file system)
- Do NOT mock the class under test
- Test both happy path and error cases
- Async tests: use `async Task` return type (not `async void`)
