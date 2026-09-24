# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-09-24

### 🚀 Nâng cấp & Tính năng mới
- **Xác minh Mạng Thủ công & Kiểm thử Tuyến đường (Smart Route Verification)**:
  - Cho phép người dùng nhập trực tiếp bất kỳ địa chỉ IP, tên miền (Domain), hoặc URL trang web (`http/https`) để kiểm tra thông tuyến và xác định card mạng/gateway phụ trách.
  - Tự động nhận diện cấu trúc URL, bóc tách host, port và phân giải DNS IPv4/IPv6 nhanh chóng.
  - Tích hợp hàm truy vấn tuyến đường hệ điều hành `queryRouteForIp` qua lệnh PowerShell `Find-NetRoute` và fallback sang `route print` của Windows.
- **Tự động Chẩn đoán Nguyên nhân Gốc (Root Cause Analysis)**:
  - Tự động phát hiện lỗi định tuyến lệch tuyến (Misrouted Route): Cảnh báo khi dải IP nội bộ LAN bị chuyển tiếp ra Gateway Internet hoặc ngược lại.
  - Đo kiểm toàn diện 6 bước: Phân giải DNS, kiểm tra Gateway Windows thực tế, bắt tay socket TCP port, kiểm tra mã phản hồi HTTP HEAD, và ping ICMP latency.
- **Khắc phục Tuyến đường 1-Click (⚡ Sửa Route Nhanh)**:
  - Tự động tạo và thực thi lệnh thêm static route chuẩn xác (`route add -p ...`) chỉ với 1 cú click chuột, tự động kích hoạt kiểm tra lại để người dùng đối soát ngay lập tức.
- **Tối ưu Bố cục Đa Cột & Không gian Hiển thị**:
  - Tái thiết kế bố cục các tab Chẩn đoán (Diagnostics), Cấu hình (Configuration), và Giới thiệu (About) theo phân cột trực quan, loại bỏ khoảng trống thừa và cho phép quan sát toàn bộ quy trình mà không cần thao tác cuộn phức tạp.
- **Nút chuyển đổi Ngôn ngữ Nhanh (QuickButton Language Switcher)**:
  - Chuyển đổi trực tiếp 1-click giữa các ngôn ngữ Tiếng Việt (VI), Tiếng Anh (EN), và Tiếng Trung (ZH) trên thanh Header với tự động nhận diện ngôn ngữ hệ điều hành Windows.

### 🐛 Sửa lỗi & Tối ưu hóa
- Bổ sung 22 bộ kiểm thử tự động (Unit Tests & Widget Tests) cho URL parser, Verification Service, Misroute detection và Quick Fix.
- Đảm bảo 100% không còn lỗi linter và layout overflow (`dart analyze: No issues found!`).
- Hoàn thiện script khởi chạy `debug.bat` hỗ trợ ưu tiên chạy bản build Debug mới nhất.

### 📦 Phát hành
- Đồng bộ version 1.2.0+2 trong pubspec.yaml, constants.dart, Runner.rc, ABOUT.txt, build.bat, USERGUIDE.md, README.md, RELEASE_NOTES.md.

---

## [1.1.0] - 2026-09-23

### Added
- **Apple Liquid Glass & Bento Card UI Remake**: Re-architected entire user interface following `JA_Mini_Showcase` design system.
- **17 Modular Glassmorphic Widgets** (`lib/modules/ui/widgets/`):
  - `GlassScaffold` & multi-layer mesh gradient `GlassBackground` with ambient floating orbs.
  - `BentoCard`, `GlassCard`, `GlassPanel`, `FrostedContainer` with real-time blur and luminous borders.
  - `GlowingActionButton`, `KbdTag`, `AnimatedBorderSweep`.
  - `DynamicIslandCapsule`, `PulseDot`, `PillBadge`, `StepIndicatorPill`.
  - `GlassDropdown`, `GlassDialog`, `GlassTerminal`, `GlassMarquee`.
  - `CommandPalette` (`Ctrl+K`), `FilterSearchDock`, `MobileDockNav`.
  - `AppToast` with state-managed timer lifecycle cleanup.
- **Hardware Performance Profiling**:
  - `PerfTierMode` (`auto`, `ultra`, `balanced`, `lite`) with auto CPU core detection.
  - Live Glassmorphism tuning sliders for Card, Dialog, and Dropdown blur and opacity.
- **Instant 1-Click Multi-Language Support**:
  - Seamless cycling between `VI` (🇻🇳 Tiếng Việt), `EN` (🇬🇧 English), and `ZH` (🇨🇳 中文).
  - Bidirectional synchronization between `LanguageProvider` and `RouteFixerLogic`.
- **Keyboard Shortcuts & Commands**:
  - `Ctrl+K`: Open Command Palette.
  - `Ctrl+1`…`5`: Navigate tabs (Overview, Config, Diagnostics, Logs, About).
  - `Ctrl+,`: Open Glass Tuning & Settings dialog.
  - `Shift+L`: Toggle Light / Dark theme.
  - `Esc`: Close dialogs.
- **LAN Over-The-Air (OTA) Updates**: In-app checker and updater for local enterprise networks.
- **Build & Packaging Tooling**: Standardized 5-step `build.bat`, `build.sh`, and `debug.bat` following `dart-build-pro` and `flutter-app-blueprint`.

### Changed
- Refactored `DashboardShell` to use centered `SlidingPillTabBar` and 4 expanding topbar buttons.
- Updated `desktop_window` initialization to standard `1280x800` (min `760x520`) using `window_manager`.
- Maintained 100% compatibility with underlying dual-NIC routing business logic (`RouteFixerLogic`, `native_bridge.dart`, `win_core.dart`).

---

## [1.0.0] - 2026-09-01

### Added
- Initial release of **JA_Route**: Automated Dual-NIC Network Routing Optimizer for Windows.
- Automatic routing separation: High-speed Internet and company internal LAN.
- Windows route table inspection and gateway auto-detection.
- Custom LAN and Internet bypass route rules.
- Network restore points and JSON profile import / export.
- Network ping diagnostics, Tailscale status check, and DNS / ARP cache flush.
- Dual logging strategies (Debug verbose vs Release informative).
