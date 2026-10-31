# Đưa AiVie.check lên mạng

Web Flutter và API FastAPI chạy chung một Web Service trên Render.
PostgreSQL chạy ở Neon. Chọn gói Free cho cả hai dịch vụ.
Máy Windows không cần cài Docker và không phải giữ hai terminal chạy khi
sử dụng địa chỉ online.

## 1. Cập nhật mã và kiểm tra GitHub Actions

Đưa toàn bộ thay đổi của bản triển khai vào repo `aivycheck`, nhánh `main`.
Không đưa `backend/.env` hoặc `.venv` lên GitHub.

```powershell
Set-Location "C:\Users\Admin\Downloads\aivycheck"
git diff --check
git add -- Dockerfile .dockerignore render.yaml DEPLOY.md README.md .github/workflows/ci.yml backend/app/config.py backend/app/database.py backend/app/main.py backend/app/bootstrap.py backend/start_cloud.py backend/tests/conftest.py backend/tests/test_deployment.py lib/services/api_client.dart
git diff --cached --check
git commit -m "deploy: prepare Render web and API with Neon PostgreSQL"
git push origin main
```

Trong GitHub → Actions, chờ đủ ba công việc thành công:

1. `Flutter analyze, test and build`.
2. `FastAPI and PostgreSQL tests`.
3. `Build and check deployment image`.

Công việc thứ ba dựng Docker, chạy migration trên PostgreSQL test riêng,
khởi tạo tài khoản thử, kiểm tra web, API, kết nối database và đăng nhập.
Nó không sử dụng database hay mật khẩu của em.

## 2. Tạo PostgreSQL trên Neon

1. Vào <https://console.neon.tech> và đăng nhập/tạo tài khoản.
2. Tạo project mới, tên `aivycheck`, gói **Free**.
3. Chọn PostgreSQL **17**, region **AWS Singapore**.
4. Mở **Connect** của database thuộc nhánh mặc định vừa tạo.
5. Tắt **Connection pooling** để lấy địa chỉ kết nối trực tiếp.
6. Sao chép **connection string** dạng `postgresql://...`.

Dùng tên database và role do Neon tạo sẵn cũng được. Không cần đổi tên
cho giống database local. Giữ nguyên các tham số SSL của connection string.
Nếu màn hình có lệnh `psql '...'`, chỉ sao chép URL bên trong dấu nháy.
URL chứa mật khẩu: điền trực tiếp trên Render ở bước sau, không gửi trong chat
và không lưu vào Git.

## 3. Tạo Web Service trên Render

1. Vào <https://dashboard.render.com> và đăng nhập/tạo tài khoản.
2. Chọn **New → Blueprint**.
3. Kết nối tài khoản GitHub, cho phép Render truy cập repo
   `dnghuythong05-arch/aivycheck`, rồi chọn repo này và nhánh `main`.
   Dùng kết nối GitHub để các lần cập nhật tự triển khai sau khi CI đạt.
4. Blueprint đọc cấu hình `render.yaml` ở thư mục gốc. Kiểm tra service
   `aivycheck`, runtime Docker, region Singapore và instance **Free**.
5. Render yêu cầu ba biến bí mật:

| Biến | Giá trị cần nhập |
| --- | --- |
| `DATABASE_URL` | Connection string đầy đủ lấy từ Neon |
| `AIVY_ADMIN_PASSWORD` | Mật khẩu em chọn cho tài khoản online `aiviee`, từ 8 đến 128 ký tự |
| `AIVY_EMPLOYEE_PASSWORD` | Mật khẩu em chọn cho tài khoản online `huythong`, từ 8 đến 128 ký tự |

6. Xác nhận tạo Blueprint với gói Free. Chờ build và deploy thành công,
   trạng thái service **Live**.
7. Mở địa chỉ HTTPS `.onrender.com` do Render hiển thị. Đó là địa chỉ web
   để em gửi cho người khác. Không tự đoán tên miền từ tên service.

Lần đầu, ứng dụng tự tạo bảng bằng Alembic và tạo hai tài khoản trên.
Các lần khởi động/deploy tiếp theo giữ nguyên tài khoản và mật khẩu đã có;
đổi biến mật khẩu khởi tạo không đặt lại mật khẩu của tài khoản đã tồn tại.
Quản trị viên vẫn đổi mật khẩu nhân viên qua chức năng quản lý hiện tại.

Mật khẩu trong database local giữ nguyên. Không cần sửa `backend/.env` local.
Không đặt `DB_PASSWORD`, `WEB_DIST_DIR` hoặc `API_BASE_URL` thêm trên Render:
Docker đã cấu hình phần cần thiết và bản web dùng API cùng địa chỉ HTTPS.

## 4. Kiểm tra bản online

Dùng địa chỉ thực tế do Render cấp, lần lượt mở:

- `/api/health`: `status` là `ok`.
- `/api/health/db`: `database` là `connected`.
- `/`: màn hình đăng nhập AiVie.check.

Database online mới chỉ có hai tài khoản khởi tạo. Dữ liệu tài khoản khác,
GPS, hồ sơ khuôn mặt, ca và lịch sử local chưa được sao chép sang Neon.
Đăng nhập admin trên bản online để thiết lập địa điểm, đăng ký khuôn mặt và
giao ca thử cho huythong trước khi chấm công.

Kiểm tra trên Chrome và Edge bằng cùng địa chỉ HTTPS:

1. Admin Chrome giao ca hôm nay cho huythong.
2. Huythong Edge đăng nhập, cấp quyền camera/vị trí và CHECK IN.
3. Admin tải lại lịch sử, kiểm tra giờ vào và trạng thái đang làm.
4. Huythong CHECK OUT; admin kiểm tra giờ ra và trạng thái hoàn thành.
5. F5, đăng nhập lại, kiểm tra lịch sử còn nguyên.
6. Trong Render, chạy **Manual Deploy → Deploy latest commit**. Khi Live
   trở lại, đăng nhập và kiểm tra tài khoản/lịch sử vẫn còn nguyên.

Chỉ xác nhận triển khai xong sau khi các kiểm tra trên đạt. Nhận diện vẫn
chạy ở trình duyệt như bản local; việc đưa lên HTTPS không bổ sung cơ chế
đối chiếu khuôn mặt hoặc chống giả mạo tại máy chủ.

## 5. Các lần cập nhật sau

Sau khi commit và push lên `main`, GitHub Actions kiểm tra mã và Docker.
Render được đặt `autoDeployTrigger: checksPass`, nên tự triển khai bản cập
nhật khi các kiểm tra của commit đó đạt. CI lỗi thì xem job báo đỏ và sửa
trước; có thể dùng bản đang chạy trong lúc sửa.

## Giới hạn gói miễn phí

Render Free tạm ngủ sau 15 phút không có truy cập. Lần mở tiếp theo có thể
chờ khoảng một phút. Trước buổi demo, mở web, đăng nhập thử và giữ sẵn
phương án chạy local nếu Internet hoặc dịch vụ miễn phí gặp sự cố.

Render/Neon đều có hạn mức miễn phí; theo dõi Usage trên tài khoản dịch vụ.
Không chọn nâng cấp trả phí để làm theo hướng dẫn này.

Tài liệu dịch vụ: <https://render.com/docs/free>,
<https://render.com/docs/blueprint-spec>,
<https://render.com/docs/deploys>,
<https://neon.com/docs/introduction/regions>.
