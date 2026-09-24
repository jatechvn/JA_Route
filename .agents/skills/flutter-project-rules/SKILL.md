---
name: flutter-project-rules
description: Kỹ năng đóng vai trò như một chuyên gia Flutter, áp đặt các quy tắc về Clean Architecture, Null Safety và tối ưu hiệu năng. Kích hoạt khi yêu cầu agent viết tính năng mới hoặc refactor.
---

# Flutter Project Rules Skill

Kỹ năng này hoạt động như hệ thống "luật lệ ngầm" (System Prompt), giúp định hình lại tư duy của Agent để code như một Senior Flutter Developer.

## Constraints & Rules (Quy tắc bắt buộc dành cho Agent)
Khi thực hiện bất kỳ thay đổi mã nguồn nào, Agent PHẢI tuân thủ các quy tắc sau:
1. **Tối ưu UI (Performance):**
   - BẮT BUỘC sử dụng từ khóa `const` constructor cho các Widget để tránh rebuild không cần thiết.
   - Không được lồng ghép (nesting) quá 4 cấp Widget. Nếu sâu hơn, phải Extract ra thành các StatelessWidget riêng biệt.
2. **Kiến trúc & Luồng dữ liệu:**
   - Không được nhét logic xử lý dữ liệu (Business Logic) trực tiếp vào trong hàm `build()` của Widget.
   - Giữ nguyên kiến trúc hiện tại của người dùng (Riverpod, Bloc, hay MVVM) không được tự ý đổi sang pattern khác.
3. **Sự An Toàn (Safety):**
   - Xử lý Null Safety một cách cẩn thận, không lạm dụng toán tử `!` ép kiểu mù quáng.
   - Không bao giờ được phép tự ý chạy lệnh `flutter clean` hay xóa các file quan trọng mà không có sự cho phép rõ ràng của người dùng.
4. **Quản lý Thư viện:**
   - Trước khi đề xuất cài thêm package mới vào `pubspec.yaml`, phải đảm bảo package đó có null-safety và là bản ổn định (stable) mới nhất.
5. **Hiệu ứng chuyển tiếp mượt mà (Smooth Transition Animations) & Hiệu năng:**
   - Ưu tiên animation implicit có sẵn của Flutter (`AnimatedContainer`, `AnimatedSwitcher`, `AnimatedAlign`, `AnimatedCrossFade`, `ScaleTransition`/`FadeTransition` trong `showGeneralDialog`) thay vì tự viết `AnimationController` thủ công — chi phí thấp, tự động interrupt/reverse mượt, ít code hơn.
   - Gom toàn bộ `Duration`/`Curve` dùng cho animation vào một file hằng số dùng chung (ví dụ `lib/modules/ui/motion.dart`) thay vì hard-code rải rác, để cảm giác chuyển động đồng nhất toàn app và dễ tinh chỉnh sau này.
   - Với danh sách dài render qua `ListView.builder` có hiệu ứng entrance (stagger fade/slide-in): PHẢI keyed bằng định danh nội dung ổn định (không dùng index thô), và lưu trạng thái "đã chạy animation" ở một `Set` sống trong State của widget cha (không phải trong chính item) — vì `ListView.builder` dispose Element khi item cuộn ra ngoài `cacheExtent`, nếu không track ở tầng cha thì cuộn qua lại sẽ làm animation bị replay liên tục, gây nhấp nháy khó chịu.
   - Chỉ bọc `AnimatedSwitcher`/`KeyedSubtree` đúng vùng thực sự cần transition (ví dụ nội dung tab/detail panel), không bọc animation lồng nhau nhiều lớp không cần thiết trên cùng một thay đổi state.
   - **BẮT BUỘC verify bằng Flutter DevTools thật sau khi thêm animation mới, không chỉ verify bằng mắt/screenshot:**
     1. Chạy `flutter run --profile -d windows` (hoặc platform tương ứng), lấy URL DevTools in ra ở console.
     2. Mở DevTools → tab **Performance**, bấm **Clear all** để xoá dữ liệu cũ.
     3. Thao tác trực tiếp với app để trigger đúng các animation vừa thêm (chuyển tab, cuộn list, mở/đóng dialog, đổi theme...).
     4. Click vào frame cao nhất trên biểu đồ, đọc **Frame Analysis**: tổng thời gian UI (Build+Layout+Paint) + Raster phải < 16.67ms (ngân sách 60fps) và không có frame màu đỏ (jank) hoặc đỏ đậm (Shader Compilation).
     5. Nếu Raster cao bất thường trong khi UI thấp → nghi ngờ animate màu nền/blur trên vùng lớn; vẫn chấp nhận được nếu còn trong ngân sách, nhưng phải đo lại mỗi khi thêm animation mới vào cùng khu vực đó.
6. **Đồng bộ các Widget Material mặc định (PopupMenuButton, DropdownButton, MenuAnchor...) với Design System riêng của app:**
   - Các widget menu/dropdown nổi của Flutter Material 3 (`PopupMenuButton`, `DropdownButton`, `MenuAnchor`...) tự áp `surfaceTint`/`colorScheme` mặc định của framework (thường ngả tím/xanh) khi không được style tường minh — nếu app có design system riêng (`theme.cardBg`, màu border, màu accent) thì các widget này sẽ trông "lệch tông", không đồng nhất với phần còn lại dù logic hoàn toàn đúng.
   - BẮT BUỘC set tường minh khi dùng `PopupMenuButton`/tương đương: `color: theme.cardBg`, `surfaceTintColor: Colors.transparent`, và `shape: RoundedRectangleBorder(...)` với border khớp các card/button khác trong app (không dùng theme mặc định của Material).
   - Style tường minh màu chữ/icon của từng item theo `theme.textPrimary`/`theme.textSecondary` — không để mặc định của `PopupMenuItem`/`DropdownMenuItem`, vì màu mặc định cũng bị tint nhẹ khác với `theme.textPrimary` dù nhìn qua tưởng giống nhau.
   - Item đang được chọn (active/selected state) trong menu PHẢI tái sử dụng đúng "ngôn ngữ chọn lựa" đã có sẵn trong app (ví dụ: pill bo góc nền màu accent ~10-15% opacity, chữ+icon đổi màu accent — giống cách tab pill hoặc item sidebar đang được chọn hiển thị) thay vì chỉ thêm một icon nhỏ đánh dấu rồi để nguyên nền mặc định — nếu không sẽ tạo ra 2 "ngôn ngữ hiển thị được chọn" khác nhau trong cùng 1 app.
   - Nếu các phần khác của app đã dùng pattern icon dẫn đầu + label (tab, sidebar, hover chip...), mỗi item trong menu cũng nên có icon riêng phù hợp ngữ nghĩa, không để item dạng text thuần — giữ nhất quán "ngôn ngữ hình ảnh" toàn app.
7. **Xây dựng Form Settings / Glassmorphism (Advanced Settings, dialog có slider blur/opacity):**
   - **Tái dùng token màu translucent đã có trước khi bịa giá trị alpha mới:** trước khi viết `Colors.transparent`/`Colors.black.withValues(alpha: x)` cho bất kỳ bề mặt mới nào, kiểm tra `ThemeProvider` (hoặc file style tương đương) xem đã có getter màu nào được tune sẵn cho đúng mục đích chưa (ví dụ `sidebarBg`, `cardBg` — thường đã phân biệt Win10/Win11 vì Win10 cần opacity cao hơn để hiện rõ trên Aero Blur, Win11 dùng opacity thấp hơn để Acrylic "bleed through" đẹp hơn). Ưu tiên tái dùng thay vì tạo hằng số mới — tránh lệch tông và tránh phải tinh chỉnh 2 nơi khi đổi theme sau này.
   - **Slider glass dùng chung 1 helper, không copy-paste:** viết 1 hàm cục bộ kiểu `buildGlassSlider({label, value, min, max, isPercent, onChanged})` trả về `Column(Row[label, giá trị hiện tại (px hoặc %)], SliderTheme(Slider))`, gọi lại nhiều lần cho từng slider (blur tính bằng `px`, opacity tính bằng `%`) — không lặp lại cấu trúc Column/Row/SliderTheme cho từng slider riêng.
   - **Section có thể thu gọn:** bọc nhóm slider trong `Theme(data: ...copyWith(dividerColor: Colors.transparent), child: ExpansionTile(...))` để có tiêu đề + mũi tên thu gọn/mở mà không có đường kẻ chia mặc định của Material.
   - **Local state mirror + commit-on-Save:** state của các slider là biến `double` cục bộ trong `StatefulBuilder` của dialog (khởi tạo từ giá trị đã persist), KHÔNG ghi thẳng vào state toàn cục khi kéo — chỉ gọi `logic.updateSettings(...)` (với tham số optional, chỉ set khi `!= null`) lúc bấm Save; nút Default chỉ `setDialogState` reset các biến cục bộ về giá trị mặc định, không tự động lưu.
   - **Live-preview blur/opacity ngay trên chính bề mặt đang chỉnh (nếu có):** bọc bề mặt (dialog/dropdown) trong `Stack` gồm `Positioned.fill(BackdropFilter(ImageFilter.blur(sigma: blur)))` phía sau + `Material`/`AlertDialog` với `backgroundColor: mauNen.withValues(alpha: opacity)` phía trước — để slider kéo tới đâu thấy hiệu ứng ngay tới đó, giống hành vi ứng dụng tham chiếu (JA_Compare).
   - **Sàn an toàn chống lỗi chữ chồng xuyên thấu (legibility floor) — BẮT BUỘC:** khi opacity < 1.0, ép `effectiveBlur = max(blur, 6.0)` bất kể slider blur người dùng để ở mức nào — blur = 0 kèm opacity thấp là công thức chắc chắn tái hiện lỗi "chữ nền xuyên qua chữ trước" từng phải fix trước đây.
   - **Trước khi cho phép trong suốt trở lại 1 dialog từng bị buộc opaque:** kiểm tra `CHANGELOG.md`/lịch sử — nếu dialog đó từng được cố tình chuyển sang nền đặc 100% để fix 1 bug cụ thể (không phải ngẫu nhiên), PHẢI hỏi xác nhận người dùng trước khi đảo ngược quyết định đó, dù có sẵn kỹ thuật "legibility floor" ở trên để giảm rủi ro lặp lại bug.
   - **Restart sạch, không hot-reload, sau khi đổi cấu trúc widget:** nếu thay đổi thêm/bớt widget cha bao quanh 1 cây widget đang chạy (ví dụ bọc thêm `Stack`/`BackdropFilter` quanh 1 `AlertDialog` có sẵn), phải dừng phiên `flutter run` đang chạy và chạy lại từ đầu (full restart) trước khi test — hot reload không luôn reconcile đúng khi thêm/bớt ancestor widget, dễ gây ra hiện tượng nút bấm/luồng bất đồng bộ trong đúng cây đó "lỗi giả" (không phải do code sai) chỉ vì state của phiên debug cũ còn sót lại.
8. **Settings dialog 3-tab layout:**
   - Settings phải có đúng 3 tab cấp cao theo thứ tự `Advanced Settings` (mặc định), `About`, `User Guide`; không đặt About/User Guide thành tab con hoặc ExpansionTile bên trong Advanced Settings. Cả ba tab nằm trong cùng dialog, không mở dialog con từ footer.
   - Không ép mọi tab dùng cùng một chiều cao cố định: khi Advanced Settings đang collapsed, dialog phải co vừa nhóm CDP + accordion; khi mở accordion hoặc chuyển sang About/User Guide, dialog được phép nở theo nội dung nhưng vẫn giới hạn bằng vùng scroll.
   - Dùng `AnimatedSize` kết hợp `AnimatedSwitcher`/layout top-aligned để chuyển chiều cao mượt, tránh khoảng trắng lớn do child bị căn giữa trong vùng cố định.
   - Giữ `Default`, `Cancel`, `Save` ở footer; các slider và text field vẫn dùng local state, chỉ persist khi Save.
