# CMS InCard API — Tổng quan dự án - (Public)

**Framework:** NestJS 10 + TypeScript 5
**Database:** MySQL 8 (TypeORM + Drizzle ORM)
**Port mặc định:** `3001`
**Global prefix:** `/api`
**Last Updated:** 2026-03-05

---

## Mục lục

- [Dự án làm gì?](#dự-án-làm-gì)
- [Kiến trúc tổng thể](#kiến-trúc-tổng-thể)
- [Modules](#modules)
  - [Auth](#auth-module)
  - [Users](#users-module)
  - [Business Cards](#business-cards-module)
  - [Appointments](#appointments-module)
  - [Activities (News Feed)](#activities-module)
  - [Notifications (FCM)](#notifications-module)
  - [Email](#email-module)
  - [Comments & Likes](#comments--likes-module)
  - [Dashboard & Analytics](#dashboard--analytics-module)
  - [GetStream](#getstream-module)
  - [Object Storage](#object-storage-module)
  - [Data Sync & Cleanup](#data-sync--cleanup-module)
- [Infrastructure](#infrastructure)
- [Authentication & Authorization](#authentication--authorization)
- [Database Schema (tóm tắt)](#database-schema-tóm-tắt)
- [Environment Variables](#environment-variables)
- [Chạy dự án](#chạy-dự-án)
- [Testing](#testing)
- [References](#references)

---

## Dự án làm gì?

**CMS InCard API** là backend CMS (Content Management System) cho nền tảng InCard — hệ thống kết nối doanh nghiệp và cá nhân tại Việt Nam. Dự án này là bản **migration từ Laravel PHP (`incard-biz`)** sang NestJS, chạy song song với hệ thống cũ và dùng chung cùng một MySQL database.

### Các chức năng chính

| Chức năng | Mô tả |
|---|---|
| **Quản lý bài đăng (Activities)** | Admin duyệt/từ chối bài đăng của user; đồng bộ lên GetStream social feed |
| **Push Notification (FCM)** | Tự động gửi push notification đến mobile app khi bài đăng được duyệt |
| **Gửi Email hàng loạt** | Admin gửi email đến user theo nhiều điều kiện lọc; quản lý template đa ngôn ngữ |
| **Quản lý User** | CRUD user, phân quyền, impersonation, export Excel, quản lý QR code |
| **Dashboard & Analytics** | Thống kê hoạt động, dữ liệu analytics |
| **Social Feed (GetStream)** | Tích hợp GetStream.io để quản lý news feed, comments, likes |
| **Object Storage** | Upload và quản lý file qua Google Cloud Storage |

---

## Kiến trúc tổng thể

```
Client (CMS Admin)
      │
      ▼ HTTP/REST
┌─────────────────────────────────┐
│        NestJS API (:3001)       │
│  Global prefix: /api            │
│  Guards: AuthGuard + AdminGuard │
└────────────┬────────────────────┘
             │
    ┌────────┼──────────┐
    ▼        ▼          ▼
  MySQL    Redis      External Services
  (TypeORM) (Bull Queue) ├── Firebase FCM (push notif)
             │           ├── GetStream.io (social feed)
             ▼           ├── Google Cloud Storage (files)
        Background      └── SMTP/Mailgun (email)
          Workers
     (FCM processors)
```

### Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | NestJS 10, Express |
| **Language** | TypeScript 5.6 |
| **Database** | MySQL 8 — TypeORM 0.3 + Drizzle ORM 0.39 |
| **Queue** | Bull 4 (Redis-backed) |
| **Push Notification** | Firebase Admin SDK 13 (FCM) |
| **Social Feed** | GetStream.io SDK 8 |
| **Email** | Nodemailer (SMTP) |
| **File Storage** | Google Cloud Storage |
| **Auth** | JWT (jsonwebtoken) + Passport |
| **Validation** | class-validator, class-transformer, Zod |
| **Testing** | Jest 30, ts-jest |

---

## Modules

### Auth Module

**Path:** `src/modules/auth/`
**Global:** Có (inject được toàn app)

Xử lý xác thực JWT cho toàn bộ hệ thống. Cung cấp `AuthGuard` (kiểm tra Bearer token) và `AdminGuard` (kiểm tra quyền admin/super admin).

**Endpoints:**
```
POST /api/auth/login   — Đăng nhập, trả về JWT token
```

**User types được hỗ trợ:** `user`, `admin`, `super admin`

---

### Users Module

**Path:** `src/modules/users/`

Quản lý toàn bộ vòng đời user: tạo, sửa, xóa, phân quyền, impersonation, xuất dữ liệu.

**Các tính năng nổi bật:**
- CRUD user với cascade delete (xóa user → xóa businesses, QR codes)
- **Impersonation:** Admin đăng nhập thay thế user để debug/hỗ trợ
- Export danh sách user ra Excel (`[No, Id, Name, Email]`)
- Export QR code dạng SVG
- Quản lý plan/subscription của user
- Quản lý contact và lịch hẹn (appointments)

**Repositories:** `UsersRepository`, `PlansRepository`, `ContactsRepository`, `AppoinmentsRepository`, `QrcodeRepository`, `BusinessRepository`

---

### Business Cards Module

**Path:** `src/modules/businesses/`
**Reference PHP:** `CardController.php`, `BusinessController.php`

Quản lý toàn bộ vòng đời business card (danh thiếp số) của user: tạo, cập nhật, xóa, gắn NFC card vật lý, generate QR code PNG, deeplink.

**Tính năng nổi bật:**
- CRUD business card với logo upload (multipart)
- **QR PNG on-demand:** `profile_qr` (500×500, encode profile URL) và `contact_qr` (800×800, encode vCard VCF) được generate khi `GET /api/cards` hoặc `GET /api/cards/:id`, file lưu tại `storage/app/public/{type}/{slug}.png`
- **Track view/scan:** Mỗi lần xem `GET /api/cards/:id` ghi `business_history` type `view` + increment `total_view`. Nếu `?fromScan=1` thì ghi thêm type `scan` + increment `total_scan` + tạo `contact_requets` type `recent` nếu scan card người khác
- **Link NFC card:** Gắn physical QR card (serial code) vào business card, reset `deep_link` để force regenerate QR. Fallback: tự động link physical card khi tạo card mới
- **Firebase Dynamic Link:** `POST /api/cards/:id/generate-deeplink` tạo short URL qua Firebase API, lưu vào `deep_link_firebase` — dùng để redirect vào mobile app
- **Public profile:** `GET /api/businesses/public/:slug` cho FE Web, không cần auth, tự track view/scan, trả `deep_link_firebase`
- **Check card (public):** `POST /api/check-card/:cardCode` — public, không cần auth, kiểm tra trạng thái NFC serial trước khi link
- **Card webhook:** Sau create/update/delete gọi `CARD_WEBHOOK_URL` (fire and forget) để trigger AI embedding

**Controllers:** `BusinessesController` (`/api/cards`), `CheckCardController` (`/api/check-card` — public), `BusinessesPublicController` (`/api/businesses`)

**Static files:** `storage/app/public/` được serve tại `/storage` prefix

**Tài liệu chi tiết:** [BUSINESS_API_REFERENCE.md](./BUSINESS_API_REFERENCE.md)

---

### Appointments Module

**Path:** `src/modules/appointments/`
**Reference PHP:** `AppointmentsController.php`

Quản lý lịch hẹn giữa chủ business card (người nhận) và user đặt lịch (người gửi).

**Tính năng nổi bật:**
- Đặt lịch hẹn với chủ card: ghi `business_history` type `booked`, increment `total_appointment`, gửi FCM push notification đến chủ card
- Chủ card accept/reject: gửi FCM push notification ngược lại cho người đặt, xóa notifications liên quan
- **Public appointments:** Webhook cho Google Calendar sync (không cần auth) — tạo/update/xóa appointment theo `google_calendar_id`
- Response hoàn toàn snake_case, `created_at`/`updated_at` format PHP `"YYYY MM DD HH:mm:ss"`

**Controllers:** `AppointmentsController` (`/api/appointments`), `PublicAppointmentsController` (`/api/public-appointments`)

**Tài liệu chi tiết:** [APPOINTMENT_API_REFERENCE.md](./APPOINTMENT_API_REFERENCE.md)

---

### Activities Module

**Path:** `src/modules/activities/`

Quản lý bài đăng (news feed) trên nền tảng InCard. Đây là module core của CMS.

**Business logic quan trọng:**
- **Regular user** tạo bài → tự động `Approved` → đồng bộ lên GetStream ngay
- **Super admin** tạo bài → trạng thái `Pending` → cần admin duyệt → mới lên GetStream
- Khi duyệt bài → trigger FCM notification đến mobile users (background job)

**Luồng trạng thái:**
```
Regular User: Create → Approved → GetStream → FCM push
Super Admin:  Create → Pending → [Admin approve] → Approved → GetStream → FCM push
                                 [Admin reject]  → Rejected
```

**Hai controller:**
- `ActivitiesController` — `/api/external/*` — yêu cầu JWT
- `ActivitiesPublicController` — `/api/public-feeds/*` — public, không cần auth

---

### Notifications Module

**Path:** `src/modules/notifications/`

Hệ thống push notification qua **Firebase Cloud Messaging (FCM)**, chạy hoàn toàn **background** qua Bull Queue — không có endpoint HTTP.

**Luồng hoạt động:**
```
Bài đăng được duyệt
  → NotificationService.dispatch() → Redis Queue
    → ActivityApprovedProcessor (xác định recipients)
      → Chunk 100 users/job → ActivityApprovedChunkProcessor
        → Group by language (vi/en)
        → FcmService.sendBatchNotifications() (50 tokens/FCM batch)
        → Lưu DB notifications table
        → Tăng users.notification_num
```

**Chiến lược gửi:**
- **Super admin post:** Gửi đến TẤT CẢ user có `device_token`
- **Regular user post:** Gửi đến contacts của user đó (fallback: chỉ owner)

**Performance:** 100 users/chunk × 50 tokens/FCM batch, retry 3 lần với exponential backoff

---

### Email Module

**Path:** `src/modules/email/`

Gửi email hàng loạt qua **Nodemailer + SMTP**, với hệ thống **campaign tracking (Phase A/B), unsubscribe management, và scheduled sending (Phase C)** — dùng chung DB template với `incard-biz`.

**Tính năng:**
- **Phase A** — Campaign History & Unsubscribe:
  - Auto-create campaign record + thống kê (total, success, failed, open_count, click_count)
  - ✅ **Custom campaign name** (hoặc fallback `"Email Campaign - YYYY-MM-DD"`)
  - HMAC-SHA256 unsubscribe tokens + stateless verification
  - Auto-inject GDPR unsubscribe footer vào email
  - Blacklist filtering (skip unsubscribed emails)

- **Phase B** — Email Tracking:
  - Open tracking via transparent 1×1 GIF pixel
  - Click tracking via transparent redirect
  - Deduplication (1 open/email, multiple clicks allowed)
  - Analytics endpoint: open_rate, click_rate, top URLs

- **Phase C** — Email Scheduling:
  - Schedule campaigns cho thời điểm tương lai (Bull Queue + Redis)
  - Idempotent execution (atomic status check, email không gửi 2 lần)
  - Cancel anytime (trước khi thực thi)
  - Startup reconciliation (auto re-queue nếu Redis restart)

- **✅ Image Support**:
  - Inject ảnh từ URL (public CDN)
  - Auto-inject vào body trước `</body>` tag
  - 100% compatible (mọi email client support)
  - Hỗ trợ cả scheduled campaigns

- **Phase F** — Analytics Dashboard (NEW):
  - Single endpoint: `GET /api/emails/analytics/dashboard`
  - 6 metrics: subscribers, campaigns_sent, emails_sent, open_rate, click_rate, bounce_rate
  - Optional date filtering (ISO 8601)
  - Realtime aggregation từ campaign records

- **Phase G** — Template Personalization (NEW):
  - Dynamic variables: `{{user.name}}`, `{{user.plan}}`, `{{user.subscription}}`, `{{user.email}}`, `{{user.first_name}}`, `{{unsubscribe_url}}`
  - Preview endpoint: `POST /api/emails/preview`
  - Personalization in send: mỗi recipient nhận custom content
  - Batch-fetch optimization: 1 DB query cho 10,000 recipients (không N+1)
  - Silent fallback: unknown variables → empty string

**Gửi email:** Đến tất cả user hoặc lọc theo user ID, email, loại tài khoản, ngày đăng ký
**Template:** CRUD `email_templates` + `email_template_langs` (VI/EN) + variables
**Personalization:** Variables automatically resolved per recipient
**Analytics:** 6 metrics aggregate từ campaign history
**Images:** URL images (inject trực tiếp, best practice)

**Endpoints:** `POST /api/emails/send`, `POST /api/emails/preview` (Phase G), `GET /api/emails/analytics/dashboard` (Phase F), CRUD `/api/emails/templates/*`, `POST /api/emails/schedule`, `DELETE /api/emails/schedule/:id`, `GET /api/emails/campaigns/*`, `GET /api/emails/tracking/*`, `GET /api/unsubscribe/*`

**Tài liệu chi tiết:** [EMAIL_CAMPAIGN_API.md](./EMAIL_CAMPAIGN_API.md) (Phase A/B/C) | [EMAIL_API.md](./EMAIL_API.md) (Phase F/G + basic send) | [PHASE_F_G_ENDPOINTS.json](./PHASE_F_G_ENDPOINTS.json) (API spec) | [PHASE_F_G_POSTMAN.json](./PHASE_F_G_POSTMAN.json) (Ready-to-import)

---

### Comments & Likes Module

**Path:** `src/modules/comments/`, `src/modules/likes/`

Quản lý comment và like trên các bài đăng, tích hợp với GetStream social feed.

---

### Dashboard & Analytics Module

**Path:** `src/modules/dashboard/`, `src/modules/analytics/`

Cung cấp dữ liệu thống kê và analytics cho CMS admin dashboard.

---

### GetStream Module

**Path:** `src/modules/getstream/`
**Global:** Có (inject được toàn app)

Wrapper cho GetStream.io SDK — quản lý social feed (tạo user feed, publish/update/delete activity, lấy token cho client).

---

### Object Storage Module

**Path:** `src/modules/object-storage/`

Upload và quản lý file (ảnh, document) lên Google Cloud Storage. Cung cấp static file serving qua `/uploads/`.

---

### Data Sync & Cleanup Module

**Path:** `src/modules/data-sync/`, `src/modules/cleanup/`

- **Data Sync:** Đồng bộ dữ liệu từ `incard-biz` sang CMS
- **Cleanup:** Dọn dẹp dữ liệu cũ, orphan records

---

## Infrastructure

### Queue System (Bull + Redis)

```
Redis (:6379)
└── Queue: "notifications"
    ├── Job: activity-approved        → ActivityApprovedProcessor
    └── Job: activity-approved-chunk  → ActivityApprovedChunkProcessor
```

Cấu hình retry: 3 lần, exponential backoff bắt đầu từ 2000ms.

### Static Files

- Thư mục `uploads/` được serve tại `/uploads/*` qua `ServeStaticModule`. Cache-Control: 1 năm.
- Thư mục `storage/app/public/` được serve tại `/storage/*` qua `app.useStaticAssets()` (NestExpressApplication). Dùng cho QR code PNG và card assets.

### Bull Board (Queue Monitor)

Admin UI để monitor Bull Queue, truy cập tại `/api/queues` (nếu được bật).

---

## Authentication & Authorization

### Flow xác thực

```
Request → AuthGuard (check Bearer JWT) → set req.user
       → AdminGuard (check req.user.type) → allow/deny
```

### Guards

| Guard | Điều kiện pass | Lỗi |
|---|---|---|
| `AuthGuard` | Bearer token hợp lệ, chưa expired | `401 Unauthorized` |
| `AdminGuard` | `user.type` là `admin` hoặc `super admin` | `403 Forbidden` |
| `OptionalAuthGuard` | Luôn pass, nhưng attach user nếu có token | — |

### Dev mode

Đặt `ENABLE_TOKEN_BYPASS=true` + `NODE_ENV=development` để bypass JWT (dùng khi develop local).

---

## Database Schema (tóm tắt)

Dùng chung MySQL database với `incard-biz`. Không dùng `synchronize: true` — mọi schema change phải qua migration.

| Bảng | Module | Mô tả |
|---|---|---|
| `users` | Users | User accounts, device_token, lang, notification_num |
| `businesses` | Business Cards | Business cards — title, slug, deep_link, deep_link_firebase, total_view/scan/appointment, password, enable_password |
| `contact_infos` | Business Cards | Email, phone, Whatsapp của mỗi card (JSON content) |
| `social` | Business Cards | Social links của card (JSON: `[{"Platform":"url","id":0}]`) |
| `services` | Business Cards | Product services và media của card (type: `service`\|`media`) |
| `testimonials` | Business Cards | Testimonials của card |
| `business_hours` | Business Cards | Giờ làm việc của card |
| `business_histories` | Business Cards | Lịch sử view/scan/booked (type: `view`\|`scan`\|`booked`) |
| `qrcode_generated` | Business Cards | Physical NFC card serials (code, business_id, user_id) |
| `appointment_deatails` | Appointments | Lịch hẹn (typo trong tên bảng — giữ nguyên) |
| `contact_requets` | Business Cards | Yêu cầu kết nối (typo — giữ nguyên): status `requested`\|`approved`\|`rejected` |
| `user_activities` | Activities | Bài đăng (Pending/Approved/Rejected) |
| `notifications` | Notifications | Lịch sử push notification (UUID PK) |
| `email_templates` | Email | Template header (name, from, created_by) |
| `email_template_langs` | Email | Nội dung template theo ngôn ngữ (vi, en) |
| `industry_categories` | Activities | Danh mục ngành nghề |
| `service_categories` | Activities | Danh mục dịch vụ |

---

## Environment Variables

Tham khảo file `.env.example` để xem đầy đủ. Các biến quan trọng:

```env
# Server
NODE_ENV=development
PORT=3001

# Database (MySQL — dùng chung với incard-biz)
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USERNAME=root
MYSQL_PASSWORD=
MYSQL_DATABASE=your_database_name

# Auth
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=24h
ENABLE_TOKEN_BYPASS=true        # Dev only

# Redis (Bull Queue)
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_PASSWORD=null

# Firebase (FCM Push Notification + Dynamic Links)
FIREBASE_CREDENTIALS=your-firebase-adminsdk-credentials.json
FIREBASE_API_KEY=AIzaSy...                # Firebase Web API Key (cho Dynamic Links)
APP_ENV=staging                           # staging | development | production (ảnh hưởng Firebase bundle ID)

# GetStream (Social Feed)
GETSTREAM_API_KEY=your_api_key
GETSTREAM_API_SECRET=your_api_secret

# Email (SMTP)
MAIL_HOST=smtp.mailgun.org
MAIL_PORT=587
MAIL_ENCRYPTION=tls
MAIL_USERNAME=your_username
MAIL_PASSWORD=your_password
MAIL_FROM_ADDRESS=noreply@incard.vn
MAIL_FROM_NAME=InCard

# Business Cards
APP_URL=https://stage.incard.biz          # Base URL cho profile_url, QR, banner
CARD_WEBHOOK_URL=https://...              # Webhook sau create/update/delete card (AI embedding)

# CORS
CORS_ORIGIN=*
```

---

## Chạy dự án

### Yêu cầu

- Node.js 18+
- MySQL 8 (kết nối chung với `incard-biz`)
- Redis (cho Bull Queue)
- Firebase credentials file (cho FCM)

### Cài đặt

```bash
npm install
```

### Development

```bash
npm run start:dev
```

### Production

```bash
npm run build
npm run start:prod
```

### Docker

Xem hướng dẫn trong:
- [DOCKER_GUIDE.md](../DOCKER_GUIDE.md)
- [DOCKER_QUICKSTART.md](../DOCKER_QUICKSTART.md)

---

## Testing

```bash
# Chạy tất cả tests
npm test

# Chạy test theo module
npx jest --testPathPatterns="email"
npx jest --testPathPatterns="notifications"
npx jest --testPathPatterns="users"

# Chạy với coverage
npm test -- --coverage
```

### Kết quả hiện tại

| Module | Test file | Tests |
|---|---|---|
| Business Cards Service | `businesses/__tests__/businesses.service.spec.ts` | 32 |
| Appointments Service | `appointments/__tests__/appointments.service.spec.ts` | 32 |
| Email Service | `email/__tests__/email.service.spec.ts` | 26 |
| Email Controller | `email/__tests__/email.controller.spec.ts` | 18 |
| Notification Service | `notifications/__tests__/notification.service.spec.ts` | 8 |
| FCM Service | `notifications/__tests__/fcm.service.spec.ts` | 4 |
| Users Service | `users/users.service.spec.ts` | — |

---

## References

### Tài liệu chi tiết theo module

| Tài liệu | Mô tả |
|---|---|
| [Business Card API](https://github.com/devinapps/public-folder/blob/main/BUSINESS_API_REFERENCE.md) | Business cards — CRUD, QR generation, deeplink, track view/scan, Firebase Dynamic Link |
| [Appointment API](https://github.com/devinapps/public-folder/blob/main/APPOINTMENT_API_REFERENCE.md) | Appointments — đặt lịch, accept/reject, FCM notification, Google Calendar sync |
| [Email API](./EMAIL_API.md) | Email — basic send + templates (send, CRUD templates) |
| [Email Campaign API](./EMAIL_CAMPAIGN_API.md) | **⭐ NEW** — Campaign tracking (A), email tracking (B), scheduling (C) — tổng hợp Phase A/B/C |
| [Activities Module](https://github.com/devinapps/public-folder/blob/main/NEWS_FEED_MANAGEMENT_API.md) | Activities — quản lý bài đăng, approval workflow, GetStream sync |
| [Notification Module](https://github.com/devinapps/public-folder/blob/main/FCM_NOTIFICATION_SYSTEM.md) | Notifications — push notification qua Firebase, Bull Queue architecture |
| [Users Module](https://github.com/devinapps/public-folder/blob/main/USER_MANAGEMENT_API.md) | Users — CRUD user, impersonation, export, plan management |
| [PHP Reference](https://github.com/devinapps/public-folder/blob/main/PHP_CREATE_USER_LOGIC.md) | Reference — business logic tạo user từ Laravel incard-biz (để so sánh migration) |

### Postman Collections

| File | Module |
|---|---|
| [./user-profiles-update.json](./user-profiles-update.json) | Business Cards & Appointments — CRUD, QR, NFC link, check-card, appointments |
| [../InCard_Email_API.postman_collection.json](../InCard_Email_API.postman_collection.json) | Email API — send bulk email, template CRUD |

### Tài liệu ngoài

| Link | Mô tả |
|---|---|
| [NestJS Docs](https://docs.nestjs.com) | Framework chính |
| [TypeORM Docs](https://typeorm.io) | ORM |
| [Bull Queue Docs](https://docs.bullmq.io) | Queue system |
| [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup) | FCM push notification |
| [GetStream Docs](https://getstream.io/docs) | Social feed |
