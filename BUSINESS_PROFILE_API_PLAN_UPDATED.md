# Plan Updated: Business Card & Profile API — Fix & Complete

**Target source:** `D:\Program Files\InCard-API\CMS_InCard_api` (NestJS)
**Reference source:** `D:\Program Files\InCard-API\incard-biz` (Laravel PHP)
**Database:** Dùng chung MySQL — không migrate schema
**Auth:** JWT Bearer token (`AuthGuard` đã có sẵn)
**Client:** Mobile app (React Native / Flutter) + FE Web riêng (https://incard.biz/{slug})
**Last verified:** 2026-03-03

---

## Mục tiêu của plan này

Fix và hoàn thiện những logic còn thiếu/sai so với PHP gốc:

1. **Response sai** — `profile_url`, `deeplink`, `request_status`, `created_at/updated_at`, `settings` format
2. **Thiếu fields** — `social_links`, `is_my_card`, `tags`, `connected_id`, `connected_name`, `approved_at`, `testimonials_is_enabled`, `banner_img`, `hasPhysicalCard`, `is_enable_appoinment`
3. **Track view/scan** — Logic hiện tại chưa đúng với PHP gốc
4. **deep_link_firebase** — Thiếu endpoint generate và logic lưu DB
5. **created_at/updated_at** — Không được set đúng khi tạo card
6. **`GET /api/businesses/public/:slug`** — Endpoint cho FE web chưa hoàn chỉnh

---

## Quyết định thiết kế đã thống nhất

| Vấn đề | Quyết định |
|---|---|
| `profile_url` format | `GET /cards` và `GET /cards/:id` → có prefix `/profile/`. `POST /cards` và `POST /cards/update/:id` → KHÔNG có `/profile/` prefix (đúng PHP gốc) |
| `deeplink` field | Giống PHP: `deep_link` từ DB (web URL), generate nếu null. KHÔNG phải Firebase link |
| `deep_link_firebase` | Thêm endpoint mới `POST /api/cards/:id/generate-deeplink`. Trả về `{ deep_link_firebase }` |
| `sociallinks` | Chỉ 1 field `sociallinks`, bỏ `social_links` |
| `password`, `enable_password` | Bỏ khỏi response |
| `request_status` | Implement đúng: query `contact_requets` table, trả `'not_requested'|'requested'|'approved'|'rejected'` |
| Track view/scan (web FE) | `GET /api/businesses/public/:slug?type=scan` — có `type=scan` thì track scan, không có thì track view |
| `created_at/updated_at` format | PHP format: `'Y m d H:i:s'` → `'2026 03 03 14:27:14'` |

---

## Danh sách endpoints

### Module 1: Business Cards (đã có, cần fix)

| Method | Endpoint | Guard | Trạng thái |
|---|---|---|---|
| `GET` | `/api/cards` | AuthGuard | Fix response |
| `POST` | `/api/cards` | AuthGuard | Fix response + created_at/updated_at |
| `GET` | `/api/cards/:id` | AuthGuard | Fix response + track logic |
| `POST` | `/api/cards/update/:id` | AuthGuard | Fix response |
| `DELETE` | `/api/cards/:id` | AuthGuard | OK |
| `POST` | `/api/cards/link-card/:id` | AuthGuard | Fix implementation (TODO stub) |
| `POST` | `/api/cards/banner/:id` | AuthGuard | OK |
| `GET` | `/api/check-card/:cardCode` | Public | OK |

### Module 2: Deep Link (MỚI)

| Method | Endpoint | Guard | Mô tả |
|---|---|---|---|
| `POST` | `/api/cards/:id/generate-deeplink` | AuthGuard | Generate + lưu `deep_link_firebase` vào DB |

### Module 3: Public Profile — FE Web (fix)

| Method | Endpoint | Guard | Mô tả |
|---|---|---|---|
| `GET` | `/api/businesses/public/:slug` | Public (OptionalAuth) | Get full profile + track view/scan |

---

## Chi tiết các task cần làm

---

### TASK 1 — Fix `created_at` / `updated_at` không được set khi tạo card

**File:** `src/modules/businesses/businesses.repository.ts`

**Vấn đề:** Khi `businessesRepo.create()` insert DB, `created_at` và `updated_at` có thể không được auto-set vì Knex/TypeORM không tự set như Eloquent.

**Fix:**
- Khi insert, thêm `created_at: new Date()` và `updated_at: new Date()` vào data
- Khi update, thêm `updated_at: new Date()` vào data

**Format khi trả về response:**
```typescript
// PHP format: 'Y m d H:i:s' → '2026 03 03 14:27:14'
function formatPhpDate(date: Date | string | null): string | null {
  if (!date) return null;
  const d = new Date(date);
  const Y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  const H = String(d.getHours()).padStart(2, '0');
  const i = String(d.getMinutes()).padStart(2, '0');
  const s = String(d.getSeconds()).padStart(2, '0');
  return `${Y} ${m} ${day} ${H}:${i}:${s}`;
}
```

---

### TASK 2 — Fix response của `GET /api/cards` (index)

**File:** `src/modules/businesses/businesses.service.ts` — method `getAll()`

**PHP source:** `CardController::index()` lines 205-245

**Response fields đúng (theo PHP + response thực tế của user):**

```typescript
{
  id: number,
  slug: string,
  first_name: string,          // business.title
  last_name: string,           // business.last_name
  email: string | null,
  phone: string | null,
  title: string | null,        // business.designation
  company: string | null,      // business.sub_title
  bio: string | null,
  industries: array,
  services: array,
  need_services: array,
  sociallinks: array,          // CHỈ 1 field này, bỏ social_links
  testimonials: array,
  // BỎ: password, enable_password
  logo: string,
  created_at: string,          // format: 'YYYY MM DD HH:mm:ss'
  updated_at: string,
  total_view: number,
  total_scan: number,
  total_appointment: number,
  is_owner: boolean,
  request_status: string,      // 'not_requested'|'requested'|'approved'|'rejected'
  profile_url: string,         // url('profile/' + slug) — CÓ /profile/ prefix
  need_services: array,        // (đã có ở trên, đảm bảo không duplicate)
  profile_qr: string,
  contact_qr: string,
  product_services: array,
  media: array,
  settings: object,            // raw JSON object từ DB (không stringify lại)
  is_my_card: boolean,         // business.owner_id == user.id
  deeplink: string | null,     // business.deep_link từ DB (web URL)
  profiles_type: string | null,
  main_service: string | null,
  key_strength: string | null,
  looking_for: any,
  collaboration: any,
}
```

**Các fix cần làm:**
1. `request_status` → query `contact_requets` table thay vì trả `null`
2. `created_at` / `updated_at` → format `'Y m d H:i:s'`
3. `deeplink` → trả `business.deep_link` từ DB (generate nếu null, xem TASK 6)
4. `settings` → trả raw object (PHP trả `$business->settings` không encode lại)
5. Bỏ `banner_img`, `tags`, `owner_id` (không có trong PHP index response)
6. Bỏ `password`, `enable_password` (quyết định của user)

---

### TASK 3 — Fix response của `GET /api/cards/:id` (detail)

**File:** `src/modules/businesses/businesses.service.ts` — method `getById()`

**PHP source:** `CardController::detail()` lines 537-586

**Response fields đúng:**

```typescript
{
  id: number,
  slug: string,
  first_name: string,
  last_name: string,
  email: string | null,
  phone: string | null,
  title: string | null,
  company: string | null,
  bio: string | null,
  industries: array,
  services: array,
  need_services: array,
  sociallinks: array,
  // BỎ: social_links
  testimonials: array,
  testimonials_is_enabled: boolean | number,  // THÊM — từ testimonials.is_enabled
  // BỎ: password, enable_password
  logo: string,
  created_at: string,          // format: 'YYYY MM DD HH:mm:ss'
  updated_at: string,
  total_view: number,
  total_scan: number,
  total_appointment: number,
  profile_qr: string,
  contact_qr: string,
  deeplink: string | null,     // business.deep_link từ DB
  is_owner: boolean,
  request_status: string,      // query thực tế từ contact_requets
  approved_at: string | null,  // THÊM — Carbon UTC timestamp nếu approved
  profile_url: string,         // url('profile/' + slug) — CÓ /profile/ prefix
  need_services: array,
  hasPhysicalCard: boolean,    // THÊM — !!qrcode record
  is_enable_appoinment: number, // THÊM — 1 nếu owner có plan hỗ trợ appointment
  banner_img: string | null,   // THÊM
  product_services: array,
  media: array,
  settings: object,
  owner_id: number,            // THÊM
  tags: array,                 // THÊM — [] (empty array, tính năng tags chưa implement)
  connected_id: number | null, // THÊM — contact connection
  connected_name: string | null, // THÊM
  profiles_type: string | null,
  main_service: string | null,
  key_strength: string | null,
  looking_for: any,
  collaboration: any,
}
```

**Các fix cần làm:**
1. Thêm `testimonials_is_enabled`
2. Thêm `approved_at` (query từ `contact_requets`)
3. Thêm `hasPhysicalCard` (!!qrcodeRepo.findByBusinessId(id))
4. Thêm `is_enable_appoinment` (check user plan)
5. Thêm `banner_img`
6. Thêm `owner_id`, `tags`, `connected_id`, `connected_name`
7. Fix `request_status` → query thực tế
8. Fix `created_at`/`updated_at` format
9. Fix `deeplink` → `business.deep_link` từ DB
10. Fix `settings` → raw object

---

### TASK 4 — Fix track view/scan trong `GET /api/cards/:id`

**File:** `src/modules/businesses/businesses.service.ts` — method `getById()`

**PHP logic (CardController::detail() lines 253-420):**

```php
// PHP luôn track VIEW khi xem detail
BusinessHistory::create(['type' => 'view', ...]);

// PHP track SCAN chỉ khi có query param fromScan
if($request->fromScan) {
    BusinessHistory::create(['type' => 'scan', ...]);
}

// PHP KHÔNG recount từ history — dùng business.total_view và total_scan trực tiếp từ DB
// total_view và total_scan được increment trong PHP theo cách khác
```

**Fix trong NestJS:**
- Bỏ việc recount toàn bộ history (tốn query)
- Thay bằng: `UPDATE businesses SET total_view = total_view + 1` khi view
- Khi fromScan: `UPDATE businesses SET total_scan = total_scan + 1`
- Ghi BusinessHistory record như hiện tại

```typescript
// Sau khi ghi history:
await this.businessesRepo.incrementView(business.id);    // UPDATE SET total_view = total_view + 1
if (fromScan) {
  await this.businessesRepo.incrementScan(business.id); // UPDATE SET total_scan = total_scan + 1
}
// Đọc lại business để lấy total_view, total_scan mới nhất
```

---

### TASK 5 — Fix response của `POST /api/cards` (create) và `POST /api/cards/update/:id` (update)

**PHP source:**
- `add()` → `profile_url = url($business->slug)` (KHÔNG có `/profile/` prefix)
- `update()` → `profile_url = url($business->slug)` (KHÔNG có `/profile/` prefix)

**Response fields cho create (POST /api/cards) — theo PHP add() lines 1139-1186:**

```typescript
{
  id: number,
  slug: string,
  first_name: string,
  last_name: string,
  email: string | null,
  phone: string | null,
  title: string | null,
  company: string | null,
  bio: string | null,
  industries: array,
  services: array,
  need_services: array,
  sociallinks: array,
  testimonials: [],
  // BỎ: password, enable_password (quyết định của user)
  logo: string,
  created_at: string,          // format: 'YYYY MM DD HH:mm:ss'
  updated_at: string,
  total_view: 0,
  total_scan: 0,
  total_appointment: 0,
  is_owner: true,
  request_status: 'not_requested',
  profile_url: string,         // url(slug) — KHÔNG có /profile/ prefix
  profiles_type: string,
  main_service: string | null,
  key_strength: string | null,
  looking_for: any,
  collaboration: any,
  product_services: [],
  media: [],
  // KHÔNG có: profile_qr, contact_qr, deeplink, banner_img, tags, owner_id, is_my_card
}
```

**Response fields cho update (POST /api/cards/update/:id) — theo PHP update() lines 1619-1669:**

```typescript
{
  // Giống create nhưng thêm:
  settings: object,
  product_services: array,     // từ DB (không phải [])
  media: array,                // từ DB
  // KHÔNG có: profile_qr, contact_qr, deeplink, banner_img, tags, owner_id, is_my_card
}
```

---

### TASK 6 — Implement `deeplink` (deep_link) generation logic

**PHP logic (CardController::index() và detail() lines 123-135, 352-380):**

Khi `business.deep_link` là null hoặc QR file chưa tồn tại:
1. Nếu business có `codeGenerated` (physical card): `deep_link = url('profile/' + codeGenerated.code)`
2. Nếu không: `deep_link = url('profile/' + business.slug)`
3. Lưu `deep_link` vào DB

**Fix trong NestJS:**
- Trong `getAll()` và `getById()`: nếu `business.deep_link` null → auto-generate và lưu DB
- Generate logic:
  ```typescript
  const qrCode = await this.qrcodeRepo.findByBusinessId(business.id);
  const deepLink = qrCode
    ? `${baseUrl}/profile/${qrCode.code}`
    : `${baseUrl}/profile/${business.slug}`;
  await this.businessesRepo.update(business.id, { deepLink });
  ```
- Trả `deeplink: business.deep_link` trong response

---

### TASK 7 — Implement `request_status` và `approved_at`

**PHP source:** `Business::request_status()` và `get_approved_at()`

**Table:** `contact_requets` (typo từ PHP, giữ nguyên tên table)

**Possible values:** `'not_requested'`, `'requested'`, `'approved'`, `'rejected'`

**Logic:**
```typescript
async getRequestStatus(userId: number, businessId: number): Promise<string> {
  // SELECT * FROM contact_requets
  // WHERE user_id = userId AND business_id = businessId
  // AND status NOT IN ('recent', 'disconnected')
  const contact = await this.contactRequestRepo.findByUserAndBusiness(userId, businessId);
  return contact ? contact.status : 'not_requested';
}

async getApprovedAt(userId: number, businessId: number): Promise<string | null> {
  const contact = await this.contactRequestRepo.findByUserAndBusiness(userId, businessId);
  return (contact?.status === 'approved') ? contact.created_at : null;
}
```

**Files cần tạo/update:**
- Tạo `src/modules/businesses/contact-request.repository.ts`
- Inject vào `BusinessesService`

---

### TASK 8 — Endpoint mới: `POST /api/cards/:id/generate-deeplink`

**Mục đích:** FE web gọi để generate Firebase Dynamic Link cho 1 card.

**PHP reference:** `getDynamicURLFromFirebase()` trong `app/Helpers/common.php`

**Logic:**
1. Check `business.deep_link_firebase` đã có chưa → nếu có thì trả về luôn
2. Nếu chưa: call Firebase API để tạo short link
3. Lưu vào `business.deep_link_firebase`
4. Trả về `{ deep_link_firebase: string }`

**Firebase API call:**
```typescript
// POST https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key={API_KEY}
// Body:
{
  "longDynamicLink": "https://inapps.page.link/?link={profileUrl}&apn=net.inapps.incard{env}&ibi=net.inapps.incard{env}&afl={profileUrl}&ifl={profileUrl}&ofl={profileUrl}"
}
// Response: { "shortLink": "https://inapps.page.link/xxx" }
```

**Environment suffix:**
- `staging` → `.staging`
- `development` → `.development`
- `production` → `` (empty)

**Controller:**
```typescript
// businesses.controller.ts
@Post(':id/generate-deeplink')
generateDeeplink(@Param('id') id: string, @GetUser() user: any) {
  return this.businessesService.generateDeepLink(+id, user.id);
}
```

**Response:**
```json
{
  "status": true,
  "message": "",
  "data": {
    "deep_link_firebase": "https://inapps.page.link/abc123"
  }
}
```

**Config cần thêm:**
- `FIREBASE_API_KEY` trong `.env`
- Service `FirebaseDeepLinkService` hoặc helper function trong businesses.service.ts

---

### TASK 9 — Fix `GET /api/businesses/public/:slug` cho FE Web

**PHP reference:** `BusinessController::getcard()` (web.php routes)

**Endpoint:** `GET /api/businesses/public/:slug?type=scan`

**Logic:**
1. Tìm business theo slug
2. Nếu không tìm thấy → tìm theo `qrcode_generated.code` (đây là scan từ QR physical card)
3. Track history:
   - `?type=scan` → ghi `type = 'scan'`
   - Không có type → ghi `type = 'view'`
4. Increment `total_view` hoặc `total_scan` trong businesses table
5. Trả full business data + `deep_link_firebase`

**Controller (update):**
```typescript
@Get('public/:slug')
@Public()
@UseGuards(OptionalAuthGuard)
getPublicProfile(
  @Param('slug') slug: string,
  @Query('type') type: string,        // THÊM query param
  @Req() req: any,
  @GetUser() user?: any,
) {
  const ip = req.headers['x-forwarded-for'] || req.ip || '';
  const fromScan = type === 'scan';
  return this.businessesService.getPublicProfile(slug, user?.id, ip, fromScan);
}
```

**Response (update)** — thêm `deep_link_firebase`:
```json
{
  "status": true,
  "data": {
    "business": { ...full business object },
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

---

### TASK 10 — Fix `POST /api/cards/link-card/:id`

**PHP source:** `CardController::linkCard()` lines 1671-1702

**Hiện trạng:** NestJS có stub `TODO` chưa implement.

**PHP logic:**
```php
$qrCodeGen = QrcodeGenerated::where('code', $cardCode)->first();
// Assign business to QR code:
$qrCodeGen->business_id = $business->id;
$qrCodeGen->user_id = $business->owner_id;
$qrCodeGen->save();

// Reset deep_link để regenerate
$business->deep_link = null;
$business->save();
```

**Fix trong NestJS:**
```typescript
async linkCard(id: number, userId: number, body: any) {
  const qr = await this.qrcodeRepo.findByCode(body.card_code);
  if (!qr) return ResponseHelper.error('Mã thẻ không tồn tại');

  // Update qrcode_generated
  await this.qrcodeRepo.update(qr.id, { businessId: id, userId: business.ownerId });

  // Reset deep_link → sẽ được regenerate lần sau
  await this.businessesRepo.update(id, { deepLink: null });

  return ResponseHelper.success(qr, '');
}
```

---

## File changes summary

| File | Action | Tasks |
|---|---|---|
| `src/modules/businesses/businesses.service.ts` | Update | 2, 3, 4, 5, 6, 7, 8, 9, 10 |
| `src/modules/businesses/businesses.controller.ts` | Update | 8, 9 |
| `src/modules/businesses/businesses.repository.ts` | Update | 1, 4, 6 |
| `src/modules/businesses/contact-request.repository.ts` | Tạo mới | 7 |
| `src/modules/businesses/businesses.module.ts` | Update | 7, 8 |
| `.env` | Update | 8 |
| `src/modules/businesses/dto/` | Update nếu cần | 5 |

---

## Luồng đầy đủ: QR → Web → App

```
[User quét QR code]
       ↓
QR embed URL: https://stage.incard.biz/profile/{slug}?type=scan
       ↓
GET /api/businesses/public/{slug}?type=scan
  → track scan (BusinessHistory + total_scan++)
  → trả full profile data + deep_link_firebase
       ↓
FE web hiển thị profile, nút "Go to app"
       ↓ (user bấm nút hoặc FE auto)
POST /api/cards/:id/generate-deeplink
  → generate Firebase short link nếu chưa có
  → trả { deep_link_firebase: "https://inapps.page.link/xxx" }
       ↓
Firebase Dynamic Link kiểm tra thiết bị:
  ├── Có app InCard → Mở thẳng vào app
  └── Chưa có app → Redirect về web URL (afl/ifl/ofl fallback)
```

---

## Các điểm cần lưu ý khi implement

1. **Table name typo**: `contact_requets` (PHP typo, giữ nguyên)
2. **`settings` field**: PHP trả raw JSON object, KHÔNG phải array. NestJS hiện đang parse và merge với defaults → cần kiểm tra lại format mà app mobile expect
3. **QR file generation**: PHP generate file QR PNG thực tế. NestJS hiện chỉ trả URL string. Cần quyết định có generate file QR thực tế không (không nằm trong scope plan này)
4. **`is_enable_appoinment`**: PHP check từ user plan/subscription. NestJS có thể tạm trả `1` (mặc định enable)
5. **`tags`**: PHP feature chưa implement, trả `[]`. NestJS cũng trả `[]`
6. **`connected_id`, `connected_name`**: PHP lấy từ contact connection. NestJS tạm trả `null`
7. **Firebase API Key**: Không hardcode trong code, phải lấy từ `.env`
8. **`deep_link_firebase`**: Chỉ generate khi được gọi qua endpoint mới, không auto-generate trong create/update card
