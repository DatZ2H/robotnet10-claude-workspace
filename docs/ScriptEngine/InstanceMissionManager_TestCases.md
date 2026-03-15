# InstanceMissionManager Test Cases

## Tổng quan
InstanceMissionManager là component để quản lý và hiển thị danh sách các instance missions (mission instances đã được tạo và chạy). Component sử dụng MudTable với server-side pagination và search.

Tài liệu này mô tả các test case cần thiết để đảm bảo component hoạt động đúng.

---

## 1. Test Cases - Khởi tạo và Loading

### TC-001: Hiển thị table khi khởi tạo
**Mô tả:** Kiểm tra table hiển thị đúng khi component được load.

**Các bước:**
1. Navigate đến InstanceMissionManager page
2. Quan sát UI

**Kết quả mong đợi:**
- MudTable hiển thị với các columns: Mission Name, State, Score, Created At, Stopped At, Actions
- Loading indicator hiển thị khi đang load data
- Table height được tính toán đúng dựa trên container height
- Toolbar với search box và refresh button hiển thị

---

### TC-002: Khởi tạo SignalR connection
**Mô tả:** Kiểm tra InstanceMissionHub connection được khởi tạo đúng.

**Các bước:**
1. Navigate đến InstanceMissionManager page
2. Mở browser DevTools > Network tab
3. Quan sát SignalR connections

**Kết quả mong đợi:**
- InstanceMissionHub connection được khởi tạo
- Connection thành công (status 101 Switching Protocols)
- Không có lỗi connection trong console

---

### TC-003: Tính toán table height động
**Mô tả:** Kiểm tra table height được tính toán đúng dựa trên container.

**Các bước:**
1. Navigate đến InstanceMissionManager page
2. Resize browser window
3. Quan sát table height

**Kết quả mong đợi:**
- Table height được tính toán dựa trên container height
- Table height = container height - toolbar height - padding
- Table height cập nhật khi resize window
- Table không bị overflow

---

### TC-004: Load data ban đầu
**Mô tả:** Kiểm tra data được load đúng khi component khởi tạo.

**Các bước:**
1. Navigate đến InstanceMissionManager page
2. Đợi data load
3. Quan sát table

**Kết quả mong đợi:**
- LoadData được gọi với page 1, page size mặc định
- Data được hiển thị trong table
- Total items được hiển thị đúng trong pagination
- Loading indicator biến mất sau khi load xong

---

## 2. Test Cases - Table Display

### TC-005: Hiển thị mission name
**Mô tả:** Kiểm tra mission name được hiển thị đúng.

**Các bước:**
1. Load table với data
2. Quan sát Mission Name column

**Kết quả mong đợi:**
- Mission name hiển thị đúng cho mỗi row
- Text không bị truncate không mong muốn
- Format đúng

---

### TC-006: Hiển thị state với color coding
**Mô tả:** Kiểm tra state được hiển thị với đúng màu sắc.

**Các bước:**
1. Load table với missions ở các states khác nhau
2. Quan sát State column

**Kết quả mong đợi:**
- Running: Color.Success (green)
- Paused: Color.Warning (yellow)
- Pausing: Color.Warning (yellow)
- Resuming: Color.Info (blue)
- Completed: Color.Success (green)
- Canceled: Color.Default (gray)
- Error: Color.Error (red)
- Idle: Color.Default (gray)
- MudChip hiển thị đúng state name và color

---

### TC-007: Hiển thị score percentage
**Mô tả:** Kiểm tra score được hiển thị dưới dạng percentage.

**Các bước:**
1. Load table với missions có score
2. Quan sát Score column

**Kết quả mong đợi:**
- Score hiển thị dưới dạng: `(score / totalScore) * 100` với 2 decimal places
- Format: "XX.XX%"
- Hiển thị "0.00%" nếu score = 0
- Hiển thị "100.00%" nếu score = totalScore

---

### TC-008: Hiển thị Created At
**Mô tả:** Kiểm tra Created At được hiển thị đúng format.

**Các bước:**
1. Load table với missions
2. Quan sát Created At column

**Kết quả mong đợi:**
- Created At hiển thị format: "yyyy-MM-dd HH:mm:ss"
- Timezone đúng (UTC hoặc local time)
- Hiển thị cho tất cả missions

---

### TC-009: Hiển thị Stopped At
**Mô tả:** Kiểm tra Stopped At chỉ hiển thị khi mission đã stopped.

**Các bước:**
1. Load table với missions ở các states khác nhau
2. Quan sát Stopped At column

**Kết quả mong đợi:**
- Stopped At hiển thị format: "yyyy-MM-dd HH:mm:ss" cho missions ở states: Canceled, Completed, Error
- Stopped At hiển thị "--" cho missions ở states khác (Running, Paused, etc.)
- Format đúng

---

### TC-010: Hiển thị actions buttons theo state
**Mô tả:** Kiểm tra action buttons hiển thị đúng theo mission state.

**Các bước:**
1. Load table với missions ở các states khác nhau
2. Quan sát Actions column

**Kết quả mong đợi:**
- View Log button: Hiển thị cho tất cả missions
- Cancel button: Chỉ hiển thị cho Running, Paused, Pausing states
- Pause button: Chỉ hiển thị cho Running state
- Resume button: Chỉ hiển thị cho Paused state
- Buttons không hiển thị khi không applicable

---

## 3. Test Cases - Pagination

### TC-011: Pagination hoạt động đúng
**Mô tả:** Kiểm tra pagination hoạt động đúng với server-side data.

**Các bước:**
1. Load table với nhiều missions (> page size)
2. Click vào page 2
3. Quan sát data

**Kết quả mong đợi:**
- LoadData được gọi với page number đúng (MudTable uses 0-based, API uses 1-based)
- Data được load đúng cho page được chọn
- Total items được hiển thị đúng trong pagination
- Page number được highlight đúng

---

### TC-012: Change page size
**Mô tả:** Kiểm tra thay đổi page size hoạt động đúng.

**Các bước:**
1. Load table
2. Thay đổi page size (10, 25, 50, 100)
3. Quan sát data

**Kết quả mong đợi:**
- LoadData được gọi với page size mới
- Data được load đúng số lượng items theo page size
- Pagination cập nhật đúng
- Table height vẫn đúng

---

### TC-013: Navigate giữa các pages
**Mô tả:** Kiểm tra navigate giữa các pages hoạt động đúng.

**Các bước:**
1. Load table với nhiều pages
2. Navigate: Page 1 → Page 2 → Page 3 → Page 1
3. Quan sát data

**Kết quả mong đợi:**
- Data được load đúng cho mỗi page
- Loading indicator hiển thị khi đang load
- Không có duplicate data
- Page number được highlight đúng

---

## 4. Test Cases - Search

### TC-014: Search bằng text input
**Mô tả:** Kiểm tra search hoạt động khi nhập text.

**Các bước:**
1. Load table
2. Nhập text vào search box
3. Đợi debounce (1 second)
4. Quan sát data

**Kết quả mong đợi:**
- Search được trigger sau 1 second debounce
- LoadData được gọi với TxtSearch parameter đúng
- Table reload với kết quả search
- Total items cập nhật theo kết quả search

---

### TC-015: Search bằng Enter key
**Mô tả:** Kiểm tra search hoạt động khi nhấn Enter.

**Các bước:**
1. Load table
2. Nhập text vào search box
3. Nhấn Enter
4. Quan sát data

**Kết quả mong đợi:**
- Search được trigger ngay lập tức (không đợi debounce)
- LoadData được gọi với TxtSearch parameter đúng
- Table reload với kết quả search

---

### TC-016: Search bằng search icon click
**Mô tả:** Kiểm tra search hoạt động khi click vào search icon.

**Các bước:**
1. Load table
2. Nhập text vào search box
3. Click vào search icon (adornment)
4. Quan sát data

**Kết quả mong đợi:**
- Search được trigger ngay lập tức
- LoadData được gọi với TxtSearch parameter đúng
- Table reload với kết quả search

---

### TC-017: Search với empty text
**Mô tả:** Kiểm tra search với empty text trả về tất cả records.

**Các bước:**
1. Search với một text
2. Clear search text (để trống)
3. Đợi debounce hoặc nhấn Enter
4. Quan sát data

**Kết quả mong đợi:**
- LoadData được gọi với TxtSearch = ""
- Table reload với tất cả records
- Total items trở về tổng số records

---

### TC-018: Search với special characters
**Mô tả:** Kiểm tra search hoạt động với special characters.

**Các bước:**
1. Search với text chứa special characters (%, _, @, etc.)
2. Quan sát data

**Kết quả mong đợi:**
- Search không crash
- Kết quả search đúng (hoặc empty nếu không match)
- Special characters được handle đúng

---

## 5. Test Cases - Actions

### TC-019: View Log action
**Mô tả:** Kiểm tra View Log action mở dialog với đúng log content.

**Các bước:**
1. Click vào View Log button của một mission
2. Quan sát dialog

**Kết quả mong đợi:**
- MissionLogDialog được mở
- Dialog title: "Mission Log: {missionName}"
- Dialog hiển thị đúng log content
- Dialog có thể đóng bằng Close button
- Dialog size: MaxWidth.Large, FullWidth = true

---

### TC-020: Cancel Mission action - Dialog
**Mô tả:** Kiểm tra Cancel Mission action mở dialog xác nhận.

**Các bước:**
1. Click vào Cancel button của một Running mission
2. Quan sát dialog

**Kết quả mong đợi:**
- CancelMissionDialog được mở
- Dialog title: "Cancel Mission"
- Dialog có input field để nhập reason
- Dialog có Cancel và Confirm buttons
- Dialog size: MaxWidth.Small, FullWidth = true

---

### TC-021: Cancel Mission action - Success
**Mô tả:** Kiểm tra Cancel Mission action thành công.

**Các bước:**
1. Click vào Cancel button của một Running mission
2. Nhập reason (hoặc để trống)
3. Click Confirm
4. Quan sát UI

**Kết quả mong đợi:**
- CancelMissionAsync được gọi với mission ID và reason
- Reason format: "Canceled by {userName}: {userReason}" hoặc "Canceled by {userName}" nếu reason trống
- Success snackbar hiển thị
- Table reload để cập nhật state
- Mission state chuyển sang Canceled

---

### TC-022: Cancel Mission action - Cancel dialog
**Mô tả:** Kiểm tra Cancel Mission action khi cancel dialog.

**Các bước:**
1. Click vào Cancel button của một Running mission
2. Click Cancel trong dialog
3. Quan sát UI

**Kết quả mong đợi:**
- Dialog đóng
- Mission không bị cancel
- Table không reload
- Không có snackbar

---

### TC-023: Cancel Mission action - Error handling
**Mô tả:** Kiểm tra error handling khi Cancel Mission fail.

**Các bước:**
1. Simulate error khi cancel mission (disconnect network hoặc server error)
2. Click Cancel button và confirm
3. Quan sát UI

**Kết quả mong đợi:**
- Error được catch
- Error snackbar hiển thị với message
- Table không reload
- Mission state không thay đổi

---

### TC-024: Pause Mission action
**Mô tả:** Kiểm tra Pause Mission action.

**Các bước:**
1. Click vào Pause button của một Running mission
2. Quan sát UI

**Kết quả mong đợi:**
- PauseMissionAsync được gọi với mission ID
- Success snackbar hiển thị nếu thành công
- Error snackbar hiển thị nếu thất bại
- Table có thể reload để cập nhật state (nếu có auto-refresh)

---

### TC-025: Resume Mission action
**Mô tả:** Kiểm tra Resume Mission action.

**Các bước:**
1. Click vào Resume button của một Paused mission
2. Quan sát UI

**Kết quả mong đợi:**
- ResumeMissionAsync được gọi với mission ID
- Success snackbar hiển thị nếu thành công
- Error snackbar hiển thị nếu thất bại
- Table có thể reload để cập nhật state (nếu có auto-refresh)

---

### TC-026: Refresh button
**Mô tả:** Kiểm tra Refresh button reload table data.

**Các bước:**
1. Load table
2. Thực hiện một action (cancel mission, etc.)
3. Click Refresh button
4. Quan sát data

**Kết quả mong đợi:**
- Table reload với data mới nhất
- Current page và search text được giữ nguyên
- Loading indicator hiển thị khi đang load

---

## 6. Test Cases - Error Handling

### TC-027: Error khi load data fail
**Mô tả:** Kiểm tra error handling khi load data thất bại.

**Các bước:**
1. Simulate error (disconnect network hoặc server error)
2. Navigate đến InstanceMissionManager page
3. Quan sát UI

**Kết quả mong đợi:**
- Exception được catch
- Error snackbar hiển thị: "Error loading missions: {errorMessage}"
- Table hiển thị empty state (No matching records found)
- Loading indicator biến mất
- Không crash ứng dụng

---

### TC-028: Error khi SignalR connection fail
**Mô tả:** Kiểm tra error handling khi SignalR connection thất bại.

**Các bước:**
1. Block SignalR port hoặc tắt server
2. Navigate đến InstanceMissionManager page
3. Quan sát UI

**Kết quả mong đợi:**
- Connection error được handle
- Table vẫn có thể load data (nếu server-side API vẫn hoạt động)
- Không crash ứng dụng
- Error message hiển thị nếu cần

---

## 7. Test Cases - Performance

### TC-029: Performance khi load nhiều records
**Mô tả:** Kiểm tra performance khi có nhiều missions.

**Các bước:**
1. Tạo 1000+ missions
2. Load table
3. Navigate giữa các pages
4. Quan sát performance

**Kết quả mong đợi:**
- Table load trong thời gian hợp lý (< 2 giy cho mỗi page)
- Pagination hoạt động mượt mà
- UI không bị freeze
- Memory usage hợp lý

---

### TC-030: Performance khi search
**Mô tả:** Kiểm tra performance khi search với nhiều records.

**Các bước:**
1. Load table với 1000+ missions
2. Search với text
3. Quan sát performance

**Kết quả mong đợi:**
- Search hoàn tất trong thời gian hợp lý (< 2 giy)
- Debounce hoạt động đúng (không search mỗi keystroke)
- UI responsive
- Không có lag

---

## 8. Test Cases - Edge Cases

### TC-031: Empty state - No missions
**Mô tả:** Kiểm tra hiển thị khi không có missions.

**Các bước:**
1. Load table khi không có missions
2. Quan sát UI

**Kết quả mong đợi:**
- Table hiển thị "No matching records found"
- Pagination hiển thị 0 items
- Search box vẫn hoạt động
- Refresh button vẫn hoạt động

---

### TC-032: Empty state - No search results
**Mô tả:** Kiểm tra hiển thị khi search không có kết quả.

**Các bước:**
1. Load table với missions
2. Search với text không match
3. Quan sát UI

**Kết quả mong đợi:**
- Table hiển thị "No matching records found"
- Pagination hiển thị 0 items
- Clear search trả về tất cả records

---

### TC-033: Table height với toolbar height khác nhau
**Mô tả:** Kiểm tra table height tính toán đúng với toolbar height khác nhau.

**Các bước:**
1. Resize browser window
2. Quan sát table height
3. Kiểm tra toolbar height

**Kết quả mong đợi:**
- Table height = container height - max(toolbar height, 64) - padding
- Table không bị overflow
- Table scroll hoạt động đúng

---

### TC-034: Dispose và cleanup
**Mô tả:** Kiểm tra cleanup đúng khi component dispose.

**Các bước:**
1. Navigate đến InstanceMissionManager page
2. Navigate away
3. Quan sát Network tab và console

**Kết quả mong đợi:**
- InstanceMissionHub connection được stop
- Không có memory leaks
- Không có lỗi trong console

---

## 9. Test Cases - Integration

### TC-035: Tích hợp với Authentication
**Mô tả:** Kiểm tra tích hợp với authentication để lấy user name.

**Các bước:**
1. Login với một user
2. Cancel một mission
3. Kiểm tra reason trong log

**Kết quả mong đợi:**
- User name được lấy từ AuthenticationStateProvider
- Reason format: "Canceled by {userName}: {reason}"
- User name đúng với user đã login

---

### TC-036: Tích hợp với Snackbar
**Mô tả:** Kiểm tra snackbar hiển thị đúng cho các actions.

**Các bước:**
1. Thực hiện các actions (cancel, pause, resume)
2. Quan sát snackbar

**Kết quả mong đợi:**
- Success snackbar hiển thị khi action thành công
- Error snackbar hiển thị khi action thất bại
- Message đúng và rõ ràng
- Snackbar tự động dismiss sau vài giy

---

## Checklist Test Execution

### Pre-conditions
- [ ] Ứng dụng đã được build thành công
- [ ] Server đang chạy
- [ ] Database có dữ liệu test (missions)
- [ ] Authentication đã được configure

### Test Environment
- [ ] Browser: Chrome/Firefox/Edge (latest version)
- [ ] Screen resolution: 1920x1080 hoặc tương đương
- [ ] Network: Stable connection
- [ ] User đã login

### Test Execution Notes
- Ghi chú các bug phát hiện trong quá trình test
- Ghi lại screenshots cho các test case failed
- Ghi lại performance metrics nếu có vấn đề
- Test với nhiều số lượng missions khác nhau

---

## Known Issues và Limitations

### Đã Fix
- ✅ Table height không được tính toán đúng khi toolbar height thay đổi
- ✅ Search không hoạt động với Enter key
- ✅ Cancel mission reason không include user name

### Cần theo dõi
- Performance khi có quá nhiều missions (>10000)
- Memory usage khi pagination với nhiều pages
- Auto-refresh khi mission state thay đổi (có thể cần thêm feature)

---

## Test Priority

### High Priority (P0)
- TC-001, TC-002, TC-004, TC-005, TC-006, TC-010, TC-011, TC-014, TC-019, TC-020, TC-021, TC-027

### Medium Priority (P1)
- TC-003, TC-007, TC-008, TC-009, TC-012, TC-013, TC-015, TC-016, TC-017, TC-022, TC-023, TC-024, TC-025, TC-026, TC-028

### Low Priority (P2)
- TC-018, TC-029, TC-030, TC-031, TC-032, TC-033, TC-034, TC-035, TC-036

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
Missions Count: [Number of missions in test data]
```

---

*Tài liệu này được tạo tự động và cần được cập nhật khi có thay đổi trong InstanceMissionManager component.*

