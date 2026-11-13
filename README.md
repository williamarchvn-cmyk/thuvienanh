# Thư viện ảnh (thuvienanh)

Web app lưu ảnh cá nhân kiểu Pinterest. Một file `index.html`, dùng Supabase (CSDL + kho ảnh + đồng bộ tức thời), host trên Vercel. 100% gói Free.

```
thuvienanh/
├─ index.html                        # toàn bộ app
├─ supabase/schema.sql               # tạo bảng, quyền, kho ảnh, realtime
├─ .github/workflows/keepalive.yml   # giữ Supabase không bị tạm dừng
└─ README.md
```

> Chưa điền Supabase trong `index.html` thì app tự chạy **dữ liệu giả lập**. Mở file là thấy ngay.

---

## Cài đặt lần đầu (khoảng 20 phút)

### Bước 1. Tạo project Supabase
1. Vào https://supabase.com → đăng nhập bằng GitHub → **New project**.
2. Đặt tên `thuvienanh`, đặt mật khẩu database (lưu lại), **Region: Southeast Asia (Singapore)** cho nhanh nhất từ Việt Nam.
3. Chờ khoảng 2 phút cho project chạy xong.

### Bước 2. Chạy file SQL
1. Trong project: menu trái **SQL Editor** → **New query**.
2. Mở `supabase/schema.sql`, copy toàn bộ, dán vào, bấm **Run**.
3. Kết quả cuối phải ra 3 dòng: `photos`, `albums`, `album_photos`. Có lỗi thì chụp màn hình gửi lại.

### Bước 3. Lấy URL và key
1. Menu trái **Project Settings** → **API Keys** (hoặc **Data API**).
2. Copy **Project URL** (dạng `https://xxxx.supabase.co`).
3. Copy key công khai: **publishable key** (`sb_publishable_...`) hoặc **anon key** (`eyJ...`).
   ⚠️ Tuyệt đối KHÔNG dùng `service_role` / `secret` key.

### Bước 4. Điền vào `index.html`
Mở `index.html` bằng Notepad/VS Code, tìm khối `CONFIG` ở đầu phần `<script>`:

```js
SUPABASE_URL: 'https://xxxx.supabase.co',
SUPABASE_ANON_KEY: 'sb_publishable_xxxxxxxx',
```

Lưu lại, mở `index.html` bằng Chrome để thử ngay trên máy: nhãn vàng "Dữ liệu mẫu" biến mất, thư viện trống → tải thử vài ảnh.

### Bước 5. Đưa code lên GitHub
1. https://github.com/new → tên `thuvienanh` → chọn **Private** → Create.
2. Bấm **uploading an existing file** → kéo cả 4 mục (`index.html`, `README.md`, thư mục `supabase`, thư mục `.github`) vào → **Commit changes**.
   Thư mục `.github` bị ẩn trên Windows: bật View → Hidden items, hoặc tạo file trên GitHub bằng **Add file → Create new file**, gõ tên `.github/workflows/keepalive.yml` rồi dán nội dung.

### Bước 6. Deploy lên Vercel
1. https://vercel.com → **Add New → Project** → chọn repo `thuvienanh` → **Import**.
2. Framework Preset: **Other**. Không cần điền gì thêm → **Deploy**.
3. Xong sẽ có link dạng `thuvienanh-xxxx.vercel.app`. Mở trên laptop và S23 Ultra.
   Gợi ý: Settings → Domains đổi sang tên khó đoán, vì ai có link cũng xem/xóa được ảnh.

Từ giờ mỗi lần sửa `index.html` trên GitHub, Vercel tự deploy lại sau khoảng 30 giây.

### Bước 7. Bật giữ Supabase hoạt động
1. Repo GitHub → **Settings → Secrets and variables → Actions → New repository secret**.
2. Tạo `SUPABASE_URL` và `SUPABASE_ANON_KEY` (giống bước 4).
3. Tab **Actions** → chọn "Giu Supabase hoat dong" → **Run workflow** để chạy thử. Dấu ✓ xanh là xong.

---

## Kiểm tra sau khi cài (đánh dấu từng mục)

| # | Thử | Kết quả đúng |
|---|---|---|
| 1 | Laptop: bấm "Tải ảnh lên", chọn 5 ảnh | Hiện tiến độ, ảnh vào đầu lưới |
| 2 | Laptop: chụp màn hình (Win+Shift+S) → Ctrl+V trong app | Ảnh dán vào |
| 3 | Laptop: kéo file ảnh từ thư mục thả vào app | Hiện lớp "Thả ảnh vào đây", ảnh tải lên |
| 4 | Mở app trên điện thoại cùng lúc, thêm ảnh trên laptop | Điện thoại tự hiện ảnh trong vài giây |
| 5 | Điện thoại: bấm + chọn ảnh từ Thư viện | Ảnh tải lên, laptop tự hiện |
| 6 | Bấm 1 ảnh → sửa ghi chú, thêm tag, link | Mở ở thiết bị kia thấy đúng |
| 7 | Tìm "noi that" (không dấu) | Ra ảnh có tag/ghi chú "nội thất" |
| 8 | Tạo album, thêm ảnh, chuyển ảnh, gỡ ảnh | Đúng trên cả 2 thiết bị |
| 9 | Xóa ảnh → bấm Hoàn tác | Ảnh quay lại; không bấm thì mất hẳn |
| 10 | Cài đặt → Tải bản sao lưu | Tải về file .zip có `data.json` và thư mục `full/` |
| 11 | Ảnh HEIC từ điện thoại (nếu camera bật HEIF) | Tải được, hoặc báo lỗi rõ ràng (CẦN XÁC MINH) |
| 12 | Kéo ảnh từ 1 tab web khác vào | Tải được, hoặc hiện hướng dẫn Ctrl+V (CẦN XÁC MINH) |
| 13 | Sau 8–10 ngày không mở app | App vẫn chạy (keepalive hoạt động — CẦN XÁC MINH) |

---

## Gặp lỗi

| Hiện tượng | Cách xử lý |
|---|---|
| Thanh đỏ "Không kết nối được máy chủ" | Kiểm tra URL/key trong `CONFIG`; Supabase có thể đang tạm dừng → vào dashboard bấm **Restore** |
| Lỗi `permission denied` / `42501` | Chạy lại `schema.sql` (phần GRANT) |
| Tải ảnh lỗi 400/403 | Kiểm tra bucket `photos` tồn tại (Storage) và đã chạy phần 6 của SQL |
| Thiết bị kia không tự cập nhật | Dòng cuối của SQL phải ra 3 bảng; vẫn có thể kéo xuống/bấm "Làm mới ngay" |
| Kho gần đầy | Cài đặt → xem dung lượng; xóa bớt ảnh, bấm "Dọn file thừa" |

Gỡ lỗi: trên laptop bấm F12 → tab **Console**, chụp dòng đỏ gửi lại.

## Giới hạn gói Free (đã tính trong app)
- Kho ảnh 1 GB → app cảnh báo ở 800 MB, chặn tải lên ở 950 MB (khoảng 2.000–2.400 ảnh).
- Supabase Free tạm dừng sau 1 tuần không hoạt động → đã có keepalive.
- Ai có link đều xem/sửa/xóa được (đã chốt không đăng nhập) → nên sao lưu định kỳ.
