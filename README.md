# AiVie.check

Ứng dụng chấm công bằng khuôn mặt và vị trí, sử dụng Flutter Web, FastAPI và PostgreSQL.

## Chức năng

- Đăng nhập, đăng xuất và phân quyền admin/nhân viên.
- Tạo, chỉnh sửa và xóa tài khoản nhân viên.
- Giao ca, cập nhật và xóa ca làm.
- Đăng ký khuôn mặt bằng ảnh, xác minh bằng webcam.
- Thiết lập địa điểm, kiểm tra vị trí khi chấm công.
- Lưu CHECK IN/OUT và lịch sử chấm công trên PostgreSQL.
- Nhân viên xem lịch sử của mình; admin xem lịch sử nhân viên.
- Giao diện sáng/tối, dùng chung màu trạng thái.
- Bảng lương minh họa cho tài khoản huythong gốc.

## Triển khai online

Xem [DEPLOY.md](DEPLOY.md) để triển khai web và API cùng một địa chỉ HTTPS
trên Render, dùng PostgreSQL của Neon. Không cần cài Docker trên máy Windows.

Gói triển khai tự chạy migration và chỉ tạo tài khoản ban đầu còn thiếu.
CI kiểm tra Flutter, API/PostgreSQL và dựng/chạy thử Docker trước khi Render
tự triển khai các lần cập nhật sau.

## Công nghệ

| Thành phần | Công nghệ |
| --- | --- |
| Frontend | Flutter 3.35.6, Dart 3.9.2 |
| Backend | Python, FastAPI, SQLAlchemy |
| Cơ sở dữ liệu | PostgreSQL 17 |
| Migration | Alembic |
| Khuôn mặt | Human 3.3.6, JavaScript interop |
| Vị trí | Geolocator |
| Mật khẩu | Argon2 |
| Phiên đăng nhập | Opaque bearer token, lưu SHA-256 digest tại backend |

## Cấu trúc chính

| Đường dẫn | Nội dung |
| --- | --- |
| `lib/screens`, `lib/widgets`, `lib/home` | Màn hình và thành phần giao diện |
| `lib/services` | Kết nối API và lưu tùy chọn trình duyệt |
| `lib/models` | Tài khoản, ca làm và phiên làm việc |
| `lib/face`, `web/aivy_face.js` | Đăng ký và xác minh khuôn mặt |
| `lib/gps` | Thiết lập và kiểm tra vị trí |
| `lib/theme` | Theme sáng/tối |
| `backend/app/auth` | Xác thực và phiên đăng nhập |
| `backend/app/users` | Quản lý tài khoản nhân viên |
| `backend/app/shifts` | Quản lý ca làm |
| `backend/app/attendance_setup` | Cấu hình GPS và hồ sơ khuôn mặt |
| `backend/app/attendance` | CHECK IN/OUT và lịch sử |
| `backend/migrations` | Migration PostgreSQL |

## Chuẩn bị lần đầu trên Windows

Cài Flutter, Python và PostgreSQL. Tạo database `aivycheck` với role `aivycheck_app` có quyền sở hữu database.

Từ thư mục gốc dự án, mở PowerShell:

```powershell
Set-Location backend
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
if (-not (Test-Path ".env")) {
    Copy-Item .env.example .env
}
```

Điền thông tin PostgreSQL trong `backend/.env`. Chỉ sao chép tệp mẫu khi chưa có `.env`; không ghi đè cấu hình đang sử dụng.

```powershell
.\.venv\Scripts\python.exe -m alembic upgrade head
.\.venv\Scripts\python.exe -m app.seed
```

Lệnh seed tạo các tài khoản ban đầu `aiviee` và `huythong`, hỏi mật khẩu bằng terminal và giữ nguyên tài khoản đã tồn tại.

## Chạy ứng dụng

PostgreSQL phải hoạt động. Không cần mở giao diện pgAdmin nếu dịch vụ PostgreSQL đã chạy.

Terminal 1, từ thư mục gốc dự án:

```powershell
Set-Location backend
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload --reload-dir app
```

Swagger: http://127.0.0.1:8000/docs

Terminal 2, tại thư mục gốc dự án:

```powershell
flutter pub get
flutter run -d web-server --web-hostname localhost --web-port 62623 --no-web-experimental-hot-reload
```

Mở http://localhost:62623 trên Chrome hoặc Edge. Nếu đang sử dụng cổng khác, giữ nguyên cổng đó trong lệnh chạy. Các địa chỉ/cổng khác nhau có vùng lưu tùy chọn trình duyệt riêng.

Giữ cả hai terminal chạy khi sử dụng ứng dụng. Flutter có thể mở giao diện riêng, nhưng đăng nhập và các chức năng gọi API cần backend. Backend cần PostgreSQL.

## Kiểm tra trước khi commit

```powershell
flutter analyze
```

Kiểm thử thủ công luồng chính:

1. Chrome: admin giao một ca hôm nay cho huythong.
2. Edge: huythong tải lại lịch, chọn ca và CHECK IN bằng khuôn mặt/GPS.
3. Chrome: admin tải lại lịch sử của huythong, kiểm tra giờ vào.
4. Edge: CHECK OUT; Chrome tải lại và kiểm tra giờ ra.
5. F5, đăng nhập lại và kiểm tra lịch sử vẫn còn.

## Quy tắc và phạm vi hiện tại

- Khi chấm công, sai số vị trí tối đa 150 m; khoảng cách cộng sai số phải nằm trong bán kính đã lưu. Bán kính mặc định 200 m.
- Giờ IN/OUT lấy từ backend; giao diện hiển thị theo giờ địa phương. Quy tắc ngày ca tại backend theo UTC+7.
- Một tài khoản chỉ có một ca đang làm; mỗi ca chỉ có một lượt chấm công.
- Lịch sử giữ thông tin ca tại thời điểm CHECK IN, kể cả khi ca được chỉnh sửa sau đó.
- Xóa tài khoản là ngừng kích hoạt và thu hồi phiên đăng nhập; dữ liệu cũ vẫn được giữ. Tên tài khoản/email vẫn thuộc hồ sơ cũ.
- Nhận diện khuôn mặt chạy trong trình duyệt. Backend nhận kết quả từ frontend; chưa tự đối chiếu embedding hoặc chứng thực webcam.
- Token đang giữ trong bộ nhớ; tải lại toàn trang cần đăng nhập lại.
- Bảng lương là dữ liệu mẫu, chưa phải hệ thống tính lương thực tế.
- Dữ liệu lượt thử local trước bước chuyển backend không tự nhập vào lịch sử PostgreSQL.
- Có thể chạy localhost hoặc triển khai HTTPS theo `DEPLOY.md`. Thư viện và mô hình khuôn mặt được tải từ CDN khi cần.
- `.env`, `.venv` và tệp sinh tự động được loại khỏi Git. GitHub lưu mã nguồn; dữ liệu PostgreSQL không đồng bộ qua Git.
