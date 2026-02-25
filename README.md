# CMS InCard API — Tổng quan dự án - (Public)

**Framework:** NestJS 10 + TypeScript 5
**Database:** MySQL 8 (TypeORM + Drizzle ORM)
**Port mặc định:** `3001`
**Global prefix:** `/api`
**Last Updated:** 2026-02-24

---

## Mục lục

- [Dự án làm gì?](#dự-án-làm-gì)
- [Kiến trúc tổng thể](#kiến-trúc-tổng-thể)
- [Modules](#modules)
  - [Auth](#auth-module)
  - [Users](#users-module)
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

Gửi email hàng loạt qua **Nodemailer + SMTP**, với hệ thống template đa ngôn ngữ dùng chung DB với `incard-biz`.

**Tính năng:**
- Gửi đến tất cả user hoặc lọc theo: user ID, email, loại tài khoản, ngày đăng ký
- Nội dung: nhập tay tự do, hoặc lấy từ template có sẵn (VI/EN), hoặc kết hợp (override subject/body)
- CRUD template: `email_templates` + `email_template_langs` (bảng chung với incard-biz)
- Trả về kết quả chi tiết: `{ total, success, failed, failed_emails[] }`

**Endpoints:** `POST /api/emails/send`, CRUD `/api/emails/templates/*`

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

Thư mục `uploads/` được serve tại `/uploads/*` qua `ServeStaticModule`. Cache-Control: 1 năm.

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
| `businesses` | Users | Business cards của user |
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

# Firebase (FCM Push Notification)
FIREBASE_CREDENTIALS=your-firebase-adminsdk-credentials.json

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
| [EMAIL_API.md](./EMAIL_API.md) | Email Module — gửi email hàng loạt, quản lý template, filter recipients |
| [NEWS_FEED_MANAGEMENT_API.md](./NEWS_FEED_MANAGEMENT_API.md) | Activities Module — quản lý bài đăng, approval workflow, GetStream sync |
| [FCM_NOTIFICATION_SYSTEM.md](./FCM_NOTIFICATION_SYSTEM.md) | Notification Module — push notification qua Firebase, Bull Queue architecture |
| [USER_MANAGEMENT_API.md](./USER_MANAGEMENT_API.md) | Users Module — CRUD user, impersonation, export, plan management |
| [PHP_CREATE_USER_LOGIC.md](./PHP_CREATE_USER_LOGIC.md) | Reference — business logic tạo user từ Laravel incard-biz (để so sánh migration) |

### Postman Collections

| File | Module |
|---|---|
| [../InCard_Email_API.postman_collection.json](../InCard_Email_API.postman_collection.json) | Email API — send bulk email, template CRUD |

### Tài liệu ngoài

| Link | Mô tả |
|---|---|
| [NestJS Docs](https://docs.nestjs.com) | Framework chính |
| [TypeORM Docs](https://typeorm.io) | ORM |
| [Bull Queue Docs](https://docs.bullmq.io) | Queue system |
| [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup) | FCM push notification |
| [GetStream Docs](https://getstream.io/docs) | Social feed |
