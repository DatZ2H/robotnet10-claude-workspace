# AutoDiffManifold Implementation Tasks

**Ngày tạo**: 2024-12-19  
**Cập nhật**: 2024-12-19  
**Priority**: Medium (Có workaround, nhưng nên implement để đầy đủ)
**Estimated Effort**: ✅ **COMPLETE** - Cả C wrapper và C# wrapper đã hoàn thành

---

## Tổng Quan

`AutoDiffManifold` là replacement cho `AutoDiffLocalParameterization` trong Ceres 2.2.0. 

**Status**:
- ✅ **C Wrapper**: **ĐÃ HOÀN THÀNH** - Đã implement trong `ipc/CeresWrapper/`
- ✅ **C# Wrapper**: **ĐÃ HOÀN THÀNH** - Đã implement trong `CeresSharp/`

**Use Case chính**: `ConstantYawQuaternionPlus` trong Cartographer's IMU-based pose extrapolation.

**Reference**: 
- C Wrapper: `ipc/CeresWrapper/CSHARP_WRAPPER_FINAL_EVALUATION.md` section 14
- C# Wrapper: `CeresSharp/README.md` section "Example 3: AutoDiffManifold", `CeresSharp/IMPLEMENTATION_PROGRESS.md` section 8
- Tests: `CeresSharp.Test/EVALUATION.md` section "13. AutoDiffManifold (Test 25)"

---

## ✅ Implementation Checklist

### Phase 1: C Wrapper (`ipc/CeresWrapper/`) ✅ **ĐÃ HOÀN THÀNH**

**Status**: ✅ **COMPLETE** - Đã implement và test

**Implementation Details**:
- ✅ **Header**: `ceres_wrapper.h` lines 340-380
  - Callback typedefs: `ceres_autodiff_manifold_plus_t`, `ceres_autodiff_manifold_minus_t`
  - Functions: `ceres_wrapper_create_autodiff_manifold()`, `ceres_wrapper_free_autodiff_manifold()`
- ✅ **Implementation**: `ceres_wrapper.cc` lines 752-904
  - `AutoDiffManifoldWrapper` class extends `ceres::Manifold`
  - Implements `Plus()`, `Minus()`, `PlusJacobian()`, `MinusJacobian()`
  - Uses numeric differentiation for Jacobians (epsilon = 1e-8)
- ✅ **Tests**: `ceres_wrapper_test.c` lines 1325-1378
  - Test create/destroy
  - Test dimensions (ambient_size, tangent_size)
  - Test Problem integration
  - Test Euclidean manifold use case

**API Signature** (đã có sẵn):
```c
// Callbacks
typedef int (*ceres_autodiff_manifold_plus_t)(
    void* user_data,
    const double* x,
    const double* delta,
    double* x_plus_delta);

typedef int (*ceres_autodiff_manifold_minus_t)(
    void* user_data,
    const double* y,
    const double* x,
    double* y_minus_x);

// Functions
CERES_WRAPPER_EXPORT ceres_manifold_t* ceres_wrapper_create_autodiff_manifold(
    int ambient_size,
    int tangent_size,
    ceres_autodiff_manifold_plus_t plus_callback,
    ceres_autodiff_manifold_minus_t minus_callback,
    void* user_data);

CERES_WRAPPER_EXPORT void ceres_wrapper_free_autodiff_manifold(ceres_manifold_t* manifold);
```

**No action needed** - C wrapper đã sẵn sàng cho C# integration.

---

#### 1.1. Update Header File ✅ **COMPLETE**

**File**: `ipc/CeresWrapper/ceres_wrapper.h` lines 340-380

**Status**: ✅ **Đã có sẵn**

**No action needed**

---

#### 1.2. Implement C++ Wrapper ✅ **COMPLETE**

**File**: `ipc/CeresWrapper/ceres_wrapper.cc` lines 752-904

**Status**: ✅ **Đã implement**

**Implementation Highlights**:
- ✅ `AutoDiffManifoldWrapper` class extends `ceres::Manifold`
- ✅ Implements `Plus()` và `Minus()` via C callbacks
- ✅ Implements `PlusJacobian()` và `MinusJacobian()` với numeric differentiation (epsilon = 1e-8)
- ✅ Error handling với try-catch
- ✅ Memory management với `std::unique_ptr`

**No action needed**

---

#### 1.3. Build & Test C Wrapper ✅ **COMPLETE**

**File**: `ipc/CeresWrapper/ceres_wrapper_test.c` lines 1325-1378

**Status**: ✅ **Đã test**

**Test Coverage**:
- ✅ Create/destroy AutoDiff manifold
- ✅ Verify dimensions (ambient_size, tangent_size)
- ✅ Test Plus operation (via Problem integration)
- ✅ Test Problem integration (SetManifold, HasManifold, GetTangentSize)
- ✅ Test với Euclidean manifold use case

**No action needed**

---

### Phase 2: C# Wrapper (`srcs/RobotNet10/RobotApp/Communication/CeresSharp/`) ✅ **ĐÃ HOÀN THÀNH**

**Status**: ✅ **COMPLETE** - Đã implement và test

#### 2.1. Add Native Declarations ✅ **COMPLETE**

**File**: `srcs/RobotNet10/RobotApp/Communication/CeresSharp/Native/CeresNative.cs` lines 594-617

**Status**: ✅ **Đã implement**

**Implementation Details**:
- ✅ `CeresAutoDiffManifoldPlus` delegate (line 594)
- ✅ `CeresAutoDiffManifoldMinus` delegate (line 601)
- ✅ `ceres_wrapper_create_autodiff_manifold` P/Invoke declaration (line 608)
- ✅ `ceres_wrapper_free_autodiff_manifold` P/Invoke declaration (line 616)

**Reference C API** (từ `ceres_wrapper.h` lines 349-377):
```c
typedef int (*ceres_autodiff_manifold_plus_t)(
    void* user_data,
    const double* x,
    const double* delta,
    double* x_plus_delta);

typedef int (*ceres_autodiff_manifold_minus_t)(
    void* user_data,
    const double* y,
    const double* x,
    double* y_minus_x);

CERES_WRAPPER_EXPORT ceres_manifold_t* ceres_wrapper_create_autodiff_manifold(
    int ambient_size,
    int tangent_size,
    ceres_autodiff_manifold_plus_t plus_callback,
    ceres_autodiff_manifold_minus_t minus_callback,
    void* user_data);

CERES_WRAPPER_EXPORT void ceres_wrapper_free_autodiff_manifold(ceres_manifold_t* manifold);
```

**Tasks**:
- [x] Add `CeresAutoDiffManifoldPlus` delegate ✅
  - [x] `[UnmanagedFunctionPointer(CallingConvention.Cdecl)]` ✅
  - [x] Parameters: `IntPtr userData`, `IntPtr x`, `IntPtr delta`, `IntPtr xPlusDelta` ✅
  - [x] Return: `int` (1 = success, 0 = failure) ✅
- [x] Add `CeresAutoDiffManifoldMinus` delegate ✅
  - [x] `[UnmanagedFunctionPointer(CallingConvention.Cdecl)]` ✅
  - [x] Parameters: `IntPtr userData`, `IntPtr y`, `IntPtr x`, `IntPtr yMinusX` ✅
  - [x] Return: `int` (1 = success, 0 = failure) ✅
- [x] Add P/Invoke declaration `ceres_wrapper_create_autodiff_manifold` ✅
  - [x] `[DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]` ✅
  - [x] Parameters: `int ambientSize`, `int tangentSize`, `CeresAutoDiffManifoldPlus plus`, `CeresAutoDiffManifoldMinus minus`, `IntPtr userData` ✅
  - [x] Return: `IntPtr` (manifold handle) ✅
- [x] Add P/Invoke declaration `ceres_wrapper_free_autodiff_manifold` ✅
  - [x] `[DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]` ✅
  - [x] Parameter: `IntPtr manifold` ✅

**Estimated Time**: ✅ **COMPLETE** (1 hour)

**Example Code**:
```csharp
// Delegates
[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
internal delegate int CeresAutoDiffManifoldPlus(
    IntPtr userData,
    IntPtr x,
    IntPtr delta,
    IntPtr xPlusDelta);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
internal delegate int CeresAutoDiffManifoldMinus(
    IntPtr userData,
    IntPtr y,
    IntPtr x,
    IntPtr yMinusX);

// P/Invoke declarations
internal static partial class CeresNative
{
    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr ceres_wrapper_create_autodiff_manifold(
        int ambientSize,
        int tangentSize,
        CeresAutoDiffManifoldPlus plus,
        CeresAutoDiffManifoldMinus minus,
        IntPtr userData);

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void ceres_wrapper_free_autodiff_manifold(IntPtr manifold);
}
```

---

#### 2.2. Create AutoDiffManifold Class ✅ **COMPLETE**

**File**: `srcs/RobotNet10/RobotApp/Communication/CeresSharp/Core/AutoDiffManifold.cs`

**Status**: ✅ **Đã implement** - Complete implementation với 272 lines

**Implementation Details**:
- ✅ Public delegates: `PlusOperation`, `MinusOperation`
- ✅ Constructor với validation
- ✅ `CreateHandle()` static method với callback marshalling
- ✅ `Dispose()` method với GCHandle cleanup
- ✅ XML documentation comments
- ✅ Error handling với CeresException

**Reference**: 
- C API: `ceres_wrapper.h` lines 349-377
- C Implementation: `ceres_wrapper.cc` lines 752-904
- Similar pattern: `AutoDiffCostFunction.cs` (callback marshalling)

**Tasks**:
- [x] Create file structure ✅
  - [x] Namespace: `CeresSharp` ✅
  - [x] Using statements: `System`, `System.Runtime.InteropServices`, `CeresSharp.Native`, `CeresSharp.Native.SafeHandles` ✅
  - [x] Class: `public sealed class AutoDiffManifold : Manifold` ✅
- [x] Define public delegates (for C# users) ✅
  - [x] `PlusOperation` delegate: `(double[] x, double[] delta, double[] xPlusDelta) => bool` ✅ (line 56)
  - [x] `MinusOperation` delegate: `(double[] y, double[] x, double[] yMinusX) => bool` ✅ (line 65)
- [x] Implement constructor ✅
  - [x] Parameters: `int ambientSize`, `int tangentSize`, `PlusOperation plus`, `MinusOperation minus` ✅ (lines 77-81)
  - [x] Validate parameters (ambientSize > 0, tangentSize > 0, tangentSize <= ambientSize) ✅ (lines 108-115)
  - [x] Validate callbacks (not null) ✅ (lines 116-119)
  - [x] Call `CreateHandle()` static method ✅ (line 82)
  - [x] Store `GCHandle` for cleanup ✅ (line 86)
- [x] Implement `CreateHandle()` static method ✅
  - [x] Create `CallbackWrapper` object với callbacks và sizes ✅ (lines 125-130)
  - [x] Pin wrapper với `GCHandle.Alloc(wrapper)` ✅ (line 133)
  - [x] Create native callbacks (marshal C# delegates → C callbacks) ✅
    - [x] `CeresAutoDiffManifoldPlus`: Marshal arrays, call C# delegate, marshal result ✅ (lines 136-160)
    - [x] `CeresAutoDiffManifoldMinus`: Marshal arrays, call C# delegate, marshal result ✅ (lines 163-187)
  - [x] Pin native callbacks với `GCHandle.Alloc()` ✅ (lines 190-191)
  - [x] Call `CeresNative.ceres_wrapper_create_autodiff_manifold()` ✅ (lines 194-199)
  - [x] Error handling: Check for `IntPtr.Zero`, throw `CeresException` on failure ✅ (lines 201-204)
  - [x] Return `ManifoldHandle.Create(handle)` ✅ (line 206)
- [x] Implement `Dispose()` method ✅
  - [x] Free `GCHandle` cho wrapper ✅ (lines 214-217)
  - [x] Free `GCHandle` cho native callbacks (stored in wrapper) ✅ (lines 218-223)
  - [x] Call base `Dispose()` (frees native handle) ✅ (line 225)
- [x] Add XML documentation comments ✅
  - [x] Class summary với use case examples ✅ (lines 8-41)
  - [x] Method summaries ✅
  - [x] Parameter descriptions ✅
  - [x] Return value descriptions ✅
  - [x] Example code snippets ✅ (lines 24-39)

**Estimated Time**: ✅ **COMPLETE** (3-4 hours)

**Key Implementation Details**:
- **Callback marshalling**: Similar to `AutoDiffCostFunction` pattern
  - Marshal `IntPtr` → `double[]` arrays
  - Call C# delegate
  - Marshal result arrays back to `IntPtr`
- **Memory management**: 
  - Pin `GCHandle` cho wrapper object
  - Pin `GCHandle` cho native callbacks
  - Cleanup trong `Dispose()` (not finalizer)
- **Error handling**: 
  - Validate parameters trong constructor
  - Throw `CeresException` on failure
  - Handle `IntPtr.Zero` return from native
- **Ownership**: 
  - Problem owns manifold when set via `SetManifold()`
  - But we need to cleanup callbacks (GCHandles) when AutoDiffManifold is disposed
  - Similar pattern to `AutoDiffCostFunction`

**Example Structure** (reference from AutoDiffCostFunction):
```csharp
public sealed class AutoDiffManifold : Manifold
{
    private readonly GCHandle _wrapperHandle;
    private readonly int _ambientSize;
    private readonly int _tangentSize;

    public delegate bool PlusOperation(double[] x, double[] delta, double[] xPlusDelta);
    public delegate bool MinusOperation(double[] y, double[] x, double[] yMinusX);

    public AutoDiffManifold(
        int ambientSize,
        int tangentSize,
        PlusOperation plus,
        MinusOperation minus)
        : base(CreateHandle(ambientSize, tangentSize, plus, minus, out var wrapperHandle))
    {
        _ambientSize = ambientSize;
        _tangentSize = tangentSize;
        _wrapperHandle = wrapperHandle;
    }

    private static ManifoldHandle CreateHandle(...)
    {
        // Similar to AutoDiffCostFunction.CreateHandle()
        // 1. Create CallbackWrapper
        // 2. Pin với GCHandle
        // 3. Create native callbacks
        // 4. Pin native callbacks
        // 5. Call ceres_wrapper_create_autodiff_manifold()
        // 6. Return ManifoldHandle
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing && _wrapperHandle.IsAllocated)
        {
            base.Dispose(disposing);
            _wrapperHandle.Free();
            // Free native callback handles from wrapper
        }
    }

    private class CallbackWrapper
    {
        public PlusOperation Plus = null!;
        public MinusOperation Minus = null!;
        public int AmbientSize;
        public int TangentSize;
        public GCHandle[]? NativeCallbackHandles;
    }
}
```

---

#### 2.3. Add Tests ✅ **COMPLETE**

**File**: `srcs/RobotNet10/RobotApp/Communication/CeresSharp.Test/AutoDiffManifoldTests.cs`

**Status**: ✅ **Đã implement** - 10 comprehensive tests

**Implementation Details**:
- ✅ Test file structure với `[TestFixture]` class
- ✅ Basic creation test: `AutoDiffManifold_ShouldCreate()`
- ✅ Plus operation test: `AutoDiffManifold_Plus_ShouldWork()`
- ✅ Minus operation test: `AutoDiffManifold_Minus_ShouldWork()`
- ✅ Problem integration test: `AutoDiffManifold_WithProblem_ShouldWork()`
- ✅ Validation tests: `AutoDiffManifold_InvalidSizes_ShouldThrow()` (3 edge cases)
- ✅ Null checks: `AutoDiffManifold_NullCallbacks_ShouldThrow()` (2 tests)
- ✅ Memory management: `AutoDiffManifold_Dispose_ShouldNotCrash()`
- ✅ Using pattern: `AutoDiffManifold_UsingStatement_ShouldWork()`
- ✅ Different sizes: `AutoDiffManifold_DifferentSizes_ShouldWork()`
- ✅ Cost function integration: `AutoDiffManifold_WithCostFunction_ShouldWork()`

**Test Results**: ✅ **All 10 tests pass**

**Estimated Time**: ✅ **COMPLETE** (1-2 hours)

---

#### 2.4. Update Documentation ✅ **COMPLETE**

**Files Updated**:

1. **README.md** ✅
   - [x] Add AutoDiffManifold vào "Quick Reference" table ✅ (line 27)
   - [x] Add AutoDiffManifold vào "Available Manifolds" section ✅ (line 207)
   - [x] Add conversion example từ AutoDiffLocalParameterization ✅ (lines 495-578)
   - [x] Add usage example cho ConstantYawQuaternion ✅ (lines 549-572)

2. **IMPLEMENTATION_PROGRESS.md** ✅
   - [x] Mark AutoDiffManifold as implemented ✅ (lines 290-301)
   - [x] Update coverage statistics ✅ (line 554: "7 types (6 standard + AutoDiffManifold)")

3. **EVALUATION.md** ✅
   - [x] Add AutoDiffManifold test coverage section ✅ (lines 357-378)
   - [x] Update test statistics ✅ (line 472: "AutoDiffManifold Tests: 10 tests")

4. **CERES_READINESS_EVALUATION.md** (CartographerSharp)
   - [x] Update status từ "chưa có" → "có sẵn" ✅

**Estimated Time**: ✅ **COMPLETE** (1 hour)

---

## Summary

### Total Estimated Effort

| Phase | Tasks | Time | Status |
|-------|-------|------|--------|
| **Phase 1: C Wrapper** | Header + Implementation + Testing | 4-6 hours | ✅ **COMPLETE** |
| **Phase 2: C# Wrapper** | Native + Class + Tests + Docs | 6-8 hours | ✅ **COMPLETE** |
| **Total** | | **10-14 hours** | ✅ **COMPLETE** | |

### Priority

- **Current**: Medium
  - Có workaround (custom Manifold implementation)
  - Không block Cartographer conversion
  - Nhưng nên implement để đầy đủ và dễ dùng hơn

### Recommended Timeline

1. ✅ **Phase 1** (C Wrapper): **ĐÃ HOÀN THÀNH** - C wrapper đã sẵn sàng
2. ✅ **Phase 2** (C# Wrapper): **ĐÃ HOÀN THÀNH** - C# wrapper đã implement và test
3. ✅ **Testing**: **ĐÃ HOÀN THÀNH** - 10 comprehensive tests pass, sẵn sàng cho Cartographer integration
4. ✅ **Documentation**: **ĐÃ HOÀN THÀNH** - README, IMPLEMENTATION_PROGRESS, EVALUATION đã cập nhật
5. [ ] **Cartographer Integration**: Sẵn sàng cho real Cartographer use cases (ConstantYawQuaternion)
6. [ ] **Optimization**: PlusJacobian và MinusJacobian đã dùng numeric diff (đủ tốt), có thể optimize sau nếu cần

---

## Related Files

### C Wrapper ✅ **COMPLETE**
- ✅ `ipc/CeresWrapper/ceres_wrapper.h` lines 340-380 - Header declarations
- ✅ `ipc/CeresWrapper/ceres_wrapper.cc` lines 752-904 - Implementation
- ✅ `ipc/CeresWrapper/ceres_wrapper_test.c` lines 1325-1378 - Tests
- ✅ `ipc/CeresWrapper/CSHARP_WRAPPER_FINAL_EVALUATION.md` - Documentation

### C# Wrapper
- `srcs/RobotNet10/RobotApp/Communication/CeresSharp/Native/CeresNative.cs` - P/Invoke declarations
- `srcs/RobotNet10/RobotApp/Communication/CeresSharp/Core/AutoDiffManifold.cs` - Main class (NEW)
- `srcs/RobotNet10/RobotApp/Communication/CeresSharp/Core/Manifold.cs` - Base class
- `srcs/RobotNet10/RobotApp/Communication/CeresSharp.Test/AutoDiffManifoldTests.cs` - Tests (NEW)

### Documentation
- `srcs/RobotNet10/RobotApp/Communication/CeresSharp/README.md` - User guide
- `srcs/RobotNet10/RobotApp/Communication/CeresSharp/IMPLEMENTATION_PROGRESS.md` - Progress tracking
- `srcs/RobotNet10/RobotApp/Communication/CartographerSharp/CERES_READINESS_EVALUATION.md` - Evaluation doc

---

##Notes

### Implementation Considerations

1. **Memory Management**:
   - Problem owns manifold when set via `SetManifold()`
   - But we need to cleanup callbacks (GCHandles) when AutoDiffManifold is disposed
   - Similar pattern to `AutoDiffCostFunction`

2. **Jacobian Computation**:
   - ✅ **Đã implement trong C wrapper** với numeric differentiation (epsilon = 1e-8)
   - ✅ `PlusJacobian`: Finite difference w.r.t. `delta` parameter
   - ✅ `MinusJacobian`: Finite difference w.r.t. first argument `y`
   - ✅ **Không cần implement trong C#** - C wrapper đã handle

3. **Error Handling**:
   - ✅ **C wrapper**: Đã có error handling (try-catch, NULL checks)
   - [ ] **C# wrapper**: Validate parameters trong constructor
   - [ ] **C# wrapper**: Throw `CeresException` on failure
   - [ ] **C# wrapper**: Handle `IntPtr.Zero` return from native

4. **Testing Strategy**:
   - ✅ **C wrapper**: Đã test với Euclidean manifold
   - [ ] **C# wrapper**: Test với simple manifolds (Euclidean) - similar to C tests
   - [ ] **C# wrapper**: Test với ConstantYawQuaternion (Cartographer use case)
   - [ ] **C# wrapper**: Verify memory management (GCHandle cleanup)
   - [ ] **C# wrapper**: Test với Problem integration

---

---

##Implementation Notes

### C Wrapper Implementation Details ✅ **COMPLETE**

**File**: `ipc/CeresWrapper/ceres_wrapper.cc` lines 752-904

**Key Features**:
- ✅ `AutoDiffManifoldWrapper` class extends `ceres::Manifold`
- ✅ `Plus()` và `Minus()` call C callbacks directly
- ✅ `PlusJacobian()`: Numeric differentiation w.r.t. `delta` (epsilon = 1e-8)
- ✅ `MinusJacobian()`: Numeric differentiation w.r.t. first argument `y` (epsilon = 1e-8)
- ✅ Error handling với try-catch
- ✅ Memory management với `std::unique_ptr` và custom deleter

**Jacobian Computation** (đã implement trong C wrapper):
- **PlusJacobian**: Finite difference `(Plus(x, perturbed_delta) - Plus(x, 0)) / epsilon`
  - Perturb từng element của `delta`
  - Compute finite difference cho mỗi column
- **MinusJacobian**: Finite difference `(Minus(perturbed_y, x) - Minus(x, x)) / epsilon`
  - Perturb từng element của `y` (first argument)
  - Compute finite difference cho mỗi column
- Epsilon: `1e-8` (sufficient for most use cases)

**API Signature** (từ `ceres_wrapper.h`):
```c
// Callback types
typedef int (*ceres_autodiff_manifold_plus_t)(
    void* user_data,
    const double* x,              // ambient_size elements
    const double* delta,          // tangent_size elements
    double* x_plus_delta);        // ambient_size elements (output)

typedef int (*ceres_autodiff_manifold_minus_t)(
    void* user_data,
    const double* y,              // ambient_size elements
    const double* x,              // ambient_size elements
    double* y_minus_x);          // tangent_size elements (output)

// Functions
CERES_WRAPPER_EXPORT ceres_manifold_t* ceres_wrapper_create_autodiff_manifold(
    int ambient_size,
    int tangent_size,
    ceres_autodiff_manifold_plus_t plus_callback,
    ceres_autodiff_manifold_minus_t minus_callback,
    void* user_data);

CERES_WRAPPER_EXPORT void ceres_wrapper_free_autodiff_manifold(ceres_manifold_t* manifold);
```

**Test Coverage** (từ `ceres_wrapper_test.c`):
- ✅ Create/destroy AutoDiff manifold
- ✅ Verify dimensions (ambient_size, tangent_size)
- ✅ Test Plus operation (via Problem integration)
- ✅ Test Problem integration (SetManifold, HasManifold, GetTangentSize)
- ✅ Test với Euclidean manifold use case

### C# Wrapper Implementation Pattern

**Similar to AutoDiffCostFunction**:
- Use `GCHandle` để pin callbacks
- Marshal C# delegates → C callbacks
- Handle memory cleanup trong `Dispose()`
- Problem owns manifold, nhưng cần cleanup callbacks

**Reference Implementation**:
- ✅ `CeresSharp/Core/AutoDiffCostFunction.cs` - Pattern cho callback marshalling
- ✅ `CeresSharp/Core/Manifold.cs` - Base class structure
- ✅ `CeresSharp/Core/ProductManifold.cs` - Example của custom manifold với callbacks

**Key Differences từ AutoDiffCostFunction**:
- AutoDiffCostFunction: `double[][] parameters` → `double[] residuals`
- AutoDiffManifold: `double[] x, double[] delta` → `double[] xPlusDelta` (Plus)
- AutoDiffManifold: `double[] y, double[] x` → `double[] yMinusX` (Minus)
- Simpler array marshalling (single arrays, not jagged arrays)

**Memory Management Pattern**:
```csharp
// 1. Create CallbackWrapper object
var wrapper = new CallbackWrapper { Plus = plus, Minus = minus, ... };

// 2. Pin wrapper
var wrapperHandle = GCHandle.Alloc(wrapper);

// 3. Create native callbacks (marshal C# → C)
var plusCallback = new CeresNative.CeresAutoDiffManifoldPlus((userData, x, delta, xPlusDelta) =>
{
    var handle = GCHandle.FromIntPtr(userData);
    var wrapperObj = (CallbackWrapper)handle.Target!;
    
    // Marshal arrays
    var xArray = new double[wrapperObj.AmbientSize];
    var deltaArray = new double[wrapperObj.TangentSize];
    var xPlusDeltaArray = new double[wrapperObj.AmbientSize];
    
    Marshal.Copy(x, xArray, 0, wrapperObj.AmbientSize);
    Marshal.Copy(delta, deltaArray, 0, wrapperObj.TangentSize);
    
    // Call C# delegate
    var success = wrapperObj.Plus(xArray, deltaArray, xPlusDeltaArray);
    
    // Marshal result back
    if (success)
        Marshal.Copy(xPlusDeltaArray, 0, xPlusDelta, wrapperObj.AmbientSize);
    
    return success ? 1 : 0;
});

// 4. Pin native callbacks
var plusHandle = GCHandle.Alloc(plusCallback);
var minusHandle = GCHandle.Alloc(minusCallback);

// 5. Call native function
var handle = CeresNative.ceres_wrapper_create_autodiff_manifold(...);

// 6. Store handles for cleanup
wrapper.NativeCallbackHandles = new[] { plusHandle, minusHandle };
```

---

---

## C Wrapper API Reference

### Header Declarations (`ceres_wrapper.h` lines 340-380)

```c
// ============================================================================
// AutoDiff Manifold
// ============================================================================

/* Callback for AutoDiff manifold Plus operation */
/* x: point on manifold (ambient_size elements) */
/* delta: tangent vector (tangent_size elements) */
/* x_plus_delta: output point on manifold (ambient_size elements) */
/* Returns 1 on success, 0 on failure */
typedef int (*ceres_autodiff_manifold_plus_t)(
    void* user_data,
    const double* x,
    const double* delta,
    double* x_plus_delta);

/* Callback for AutoDiff manifold Minus operation */
/* y: point on manifold (ambient_size elements) */
/* x: point on manifold (ambient_size elements) */
/* y_minus_x: output tangent vector (tangent_size elements) */
/* Returns 1 on success, 0 on failure */
typedef int (*ceres_autodiff_manifold_minus_t)(
    void* user_data,
    const double* y,
    const double* x,
    double* y_minus_x);

/* Create AutoDiff manifold */
/* ambient_size: dimension of ambient space */
/* tangent_size: dimension of tangent space */
/* plus_callback: callback for Plus operation */
/* minus_callback: callback for Minus operation */
/* user_data: user data passed to callbacks */
CERES_WRAPPER_EXPORT ceres_manifold_t* ceres_wrapper_create_autodiff_manifold(
    int ambient_size,
    int tangent_size,
    ceres_autodiff_manifold_plus_t plus_callback,
    ceres_autodiff_manifold_minus_t minus_callback,
    void* user_data);

/* Free AutoDiff manifold */
CERES_WRAPPER_EXPORT void ceres_wrapper_free_autodiff_manifold(ceres_manifold_t* manifold);
```

### Test Example (`ceres_wrapper_test.c` lines 1325-1378)

**Euclidean Manifold Test**:
```c
// Plus: x + delta
int autodiff_manifold_plus_euclidean(void* user_data, 
    const double* x, const double* delta, double* x_plus_delta) {
    int size = *(int*)user_data;
    for (int i = 0; i < size; i++) {
        x_plus_delta[i] = x[i] + delta[i];
    }
    return 1;
}

// Minus: y - x
int autodiff_manifold_minus_euclidean(void* user_data,
    const double* y, const double* x, double* y_minus_x) {
    int size = *(int*)user_data;
    for (int i = 0; i < size; i++) {
        y_minus_x[i] = y[i] - x[i];
    }
    return 1;
}

// Usage
ceres_manifold_t* manifold = ceres_wrapper_create_autodiff_manifold(
    3, 3,  // ambient_size=3, tangent_size=3
    autodiff_manifold_plus_euclidean,
    autodiff_manifold_minus_euclidean,
    &ambient_size);
```

---

**Last Updated**: 2024-12-19  
**Status**: 
- ✅ **Phase 1 (C Wrapper)**: **COMPLETE** - Đã implement và test
- ✅ **Phase 2 (C# Wrapper)**: **COMPLETE** - Đã implement và test  
**Next Steps**: ✅ **READY FOR CARTOGRAPHER INTEGRATION** - AutoDiffManifold đã sẵn sàng cho ConstantYawQuaternion use case
