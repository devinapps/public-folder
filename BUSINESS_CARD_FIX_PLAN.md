# Business Card API — Fix & Update Plan

**Ngày tạo:** 2026-03-04
**Cập nhật:** 2026-03-04 (bổ sung CamelCase/field mapping audit)
**Mục tiêu:** Sửa các sai lệch giữa PHP (incard-biz) và NestJS (CMS_InCard_api) cho Business/Card API và Appointment API.
**Phạm vi:** Chỉ báo cáo + fix các issue. Không thêm feature ngoài danh sách.

---

## Tổng quan Issues

| Mức độ | # | Vị trí | Vấn đề | Trạng thái |
|--------|---|--------|--------|-----------|
| 🔴 Critical | 1 | `POST /api/check-card/:cardCode` | HTTP method sai: PHP dùng POST, NestJS dùng GET | ✅ Fixed |
| 🔴 Critical | 2 | `checkSerialNumberOfCard` logic | statusCode ý nghĩa hoàn toàn khác PHP | ✅ Fixed |
| 🔴 Critical | 13 | `industries` / `services` response | PHP trả `[{id, name}]` objects, NestJS trả raw JSON từ DB (string array nếu lưu sai) | ✅ Fixed |
| 🔴 Critical | 14 | `settings` response | PHP trả raw string, NestJS trả parsed object — giữ NestJS, docs updated | ✅ Fixed |
| 🔴 Critical | 15 | `GET /api/businesses/public/:slug` — `business` object | Trả raw Drizzle camelCase thay vì snake_case PHP-compatible | ✅ Fixed |
| 🟠 High | 3 | `DELETE /api/cards/:id` | Thiếu xóa `contact_requests` và thiếu gọi webhook | ✅ Fixed |
| 🟠 High | 4 | `POST /api/cards` (create) | Thiếu xử lý `qrcode_serial` linking khi tạo card | ✅ Fixed |
| 🟠 High | 5 | `POST /api/cards/update/:id` | Thiếu gọi webhook `callCardWebhook` sau update | ✅ Fixed |
| 🟠 High | 16 | Tất cả endpoints | Thiếu `social_links` (PHP có 2 fields: `sociallinks` + `social_links`) | ✅ Fixed |
| 🟠 High | 17 | `GET /api/cards`, `GET /api/cards/:id` | Thiếu `password` và `enable_password` trong response | ✅ Fixed |
| 🟡 Medium | 6 | `POST /api/cards/link-card/:id` | Response message trống, PHP trả `"Liên kết thành công."` | ✅ Fixed |
| ⚪ N/A | 7 | `industries` / `services` DB format | Đã giải quyết trong Issue 13 — PHP lưu `{"0":"name"}` associative array | ✅ Merge vào 13 |
| 🟡 Medium | 18 | `GET /api/cards` | Thiếu filter `?profiles_type=` (PHP có check) | ✅ Fixed |
| 🟡 Medium | 19 | `GET /api/cards/:id` | `total_view`/`total_scan` PHP đếm lại từ `history` table, NestJS dùng counter column | ⬜ Khác biệt |
| 🟡 Medium | 20 | `GET /api/cards/:id` | PHP tạo `contact_request` type=`recent` khi `fromScan`, NestJS không có | ✅ Fixed |
| 🟢 Low | 8 | `POST /api/cards` response | Issue 8 đã loại — không phải bug (xem phân tích bên dưới) | ✅ Không cần fix |
| 🟢 Low | 9 | `POST /api/cards/update/:id` | Thiếu clear `matching_data = null` sau update | ✅ Fixed |
| 🟢 Low | 10 | Appointment messages | PHP có dấu tiếng Việt, NestJS không dấu | ✅ Fixed |
| 🟢 Low | 21 | `POST /api/cards/link-card/:id` | Thiếu check QR đã linked (`business_id != null`) trước khi link | ✅ Fixed |
| 🟢 Low | 22 | `POST /api/cards/banner/:id` | Response message: PHP `"Cập nhật thành công"`, NestJS `''` | ✅ Fixed |
| 📋 New Feature | 11 | `POST /api/cards/:id/generate-deeplink` | Feature mới — PHP chỉ có artisan command | ✅ Đã có |
| 📋 New Feature | 12 | `GET /api/businesses/public/:slug` | Feature mới — PHP dùng web route Blade, NestJS expose API | ✅ Đã có |

---

## Issue 1 — 🔴 HTTP Method sai: `check-card`

### Phân tích
- **PHP** (`routes/api.php` line 47): `Route::post('check-card/{cardCode}', 'API\CardController@checkSerialNumberOfCard')`
- **NestJS**: `@Get(':cardCode')` trong `CheckCardController`
- **Docs** (`BUSINESS_API_REFERENCE.md`): Ghi là `GET` → **Docs sai so với PHP**

### Quyết định cần làm rõ
Mobile app hiện đang gọi `POST` (theo PHP). Nếu NestJS dùng `GET`, mobile app sẽ nhận 404.

### Fix
**File:** `src/modules/businesses/businesses.controller.ts`
Đổi `@Get(':cardCode')` thành `@Post(':cardCode')` trong `CheckCardController`.

```typescript
// BEFORE
@Get(':cardCode')
checkSerialNumberOfCard(...)

// AFTER
@Post(':cardCode')
checkSerialNumberOfCard(...)
```

**Cập nhật docs** `BUSINESS_API_REFERENCE.md` section 9: đổi `GET` → `POST`.

---

## Issue 2 — 🔴 `checkSerialNumberOfCard` Logic sai

### Phân tích — PHP vs NestJS

**Mục đích:** Mobile app quét QR code vật lý → hỏi trạng thái mã NFC → quyết định flow tiếp theo.

#### PHP Logic (đúng)
```
Input: cardCode (NFC serial)

1. Tìm QrcodeGenerated WHERE code = cardCode
2. Nếu KHÔNG tìm thấy qrCode:
   - Tìm Business WHERE slug = cardCode
   - Nếu có business → statusCode=1 (Có profile)
   - → Không xử lý thêm (statusCode=6 default)

3. Nếu TÌM THẤY qrCode:
   a. qrCode.business_id != null && qrCode.user_id != null
      → statusCode=1, profileId=qrCode.business_id ("Có profile")

   b. qrCode.business_id == null && qrCode.user_id == null
      - Tìm Business WHERE slug = cardCode
      - Nếu có business → statusCode=1, profileId=business.id
      - Nếu không       → statusCode=2 ("Chưa có profile & chưa có account")

   c. Một trong hai là null (partial link)
      - Tìm Business WHERE slug = cardCode
      - Nếu có business → statusCode=1

   d. Sau các bước trên, nếu user đang đăng nhập:
      - qrCode.user_id tồn tại && user_id != currentUser.id
        → statusCode=3 ("Có account, chưa có profile, không phải owner")
      - qrCode.user_id tồn tại && user_id == currentUser.id
        → statusCode=4 ("Có account, chưa có profile, là owner")

   e. Nếu KHÔNG đăng nhập:
      - qrCode.user_id tồn tại && qrCode.business_id == null
        → statusCode=5 ("Có account, chưa có profile")
```

#### NestJS Logic (hiện tại — đơn giản hơn nhưng khác PHP)
```
1. Không tìm thấy qrCode → statusCode=4 (Not Found)
2. qrCode.businessId == null → statusCode=1 (Available)
3. Business không tồn tại → statusCode=1 (Available)
4. Business.ownerId == userId → statusCode=6 (Already Linked)
5. Còn lại → statusCode=2 (In Use)
```

### Mapping PHP → NestJS (đề xuất)

| PHP statusCode | PHP statusText | NestJS statusCode mới | NestJS statusText |
|---|---|---|---|
| 1 | Có profile | 1 | Has Profile |
| 2 | Chưa có profile & chưa có account | 2 | Card Available |
| 3 | Có account, không phải owner | 3 | Owned By Another |
| 4 | Có account, là owner, chưa tạo profile | 4 | Owner No Profile |
| 5 | Chưa đăng nhập, có account | 5 | Has Account No Profile |
| 6 | Default/unknown | 6 | Unknown |

### Fix
**File:** `src/modules/businesses/businesses.service.ts`
Rewrite `checkSerialNumberOfCard()` theo đúng logic PHP.

**Logic mới:**
```typescript
async checkSerialNumberOfCard(cardCode: string, userId: number) {
  const qrCode = await this.qrcodeRepo.findByCode(cardCode);

  let statusCode = 6;
  let profileId: number | null = null;
  let statusText = '';

  if (qrCode) {
    // Case a: both business_id and user_id set → has profile
    if (qrCode.businessId && qrCode.userId) {
      statusCode = 1;
      profileId = Number(qrCode.businessId);
      statusText = 'Has Profile';
    }
    // Case b: neither set → check by slug
    else if (!qrCode.businessId && !qrCode.userId) {
      const biz = await this.businessesRepo.findBySlug(cardCode);
      if (biz) {
        statusCode = 1;
        profileId = biz.id;
        statusText = 'Has Profile';
      } else {
        statusCode = 2;
        statusText = 'Card Available';
      }
    }
    // Case c: partial link → check by slug
    else if (!qrCode.businessId || !qrCode.userId) {
      const biz = await this.businessesRepo.findBySlug(cardCode);
      if (biz) {
        statusCode = 1;
        profileId = biz.id;
        statusText = 'Has Profile';
      }
    }

    // Case d: authenticated user — refine status
    if (userId) {
      if (!qrCode.businessId && qrCode.userId && Number(qrCode.userId) !== userId) {
        statusCode = 3;
        statusText = 'Owned By Another';
      } else if (!qrCode.businessId && qrCode.userId && Number(qrCode.userId) === userId) {
        statusCode = 4;
        statusText = 'Owner No Profile';
      }
    } else {
      // Case e: not authenticated
      if (qrCode.userId && !qrCode.businessId) {
        statusCode = 5;
        statusText = 'Has Account No Profile';
      }
    }
  } else {
    // qrCode not found — check if slug matches a business
    const biz = await this.businessesRepo.findBySlug(cardCode);
    if (biz) {
      statusCode = 1;
      profileId = biz.id;
      statusText = 'Has Profile';
    }
  }

  return ResponseHelper.success({ statusCode, profileId, statusText }, '');
}
```

**`findBySlug` đã tồn tại** trong `BusinessesRepository` (line 35) — không cần thêm.

**Cập nhật docs** `BUSINESS_API_REFERENCE.md` section 9: cập nhật bảng statusCode.

---

## Issue 3 — 🟠 `DELETE /api/cards/:id` thiếu side effects

### Phân tích
PHP `delete()` thực hiện:
1. ✅ Xóa business
2. ✅ Xóa social
3. ✅ Unlink qrcode_generated (set business_id = null)
4. ❌ **Thiếu:** `ContactRequest::where('business_id', $id)->delete()`
5. ❌ **Thiếu:** Gọi `callCardWebhook($cardId, 'delete')`

### Fix
**File:** `src/modules/businesses/businesses.service.ts` — method `delete()`

Sau khi unlink QR code, thêm:
```typescript
// 1. Xóa contact_requests liên quan
await this.db
  .delete(contactRequests)
  .where(eq(contactRequests.businessId, id));

// 2. Gọi webhook (fire and forget)
this.callCardWebhook(id, 'delete');
```

**Cần thêm `callCardWebhook` helper** (giống PHP):
```typescript
private async callCardWebhook(cardId: number, type: 'upsert' | 'delete') {
  const webhookUrl = this.configService.get('CARD_WEBHOOK_URL');
  if (!webhookUrl) {
    this.logger.warn('CARD_WEBHOOK_URL not configured');
    return;
  }
  try {
    await fetch(webhookUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ card_id: cardId, type }),
      signal: AbortSignal.timeout(10000),
    });
  } catch (e) {
    this.logger.error(`Card webhook error: ${e.message}`);
  }
}
```

**ENV cần có:** `CARD_WEBHOOK_URL=...`

---

## Issue 4 — 🟠 `POST /api/cards` thiếu `qrcode_serial` linking

### Phân tích
PHP `add()` (lines 1055-1071): 2 luồng xử lý NFC card:

1. **Nếu có `qrcode_serial`**: tìm QrcodeGenerated theo code rồi link (PHP KHÔNG kiểm tra `business_id` trước, link thẳng):
   ```php
   if($request->qrcode_serial) {
       $qrcode = QrcodeGenerated::where('code', $request->qrcode_serial)->first();
       if($qrcode) {
           $qrcode->user_id = $user->id;
           $qrcode->business_id = $business->id;
           $qrcode->save();
       }
   }
   ```

2. **Fallback — không có `qrcode_serial`**: nếu user có thẻ vật lý chưa link, tự động link vào business mới tạo:
   ```php
   else {
       $physicalCard = $user->checkHasPhysicalCard();
       if($physicalCard) {
           if(!$user->checkHasLinkedToPhysicalCard()) {
               $physicalCard->business_id = $business->id;
               $physicalCard->save();
           }
       }
   }
   ```

NestJS hiện tại: nhận `qrcode_serial` trong DTO nhưng không xử lý (TODO stub). Không có fallback auto-link.

### Fix
**File:** `src/modules/businesses/businesses.service.ts` — method `create()`

Sau khi tạo business, thêm (chú ý: PHP link ngay kể cả khi QR đã có `businessId`):
```typescript
if (dto.qrcode_serial) {
  const qr = await this.qrcodeRepo.findByCode(dto.qrcode_serial);
  if (qr) {
    // PHP links directly without checking existing businessId
    await this.qrcodeRepo.linkToBusinessAndUser(qr.id, business.id, userId);
  }
} else {
  // Fallback: auto-link physical card if user has one and hasn't linked yet
  const physicalCard = await this.qrcodeRepo.findPhysicalCardByUser(userId);
  if (physicalCard) {
    const alreadyLinked = await this.qrcodeRepo.hasUserLinkedPhysicalCard(userId);
    if (!alreadyLinked) {
      await this.qrcodeRepo.update(physicalCard.id, { businessId: business.id });
    }
  }
}
```

**Cần thêm methods** vào `QrcodeRepository`:
- `findPhysicalCardByUser(userId)` — maps to PHP `checkHasPhysicalCard()`
- `hasUserLinkedPhysicalCard(userId)` — maps to PHP `checkHasLinkedToPhysicalCard()`

---

## Issue 5 — 🟠 `POST /api/cards/update/:id` thiếu webhook call

### Phân tích
PHP `update()` gọi `callCardWebhook($id, 'upsert')` sau khi save.
PHP `add()` cũng gọi `callCardWebhook($id, 'upsert')` sau khi tạo.
NestJS không có.

### Fix
**File:** `src/modules/businesses/businesses.service.ts`

1. Thêm `callCardWebhook` helper (xem Issue 3).
2. Trong `update()` — trước `return`: thêm `this.callCardWebhook(id, 'upsert');`
3. Trong `create()` — trước `return`: thêm `this.callCardWebhook(business.id, 'upsert');`

---

## Issue 6 — 🟡 `POST /api/cards/link-card/:id` response message

### Phân tích
- PHP: `return $this->sendResponse($qrCode, "Liên kết thành công.")`
- NestJS: `return ResponseHelper.success(qr, '')` → message rỗng

### Fix
**File:** `src/modules/businesses/businesses.service.ts` — method `linkCard()`

```typescript
// BEFORE
return ResponseHelper.success(qr, '');

// AFTER
return ResponseHelper.success(qr, 'Liên kết thành công.');
```

---

## Issue 7 — ✅ MERGED vào Issue 13

### Kết luận
PHP **lưu DB** dạng associative array `{"0":"Tech","1":"Finance"}` (key=index, value=name), **không phải** `[{id,name}]`.

PHP **luôn transform** khi response: `foreach($key => $industry)` → `[{id: $key, name: $industry}]`.

→ Vấn đề này đã được phân tích đầy đủ trong Issue 13 bên dưới. Issue 7 không cần xử lý riêng.

---

## Issue 8 — 🟡 `POST /api/cards` (create) thiếu `settings` field

### Phân tích
PHP `add()` response **không có** `settings` field.
PHP `index()` và `detail()` response **có** `settings`.
NestJS `create()` response hiện tại cũng không có `settings` → **đúng với PHP**.

→ **Không phải lỗi.** Xóa khỏi issue list.

---

## Issue 9 — 🟢 `POST /api/cards/update/:id` thiếu clear `matching_data`

### Phân tích
PHP `update()` thực hiện:
```php
$business->matching_data = null;
$business->save();
```
Đây để reset vector embedding khi profile thay đổi.

### Fix
**File:** `src/modules/businesses/businesses.service.ts` — method `update()`

Thêm vào `updateData`:
```typescript
matchingData: null,
```

> **Lưu ý:** Chỉ cần thiết nếu NestJS project có AI matching feature. Nếu không, có thể bỏ qua.

---

## Issue 10 — 🟢 Appointment response messages

### Phân tích
| Action | PHP | NestJS |
|--------|-----|--------|
| add | `"Tạo lịch hẹn thàng công!"` *(có typo "thàng")* | `"Tao lich hen thanh cong!"` |
| update/accept/reject | `"Cập nhật lịch hẹn thàng công!"` | `"Cap nhat lich hen thanh cong!"` |
| delete | `"Xóa lịch hẹn thàng công!"` | `"Xoa lich hen thanh cong!"` |

PHP có dấu nhưng có typo (`thàng` thay vì `thành`). NestJS không có dấu nhưng chính xác.

### Fix (optional)
Nếu mobile app không compare string message này, không cần fix.
Nếu cần đồng nhất, chuẩn hóa NestJS theo PHP nhưng sửa typo:

**File:** `src/modules/appointments/appointments.service.ts`
```typescript
// BEFORE
return ResponseHelper.success({ appointment: ... }, 'Tao lich hen thanh cong!');

// AFTER
return ResponseHelper.success({ appointment: ... }, 'Tạo lịch hẹn thành công!');
```

---

## Issue 13 — 🔴 `industries` / `services` response format sai

### Phân tích — PHP source thực tế (lines 92-122)

PHP đọc `$business->category` (lưu dạng `{"0":"Tech","1":"Finance"}` — associative array key=index, value=name), rồi transform ra:
```php
foreach($_industries as $key => $industry) {
    array_push($industries, ['id' => $key, 'name' => $industry]);
}
// → [{"id": 0, "name": "Tech"}, {"id": 1, "name": "Finance"}]
```

**NestJS** lưu bằng `resolveArray()` → `JSON.stringify(array)`, rồi đọc lại bằng `tryParseJson()`:
- Nếu client gửi `["Tech","Finance"]` → DB lưu `["Tech","Finance"]` → NestJS trả `["Tech","Finance"]`
- Nếu client gửi `[{"id":0,"name":"Tech"}]` → DB lưu `[{"id":0,"name":"Tech"}]` → NestJS trả `[{"id":0,"name":"Tech"}]`

→ **PHP luôn trả `[{id, name}]` dù DB lưu gì. NestJS trả nguyên trạng DB.**

### Fix
**File:** `src/modules/businesses/businesses.service.ts`

Thêm helper `formatIndustryArray()`:
```typescript
private formatIndustryArray(value: string | null | undefined): Array<{id: number|string, name: string}> {
  const parsed = this.tryParseJson(value);
  if (!parsed || !Array.isArray(parsed)) return [];
  // Already [{id, name}] format
  if (parsed.length > 0 && typeof parsed[0] === 'object' && 'name' in parsed[0]) return parsed;
  // String array → convert to [{id, name}]
  return parsed.map((name: string, idx: number) => ({ id: idx, name: String(name) }));
}
```

Thay thế toàn bộ `this.tryParseJson(b.category) ?? []` bằng `this.formatIndustryArray(b.category)` cho cả `industries`, `services`, `need_services` trong tất cả response methods (`getAll`, `getById`, `create`, `update`).

---

## Issue 14 — 🔴 `settings` response format sai

### Phân tích
- **PHP** (`index`, `detail`, `update` — lines 237, 576, ~1500): `'settings' => $business->settings` → trả **raw JSON string** từ DB (ví dụ: `'{"phone_enable":1}'`)
- **NestJS** `parseSettings()`: parse JSON rồi merge với defaults → trả **JavaScript object** `{phone_enable: 1, zalo_enable: 1, whatsapp_enable: 1}`

Nếu mobile app expect raw string → sẽ parse fail khi nhận object từ NestJS.
Nếu mobile app expect object → NestJS đúng, PHP sai.

### Quyết định
PHP trả raw string là **không tốt** (client phải tự parse). NestJS trả object là đúng hơn về mặt API design.
→ **Giữ nguyên NestJS behavior** (trả object) nhưng **ghi rõ vào docs** đây là cải tiến so với PHP.

**Cập nhật docs** `BUSINESS_API_REFERENCE.md`:
```
settings: object (NestJS parse sẵn — PHP trả raw string)
```

---

## Issue 15 — 🔴 `GET /api/businesses/public/:slug` — `business` object dạng camelCase

### Phân tích
NestJS `getPublicProfile()` trả:
```typescript
return ResponseHelper.success({
  business,   // ← raw Drizzle object: {id, slug, title, lastName, designation, subTitle, ...}
  contactInfo: ...,
  ...
}, 'Lấy profile thành công');
```

Drizzle trả object với camelCase keys: `lastName`, `subTitle`, `designation`, `ownerId`, `createdBy`, `totalView`, `totalScan`, `deepLink`, `deepLinkFirebase`, `profilesType`, `mainService`, `keyStrength`, `lookingFor`, `cardTheme`, `themeColor`, `createdAt`, `updatedAt`, ...

PHP `BusinessController@getcard` trả snake_case: `last_name`, `sub_title`, `designation`, `owner_id`, `created_by`, `total_view`, `total_scan`, `deep_link`, `deep_link_firebase`, `profiles_type`, `main_service`, `key_strength`, `looking_for`, `card_theme`, `theme_color`, `created_at`, `updated_at`...

### Danh sách đầy đủ field cần map (camelCase → snake_case)

| Drizzle camelCase | PHP snake_case |
|---|---|
| `lastName` | `last_name` |
| `subTitle` | `sub_title` |
| `designation` | `designation` ✅ (giống) |
| `ownerId` | `owner_id` |
| `createdBy` | `created_by` |
| `ownerIds` | `owner_ids` |
| `totalView` | `total_view` |
| `totalScan` | `total_scan` |
| `totalAppointment` | `total_appointment` |
| `deepLink` | `deep_link` |
| `deepLinkFirebase` | `deep_link_firebase` |
| `profilesType` | `profiles_type` |
| `mainService` | `main_service` |
| `keyStrength` | `key_strength` |
| `lookingFor` | `looking_for` |
| `cardTheme` | `card_theme` |
| `themeColor` | `theme_color` |
| `enableBusinesslink` | `enable_businesslink` |
| `isBrandingEnabled` | `is_branding_enabled` |
| `brandingText` | `branding_text` |
| `matchingData` | `matching_data` |
| `createdAt` | `created_at` |
| `updatedAt` | `updated_at` |

### Fix
**File:** `src/modules/businesses/businesses.service.ts` — method `getPublicProfile()`

Thay vì trả `business` (raw Drizzle), format sang snake_case:
```typescript
return ResponseHelper.success({
  business: {
    id: business.id,
    slug: business.slug,
    title: business.title,           // first_name
    lastName: undefined,             // ← XÓA
    last_name: business.lastName,   // ← THÊM
    designation: business.designation,
    sub_title: business.subTitle,   // ← snake_case
    bio: business.bio,
    logo: business.logo,
    banner: business.banner,
    totalView: undefined,
    total_view: business.totalView,
    total_scan: business.totalScan,
    deep_link: business.deepLink,
    deep_link_firebase: business.deepLinkFirebase,
    settings: business.settings,    // raw string (giống PHP)
    created_at: formatPhpDate(business.createdAt),
    updated_at: formatPhpDate(business.updatedAt),
  },
  contactInfo: ...,
  ...
}, 'Lấy profile thành công');
```

---

## Issue 16 — 🟠 Thiếu `social_links` field

### Phân tích
PHP `index()` và `detail()` trả **2 fields** cho socials:
```php
'sociallinks'  => json_decode($sociallinks->content, true),  // raw parsed (object/array)
'social_links' => $social_content_array,                     // rebuilt array
```

NestJS chỉ trả `sociallinks` (qua `formatSociallinks()`). Thiếu hoàn toàn `social_links`.

Sự khác biệt:
- `sociallinks`: PHP `index()` trả raw `json_decode` (object), PHP `detail()` trả raw `json_decode` (object). NestJS trả array format `[{Platform: url, id: idx}]`.
- `social_links`: Rebuilt array `[{Platform: url, id: idx}]` — giống NestJS `sociallinks`.

### Fix
**File:** `src/modules/businesses/businesses.service.ts`

Thêm `social_links: socialsArr` vào response của `getAll()` và `getById()`:
```typescript
sociallinks: socialsArr,
social_links: socialsArr,   // ← THÊM (PHP có 2 fields này, cùng giá trị)
```

---

## Issue 17 — 🟠 Thiếu `password` và `enable_password`

### Phân tích
PHP `index()` và `detail()` trả:
```php
'password'        => $business->password,
'enable_password' => $business->enable_password,
```

Đây là password bảo vệ card (visitor phải nhập mật khẩu để xem). NestJS không trả 2 fields này.

### Kiểm tra schema
Cần xác nhận bảng `businesses` có column `password` và `enable_password` không:

```sql
DESCRIBE businesses;
```

### Fix (sau khi xác nhận column tồn tại)
**File:** `src/shared/schema.ts` — thêm vào `businesses` table nếu chưa có:
```typescript
password: varchar("password", { length: 255 }),
enablePassword: int("enable_password"),
```

**File:** `src/modules/businesses/businesses.service.ts` — thêm vào response `getAll()` và `getById()`:
```typescript
password: business.password ?? null,
enable_password: business.enablePassword ?? 0,
```

---

## Issue 18 — 🟡 `GET /api/cards` thiếu filter `?profiles_type=`

### Phân tích
PHP `index()` có:
```php
if ($request->has('profiles_type')) {
    $query->where('profiles_type', $request->profiles_type);
}
```

NestJS `getAll()` không có filter này — luôn trả tất cả cards.

### Fix
**File:** `src/modules/businesses/businesses.controller.ts` — thêm `@Query('profiles_type')`:
```typescript
@Get()
getAll(@GetUser() user: any, @Query('profiles_type') profilesType?: string) {
  return this.businessesService.getAll(user.id, profilesType);
}
```

**File:** `src/modules/businesses/businesses.service.ts` — thêm param vào `getAll()`:
```typescript
async getAll(userId: number, profilesType?: string) {
  const list = await this.businessesRepo.findAllByUser(userId, profilesType);
  ...
}
```

**File:** `src/modules/businesses/businesses.repository.ts` — thêm filter vào query:
```typescript
async findAllByUser(userId: number, profilesType?: string) {
  const conditions = [...];
  if (profilesType) {
    conditions.push(eq(businesses.profilesType, profilesType));
  }
  ...
}
```

---

## Issue 19 — 🟡 `total_view` / `total_scan` counting method khác

### Phân tích
- **PHP** `detail()` (lines 443-447): **đếm lại từ history table** sau mỗi request:
  ```php
  $views = $business->history()->where('type', 'view')->count();
  $scans = $business->history()->where('type', 'scan')->count();
  $business->total_view = $views;
  $business->total_scan = $scans;
  $business->save();
  ```
- **NestJS** `getById()`: `incrementView()` / `incrementScan()` rồi reload từ column counter.

→ Nếu history table bị out-of-sync với counter column, PHP và NestJS sẽ trả số khác nhau.

### Quyết định
NestJS dùng **counter column** (increment) là đúng và performant hơn PHP (count toàn bộ history).
→ **Giữ nguyên** NestJS approach nhưng **ghi chú vào docs** để team biết sự khác biệt.

---

## Issue 20 — 🟡 Thiếu tạo `contact_request` type=`recent` khi scan

### Phân tích
PHP `detail()` khi `$request->fromScan = true` (lines 404-422):
```php
if($request->fromScan) {
    if($authUser) {
        // Kiểm tra đã có recent contact chưa
        $recentContact = ContactRequest::where('user_id', $authUser->id)
                            ->where('business_id', $business->id)
                            ->where('type', 'recent')->first();
        if(!$recentContact) {
            // Chỉ tạo nếu scan người khác (không phải chính mình)
            if($businessId != $authUser->id) {
                ContactRequest::create([
                    'user_id' => $authUser->id,
                    'status' => 'recent',
                    'type' => 'recent',
                    'business_id' => $business->id,
                    'requested_user_id' => $businessId,
                ]);
            }
        }
    }
}
```

NestJS `getById()` không có logic này.

### Fix
**File:** `src/modules/businesses/businesses.service.ts` — method `getById()`

Sau khi xác nhận `fromScan = true`:
```typescript
if (fromScan && userId) {
  // Tạo recent contact nếu scan người khác
  const businessOwnerId = business.ownerId ?? business.createdBy;
  if (businessOwnerId !== userId) {
    const existing = await this.contactRequestRepo.findRecentByUserAndBusiness(userId, id);
    if (!existing) {
      await this.contactRequestRepo.createRecent({
        userId,
        businessId: id,
        requestedUserId: businessOwnerId,
        status: 'recent',
        type: 'recent',
      });
    }
  }
}
```

**Cần thêm:** `ContactRequestRepository` và method `findRecentByUserAndBusiness()`, `createRecent()`.

---

## Issue 21 — 🟢 `POST /api/cards/link-card/:id` thiếu check QR đã linked

### Phân tích
PHP `linkCard()` (line 1688-1691):
```php
if($qrCodeGen->business_id) {
    sentryLog('Thẻ đã được liên kết. Vui lòng chọn thẻ khác.');
    return $this->error([], 'Thẻ đã được liên kết. Vui lòng chọn thẻ khác.');
}
```

PHP cũng kiểm tra `if(!$qrCodeGen)` → error `"Mã code không tồn tại"` (PHP) vs `"Mã thẻ không tồn tại"` (NestJS) — minor.

NestJS hiện tại: tìm QR rồi link thẳng, **không kiểm tra** nếu QR đã có `businessId` (đã được link vào card khác).

### Fix
**File:** `src/modules/businesses/businesses.service.ts` — method `linkCard()`

Thêm sau khi tìm được `qr`:
```typescript
if (!qr) {
  return ResponseHelper.error('Mã code không tồn tại');
}
// Check if QR is already linked to another business
if (qr.businessId) {
  return ResponseHelper.error('Thẻ đã được liên kết. Vui lòng chọn thẻ khác.');
}
```

---

## Issue 22 — 🟢 `POST /api/cards/banner/:id` response message rỗng

### Phân tích
- **PHP** `updateBanner()` (line 1787): `return $this->success([...], 'Cập nhật thành công')`
- **NestJS**: trả message `''` (rỗng)

### Fix
**File:** `src/modules/businesses/businesses.service.ts` — method `updateBanner()`

```typescript
// BEFORE
return ResponseHelper.success({ banner_img: url }, '');

// AFTER
return ResponseHelper.success({ banner_img: url }, 'Cập nhật thành công');
```

---

## Feature mới (không phải bug — NestJS bổ sung so với PHP)

### Feature 11 — `POST /api/cards/:id/generate-deeplink`

**Nguồn gốc:** PHP chỉ có artisan command `business:generate-deeplink` chạy batch.
**NestJS thêm:** API endpoint để FE Web gọi on-demand cho từng card.

**Trạng thái:** ✅ Đã implement đúng.

**Flow:**
1. Nếu `business.deepLinkFirebase` đã có → trả về luôn (không generate lại).
2. Nếu chưa → build longDynamicLink → POST Firebase API → lưu shortLink vào DB.

**ENV cần có:**
```
FIREBASE_API_KEY=AIzaSy...
APP_ENV=staging|development|production
```

---

### Feature 12 — `GET /api/businesses/public/:slug`

**Nguồn gốc:** PHP dùng web route Blade (`GET /{slug}` → `BusinessController@getcard`).
**NestJS thêm:** JSON API endpoint để FE/mobile gọi trực tiếp không qua Blade.

**Trạng thái:** ✅ Đã implement.

**Gap còn lại (đã ghi trong BUSINESS_API_REFERENCE.md TODOs):**
- Response trả `business` object dạng raw Drizzle camelCase. Nếu FE cần format giống `/api/cards/:id` (snake_case đầy đủ) thì cần chuẩn hóa lại.

---

## Thứ tự thực hiện

```
Phase 1 — Critical (block mobile app hoặc sai data nghiêm trọng):
  [1]  Fix HTTP method: POST /api/check-card/:cardCode
  [2]  Fix checkSerialNumberOfCard logic (rewrite theo PHP)
       └── Cần BusinessesRepository.findBySlug() — kiểm tra có sẵn chưa
  [13] Fix industries/services/need_services response: thêm formatIndustryArray() helper
       └── Apply cho getAll(), getById(), create(), update()
  [14] Ghi docs về settings format (NestJS object vs PHP raw string — giữ NestJS)
  [15] Fix getPublicProfile(): map business object sang snake_case

Phase 2 — High (data integrity + missing side effects):
  [16] Thêm social_links field vào getAll() và getById()
  [17] Kiểm tra schema password/enable_password, thêm nếu thiếu, trả trong response
  [3]  Fix delete(): thêm xóa contact_requests
  [4]  Fix create(): implement qrcode_serial linking + auto-link physical card fallback
  [5]  Thêm callCardWebhook() helper; gọi trong delete() + create() + update()

Phase 3 — Medium:
  [18] Thêm filter ?profiles_type= vào getAll()
  [20] Thêm tạo contact_request type=recent khi scan (getById + getPublicProfile)
  [6]  Fix linkCard() response message: "" → "Liên kết thành công."

Phase 4 — Low (optional):
  [9]  Fix update(): clear matching_data = null
  [10] Chuẩn hóa appointment messages (thêm dấu tiếng Việt, sửa typo)
  [21] Fix linkCard(): thêm check if QR already linked (business_id != null)
  [22] Fix updateBanner() response message: "" → "Cập nhật thành công"
```

---

## Files cần chỉnh sửa

| File | Issues |
|------|--------|
| `src/modules/businesses/businesses.controller.ts` | Issue 1 (POST method), Issue 18 (profiles_type query) |
| `src/modules/businesses/businesses.service.ts` | Issue 2, 3, 4, 5, 6, 9, 13, 15, 16, 17, 18, 20, 21, 22 |
| `src/modules/businesses/businesses.repository.ts` | Issue 18 (filter profilesType) — findBySlug đã có |
| `src/shared/schema.ts` | Issue 17 (thêm password, enable_password nếu thiếu) |
| `src/modules/appointments/appointments.service.ts` | Issue 10 |
| `docs/BUSINESS_API_REFERENCE.md` | Issue 1 (method POST), Issue 2 (statusCode table), Issue 14 (settings note), Issue 19 (counting note) |

---

## Files không cần thay đổi

- Appointment routes: Đã match PHP 100%
- `POST /api/cards/banner/:id`: Logic đúng, chỉ fix message (Issue 22)
- `generate-deeplink` (Issue 11): Feature mới, giữ nguyên
- `businesses/public/:slug` route (Issue 12): Feature mới, chỉ fix format response (Issue 15)
- Issue 19 (`total_view` counting): NestJS approach tốt hơn, không cần fix

---

## CamelCase → snake_case Audit Summary

Tất cả response trong `businesses.service.ts` đều dùng **hardcoded snake_case keys** cho response (đúng). Vấn đề chỉ xảy ra tại:

1. **`getPublicProfile()`**: Trả raw Drizzle object `business` — tất cả keys là camelCase. → **Fix: Issue 15**
2. **`industries`/`services`/`need_services`**: Trả raw JSON từ DB thay vì transform sang `[{id, name}]` như PHP. → **Fix: Issue 13**
3. **`settings`**: NestJS parse JSON → object; PHP trả raw string. → **Giữ NestJS (đúng hơn), ghi docs: Issue 14**
4. **`social_links`**: Thiếu field (NestJS chỉ có `sociallinks`). → **Fix: Issue 16**
5. **`password`/`enable_password`**: Thiếu hoàn toàn. → **Fix: Issue 17**
