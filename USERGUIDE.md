# Hướng dẫn sử dụng JA_Route v1.3.0

Ứng dụng **JA_Route** là công cụ tối ưu và xử lý bảng định tuyến 2 card mạng (Dual-NIC) tự động dành cho hệ điều hành Windows, phát triển trên nền Flutter Desktop với giao diện Bento Glassmorphism hiện đại.

---

## 📦 1. Cài đặt & Khởi chạy

### Cách 1: Chạy trực tiếp (Portable)
1. Tải và giải nén file `JA_Route_v1.3.0_Windows_x64.zip`.
2. Chạy file `ja_route.exe` với quyền Administrator (yêu cầu cấp quyền UAC để chỉnh sửa bảng định tuyến hệ thống).
3. Hoặc chạy file `debug.bat` để mở app ở chế độ **Debug (-debug)** kèm log chi tiết.

### Cách 2: Cài đặt vào hệ thống (Không cần quyền Admin)
1. Chạy file `install.bat` có sẵn trong thư mục ứng dụng.
2. Bộ cài sẽ tự động tạo lối tắt trên Desktop và Start Menu.
3. Để gỡ bỏ cài đặt, chỉ cần chạy file `uninstall.bat`.

---

## 🎯 2. Các chức năng chính

### Tab 1: Tổng quan (Dashboard)
- **Sơ đồ Trực quan Kết nối**: Hiển thị trạng thái kết nối từ PC đến Internet Gateway và LAN Gateway.
- **Nút Bắt Đầu Fix (Bento Action Button)**: Bấm 1 lần để hệ thống tự động:
  1. Kích hoạt tính năng `IgnoreDefaultRoutes` và nâng metric card mạng LAN.
  2. Dọn sạch DNS/ARP cache và xóa các static route cũ sai lệch.
  3. Bổ sung các static route chuẩn xác cho dải mạng nội bộ công ty.
  4. Xác minh thông tuyến bằng ping đồng thời ra Internet và LAN.

### Tab 2: Cấu hình (Configuration)
- Quản lý các cấu hình kết nối mạng (Profile): Office, Factory, Home...
- Thiết lập địa chỉ Gateway Internet, Gateway LAN, Dải IP LAN và Netmask.
- Thêm/xóa danh sách định tuyến phụ trợ tùy biến (Custom Routes).
- Cơ chế Tự động phục hồi (Auto-Heal) theo chu kỳ định sẵn.
- Sao lưu và khôi phục cấu hình qua file JSON hoặc Windows Registry.

### Tab 3: Chẩn đoán & Xác minh (Diagnostics & Verification)
- **Kiểm thử Tuyến đường Thông minh (Smart Verify)**:
  - Nhập bất kỳ địa chỉ IP (ví dụ: `172.21.168.100`), Domain (`intranet.local`), hoặc URL (`http://10.20.30.40:8080`).
  - Chọn chế độ mong muốn: `Tự động (Auto)`, `Bắt buộc qua LAN`, `Bắt buộc qua Internet`.
  - Hoặc click các preset nhanh: `Google (8.8.8.8)`, `Cloudflare (1.1.1.1)`, `Cổng LAN`, `Cổng Internet`.
- **Tự động Chẩn đoán Lệch tuyến (Misrouted Detection)**:
  - Hệ thống truy vấn trực tiếp Windows Kernel để xem card mạng và gateway đang phụ trách địa chỉ đó.
  - Cảnh báo rõ ràng nếu IP mạng nội bộ bị gửi nhầm ra cổng Internet hoặc ngược lại.
  - Phân tích nguyên nhân gốc (Root Cause) kèm khuyến nghị sửa lỗi.
- **⚡ Sửa Route Nhanh (1-Click Quick Fix)**:
  - Bấm nút `[⚡ Sửa Route Nhanh]` để hệ thống tự động ghi Persistent Route vào Windows và chạy lại kiểm tra.
- **Công cụ phụ trợ**:
  - `Ping`: Đo kiểm độ trễ gói tin.
  - `Test Cổng`: Bắt tay TCP socket kiểm tra dịch vụ.
  - `Kiểm tra Tailscale`: Tra cứu trạng thái dịch vụ mạng riêng ảo.
  - `Dọn dẹp DNS & ARP`: Flush bộ đệm phân giải tên miền và bảng địa chỉ vật lý.
  - `Khôi phục Mặc định`: Đưa card mạng và bảng định tuyến về trạng thái Windows nguyên bản.

### Tab 4: Nhật ký (Logs)
- Xem luồng log thời gian thực với mã màu phân cấp (INFO, WARNING, ERROR, SUCCESS).
- Lọc log theo từ khóa hoặc tìm kiếm nhanh.
- Sao chép toàn bộ log hoặc xuất file `.log` để gửi bộ phận kỹ thuật.

### Tab 5: Giới thiệu (About)
- Thông tin phiên bản, giấy phép nguồn mở MIT và trạng thái hiệu năng GPU/Acrylic.
- Kiểm tra cập nhật qua mạng nội bộ LAN Over-The-Air (OTA).

---

## 🌐 3. Cập nhật qua Mạng nội bộ (LAN OTA)
1. Ứng dụng tự động kiểm tra bản cập nhật mới trên máy chủ nội bộ:
   `\\10.81.141.226\temp\FBT\JA_PROJECT\JA_Update\JA_Route`
2. Khi có phiên bản mới, hộp thoại cập nhật `GlassUpdateDialog` sẽ xuất hiện với thông tin phiên bản, kích thước và ghi chú cập nhật.
3. Người dùng bấm **CẬP NHẬT NGAY** để tải về và tự động cài đặt phiên bản mới.
