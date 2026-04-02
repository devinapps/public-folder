# Business Card & QR API Reference

**Last updated:** 2026-03-31
**Base URL:** `{APP_URL}/api`
**Auth:** `Authorization: Bearer <jwt_token>` (trừ endpoint public và check-card)

---

## Tổng quan endpoints

| Method | Endpoint | Auth | Mô tả |
|--------|----------|------|-------|
| GET | `/api/cards` | ✅ JWT | Danh sách cards của user |
| GET | `/api/cards/industries` | ✅ JWT | Danh sách ngành nghề predefined |
| POST | `/api/cards` | ✅ JWT | Tạo card mới |
| GET | `/api/cards/:id` | ✅ JWT | Chi tiết card + track view/scan |
| POST | `/api/cards/update/:id` | ✅ JWT | Cập nhật card |
| DELETE | `/api/cards/:id` | ✅ JWT | Xóa card |
| POST | `/api/cards/banner/:id` | ✅ JWT | Upload banner |
| POST | `/api/cards/link-card/:id` | ✅ JWT | Gắn physical NFC card |
| POST | `/api/check-card/:cardCode` | ❌ Public (OptionalAuth) | Kiểm tra mã serial NFC card |
| GET | `/api/businesses/public/:slug` | ❌ Public (OptionalAuth) | Profile công khai cho FE Web |

---

## 1. GET `/api/cards`

**Mô tả:** Lấy danh sách tất cả business cards của user đang đăng nhập (owner hoặc created_by).

**Query params:**

| Param | Value | Mô tả |
|-------|-------|-------|
| `profiles_type` | `"mobile"` \| `"web"` \| ... | Filter theo loại profile (optional) |

**Side effects:**
- `generateProfileQr()`: Generate file PNG `storage/app/public/profile_qr/{slug}.png` nếu chưa tồn tại hoặc `deep_link` là null. Lưu `deep_link` vào DB.
- `generateContactQr()`: Generate file PNG `storage/app/public/contact_qr/{slug}.png` nếu chưa tồn tại.

**Request:**
```
GET /api/cards
GET /api/cards?profiles_type=mobile
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": true,
  "message": "",
  "data": [
    {
      "id": 1,
      "slug": "nguyen-van-a",
      "first_name": "Nguyen Van",
      "last_name": "A",
      "email": "example@gmail.com",
      "phone": "0901234567",
      "title": "CEO",
      "company": "Công ty ABC",
      "bio": "Giới thiệu bản thân",
      "industries": [{ "id": "0", "name": "Technology" }, { "id": "1", "name": "Finance" }],
      "services": [{ "id": "0", "name": "Consulting" }],
      "need_services": [],
      "sociallinks": [
        { "Facebook": "https://facebook.com/example", "id": 0 },
        { "Zalo": "https://zalo.me/example", "id": 1 }
      ],
      "social_links": [
        { "Facebook": "https://facebook.com/example", "id": 0 },
        { "Zalo": "https://zalo.me/example", "id": 1 }
      ],
      "testimonials": [],
      "logo": "http://localhost:3001/storage/card_logo/logo_123.png",
      "created_at": "2026 03 03 14:27:14",
      "updated_at": "2026 03 03 14:27:14",
      "total_view": 10,
      "total_scan": 2,
      "total_appointment": 0,
      "is_owner": true,
      "request_status": "not_requested",
      "profile_url": "http://localhost:3001/profile/nguyen-van-a",
      "profiles_type": "mobile",
      "main_service": null,
      "key_strength": null,
      "looking_for": null,
      "collaboration": null,
      "product_services": [],
      "media": [],
      "profile_qr": "http://localhost:3001/storage/profile_qr/nguyen-van-a.png",
      "contact_qr": "http://localhost:3001/storage/contact_qr/nguyen-van-a.png",
      "is_my_card": true,
      "deeplink": "http://localhost:3001/profile/nguyen-van-a",
      "banner_img": null,
      "settings": { "phone_enable": 1, "zalo_enable": 1, "whatsapp_enable": 1 },
      "password": null,
      "enable_password": 0,
      "tags": [],
      "owner_id": 13
    }
  ]
}
```

**Notes so sánh PHP:**
- `deeplink` = `business.deep_link` từ DB (auto-generated khi null). Nếu có physical card → `{APP_URL}/profile/{qrCode.code}`, nếu không → `{APP_URL}/profile/{slug}`.
- `profile_url` **có** prefix `/profile/` (PHP `index()` behavior).
- **[Phase 1 - B2 ✅]** `request_status` — từ `contact_requets` table (dynamic query — không còn hardcode).
- `sociallinks` = `social_links`: cùng nội dung, format `[{ "PlatformName": "url", "id": 0 }]`.
- `industries`, `services`, `need_services`: luôn trả `[{id, name}]` — PHP lưu DB dạng `{"0":"name"}` và transform.
- `settings`: object đã parse. Format: `{ phone_enable: 0|1, zalo_enable: 0|1, whatsapp_enable: 0|1 }` (integer, NOT boolean). Defaults: `{phone_enable:1, zalo_enable:1, whatsapp_enable:1}` merge với giá trị DB. PHP `getSettingsAttribute()` casts sang int.
- `email` / `phone`: extracted từ `contact_infos.content` — PHP flat format: `[{"Email":"val","id":0},{"Phone":"val","id":1}]`.
- `password`, `enable_password`: fields bảo vệ card bằng mật khẩu.

---

## 2. POST `/api/cards`

**Mô tả:** Tạo business card mới.

**Request:**
```
POST /api/cards
Authorization: Bearer <token>
Content-Type: multipart/form-data

first_name: "Nguyen Van"        (required)
last_name: "A"                  (required)
title: "CEO"                    (optional)
company: "Công ty ABC"          (optional)
bio: "Giới thiệu"               (optional)
email: "test@gmail.com"         (optional)
phone: "0901234567"             (optional)
profiles_type: "mobile"         (optional, default: "mobile")
main_service: null              (optional)
key_strength: null              (optional)
looking_for: {...}              (optional, JSON)
collaboration: {...}            (optional, JSON)
industries: ["Tech"]            (optional, JSON array)
services: ["Dev"]               (optional, JSON array)
need_services: []               (optional, JSON array)
social_link: {"Facebook":"url"} (optional, JSON object)
qrcode_serial: "ABC123"         (optional — link QR card ngay khi tạo)
logo: <file>                    (optional, multipart — field name: "logo")
service_image_0: <file>         (optional, multipart — ảnh cho servicesInfo[0])
service_image_1: <file>         (optional, multipart — ảnh cho servicesInfo[1])
... (service_image_0 → service_image_9, tối đa 10 dịch vụ có ảnh)
```

> **Lưu ý file upload:** Endpoint dùng `FileFieldsInterceptor` — chỉ accept các field: `logo`, `service_image_0` → `service_image_9`. Gửi field file không đúng tên sẽ bị từ chối `400 Unexpected field`.
>
> **Image URL trả về:** Sau khi upload, `product_services[i].image` = `{APP_URL}/storage/service_images/{filename}`.

**Response:**
```json
{
  "status": true,
  "message": "Tạo danh thiếp thành công!",
  "data": {
    "id": 2,
    "slug": "nguyen-van-a-5432",
    "first_name": "Nguyen Van",
    "last_name": "A",
    "email": "test@gmail.com",
    "phone": "0901234567",
    "title": "CEO",
    "company": "Công ty ABC",
    "bio": "Giới thiệu",
    "industries": [{ "id": "0", "name": "Tech" }],
    "services": [{ "id": "0", "name": "Dev" }],
    "need_services": [],
    "sociallinks": [{ "Facebook": "https://fb.com/x", "id": 0 }],
    "testimonials": [],
    "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
    "created_at": "2026 03 03 14:27:14",
    "updated_at": "2026 03 03 14:27:14",
    "total_view": 0,
    "total_scan": 0,
    "total_appointment": 0,
    "is_owner": true,
    "request_status": "not_requested",
    "profile_url": "http://localhost:3001/profile/nguyen-van-a-5432",
    "profiles_type": "mobile",
    "main_service": null,
    "key_strength": null,
    "looking_for": null,
    "collaboration": null,
    "product_services": [],
    "media": [],
    "password": null,
    "enable_password": null
  }
}
```

**Side effects:**
- Auto set `card_theme = theme5`, `theme_color = color5-theme5`.
- Nếu có `qrcode_serial`: link QR vào business ngay.
- Fallback: nếu user có physical card chưa link → tự động link.
- Gọi webhook `CARD_WEBHOOK_URL` (fire and forget) với `{card_id, type: "upsert"}`.

**Notes so sánh PHP:**
- `profile_url` **có** `/profile/` prefix — NestJS behavior (PHP `add()` không có prefix, nhưng NestJS luôn include).
- **KHÔNG có** `profile_qr`, `contact_qr`, `deeplink`, `banner_img`, `tags`, `owner_id`, `is_my_card`.
- `slug` khi tạo mới: nếu `nguyen-van-a` đã tồn tại → `nguyen-van-a-1`, `nguyen-van-a-2`, ..., `nguyen-van-a-100` (sequential, match PHP behavior). **Trước đây dùng random 4-digit — đã fix 2026-03-17**.

---

## 3. GET `/api/cards/:id`

**Mô tả:** Chi tiết card. **Luôn track view**. Nếu `?fromScan=1` thì track thêm scan.

**Query params:**

| Param | Value | Mô tả |
|-------|-------|-------|
| `fromScan` | `1` \| `true` | Track scan history (PHP behavior) |
| `type` | `serial` | **[Phase 1 - B1 ✅]** Lookup card theo QR serial code thay vì ID (PHP behavior) |

**Side effects:**
- Ghi record `business_history` type `view`.
- `UPDATE businesses SET total_view = total_view + 1`.
- Nếu `?fromScan=1`: ghi thêm `business_history` type `scan` + `total_scan++`.
- Nếu `?fromScan=1` và user đang scan card của người khác: tạo `contact_requets` type `recent`.
- `generateProfileQr()` + `generateContactQr()` như `GET /api/cards`.

**Request:**
```
GET /api/cards/1
GET /api/cards/1?fromScan=1
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": true,
  "message": "",
  "data": {
    "id": 1,
    "slug": "nguyen-van-a",
    "first_name": "Nguyen Van",
    "last_name": "A",
    "email": "example@gmail.com",
    "phone": "0901234567",
    "title": "CEO",
    "company": "Công ty ABC",
    "bio": "Giới thiệu",
    "industries": [{ "id": "0", "name": "Technology" }],
    "services": [{ "id": "0", "name": "Consulting" }],
    "need_services": [],
    "sociallinks": [{ "Facebook": "https://fb.com/x", "id": 0 }],
    "social_links": [{ "Facebook": "https://fb.com/x", "id": 0 }],
    "testimonials": [],
    "testimonials_is_enabled": 1,
    "logo": "http://localhost:3001/storage/card_logo/logo_123.png",
    "created_at": "2026 03 03 14:27:14",
    "updated_at": "2026 03 03 14:27:14",
    "total_view": 11,
    "total_scan": 3,
    "total_appointment": 0,
    "profile_qr": "http://localhost:3001/storage/profile_qr/nguyen-van-a.png",
    "contact_qr": "http://localhost:3001/storage/contact_qr/nguyen-van-a.png",
    "deeplink": "http://localhost:3001/profile/nguyen-van-a",
    "is_owner": true,
    "request_status": "not_requested",
    "approved_at": null,
    "profile_url": "http://localhost:3001/profile/nguyen-van-a",
    "hasPhysicalCard": false,
    "is_enable_appoinment": 1,
    "banner_img": null,
    "product_services": [],
    "media": [],
    "settings": { "phone_enable": 1, "zalo_enable": 1, "whatsapp_enable": 1 },
    "password": null,
    "enable_password": 0,
    "owner_id": 13,
    "tags": [],
    "connected_id": null,
    "connected_name": null,
    "profiles_type": "mobile",
    "main_service": null,
    "key_strength": null,
    "looking_for": null,
    "collaboration": null
  }
}
```

**Notes so sánh PHP:**
- `?fromScan=1` (không phải `?type=scan`) để track scan — đúng PHP behavior.
- `total_view` / `total_scan`: lấy từ DB sau khi increment (reload).
- `testimonials_is_enabled`: từ `testimonials.is_enabled` DB field.
- `hasPhysicalCard`: `true` nếu có row trong `qrcode_generated` với `business_id = id`.
- **[Phase 2 - B11 ✅]** `is_enable_appoinment`: từ `user.plan.enableAppointment` (dynamic query).
- **[Phase 2 - B8 ✅]** `approved_at`: từ `contact_requets.created_at` khi status = 'approved' (dynamic query).
- **[Phase 1 - B2 ✅]** `request_status`: từ `contact_requets` table (dynamic query — không còn hardcode).
- **[Phase 2 - B9 ✅]** `connected_id`, `connected_name`: từ approved contact (dynamic query — không còn hardcode).

---

## 4. POST `/api/cards/update/:id`

**Mô tả:** Cập nhật card. **Không track view/scan. Không kiểm tra ownership** (PHP behavior — bất kỳ user login đều update được).

**Request:**
```
POST /api/cards/update/1
Authorization: Bearer <token>
Content-Type: multipart/form-data

first_name: "Nguyen Van"        (optional)
last_name: "B"                  (optional)
title: "CTO"                    (optional)
company: "Công ty XYZ"          (optional)
bio: "Bio mới"                  (optional)
email: "new@gmail.com"          (optional)
phone: "0909999999"             (optional)
profiles_type: "mobile"         (optional)
main_service: "Dev"             (optional)
key_strength: "Leadership"      (optional)
looking_for: {...}              (optional, JSON)
collaboration: {...}            (optional, JSON)
industries: ["Finance"]         (optional — PHP field name; alias với category)
category: ["Finance"]           (optional — legacy/internal alias)
services: ["Consulting"]        (optional)
need_services: []               (optional)
social_link: {"Zalo": "url"}   (optional, JSON object — gửi value "" để xóa link)
settings: {...}                 (optional, JSON object)
media: [...]                    (optional, JSON array — product media)
servicesInfo: [...]             (optional, JSON array — product services)
                                  Format: [{ title, description, purchase_link?, image? }]
                                  image: URL ảnh cũ (giữ nguyên nếu không upload mới)
logo: <file>                    (optional, multipart — field name: "logo")
service_image_0: <file>         (optional, multipart — ảnh cho servicesInfo[0])
service_image_1: <file>         (optional, multipart — ảnh cho servicesInfo[1])
... (service_image_0 → service_image_9, tối đa 10 dịch vụ có ảnh)
testimonial_image_0: <file>     (optional, multipart — ảnh cho testimonials[0])
... (testimonial_image_0 → testimonial_image_9)
```

> **Lưu ý file upload:** Endpoint dùng `FileFieldsInterceptor` — tất cả các field file (`logo`, `service_image_*`, `testimonial_image_*`) phải gửi đúng tên field. Gửi field file không đúng tên sẽ bị từ chối `400 Unexpected field`.
>
> **Image URL trả về:** Sau khi upload, `product_services[i].image` = `{APP_URL}/storage/service_images/{filename}` và `testimonials[i].image` = `{APP_URL}/storage/testimonial_images/{filename}`.

**Response:**
```json
{
  "status": true,
  "message": "Cập nhật danh thiếp thành công!",
  "data": {
    "id": 1,
    "slug": "nguyen-van-a",
    "first_name": "Nguyen Van",
    "last_name": "B",
    "email": "new@gmail.com",
    "phone": "0909999999",
    "title": "CTO",
    "company": "Công ty XYZ",
    "bio": "Bio mới",
    "industries": [{ "id": "0", "name": "Finance" }],
    "services": [{ "id": "0", "name": "Consulting" }],
    "need_services": [],
    "sociallinks": [{ "Zalo": "url", "id": 0 }],
    "testimonials": [],
    "logo": "http://localhost:3001/storage/card_logo/logo_456.png",
    "created_at": "2026 03 03 14:27:14",
    "updated_at": "2026 03 03 15:00:00",
    "total_view": 11,
    "total_scan": 3,
    "total_appointment": 0,
    "is_owner": true,
    "request_status": "not_requested",
    "profile_url": "http://localhost:3001/nguyen-van-a",
    "profiles_type": "mobile",
    "main_service": "Dev",
    "key_strength": "Leadership",
    "looking_for": null,
    "collaboration": null,
    "product_services": [],
    "media": [],
    "settings": { "phone_enable": 1, "zalo_enable": 1, "whatsapp_enable": 1 }
  }
}
```

**Side effects (Phase 2 - B3 ✅ — AI webhook):**
- Luôn overwrite `card_theme = theme5`, `theme_color = color5-theme5` (PHP behavior).
- Reset `matching_data = null` (force AI re-embedding).
- **[PHASE 2 - B3 ✅]** Gọi webhook `RENEW_POTENTIAL_PROFILE_WEBHOOK_URL` (fire-and-forget) để re-embed AI matching data.
- Gọi webhook `CARD_WEBHOOK_URL` với `{card_id, type: "upsert"}`.

**Notes so sánh PHP:**
- `profile_url` **có** `/profile/` prefix — NestJS behavior (PHP `update()` không có prefix).
- **KHÔNG có** `profile_qr`, `contact_qr`, `deeplink`, `banner_img`, `tags`, `owner_id`, `is_my_card`.
- Field `industries` (PHP) được lưu vào DB column `category`. Cả `industries` lẫn `category` đều được chấp nhận.

---

## 5. DELETE `/api/cards/:id`

**Mô tả:** Xóa card. Chỉ `owner_id = userId` mới được xóa (KHÔNG check `created_by` — PHP behavior).

**Request:**
```
DELETE /api/cards/1
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": true,
  "message": "Xóa danh thiếp thành công!",
  "data": null
}
```

**Response (không phải owner):**
```json
{
  "status": false,
  "message": "Thẻ không hợp lệ",
  "data": null
}
```

**Side effects (Phase 4 - B4 ✅ — Cascade delete):**
- Xóa tất cả child records (correct order):
  - `contactInfos`, `businessHours`, `servicesTable`, `testimonials`
  - `businessHistories`, `socials`, `contactRequets`
- Unlink `qrcode_generated` (set `business_id = null`).
- Xóa row trong `businesses` table.
- Gọi webhook `CARD_WEBHOOK_URL` với `{card_id, type: "delete"}`.

---

## 6. GET `/api/cards/industries`

**Mô tả:** Lấy danh sách ngành nghề predefined từ bảng `industry_category` (status=1).

**Query params:** `?lang=vi` (default: `vi`)

**Request:**
```
GET /api/cards/industries?lang=vi
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": true,
  "message": "Lấy danh sách ngành nghề thành công",
  "data": [
    { "id": 1, "name": "Công nghệ thông tin" },
    { "id": 2, "name": "Tài chính - Ngân hàng" },
    { "id": 3, "name": "Bất động sản" }
  ]
}
```

**Ghi chú:**
- Dùng để populate dropdown gợi ý trong form tạo/sửa card (FE `IndustriesTagInput` component).
- FE cũng cho phép nhập free-text tạo tag mới — BE nhận `industries: ["tên1", "tên2"]` trong create/update.

---

## 7. POST `/api/cards/banner/:id`

**Mô tả:** Upload ảnh banner cho card.

**Request:**
```
POST /api/cards/banner/1
Authorization: Bearer <token>
Content-Type: multipart/form-data

banner_img: <file>    (required)
```

**File lưu tại:** `storage/app/public/banner_img/banner_{id}.png`

**Response:**
```json
{
  "status": true,
  "message": "Cập nhật thành công",
  "data": {
    "banner_img": "http://localhost:3001/storage/banner_img/banner_1.png"
  }
}
```

---

## 7. POST `/api/cards/link-card/:id`

**Mô tả:** Gắn physical NFC card (QR code serial) vào business card.

**Request:**
```
POST /api/cards/link-card/1
Authorization: Bearer <token>
Content-Type: application/json

{
  "card_code": "ABC123XYZ"
}
```

**Response (success):**
```json
{
  "status": true,
  "message": "Liên kết thành công.",
  "data": {
    "id": 5,
    "code": "ABC123XYZ",
    "business_id": 1,
    "user_id": 13,
    "group_id": null,
    "status": 1,
    "note": null,
    "created_at": "...",
    "updated_at": "..."
  }
}
```

**Response (error — mã không tồn tại):**
```json
{
  "status": false,
  "message": "Mã code không tồn tại",
  "data": null
}
```

**Response (error — QR đã được liên kết):**
```json
{
  "status": false,
  "message": "Thẻ đã được liên kết. Vui lòng chọn thẻ khác.",
  "data": null
}
```

**Side effects:**
- `UPDATE qrcode_generated SET business_id = id, user_id = business.owner_id WHERE id = qr.id`
- `UPDATE businesses SET deep_link = null WHERE id = id` → force regenerate QR lần sau.

---

## 8. POST `/api/check-card/:cardCode`

**Mô tả:** Kiểm tra trạng thái của NFC card serial. Dùng trước khi link card.

> ⚠️ **PUBLIC route** — không cần auth. Nếu có token thì user được nhận diện (OptionalAuth).

**Request:**
```
POST /api/check-card/ABC123XYZ
(không cần Authorization header)
```

**Response — các trạng thái (matching PHP CardController exactly):**

| statusCode | Mô tả | Điều kiện |
|-----------|-------|-----------|
| 1 | Has Profile | QR đã gắn vào business, hoặc slug khớp với business |
| 2 | Card Available | QR tồn tại, chưa link business lẫn user; hoặc slug không match |
| 3 | Owned By Another | QR có user_id, không có business_id, user hiện tại KHÔNG phải owner |
| 4 | Owner No Profile | QR có user_id, không có business_id, user hiện tại LÀ owner |
| 5 | Has Account No Profile | Unauthenticated: QR có user_id nhưng không có business_id |
| 6 | Unknown | Default / QR không tìm thấy và slug không khớp |

```json
// statusCode 1 — có profile
{ "status": true, "message": "", "data": { "statusCode": 1, "profileId": 42, "statusText": "Có profile" } }

// statusCode 2 — card available
{ "status": true, "message": "", "data": { "statusCode": 2, "profileId": null, "statusText": "Chưa có profile & chưa có account" } }

// statusCode 3 — owned by another
{ "status": true, "message": "", "data": { "statusCode": 3, "profileId": null, "statusText": "Có account && chưa có profile nhưng ko phải owner" } }

// statusCode 4 — owner, no profile yet
{ "status": true, "message": "", "data": { "statusCode": 4, "profileId": null, "statusText": "Có account && chưa có profile & là owner" } }

// statusCode 5 — unauthenticated, has account no profile
{ "status": true, "message": "", "data": { "statusCode": 5, "profileId": null, "statusText": "Có account && chưa có profile" } }

// statusCode 6 — unknown
{ "status": true, "message": "", "data": { "statusCode": 6, "profileId": null, "statusText": "" } }
```

---

## 9. GET `/api/businesses/public/:slug`

**Mô tả:** Profile công khai cho FE Web (trang `incard.biz/profile/{slug}`). Không cần auth, có OptionalAuth.

**Side effects:**
- Luôn ghi `business_history` type `view` + `total_view++`.
- Nếu `?fromScan=1` HOẶC slug là mã QR physical card → ghi thêm `business_history` type `scan` + `total_scan++`.

**Request:**
```
GET /api/businesses/public/nguyen-van-a
GET /api/businesses/public/nguyen-van-a?fromScan=1
GET /api/businesses/public/ABC123XYZ           ← dùng QR code thay vì slug
```

**Response:**
```json
{
  "status": true,
  "message": "Lấy profile thành công",
  "data": {
    "business": {
      "id": 1,
      "slug": "nguyen-van-a",
      "title": "Nguyen Van",
      "last_name": "A",
      "sub_title": "Công ty ABC",
      "designation": "CEO",
      "bio": "...",
      "logo": "logo_123.png",
      "banner": "banner_1.png",
      "total_view": 11,
      "total_scan": 3,
      "deep_link": "http://localhost:3001/profile/nguyen-van-a",
      "settings": { "phone_enable": 1 },
      "industries": [{ "id": "0", "name": "Technology" }],
      "services": [{ "id": "0", "name": "Consulting" }],
      "profiles_type": "mobile",
      "owner_id": 13,
      "created_by": 13,
      "created_at": "2026-03-03T07:27:14.000Z",
      "updated_at": "2026-03-03T07:27:14.000Z"
    },
    "contactInfo": [...],
    "businessHours": [...],
    "services": [...],
    "media": [...],
    "testimonials": [...],
    "socials": [...]
  }
}
```

---

## QR File Generation Logic

### Profile QR (`storage/app/public/profile_qr/{slug}.png`)

```
Điều kiện generate: file chưa tồn tại HOẶC business.deep_link == null
Encode vào QR: {APP_URL}/profile/{slug}  ← luôn là slug URL (không phải deeplink)
deep_link lưu DB:
  - Nếu có physical card: {APP_URL}/profile/{qrCode.code}
  - Nếu không: {APP_URL}/profile/{slug}
Size: 500×500 px, Error correction: H
Serve tại: GET /storage/profile_qr/{slug}.png
```

### Contact QR (`storage/app/public/contact_qr/{slug}.png`)

```
Điều kiện generate: file chưa tồn tại (KHÔNG force-regen)
Encode vào QR: vCard VCF string
  BEGIN:VCARD
  VERSION:3.0
  N:{lastName};{firstName}
  FN:{firstName} {lastName}
  ORG:{subTitle}
  TITLE:{designation}
  EMAIL;TYPE=WORK:{email}
  TEL;TYPE=WORK,VOICE:{phone}
  URL:{APP_URL}/profile/{slug}
  X-SOCIALPROFILE;type={platform}:{url}
  ...
  END:VCARD
Size: 800×800 px, Error correction: H
Serve tại: GET /storage/contact_qr/{slug}.png
```

---

## Slug Generation Logic

### createSlug algorithm (businesses.service.ts)

```
Input: first_name + " " + last_name
Step 1: slugify(text, { lower: true, locale: 'vi', strict: true })
        "Nguyễn Văn A" → "nguyen-van-a"

Step 2: Check DB — if "nguyen-van-a" not taken → return "nguyen-van-a"

Step 3: Sequential suffix loop (matches incard-biz PHP behavior):
        "nguyen-van-a-1" → taken? try next
        "nguyen-van-a-2" → taken? try next
        ...
        "nguyen-van-a-100" → if still taken → throw Error

Note: findBySlug() uses ORDER BY id ASC LIMIT 1 — trả về record cũ nhất khi có duplicate (phòng hờ data cũ).
```

### Slug integrity fix (2026-03-17)

| Vấn đề | Trạng thái |
|--------|-----------|
| 26 bản ghi duplicate slug trong DB | ✅ Cleanup — đã gán suffix `-2`, `-3`, ... |
| `createSlug` dùng random 4-digit suffix | ✅ Đổi sang sequential `-1`, `-2`, ... (match PHP) |
| `findBySlug` không có ORDER BY | ✅ Thêm `ORDER BY id ASC LIMIT 1` |

---

## Phase 1-3 Fixes Status

| Endpoint | Field | Trạng thái | Mô tả |
|---------|-------|-----------|-------|
| GET `/api/cards`, GET `/api/cards/:id` | `request_status` | ✅ **[Phase 1 - B2]** IMPLEMENTED | Dynamic query từ `contact_requets` table |
| GET `/api/cards/:id` | `approved_at` | ✅ **[Phase 2 - B8]** IMPLEMENTED | Dynamic từ `contact_requets.created_at` khi status = 'approved' |
| GET `/api/cards/:id` | `is_enable_appoinment` | ✅ **[Phase 2 - B11]** IMPLEMENTED | Dynamic từ `user.plan.enableAppointment` |
| GET `/api/cards/:id` | `connected_id`, `connected_name` | ✅ **[Phase 2 - B9]** IMPLEMENTED | Dynamic từ approved contact |
| POST `/api/cards/update/:id` | AI webhook | ✅ **[Phase 2 - B3]** IMPLEMENTED | Fire-and-forget call đến `RENEW_POTENTIAL_PROFILE_WEBHOOK_URL` |
| DELETE `/api/cards/:id` | Cascade delete | ✅ **[Phase 4 - B4]** IMPLEMENTED | Xóa tất cả child records (contactInfos, businessHours, services, testimonials, histories) |
| GET `/api/cards/:id` | `?type=serial` | ✅ **[Phase 1 - B1]** IMPLEMENTED | Lookup card theo QR serial code thay vì numeric ID |

### contact_infos.content Format (PHP-compatible)

`contact_infos.content` lưu JSON array flat format (PHP-compatible):
```json
[
  { "Email": "owner@example.com", "id": 0 },
  { "Phone": "0901234567", "id": 1 }
]
```

> ⚠️ NestJS từng dùng nested format (`{ "Email": [{ "value": "...", "label": "Email" }] }`).
> Đã fix để dùng PHP flat format. Extraction code handle backward compat với data cũ.

> `POST /api/cards/:id/generate-deeplink` **đã bị xóa** — Firebase Dynamic Links deprecated tháng 8/2025.

### Reference Documentation
- **Postman Collection**: [user-profiles.json](../user-profiles.json) — 3 new test endpoints (8, 9, 10)
- **Update Log**: [POSTMAN_COLLECTION_UPDATE.md](POSTMAN_COLLECTION_UPDATE.md)
- **Phase Plan**: [BUSINESS_CARD_API_PHASES.md](BUSINESS_CARD_API_PHASES.md)
