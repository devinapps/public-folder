# Business Card & QR API Reference

**Last updated:** 2026-03-03
**Base URL:** `{APP_URL}/api`
**Auth:** `Authorization: Bearer <jwt_token>` (trừ endpoint public)

---

## Tổng quan endpoints

| Method | Endpoint | Auth | Mô tả |
|--------|----------|------|-------|
| GET | `/api/cards` | ✅ JWT | Danh sách cards của user |
| POST | `/api/cards` | ✅ JWT | Tạo card mới |
| GET | `/api/cards/:id` | ✅ JWT | Chi tiết card + track view/scan |
| POST | `/api/cards/update/:id` | ✅ JWT | Cập nhật card |
| DELETE | `/api/cards/:id` | ✅ JWT | Xóa card |
| POST | `/api/cards/banner/:id` | ✅ JWT | Upload banner |
| POST | `/api/cards/link-card/:id` | ✅ JWT | Gắn physical NFC card |
| POST | `/api/cards/:id/generate-deeplink` | ✅ JWT | Generate Firebase Dynamic Link |
| POST | `/api/check-card/:cardCode` | ✅ JWT | Kiểm tra mã serial NFC card |
| GET | `/api/businesses/public/:slug` | ❌ Public (OptionalAuth) | Profile công khai cho FE Web |

---

## 1. GET `/api/cards`

**Mô tả:** Lấy danh sách tất cả business cards của user đang đăng nhập (owner hoặc created_by).

**Side effects:**
- `generateProfileQr()`: Generate file PNG `storage/app/public/profile_qr/{slug}.png` nếu chưa tồn tại hoặc `deep_link` là null. Lưu `deep_link` vào DB.
- `generateContactQr()`: Generate file PNG `storage/app/public/contact_qr/{slug}.png` nếu chưa tồn tại.

**Request:**
```
GET /api/cards
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
      "industries": ["Technology", "Finance"],
      "services": ["Consulting", "Development"],
      "need_services": [],
      "sociallinks": [
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
      "tags": [],
      "owner_id": 13
    }
  ]
}
```

**Notes so sánh PHP:**
- `deeplink` = `business.deep_link` từ DB (auto-generated khi null). Nếu có physical card → `{APP_URL}/profile/{qrCode.code}`, nếu không → `{APP_URL}/profile/{slug}`.
- `profile_url` **có** prefix `/profile/` (PHP `index()` behavior).
- `request_status` hiện hardcode `"not_requested"` — PHP query từ `contact_requets` table (TODO).
- `sociallinks` format: `[{ "PlatformName": "url", "id": 0 }]` — đúng PHP format.
- `settings` là **object** đã được parse (NestJS cải tiến so với PHP trả raw string). Defaults: `{phone_enable:1, zalo_enable:1, whatsapp_enable:1}` merge với giá trị lưu trong DB.
- `industries`, `services`, `need_services`: NestJS luôn trả `[{id, name}]` format — PHP lưu DB dạng `{"0":"name"}` và transform giống nhau.

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
industries: ["Tech"]            (optional, JSON array or string)
services: ["Dev"]               (optional, JSON array or string)
need_services: []               (optional, JSON array or string)
social_link: {"Facebook":"url"} (optional, JSON object)
qrcode_serial: "ABC123"        (optional)
logo: <file>                    (optional, multipart)
```

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
    "industries": ["Tech"],
    "services": ["Dev"],
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
    "profile_url": "http://localhost:3001/nguyen-van-a-5432",
    "profiles_type": "mobile",
    "main_service": null,
    "key_strength": null,
    "looking_for": null,
    "collaboration": null,
    "product_services": [],
    "media": []
  }
}
```

**Notes so sánh PHP:**
- `profile_url` **KHÔNG có** `/profile/` prefix — đúng PHP `add()` behavior.
- **KHÔNG có** `profile_qr`, `contact_qr`, `deeplink`, `banner_img`, `tags`, `owner_id`, `is_my_card` — đúng PHP.
- `created_at` / `updated_at` format `'YYYY MM DD HH:mm:ss'` — đã fix (trước đây null).

---

## 3. GET `/api/cards/:id`

**Mô tả:** Chi tiết card. **Luôn track view**. Nếu `?type=scan` thì track thêm scan.

**Side effects:**
- Ghi record `business_history` type `view`.
- `UPDATE businesses SET total_view = total_view + 1`.
- Nếu `?type=scan`: ghi thêm `business_history` type `scan` + `total_scan++`.
- `generateProfileQr()` + `generateContactQr()` như `GET /api/cards`.

**Request:**
```
GET /api/cards/1
GET /api/cards/1?type=scan
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
    "industries": ["Technology"],
    "services": ["Consulting"],
    "need_services": [],
    "sociallinks": [{ "Facebook": "https://fb.com/x", "id": 0 }],
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
- `total_view` / `total_scan`: lấy từ DB sau khi increment (reload).
- `testimonials_is_enabled`: từ `testimonials.is_enabled` DB field.
- `hasPhysicalCard`: `true` nếu có row trong `qrcode_generated` với `business_id = id`.
- `is_enable_appoinment`: hardcode `1` (PHP check user plan — TODO nếu cần).
- `approved_at`: hardcode `null` (PHP query `contact_requets` — TODO).
- `request_status`: hardcode `"not_requested"` (TODO).
- `connected_id`, `connected_name`: hardcode `null` (PHP contact connection — TODO).

---

## 4. POST `/api/cards/update/:id`

**Mô tả:** Cập nhật card. **Không track view/scan.**

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
category: ["Finance"]           (optional)
services: ["Consulting"]        (optional)
need_services: []               (optional)
social_link: {"Zalo": "url"}   (optional, JSON object)
settings: {...}                 (optional, JSON object)
media: [...]                    (optional, JSON array)
servicesInfo: [...]             (optional, JSON array)
logo: <file>                    (optional, multipart)
```

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
    "industries": ["Finance"],
    "services": ["Consulting"],
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

**Notes so sánh PHP:**
- `profile_url` **KHÔNG có** `/profile/` prefix — đúng PHP `update()` behavior.
- **KHÔNG có** `profile_qr`, `contact_qr`, `deeplink`, `banner_img`, `tags`, `owner_id`, `is_my_card`.
- `settings` được save từ request, rồi merge với defaults khi trả về.
- PHP luôn overwrite `card_theme` = `theme5`, `theme_color` = `color5-theme5`.

---

## 5. DELETE `/api/cards/:id`

**Mô tả:** Xóa card. Chỉ owner mới được xóa.

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

**Side effects:**
- Xóa row trong `social` table.
- Unlink `qrcode_generated` (set `business_id = null`).
- Xóa row trong `businesses` table.

---

## 6. POST `/api/cards/banner/:id`

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
  "message": "",
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
  "message": "",
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

**Response (error — không tìm thấy mã):**
```json
{
  "status": false,
  "message": "Mã thẻ không tồn tại",
  "data": null
}
```

**Side effects:**
- `UPDATE qrcode_generated SET business_id = id, user_id = business.owner_id WHERE id = qr.id`
- `UPDATE businesses SET deep_link = null WHERE id = id` → force regenerate QR lần sau.

---

## 8. POST `/api/cards/:id/generate-deeplink`

**Mô tả:** Generate Firebase Dynamic Link cho card. Dùng để FE Web redirect vào app InCard.

**Logic:**
1. Nếu `business.deep_link_firebase` đã có → trả về luôn (không generate lại).
2. Nếu chưa → call Firebase API → lưu vào DB → trả về.

**Request:**
```
POST /api/cards/1/generate-deeplink
Authorization: Bearer <token>
```

**Response (success):**
```json
{
  "status": true,
  "message": "",
  "data": {
    "deep_link_firebase": "https://inapps.page.link/abc123"
  }
}
```

**Response (error — chưa config Firebase):**
```json
{
  "status": false,
  "message": "FIREBASE_API_KEY chưa được cấu hình",
  "data": null
}
```

**Firebase API call (nội bộ):**
```
POST https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key={FIREBASE_API_KEY}
Body: {
  "longDynamicLink": "https://inapps.page.link/?link={profileUrl}&apn=net.inapps.incard{env}&ibi=net.inapps.incard{env}&afl={profileUrl}&ifl={profileUrl}&ofl={profileUrl}"
}
```

**ENV cần có:**
```env
FIREBASE_API_KEY=AIzaSy...
APP_ENV=staging|development|production
```

---

## 9. POST `/api/check-card/:cardCode`

**Mô tả:** Kiểm tra trạng thái của NFC card serial. Dùng trước khi link card. **HTTP method: POST** (matches PHP source).

**Request:**
```
POST /api/check-card/ABC123XYZ
Authorization: Bearer <token>
```

**Response — các trạng thái (matching PHP CardController exactly):**

| statusCode | statusText (PHP) | Mô tả |
|-----------|-----------------|-------|
| 1 | Có profile | QR đã gắn vào profile, hoặc slug khớp với business |
| 2 | Chưa có profile & chưa có account | QR chưa gắn vào ai, không tìm thấy business theo slug |
| 3 | Có account && chưa có profile nhưng ko phải owner | QR có user_id nhưng không có business_id, user hiện tại KHÔNG phải owner |
| 4 | Có account && chưa có profile & là owner | QR có user_id nhưng không có business_id, user hiện tại LÀ owner |
| 5 | Có account && chưa có profile | Không đăng nhập: QR có user_id nhưng không có business_id |
| 6 | (empty) | Default / unknown state |

```json
// Có profile
{ "status": true, "message": "", "data": { "statusCode": 1, "profileId": 42, "statusText": "Có profile" } }

// Card available (chưa có account)
{ "status": true, "message": "", "data": { "statusCode": 2, "profileId": null, "statusText": "Chưa có profile & chưa có account" } }

// Owned by another
{ "status": true, "message": "", "data": { "statusCode": 3, "profileId": null, "statusText": "Có account && chưa có profile nhưng ko phải owner" } }

// Owner, no profile yet
{ "status": true, "message": "", "data": { "statusCode": 4, "profileId": null, "statusText": "Có account && chưa có profile & là owner" } }

// Default/unknown
{ "status": true, "message": "", "data": { "statusCode": 6, "profileId": null, "statusText": "" } }
```

---

## 10. GET `/api/businesses/public/:slug`

**Mô tả:** Profile công khai cho FE Web (trang `incard.biz/profile/{slug}`). Không cần auth, có OptionalAuth.

**Side effects:**
- Luôn ghi `business_history` type `view` + `total_view++`.
- Nếu `?type=scan` HOẶC slug là mã QR physical card → ghi thêm `business_history` type `scan` + `total_scan++`.

**Request:**
```
GET /api/businesses/public/nguyen-van-a
GET /api/businesses/public/nguyen-van-a?type=scan
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
      "lastName": "A",
      "designation": "CEO",
      "subTitle": "Công ty ABC",
      "bio": "...",
      "logo": "logo_123.png",
      "banner": "banner_1.png",
      "totalView": 11,
      "totalScan": 3,
      "deepLink": "http://localhost:3001/profile/nguyen-van-a",
      "deepLinkFirebase": "https://inapps.page.link/abc123",
      "settings": "...",
      "createdAt": "2026-03-03T07:27:14.000Z",
      "updatedAt": "2026-03-03T07:27:14.000Z"
    },
    "contactInfo": [...],
    "businessHours": [...],
    "services": [...],
    "media": [...],
    "testimonials": [...],
    "socials": [...],
    "deep_link_firebase": "https://inapps.page.link/abc123"
  }
}
```

> ⚠️ **Gap cần lưu ý:** Response trả `business` object dạng **raw Drizzle camelCase** (không format như các endpoint `/api/cards`). PHP trả formatted object. Nếu FE Web cần format giống `/api/cards/:id` thì cần chuẩn hóa lại.

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

## Flow đầy đủ: QR scan → App deeplink

```
1. User quét QR code vật lý (physical NFC card)
   → QR encode URL: {APP_URL}/profile/{qrCode.code}

2. GET /api/businesses/public/{qrCode.code}?type=scan
   → Tìm business theo slug, nếu không có → tìm theo qrcode_generated.code
   → Track scan (business_history + total_scan++)
   → Trả về full profile + deep_link_firebase

3. FE Web hiển thị profile, nút "Mở trong app"

4. POST /api/cards/{id}/generate-deeplink
   → Generate Firebase short link nếu chưa có
   → Trả { deep_link_firebase: "https://inapps.page.link/xxx" }

5. Firebase Dynamic Link:
   ├── Đã có app InCard → Mở thẳng vào app
   └── Chưa có app → Redirect về web URL (afl/ifl/ofl fallback)
```

---

## TODOs còn lại (chưa implement)

| Endpoint | Field | Trạng thái | Mô tả |
|---------|-------|-----------|-------|
| GET `/api/cards`, GET `/api/cards/:id` | `request_status` | ⚠️ Hardcode `"not_requested"` | PHP query `contact_requets` table WHERE user_id + business_id |
| GET `/api/cards/:id` | `approved_at` | ⚠️ Hardcode `null` | PHP lấy từ `contact_requets.created_at` khi status = 'approved' |
| GET `/api/cards/:id` | `is_enable_appoinment` | ⚠️ Hardcode `1` | PHP check user plan/subscription |
| GET `/api/cards/:id` | `connected_id`, `connected_name` | ⚠️ Hardcode `null` | PHP lấy từ contact connection |
| GET `/api/businesses/public/:slug` | `business` object | ⚠️ Raw camelCase | Cần format lại nếu FE cần format giống `/api/cards/:id` |
| POST `/api/cards` | `qrcode_serial` linking | ⚠️ TODO stub | PHP link qrcode_serial vào business khi tạo card |
