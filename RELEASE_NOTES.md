TAG=v1.3.0
TITLE=JA_Route v1.3.0 — Đồng Bộ Đa Ngữ Toàn Diện & Tối Ưu Bảng Định Tuyến Responsive
BODY=
## JA_Route v1.3.0 — Đồng Bộ Đa Ngữ Toàn Diện & Tối Ưu Bảng Định Tuyến Responsive

Phiên bản phát hành **JA_Route v1.3.0** tập trung hoàn thiện trải nghiệm giao diện người dùng, nâng cấp bộ máy đa ngữ và tối ưu diện tích hiển thị:

- **Biểu tượng Ứng dụng Chính thức (Official App Icon)**: Cập nhật logo mới chất lượng cao chuẩn Windows đa kích cỡ (16x16 - 256x256), nhúng trực tiếp vào file EXE hiển thị sắc nét trên Taskbar, Desktop shortcut và Windows Explorer.
- **Đồng bộ Đa ngữ Toàn diện (Multi-Language Reactivity)**: Khắc phục triệt để lỗi khóa cứng Tiếng Việt khi chuyển sang `EN` / `ZH`. Tự động chuẩn hóa mã locale Windows và đồng bộ tức thì trên toàn bộ 5 View chính mà không cần khởi động lại ứng dụng.
- **Tối ưu Bảng định tuyến IPv4 Toàn Chiều Ngang**: Tái cấu trúc bảng Route bằng widget `Table` và tỷ lệ cột `FlexColumnWidth` tối ưu, lấp đầy 100% không gian BentoCard, loại bỏ hoàn toàn khoảng trống thừa ở cạnh phải cột Metric.
- **Nâng cấp Droplist Chuẩn Showcase**: Nâng độ đục lên 0.96 / 0.98, bổ sung viền specular highlight, shadow sâu 28px và tự động bản địa hóa thanh tìm kiếm bên trong dropdown.
- **Bản địa hóa 100% Chuỗi Hệ Thống**: Dịch thuật hoàn toàn các thông báo kiểm tra IPv4/Subnet, thanh tìm kiếm logs, kết quả terminal chẩn đoán và dialog cấu hình.
- **Bộ Kiểm thử Tự động**: Bổ sung bộ test dropdown & localization, đảm bảo 32/32 tests pass và `dart analyze` 0 cảnh báo.

### Cài đặt
Giải nén toàn bộ file `JA_Route_v1.3.0_Windows_x64.zip` và chạy file `install.bat` (hoặc chạy trực tiếp `ja_route.exe` / `debug.bat`). Xem thêm tài liệu `USERGUIDE.md` đính kèm.
