# Email API Documentation

**Version:** 1.5.0
**Base URL:** `http://localhost:3001/api`
**Authentication:** JWT Bearer Token (Admin role required)
**Last Updated:** 2026-03-25

> **📧 New:** For **Email Campaign features** (campaign history, tracking, scheduling), see [EMAIL_CAMPAIGN_API.md](EMAIL_CAMPAIGN_API.md). This document covers basic email sending and template management only.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Authentication](#authentication)
- [Error Handling](#error-handling)
- [API Endpoints](#api-endpoints)
  - [Send Bulk Email](#send-bulk-email)
  - [Get All Templates](#get-all-templates)
  - [Get Template by ID](#get-template-by-id)
  - [Create Template](#create-template)
  - [Update Template](#update-template)
  - [Delete Template](#delete-template)
- [Recipient Filter Reference](#recipient-filter-reference)
- [Upload Image for Email Body](#upload-image-for-email-body)
- [Content Resolution Logic](#content-resolution-logic)
- [Email Signatures](#email-signatures)
- [AI Settings & Knowledge Base](#ai-settings--knowledge-base)
- [Database Schema](#database-schema)
- [Environment Variables](#environment-variables)

---

## Overview

Email Module cung cấp khả năng **gửi email hàng loạt** cho user trong hệ thống InCard CMS, với các tính năng:

- Gửi đến tất cả user, hoặc lọc theo **user ID**, **địa chỉ email**, **loại tài khoản**, hoặc **ngày đăng ký**
- Nội dung email có thể **nhập tay tự do** hoặc **lấy từ template** có sẵn trong DB (hỗ trợ đa ngôn ngữ VI/EN)
- Hỗ trợ **override** nội dung từ template (giữ body, đổi subject, hoặc ngược lại)
- Nội dung sau khi chỉnh sửa có thể **lưu thành template mới** để tái sử dụng
- Tích hợp **Nodemailer + SMTP** (Mailgun, Gmail, hoặc bất kỳ SMTP provider nào)
- Trả về kết quả chi tiết: tổng gửi, thành công, thất bại, danh sách email lỗi

---

## Architecture

```
EmailController  ──(AuthGuard + AdminGuard)──►  Chỉ admin/super admin
      │
      ▼
EmailService
  ├── resolveContent()      ← Xác định subject/body (template hoặc free-form)
  ├── resolveRecipients()   ← Query DB theo filter → danh sách email
  └── Nodemailer.sendMail() ← Gửi từng email qua SMTP (synchronous)
      │
      ├── EmailTemplate repository   (bảng email_templates)
      ├── EmailTemplateLang repository (bảng email_template_langs)
      └── User repository            (bảng users)
```

**Luồng gửi email:**

```
POST /api/emails/send
  │
  ├─► Xác thực JWT + kiểm tra quyền admin
  ├─► resolveContent(): lấy subject + body
  │     ├── Có template_id → đọc từ email_template_langs theo lang (default: 'vi')
  │     │     └── Admin có thể override subject và/hoặc body
  │     └── Không có template_id → dùng subject + body nhập tay
  ├─► resolveRecipients(): lấy danh sách email
  │     ├── user_emails → trả về ngay, không query DB
  │     ├── list_id → query email_list_members [Phase D]
  │     ├── user_ids / user_types / created_from+to → query bảng users
  │     ├── is_can_test → áp dụng filter users.is_can_test=1 [Phase D]
  │     └── Không có filter → lấy toàn bộ users
  └─► Loop sendMail() → trả về { total, success, failed, failed_emails }
```

---

## Authentication

Tất cả endpoint đều yêu cầu JWT và quyền admin.

### Required Headers

```http
Authorization: Bearer <your-jwt-token>
Content-Type: application/json
```

### Admin Role Requirements

Field `type` trong bảng `users` phải là một trong:
- `admin`
- `super admin`

### Error Responses khi thiếu auth

| HTTP | Message | Nguyên nhân |
|---|---|---|
| `401 Unauthorized` | `Token xác thực không được cung cấp` | Thiếu header Authorization |
| `401 Unauthorized` | `Token không hợp lệ hoặc đã hết hạn` | Token sai hoặc expired |
| `403 Forbidden` | `Chỉ admin mới có quyền truy cập` | User không có quyền admin |

---

## Error Handling

### Format lỗi chuẩn

```json
{
  "statusCode": 400,
  "message": "Mô tả lỗi",
  "error": "Bad Request"
}
```

### Các mã lỗi

| HTTP | Trường hợp |
|---|---|
| `400 Bad Request` | Thiếu `subject`/`body` khi không dùng `template_id`; validation DTO thất bại |
| `401 Unauthorized` | Thiếu hoặc sai JWT token |
| `403 Forbidden` | User không phải admin |
| `404 Not Found` | Template ID không tồn tại; template không có lang tương ứng |

---

## API Endpoints

---

### Send Bulk Email

Gửi email hàng loạt đến danh sách user được lọc theo điều kiện.

```http
POST /api/emails/send
```

#### Request Body

| Field | Type | Bắt buộc | Mô tả |
|---|---|---|---|
| `user_ids` | `number[]` | Không | Lọc user theo danh sách ID |
| `user_emails` | `string[]` | Không | Gửi trực tiếp đến danh sách email (không query DB) |
| `user_types` | `string[]` | Không | Lọc theo loại: `"user"`, `"admin"`, `"super admin"` |
| `created_from` | `string` | Không | Lọc user đăng ký từ ngày (ISO 8601: `YYYY-MM-DD`) |
| `created_to` | `string` | Không | Lọc user đăng ký đến ngày (ISO 8601: `YYYY-MM-DD`) |
| `template_id` | `number` | Không | ID template có sẵn trong DB |
| `lang` | `string` | Không | Ngôn ngữ template cần dùng (default: `"vi"`) |
| `subject` | `string` | Có (*) | Tiêu đề email — bắt buộc nếu không có `template_id` |
| `body` | `string` | Có (*) | Nội dung HTML — bắt buộc nếu không có `template_id` |
| `campaign_name` | `string` | Không | Tên campaign tùy chỉnh. Nếu không cung cấp → fallback: `"Email Campaign - YYYY-MM-DD"` |
| `include_unsubscribe_link` | `boolean` | Không | Tự động thêm unsubscribe footer (default: `true`) |
| `redirect_url` | `string` | Không | URL cố định để redirect tất cả link trong email (vẫn tracking được click từng link) |
| `url_images` | `array` | Không | Danh sách ảnh URL để inject vào body: `[{ filename: string, url: string }, ...]` — phải public URL |
| `list_id` | `number` | Không | **[Phase D]** Gửi cho toàn bộ members trong Email List (xem [EMAIL_CAMPAIGN_API.md](EMAIL_CAMPAIGN_API.md#phase-d--email-list-management)) |
| `is_can_test` | `boolean` | Không | **[Phase D]** Nếu `true` → chỉ gửi cho users có `is_can_test=1`. Kết hợp được với bất kỳ filter nào (trừ `user_emails`) |
| `from_name` | `string` | Không | Override tên người gửi hiển thị (e.g. `"Tâm Hồ từ InCard"`). Ưu tiên: `dto.from_name` → `template.from_name` → `MAIL_FROM_NAME` từ `.env` |
| `from_email` | `string` | Không | Override địa chỉ email gửi thực sự. Phải là domain đã verify trên SendGrid (`@incard.biz` hoặc `@inapps.net`). Ưu tiên: `dto.from_email` → `template.from_email` → `MAIL_FROM_ADDRESS` từ `.env` |
| `reply_to` | `string` | Không | Override địa chỉ Reply-To email. Ưu tiên: `dto.reply_to` → `template.reply_to` → _(không set header)_ |

> **(\*)** Khi có `template_id`: `subject` và `body` là **optional** (dùng để override nội dung từ template).
> Khi không có `template_id`: cả hai là **bắt buộc**.

> **Ưu tiên filter recipient** (cao → thấp):
> 1. `user_emails` — gửi thẳng, không query DB
> 2. `list_id` — lấy emails từ `email_list_members`
> 3. `user_ids` / `user_types` / `created_from`+`created_to` — filter từ bảng users
> 4. _(none)_ — toàn bộ users
>
> `is_can_test=true` luôn áp dụng sau khi resolve recipients (trừ `user_emails`).

> **Không truyền filter nào** → gửi cho **toàn bộ user** trong hệ thống.

#### Response

```json
{
  "status": true,
  "message": "Gửi email hoàn tất: 98/100 thành công",
  "data": {
    "total": 100,
    "success": 98,
    "failed": 2,
    "failed_emails": ["err1@example.com", "err2@example.com"]
  }
}
```

#### Ví dụ

**1. Gửi tất cả user — nhập tay:**
```json
{
  "subject": "Thông báo từ InCard",
  "body": "<h1>Xin chào!</h1><p>Nội dung email.</p>"
}
```

**2. Gửi theo danh sách user ID:**
```json
{
  "user_ids": [1, 5, 12, 20],
  "subject": "Thông báo cá nhân",
  "body": "<p>Email dành riêng cho bạn.</p>"
}
```

**3. Gửi trực tiếp theo email (không query DB):**
```json
{
  "user_emails": ["alice@example.com", "bob@example.com"],
  "subject": "Thông báo",
  "body": "<p>Nội dung.</p>"
}
```

**4. Lọc theo loại tài khoản:**
```json
{
  "user_types": ["admin", "super admin"],
  "subject": "Thông báo nội bộ",
  "body": "<p>Dành cho admin.</p>"
}
```

**5. Lọc theo ngày đăng ký:**
```json
{
  "created_from": "2024-01-01",
  "created_to": "2024-06-30",
  "subject": "Chào mừng thành viên H1/2024",
  "body": "<p>Cảm ơn bạn đã tham gia!</p>"
}
```

**6. Dùng template (tiếng Việt, mặc định):**
```json
{
  "template_id": 3
}
```

**7. Dùng template tiếng Anh — lọc theo type:**
```json
{
  "template_id": 3,
  "lang": "en",
  "user_types": ["user"]
}
```

**8. Dùng template nhưng override subject:**
```json
{
  "template_id": 3,
  "lang": "vi",
  "subject": "[Khẩn] Tiêu đề mới thay thế",
  "user_ids": [1, 2, 3]
}
```

**9. Kết hợp nhiều filter:**
```json
{
  "user_types": ["user"],
  "created_from": "2024-06-01",
  "created_to": "2024-12-31",
  "template_id": 3,
  "lang": "vi"
}
```

**10. Gửi với campaign name tùy chỉnh:**
```json
{
  "campaign_name": "Newsletter Tháng 3 - Khuyến mãi đặc biệt",
  "subject": "Tin khuyến mãi",
  "body": "<p>Khuyến mãi tháng 3...</p>"
}
```

**11. Gửi với ảnh từ URL (logo + banner):**
```json
{
  "subject": "Email với ảnh",
  "body": "<p>Dưới đây là logo và banner:</p>",
  "url_images": [
    {
      "filename": "logo.png",
      "url": "https://cdn.example.com/logo.png"
    },
    {
      "filename": "banner.jpg",
      "url": "https://cdn.example.com/banner.jpg"
    }
  ]
}
```

**12. Gửi campaign với ảnh + tên tùy chỉnh:**
```json
{
  "campaign_name": "Newsletter Tháng 3 - Khuyến mãi đặc biệt",
  "subject": "Email với ảnh",
  "body": "<p>Khuyến mãi:</p>",
  "url_images": [
    {
      "filename": "promo-banner.jpg",
      "url": "https://cdn.incard.vn/promos/march-2026.jpg"
    }
  ],
  "include_unsubscribe_link": true
}
```

**13. Gửi ảnh động (versioning URL):**
```json
{
  "subject": "Dynamic Banner",
  "body": "<p>Custom banner per user:</p>",
  "url_images": [
    {
      "filename": "user-banner.jpg",
      "url": "https://api.example.com/banners/v1?user={{user_id}}&lang={{lang}}"
    }
  ]
}
```

---

### Get All Templates

Lấy danh sách tất cả email templates, kèm theo toàn bộ `langs`.

```http
GET /api/emails/templates
```

#### Response

```json
{
  "status": true,
  "message": "OK",
  "data": [
    {
      "id": 2,
      "name": "Weekly Report",
      "from_name": "Báo Cáo Tuần từ InCard",
      "from_email": "report@incard.biz",
      "reply_to": null,
      "created_by": 1,
      "created_at": "2024-02-01T10:00:00.000Z",
      "updated_at": "2024-02-01T10:00:00.000Z",
      "langs": [
        {
          "id": 3,
          "parent_id": 2,
          "lang": "vi",
          "subject": "Báo cáo tuần của bạn",
          "content": "<h1>Báo cáo tuần</h1><p>...</p>"
        },
        {
          "id": 4,
          "parent_id": 2,
          "lang": "en",
          "subject": "Your Weekly Report",
          "content": "<h1>Weekly Report</h1><p>...</p>"
        }
      ]
    }
  ]
}
```

> Kết quả được sắp xếp theo `created_at DESC` (template mới nhất trước).

---

### Get Template by ID

Lấy chi tiết một template theo ID.

```http
GET /api/emails/templates/:id
```

#### Path Parameters

| Param | Type | Mô tả |
|---|---|---|
| `id` | `number` | ID của template |

#### Response

```json
{
  "status": true,
  "message": "OK",
  "data": {
    "id": 1,
    "name": "Welcome Email",
    "from_name": null,
    "from_email": null,
    "reply_to": null,
    "created_by": 1,
    "created_at": "2024-01-15T08:00:00.000Z",
    "updated_at": "2024-01-15T08:00:00.000Z",
    "langs": [
      {
        "id": 1,
        "parent_id": 1,
        "lang": "vi",
        "subject": "Chào mừng đến InCard!",
        "content": "<h1>Xin chào!</h1><p>Cảm ơn bạn đã đăng ký.</p>"
      },
      {
        "id": 2,
        "parent_id": 1,
        "lang": "en",
        "subject": "Welcome to InCard!",
        "content": "<h1>Hello!</h1><p>Thank you for signing up.</p>"
      }
    ]
  }
}
```

#### Error

```json
{
  "statusCode": 404,
  "message": "Template #999 không tồn tại",
  "error": "Not Found"
}
```

---

### Create Template

Tạo email template mới với nhiều phiên bản ngôn ngữ.

```http
POST /api/emails/templates
```

#### Request Body

| Field | Type | Bắt buộc | Mô tả |
|---|---|---|---|
| `name` | `string` | Có | Tên định danh template |
| `from_name` | `string` | Có | Tên người gửi hiển thị (e.g. `"Tâm Hồ từ InCard"`). Dùng kết hợp với `from_email` hoặc `MAIL_FROM_ADDRESS` làm From header |
| `from_email` | `string` | Không | Địa chỉ email gửi thực sự. Phải là domain đã verify trên SendGrid (`@incard.biz` hoặc `@inapps.net`). Để trống = dùng `MAIL_FROM_ADDRESS` từ env |
| `reply_to` | `string` | Không | Reply-To email (e.g. `"tamho@incard.biz"`). Khi set, email client sẽ reply về địa chỉ này. Chỉ cho phép `@incard.biz` hoặc `@inapps.net` |
| `langs` | `LangItem[]` | Có | Mảng nội dung theo ngôn ngữ (có thể để `[]`) |

**`LangItem`:**

| Field | Type | Bắt buộc | Mô tả |
|---|---|---|---|
| `lang` | `string` | Có | Mã ngôn ngữ: `"vi"`, `"en"`, ... |
| `subject` | `string` | Có | Tiêu đề email |
| `content` | `string` | Có | Nội dung HTML |

#### Request

```json
{
  "name": "Welcome Email",
  "from_name": "Đội ngũ InCard",
  "from_email": "hello@incard.biz",
  "reply_to": "support@incard.biz",
  "langs": [
    {
      "lang": "vi",
      "subject": "Chào mừng đến InCard!",
      "content": "<h1>Xin chào!</h1><p>Cảm ơn bạn đã đăng ký InCard.</p>"
    },
    {
      "lang": "en",
      "subject": "Welcome to InCard!",
      "content": "<h1>Hello!</h1><p>Thank you for joining InCard.</p>"
    }
  ]
}
```

**Email header result:**
```
From: "Đội ngũ InCard" <hello@incard.biz>
Reply-To: support@incard.biz
```

#### Response `201 Created`

```json
{
  "status": true,
  "message": "OK",
  "data": {
    "id": 5,
    "name": "Welcome Email",
    "from_name": "Đội ngũ InCard",
    "from_email": "hello@incard.biz",
    "reply_to": "support@incard.biz",
    "created_by": 7,
    "created_at": "2026-02-24T10:30:00.000Z",
    "updated_at": "2026-02-24T10:30:00.000Z",
    "langs": [
      { "id": 9, "parent_id": 5, "lang": "vi", "subject": "Chào mừng đến InCard!", "content": "..." },
      { "id": 10, "parent_id": 5, "lang": "en", "subject": "Welcome to InCard!", "content": "..." }
    ]
  }
}
```

> `created_by` được tự động lấy từ `id` của admin đang đăng nhập qua JWT.

---

### Update Template

Cập nhật thông tin và/hoặc nội dung ngôn ngữ của template.

```http
PUT /api/emails/templates/:id
```

#### Path Parameters

| Param | Type | Mô tả |
|---|---|---|
| `id` | `number` | ID của template cần cập nhật |

#### Request Body (tất cả đều optional)

| Field | Type | Mô tả |
|---|---|---|
| `name` | `string` | Đổi tên template |
| `from_name` | `string` | Đổi tên người gửi hiển thị (From header) |
| `from_email` | `string` | Đổi địa chỉ email gửi thực sự (`@incard.biz` hoặc `@inapps.net`) |
| `reply_to` | `string` | Đổi địa chỉ Reply-To email (`@incard.biz` hoặc `@inapps.net`) |
| `langs` | `LangItem[]` | Thay toàn bộ langs — **xóa cũ, thêm mới** |

> **Lưu ý quan trọng về `langs`:** Nếu truyền `langs`, toàn bộ langs cũ sẽ bị **xóa** và thay bằng danh sách mới. Không truyền `langs` → langs hiện tại được **giữ nguyên**.

**Ví dụ — chỉ đổi tên (giữ langs cũ):**
```json
{
  "name": "Welcome Email v2"
}
```

**Ví dụ — cập nhật toàn bộ langs:**
```json
{
  "name": "Welcome Email v2",
  "langs": [
    {
      "lang": "vi",
      "subject": "[Cập nhật] Chào mừng đến InCard!",
      "content": "<h1>Xin chào!</h1><p>Nội dung đã được cập nhật.</p>"
    }
  ]
}
```

#### Response `200 OK`

```json
{
  "status": true,
  "message": "OK",
  "data": {
    "id": 1,
    "name": "Welcome Email v2",
    "from_name": null,
    "from_email": null,
    "reply_to": null,
    "created_by": 1,
    "created_at": "2024-01-15T08:00:00.000Z",
    "updated_at": "2026-02-24T11:00:00.000Z",
    "langs": [
      {
        "id": 11,
        "parent_id": 1,
        "lang": "vi",
        "subject": "[Cập nhật] Chào mừng đến InCard!",
        "content": "<h1>Xin chào!</h1><p>Nội dung đã được cập nhật.</p>"
      }
    ]
  }
}
```

---

### Delete Template

Xóa template và toàn bộ langs liên quan.

```http
DELETE /api/emails/templates/:id
```

#### Path Parameters

| Param | Type | Mô tả |
|---|---|---|
| `id` | `number` | ID của template cần xóa |

> **Không thể hoàn tác.** Thao tác xóa theo thứ tự: xóa toàn bộ `email_template_langs` trước, sau đó xóa `email_templates`.

#### Response `200 OK`

```json
{
  "status": true,
  "message": "Xóa template thành công",
  "data": null
}
```

#### Error

```json
{
  "statusCode": 404,
  "message": "Template #999 không tồn tại",
  "error": "Not Found"
}
```

---

## Campaign Name

Mỗi lần gọi `POST /api/emails/send`, hệ thống tự động tạo **campaign record** để tracking:

| Trường | Giá trị | Mô tả |
|---|---|---|
| `name` | User cung cấp hoặc fallback | Tên campaign lưu vào DB |
| `status` | `sending` → `sent` | Trạng thái gửi |
| `total` | Số lượng recipients | Tổng email được gửi |
| `success` | Số thành công | Email gửi thành công |
| `failed` | Số thất bại | Email lỗi, không gửi được |

### Fallback Logic

Nếu không cung cấp `campaign_name`, hệ thống sẽ fallback:

```
campaign_name = "Email Campaign - YYYY-MM-DD"
```

**Ví dụ:**
- 2026-03-09 → `"Email Campaign - 2026-03-09"`
- 2026-03-10 → `"Email Campaign - 2026-03-10"`

### Tùy chỉnh Campaign Name

Cung cấp `campaign_name` trong request để override fallback:

```json
{
  "campaign_name": "Newsletter Tháng 3 - Khuyến mãi 50%",
  "subject": "Khuyến mãi khủng",
  "body": "..."
}
```

**Kết quả:** Campaign record sẽ có `name = "Newsletter Tháng 3 - Khuyến mãi 50%"`

---

## Upload Image for Email Body

Upload ảnh trực tiếp từ CMS rich editor. Ảnh được lưu vào server và trả về public URL để chèn vào email body.

```http
POST /api/emails/upload-image
Content-Type: multipart/form-data
```

### Request

| Field | Type | Bắt buộc | Mô tả |
|---|---|---|---|
| `file` | `binary` | Có | File ảnh (PNG, JPG, GIF, WEBP). Tối đa **10MB** |

### Response `200 OK`

```json
{
  "success": true,
  "data": {
    "url": "http://localhost:3001/storage/email-images/a1b2c3d4-uuid.png"
  }
}
```

### Error Responses

| HTTP | Message | Nguyên nhân |
|---|---|---|
| `400` | `Chỉ chấp nhận file ảnh` | File không phải image (PDF, ZIP, v.v.) |
| `400` | `Vui lòng chọn file ảnh` | Không gửi file trong request |

### Storage

- **Lưu tại:** `storage/app/public/email-images/`
- **URL prefix:** `/storage/email-images/` (served bởi NestJS static assets)
- **Filename:** UUID random — tránh trùng lặp
- **Production:** Đổi `APP_URL` trong `.env` thành domain thật (e.g. `https://api.incard.biz`)

### Base64 Auto-Conversion

Khi user paste ảnh vào rich editor mà **không có** upload handler, TipTap sẽ lưu ảnh dưới dạng `data:image/...;base64,...` trong HTML body.

**Tại thời điểm gửi email**, hệ thống **tự động** scan body HTML và convert tất cả base64 images thành hosted URLs:

```
<img src="data:image/png;base64,iVBORw0KGgo...133KB...">
                    ↓ auto-convert at send time
<img src="http://localhost:3001/storage/email-images/uuid.png">
```

Điều này đảm bảo:
- Gmail không bị clip (giới hạn 102KB)
- Tracking pixel và unsubscribe link luôn hiển thị
- Email size nhỏ gọn (~60 chars URL thay vì 133KB base64)

### Frontend Integration (CMS)

Rich editor trong CMS đã tích hợp sẵn:
- **Toolbar button "Add Image"** — mở file picker, upload qua API, chèn URL
- **Paste image** (Ctrl+V screenshot) — tự động upload, chèn URL
- **Drag & drop** — tự động upload, chèn URL

---

## Images Support

Email API hỗ trợ chèn ảnh vào email qua **URL images** (best practice):

### URL Images (Recommended)

Cung cấp URL công khai của ảnh — API inject trực tiếp vào HTML **không download, không attachment**:

```json
{
  "url_images": [
    {
      "filename": "banner.jpg",
      "url": "https://cdn.example.com/banner.jpg"
    },
    {
      "filename": "logo.png",
      "url": "https://cdn.example.com/logo.png"
    }
  ]
}
```

**Ưu điểm:**
- ✅ **Email nhỏ gọn** — chỉ chứa URL reference, không phình to Base64
- ✅ **Tương thích 100%** — mọi email client support (Gmail, Outlook, Apple Mail)
- ✅ **Dễ update** — thay đổi ảnh mà không resend campaign
- ✅ **Best practice** — Mailchimp, SendGrid, ConvertKit đều dùng cách này
- ✅ **CDN-friendly** — ảnh từ CDN được cache tự động
- ✅ **Analytics** — track image loads, referer logs

**Nhược điểm:**
- Ảnh phải public (accessible từ email client)
- Nếu CDN down → email client không tải được ảnh

### Image Injection & Display

Flow xử lý ảnh:
1. **Validate URL** — kiểm tra format (không fetch từ server)
2. **Inject vào HTML** — tự động thêm `<img src="URL">` tag trước tag `</body>`
3. **Email client fetch** — client sẽ download ảnh khi user xem email

**HTML được tạo tự động:**
```html
<img src="https://cdn.example.com/banner.jpg" alt="banner.jpg" style="max-width: 100%; height: auto; margin: 10px 0;" />
```

> **Lưu ý:** Ảnh được inject **trước footer unsubscribe** (nếu có), **sau tracking pixel**. Thứ tự injection: unsubscribe footer → images → tracking pixel.

### Best Practices

| Tình huống | Khuyến nghị |
|---|---|
| Logo công ty, ảnh cố định | Lưu trên CDN, reuse URL (cache) |
| Banner thay đổi theo campaign | Lưu trên CDN với versioning (e.g., `/v1/`, `/v2/`) |
| Ảnh cá nhân hoá | Tạo dynamic URL (e.g., `/banner?user=123&lang=vi`) |
| Performance | CDN gần user (CloudFlare, AWS CloudFront, ...) |

### Requirements

- **URL phải public**: Email client phải truy cập được từ internet
- **HTTPS recommended**: Tránh "mixed content" warning
- **No auth headers**: Email client không gửi auth credentials → URL phải public
- **Timeout**: Email client có timeout, ảnh phải load < 5s

---

## Recipient Filter Reference

Bảng tóm tắt tất cả cách lọc recipient cho `POST /api/emails/send`:

| Filter | Field | Ví dụ | Ghi chú |
|---|---|---|---|
| Tất cả user | _(không truyền gì)_ | `{}` | Broadcast toàn bộ |
| Theo email | `user_emails` | `["a@b.com"]` | Không query DB — nhanh nhất; bỏ qua mọi filter khác |
| Theo Email List | `list_id` | `3` | Lấy từ `email_list_members` — ưu tiên 2 |
| Theo user ID | `user_ids` | `[1, 5, 20]` | Query `WHERE id IN (...)` |
| Theo loại TK | `user_types` | `["admin"]` | Query `WHERE type IN (...)` |
| Theo ngày ĐK | `created_from` + `created_to` | `"2024-01-01"` | `WHERE created_at BETWEEN ... AND ...` — `created_to` set 23:59:59 |
| Chỉ test users | `is_can_test: true` | `true` | Kết hợp với bất kỳ filter trên (trừ `user_emails`) |
| Kết hợp | Nhiều field | Xem ví dụ 9 | `user_ids` + `user_types` + date dùng AND logic |

> **Ưu tiên:** `user_emails` → `list_id` → `user_ids`/`user_types`/date → _(all users)_. `is_can_test` luôn áp dụng sau cùng (trừ `user_emails`).

---

## Content Resolution Logic

Sơ đồ quyết định nội dung email khi gọi `POST /api/emails/send`:

```
Có template_id?
├── Có
│   ├── Tìm template trong DB → không tồn tại → 404 NotFoundException
│   ├── Tìm lang theo `lang` (default: 'vi') trong template.langs
│   │   └── Không có lang phù hợp → fallback về langs[0]
│   │       └── Không có langs nào → 404 NotFoundException
│   ├── subject = dto.subject ?? templateLang.subject   ← admin có thể override
│   └── body    = dto.body    ?? templateLang.content   ← admin có thể override
└── Không
    ├── dto.subject + dto.body đều có → dùng trực tiếp
    └── Thiếu một trong hai → 400 BadRequestException
```

**Use cases phổ biến:**

| Tình huống | Cần truyền |
|---|---|
| Nhập tay hoàn toàn | `subject` + `body` |
| Dùng template nguyên vẹn | `template_id` (+ `lang` nếu cần EN) |
| Template + đổi tiêu đề | `template_id` + `subject` |
| Template + đổi cả nội dung | `template_id` + `subject` + `body` |
| Lưu nội dung đã chỉnh thành template mới | Gọi thêm `POST /api/emails/templates` |

---

## Sender Identity (from_name + from_email + Reply-To)

### Email Header Result

Hệ thống hỗ trợ override 3 trường sender ở 3 cấp độ: **per-campaign** → **template** → **env default**.

```
From: "Tâm Hồ từ InCard" <Marketing@incard.biz>   ← from_name + from_email (hoặc MAIL_FROM_ADDRESS)
Reply-To: tamho@incard.biz                          ← chỉ set khi reply_to được cung cấp
```

### Priority Chain

| Header | Ưu tiên 1 (campaign) | Ưu tiên 2 (template) | Ưu tiên 3 (env fallback) |
|---|---|---|---|
| `From` tên | `dto.from_name` | `template.from_name` | `MAIL_FROM_NAME` từ `.env` |
| `From` address | `dto.from_email` | `template.from_email` | `MAIL_FROM_ADDRESS` từ `.env` |
| `Reply-To` | `dto.reply_to` | `template.reply_to` | _(không set header)_ |

> **Lưu ý:** Nếu không có giá trị nào cho `Reply-To`, header `Reply-To` sẽ **không** được thêm vào email.
> `from_email` phải là domain đã verify trên SendGrid: `@incard.biz` hoặc `@inapps.net`.

### Use Cases

| Tình huống | Cách dùng |
|---|---|
| Gửi dưới tên cá nhân, địa chỉ riêng | Set `from_name` + `from_email` trong template |
| Override tên và địa chỉ cho một campaign | Truyền `from_name` + `from_email` trong `POST /emails/send` |
| Cho phép user reply về hộp thư riêng | Set `reply_to` trong template hoặc request |
| Dùng tên + địa chỉ mặc định từ env | Không truyền `from_name`/`from_email` |
| Sender Name helper ("từ InCard") | Frontend: user nhập tên phần → stored as `"Tên từ InCard"` |

---

## Email Signatures

Email Signature là chữ ký email được đính kèm tự động vào mỗi email gửi đi. Admin có thể quản lý nhiều signature và chọn một làm active.

**Base path:** `GET|POST|PATCH|DELETE /api/admin/email-signatures`
**Auth:** `AuthGuard` + `AdminGuard`

### Auto-activation

- Signature đầu tiên tạo ra sẽ tự động được set `is_active = 1`
- Chỉ có **1 signature active** tại một thời điểm — khi activate một signature, tất cả signature còn lại bị set inactive
- Khi xóa signature đang active → signature tiếp theo trong danh sách (theo `created_at ASC`) tự động được kích hoạt

---

### List All Signatures

```http
GET /api/admin/email-signatures
```

#### Response

```json
{
  "status": true,
  "message": "Lấy danh sách signatures thành công",
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "label": "Chữ ký chính",
      "name": "Tâm Hồ",
      "title": "CEO",
      "company": "InCard",
      "phone": "+84 901 234 567",
      "email": "tamho@incard.biz",
      "website": "https://incard.vn",
      "isActive": 1,
      "createdAt": "2026-03-01T08:00:00.000Z",
      "updatedAt": "2026-03-01T08:00:00.000Z"
    }
  ]
}
```

> Kết quả sắp xếp theo `created_at ASC`.

---

### Create Signature

```http
POST /api/admin/email-signatures
```

#### Request Body

| Field | Type | Bắt buộc | Mô tả |
|---|---|---|---|
| `label` | `string` | Không | Tên hiển thị trong danh sách (default: `name` hoặc `company`) |
| `name` | `string` | Có (*) | Tên người ký |
| `title` | `string` | Không | Chức vụ |
| `company` | `string` | Có (*) | Tên công ty |
| `phone` | `string` | Không | Số điện thoại |
| `email` | `string` | Không | Email hiển thị trong signature |
| `website` | `string` | Không | Website |

> **(\*)** Cần ít nhất `name` **hoặc** `company`.

#### Response `201 Created`

```json
{
  "status": true,
  "message": "Tạo signature thành công",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "label": "Chữ ký chính",
    "name": "Tâm Hồ",
    "title": "CEO",
    "company": "InCard",
    "phone": "+84 901 234 567",
    "email": "tamho@incard.biz",
    "website": "https://incard.vn",
    "isActive": 1,
    "createdAt": "2026-03-25T08:00:00.000Z",
    "updatedAt": "2026-03-25T08:00:00.000Z"
  }
}
```

---

### Update Signature

```http
PATCH /api/admin/email-signatures/:id
```

Tất cả fields đều optional — chỉ cập nhật những field được truyền vào.

> **Lưu ý:** `isActive` không thể cập nhật qua endpoint này. Dùng endpoint **Activate** bên dưới.

#### Response `200 OK`

Trả về signature sau khi cập nhật (cùng format với Create).

---

### Delete Signature

```http
DELETE /api/admin/email-signatures/:id
```

#### Response `200 OK`

```json
{
  "status": true,
  "message": "Xóa signature thành công",
  "data": { "success": true }
}
```

#### Error

```json
{ "status": false, "message": "Không tìm thấy signature", "data": null }
```

---

### Set Active Signature

Chọn một signature làm active. Signature active sẽ được đính kèm vào email gửi đi.

```http
POST /api/admin/email-signatures/:id/activate
```

#### Response `200 OK`

```json
{
  "status": true,
  "message": "Đặt signature active thành công",
  "data": { "success": true }
}
```

---

### Database Schema — `email_signatures`

```sql
CREATE TABLE email_signatures (
  id         VARCHAR(36) NOT NULL PRIMARY KEY,  -- UUID
  label      VARCHAR(191) NOT NULL,             -- tên hiển thị trong danh sách
  name       VARCHAR(191) NOT NULL DEFAULT '',  -- tên người ký
  title      VARCHAR(191) NOT NULL DEFAULT '',  -- chức vụ
  company    VARCHAR(191) NOT NULL DEFAULT '',  -- tên công ty
  phone      VARCHAR(191) NOT NULL DEFAULT '',  -- số điện thoại
  email      VARCHAR(191) NOT NULL DEFAULT '',  -- email hiển thị
  website    VARCHAR(191) NOT NULL DEFAULT '',  -- website
  is_active  TINYINT NOT NULL DEFAULT 0,        -- 1 = đang active
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

---

## AI Settings & Knowledge Base

Admin có thể cấu hình AI model, system prompt, và upload PDF làm knowledge base để AI generate email body chính xác hơn theo brand/sản phẩm.

Tất cả settings được lưu trong bảng `setting_ai_email` (key-value store).

**Base path:** `GET|PUT /api/admin/settings/:key` và `GET|POST|DELETE /api/admin/settings/knowledge-base`
**Auth:** `AuthGuard` + `AdminGuard`

---

### Get AI Settings

```http
GET /api/admin/settings/ai_email_settings
```

#### Response

```json
{
  "status": true,
  "message": "Lấy cài đặt thành công",
  "data": {
    "key": "ai_email_settings",
    "value": "{\"model\":\"gpt-4.1-mini\",\"systemPrompt\":\"...\",\"subjectSystemPrompt\":\"...\",\"userPromptTemplate\":\"{input}\"}"
  }
}
```

> `value` là JSON string. Parse để lấy các field con.

---

### Update AI Settings

```http
PUT /api/admin/settings/ai_email_settings
```

#### Request Body

```json
{
  "value": "{\"model\":\"gpt-4o\",\"systemPrompt\":\"You are...\",\"subjectSystemPrompt\":\"Write a subject...\",\"userPromptTemplate\":\"{input}\"}"
}
```

| Field trong `value` (JSON) | Mô tả | Default |
|---|---|---|
| `model` | OpenAI model ID | `gpt-4.1-mini` |
| `systemPrompt` | System prompt cho generate **body** email | Xem `ai-prompt-storage.ts` |
| `subjectSystemPrompt` | System prompt cho generate **subject** email | Xem `ai-prompt-storage.ts` |
| `userPromptTemplate` | Template bọc input của user — phải chứa `{input}` | `{input}` |

---

### Upload Knowledge Base (PDF)

Upload file PDF làm knowledge base. Backend extract text, lưu vào DB. AI sẽ dùng text này khi generate email body.

```http
POST /api/admin/settings/knowledge-base/upload
Content-Type: multipart/form-data
```

#### Request

| Field | Type | Bắt buộc | Mô tả |
|---|---|---|---|
| `file` | `binary` | Có | File PDF. Tối đa **5MB**. Chỉ chấp nhận `application/pdf` |

#### Response `200 OK`

```json
{
  "status": true,
  "message": "Knowledge base đã được cập nhật",
  "data": {
    "filename": "incard-brand-guide.pdf",
    "size_bytes": 204800,
    "char_count": 12500,
    "uploaded_at": "2026-03-25T10:00:00.000Z"
  }
}
```

#### Error Responses

| HTTP | Message | Nguyên nhân |
|---|---|---|
| `400` | `Vui lòng chọn file PDF` | Không gửi file |
| `400` | `Chỉ chấp nhận file PDF` | File không phải PDF |
| `400` | `File quá lớn (tối đa 5MB)` | File > 5MB |
| `400` | `File PDF không chứa text` | PDF toàn ảnh scan, không có text layer |
| `400` | `Không thể đọc nội dung từ file PDF: ...` | PDF bị password protect hoặc corrupted |

> **Giới hạn text:** PDF được truncate về tối đa **50,000 ký tự** (~10,000 tokens). Upload file mới sẽ **thay thế** knowledge base cũ.

---

### Get Knowledge Base Metadata

```http
GET /api/admin/settings/knowledge-base
```

#### Response khi có knowledge base

```json
{
  "status": true,
  "message": "Lấy knowledge base thành công",
  "data": {
    "filename": "incard-brand-guide.pdf",
    "size_bytes": 204800,
    "char_count": 12500,
    "uploaded_at": "2026-03-25T10:00:00.000Z",
    "preview": "InCard là nền tảng danh thiếp kỹ thuật số hàng đầu Việt Nam..."
  }
}
```

> `preview` chứa **500 ký tự đầu** của extracted text.

#### Response khi chưa có

```json
{
  "status": true,
  "message": "Lấy knowledge base thành công",
  "data": null
}
```

---

### Delete Knowledge Base

```http
DELETE /api/admin/settings/knowledge-base
```

#### Response `200 OK`

```json
{
  "status": true,
  "message": "Đã xóa knowledge base",
  "data": null
}
```

---

### How Knowledge Base Affects AI Generation

Khi admin upload PDF, text được inject vào system prompt lúc generate email:

```
[Existing system prompt]

## Brand & Company Knowledge

Use the following information about the company when writing emails.
Stay consistent with the brand voice, product names, and key messages described below.

[Extracted PDF text — max 50,000 chars]
```

**Áp dụng:** Chỉ khi generate **body** (`type=body`). Subject generation không dùng knowledge base.

**Fallback:** Nếu knowledge base chưa được upload hoặc fetch lỗi → AI generate bình thường, không bị block.

---

### Keys trong `setting_ai_email`

| Key | Nội dung |
|---|---|
| `ai_email_settings` | JSON: `{ model, systemPrompt, subjectSystemPrompt, userPromptTemplate }` |
| `ai_knowledge_base` | Plain text extracted từ PDF (max 50,000 chars) |
| `ai_knowledge_base_meta` | JSON: `{ filename, size_bytes, char_count, uploaded_at }` |

---

## Database Schema

### `email_templates`

```sql
CREATE TABLE email_templates (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(191) NOT NULL,
  from_name  VARCHAR(191) DEFAULT NULL,   -- tên người gửi hiển thị trong From header
  from_email VARCHAR(191) DEFAULT NULL,   -- địa chỉ email gửi thực sự (phải verify trên SendGrid)
  reply_to   VARCHAR(191) DEFAULT NULL,   -- Reply-To email (khi người nhận reply, email đến đây)
  created_by INT NOT NULL,                -- user id của admin tạo template
  created_at TIMESTAMP NULL DEFAULT NULL,
  updated_at TIMESTAMP NULL DEFAULT NULL
);
```

> **DB Migration đã thực hiện:**
> ```sql
> -- Đổi tên column `from` → `reply_to`
> ALTER TABLE email_templates
>   CHANGE COLUMN `from` `reply_to` VARCHAR(191) NULL;
>
> -- Thêm column `from_email`
> ALTER TABLE email_templates
>   ADD COLUMN `from_email` VARCHAR(191) NULL
>   AFTER `from_name`;
> ```

### `email_template_langs`

```sql
CREATE TABLE email_template_langs (
  id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  parent_id INT NOT NULL,              -- FK → email_templates.id
  lang      VARCHAR(100) NOT NULL,     -- 'vi', 'en', ...
  subject   VARCHAR(191) NOT NULL,     -- tiêu đề email
  content   TEXT NOT NULL,             -- nội dung HTML
  created_at TIMESTAMP NULL DEFAULT NULL,
  updated_at TIMESTAMP NULL DEFAULT NULL
);
```

> Bảng này **dùng chung với incard-biz** (cùng DB). Không cần chạy migration.

---

## Environment Variables

Thêm vào file `.env` (xem mẫu đầy đủ trong `.env.example`):

```env
# Mail Configuration (SMTP)
MAIL_HOST=smtp.mailgun.org       # SMTP host
MAIL_PORT=587                    # 587 (TLS) hoặc 465 (SSL)
MAIL_ENCRYPTION=tls              # 'tls' hoặc 'ssl'
MAIL_USERNAME=your_smtp_username
MAIL_PASSWORD=your_smtp_password
MAIL_FROM_ADDRESS=noreply@incard.vn
MAIL_FROM_NAME=InCard
```

### SMTP Providers phổ biến

| Provider | Host | Port | Encryption |
|---|---|---|---|
| Mailgun | `smtp.mailgun.org` | `587` | `tls` |
| Gmail | `smtp.gmail.com` | `587` | `tls` |
| SendGrid | `smtp.sendgrid.net` | `587` | `tls` |
| AWS SES | `email-smtp.<region>.amazonaws.com` | `587` | `tls` |

> **Gmail:** Cần bật "App Password" trong Google Account, không dùng mật khẩu thông thường.

---

## Files

```
src/modules/email/
├── email.module.ts                        # Module declaration
├── email.controller.ts                    # REST endpoints
├── email.service.ts                       # Business logic + Nodemailer
├── dto/
│   ├── send-email.dto.ts                  # DTO cho POST /emails/send
│   └── email-template.dto.ts             # DTO cho CRUD template
├── entities/
│   ├── email-template.entity.ts           # TypeORM entity → email_templates
│   └── email-template-lang.entity.ts     # TypeORM entity → email_template_langs
└── __tests__/
    ├── email.service.spec.ts              # 26 unit tests cho EmailService
    └── email.controller.spec.ts          # 18 unit tests cho EmailController + Guards

src/modules/email-signatures/
├── email-signatures.module.ts             # Module declaration
├── email-signatures.controller.ts         # CRUD + activate endpoints
├── email-signatures.service.ts            # Business logic (Drizzle ORM)
└── dto/
    ├── create-email-signature.dto.ts
    └── update-email-signature.dto.ts

src/modules/admin-settings/
├── admin-settings.module.ts               # Module declaration
├── admin-settings.controller.ts           # GET/PUT :key + knowledge-base endpoints
├── admin-settings.service.ts              # getSettings/setSettings + uploadKnowledgeBase
└── dto/
    ├── update-settings.dto.ts
    └── upload-knowledge-base.dto.ts
```

---

## 📊 Phase F - Analytics Dashboard (NEW)

**Endpoint:** `GET /api/emails/analytics/dashboard`

Lấy tổng hợp 6 metrics cho email analytics dashboard. Dữ liệu aggregate từ `email_campaigns` table.

### Query Parameters

| Param | Type | Optional | Example |
|-------|------|----------|---------|
| `from` | ISO 8601 date | Yes | `2026-01-01` |
| `to` | ISO 8601 date | Yes | `2026-03-31` |

### Response

```json
{
  "status": true,
  "message": "Lấy thống kê thành công",
  "data": {
    "subscribers": 15000,
    "campaigns_sent": 42,
    "emails_sent": 14800,
    "open_rate": "24.5",
    "click_rate": "8.2",
    "bounce_rate": "1.3",
    "total_opens": 3626,
    "total_clicks": 1214,
    "total_failed": 200
  }
}
```

### Metrics Explanation

| Metric | Definition | Formula |
|--------|-----------|---------|
| `subscribers` | Tổng email cố gắng gửi | SUM(total) |
| `campaigns_sent` | Số campaigns đã gửi | COUNT(*) |
| `emails_sent` | Email delivered successfully | SUM(success) |
| `open_rate` (%) | Tỷ lệ mở email | (opens / emails_sent) × 100 |
| `click_rate` (%) | Tỷ lệ click link | (clicks / emails_sent) × 100 |
| `bounce_rate` (%) | Tỷ lệ email failed | (failed / subscribers) × 100 |

### Examples

```bash
# All-time
GET /api/emails/analytics/dashboard

# Last 30 days
GET /api/emails/analytics/dashboard?from=2026-02-07&to=2026-03-09

# Specific month
GET /api/emails/analytics/dashboard?from=2026-03-01&to=2026-03-31
```

---

## 🚀 Phase G - Template Personalization (NEW)

Hỗ trợ dynamic variables trong email content. Mỗi recipient nhận content tùy chỉnh theo data của họ.

### Preview Email Endpoint

**Endpoint:** `POST /api/emails/preview`

Xem trước email đã render variables cho 1 user.

```json
{
  "user_id": 123,
  "subject": "Xin chào {{user.name}}",
  "body": "<p>Gói: {{user.plan}}</p>"
}
```

**Response:**
```json
{
  "status": true,
  "message": "Xem trước email thành công",
  "data": {
    "subject": "Xin chào John Doe",
    "body": "<p>Gói: Pro</p>"
  }
}
```

### Personalization in Send

**Endpoint:** `POST /api/emails/send` (with variables)

```json
{
  "user_ids": [1, 2, 3],
  "subject": "Xin chào {{user.name}} - {{user.plan}} Plan",
  "body": "<p>Công ty: {{user.subscription}}</p>",
  "campaign_name": "Personalized Newsletter"
}
```

**Response:**
```json
{
  "status": true,
  "message": "Gửi email hoàn tất: 3/3 thành công",
  "data": {
    "total": 3,
    "success": 3,
    "failed": 0,
    "campaign_id": 42
  }
}
```

**Behavior per recipient:**
- User #1 (name=John, plan=Pro) → "Xin chào John - Pro Plan"
- User #2 (name=Jane, plan=Enterprise) → "Xin chào Jane - Enterprise Plan"
- User #3 (name=Bob, plan=Basic) → "Xin chào Bob - Basic Plan"

### Supported Variables

| Variable | Source | Fallback |
|----------|--------|----------|
| `{{user.name}}` | users.name | `''` |
| `{{user.first_name}}` | First word of name | `''` |
| `{{user.email}}` | Recipient email | email |
| `{{user.plan}}` | plans.name (JOINed) | `''` |
| `{{user.subscription}}` | users.subscriptionName | `''` |
| `{{unsubscribe_url}}` | HMAC token URL | `''` |

### Performance Optimization

**Batch-Fetch Strategy:**
- 1 single DB query cho tất cả recipients (không N+1)
- Query: `SELECT users LEFT JOIN plans WHERE email IN (...)`
- Result: 10,000 recipients = 1 query + 10,000 variable replacements

### Variable Resolution Rules

1. **Unknown variables** → render as empty string (silent fallback)
   - Input: `"Gói: {{unknown.var}}"`
   - Output: `"Gói: "`

2. **User not in DB** → all `user.*` variables → empty string
   - Input: `"Email: {{user.email}}"` for email not in DB
   - Output: `"Email: "`

3. **Case-sensitive** → `{{user.name}}` ≠ `{{User.Name}}`

---

## See Also

- [Email Campaign API](./EMAIL_CAMPAIGN_API.md) - Campaign history, tracking, scheduling
- [Email Campaign Plan](./EMAIL_CAMPAIGN_PLAN.md) - Phase A-D implementation details
- [Postman Collection](./PHASE_F_G_POSTMAN.json) - Ready-to-import API examples
- [API Endpoints Reference](./PHASE_F_G_ENDPOINTS.json) - Full API specification
