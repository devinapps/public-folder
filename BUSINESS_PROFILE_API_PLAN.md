# Plan: Business Card & Profile Management API

**Target source:** `D:\Program Files\InCard-API\CMS_InCard_api` (NestJS)
**Reference source:** `D:\Program Files\InCard-API\incard-biz` (Laravel PHP)
**Database:** Dùng chung MySQL — không migrate schema
**Auth:** JWT Bearer token (`AuthGuard` đã có sẵn)
**Client:** Mobile app (React Native / Flutter)
**Last verified:** 2026-03-02

---

## Tổng quan phạm vi

Migrate 2 nhóm chức năng từ PHP sang NestJS.

| Nhóm | PHP Controller | PHP Route prefix | Module NestJS |
|---|---|---|---|
| **Business Card** | `API\CardController` | `GET/POST /api/cards` | `src/modules/businesses/` |
| **Appointment** | `API\AppointmentsController` | `GET/POST /api/appointments` | `src/modules/appointments/` |

> **Quan trọng:** PHP có 2 controller khác nhau cho Business:
> - `API\CardController` (api.php) → JSON API cho mobile app ← **đây là reference**
> - `BusinessController` (web.php) → HTML/Blade cho web dashboard ← chỉ tham khảo business logic
>
> Plan này migrate từ `API\CardController`, KHÔNG phải `BusinessController`.

---

## Danh sách Endpoints

### Module 1: Business Cards

| Method | Endpoint NestJS | Guard | PHP tương đương | Mô tả |
|---|---|---|---|---|
| `GET` | `/api/cards` | `AuthGuard` | `GET /api/cards` | Danh sách cards của user |
| `POST` | `/api/cards` | `AuthGuard` | `POST /api/cards` | Tạo card mới |
| `GET` | `/api/cards/:id` | `AuthGuard` | `GET /api/cards/:id` | Chi tiết 1 card (private + public view) |
| `POST` | `/api/cards/update/:id` | `AuthGuard` | `POST /api/cards/update/:id` | Cập nhật card |
| `DELETE` | `/api/cards/:id` | `AuthGuard` | `DELETE /api/cards/:id` | Xóa card |
| `POST` | `/api/cards/link-card/:id` | `AuthGuard` | `POST /api/cards/link-card/:id` | Link physical card |
| `POST` | `/api/cards/banner/:id` | `AuthGuard` | `POST /api/cards/banner/:id` | Upload banner (field: `banner_img`) |
| `GET` | `/api/check-card/:cardCode` | `AuthGuard` | `GET /api/check-card/:cardCode` | Kiểm tra serial card vật lý |

> **Routing conflict:** `/api/cards/update/:id` và `/api/cards/:id` có thể conflict → khai báo `update/:id` trước `:id`.

### Module 2: Appointments

| Method | Endpoint NestJS | Guard | PHP tương đương | Mô tả |
|---|---|---|---|---|
| `GET` | `/api/appointments` | `AuthGuard` | `GET /api/appointments` | Danh sách lịch hẹn |
| `POST` | `/api/appointments/add` | `AuthGuard` | `POST /api/appointments/add` | Tạo lịch hẹn (user đặt cho card người khác) |
| `GET` | `/api/appointments/:id` | `AuthGuard` | `GET /api/appointments/:id` | Chi tiết lịch hẹn |
| `POST` | `/api/appointments/update/:id` | `AuthGuard` | `POST /api/appointments/update/:id` | Cập nhật lịch hẹn |
| `POST` | `/api/appointments/accept/:id` | `AuthGuard` | `POST /api/appointments/accept/:id` | Chấp nhận lịch hẹn |
| `POST` | `/api/appointments/reject/:id` | `AuthGuard` | `POST /api/appointments/reject/:id` | Từ chối lịch hẹn |
| `POST` | `/api/appointments/delete/:id` | `AuthGuard` | `POST /api/appointments/delete/:id` | Xóa lịch hẹn (PHP dùng POST, không phải DELETE) |

### Public Appointments (Google Calendar sync — No Auth)

| Method | Endpoint NestJS | Guard | PHP tương đương | Mô tả |
|---|---|---|---|---|
| `POST` | `/api/public-appointments/add` | Public | `POST /api/public-appointments/add` | Tạo appointment từ Google Calendar |
| `POST` | `/api/public-appointments/update` | Public | `POST /api/public-appointments/update` | Update appointment từ Google Calendar |
| `POST` | `/api/public-appointments/delete` | Public | `POST /api/public-appointments/delete` | Xóa appointment từ Google Calendar |

---

## Database Tables

### Bảng đã có trong `src/shared/schema.ts` — cần kiểm tra đủ fields

| Table DB | Tên trong schema.ts | Cần kiểm tra |
|---|---|---|
| `businesses` | `businesses` | Nhiều fields JSON — verify đủ so với DB |
| `appoinments` | `appoinments` | `business_id`, `content`, `is_enabled`, `created_by` |
| `appointment_deatails` | `appointmentDeatails` | Đủ fields kể cả `user_requested`, `google_calendar_id` |
| `qrcode_generated` | `qrcodeGenerated` | OK |

### Bảng chưa có — cần thêm vào `src/shared/schema.ts`

```sql
-- contact_infos
CREATE TABLE contact_infos (
  id bigint unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  business_id int DEFAULT NULL,
  content text,
  is_enabled int DEFAULT NULL,
  created_by int DEFAULT NULL,
  created_at timestamp NULL,
  updated_at timestamp NULL
);

-- business_hours
CREATE TABLE business_hours (
  id bigint unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  business_id int DEFAULT NULL,
  content text,
  is_enabled int DEFAULT NULL,
  created_by int DEFAULT NULL,
  created_at timestamp NULL,
  updated_at timestamp NULL
);

-- services (dùng cho cả product_services và media, phân biệt bằng type)
CREATE TABLE services (
  id bigint unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  business_id int DEFAULT NULL,
  content text,
  is_enabled int DEFAULT NULL,
  created_by int DEFAULT NULL,
  created_at timestamp NULL,
  updated_at timestamp NULL,
  type varchar(191) NOT NULL DEFAULT 'service'
);

-- testimonials
CREATE TABLE testimonials (
  id bigint unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  business_id int DEFAULT NULL,
  content text,
  is_enabled int DEFAULT NULL,
  created_by int DEFAULT NULL,
  created_at timestamp NULL,
  updated_at timestamp NULL
);

-- socials
CREATE TABLE socials (
  id bigint unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  business_id int DEFAULT NULL,
  content text,
  is_enabled int DEFAULT NULL,
  created_by int DEFAULT NULL,
  created_at timestamp NULL,
  updated_at timestamp NULL
);

-- business_histories — tracking view/scan/booked
-- type: 'view' | 'scan' | 'booked'
CREATE TABLE business_histories (
  id bigint unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id int DEFAULT NULL,
  business_id bigint NOT NULL,
  type varchar(20) DEFAULT NULL,
  ip varchar(30) DEFAULT NULL,
  url varchar(200) DEFAULT NULL,
  created_at timestamp NULL,
  updated_at timestamp NULL
);

-- contact_requets (typo giữ nguyên — khớp DB)
CREATE TABLE contact_requets (
  id bigint unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id bigint NOT NULL,
  user_business_id bigint DEFAULT NULL,
  business_id bigint NOT NULL,
  requested_user_id bigint NOT NULL,
  status varchar(191) NOT NULL,
  note text,
  type varchar(191) NOT NULL DEFAULT 'request',
  tags text,
  created_at timestamp NULL,
  updated_at timestamp NULL
);
```

---

## Cấu trúc Files

### Module Businesses (cards)

```
src/modules/businesses/
├── businesses.module.ts
├── businesses.controller.ts
├── businesses.service.ts
├── businesses.repository.ts          # bảng businesses
├── contact-info.repository.ts        # bảng contact_infos
├── business-hours.repository.ts      # bảng business_hours
├── services.repository.ts            # bảng services (type=service + type=media)
├── testimonials.repository.ts        # bảng testimonials
├── socials.repository.ts             # bảng socials
├── business-history.repository.ts    # bảng business_histories
└── dto/
    ├── create-card.dto.ts
    ├── update-card.dto.ts
    └── index.ts
```

### Module Appointments

```
src/modules/appointments/
├── appointments.module.ts
├── appointments.controller.ts
├── appointments.service.ts
├── appointments.repository.ts        # bảng appointment_deatails (typo giữ nguyên)
├── appointment-config.repository.ts  # bảng appoinments (typo giữ nguyên)
└── dto/
    ├── create-appointment.dto.ts
    ├── update-appointment.dto.ts
    └── index.ts
```

---

## Chi tiết Implementation

---

### Bước 1: Cập nhật `src/shared/schema.ts`

Thêm 7 table definitions mới. Pattern:

```typescript
export const contactInfos = mysqlTable('contact_infos', {
  id: bigint('id', { mode: 'number', unsigned: true }).primaryKey().autoincrement(),
  businessId: int('business_id'),
  content: text('content'),
  isEnabled: int('is_enabled'),
  createdBy: int('created_by'),
  createdAt: timestamp('created_at'),
  updatedAt: timestamp('updated_at'),
});
export const insertContactInfoSchema = createInsertSchema(contactInfos).omit({ id: true, createdAt: true, updatedAt: true });
export type ContactInfo = typeof contactInfos.$inferSelect;
export type InsertContactInfo = z.infer<typeof insertContactInfoSchema>;
```

Áp dụng tương tự cho: `businessHours`, `services` (thêm field `type`), `testimonials`, `socials`, `businessHistories`, `contactRequets`.

**Kiểm tra lại** bảng `businesses` trong schema hiện tại — đảm bảo có đủ:
- `title`, `lastName`, `slug`, `designation`, `subTitle`, `description`, `bio`
- `category` (JSON), `services` (JSON), `needServices` (JSON)
- `logo`, `banner`, `cardTheme`, `themeColor`, `settings` (JSON)
- `totalView`, `totalScan`, `totalAppointment`
- `ownerId`, `ownerIds` (JSON), `createdBy`
- `password`, `enablePassword`, `deepLink`, `profilesType`
- `mainService`, `keyStrength`, `lookingFor` (JSON), `collaboration` (JSON)

---

### Bước 2: Register vào `src/common/repository.module.ts`

```typescript
// Businesses group
BusinessesRepository,
ContactInfoRepository,
BusinessHoursRepository,
ServicesRepository,
TestimonialsRepository,
SocialsRepository,
BusinessHistoryRepository,

// Appointments group
AppointmentsRepository,        // appointment_deatails
AppointmentConfigRepository,   // appoinments
```

---

### Bước 3: Repositories chi tiết

#### `businesses.repository.ts`

```typescript
findAllByUser(userId: number): Promise<Business[]>
// WHERE (owner_id = userId OR owner_ids JSON contains userId)
// ORDER BY id DESC
// Lưu ý: PHP dùng owner_id + owner_ids (không dùng created_by)

findById(id: number): Promise<Business | undefined>
findBySlug(slug: string): Promise<Business | undefined>

// Dùng khi lookup bằng serial number (qrcode_generated.code)
findByQrcodeSerial(code: string): Promise<Business | undefined>
// → JOIN qrcode_generated WHERE code = ?

create(data: InsertBusiness): Promise<Business>
update(id: number, data: Partial<InsertBusiness>): Promise<Business | undefined>

delete(id: number): Promise<boolean>
// PHP delete: chỉ WHERE id = ? AND owner_id = userId (không check created_by)

// Tăng/giảm counter
incrementTotalView(id: number): Promise<void>
incrementTotalScan(id: number): Promise<void>
recalculateTotalViewScan(id: number): Promise<void>
// PHP logic: sau khi ghi history → đếm lại từ DB và save vào total_view/total_scan
// views = COUNT(*) WHERE business_id = id AND type = 'view'
// scans = COUNT(*) WHERE business_id = id AND type = 'scan'
```

#### `contact-info.repository.ts` (và tương tự 4 bảng còn lại)

```typescript
findByBusinessId(businessId: number): Promise<ContactInfo | undefined>

upsert(businessId: number, content: string, isEnabled: number, createdBy: number): Promise<void>
// - Nếu chưa có → INSERT
// - Nếu có rồi  → UPDATE content + is_enabled
```

> `services.repository.ts`: có thêm param `type: 'service' | 'media'` trong `findByBusinessId` và `upsert`.

#### `business-history.repository.ts`

```typescript
create(data: {
  businessId: number,
  userId?: number,
  type: 'view' | 'scan' | 'booked',
  ip: string,
  url: string
}): Promise<void>

countByType(businessId: number, type: string): Promise<number>
// SELECT COUNT(*) WHERE business_id = ? AND type = ?
```

#### `appointment-config.repository.ts` (bảng `appoinments`)

```typescript
findByBusinessId(businessId: number): Promise<AppointmentConfig | undefined>
upsert(businessId: number, content: string, isEnabled: number, createdBy: number): Promise<void>
```

#### `appointments.repository.ts` (bảng `appointment_deatails`)

```typescript
findAllByCreator(userId: number): Promise<AppointmentDetail[]>
// WHERE created_by = userId AND user_requested IS NULL
// ORDER BY date DESC

findAllRequested(userId: number): Promise<AppointmentDetail[]>
// WHERE user_requested = userId AND user_requested IS NOT NULL
// ORDER BY date DESC

findByIdAndCreator(id: number, userId: number): Promise<AppointmentDetail | undefined>
// WHERE id = ? AND created_by = userId

create(data: InsertAppointmentDetail): Promise<AppointmentDetail>
update(id: number, data: Partial<InsertAppointmentDetail>): Promise<AppointmentDetail | undefined>
delete(id: number): Promise<boolean>

findByGoogleCalendarId(userId: number, googleCalendarId: string): Promise<AppointmentDetail | undefined>
// WHERE created_by = userId AND google_calendar_id = ?
```

---

### Bước 4: `businesses.service.ts` — Business Logic

#### `getAll(userId: number, profilesType?: string)`

```
1. Query businesses WHERE (owner_id = userId OR owner_ids JSON contains userId)
   ORDER BY id DESC
   - Optional: filter by profiles_type nếu được truyền vào

2. Với mỗi business:
   a. sociallinks = socials WHERE business_id = id (parse JSON content)
   b. contacts = contact_infos WHERE business_id = id (parse JSON → lấy email + phone)
      - Lấy email: contact.find Email key
      - Lấy phone: contact.find Phone key
      - Chỉ parse nếu is_enabled == '1'
   c. testimonials = testimonials WHERE business_id = id (parse JSON)
   d. industries = parse business.category JSON → [{id, name}]
   e. services = parse business.services JSON → [{id, name}]
   f. need_services = parse business.need_services JSON → [{id, name}]
   g. product_services = services WHERE business_id = id AND type = 'service' (parse JSON)
      - Mỗi item: {id, title, description, purchase_link, image: full URL}
      - image URL: asset(Storage::url('service_images/' + filename))
   h. media = services WHERE business_id = id AND type = 'media' (parse JSON)
      - Mỗi item: {id, title, description, video_link, image: full URL}
      - image URL: asset(Storage::url('media_images/' + filename))
   i. deeplink: nếu business.deep_link null → tạo URL từ slug
   j. is_my_card = (business.owner_id == userId)
   k. Generate QR files on-demand (xem mục QR Generation bên dưới)

3. Build response item:
   {
     id, slug,
     first_name: business.title,
     last_name: business.last_name,
     email, phone,          ← từ contact_infos
     title: business.designation,
     company: business.sub_title,
     bio: business.bio,
     industries, services, need_services,
     sociallinks,           ← raw JSON parsed
     social_links,          ← array from social content
     testimonials,
     password, enable_password,
     logo: full URL (Storage::url('card_logo/' + logo) hoặc default avatar),
     created_at, updated_at,
     total_view, total_scan, total_appointment,
     is_owner,              ← business.is_owner()
     request_status,        ← business.request_status()
     profile_url: url('profile/' + slug),
     profile_qr: full URL ← file PNG thực tế được generate on-demand (xem QR Generation),
     contact_qr: full URL ← file PNG thực tế được generate on-demand (xem QR Generation),
     product_services, media,
     settings: business.settings,
     is_my_card: (owner_id == userId),
     deeplink: business.deep_link,
     profiles_type, main_service, key_strength,
     looking_for: JSON parsed or null,
     collaboration: JSON parsed or null
   }
```

#### `getDetail(id: string, userId: number, fromScan?: boolean)`

```
PHP detail() logic — id có thể là:
  - numeric id → Business::find(id)
  - serial code (type=serial) → QrcodeGenerated::where('code', id) → business
  - slug → Business::where('slug', id)

1. Resolve business từ id param (check serial → id → slug)
2. Ghi business_histories:
   - Luôn ghi type='view' với user_id = business.created_by
   - Nếu fromScan=true: thêm 1 record type='scan' (không có user_id)
   - Nếu fromScan=true VÀ userId tồn tại: upsert contact_requets
     { user_id: userId, status: 'recent', type: 'recent', business_id: id,
       requested_user_id: (business.owner_id ?? business.created_by) }
     - Chỉ tạo nếu chưa có record recent AND businessId != userId

3. Sau khi ghi history: đếm lại views/scans và UPDATE businesses.total_view, total_scan
   views = COUNT(*) history WHERE business_id = id AND type = 'view'
   scans = COUNT(*) history WHERE business_id = id AND type = 'scan'
   business.total_view = views; business.total_scan = scans; business.save()

4. Load tất cả sub-data (như getAll nhưng đầy đủ hơn):
   - testimonials: parse image thành full URL
   - contacts, sociallinks, industries, services, need_services
   - product_services, media (với full URL cho images)
   - tags từ business_tags + service_categories (nếu có)
   - connected_id, connected_name (từ contact_requets)
   - is_enable_appoinment (từ appoinments table)
   - hasPhysicalCard (từ qrcode_generated)
   - banner_img: full URL nếu file tồn tại

5. Return full response:
   {
     id, slug,
     first_name: business.title,
     last_name: business.last_name,
     email, phone,
     title: business.designation,
     company: business.sub_title,
     bio,
     industries, services, need_services,
     sociallinks, social_links,
     testimonials, testimonials_is_enabled,
     password, enable_password,
     logo: full URL,
     created_at, updated_at,
     total_view, total_scan, total_appointment,
     profile_qr, contact_qr,
     deeplink,
     is_owner, request_status, approved_at,
     profile_url,
     need_services,
     hasPhysicalCard,
     is_enable_appoinment,
     banner_img,
     product_services, media,
     settings,
     owner_id,
     tags,
     connected_id, connected_name,
     profiles_type, main_service, key_strength,
     looking_for, collaboration
   }
```

#### `create(userId: number, dto: CreateCardDto)`

```
PHP add() logic:

1. Validate: first_name required, last_name required

2. Nếu user chưa có card (numOfCards == 0) hoặc user.name rỗng:
   → UPDATE users SET name = first_name + ' ' + last_name,
     first_name = first_name, last_name = last_name

3. INSERT businesses:
   created_by = userId
   owner_id   = userId
   owner_ids  = JSON.stringify([userId])
   title      = dto.first_name
   last_name  = dto.last_name
   slug       = createSlug(businesses, title + ' ' + last_name)
   designation = dto.title
   sub_title  = dto.company
   description = dto.introduction
   bio        = dto.bio
   category   = JSON.stringify(resolvedIndustries)   ← {id: name} map
   services   = JSON.stringify(resolvedServices)      ← {id: name} map
   need_services = JSON.stringify(resolvedNeedServices)
   profiles_type, main_service, key_strength (nếu có trong dto)
   looking_for, collaboration (JSON validate + store)

4. Sau khi save:
   card_theme = { theme: 'theme5', order: DEFAULT_CARD_THEME_ORDER }
   theme_color = 'color5-theme5'
   → save lại

5. Nếu dto.media → INSERT services (type='media')
   Nếu dto.servicesInfo → INSERT services (type='service')

6. Nếu dto.logo (file) → upload → lưu filename, resize 400px

7. Nếu dto.social_link → upsert socials

8. Nếu dto.email hoặc dto.phone → upsert contact_infos

9. Nếu dto.qrcode_serial → link QrcodeGenerated với business

10. Return response (PHP add() trả về subset — KHÔNG giống getDetail):
    {
      id, slug,
      first_name: business.title,
      last_name: business.last_name,
      email, phone,
      title: business.designation,
      company: business.sub_title,
      bio,
      industries, services, need_services,
      sociallinks,          ← json_decode(sociallinks.content) hoặc []
      testimonials,
      password, enable_password,
      logo: full URL hoặc default avatar,
      created_at, updated_at,
      total_view, total_scan, total_appointment,
      is_owner, request_status,
      profile_url: url(business.slug),   ← KHÔNG có '/profile/' prefix
      profiles_type, main_service, key_strength,
      looking_for, collaboration,
      product_services, media
      // KHÔNG có: profile_qr, contact_qr, deeplink, banner_img, tags, connected_id, owner_id, settings, is_my_card
    }
```

**`createSlug(table, text)`** — PHP `Utility::createSlug()`:
```
1. slugify(text, { lower: true, locale: 'vi' })
2. Kiểm tra slug đã tồn tại trong bảng
   - Nếu chưa có → dùng luôn
   - Nếu có → thêm số ngẫu nhiên: slug + '-' + random(4 digits)
   - Lặp lại cho đến khi unique
```

#### `update(id: string, userId: number, dto: UpdateCardDto, files?)`

```
PHP update() logic (CardController.update):

1. Load business = Business::find(id)
   → 400 nếu không tìm thấy
   !! QUAN TRỌNG: PHP KHÔNG check ownership tại đây — chỉ find by id

2. Luôn save settings trước: business.settings = dto.settings ?? []

3. Upsert media (services type='media'):
   - Nếu dto.media có dữ liệu → upsert với content mới (xử lý file image upload trong vòng lặp)
   - Nếu dto.media không có → set content = [] và is_enabled = '1'

4. Upsert product services (services type='service') với field name là 'servicesInfo':
   - Nếu dto.servicesInfo có dữ liệu → upsert với content mới
   - Nếu dto.servicesInfo không có → set content = [], is_enabled = '0'

5. Update main business fields:
   title = dto.first_name
   last_name = dto.last_name
   designation = dto.title
   sub_title = dto.company
   bio = dto.bio
   category = JSON.stringify(resolvedIndustries)  ← resolve từ industries IDs/names
   services = JSON.stringify(resolvedServices)
   need_services = JSON.stringify(resolvedNeedServices)
   profiles_type, main_service, key_strength (nếu có trong dto)
   looking_for, collaboration (JSON validate + store, nếu có)

6. Nếu files.logo → upload logo:
   - Store vào app/public/card_logo/
   - Resize to 400px (aspect ratio)
   - Create fit version (300px) in card_logo/fit/
   - DELETE cũ trước khi save mới

7. Upsert socials (field name 'social_link'):
   - Nếu dto.social_link có entries → upsert socials
   - Nếu dto.social_link rỗng/không có → SET socials.content = null

8. Upsert contact_infos từ email + phone flat fields:
   - [{ Email: dto.email, id: 0 }, { Phone: dto.phone, id: 1 }]

9. LUÔN overwrite card_theme và theme_color sau khi update:
   card_theme = { theme: 'theme5', order: DEFAULT_CARD_THEME_ORDER }
   theme_color = 'color5-theme5'

10. Call webhook: POST CARD_WEBHOOK_URL với { id, type: 'upsert' }

11. Call update_vector_profile(business) — AI matching update

12. Return response (subset — không đầy đủ như getDetail):
    {
      id, slug,
      first_name: business.title,
      last_name: business.last_name,
      email, phone,
      title: business.designation,
      company: business.sub_title,
      bio,
      industries, services, need_services,
      sociallinks,   ← json_decode hoặc []
      testimonials,
      password, enable_password,
      logo: full URL,
      created_at, updated_at,
      total_view, total_scan, total_appointment,
      is_owner, request_status,
      profile_url: url(business.slug),   ← KHÔNG có '/profile/' prefix
      product_services, media,
      settings,
      profiles_type, main_service, key_strength,
      looking_for, collaboration
      // KHÔNG có: profile_qr, contact_qr, deeplink, banner_img, tags, owner_id, is_my_card
    }
```

#### `delete(id: number, userId: number)`

```
PHP delete() logic:

1. Load business WHERE id = ? AND owner_id = userId
   → 404 nếu không tìm thấy (chỉ owner_id check, KHÔNG check created_by)

2. Nếu xóa thành công:
   a. DELETE socials WHERE business_id = id
   b. UPDATE qrcode_generated SET business_id = NULL WHERE business_id = id
      (giữ nguyên user_id của qrcode)
   c. DELETE contact_requets WHERE business_id = id
   d. Call webhook (optional): POST đến CARD_WEBHOOK_URL với {id, type: 'delete'}

3. Return success
```

---

#### QR Code Generation (on-demand — gọi trong `getAll` và `getDetail`)

> **Quan trọng:** QR code là **file PNG thực tế lưu trên filesystem**, KHÔNG phải chỉ URL string.
> PHP generate file trước, rồi trả URL trỏ đến file đó.
> NestJS hiện tại chỉ trả URL string mà **chưa generate file** — đây là gap cần implement.

##### Profile QR (`profile_qr`)

```
File path : storage/profile_qr/{slug}.png
Size      : 500×500 px, format PNG, error correction H
Encode    : profileURL
           - Nếu business.deep_link != null  → encode deep_link (URL NFC deeplink đã set)
           - Nếu business.deep_link == null  → encode url('profile/' + slug)

Điều kiện generate:
  - Nếu file chưa tồn tại trên disk, HOẶC
  - business.deep_link == null (force regenerate sau khi link NFC card)
  → Generate file mới vào storage/profile_qr/{slug}.png

Sau khi generate: lưu lại profileURL vào business.deep_link
  → UPDATE businesses SET deep_link = profileURL WHERE id = business.id

URL trả về: {APP_URL}/storage/profile_qr/{slug}.png
```

##### Contact QR (`contact_qr`)

```
File path : storage/contact_qr/{slug}.png
Size      : 800×800 px, format PNG, error correction H
Encode    : vCard string (VCF format)

vCard content:
  BEGIN:VCARD
  VERSION:3.0
  N:{lastName};{firstName}
  FN:{firstName} {lastName}
  ORG:{company}
  EMAIL;TYPE=WORK:{email}
  TEL;TYPE=WORK,VOICE:{phone}
  URL:{profile_url}
  X-SOCIALPROFILE;type=facebook:{facebook_url}
  ... (các social links khác)
  END:VCARD

Điều kiện generate:
  - Chỉ generate nếu file chưa tồn tại trên disk
  (KHÔNG force regenerate — contact QR ổn định hơn profile QR)

URL trả về: {APP_URL}/storage/contact_qr/{slug}.png
```

##### NestJS Implementation

```typescript
// Cần install: npm install qrcode
// Types       : npm install --save-dev @types/qrcode

import * as QRCode from 'qrcode';
import * as fs from 'fs';
import * as path from 'path';

private async generateProfileQr(business: Business): Promise<string> {
  const filePath = path.join(process.cwd(), 'storage/profile_qr', `${business.slug}.png`);
  const profileURL = business.deepLink ?? `${process.env.APP_URL}profile/${business.slug}`;

  const needsGenerate = !fs.existsSync(filePath) || !business.deepLink;
  if (needsGenerate) {
    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    await QRCode.toFile(filePath, profileURL, { width: 500, errorCorrectionLevel: 'H' });
    // Cập nhật deep_link để lần sau không generate lại
    await this.businessesRepo.update(business.id, { deepLink: profileURL });
  }
  return `${process.env.APP_URL}storage/profile_qr/${business.slug}.png`;
}

private async generateContactQr(business: Business, email: string, phone: string): Promise<string> {
  const filePath = path.join(process.cwd(), 'storage/contact_qr', `${business.slug}.png`);

  if (!fs.existsSync(filePath)) {
    const vcard = buildVCard(business, email, phone); // helper riêng
    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    await QRCode.toFile(filePath, vcard, { width: 800, errorCorrectionLevel: 'H' });
  }
  return `${process.env.APP_URL}storage/contact_qr/${business.slug}.png`;
}
```

> **Static file serving:** NestJS cần serve thư mục `storage/` dưới prefix `/storage`.
> Trong `main.ts`: `app.useStaticAssets(join(__dirname, '..', 'storage'), { prefix: '/storage' });`
> (dùng `@nestjs/serve-static` hoặc `express.static`)

---

### Bước 5: `businesses.controller.ts`

```typescript
@Controller('cards')
@UseGuards(AuthGuard)
export class BusinessesController {
  constructor(private readonly businessesService: BusinessesService) {}

  @Get()
  getAll(@GetUser() user: any, @Query('profiles_type') profilesType?: string) {
    return this.businessesService.getAll(user.id, profilesType);
  }

  @Post()
  @UseInterceptors(FileFieldsInterceptor([
    { name: 'logo', maxCount: 1 },
    { name: 'media[0][image]', maxCount: 1 },
    // ... các file field khác
  ]))
  create(
    @GetUser() user: any,
    @Body() dto: CreateCardDto,
    @UploadedFiles() files: any,
  ) {
    return this.businessesService.create(user.id, dto, files);
  }

  // PHẢI khai báo trước ':id' để tránh routing conflict
  @Post('update/:id')
  @UseInterceptors(FileFieldsInterceptor([
    { name: 'banner', maxCount: 1 },
    { name: 'logo', maxCount: 1 },
  ]))
  update(
    @Param('id') id: string,
    @GetUser() user: any,
    @Body() dto: UpdateCardDto,
    @UploadedFiles() files: { banner?: Express.Multer.File[], logo?: Express.Multer.File[] },
  ) {
    return this.businessesService.update(id, user.id, dto, files);
  }

  @Post('link-card/:id')
  linkCard(@Param('id') id: string, @GetUser() user: any, @Body() body: any) {
    return this.businessesService.linkCard(+id, user.id, body);
  }

  @Post('banner/:id')
  @UseInterceptors(FileInterceptor('banner_img'))  // PHP field name là 'banner_img'
  updateBanner(
    @Param('id') id: string,
    @GetUser() user: any,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.businessesService.updateBanner(+id, user.id, file);
  }

  @Get(':id')
  getDetail(
    @Param('id') id: string,
    @GetUser() user: any,
    @Query('type') type?: string,
    @Query('fromScan') fromScan?: string,
  ) {
    return this.businessesService.getDetail(id, user.id, type, fromScan === 'true');
  }

  @Delete(':id')
  delete(@Param('id') id: string, @GetUser() user: any) {
    return this.businessesService.delete(+id, user.id);
  }
}
```

---

### Bước 6: DTOs Business Cards

#### `create-card.dto.ts`

```typescript
import { z } from 'zod';

export const CreateCardSchema = z.object({
  first_name: z.string().min(1, 'first_name là bắt buộc'),
  last_name: z.string().min(1, 'last_name là bắt buộc'),
  // Optional fields
  title: z.string().optional(),             // → designation
  company: z.string().optional(),           // → sub_title
  introduction: z.string().optional(),      // → description
  bio: z.string().optional(),
  email: z.string().email().optional(),
  phone: z.string().optional(),
  industries: z.array(z.any()).optional(),  // array of IDs or names
  services: z.array(z.number()).optional(), // array of ServiceCategory IDs
  need_services: z.array(z.number()).optional(),
  profiles_type: z.string().optional(),
  main_service: z.string().optional(),
  key_strength: z.string().optional(),
  looking_for: z.any().optional(),          // JSON string or object
  collaboration: z.any().optional(),        // JSON string or object
  qrcode_serial: z.string().optional(),
  is_create_account: z.string().optional(), // 'true' | 'false'
  // social_link: object shape varies
});

export type CreateCardDto = z.infer<typeof CreateCardSchema>;
```

#### `update-card.dto.ts`

```typescript
export const UpdateCardSchema = z.object({
  first_name: z.string().optional(),
  last_name: z.string().optional(),
  title: z.string().optional(),
  company: z.string().optional(),
  bio: z.string().optional(),
  description: z.string().optional(),
  slug: z.string().optional(),
  status: z.enum(['active', 'inactive']).optional(),
  card_theme: z.string().optional(),
  theme_color: z.string().optional(),
  enable_zalo: z.number().min(0).max(1).optional(),
  enable_whatsapp: z.number().min(0).max(1).optional(),
  settings: z.object({
    phone_enable: z.number().optional(),
    zalo_enable: z.number().optional(),
    whatsapp_enable: z.number().optional(),
  }).optional(),
  category: z.any().optional(),
  services: z.any().optional(),
  need_services: z.any().optional(),
  profiles_type: z.string().optional(),
  main_service: z.string().optional(),
  key_strength: z.string().optional(),
  looking_for: z.any().optional(),
  collaboration: z.any().optional(),
  // Flat fields (không phải JSON strings — PHP nhận trực tiếp)
  email: z.string().optional(),            // → upsert contact_infos
  phone: z.string().optional(),            // → upsert contact_infos
  // social_link gửi dạng object: { Facebook: 'url', LinkedIn: 'url' }
  social_link: z.record(z.string()).optional(),
  // media và servicesInfo gửi dạng array of objects (multipart)
  // PHP field names: media[], servicesInfo[]
  // Không validate ở DTO level — handled trực tiếp từ multipart body
});

export type UpdateCardDto = z.infer<typeof UpdateCardSchema>;
```

---

### Bước 7: `appointments.service.ts` — Business Logic

#### `getAll(userId: number, requested?: boolean)`

```
PHP list() logic:

1. Nếu requested == true:
   Query WHERE user_requested = userId AND user_requested IS NOT NULL
   → lịch hẹn của các card khác mà user này đã đặt

2. Nếu requested == false (default):
   Query WHERE created_by = userId AND user_requested IS NULL
   → lịch hẹn được đặt vào card của user này

3. ORDER BY date DESC

4. Với mỗi appointment:
   business_name = businesses.title + ' ' + businesses.last_name WHERE id = appointment.business_id

5. Return list (raw appointment + appended business_name)
```

#### `add(userId: number, dto: CreateAppointmentDto)` — Auth required

```
PHP add() logic — ĐÂY LÀ USER ĐẶT LỊCH HẸN VỚI CARD NGƯỜI KHÁC (auth required):

1. Load business theo dto.card_id (field name là card_id, không phải business_id)
   Load user = users WHERE id = business.created_by
   → 400 nếu không tìm thấy

2. INSERT appointment_deatails (PHP tạo không có title, rồi set riêng):
   business_id  = dto.card_id
   name         = dto.name
   email        = dto.email
   phone        = dto.phone
   date         = dto.date
   time         = dto.time
   note         = dto.note
   status       = 'pending'
   created_by   = (business.owner_id ?? business.created_by)
   user_requested = userId   ← ID của người đặt lịch (auth user)
   → save()
   → appointment.title = dto.title; appointment.save()   ← 2 lần save (PHP quirk)

3. Ghi business_histories:
   { user_id: business.created_by, business_id, type: 'booked', ip, url: url(business.slug) }

4. Tăng counter: business.total_appointment += 1; business.save()

5. Gửi notification FCM (best-effort, không fail nếu lỗi):
   - Notify business owner: AppointmentBooked notification
   - Gửi FCM nếu owner.device_token tồn tại
   - title: '{me.name} vừa đặt lịch hẹn cho bạn.'
   - type: 'appointment'

6. Return { appointment: appointmentObject }
   (KHÔNG phải { appointment_id: 123 } — PHP trả về full object)
```

#### `getDetail(id: number, userId: number)`

```
PHP detail() logic:

1. Load appointment WHERE id = ? AND created_by = userId
   → 400 nếu không tìm thấy

2. Return appointment (raw model, không có business_name)
```

#### `update(id: number, userId: number, dto: UpdateAppointmentDto)`

```
PHP update() logic:

1. Load appointment WHERE id = ? AND created_by = userId
   → 400 nếu không tìm thấy

2. UPDATE tất cả fields (không phân biệt, gán null nếu dto không có):
   name = dto.name
   email = dto.email
   phone = dto.phone
   date = dto.date
   time = dto.time
   title = dto.title
   note = dto.note

3. Return { appointment: updatedObject }
```

#### `accept(id: number, userId: number)`

```
PHP accept() logic:

1. Load appointment WHERE id = ? AND created_by = userId → 400 nếu không tìm
2. SET status = 'accepted'
3. Notify user_requested:
   - AppointmentAccepted notification
   - FCM nếu userRequested.device_token tồn tại
   - title: '{user.name} vừa chấp nhận lịch hẹn của bạn.'
4. Xóa notification trong DB: DELETE notifications WHERE type LIKE '%Appointment%' AND data->id = id
5. Return { appointment: updatedObject }
```

#### `reject(id: number, userId: number)`

```
PHP reject() logic:

1. Load appointment WHERE id = ? AND created_by = userId → 400 nếu không tìm
2. SET status = 'rejected'
3. Notify user_requested:
   - AppointmentAccepted notification (PHP dùng cùng class AppointmentAccepted cho cả reject)
   - FCM nếu userRequested.device_token tồn tại
   - title: '{user.name} vừa hủy lịch hẹn của bạn.'
4. Xóa notification trong DB (giống accept):
   DELETE notifications WHERE type LIKE '%Appointment%' AND data->id = id
5. Return { appointment: updatedObject }
```

#### `delete(id: number, userId: number)`

```
PHP delete() logic:

1. Load appointment WHERE id = ? AND created_by = userId → 400 nếu không tìm
2. DELETE appointment
3. DECREMENT business.total_appointment:
   business.total_appointment -= 1; business.save()
4. Return null (PHP: success(null, 'Xóa lịch hẹn thàng công!'))
```

#### Public appointments (Google Calendar sync)

```
addPublic(dto):
  - Required: user_id, google_calendar_id
  - INSERT với status = 'accepted' (KHÔNG phải 'pending')
  - created_by = dto.user_id (KHÔNG phải auth user)
  - Return { appointment: object }

updatePublic(dto):
  - Required: user_id, google_calendar_id
  - Find WHERE created_by = user_id AND google_calendar_id = ?
  - Update: date, time, note, title, google_calendar_id, status = 'pending'
  - Return { appointment: object }

deletePublic(dto):
  - Required: user_id, google_calendar_id
  - Find WHERE created_by = user_id AND google_calendar_id = ?
  - DELETE
  - Return null
```

---

### Bước 8: `appointments.controller.ts`

```typescript
@Controller('appointments')
@UseGuards(AuthGuard)
export class AppointmentsController {
  constructor(private readonly appointmentsService: AppointmentsService) {}

  @Get()
  getAll(@GetUser() user: any, @Query('requested') requested?: string) {
    return this.appointmentsService.getAll(user.id, requested === 'true');
  }

  @Post('add')
  add(@GetUser() user: any, @Body() dto: CreateAppointmentDto) {
    return this.appointmentsService.add(user.id, dto);
  }

  // PHẢI khai báo trước ':id'
  @Post('update/:id')
  update(
    @Param('id') id: string,
    @GetUser() user: any,
    @Body() dto: UpdateAppointmentDto,
  ) {
    return this.appointmentsService.update(+id, user.id, dto);
  }

  @Post('accept/:id')
  accept(@Param('id') id: string, @GetUser() user: any) {
    return this.appointmentsService.accept(+id, user.id);
  }

  @Post('reject/:id')
  reject(@Param('id') id: string, @GetUser() user: any) {
    return this.appointmentsService.reject(+id, user.id);
  }

  // PHẢI khai báo trước ':id' để tránh conflict với GET ':id'
  @Post('delete/:id')
  delete(@Param('id') id: string, @GetUser() user: any) {
    return this.appointmentsService.delete(+id, user.id);
  }

  @Get(':id')
  getDetail(@Param('id') id: string, @GetUser() user: any) {
    return this.appointmentsService.getDetail(+id, user.id);
  }
}

// Public appointments controller (separate controller)
@Controller('public-appointments')
export class PublicAppointmentsController {
  constructor(private readonly appointmentsService: AppointmentsService) {}

  @Post('add')
  addPublic(@Body() body: any) {
    return this.appointmentsService.addPublic(body);
  }

  @Post('update')
  updatePublic(@Body() body: any) {
    return this.appointmentsService.updatePublic(body);
  }

  @Post('delete')
  deletePublic(@Body() body: any) {
    return this.appointmentsService.deletePublic(body);
  }
}
```

---

### Bước 9: DTOs Appointments

#### `create-appointment.dto.ts`

```typescript
export const CreateAppointmentSchema = z.object({
  card_id: z.number().int().positive(),    // QUAN TRỌNG: field name là card_id (không phải business_id)
  name: z.string().optional(),
  email: z.string().email().optional(),
  phone: z.string().optional(),
  date: z.string().optional(),
  time: z.string().optional(),
  note: z.string().optional(),
  title: z.string().optional(),
});
```

#### `update-appointment.dto.ts`

```typescript
export const UpdateAppointmentSchema = z.object({
  name: z.string().optional(),
  email: z.string().optional(),
  phone: z.string().optional(),
  date: z.string().optional(),
  time: z.string().optional(),
  title: z.string().optional(),
  note: z.string().optional(),
  // KHÔNG có status — PHP update() không cho phép update status
  // status được thay đổi qua accept/reject endpoints riêng biệt
});
```

---

### Bước 10: Module declarations + AppModule

#### `businesses.module.ts`

```typescript
@Module({
  controllers: [BusinessesController],
  providers: [
    BusinessesService,
    BusinessesRepository,
    ContactInfoRepository,
    BusinessHoursRepository,
    ServicesRepository,
    TestimonialsRepository,
    SocialsRepository,
    BusinessHistoryRepository,
  ],
  exports: [BusinessesService, BusinessesRepository],
})
export class BusinessesModule {}
```

#### `appointments.module.ts`

```typescript
@Module({
  controllers: [AppointmentsController, PublicAppointmentsController],
  providers: [
    AppointmentsService,
    AppointmentsRepository,
    AppointmentConfigRepository,
    BusinessesRepository,  // Inject để load business info
  ],
  exports: [AppointmentsService],
})
export class AppointmentsModule {}
```

---

## Response Format

Chuẩn theo project: `ResponseHelper.success()` / `ResponseHelper.error()`

### GET /api/cards

```json
{
  "status": true,
  "message": "",
  "data": [
    {
      "id": 1,
      "slug": "nguyen-van-a",
      "first_name": "Nguyễn Văn",
      "last_name": "A",
      "email": "email@example.com",
      "phone": "0901234567",
      "title": "CEO",
      "company": "ACME Corp",
      "bio": "...",
      "industries": [{"id": "1", "name": "Công nghệ"}],
      "services": [],
      "need_services": [],
      "sociallinks": {},
      "social_links": [],
      "testimonials": [],
      "password": null,
      "enable_password": null,
      "logo": "https://domain.com/storage/card_logo/logo_xxx.jpg",
      "created_at": "2024 01 01 12:00:00",
      "updated_at": "2024 01 01 12:00:00",
      "total_view": 120,
      "total_scan": 30,
      "total_appointment": 5,
      "is_owner": true,
      "request_status": null,
      "profile_url": "https://domain.com/profile/nguyen-van-a",  // GET index() dùng url('profile/' + slug)
      "need_services": [],
      "profile_qr": "https://domain.com/storage/profile_qr/nguyen-van-a.png",
      "contact_qr": "https://domain.com/storage/contact_qr/nguyen-van-a.png",
      "product_services": [],
      "media": [],
      "settings": {"phone_enable": 1},
      "is_my_card": true,
      "deeplink": "https://domain.com/profile/nguyen-van-a",
      "profiles_type": "mobile",
      "main_service": null,
      "key_strength": null,
      "looking_for": null,
      "collaboration": null
    }
  ]
}
```

### GET /api/cards/:id

Response giống getAll nhưng có thêm:
```json
{
  "data": {
    "...all fields above...",
    "testimonials_is_enabled": true,
    "approved_at": null,
    "hasPhysicalCard": false,
    "is_enable_appoinment": false,
    "banner_img": null,
    "owner_id": 1,
    "tags": [],
    "connected_id": null,
    "connected_name": null
  }
}
```

### POST /api/cards (create) & POST /api/cards/update/:id

Response là **subset** (KHÔNG giống GET /api/cards/:id — thiếu profile_qr, contact_qr, deeplink, banner_img, tags, owner_id, is_my_card):
- `profile_url` dùng `url(slug)` — không có `/profile/` prefix (khác với GET /api/cards list)
- Xem chi tiết field list trong service `create()` và `update()` ở trên

### POST /api/appointments/add

```json
{
  "status": true,
  "message": "Tạo lịch hẹn thàng công!",
  "data": {
    "appointment": {
      "id": 1,
      "business_id": 5,
      "name": "Nguyễn Văn B",
      "email": "b@example.com",
      "phone": "0901234567",
      "date": "2026-03-15",
      "time": "10:00",
      "note": "...",
      "title": "...",
      "status": "pending",
      "created_by": 1,
      "user_requested": 2,
      "created_at": "...",
      "updated_at": "..."
    }
  }
}
```

### POST /api/appointments/delete/:id

```json
{
  "status": true,
  "message": "Xóa lịch hẹn thàng công!",
  "data": null
}
```

> **Lưu ý typo trong message:** PHP dùng `'thàng công!'` (thiếu dấu nh) cho tất cả appointments messages. Giữ nguyên để khớp PHP.

---

## Thứ tự Implementation

1. **Schema** — Thêm 7 tables mới + verify `businesses` / `appoinments` / `appointmentDeatails` đủ fields
2. **Repository.module.ts** — Register tất cả repositories mới
3. **Businesses repositories** — 7 repositories
4. **Businesses service + controller + DTOs** — Theo đúng business logic của `CardController`
5. **Appointments repositories** — 2 repositories
6. **Appointments service + controller + DTOs** — Theo đúng `AppointmentsController`
7. **App.module.ts** — Import 2 modules mới
8. **Test** — Dùng `ENABLE_TOKEN_BYPASS=true` + `dev_token_{userId}`

---

## Sai lệch quan trọng đã phát hiện (cần fix trong implementation)

### NestJS hiện tại vs PHP thực tế

| # | Vấn đề | PHP (Đúng) | NestJS hiện tại (Sai) | Mức độ |
|---|---|---|---|---|
| 1 | Logo/banner URL | Full URL: `asset(Storage::url('card_logo/' + filename))` | Chỉ filename | CRITICAL |
| 2 | `total_view`/`total_scan` | Đếm lại từ history table sau mỗi view, UPDATE businesses | Không increment | CRITICAL |
| 3 | Delete appointment | DECREMENT `total_appointment` sau khi xóa | Không decrement | MODERATE |
| 4 | Response của `add appointment` | `{ appointment: {...} }` (full object) | `{ appointment_id: 123 }` | MODERATE |
| 5 | `list()` filter | `requested` query param để phân loại (created vs requested) | Không có filter | MODERATE |
| 6 | `detail()` ghi history | Ghi `business_history` + recount view/scan | Không ghi history | CRITICAL |
| 7 | Field name `card_id` | Request body dùng `card_id` | `business_id` | HIGH |
| 8 | Card `delete()` ownership | Chỉ check `owner_id = userId` (không check created_by) | Không rõ | MODERATE |
| 9 | Route prefix | `/api/cards` | `/api/businesses` | HIGH |
| 10 | `accept`/`reject` endpoints | Có endpoint riêng cho accept và reject | Không có | HIGH |
| 11 | Delete appointment HTTP method | `POST /api/appointments/delete/:id` | `DELETE /api/appointments/:id` | HIGH |
| 12 | Banner upload field name | `banner_img` | `banner` | MODERATE |
| 13 | Update card không check ownership | PHP chỉ `Business::find(id)` — không check owner | Cần verify | LOW |
| 14 | reject() xóa notifications | Có `DELETE notifications WHERE type LIKE '%Appointment%'` | Không có | LOW |

---

## Quyết định kỹ thuật đã xác nhận

### 1. Slug generation

`slugify` cần install (chưa có trong package.json):
```bash
npm install slugify
```
Sử dụng: `slugify(text, { lower: true, locale: 'vi', strict: true })`
Nếu slug bị trùng → thêm số ngẫu nhiên 4 chữ số vào cuối.

### 2. File upload

Controller xử lý `multipart/form-data` với `multer` (đã có trong project).
PHP lưu file local (`storage/app/public/`). NestJS có thể dùng Google Cloud Storage hoặc local tùy cấu hình.

Logo upload path: `card_logo/` (resize 400px)
Banner upload path: `banner_img/`
Service images: `service_images/`
Media images: `media_images/`
Testimonial images: `testimonials_images/`

### 3. Default theme

```typescript
const DEFAULT_CARD_THEME = {
  theme: 'theme5',    // PHP dùng theme5 (không phải theme1)
  order: {
    appointment:    '1',
    service:        '2',
    testimonials:   '3',
    bussiness_hour: '4',   // typo khớp với PHP
    contact_info:   '5',
    more:           '6',
    custom_html:    '7',
  },
};
// theme_color default = 'color5-theme5'
```

### 4. BaseController response format

PHP `BaseController::success($data, $message)` trả về:
```json
{ "status": true, "message": "...", "data": ... }
```
PHP `BaseController::error($data, $message)` trả về:
```json
{ "status": false, "message": "...", "data": ... }
```

NestJS cần match format này qua `ResponseHelper`.

### 5. Ngoài scope

| Feature | PHP Route | Ghi chú |
|---|---|---|
| Theme editor | `POST /business/edit-theme/:id` | Phức tạp, cần UI state |
| Custom domain | `POST /business/domain-setting/:id` | Infrastructure |
| SEO settings | `POST /business/seo/:id` | Optional |
| Custom JS/CSS | `POST /business/custom-js-setting/:id` | Optional |
| Password protect | `POST /business/setpassword/:id` | Optional |
| Branding | `POST /business/setbranding/:id` | Optional |
| vCard download | `GET /download/:slug` | File generation (.vcf) |
| QR code download | `GET /businessqr/download/` | Download PNG (khác với generate on-demand — xem QR Generation section) |
| Import businesses | `POST /business/save_import` | Batch operation |
| Google Calendar sync | `GET /appointment/sync-google-calendar` | External API |
| Analytics | `GET /business/analytics/:id` | Chart data cho 15 ngày |
| Public profile page (HTML) | `GET /profile/:slug` | Web-only HTML — PHP Blade view. NestJS có JSON API tương đương: `GET /api/businesses/public/:slug` |
| checkSerialNumberOfCard | `POST /api/check-card/:cardCode` | Kiểm tra serial card vật lý |
