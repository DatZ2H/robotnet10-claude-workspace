# RobotNet10 Documentation Hub

## Tài liệu dự án / Project Documentation

Chào mừng đến với trung tâm tài liệu của RobotNet10. Tài liệu được tổ chức theo cấu trúc module để dễ dàng tra cứu và bảo trì.

## Cấu trúc tài liệu / Documentation Structure

### 1. [Architecture](architecture/README.md)
Tài liệu về kiến trúc hệ thống, các thành phần và cách chúng tương tác với nhau.

- System architecture overview
- Component diagrams
- Data flow diagrams
- Communication patterns
- Technology stack details

### 1.5 [ScriptEngine](ScriptEngine/README.md)
Tài liệu về module ScriptEngine - shared library cho scripting.

- Web-based C# scripting with Monaco Editor
- Variables, Tasks, and Missions
- State machine and execution flow
- Extension APIs (IScriptResource)
- Used by both RobotApp and FleetManager

### 2. [RobotApp](robotapp/README.md)
Tài liệu chi tiết về ứng dụng điều khiển robot.

- Application architecture
- Core features and modules
- Hardware integration
- Navigation and control
- Web interface
- Configuration guide

### 3. [FleetManager](fleetmanager/README.md)
Tài liệu chi tiết về hệ thống quản lý đội xe.

- System architecture
- Fleet coordination logic
- Mission planning and dispatching
- Monitoring and analytics
- Web dashboard
- Configuration guide

### 4. [VDA 5050 Integration](vda5050/README.md)
Hướng dẫn triển khai và sử dụng tiêu chuẩn VDA 5050.

- VDA 5050 standard overview
- Message formats and schemas
- MQTT topics structure
- Implementation guidelines
- Testing and validation
- Interoperability considerations

### 5. [Development Guide](development/README.md)
Hướng dẫn cho developers tham gia phát triển dự án.

- Development environment setup
- Build and deployment
- Coding standards and conventions
- Testing strategies
- CI/CD pipeline
- Debugging and troubleshooting
- **[Project Structure & Conventions](development/ProjectStructure.md)** - Cấu trúc dự án, thư viện, và quy ước đặt tên
- **[Appccelerate.StateMachine Guide](development/AppccelerateStateMachine.md)** - Hướng dẫn sử dụng thư viện state machine
- **[Realtime Integration Guide](development/RealtimeIntegration.md)** - Tích hợp Linux realtime vào ScriptTask

### 6. [AI Collaboration Guide](ai-guide/README.md)
Hướng dẫn dành riêng cho AI agents tham gia phát triển dự án.

- Project context and goals
- Key technical decisions
- Code organization principles
- Important patterns and practices
- Common tasks and workflows

## Đối tượng sử dụng / Target Audience

| Tài liệu | Developers | Operators | AI Agents | System Integrators |
|----------|-----------|-----------|-----------|-------------------|
| Architecture | ✅ | ⭕ | ✅ | ✅ |
| RobotApp | ✅ | ✅ | ✅ | ✅ |
| FleetManager | ✅ | ✅ | ✅ | ✅ |
| VDA 5050 | ✅ | ⭕ | ✅ | ✅ |
| Development | ✅ | ❌ | ✅ | ⭕ |
| AI Guide | ⭕ | ❌ | ✅ | ❌ |

**Legend**: ✅ Primary audience | ⭕ Secondary audience | ❌ Not applicable

## Bắt đầu nhanh / Quick Start

**[QUICK START GUIDE](QUICK_START.md)** - Get started in 5-15 minutes!

**[DOCUMENTATION MAP](DOCUMENTATION_MAP.md)** - Find any documentation quickly!

### Cho Developers
1. Đọc [Quick Start Guide](QUICK_START.md) để setup nhanh (30-45 phút)
2. Xem [Development Guide](development/README.md) để hiểu chi tiết
3. Đọc [Architecture Overview](architecture/README.md) để hiểu tổng quan hệ thống
4. Chọn module muốn làm việc: [RobotApp](robotapp/README.md) hoặc [FleetManager](fleetmanager/README.md)

### Cho AI Agents
1. **Bắt buộc**: Đọc [AI Collaboration Guide](ai-guide/README.md) trước tiên (15 phút)
2. Xem [Quick Start Guide](QUICK_START.md) cho AI section (5 phút)
3. Review [Architecture](architecture/README.md) để hiểu context (skim 10 phút)
4. Tham khảo module-specific docs khi cần

### Cho System Integrators
1. Đọc [Quick Start Guide](QUICK_START.md) - Integrator section
2. Đọc [VDA 5050 Integration](vda5050/README.md) để hiểu giao thức
3. Review [Architecture](architecture/README.md) để hiểu hệ thống
4. Xem [RobotApp](robotapp/README.md) và [FleetManager](fleetmanager/README.md) configuration guides

## Quy tắc viết tài liệu / Documentation Guidelines

### Mục tiêu Tài liệu / Documentation Goals

Tài liệu trong thư mục `docs` tập trung vào:
- ✅ **Bối cảnh dự án**: Vấn đề cần giải quyết, mục tiêu, giải pháp
- ✅ **Kiến trúc hệ thống**: Cấu trúc tổng thể, các thành phần chính, luồng dữ liệu
- ✅ **Ý tưởng thiết kế**: Design rationale, quyết định công nghệ, patterns
- ✅ **Mermaid diagrams**: Sử dụng biểu đồ để minh họa kiến trúc và luồng
- ❌ **Không đi chi tiết lập trình**: Code examples, API endpoints, implementation details (xem Development Guide)

### Ngôn ngữ / Language
- Sử dụng song ngữ **Tiếng Việt / English**
- Tiêu đề chính bằng cả hai ngôn ngữ
- Nội dung kỹ thuật ưu tiên tiếng Anh (dễ hiểu với AI và developer quốc tế)
- Giải thích concept quan trọng bằng cả hai ngôn ngữ

### Cấu trúc / Structure
- Mỗi module có file README.md riêng
- Sử dụng markdown heading hierarchy (H1 > H2 > H3)
- **Ưu tiên Mermaid diagrams** để minh họa kiến trúc và luồng dữ liệu
- Tránh code examples chi tiết (chỉ khi cần thiết để giải thích concept)
- Links đến related documents

### Nội dung / Content
- **Rõ ràng**: Tránh mơ hồ, mô tả cụ thể
- **Bối cảnh**: Giải thích "tại sao" không chỉ "như thế nào"
- **Kiến trúc**: Mô tả cấu trúc và tương tác giữa các thành phần
- **Design rationale**: Giải thích lý do đằng sau các quyết định thiết kế
- **Visual**: Sử dụng diagrams (Mermaid) để minh họa concepts

## Cập nhật tài liệu / Documentation Updates

Tài liệu cần được cập nhật khi:
- Thêm feature mới
- Thay đổi architecture
- Update dependencies hoặc technology stack
- Phát hiện lỗi hoặc thiếu sót trong docs
- Thay đổi VDA 5050 implementation

## Hỗ trợ / Support

Nếu bạn (human hoặc AI) cần giúp đỡ về tài liệu:
1. Check FAQ trong từng section
2. Search trong docs bằng từ khóa
3. Liên hệ team lead

---

**Last Updated**: 2026-03-15
**Maintained By**: RobotNet10 Development Team
