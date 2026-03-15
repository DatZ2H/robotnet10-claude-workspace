---
globs:
  - "srcs/**/*.Client/**"
  - "srcs/**/Components/**"
---

# Blazor UI Guidelines

## Render modes

RobotNet10 uses Blazor Web App with both server-side and WASM:
- **Server-side** (default): RobotApp and FleetManager main apps
- **WASM (Client)**: `RobotApp.Client/` and `FleetManager.Client/` — runs in browser
- Shared components in `Components/` must work in BOTH render modes

## SignalR hub connection patterns

RobotApp has 13 SignalR hubs. When building UI that consumes real-time data:
- Use `HubConnectionBuilder` in `OnInitializedAsync`
- Always handle reconnection: `hubConnection.Closed += async (error) => { ... }`
- Dispose hub connections in `IAsyncDisposable.DisposeAsync`
- Hub URL pattern: `NavigationManager.ToAbsoluteUri("/hubs/{hubName}")`

## Shared component conventions

Components in `Components/` projects are shared libraries:
- Namespace: `RobotNet10.{ComponentProject}`
- Use `[Parameter]` for component inputs, `[CascadingParameter]` sparingly
- Use `EventCallback<T>` for component outputs, NOT direct parent method calls
- CSS isolation: use `.razor.css` files, avoid global styles

## JS Interop

- Prefer `IJSRuntime.InvokeAsync<T>` over `InvokeVoidAsync` where return values exist
- JS files: colocate as `{Component}.razor.js`
- Always check `OperatingSystem.IsBrowser()` before browser-only APIs in shared components
- Dispose `IJSObjectReference` in `DisposeAsync`

## Common pitfalls

- Do NOT call `StateHasChanged()` from non-UI threads — use `InvokeAsync(StateHasChanged)`
- Do NOT use `Thread.Sleep` or blocking calls in server-side Blazor — blocks the circuit
- Interactive components need `@rendermode InteractiveServer` or `InteractiveWebAssembly`
- Shared component libraries should NOT specify render mode — let the consuming app decide
