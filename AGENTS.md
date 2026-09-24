# AGENTS.md — Luật nền cho dự án Flutter/Dart này

File này được Antigravity, Claude Code và các agent tương thích (Cursor, Windsurf...) tự động đọc mỗi khi mở project. Khác với các skill trong `skills/`, `.agents/skills/`, `.claude/skills/` (chỉ kích hoạt khi mô tả khớp yêu cầu của bạn), nội dung dưới đây **luôn áp dụng cho mọi thay đổi mã nguồn**, không cần bạn nhắc lại.

Ngoài ra agent cũng nên tham chiếu luật chung toàn workspace (áp dụng mọi project, mọi ngôn ngữ) tại:
- `~/.claude/rules/security.md`
- `~/.claude/rules/coding-style.md`
- `~/.claude/rules/git-workflow.md`
- `~/.claude/rules/response-format.md` (bắt buộc gợi ý bước tiếp theo + skill liên quan cuối mỗi câu trả lời — đã lặp lại ở mục 5 bên dưới để agent không cần đọc file ngoài)

Luật riêng của project này (bên dưới) ưu tiên cao hơn nếu có xung đột với luật chung ở trên.

## Bối cảnh dự án
- Đây là ứng dụng Flutter Desktop (Windows/macOS/Linux), có thể mở rộng Android/iOS — xem chi tiết kiến trúc đầy đủ tại skill `flutter-app-blueprint`.
- Xem `skills_guide.md` để biết danh sách các skill có sẵn và khi nào nên gọi skill nào.

## Quy tắc bắt buộc (Constraints)

### 1. Hiệu năng UI
- Luôn dùng `const` constructor cho Widget khi có thể, để tránh rebuild không cần thiết.
- Không lồng Widget quá 4 cấp trong một `build()`. Nếu sâu hơn, extract ra `StatelessWidget`/`ConsumerWidget` riêng.

### 2. Kiến trúc & luồng dữ liệu
- Không viết Business Logic trực tiếp trong hàm `build()`.
- Giữ nguyên kiến trúc state-management hiện tại của project (Riverpod/Bloc/MVVM...) — không tự ý đổi sang pattern khác trừ khi được yêu cầu rõ ràng.
- Theo cấu trúc thư mục chuẩn trong skill `flutter-app-blueprint` (`lib/modules/ui`, `lib/modules/native`, `native_bridge.dart`, `logic.dart`...) khi tạo file/module mới.

### 3. An toàn
- Xử lý Null Safety cẩn thận — không lạm dụng toán tử `!` để ép kiểu mù quáng.
- KHÔNG BAO GIỜ tự ý chạy `flutter clean`, xóa file, hoặc các lệnh phá hủy dữ liệu mà chưa được người dùng xác nhận rõ ràng.
- Trước khi thêm package mới vào `pubspec.yaml`: xác nhận package có null-safety và đang ở bản ổn định (stable) mới nhất.

### 4. Vòng kiểm chứng bắt buộc trước khi báo "xong"
Sau bất kỳ thay đổi code nào, PHẢI chạy tuần tự và sửa hết lỗi phát sinh trước khi báo cáo hoàn thành:
1. `dart analyze` (hoặc `flutter analyze`)
2. `dart format .`
3. Nếu có test: `flutter test`

Không được tự nhận "đã xong" nếu các lệnh trên còn báo lỗi/cảnh báo chưa xử lý.

### 5. Định dạng phản hồi
- Cuối mỗi câu trả lời, LUÔN LUÔN tự động đưa ra danh sách các gợi ý bước tiếp theo (Prompt mẫu) cùng với tên các **Skill** tương ứng sẽ kích hoạt.

## Khi nào gọi skill cụ thể
Với các tác vụ chuyên biệt (build/release, đa ngôn ngữ, scaffold feature, debug theo giả thuyết, đóng gói theo từng OS...), hãy tham chiếu skill tương ứng trong `.agents/skills/` (Antigravity) hoặc `.claude/skills/` (Claude Code) — xem mô tả đầy đủ ở `skills_guide.md`. Các luật ở trên vẫn áp dụng song song khi thực hiện skill.

⚠️ Một số skill được `flutter-app-blueprint` tham chiếu (`flutter-mobile-build-pro`, `flutter-macos-packager`) hiện **chưa được tạo** — xem `skills_guide.md` mục 12/14 trước khi giả định chúng tồn tại.
