# News & Feed Management API Documentation

**Version:** 3.0.0
**Base URL:** `http://localhost:3001/api`
**Authentication:** JWT Bearer Token (trừ public endpoints)
**Last Updated:** 2026-03-30

---

## Changelog

| Version | Date | Summary |
|---------|------|---------|
| 3.0.0 | 2026-03-30 | Thêm `POST /external/feeds/get-user-token`; fix actor format `SU:{getstreamUserId}`; fix `getstreamUserId` generation; document auto-createUser flow; fix `updateUser` GetStream sync; thêm `per_page` alias |
| 2.0.1 | 2026-02-11 | Public Controller separation (`ActivitiesPublicController`) |
| 2.0.0 | 2026-02-11 | Phase 1-5: 5 endpoints mới, fix paths, merge duplicates |
| 1.0.0 | — | Initial implementation |

---

## Table of Contents

- [Architecture](#architecture)
- [Authentication](#authentication)
- [Quick Reference](#quick-reference)
- [Error Handling](#error-handling)
- [Data Models](#data-models)
- [API Endpoints](#api-endpoints)
  - [GetStream Token](#getstream-token)
  - [My Activities](#my-activities)
  - [Activity Management](#activity-management)
  - [Admin Dashboard](#admin-dashboard)
  - [Admin Approval Workflow](#admin-approval-workflow)
  - [Admin Direct Operations](#admin-direct-operations)
  - [Public Endpoints (No Auth)](#public-endpoints-no-auth)
- [Workflow](#workflow)
- [GetStream Integration](#getstream-integration)

---

## Architecture

### Controller Structure

| Controller | Prefix | Auth | File |
|------------|--------|------|------|
| `FeedsController` | `external/feeds` | ✅ JWT | `getstream/feeds.controller.ts` |
| `ActivitiesController` | `external` | ✅ JWT | `activities/activities.controller.ts` |
| `ActivitiesPublicController` | `public-feeds` | ⭕ None | `activities/activities-public.controller.ts` |
| `GetstreamController` | `getstream` | ⭕ None | `getstream/getstream.controller.ts` *(debug/status)* |

### Module Dependencies

```
GetstreamModule (@Global)
  ├── GetstreamService          ← createUserToken, getOrCreateUserToken, createUser, update_user...
  ├── UsersRepository           ← save getstreamUserId + getstreamToken to DB
  ├── FeedsController           ← POST /external/feeds/get-user-token
  ├── GetstreamController       ← GET /getstream/status, GET /getstream/feeds/:slug/:id (debug)
  └── GetstreamStatusController ← GET /getstream-status/* (health checks)

ActivitiesModule
  ├── ActivitiesService         ← business logic, uses GetstreamService (injected via @Global)
  ├── ActivitiesController      ← /external/db-feeds/activities/*
  └── ActivitiesPublicController← /public-feeds/activities/*
```

---

## Authentication

### Required Headers
```http
Authorization: Bearer <your-jwt-token>
Content-Type: application/json
# or for file uploads:
Content-Type: multipart/form-data
```

### Public Endpoints (No Auth)
```http
GET /api/public-feeds/activities
GET /api/public-feeds/activities/:id
```

### User Types & Access Control

| Feature | Regular User | Super Admin |
|---------|-------------|-------------|
| Get GetStream token | ✅ | ✅ |
| Create Activity | ✅ Auto-approved + GetStream | ✅ Pending approval |
| Update Activity (DB) | ✅ Own only | ✅ Own only |
| User-Update (DB + GetStream) | ✅ Own only | ✅ Own only |
| Delete Activity | ✅ Own only | ✅ Any |
| Approve / Reject | ❌ | ✅ Admin only |
| Direct Status Update | ❌ | ✅ Admin only |
| Dashboard (all activities) | Own only | All non-admin |
| Public Endpoints | ✅ Anyone | ✅ Anyone |

---

## Quick Reference

### Full Endpoint List (15 Total)

| # | Method | Full Path | Auth | Description |
|---|--------|-----------|------|-------------|
| **GETSTREAM TOKEN** | | | | |
| 1 | POST | `/api/external/feeds/get-user-token` | ✅ | Lấy/tạo GetStream token |
| **MY ACTIVITIES** | | | | |
| 2 | GET | `/api/external/db-feeds/activities/post` | ✅ | Own activities (all users) |
| **ACTIVITY MANAGEMENT** | | | | |
| 3 | POST | `/api/external/db-feeds/activities/create` | ✅ | Create (auto-approval logic) |
| 4 | POST | `/api/external/db-feeds/activities/update` | ✅ | Update DB only, no GetStream |
| 5 | POST | `/api/external/db-feeds/activities/user-update/:id` | ✅ | Update + sync GetStream |
| 6 | GET | `/api/external/db-feeds/activities/:id` | ✅ | Detail by DB ID |
| 7 | POST | `/api/external/db-feeds/activities/delete` | ✅ | Delete (owner/admin) |
| **ADMIN DASHBOARD** | | | | |
| 8 | GET | `/api/external/db-feeds/activities` | ✅ | Dashboard với logic per role |
| 9 | GET | `/api/external/activities` | 🔒 Admin | Feed management (legacy) |
| **ADMIN APPROVAL WORKFLOW** | | | | |
| 10 | POST | `/api/external/db-feeds/activities/approve` | 🔒 Admin | Approve → GetStream + FCM |
| 11 | POST | `/api/external/db-feeds/activities/reject` | 🔒 Admin | Reject + lưu reason |
| **ADMIN DIRECT OPERATIONS** | | | | |
| 12 | POST | `/api/external/db-feeds/activities/update-status` | 🔒 Admin | Direct status (no workflow) |
| **PUBLIC (NO AUTH)** | | | | |
| 13 | GET | `/api/public-feeds/activities` | ⭕ Public | Approved only |
| 14 | GET | `/api/public-feeds/activities/:id` | ⭕ Public | Detail + expanded fields |

**Legend:** ✅ = Authenticated | 🔒 = Admin only | ⭕ = Public (no auth)

---

## Error Handling

### Standard Response Format
```json
// Success
{
  "status": true,
  "message": "...",
  "data": { ... }
}

// Error
{
  "status": false,
  "message": "Thông báo lỗi tiếng Việt",
  "data": null
}
```

### HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK |
| 400 | Bad Request — validation errors |
| 401 | Unauthorized — missing/invalid JWT |
| 403 | Forbidden — admin access required |
| 404 | Not Found |
| 500 | Internal Server Error |

---

## Data Models

### UserActivity Entity

```typescript
{
  id: number,
  user_id: number,
  title?: string,                    // Tiếng Việt (optional)
  content: string,                   // Tiếng Việt (required)
  title_en?: string,
  content_en?: string,
  industries?: IndustryItem[],       // [{ id, name }]
  services?: ServiceItem[],          // [{ id, name }]
  file_uri?: string,
  activity_data?: ActivityDataStructure,
  status: 'Pending' | 'Approved' | 'Rejected',
  notes?: string,                    // Rejection reason
  source: 'admin_created' | 'ai_auto_generated',
  approved_by?: number,
  approved_at?: Date,
  rejected_by?: number,
  rejected_at?: Date,
  getstream_activity_id?: string,    // UUID from GetStream
  created_at: Date,
  updated_at: Date
}
```

### Activity Status Flow

```
Regular User:  Create → Approved → pushed to GetStream immediately
Super Admin:   Create → Pending → Approve → Approved → pushed to GetStream
                                 → Reject  → Rejected (never pushed)
```

---

## API Endpoints

---

## GetStream Token

### 1. POST /external/feeds/get-user-token
**Lấy GetStream JWT token cho mobile app**

**Endpoint:** `POST /api/external/feeds/get-user-token`
**PHP Equivalent:** `POST /api/user/feeds/get-user-token`
**Authentication:** ✅ Required
**Request Body:** *(none)*

**Logic:**
1. Nếu user chưa có `getstream_user_id` trong DB → auto-create user trên GetStream
   - `getstreamUserId` = `filterEmailString(email)_userId`
   - Ví dụ: email `bxthuan@gmail.com`, id `2` → `bxthuangmailcom_2`
2. Tạo JWT token bằng `client.createUserToken(getstreamUserId)` *(local, synchronous, không gọi network)*
3. Lưu `getstreamToken` và `getstreamUserId` vào `users` table
4. Trả về token

**Request Example:**
```http
POST /api/external/feeds/get-user-token
Authorization: Bearer <jwt-token>
```

**Success Response:**
```json
{
  "status": true,
  "message": "",
  "data": {
    "getstream_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Error Response:**
```json
{
  "status": false,
  "message": "Không thể tạo GetStream token: ...",
  "data": null
}
```

> **Note:** Token không có expiry (không dùng `expireTokens` option) — khớp với behavior PHP. Token vẫn valid kể cả DB save fails (non-fatal).

---

## My Activities

### 2. GET /db-feeds/activities/post
**Xem danh sách activity của chính mình**

**Endpoint:** `GET /api/external/db-feeds/activities/post`
**Authentication:** ✅ Required

**Business Logic:**
- Tất cả user types (kể cả super admin) chỉ thấy activity của **chính mình**
- Dùng cho "My Activities" page
- Dùng endpoint #8 cho admin dashboard

**Query Parameters:**
```
page?        number   Default: 1
limit?       number   Default: 10
per_page?    number   Alias cho limit (PHP compat)
status?      string   Comma-separated: "Pending,Approved,Rejected"
source?      string   "admin_created" | "ai_auto_generated"
```

**Request Example:**
```http
GET /api/external/db-feeds/activities/post?page=1&limit=10&status=Approved
Authorization: Bearer <token>
```

**Success Response:**
```json
{
  "status": true,
  "message": "Lấy danh sách hoạt động thành công",
  "data": {
    "current_page": 1,
    "data": [...],
    "last_page": 5,
    "total": 42,
    "per_page": 10
  }
}
```

**PHP Reference:** `DatabaseFeedController@getAdminActivities`

---

## Activity Management

### 3. POST /db-feeds/activities/create
**Tạo activity mới**

**Endpoint:** `POST /api/external/db-feeds/activities/create`
**Authentication:** ✅ Required
**Content-Type:** `multipart/form-data`

**Request Body:**
```
content       string    Required
title?        string    Tiêu đề tiếng Việt
content_en?   string    Nội dung tiếng Anh
title_en?     string    Tiêu đề tiếng Anh
industries?   number[]  Industry IDs — JSON array string, e.g. "[1,3]"
services?     number[]  Service IDs — JSON array string
file?         File      Image/document upload
notes?        string    Internal notes
source?       string    Default: "admin_created"
```

**Auto-create GetStream User Flow (NEW in v3.0.0):**
```
Nếu user.getstream_user_id không có trong DB:
  → getstreamUserId = filterEmailString(email) + '_' + id
  → createUser(getstreamUserId, { first_name, last_name, email, avatar, company, name })
  → lưu getstreamUserId về users table
  → tiếp tục createActivity (không fail nếu step này lỗi)
```

**Auto-Approval Logic:**
```
Regular user  → status = Approved  → pushed to GetStream immediately
Super admin   → status = Pending   → chờ admin approve
```

**actor format trên GetStream:** `SU:{getstreamUserId}` (e.g., `SU:bxthuangmailcom_2`)

**Request Example:**
```javascript
const formData = new FormData();
formData.append('content', 'Nội dung hoạt động');
formData.append('title', 'Tiêu đề');
formData.append('industries', JSON.stringify([1, 3]));
formData.append('file', fileInput.files[0]);

await fetch('/api/external/db-feeds/activities/create', {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${token}` },
  body: formData
});
```

**PHP Reference:** `DatabaseFeedController@createActivity`

---

### 4. POST /db-feeds/activities/update
**Cập nhật activity (DB only, không sync GetStream)**

**Endpoint:** `POST /api/external/db-feeds/activities/update`
**Authentication:** ✅ Required (owner only)
**Content-Type:** `multipart/form-data`

**Request Body:**
```
activity_id   number    Required
title?        string
content?      string
title_en?     string
content_en?   string
industries?   number[]
services?     number[]
file?         File
```

> Không sync GetStream. Dùng endpoint #5 nếu cần sync.

**PHP Reference:** `DatabaseFeedController@updateActivity`

---

### 5. POST /db-feeds/activities/user-update/:getstream_activity_id
**Cập nhật activity + sync GetStream**

**Endpoint:** `POST /api/external/db-feeds/activities/user-update/:getstream_activity_id`
**Authentication:** ✅ Required (owner only)
**Content-Type:** `multipart/form-data`

**Path Parameter:**
- `getstream_activity_id` — GetStream UUID (KHÔNG phải DB id)

**Request Body:**
```
content       string    Required
title?        string
content_en?   string
title_en?     string
industries?   number[]
services?     number[]
file?         File
notes?        string
```

**Request Example:**
```bash
curl -X POST \
  /api/external/db-feeds/activities/user-update/54a60c1e-4ee3-11e4-8689-1234567890ab \
  -H "Authorization: Bearer <token>" \
  -F "content=Updated content"
```

**Success Response:**
```json
{
  "status": true,
  "message": "Cập nhật và đồng bộ hoạt động thành công",
  "data": {
    "id": 124,
    "getstream_activity_id": "54a60c1e-4ee3-11e4-8689-1234567890ab",
    "updated_at": "2026-03-30T12:00:00.000Z"
  }
}
```

**PHP Reference:** `DatabaseFeedController@userUpdateActivity`

---

### 6. GET /db-feeds/activities/:id
**Xem chi tiết activity**

**Endpoint:** `GET /api/external/db-feeds/activities/:id`
**Authentication:** ✅ Required

**Path Parameter:** `id` — DB id

**Request Example:**
```http
GET /api/external/db-feeds/activities/124
Authorization: Bearer <token>
```

**PHP Reference:** `DatabaseFeedController@getActivityDetail`

---

### 7. POST /db-feeds/activities/delete
**Xóa activity**

**Endpoint:** `POST /api/external/db-feeds/activities/delete`
**Authentication:** ✅ Required

**Request Body:**
```json
{ "activity_id": 124 }
```

**Business Logic:**
- Regular user: chỉ xóa activity của mình
- Super admin: xóa bất kỳ activity
- Xóa DB + GetStream (nếu có `getstream_activity_id`) + file storage

**Success Response:**
```json
{
  "status": true,
  "message": "Xóa hoạt động thành công",
  "data": { "message": "Activity deleted successfully" }
}
```

**PHP Reference:** `DatabaseFeedController@deleteActivity`

---

## Admin Dashboard

### 8. GET /db-feeds/activities
**Dashboard activities với logic theo role**

**Endpoint:** `GET /api/external/db-feeds/activities`
**Authentication:** ✅ Required

**Business Logic:**
- Regular user → chỉ thấy activity của mình
- Super admin → thấy TẤT CẢ activity của non-admin users

**Query Parameters:**
```
page?        number   Default: 1
limit?       number   Default: 10
per_page?    number   Alias cho limit (PHP compat)
status?      string   Comma-separated: "Pending,Approved,Rejected"
source?      string   "admin_created" | "ai_auto_generated"
```

**PHP Reference:** `DatabaseFeedController@getActivities`

---

### 9. GET /activities
**Feed Management Dashboard (Legacy)**

**Endpoint:** `GET /api/external/activities`
**Authentication:** 🔒 Admin only (`AdminGuard`)

Trả về tất cả activities (không phân trang). Legacy endpoint, giữ lại cho backward compat.

---

## Admin Approval Workflow

### 10. POST /db-feeds/activities/approve
**Phê duyệt activity**

**Endpoint:** `POST /api/external/db-feeds/activities/approve`
**Authentication:** 🔒 Admin only

**Request Body:**
```json
{ "activity_id": 125 }
```

**Logic:**
1. Status → `Approved`
2. Set `approved_by`, `approved_at`
3. Push activity lên GetStream
4. Lưu `getstream_activity_id`
5. Dispatch FCM push notification (background job)

**Success Response:**
```json
{
  "status": true,
  "message": "Phê duyệt hoạt động thành công",
  "data": {
    "id": 125,
    "status": "Approved",
    "approved_by": 13,
    "approved_at": "2026-03-30T11:15:00.000Z",
    "getstream_activity_id": "78b90d2f-5ab4-12e5-9123-abcdef123456"
  }
}
```

**PHP Reference:** `DatabaseFeedController@approveActivity`

---

### 11. POST /db-feeds/activities/reject
**Từ chối activity**

**Endpoint:** `POST /api/external/db-feeds/activities/reject`
**Authentication:** 🔒 Admin only

**Request Body:**
```json
{
  "activity_id": 123,
  "reason": "Nội dung không phù hợp"
}
```

**Logic:**
1. Status → `Rejected`
2. Set `rejected_by`, `rejected_at`
3. Lưu `reason` vào `notes`
4. Không push lên GetStream

**Success Response:**
```json
{
  "status": true,
  "message": "Từ chối hoạt động thành công",
  "data": {
    "id": 123,
    "status": "Rejected",
    "rejected_by": 13,
    "rejected_at": "2026-03-30T11:45:00.000Z",
    "notes": "Nội dung không phù hợp"
  }
}
```

**PHP Reference:** `DatabaseFeedController@rejectActivity`

---

## Admin Direct Operations

### 12. POST /db-feeds/activities/update-status
**Cập nhật status trực tiếp (không qua workflow)**

**Endpoint:** `POST /api/external/db-feeds/activities/update-status`
**Authentication:** 🔒 Admin only

**Request Body:**
```json
{
  "activity_id": 123,
  "status": "Approved",
  "notes": "Manual correction"
}
```

**Khác biệt với approve/reject:**
- Không set `approved_by` / `rejected_by`
- Không push lên GetStream
- Dùng để sửa trực tiếp hoặc testing

**PHP Reference:** `DatabaseFeedController@updateActivityStatus`

---

## Public Endpoints (No Auth)

### 13. GET /public-feeds/activities
**Danh sách activity công khai**

**Endpoint:** `GET /api/public-feeds/activities`
**Authentication:** ⭕ Không cần

**Query Parameters:**
```
page?        number   Default: 1
limit?       number   Default: 10
per_page?    number   Alias cho limit
user_id?     number   Filter theo user cụ thể
status?      string   Default: "approved"
```

**Request Example:**
```http
GET /api/public-feeds/activities?page=1&limit=10&user_id=5
```

**PHP Reference:** `DatabaseFeedController@getPublicActivities`

---

### 14. GET /public-feeds/activities/:id
**Chi tiết activity công khai**

**Endpoint:** `GET /api/public-feeds/activities/:id`
**Authentication:** ⭕ Không cần

Chỉ trả về activity đã `Approved`. Expand `industry_details` và `service_details` (full objects).

**Success Response:**
```json
{
  "status": true,
  "message": "Lấy thông tin hoạt động công khai thành công",
  "data": {
    "id": 124,
    "title": "...",
    "content": "...",
    "status": "Approved",
    "industries": [{ "id": 1, "name": "Công nghệ" }],
    "industry_details": [{ "id": 1, "name": "Công nghệ", "status": 1, "language": "vi" }],
    "service_details": [{ "id": 5, "name": "Tư vấn", "status": 1, "type": "service" }],
    "user": { ... }
  }
}
```

**PHP Reference:** `DatabaseFeedController@getPublicActivityDetail`

---

## Workflow

### Activity Creation Flow

```
Regular User:
  POST /create → status=Approved → auto-create GetStream user (if needed) → push to GetStream

Super Admin:
  POST /create → status=Pending → stored in DB only
  POST /approve → status=Approved → push to GetStream → FCM notification
  POST /reject  → status=Rejected → stored in DB only
```

### Update Options

| Endpoint | DB | GetStream | Use Case |
|----------|----|-----------|----------|
| `/update` | ✅ | ❌ | Draft edit, no live feed update |
| `/user-update/:id` | ✅ | ✅ | Live feed update |
| `/update-status` | ✅ | ❌ | Admin manual correction |

---

## GetStream Integration

### GetstreamUserId Format

```
getstreamUserId = filterEmailString(email) + '_' + userId

filterEmailString: lowercase, remove all non-alphanumeric [^a-z0-9]

Examples:
  "bxthuan@gmail.com"   + id=2  → "bxthuangmailcom_2"
  "test+tag@domain.com" + id=5  → "testtagdomaincom_5"
  "User@Company.vn"     + id=10 → "usercompany_10"
```

Field lưu vào DB: `users.getstream_user_id` (Drizzle: `getstreamUserId`)

### Actor Format

```
actor = "SU:" + getstreamUserId

Example: "SU:bxthuangmailcom_2"
```

> **Breaking change từ v3.0.0:** Actor trước đây doc ghi là `user_5` — **không đúng**. Code thực tế luôn dùng `SU:{getstreamUserId}`.

### Token Generation

```typescript
// Synchronous — ký JWT locally bằng API Secret, không gọi GetStream server
const token = client.createUserToken(getstreamUserId);
```

Token không có expiry (không dùng `expireTokens` option) — khớp với PHP behavior.

### GetStream Sync Points

| Action | Endpoint | Sync? | Notes |
|--------|----------|-------|-------|
| Create (regular user) | `/create` | ✅ | Immediate trên auto-approve |
| Create (super admin) | `/create` | ❌ | Pending, chờ approve |
| Update (DB only) | `/update` | ❌ | — |
| User-Update | `/user-update/:id` | ✅ | Live update |
| Approve | `/approve` | ✅ | Push + lưu getstream_activity_id |
| Reject | `/reject` | ❌ | — |
| Update Status | `/update-status` | ❌ | — |
| Delete | `/delete` | ✅ (if exists) | Remove từ GetStream feed |

### User Sync khi updateUser

Khi user cập nhật profile, `UsersService.updateUser()` tự động sync lên GetStream với full fields:

```typescript
await getstreamService.update_user(getstreamUserId, {
  id, first_name, last_name, email, avatar, name
});
```

> Dùng `getstreamUserId` (format `email_id`) thay vì DB `id.toString()`.
> GetStream sync là **non-fatal** — lỗi chỉ log, không fail request.

### Activity Structure trên GetStream

```json
{
  "actor": "SU:bxthuangmailcom_2",
  "verb": "post",
  "object": "post:1739258374123",
  "foreign_id": "user_activity_124",
  "time": "2026-03-30T10:30:00.000Z",
  "data": {
    "title": "Tiêu đề",
    "content": "Nội dung...",
    "industries": [{ "id": 1, "name": "Công nghệ" }],
    "services": [{ "id": 5, "name": "Tư vấn" }],
    "file_uri": "/uploads/activities/..."
  },
  "extra": {
    "language": {
      "en": {
        "title": "Title",
        "content": "Content...",
        "industries": [{ "id": 1, "name": "Technology" }]
      }
    }
  }
}
```

---

## Related Documentation

- [GETSTREAM_TOKEN_ENDPOINT_PLAN.md](./GETSTREAM_TOKEN_ENDPOINT_PLAN.md) — Implementation plan cho token endpoint
- [DATABASE_FEED_CONTROLLER_PLAN.md](./DATABASE_FEED_CONTROLLER_PLAN.md) — PHP vs NestJS gap analysis (all gaps resolved)
- [FCM_NOTIFICATION_SYSTEM.md](./FCM_NOTIFICATION_SYSTEM.md) — Push notification khi approve activity
- [activities-postman-collection.json](./activities-postman-collection.json) — Postman collection

---

**Last Updated:** 2026-03-30
**API Version:** 3.0.0
