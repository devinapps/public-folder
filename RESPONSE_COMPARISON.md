# Response Comparison — NestJS vs PHP (incard-biz)

> Mục đích: Paste response thực tế từ cả 2 project để so sánh từng field.
> NestJS chạy port 3001 · PHP chạy port 8000

---

## Hướng dẫn sử dụng

1. Import `postman_business_api.json` vào Postman
2. Set biến `token` (login NestJS), `php_token` (login PHP)
3. Với mỗi endpoint: chạy NestJS → paste response vào cột **NestJS**, chạy PHP → paste vào cột **PHP**
4. Highlight các field khác nhau bằng `⚠️`

---

## Auth — Lấy token

### NestJS `POST /api/auth/login`
```
URL: http://localhost:3001/api/auth/login
```

**NestJS Response:**
```json
// PASTE HERE

```

**PHP Response:**
```json
// PASTE HERE — http://localhost:8000/api/login

```

**Diff notes:**
- [ ] token format
- [ ] user object fields

---

---

## 1. GET /api/cards — Danh sách cards

```
NestJS: GET http://localhost:3001/api/cards
PHP:    GET http://localhost:8000/api/cards
```

**NestJS Response:**
```json
// PASTE HERE

```

**PHP Response:**
```json
// PASTE HERE

```

**Checklist so sánh fields:**
- [ ] `id`, `slug`
- [ ] `first_name`, `last_name`
- [ ] `email`, `phone`, `title`, `company`, `bio`
- [ ] `industries` — format `[{id, name}]` vs PHP format
- [ ] `services`, `need_services`
- [ ] `sociallinks` / `social_links` — cả 2 key hay 1?
- [ ] `testimonials`
- [ ] `logo` — full URL hay chỉ path?
- [ ] `created_at`, `updated_at` — format `"2026 03 03 14:27:14"` hay ISO?
- [ ] `total_view`, `total_scan`, `total_appointment`
- [ ] `is_owner`, `is_my_card`
- [ ] `request_status` — `"not_requested"` hay giá trị khác?
- [ ] `profile_url` — có `/profile/` prefix không?
- [ ] `profile_qr`, `contact_qr`, `deeplink`
- [ ] `banner_img`, `settings`, `password`, `enable_password`
- [ ] `tags`, `owner_id`
- [ ] `product_services`, `media`
- [ ] `main_service`, `key_strength`, `looking_for`, `collaboration`
- [ ] `profiles_type`

**Diff notes:**
```
// Ghi chú các field khác nhau ở đây
```

---

## 2. POST /api/cards — Tạo card mới

```
NestJS: POST http://localhost:3001/api/cards
PHP:    POST http://localhost:8000/api/card/add
```

**NestJS Response:**
```json
// PASTE HERE

```

**PHP Response:**
```json
// PASTE HERE

```

**Checklist so sánh:**
- [ ] `message` — "Tạo danh thiếp thành công!" hay khác?
- [ ] `slug` — sequential suffix `-1,-2` hay random 4-digit?
- [ ] `profile_url` — có `/profile/` prefix không? (PHP bug: không có, NestJS đã fix)
- [ ] Có `profile_qr`, `contact_qr`, `deeplink` không? (PHP `add()` không trả về)
- [ ] `industries` format
- [ ] `sociallinks` format

**Diff notes:**
```
// Ghi chú các field khác nhau ở đây
```

---

## 3. GET /api/cards/:id — Chi tiết card

```
NestJS: GET http://localhost:3001/api/cards/{{card_id}}
PHP:    GET http://localhost:8000/api/card/detail/{{card_id}}
```

**NestJS Response:**
```json
// PASTE HERE

```

**PHP Response:**
```json
// PASTE HERE

```

**Checklist so sánh:**
- [ ] Tất cả fields từ mục 1 +
- [ ] `testimonials_is_enabled`
- [ ] `hasPhysicalCard` (true/false)
- [ ] `is_enable_appoinment` — từ plan
- [ ] `approved_at`
- [ ] `connected_id`, `connected_name`
- [ ] `total_view` có tăng sau mỗi lần call không?

**Diff notes:**
```
// Ghi chú các field khác nhau ở đây
```

---

## 3b. GET /api/cards/:id?fromScan=1 — Track scan

```
NestJS: GET http://localhost:3001/api/cards/{{card_id}}?fromScan=1
PHP:    GET http://localhost:8000/api/card/detail/{{card_id}}?fromScan=1
```

**NestJS Response:**
```json
// PASTE HERE

```

**PHP Response:**
```json
// PASTE HERE

```

**Checklist:**
- [ ] `total_scan` tăng sau call
- [ ] `business_history` record tạo không (verify qua DB)

---

## 4. POST /api/cards/update/:id — Cập nhật card

```
NestJS: POST http://localhost:3001/api/cards/update/{{card_id}}
PHP:    POST http://localhost:8000/api/card/update/{{card_id}}
```

**NestJS Response:**
```json
// PASTE HERE

```

**PHP Response:**
```json
// PASTE HERE

```

**Checklist:**
- [ ] `message` — "Cập nhật danh thiếp thành công!" hay khác?
- [ ] `profile_url` — PHP `update()` không có `/profile/` (bug), NestJS đã fix
- [ ] `industries` lưu đúng ID từ `industry_category` không?
- [ ] `social_link: {"Facebook":""}` → xóa Facebook link không?
- [ ] Không có `profile_qr`, `contact_qr`, `deeplink`, `banner_img` (PHP behavior)

**Diff notes:**
```
// Ghi chú các field khác nhau ở đây
```

---

## 5. DELETE /api/cards/:id — Xóa card

```
NestJS: DELETE http://localhost:3001/api/cards/{{card_id}}
PHP:    DELETE http://localhost:8000/api/card/delete/{{card_id}}
        (hoặc POST tùy PHP routing)
```

**NestJS Response (success):**
```json
// PASTE HERE

```

**PHP Response:**
```json
// PASTE HERE

```

**NestJS Response (không phải owner):**
```json
// PASTE HERE

```

**PHP Response (không phải owner):**
```json
// PASTE HERE

```

**Checklist:**
- [ ] `message` khi thành công
- [ ] `message` khi không phải owner — "Thẻ không hợp lệ"?
- [ ] Child records đã bị xóa chưa (verify DB)

---

## 6. GET /api/cards/industries — Ngành nghề

```
NestJS: GET http://localhost:3001/api/cards/industries?lang=vi
PHP:    GET http://localhost:8000/api/industry-category?lang=vi
        (hoặc endpoint tương đương)
```

**NestJS Response:**
```json
// PASTE HERE

```

**PHP Response:**
```json
// PASTE HERE

```

**Checklist:**
- [ ] Format `[{id, name}]`
- [ ] Số lượng items
- [ ] `id` là integer hay string?

---

## 7. POST /api/cards/banner/:id — Upload banner

```
NestJS: POST http://localhost:3001/api/cards/banner/{{card_id}}
PHP:    POST http://localhost:8000/api/card/banner/{{card_id}}
```

**NestJS Response:**
```json
// PASTE HERE

```

**PHP Response:**
```json
// PASTE HERE

```

**Checklist:**
- [ ] `banner_img` URL format
- [ ] Filename pattern `banner_{id}.png`

---

## 8. POST /api/cards/link-card/:id — Link NFC card

```
NestJS: POST http://localhost:3001/api/cards/link-card/{{card_id}}
PHP:    POST http://localhost:8000/api/card/link-card/{{card_id}}
```

**NestJS Response (success):**
```json
// PASTE HERE

```

**NestJS Response (mã không tồn tại):**
```json
// PASTE HERE

```

**NestJS Response (đã link):**
```json
// PASTE HERE

```

**PHP Response (tương ứng):**
```json
// PASTE HERE

```

**Checklist:**
- [ ] Message "Liên kết thành công." — có dấu chấm không?
- [ ] Response data có `code`, `business_id`, `user_id`, `group_id`, `status`, `note`?
- [ ] Error messages khớp nhau?

---

## 9. POST /api/cards/:id/generate-deeplink

```
NestJS: POST http://localhost:3001/api/cards/{{card_id}}/generate-deeplink
PHP:    POST http://localhost:8000/api/card/generate-deeplink/{{card_id}}
```

**NestJS Response:**
```json
// PASTE HERE

```

**PHP Response:**
```json
// PASTE HERE

```

**Checklist:**
- [ ] `deep_link_firebase` format
- [ ] Idempotent: gọi 2 lần → cùng link không?

---

## 10. POST /api/check-card/:cardCode — Kiểm tra QR (Public)

```
NestJS: POST http://localhost:3001/api/check-card/{{qr_serial}}
PHP:    POST http://localhost:8000/api/check-card/{{qr_serial}}
```

### Status 1 — Has Profile (QR đã gắn vào card)

**NestJS:**
```json
// PASTE HERE

```

**PHP:**
```json
// PASTE HERE

```

### Status 2 — Card Available (chưa link)

**NestJS:**
```json
// PASTE HERE

```

**PHP:**
```json
// PASTE HERE

```

### Status 3 — Owned By Another (có user_id, không phải owner)

**NestJS:**
```json
// PASTE HERE

```

**PHP:**
```json
// PASTE HERE

```

### Status 4 — Owner No Profile (là owner, chưa có card)

**NestJS:**
```json
// PASTE HERE

```

**PHP:**
```json
// PASTE HERE

```

### Status 5 — Unauthenticated, Has Account

**NestJS:**
```json
// PASTE HERE

```

**PHP:**
```json
// PASTE HERE

```

### Status 6 — Unknown

**NestJS:**
```json
// PASTE HERE

```

**PHP:**
```json
// PASTE HERE

```

**Checklist:**
- [ ] `statusCode` values (1-6) khớp nhau?
- [ ] `statusText` messages
- [ ] `profileId` — integer hay null?

---

## 11. GET /api/businesses/public/:slug — Public Profile

```
NestJS: GET http://localhost:3001/api/businesses/public/{{card_slug}}
PHP:    GET http://localhost:8000/api/public-profile/{{card_slug}}
        (hoặc tương đương)
```

**NestJS Response:**
```json
// PASTE HERE

```

**PHP Response:**
```json
// PASTE HERE

```

**Checklist:**
- [ ] `business` object — fields: `id`, `slug`, `title`, `last_name`, `sub_title`, `designation`, `bio`
- [ ] `title` vs `first_name` — PHP dùng `title` cho first_name?
- [ ] `sub_title` vs `company`
- [ ] `designation` vs `title` (job title)
- [ ] `logo`, `banner` — chỉ filename hay full URL?
- [ ] `contactInfo` array format
- [ ] `businessHours` array format
- [ ] `services` array format
- [ ] `media` array format
- [ ] `testimonials` array format
- [ ] `socials` array format — `{platform, url}` hay `{PlatformName: url}`?
- [ ] `deep_link_firebase` ở root level và trong `business` object

**Diff notes:**
```
// Ghi chú các field khác nhau ở đây
```

---

## Appointments

### A1. GET /api/appointments

```
NestJS: GET http://localhost:3001/api/appointments
PHP:    GET http://localhost:8000/api/appointment/list
```

**NestJS Response:**
```json
// PASTE HERE

```

**PHP Response:**
```json
// PASTE HERE

```

**Checklist:**
- [ ] `status` values: `pending`, `accepted`, `rejected`
- [ ] Date format `date` field
- [ ] Time format `time` field
- [ ] `created_at` format
- [ ] `user_requested`, `created_by` fields

---

### A2. POST /api/appointments/add

```
NestJS: POST http://localhost:3001/api/appointments/add
PHP:    POST http://localhost:8000/api/appointment/add
```

**NestJS Response:**
```json
// PASTE HERE

```

**PHP Response:**
```json
// PASTE HERE

```

---

### A5. POST /api/appointments/accept/:id

```
NestJS: POST http://localhost:3001/api/appointments/accept/{{appointment_id}}
PHP:    POST http://localhost:8000/api/appointment/accept/{{appointment_id}}
```

**NestJS Response:**
```json
// PASTE HERE

```

**PHP Response:**
```json
// PASTE HERE

```

---

### A6. POST /api/appointments/reject/:id

```
NestJS: POST http://localhost:3001/api/appointments/reject/{{appointment_id}}
PHP:    POST http://localhost:8000/api/appointment/reject/{{appointment_id}}
```

**NestJS Response:**
```json
// PASTE HERE

```

**PHP Response:**
```json
// PASTE HERE

```

---

## Known Differences (đã xác nhận)

| Endpoint | Field | PHP | NestJS | Ghi chú |
|---|---|---|---|---|
| POST /cards | `profile_url` | `{url}/{slug}` (no prefix) | `{url}/profile/{slug}` | PHP bug, NestJS đã fix |
| POST /cards/update | `profile_url` | `{url}/{slug}` (no prefix) | `{url}/profile/{slug}` | PHP bug, NestJS đã fix |
| POST /cards | Các QR fields | Không có | Không có | Cả 2 đều không trả `profile_qr`, `contact_qr`, `deeplink` |
| GET /cards | `sociallinks` | 1 key | 2 keys (`sociallinks` + `social_links`) | NestJS thêm alias |

---

## PHP Route Reference (incard-biz)

> Dùng để biết URL PHP tương ứng khi test

```
GET    /api/cards              → GET  /api/card/list     (hoặc /api/cards)
POST   /api/cards              → POST /api/card/add
GET    /api/cards/:id          → GET  /api/card/detail/:id
POST   /api/cards/update/:id   → POST /api/card/update/:id
DELETE /api/cards/:id          → DELETE /api/card/delete/:id  (hoặc POST)
GET    /api/cards/industries   → GET  /api/industry-category
POST   /api/cards/banner/:id   → POST /api/card/banner/:id
POST   /api/cards/link-card/:id → POST /api/card/link-card/:id
POST   /api/check-card/:code   → POST /api/check-card/:code
GET    /api/businesses/public/:slug → trang web public profile
GET    /api/appointments        → GET  /api/appointment/list
POST   /api/appointments/add    → POST /api/appointment/add
POST   /api/appointments/accept/:id → POST /api/appointment/accept/:id
POST   /api/appointments/reject/:id → POST /api/appointment/reject/:id
POST   /api/appointments/delete/:id → POST /api/appointment/delete/:id
```

> ⚠️ Kiểm tra `incard-biz/routes/api.php` để xác nhận URL chính xác trước khi test.
