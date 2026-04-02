# Email Campaign API Documentation

**Version:** 2.5
**Base URL:** `http://localhost:3001/api`
**Authentication:** JWT Bearer Token (Admin role required, except public endpoints)
**Last Updated:** 2026-04-01

> **Note:** This document covers **Email Campaign features (Phase A, B, C, D)** — campaign history, email tracking, scheduled sending, and email list management. For basic email sending and template management, see [EMAIL_API.md](EMAIL_API.md).

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Phase A — Campaign History & Unsubscribe](#phase-a--campaign-history--unsubscribe)
  - [Send Bulk Email with Campaign Tracking](#send-bulk-email-with-campaign-tracking)
  - [Get Campaigns](#get-campaigns)
  - [Get Campaign by ID](#get-campaign-by-id)
  - [Get Campaign Unsubscribers](#get-campaign-unsubscribers)
  - [Get Campaigns by Status](#get-campaigns-by-status)
  - [List All Unsubscribes](#list-all-unsubscribes)
  - [Verify Unsubscribe Token](#verify-unsubscribe-token)
  - [Get Unsubscribe Status](#get-unsubscribe-status)
- [Phase B — Email Tracking](#phase-b--email-tracking)
  - [Track Email Open](#track-email-open)
  - [Track Link Click](#track-link-click)
  - [Get Campaign Tracking Stats](#get-campaign-tracking-stats)
- [Phase C — Email Scheduling](#phase-c--email-scheduling)
  - [Schedule Email Campaign](#schedule-email-campaign)
  - [Cancel Scheduled Campaign](#cancel-scheduled-campaign)
- [Phase D — Email List Management](#phase-d--email-list-management)
  - [Send Email Filters — New Fields](#send-email-filters--new-fields)
  - [List All Email Lists](#list-all-email-lists)
  - [Create Email List](#create-email-list)
  - [Get Email List by ID](#get-email-list-by-id)
  - [Update Email List](#update-email-list)
  - [Delete Email List](#delete-email-list)
  - [Get List Members](#get-list-members)
  - [Add Members to List](#add-members-to-list)
  - [Remove Members from List](#remove-members-from-list)
- [Campaign Status Reference](#campaign-status-reference)
- [Database Schema](#database-schema)
- [Environment Variables](#environment-variables)
- [Integration with EMAIL_API](#integration-with-email_api)

---

## Overview

Email Campaign Module cung cấp khả năng **quản lý email campaign toàn vòng đời** cho admin:

### Phase A — Campaign History & Unsubscribe
- ✅ **Campaign auto-tracking**: Mỗi lần gửi email qua `POST /api/emails/send` tự động tạo campaign record với thống kê (total, success, failed)
- ✅ **HMAC-SHA256 unsubscribe tokens**: Stateless unsubscribe links — không cần DB storage
- ✅ **Auto-footer injection**: GDPR-compliant unsubscribe footer tự động thêm vào email
- ✅ **Blacklist filtering**: Hệ thống tự động bỏ qua email của user đã unsubscribe từ campaign tương lai

### Phase B — Email Tracking
- ✅ **Open tracking**: Transparent GIF pixel tự động inject → đếm số lần email được mở
- ✅ **Click tracking**: Transparent redirect — ghi lại link nào được click + bao nhiêu lần
- ✅ **Deduplication**: Một email chỉ counted 1 lần open, nhưng có thể track multiple clicks
- ✅ **Analytics**: GET endpoint trả về open_rate, click_rate, top clicked URLs, etc.

### Phase C — Email Scheduling
- ✅ **Schedule campaigns**: Lên lịch gửi email vào thời điểm tương lai (sử dụng Bull Queue + Redis)
- ✅ **Idempotent execution**: Même nếu Bull Queue retry job, email chỉ gửi 1 lần (atomic status check)
- ✅ **Startup reconciliation**: Nếu Redis restart, app tự động re-enqueue các campaign đã schedule
- ✅ **Cancel anytime**: Hủy campaign scheduled trước khi thực thi

### Phase D — Email List Management
- ✅ **Named email lists**: Tạo/quản lý danh sách email tùy chỉnh (name, description, tags)
- ✅ **Flexible membership**: Thêm thành viên bằng `user_ids` hoặc raw `emails` (external emails supported)
- ✅ **Multi-list**: Một user có thể nằm trong nhiều list
- ✅ **list_id filter**: Dùng `list_id` trong `POST /api/emails/send` để gửi cho toàn bộ members
- ✅ **is_can_test flag**: Đánh dấu user là "test recipient" — filter kết hợp với bất kỳ recipient filter nào

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│ Admin                                                    │
│ POST /api/emails/send (Phase A)                         │
│ POST /api/emails/schedule (Phase C)                    │
└────────────────────┬────────────────────────────────────┘
                     ↓
         ┌───────────────────────────┐
         │ EmailController           │
         │ (auth + admin guard)      │
         └────────┬──────────────────┘
                  ↓
    ┌─────────────────────────────┐
    │ EmailService                │
    ├─ resolveContent()           │
    ├─ resolveRecipients()        │
    ├─ injectTracking() [Phase B] │
    ├─ buildUnsubscribeFooter()   │
    │   [Phase A]                 │
    └────────┬────────────────────┘
             ├──► EmailCampaignRepository (create, update, query)
             ├──► EmailUnsubscribeRepository (check blacklist)
             ├──► EmailTrackingRepository (record open/click) [Phase B]
             ├──► EmailListRepository (resolve list members) [Phase D]
             ├──► Nodemailer.sendMail()
             └──► Bull Queue [Phase C]

[After delay - Phase C]
             ↓
    ┌─────────────────────────────┐
    │ EmailScheduleProcessor      │
    │ (Bull Job Handler)          │
    └────────┬────────────────────┘
             ↓
    [Same flow as above]
```

---

## Phase A — Campaign History & Unsubscribe

### Send Bulk Email with Campaign Tracking

Gửi email hàng loạt + **tự động tạo campaign record** để tracking thống kê.

```http
POST /api/emails/send
```

**Giống với `EMAIL_API.md`** — xem [Send Bulk Email](EMAIL_API.md#send-bulk-email) để chi tiết đầy đủ.

#### Sự khác biệt Phase A

Request body hỗ trợ thêm các field (optional):

| Field | Type | Bắt buộc | Mô tả |
|---|---|---|---|
| `campaign_name` | `string` | Không | Tên campaign tùy chỉnh (default: `{template_name} - {date}`) |
| `include_unsubscribe_link` | `boolean` | Không | Thêm unsubscribe footer vào email (default: `true`) |
| `list_id` | `number` | Không | **[Phase D]** Gửi cho toàn bộ members trong Email List |
| `is_can_test` | `boolean` | Không | **[Phase D]** Nếu `true` → chỉ gửi cho users có `is_can_test=1`. Kết hợp với bất kỳ filter nào |
| `send_by_lang` | `boolean` | Không | Gửi theo ngôn ngữ người dùng (`users.lang`). Mỗi recipient nhận email theo ngôn ngữ của họ. Yêu cầu template có ≥ 2 ngôn ngữ |
| `subject_vi` | `string` | Không | Override subject tiếng Việt khi `send_by_lang=true` |
| `body_vi` | `string` | Không | Override body tiếng Việt (HTML) khi `send_by_lang=true` |
| `from_name` | `string` | Không | Override tên người gửi hiển thị cho campaign này. Ưu tiên: `dto.from_name` → `template.from_name` → `MAIL_FROM_NAME` từ `.env` |
| `from_email` | `string` | Không | Override địa chỉ email gửi thực sự. Phải là `@incard.biz` hoặc `@inapps.net`. Ưu tiên: `dto.from_email` → `template.from_email` → `MAIL_FROM_ADDRESS` từ `.env` |
| `reply_to` | `string` | Không | Override địa chỉ Reply-To cho campaign này. Ưu tiên: `dto.reply_to` → `template.reply_to` → _(không set header)_ |

**Recipient priority** (cao → thấp):
1. `user_emails` — gửi thẳng, không query DB
2. `list_id` — lấy emails từ `email_list_members`
3. `user_ids` / `user_types` / `created_from`+`created_to` — filter từ bảng users
4. (none) — toàn bộ users

`is_can_test=true` luôn áp dụng sau khi resolve recipients (trừ `user_emails`).

#### Response (Phase A enhancement)

```json
{
  "status": true,
  "message": "Gửi email hoàn tất: 98/100 thành công",
  "data": {
    "total": 100,
    "success": 98,
    "failed": 2,
    "failed_emails": ["err1@example.com", "err2@example.com"],
    "campaign_id": 42
  }
}
```

**New field:** `campaign_id` — ID campaign vừa tạo (dùng để track open/click ở Phase B)

#### Auto-created Campaign Record

```
Database (email_campaigns table):
├── id: 42
├── name: "Newsletter - 2026-03-09"
├── status: "sent"
├── total: 100
├── success: 98
├── failed: 2
├── open_count: 0 (Phase B tracks this)
├── click_count: 0 (Phase B tracks this)
└── created_at: 2026-03-09T10:30:00Z
```

#### Example with Phase A fields

```json
{
  "user_emails": ["alice@example.com", "bob@example.com"],
  "subject": "March Newsletter",
  "body": "<h1>Hello</h1><p>Latest updates...</p>",
  "campaign_name": "Newsletter - Q1 2026",
  "include_unsubscribe_link": true,
  "from_name": "Tâm Hồ từ InCard",
  "from_email": "tamho@incard.biz",
  "reply_to": "support@incard.biz"
}
```

#### Example with send_by_lang

```json
{
  "template_id": 3,
  "send_by_lang": true,
  "subject_vi": "Bản tin tháng 3",
  "body_vi": "<h1>Xin chào {{firstName}}!</h1><p>Nội dung tiếng Việt...</p>",
  "subject": "March Newsletter",
  "body": "<h1>Hello {{firstName}}!</h1><p>English content...</p>",
  "campaign_name": "Newsletter Q1 2026 - Multi-lang",
  "include_unsubscribe_link": true
}
```

**Fallback chain khi `send_by_lang=true`:**
- User có `lang='vi'`: dùng `subject_vi` / `body_vi` → fallback `subject_vi` từ template lang `vi` → fallback EN
- User có `lang='en'` hoặc lang khác: dùng `subject` / `body` → fallback từ template lang `en` / `langs[0]`

**What happens:**
1. ✅ Campaign record created with `name` = "Newsletter - Q1 2026"
2. ✅ Email body automatically gets unsubscribe footer injected:
   ```html
   <h1>Hello</h1><p>Latest updates...</p>
   <hr>
   <p>Bạn không muốn nhận email từ chúng tôi? <a href="https://api.incard.vn/api/unsubscribe?email=...&token=...">Hủy đăng ký</a></p>
   ```
3. ✅ If recipient already unsubscribed → skipped, counted as `failed`

---

### Get Campaigns

Lấy danh sách campaign với pagination.

```http
GET /api/emails/campaigns?page=1&limit=20&status=sent
```

**Authentication:** Admin only

#### Query Parameters

| Param | Type | Default | Mô tả |
|---|---|---|---|
| `page` | `number` | `1` | Trang (min: 1) |
| `limit` | `number` | `20` | Số item/trang (max: 100) |
| `status` | `string` | (tất cả) | Filter by status: `sent`, `scheduled`, `sending`, `cancelled`, `failed` |

#### Response

```json
{
  "status": true,
  "message": "OK",
  "data": {
    "campaigns": [
      {
        "id": 42,
        "name": "Newsletter - 2026-03-09",
        "template_id": 3,
        "template_name": "Newsletter Template",
        "lang": "vi",
        "recipient_mode": "filter",
        "subject": "March Newsletter",
        "body": "<h1>Hello</h1>...",
        "subject_vi": "Bản tin tháng 3",
        "body_vi": "<h1>Xin chào</h1>...",
        "subject_en": "March Newsletter",
        "body_en": "<h1>Hello</h1>...",
        "total": 100,
        "success": 98,
        "failed": 2,
        "open_count": 45,
        "click_count": 12,
        "status": "sent",
        "created_at": "2026-03-09T10:30:00Z",
        "updated_at": "2026-03-09T10:35:00Z"
      }
    ],
    "pagination": {
      "total": 150,
      "page": 1,
      "limit": 20,
      "pages": 8
    }
  }
}
```

---

### Get Campaign by ID

Lấy chi tiết campaign theo ID.

```http
GET /api/emails/campaigns/:id
```

**Authentication:** Admin only

#### Path Parameters

| Param | Type | Mô tả |
|---|---|---|
| `id` | `number` | Campaign ID |

#### Response

```json
{
  "status": true,
  "message": "OK",
  "data": {
    "id": 42,
    "name": "Newsletter - Q1 2026",
    "template_id": 3,
    "template_name": "Newsletter Template",
    "lang": "vi",
    "recipient_mode": "filter",
    "subject": "March Newsletter",
    "body": "<h1>Hello</h1>...",
    "subject_vi": "Bản tin tháng 3",
    "body_vi": "<h1>Xin chào</h1>...",
    "subject_en": "March Newsletter",
    "body_en": "<h1>Hello</h1>...",
    "total": 100,
    "success": 98,
    "failed": 2,
    "failed_emails": ["err1@example.com", "err2@example.com"],
    "open_count": 45,
    "click_count": 12,
    "status": "sent",
    "scheduled_at": null,
    "created_at": "2026-03-09T10:30:00Z",
    "updated_at": "2026-03-09T10:35:00Z"
  }
}
```

---

### Get Campaign Unsubscribers

Lấy danh sách email đã unsubscribe từ campaign này.

```http
GET /api/emails/campaigns/:id/unsubscribers?page=1&limit=50
```

**Authentication:** Admin only

#### Response

```json
{
  "status": true,
  "message": "OK",
  "data": {
    "unsubscribes": [
      {
        "email": "unsubbed@example.com",
        "unsubscribed_at": "2026-03-08T15:20:00Z"
      }
    ],
    "pagination": {
      "total": 5,
      "page": 1,
      "limit": 50,
      "pages": 1
    }
  }
}
```

---

### Get Campaigns by Status

Lấy danh sách campaign theo status cụ thể.

```http
GET /api/emails/campaigns/filter/status/scheduled?page=1&limit=10
```

**Authentication:** Admin only

#### Response

```json
{
  "status": true,
  "message": "OK",
  "data": {
    "campaigns": [
      {
        "id": 50,
        "name": "Scheduled Campaign",
        "status": "scheduled",
        "scheduled_at": "2026-03-15T09:00:00Z",
        "total": 500,
        "success": 0,
        "failed": 0,
        "created_at": "2026-03-09T10:00:00Z"
      }
    ],
    "pagination": {
      "total": 3,
      "page": 1,
      "limit": 10,
      "pages": 1
    }
  }
}
```

---

### List All Unsubscribes

Lấy danh sách **tất cả** email đã unsubscribe (từ tất cả campaigns). Hỗ trợ phân trang, search email, filter date.

```http
GET /api/emails/unsubscribes?page=1&limit=50&email=example.com&from=2026-01-01&to=2026-03-31
```

**Authentication:** Admin only

#### Query Parameters

| Param | Type | Default | Mô tả |
|---|---|---|---|
| `page` | `number` | 1 | Trang hiện tại |
| `limit` | `number` | 50 | Records trên page (max 100) |
| `email` | `string` | - | Search partial match (LIKE %email%) |
| `from` | `date (ISO)` | - | Filter unsubscribed_at >= from |
| `to` | `date (ISO)` | - | Filter unsubscribed_at <= to (23:59:59) |

#### Examples

**Get all unsubscribes (first page, default 50 per page):**
```http
GET /api/emails/unsubscribes
```

**Search unsubscribes for a domain:**
```http
GET /api/emails/unsubscribes?email=gmail.com&page=1&limit=50
```

**Filter by date range (March 2026):**
```http
GET /api/emails/unsubscribes?from=2026-03-01&to=2026-03-31
```

**Combine search + date filter:**
```http
GET /api/emails/unsubscribes?email=example&from=2026-02-01&to=2026-03-31&page=1&limit=100
```

#### Response (Success)

```json
{
  "status": true,
  "message": "Lấy danh sách unsubscribe thành công",
  "data": {
    "unsubscribes": [
      {
        "email": "user1@example.com",
        "unsubscribed_at": "2026-03-09T10:30:00.000Z"
      },
      {
        "email": "user2@example.com",
        "unsubscribed_at": "2026-03-08T15:20:00.000Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 50,
      "total": 125,
      "pages": 3
    }
  }
}
```

#### Response (Error - Unauthorized)

```json
{
  "status": false,
  "message": "Token xác thực không được cung cấp",
  "data": null
}
```

#### Response (Error - Forbidden)

```json
{
  "status": false,
  "message": "Forbidden resource",
  "data": null
}
```

#### CURL Examples

**Basic request:**
```bash
curl -X GET 'http://localhost:3001/api/emails/unsubscribes' \
  -H 'Authorization: Bearer dev_token_13'
```

**With search and date filter:**
```bash
curl -X GET 'http://localhost:3001/api/emails/unsubscribes?email=example.com&from=2026-01-01&limit=10' \
  -H 'Authorization: Bearer dev_token_13'
```

---

### Verify Unsubscribe Token

**PUBLIC endpoint** — người dùng click unsubscribe link → verify token + unsubscribe

```http
GET /api/unsubscribe/verify?email=user@example.com&token=hmac_token
```

**Authentication:** @Public() — không cần JWT

#### Query Parameters

| Param | Type | Mô tả |
|---|---|---|
| `email` | `string` | Email muốn unsubscribe |
| `token` | `string` | HMAC-SHA256 token từ link |

#### Response (Success - HTML)

```html
<html>
<body>
  <h2>✓ Đã hủy đăng ký thành công.</h2>
  <p>Email <b>user@example.com</b> sẽ không nhận email từ InCard nữa.</p>
</body>
</html>
```

#### Response (Invalid Token - HTML)

```html
<html>
<body>
  <h2>❌ Link không hợp lệ hoặc đã hết hạn.</h2>
</body>
</html>
```

---

### Get Unsubscribe Status

**PUBLIC endpoint** — kiểm tra email có bị unsubscribe hay không

```http
GET /api/unsubscribe/status?email=user@example.com
```

**Authentication:** @Public()

#### Response

```json
{
  "success": true,
  "data": {
    "email": "user@example.com",
    "is_unsubscribed": false,
    "unsubscribed_at": null
  }
}
```

---

## Phase B — Email Tracking

### Track Email Open

**PUBLIC endpoint** — transparent 1x1 GIF pixel, auto-injected vào email body

```http
GET /api/emails/tracking/open?cid=42&email=user@example.com
```

**Authentication:** @Public()

#### Query Parameters

| Param | Type | Mô tả |
|---|---|---|
| `cid` | `number` | Campaign ID |
| `email` | `string` | Recipient email (URL-encoded) |

#### Response

Transparent 1x1 GIF image (fire-and-forget)

```
[Binary GIF data]
Cache-Control: no-cache, no-store, must-revalidate
```

**What happens in DB:**
- Create/update `email_tracking_events` record: `(campaign_id, email, event_type='open')`
- Increment `email_campaigns.open_count` by 1 (deduplicated — max 1 per email)

---

### Track Link Click

**PUBLIC endpoint** — click tracking + redirect

```http
GET /api/emails/tracking/click?cid=42&email=user@example.com&url=https://example.com&redirect_to=https://incard.biz
```

**Authentication:** @Public()

#### Query Parameters

| Param | Type | Mô tả |
|---|---|---|
| `cid` | `number` | Campaign ID |
| `email` | `string` | Recipient email (URL-encoded) |
| `url` | `string` | Original URL being clicked (URL-encoded) — stored for analytics |
| `redirect_to` | `string` | *(Optional)* Fixed redirect URL (nếu có thì redirect đây thay vì `url`) |

#### Response

```
HTTP 302 Found
Location: https://example.com  (or https://incard.biz if redirect_to provided)
```

**What happens in DB:**
- Create `email_tracking_events` record: `(campaign_id, email, event_type='click', url, ...)`
- Increment `email_campaigns.click_count` by 1

**Security:**
- Open redirect prevention: URL must start with `http://` or `https://`
- Invalid URLs → response 400 Bad Request

---

### Get Campaign Tracking Stats

Lấy analytics cho campaign: open rate, click rate, top URLs, etc.

```http
GET /api/emails/tracking/stats?campaign_id=42
```

**Authentication:** Admin only

#### Query Parameters

| Param | Type | Mô tả |
|---|---|---|
| `campaign_id` | `number` | Campaign ID |

#### Response

```json
{
  "status": true,
  "message": "OK",
  "data": {
    "campaign_id": 42,
    "total_sent": 100,
    "unique_opens": 45,
    "unique_clicks": 12,
    "open_rate": "45%",
    "click_rate": "12%",
    "top_clicked_urls": [
      {
        "url": "https://incard.vn",
        "click_count": 8
      },
      {
        "url": "https://example.com",
        "click_count": 4
      }
    ]
  }
}
```

---

## Phase C — Email Scheduling

### Schedule Email Campaign

Lên lịch gửi email vào thời điểm tương lai.

```http
POST /api/emails/schedule
```

**Authentication:** Admin only

#### Request Body

Kết hợp `SendEmailDto` (xem [EMAIL_API.md](EMAIL_API.md#send-bulk-email)) + thêm:

| Field | Type | Bắt buộc | Mô tả |
|---|---|---|---|
| `scheduled_at` | `string` | **Có** | ISO 8601 datetime — phải là thời điểm tương lai (e.g., `2026-12-31T15:30:00Z`) |
| `name` | `string` | Không | Campaign name (default: `{template_name} - {date}`) |
| `user_emails` | `string[]` | Không | Gửi tới (dùng giống `SendEmailDto`) |
| `user_ids` | `number[]` | Không | Lọc theo ID |
| `user_types` | `string[]` | Không | Lọc theo type |
| `industry_ids` | `number[]` | Không | Lọc theo ngành nghề — tra ngược `businesses.category` → `users`. OR logic giữa nhiều IDs |
| `is_can_test` | `boolean` | Không | Nếu `true` → chỉ gửi cho users có `is_can_test=1`. Kết hợp với bất kỳ filter nào |
| `created_from` | `string` | Không | Lọc theo date from |
| `created_to` | `string` | Không | Lọc theo date to |
| `template_id` | `number` | Không | Template ID |
| `lang` | `string` | Không | Template lang (default: `vi`) |
| `subject` | `string` | Có (*) | Subject (EN hoặc mặc định) |
| `body` | `string` | Có (*) | Body (EN hoặc mặc định) |
| `include_unsubscribe_link` | `boolean` | Không | Phase A feature (default: `true`) |
| `redirect_url` | `string` | Không | Phase B feature |
| `send_by_lang` | `boolean` | Không | Gửi theo ngôn ngữ người dùng — mỗi recipient nhận theo `users.lang` |
| `subject_vi` | `string` | Không | Override subject tiếng Việt khi `send_by_lang=true` |
| `body_vi` | `string` | Không | Override body tiếng Việt (HTML) khi `send_by_lang=true` |
| `from_name` | `string` | Không | Override tên người gửi hiển thị. Ưu tiên: `dto.from_name` → `template.from_name` → `MAIL_FROM_NAME` từ `.env` |
| `from_email` | `string` | Không | Override địa chỉ email gửi thực sự (`@incard.biz` hoặc `@inapps.net`). Ưu tiên: `dto.from_email` → `template.from_email` → `MAIL_FROM_ADDRESS` từ `.env` |
| `reply_to` | `string` | Không | Override Reply-To email. Ưu tiên: `dto.reply_to` → `template.reply_to` → _(không set header)_ |

> **(\*)** Bắt buộc nếu không có `template_id`

#### Request Example

```json
{
  "scheduled_at": "2026-12-31T15:30:00Z",
  "name": "New Year Campaign",
  "user_emails": ["customer@example.com"],
  "subject": "Happy New Year!",
  "body": "<h1>Welcome to 2027!</h1>",
  "include_unsubscribe_link": true
}
```

#### Request Example với send_by_lang

```json
{
  "scheduled_at": "2026-12-31T15:30:00Z",
  "name": "New Year Campaign - Multi-lang",
  "template_id": 3,
  "send_by_lang": true,
  "subject_vi": "Chúc mừng năm mới 2027!",
  "body_vi": "<h1>Kính chúc {{firstName}} năm mới an khang!</h1>",
  "subject": "Happy New Year 2027!",
  "body": "<h1>Happy New Year {{firstName}}!</h1>",
  "include_unsubscribe_link": true
}
```

#### Response `200 OK`

```json
{
  "status": true,
  "message": "OK",
  "data": {
    "id": 50,
    "status": "scheduled",
    "scheduled_at": "2026-12-31T15:30:00Z"
  }
}
```

**What happens:**
1. ✅ Campaign record created with `status='scheduled'`
2. ✅ Full payload stored in `scheduled_payload` (JSON)
3. ✅ Bull Queue job created with delay until `scheduled_at`
4. ✅ Job ID: `campaign-50` (deterministic, for cancellation)

#### Errors

| HTTP | Message | Nguyên nhân |
|---|---|---|
| `400 Bad Request` | `scheduled_at phải là thời điểm tương lai` | Datetime is past |
| `400 Bad Request` | Validation errors | Missing required fields |
| `401 Unauthorized` | No auth token | Missing JWT |
| `403 Forbidden` | User not admin | Non-admin user |

---

### Cancel Scheduled Campaign

Hủy campaign đã schedule (trước khi thực thi).

```http
DELETE /api/emails/schedule/:id
```

**Authentication:** Admin only

#### Path Parameters

| Param | Type | Mô tả |
|---|---|---|
| `id` | `number` | Campaign ID |

#### Response `200 OK`

```json
{
  "status": true,
  "message": "OK",
  "data": {
    "id": 50,
    "status": "cancelled"
  }
}
```

**What happens:**
1. ✅ Campaign status updated to `cancelled`
2. ✅ Bull Queue job removed (won't execute)

#### Errors

| HTTP | Message | Nguyên nhân |
|---|---|---|
| `404 Not Found` | Campaign not found | Invalid ID |
| `409 Conflict` | Cannot cancel status="sent" | Campaign already sent |
| `409 Conflict` | Cannot cancel status="cancelled" | Already cancelled |

---

## Phase D — Email List Management

### Send Email Filters — New Fields

Hai field mới trong `POST /api/emails/send` (xem [Phase A section](#sự-khác-biệt-phase-a) cho đầy đủ).

| Field | Type | Mô tả |
|---|---|---|
| `list_id` | `number` | Gửi cho tất cả members trong Email List |
| `is_can_test` | `boolean` | Chỉ gửi cho users có `is_can_test=1` |

---

### List All Email Lists

```http
GET /api/email-lists?page=1&limit=20&search=beta
Authorization: Bearer <token>
```

**Authentication:** Admin only

#### Query Parameters

| Param | Type | Default | Mô tả |
|---|---|---|---|
| `page` | `number` | `1` | Trang (min: 1) |
| `limit` | `number` | `20` | Số item/trang (max: 100) |
| `search` | `string` | - | Search theo tên list |

#### Response

```json
{
  "status": true,
  "message": "OK",
  "data": {
    "lists": [
      {
        "id": 1,
        "name": "Beta Q1 2026",
        "description": "Danh sách user thử nghiệm",
        "tags": ["beta", "q1"],
        "member_count": 250,
        "created_at": "2026-03-12T10:00:00Z",
        "updated_at": "2026-03-12T10:00:00Z"
      }
    ],
    "pagination": { "page": 1, "limit": 20, "total": 5, "pages": 1 }
  }
}
```

---

### Create Email List

```http
POST /api/email-lists
Authorization: Bearer <token>
```

**Authentication:** Admin only

#### Request Body

```json
{
  "name": "VIP Customers",
  "description": "Khách hàng VIP Q2",
  "tags": ["vip", "q2"]
}
```

| Field | Type | Bắt buộc | Mô tả |
|---|---|---|---|
| `name` | `string` | **Có** | Tên list |
| `description` | `string` | Không | Mô tả |
| `tags` | `string[]` | Không | Tags (default: `[]`) |

#### Response `201 Created`

```json
{
  "status": true,
  "message": "Tạo list thành công",
  "data": { "id": 2, "name": "VIP Customers", "tags": ["vip", "q2"], "member_count": 0, ... }
}
```

---

### Get Email List by ID

```http
GET /api/email-lists/:id
Authorization: Bearer <token>
```

**Authentication:** Admin only

#### Response

```json
{
  "status": true,
  "message": "OK",
  "data": { "id": 1, "name": "Beta Q1 2026", "description": "...", "tags": ["beta"], "member_count": 250, ... }
}
```

#### Errors

| HTTP | Message |
|---|---|
| `404 Not Found` | `List #:id không tồn tại` |

---

### Update Email List

```http
PUT /api/email-lists/:id
Authorization: Bearer <token>
```

**Authentication:** Admin only

#### Request Body (all fields optional)

```json
{
  "name": "Beta Q1 2026 — Updated",
  "description": "Mô tả mới",
  "tags": ["beta"]
}
```

#### Response

```json
{
  "status": true,
  "message": "Cập nhật list thành công",
  "data": { "id": 1, "name": "Beta Q1 2026 — Updated", ... }
}
```

---

### Delete Email List

```http
DELETE /api/email-lists/:id
Authorization: Bearer <token>
```

**Authentication:** Admin only

> Members bị xóa cascade (cả DB và explicit delete trong code).

#### Response

```json
{
  "status": true,
  "message": "Xóa list thành công",
  "data": null
}
```

---

### Get List Members

```http
GET /api/email-lists/:id/members?page=1&limit=20&q=example.com
Authorization: Bearer <token>
```

**Authentication:** Admin only

#### Query Parameters

| Param | Type | Default | Mô tả |
|---|---|---|---|
| `page` | `number` | `1` | Trang |
| `limit` | `number` | `20` | Số item/trang (max: 100) |
| `q` | `string` | - | Search theo email |

#### Response

```json
{
  "status": true,
  "message": "OK",
  "data": {
    "list": { "id": 1, "name": "Beta Q1 2026" },
    "members": [
      { "id": 1, "user_id": 42, "email": "user@example.com", "created_at": "..." },
      { "id": 2, "user_id": null, "email": "external@gmail.com", "created_at": "..." }
    ],
    "pagination": { "page": 1, "limit": 20, "total": 250, "pages": 13 }
  }
}
```

> `user_id` là `null` khi email không có trong bảng `users` (external email).

---

### Add Members to List

```http
POST /api/email-lists/:id/members
Authorization: Bearer <token>
```

**Authentication:** Admin only

#### Request Body

```json
{
  "user_ids": [42, 43, 44],
  "emails": ["external1@gmail.com", "external2@gmail.com"]
}
```

| Field | Type | Mô tả |
|---|---|---|
| `user_ids` | `number[]` | Thêm bằng user ID (auto-resolve sang email) |
| `emails` | `string[]` | Thêm bằng email (external emails supported) |

> Phải có ít nhất 1 trong 2 field. Duplicate bị bỏ qua (không báo lỗi).

#### Response

```json
{
  "status": true,
  "message": "Thêm members thành công",
  "data": { "added": 4, "skipped": 1 }
}
```

#### Errors

| HTTP | Message | Nguyên nhân |
|---|---|---|
| `400 Bad Request` | `Phải cung cấp ít nhất user_ids hoặc emails` | Body rỗng |
| `404 Not Found` | `List #:id không tồn tại` | List không có |

---

### Remove Members from List

```http
DELETE /api/email-lists/:id/members
Authorization: Bearer <token>
```

**Authentication:** Admin only

#### Request Body

```json
{
  "user_ids": [42],
  "emails": ["external1@gmail.com"]
}
```

#### Response

```json
{
  "status": true,
  "message": "Xóa members thành công",
  "data": { "removed": 2 }
}
```

---

## Campaign Status Reference

| Status | Meaning | Can Transition To | Notes |
|---|---|---|---|
| `sent` | ✅ Email sent | _(terminal)_ | Phase A: default after `POST /api/emails/send` |
| `scheduled` | ⏳ Waiting for execution | `sending`, `cancelled` | Phase C: created by `POST /api/emails/schedule` |
| `sending` | 🔄 Currently executing | `sent`, `failed` | Phase C: set atomically before execution (idempotent check) |
| `cancelled` | ❌ Admin cancelled | _(terminal)_ | Phase C: `DELETE /api/emails/schedule/:id` |
| `failed` | ❌ Execution failed | _(retried by Bull)_ | Phase C: job error → status set to failed, Bull retries |

---

## Database Schema

### `email_campaigns` (Phase A, B, C)

```sql
CREATE TABLE email_campaigns (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  template_id INT,
  template_name VARCHAR(255),
  lang VARCHAR(10),
  recipient_mode VARCHAR(20) NOT NULL,  -- direct | filter | all
  subject TEXT,

  -- Statistics
  total INT DEFAULT 0,
  success INT DEFAULT 0,
  failed INT DEFAULT 0,
  failed_emails JSON DEFAULT (JSON_ARRAY()),

  -- Phase B: Tracking
  open_count INT DEFAULT 0,
  click_count INT DEFAULT 0,

  -- Phase C: Scheduling
  status VARCHAR(20) DEFAULT 'sent',   -- sent | scheduled | sending | cancelled | failed
  scheduled_at TIMESTAMP NULL,
  scheduled_payload JSON DEFAULT NULL,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_email_campaigns_status (status),
  INDEX idx_email_campaigns_scheduled (status, scheduled_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### `email_unsubscribes` (Phase A)

```sql
CREATE TABLE email_unsubscribes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  reason VARCHAR(500),
  source VARCHAR(50) DEFAULT 'link',  -- link | admin
  unsubscribed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### `email_tracking_events` (Phase B)

```sql
CREATE TABLE email_tracking_events (
  id INT AUTO_INCREMENT PRIMARY KEY,
  campaign_id INT NOT NULL,
  email VARCHAR(255) NOT NULL,
  event_type VARCHAR(20) NOT NULL,  -- open | click
  url TEXT,
  user_agent TEXT,
  ip_address VARCHAR(45),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_email_tracking_campaign (campaign_id),
  INDEX idx_email_tracking_event_type (event_type),
  UNIQUE INDEX idx_email_tracking_unique (campaign_id, email, event_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### `users.is_can_test` (Phase D)

```sql
ALTER TABLE users
ADD COLUMN is_can_test TINYINT(1) NOT NULL DEFAULT 0;
-- Index for fast lookup
ALTER TABLE users ADD INDEX idx_users_can_test (is_can_test);
```

### `email_lists` (Phase D)

```sql
CREATE TABLE email_lists (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(255) NOT NULL,
  description TEXT NULL,
  tags        JSON DEFAULT (JSON_ARRAY()),
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_email_lists_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### `email_list_members` (Phase D)

```sql
CREATE TABLE email_list_members (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  list_id    INT NOT NULL,
  user_id    INT NULL,          -- NULL nếu email không có trong bảng users
  email      VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  UNIQUE KEY uq_list_email (list_id, email),
  INDEX idx_list_members_list (list_id),
  INDEX idx_list_members_user (user_id),

  CONSTRAINT fk_list_members_list
    FOREIGN KEY (list_id) REFERENCES email_lists(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

> Migration SQL đầy đủ: [`EMAIL_LIST_MIGRATION.sql`](EMAIL_LIST_MIGRATION.sql)

---

## Environment Variables

Thêm vào `.env`:

```env
# Phase A
APP_URL=https://api.incard.vn  # Used for unsubscribe links, tracking URLs, and email image hosting
UNSUBSCRIBE_SECRET=your-random-secret-at-least-32-chars  # HMAC key

# Phase C: Bull Queue (Redis)
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_PASSWORD=null  # or your redis password

# Email Feature Flags
ENABLE_SEND_ALL_USER=false  # true = cho phép broadcast toàn bộ users khi không có filter
                            # false (default) = chặn, trả về 400 khi không truyền filter nào
                            # Áp dụng cho cả POST /emails/send và POST /emails/schedule

# Xem EMAIL_API.md cho MAIL_* vars
```

> **`ENABLE_SEND_ALL_USER`**: Guard này nằm trong `resolveRecipients()` — kích hoạt khi **không có filter nào** (không có `user_ids`, `user_types`, `industry_ids`, `list_id`, `user_emails`, date range). Nếu có bất kỳ filter nào thì guard không chặn, dù biến này là `false`.

---

## Integration with EMAIL_API

| Feature | EMAIL_API | EMAIL_CAMPAIGN_API |
|---|---|---|
| **Send Email** | ✅ Basic send | ✅ + auto-campaign tracking (Phase A) |
| **Templates** | ✅ CRUD | ✅ Usable in send + schedule |
| **Sender Groups** | ✅ CRUD + set-default | ✅ Usable in send + schedule (pre-fills from_name / from_email / reply_to / signature) |
| **Recipient Filter** | ✅ All filters (incl. `industry_ids`) | ✅ Same filters + schedule support (incl. `industry_ids`, `is_can_test`) |
| **Campaign Tracking** | ❌ | ✅ History + stats (Phase B, C) |
| **Email Unsubscribe** | ❌ | ✅ Footer injection + blacklist (Phase A) |
| **Open/Click Tracking** | ❌ | ✅ Pixel + redirect (Phase B) |
| **Scheduled Send** | ❌ | ✅ Bull Queue + reconciliation (Phase C) |
| **Email Lists** | ❌ | ✅ Named lists + member management (Phase D) |
| **Test Recipients** | ❌ | ✅ `is_can_test` flag + filter (Phase D) |

---

## Related Documentation

- [EMAIL_API.md](EMAIL_API.md) — Basic email send & templates
- [EMAIL_CAMPAIGN_PLAN.md](EMAIL_CAMPAIGN_PLAN.md) — Detailed implementation plan (Phases A, B, C)
- [PHASE_C_IMPLEMENTATION_SUMMARY.md](PHASE_C_IMPLEMENTATION_SUMMARY.md) — Phase C architecture & deployment
- [PHASE_C_TESTING_GUIDE.md](PHASE_C_TESTING_GUIDE.md) — 7 manual test scenarios
- [PHASE_C_SCHEMA_SUMMARY.md](PHASE_C_SCHEMA_SUMMARY.md) — Database schema evolution

---

## Support

For issues or questions:
1. Check related docs above
2. Review test files: `src/modules/email/__tests__/`
3. Run tests: `npm test -- src/modules/email`
