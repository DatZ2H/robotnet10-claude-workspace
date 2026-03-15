# ScriptEditor Test Cases

## Tổng quan
ScriptEditor là component chính của Script Engine Editor, bao gồm:
- **Sidebar**: FileExplorer, VariableManager, TaskManager, MissionManager (có thể resize ngang)
- **Editor Area**: Monaco Editor để chỉnh sửa script files (có thể resize dọc)
- **Console Panel**: Hiển thị logs từ ScriptEngine (có thể resize dọc)

Tài liệu này mô tả các test case cần thiết để đảm bảo component hoạt động đúng.

---

## 1. Test Cases - Khởi tạo và Loading

### TC-001: Hiển thị loading overlay khi khởi tạo
**Mô tả:** Kiểm tra loading overlay hiển thị khi Workspace chưa được khởi tạo.

**Các bước:**
1. Navigate đến ScriptEditor page
2. Quan sát UI trong quá trình loading

**Kết quả mong đợi:**
- Loading overlay (MudOverlay với MudProgressCircular) hiển thị ngay lập tức
- Overlay có dark background và modal
- Overlay không tự động đóng (AutoClose="false")
- Overlay biến mất khi Workspace.IsInitialized = true

---

### TC-002: Khởi tạo SignalR connections
**Mô tả:** Kiểm tra các SignalR connections được khởi tạo đúng.

**Các bước:**
1. Navigate đến ScriptEditor page
2. Mở browser DevTools > Network tab
3. Quan sát SignalR connections

**Kết quả mong đợi:**
- FileManagerHub connection được khởi tạo
- ScriptManagerHub connection được khởi tạo
- Connections thành công (status 101 Switching Protocols)
- Không có lỗi connection trong console

---

### TC-003: Request edit permission khi khởi tạo
**Mô tả:** Kiểm tra edit permission được request tự động khi khởi tạo.

**Các bước:**
1. Navigate đến ScriptEditor page
2. Quan sát Network tab hoặc server logs

**Kết quả mong đợi:**
- RequestEditPermission được gọi tự động
- Permission được grant nếu ScriptEngine state là Idle
- Permission bị từ chối nếu ScriptEngine state không phải Idle
- Workspace.IsReadOnly được set đúng dựa trên permission

---

### TC-004: Khởi tạo Workspace với metadata references
**Mô tả:** Kiểm tra Workspace được khởi tạo với đúng metadata references.

**Các bước:**
1. Navigate đến ScriptEditor page
2. Đợi loading hoàn tất
3. Mở một file trong editor

**Kết quả mong đợi:**
- Workspace.Initialize được gọi với đúng parameters:
  - Metadata references từ ScriptResource
  - Using namespaces
  - AppGlobalType
  - Root folder structure
- Editor có IntelliSense hoạt động đúng
- Không có lỗi trong console

---

### TC-005: Khởi tạo JavaScript resize handlers
**Mô tả:** Kiểm tra JavaScript module cho resize handlers được load đúng.

**Các bước:**
1. Navigate đến ScriptEditor page
2. Đợi loading hoàn tất
3. Thử resize sidebar hoặc console

**Kết quả mong đợi:**
- scriptEditorResize.js được load thành công
- initializeLayout được gọi
- Sidebar có thể resize ngang
- Console có thể resize dọc
- Editor area điều chỉnh kích thước đúng

---

## 2. Test Cases - Layout và Resize

### TC-006: Resize sidebar ngang
**Mô tả:** Kiểm tra sidebar có thể resize ngang.

**Các bước:**
1. Hover vào border bên phải của sidebar
2. Drag để resize
3. Quan sát UI

**Kết quả mong đợi:**
- Cursor đổi thành col-resize khi hover
- Border highlight khi hover
- Sidebar width thay đổi khi drag
- Editor area điều chỉnh width tự động
- Min width: 200px, Max width: 600px
- Width được giữ lại sau khi refresh (nếu có persistence)

---

### TC-007: Resize console panel dọc
**Mô tả:** Kiểm tra console panel có thể resize dọc.

**Các bước:**
1. Hover vào resizer giữa Editor và Console
2. Drag để resize
3. Quan sát UI

**Kết quả mong đợi:**
- Cursor đổi thành row-resize khi hover
- Resizer highlight khi hover
- Console height thay đổi khi drag
- Editor area điều chỉnh height tự động
- Min height cho editor: 200px
- Height được giữ lại sau khi refresh (nếu có persistence)

---

### TC-008: Layout responsive khi resize window
**Mô tả:** Kiểm tra layout điều chỉnh đúng khi resize browser window.

**Các bước:**
1. Resize browser window
2. Quan sát layout

**Kết quả mong đợi:**
- Sidebar, Editor, Console điều chỉnh kích thước đúng
- Không có overflow hoặc scroll không mong muốn
- Layout vẫn hoạt động tốt ở các kích thước khác nhau

---

## 3. Test Cases - Edit Permission

### TC-009: Edit permission được grant khi state là Idle
**Mô tả:** Kiểm tra edit permission được grant khi ScriptEngine state là Idle.

**Các bước:**
1. Đảm bảo ScriptEngine state là Idle
2. Navigate đến ScriptEditor page
3. Thử edit một file

**Kết quả mong đợi:**
- RequestEditPermission thành công
- HasEditPermission trả về true
- Workspace.IsReadOnly = false
- Editor cho phép edit (không readonly)
- FileExplorer cho phép tạo/xóa/rename

---

### TC-010: Edit permission bị từ chối khi state không phải Idle
**Mô tả:** Kiểm tra edit permission bị từ chối khi ScriptEngine state không phải Idle.

**Các bước:**
1. Đảm bảo ScriptEngine state là Ready hoặc Running
2. Navigate đến ScriptEditor page
3. Thử edit một file

**Kết quả mong đợi:**
- RequestEditPermission vẫn được gọi (luôn thành công)
- HasEditPermission trả về false (vì state không phải Idle)
- Workspace.IsReadOnly = true
- Editor readonly (không cho phép edit)
- FileExplorer không cho phép tạo/xóa/rename

---

### TC-011: Edit permission bị revoke từ client khác
**Mô tả:** Kiểm tra edit permission bị revoke khi client khác request permission.

**Các bước:**
1. Mở ScriptEditor trên 2 clients (Client A và Client B)
2. Client A có edit permission
3. Client B request edit permission
4. Quan sát Client A

**Kết quả mong đợi:**
- Client A nhận EditPermissionRevoked event
- PermissionRevokedDialog hiển thị trên Client A
- Workspace.IsReadOnly = true trên Client A
- Editor trở thành readonly trên Client A
- Dialog chỉ có thể đóng bằng nút Reload (không thể click outside hoặc Escape)

---

### TC-012: Revoke edit permission khi dispose
**Mô tả:** Kiểm tra edit permission được revoke khi component dispose.

**Các bước:**
1. Navigate đến ScriptEditor page
2. Có edit permission
3. Navigate away hoặc close tab
4. Quan sát server logs

**Kết quả mong đợi:**
- RevokeEditPermission được gọi trước khi disconnect
- Permission được clear trên server
- Không có lỗi trong console

---

## 4. Test Cases - Component Integration

### TC-013: FileExplorer tích hợp với Editor
**Mô tả:** Kiểm tra FileExplorer tích hợp đúng với Editor.

**Các bước:**
1. Click vào một file trong FileExplorer
2. Quan sát Editor

**Kết quả mong đợi:**
- File được mở trong Editor
- Editor hiển thị đúng nội dung file
- Workspace.CurrentFile được set đúng
- Editor header hiển thị tên file

---

### TC-014: Editor tích hợp với Console
**Mô tả:** Kiểm tra Editor tích hợp đúng với Console.

**Các bước:**
1. Build scripts từ Editor
2. Quan sát Console

**Kết quả mong đợi:**
- Build messages hiển thị trong Console
- Error messages hiển thị trong Console
- Warning messages hiển thị trong Console
- Info messages hiển thị trong Console

---

### TC-015: VariableManager tích hợp với ScriptEngine
**Mô tả:** Kiểm tra VariableManager hiển thị đúng variables từ ScriptEngine.

**Các bước:**
1. Build scripts thành công
2. Quan sát VariableManager trong sidebar

**Kết quả mong đợi:**
- Variables được load và hiển thị
- Chỉ hiển thị variables có PublicRead = true
- Values được hiển thị đúng
- Có thể edit variables có PublicWrite = true

---

### TC-016: TaskManager tích hợp với ScriptEngine
**Mô tả:** Kiểm tra TaskManager hiển thị đúng tasks từ ScriptEngine.

**Các bước:**
1. Build scripts thành công
2. Start ScriptEngine
3. Quan sát TaskManager trong sidebar

**Kết quả mong đợi:**
- Tasks được load và hiển thị khi state là Ready hoặc Running
- Task states được hiển thị đúng
- Có thể enable/disable tasks
- Tasks với AutoStart = true tự động start

---

### TC-017: MissionManager tích hợp với ScriptEngine
**Mô tả:** Kiểm tra MissionManager hiển thị đúng missions từ ScriptEngine.

**Các bước:**
1. Build scripts thành công
2. Start ScriptEngine
3. Quan sát MissionManager trong sidebar

**Kết quả mong đợi:**
- Missions được load và hiển thị khi state là Ready hoặc Running
- Mission parameters được hiển thị đúng
- Có thể instantiate missions
- Missions với AutoStart = true tự động start

---

## 5. Test Cases - State Management

### TC-018: UI cập nhật khi ScriptEngine state thay đổi
**Mô tả:** Kiểm tra UI cập nhật đúng khi ScriptEngine state thay đổi.

**Các bước:**
1. Build scripts
2. Quan sát Editor header buttons
3. Start ScriptEngine
4. Quan sát Editor header buttons

**Kết quả mong đợi:**
- Build button enabled khi state là Idle hoặc BuildError
- Start button enabled khi state là Ready
- Stop button enabled khi state là Running
- Reset button enabled khi state là Idle, Ready, BuildError, Running, hoặc Fault
- Buttons disabled đúng theo state

---

### TC-019: Editor readonly state theo ScriptEngine state
**Mô tả:** Kiểm tra Editor readonly state thay đổi theo ScriptEngine state.

**Các bước:**
1. Đảm bảo ScriptEngine state là Idle
2. Mở một file trong Editor
3. Thử edit
4. Build scripts (chuyển sang Ready state)
5. Thử edit

**Kết quả mong đợi:**
- Editor cho phép edit khi state là Idle
- Editor trở thành readonly khi state không phải Idle
- Editor trở lại cho phép edit khi state quay về Idle

---

### TC-020: Workspace state đồng bộ với ScriptEngine
**Mô tả:** Kiểm tra Workspace state đồng bộ đúng với ScriptEngine state.

**Các bước:**
1. Thực hiện các thao tác (build, start, stop, reset)
2. Kiểm tra Workspace state

**Kết quả mong đợi:**
- Workspace.IsReadOnly đồng bộ với ScriptEngine state
- Workspace.CurrentFile được cập nhật đúng
- Workspace.Folders và Workspace.Files được cập nhật đúng

---

## 6. Test Cases - Error Handling

### TC-021: Xử lý lỗi khi SignalR connection fail
**Mô tả:** Kiểm tra xử lý lỗi khi SignalR connection không thể kết nối.

**Các bước:**
1. Tắt server hoặc block SignalR port
2. Navigate đến ScriptEditor page
3. Quan sát UI

**Kết quả mong đợi:**
- Loading overlay vẫn hiển thị
- Error message hiển thị (nếu có)
- Không crash ứng dụng
- Có thể retry connection

---

### TC-022: Xử lý lỗi khi JavaScript module không load
**Mô tả:** Kiểm tra xử lý lỗi khi scriptEditorResize.js không load được.

**Các bước:**
1. Block scriptEditorResize.js trong browser DevTools
2. Navigate đến ScriptEditor page
3. Quan sát UI

**Kết quả mong đợi:**
- JSException được catch
- Ứng dụng vẫn hoạt động (không crash)
- Resize có thể không hoạt động nhưng không ảnh hưởng chức năng khác

---

### TC-023: Xử lý lỗi khi Workspace initialization fail
**Mô tả:** Kiểm tra xử lý lỗi khi Workspace initialization thất bại.

**Các bước:**
1. Simulate lỗi trong ResourceResolver hoặc FileManagerClient
2. Navigate đến ScriptEditor page
3. Quan sát UI

**Kết quả mong đợi:**
- Exception được catch
- Loading overlay có thể không biến mất hoặc hiển thị error
- Không crash ứng dụng
- Error message hiển thị cho user

---

## 7. Test Cases - Cleanup và Dispose

### TC-024: Cleanup khi component dispose
**Mô tả:** Kiểm tra cleanup đúng khi component dispose.

**Các bước:**
1. Navigate đến ScriptEditor page
2. Navigate away
3. Quan sát Network tab và console

**Kết quả mong đợi:**
- EditPermissionRevoked event được unsubscribe
- JavaScript module cleanup được gọi
- Edit permission được revoke
- SignalR connections được stop
- Không có memory leaks
- Không có lỗi trong console

---

### TC-025: Xử lý JSDisconnectedException khi dispose
**Mô tả:** Kiểm tra xử lý JSDisconnectedException khi JS context đã disconnect.

**Các bước:**
1. Navigate đến ScriptEditor page
2. Close tab đột ngột
3. Quan sát server logs

**Kết quả mong đợi:**
- JSDisconnectedException được catch
- Không có lỗi trong server logs
- Cleanup vẫn được thực hiện đúng

---

## 8. Test Cases - Performance

### TC-026: Performance khi khởi tạo với nhiều files
**Mô tả:** Kiểm tra performance khi workspace có nhiều files.

**Các bước:**
1. Tạo workspace với 100+ files
2. Navigate đến ScriptEditor page
3. Đo thời gian loading

**Kết quả mong đợi:**
- Loading time < 5 giy cho 100 files
- UI không bị freeze
- Workspace initialization hoàn tất trong thời gian hợp lý

---

### TC-027: Performance khi resize layout
**Mô tả:** Kiểm tra performance khi resize sidebar và console.

**Các bước:**
1. Resize sidebar liên tục
2. Resize console liên tục
3. Quan sát performance

**Kết quả mong đợi:**
- Resize mượt mà, không lag
- UI responsive
- Không có jank hoặc stutter

---

## 9. Test Cases - Edge Cases

### TC-028: Multiple clients cùng lúc
**Mô tả:** Kiểm tra behavior khi có nhiều clients mở cùng lúc.

**Các bước:**
1. Mở ScriptEditor trên 3+ clients
2. Thực hiện các thao tác trên các clients khác nhau
3. Quan sát behavior

**Kết quả mong đợi:**
- Chỉ 1 client có edit permission tại một thời điểm
- Clients khác được notify khi permission bị revoke
- File changes được sync qua SignalR events
- Không có conflict hoặc race conditions

---

### TC-029: Reconnect sau khi disconnect
**Mô tả:** Kiểm tra behavior khi SignalR reconnect.

**Các bước:**
1. Navigate đến ScriptEditor page
2. Disconnect network tạm thời
3. Reconnect network
4. Quan sát behavior

**Kết quả mong đợi:**
- SignalR tự động reconnect
- State được reload sau khi reconnect
- Edit permission được request lại
- UI cập nhật đúng

---

### TC-030: Navigate away và quay lại
**Mô tả:** Kiểm tra behavior khi navigate away và quay lại.

**Các bước:**
1. Navigate đến ScriptEditor page
2. Navigate đến page khác
3. Navigate quay lại ScriptEditor
4. Quan sát behavior

**Kết quả mong đợi:**
- Component được dispose đúng khi navigate away
- Component được khởi tạo lại khi quay lại
- State được reload
- Không có memory leaks

---

## Checklist Test Execution

### Pre-conditions
- [ ] Ứng dụng đã được build thành công
- [ ] Server đang chạy
- [ ] Database có dữ liệu test
- [ ] ScriptEngine đã được configure đúng

### Test Environment
- [ ] Browser: Chrome/Firefox/Edge (latest version)
- [ ] Screen resolution: 1920x1080 hoặc tương đương
- [ ] Network: Stable connection
- [ ] JavaScript enabled

### Test Execution Notes
- Ghi chú các bug phát hiện trong quá trình test
- Ghi lại screenshots cho các test case failed
- Ghi lại performance metrics nếu có vấn đề
- Test với nhiều browsers khác nhau

---

## Known Issues và Limitations

### Đã Fix
- ✅ Edit permission không được request tự động khi khởi tạo
- ✅ Workspace không được khởi tạo đúng khi SignalR chưa connect
- ✅ Loading overlay không hiển thị đúng

### Cần theo dõi
- Performance khi có quá nhiều files (>1000 items)
- Memory leak khi navigate nhiều lần
- SignalR reconnection behavior trong môi trường network không ổn định

---

## Test Priority

### High Priority (P0)
- TC-001, TC-002, TC-003, TC-004, TC-009, TC-010, TC-011, TC-013, TC-018, TC-019, TC-024

### Medium Priority (P1)
- TC-005, TC-006, TC-007, TC-008, TC-012, TC-014, TC-015, TC-016, TC-017, TC-020, TC-021, TC-022, TC-023

### Low Priority (P2)
- TC-025, TC-026, TC-027, TC-028, TC-029, TC-030

---

## Test Results Template

```
Test Case ID: TC-XXX
Test Date: YYYY-MM-DD
Tester: [Name]
Status: Pass/Fail/Blocked
Notes: [Any additional notes]
Screenshots: [If applicable]
Browser: [Browser name and version]
```

---

*Tài liệu này được tạo tự động và cần được cập nhật khi có thay đổi trong ScriptEditor component.*

