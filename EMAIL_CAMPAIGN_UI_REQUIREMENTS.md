# Email Campaign UI — Requirements Document

**Stack:** Next.js + React + Tailwind CSS
**API Base:** `POST /api/auth/login` → Bearer token → tất cả endpoints yêu cầu `Authorization: Bearer <token>`
**Audience:** Frontend developer + UI/UX designer
**Phiên bản:** 1.0 — 2026-02-25

---

## Tổng quan

Trang Email Campaign trong CMS InCard cho phép super admin:
1. **Gửi email bulk** — compose nội dung (thủ công hoặc từ template) và filter người nhận
2. **Quản lý template** — CRUD danh sách template email đa ngôn ngữ

---

## Màn hình 1 — Gửi Email Bulk (`/email/send`)

### Wireframe

```
┌─────────────────────────────────────────────────────────────────┐
│  📧 Email Campaign                              [Templates →]   │
├──────────────────────────┬──────────────────────────────────────┤
│                          │                                      │
│  BƯỚC 1: NGƯỜI NHẬN      │   BƯỚC 2: NỘI DUNG EMAIL           │
│  ─────────────────────   │   ──────────────────────────────    │
│                          │                                      │
│  ○ Tất cả người dùng     │   Nguồn nội dung:                   │
│  ○ Lọc theo điều kiện    │   ┌─────────────┬─────────────┐     │
│  ○ Nhập email trực tiếp  │   │  📋 Template │  ✏️ Thủ công │     │
│                          │   └─────────────┴─────────────┘     │
│  ── Khi chọn "Lọc" ──    │                                      │
│  User IDs:               │   [Tab: Template được chọn]         │
│  ┌──────────────────┐    │   Template:                         │
│  │ 1, 2, 3...       │    │   ┌──────────────────────────────┐  │
│  └──────────────────┘    │   │ Chọn template...           ▼ │  │
│                          │   └──────────────────────────────┘  │
│  Loại tài khoản:         │                                      │
│  ☐ user                  │   Ngôn ngữ:  ○ VI  ○ EN  ○ Khác    │
│  ☐ admin                 │                                      │
│  ☐ super admin           │   Override (tuỳ chọn):              │
│                          │   Subject:                          │
│  Ngày tạo tài khoản:     │   ┌──────────────────────────────┐  │
│  Từ: [──────────] 📅      │   │ (để trống = dùng template)   │  │
│  Đến: [──────────] 📅     │   └──────────────────────────────┘  │
│                          │   Nội dung:                         │
│  ── Khi chọn "Email" ──  │   ┌──────────────────────────────┐  │
│  Nhập email:             │   │ (để trống = dùng template)   │  │
│  ┌──────────────────┐    │   │                              │  │
│  │ a@b.com          │    │   │                              │  │
│  │ c@d.com          │    │   └──────────────────────────────┘  │
│  └──────────────────┘    │                                      │
│  (mỗi dòng 1 email)      │   [Tab: Thủ công]                   │
│                          │   Subject: *                        │
│  ── Preview ──           │   ┌──────────────────────────────┐  │
│  📊 Ước tính: ~120 người │   │ Tiêu đề email                │  │
│                          │   └──────────────────────────────┘  │
│                          │   Nội dung: * (HTML editor)         │
│                          │   ┌──────────────────────────────┐  │
│                          │   │                              │  │
│                          │   │  [Rich text / HTML editor]   │  │
│                          │   │                              │  │
│                          │   └──────────────────────────────┘  │
│                          │                                      │
│                          │   ┌──────────────────────────────┐  │
│                          │   │    👁 Preview email           │  │
│                          │   └──────────────────────────────┘  │
├──────────────────────────┴──────────────────────────────────────┤
│              [Hủy]                    [🚀 Gửi Email]            │
└─────────────────────────────────────────────────────────────────┘
```

### Kết quả sau khi gửi

```
┌─────────────────────────────────────────┐
│  ✅ Gửi email hoàn tất                  │
│                                         │
│  Tổng:      120 người nhận              │
│  Thành công: 118 ✅                     │
│  Thất bại:     2 ❌                     │
│                                         │
│  Email thất bại:                        │
│  • broken@example.com                   │
│  • invalid@test.com                     │
│                                         │
│              [Đóng]  [Gửi lại ❌]       │
└─────────────────────────────────────────┘
```

### Tính năng & Logic

#### Bước 1 — Người nhận

| Mode | UI | API field | Ưu tiên |
|---|---|---|---|
| **Tất cả** | Radio chọn mặc định | Không gửi field nào | Thấp nhất |
| **Lọc theo điều kiện** | Hiện form filter | `user_ids`, `user_types`, `created_from`, `created_to` | Trung bình |
| **Nhập email trực tiếp** | Textarea mỗi dòng 1 email | `user_emails` | **Cao nhất** — khi có field này, các filter khác bị bỏ qua |

- Khi mode "Lọc": các conditions AND với nhau
- Khi mode "Nhập email": parse textarea thành array, trim + lowercase + loại dòng trống
- **Preview count:** Khi mode "Lọc" → gọi API estimate (hoặc hiển thị "sẽ query khi gửi")

#### Bước 2 — Nội dung

**Tab Template:**
- Dropdown chọn template (gọi `GET /api/emails/templates`)
- Radio chọn ngôn ngữ (hiển thị các `lang` có trong template đã chọn)
- 2 field override optional: `subject`, `body` (để trống = dùng template)
- Khi chọn template: hiển thị preview subject + nội dung của lang đã chọn

**Tab Thủ công:**
- `subject`: input text, **bắt buộc**
- `body`: HTML editor (rich text hoặc raw HTML), **bắt buộc**
- Có nút **👁 Preview** mở modal render HTML body

#### Validation (client-side)

| Trường hợp | Lỗi hiển thị |
|---|---|
| Tab Template + không chọn template | "Vui lòng chọn template" |
| Tab Thủ công + trống subject | "Subject là bắt buộc" |
| Tab Thủ công + trống body | "Nội dung là bắt buộc" |
| Mode "Nhập email" + không có email nào | "Nhập ít nhất 1 email" |
| Email không hợp lệ trong danh sách | Highlight dòng lỗi + "Email không hợp lệ" |

#### States của nút Gửi

```
Bình thường:  [🚀 Gửi Email]
Loading:      [⏳ Đang gửi... (118/120)]   ← optional: progress nếu API hỗ trợ
Thành công:   hiện modal kết quả
Lỗi:          Toast error (401/403/400)
```

#### API Call

```
POST /api/emails/send
Authorization: Bearer <token>
Content-Type: application/json

{
  // Tùy mode người nhận:
  "user_emails": ["a@b.com"],          // Mode nhập email
  "user_ids": [1, 2, 3],              // Mode lọc (nếu có)
  "user_types": ["user"],             // Mode lọc (nếu có)
  "created_from": "2024-01-01",       // Mode lọc (nếu có)
  "created_to": "2024-12-31",         // Mode lọc (nếu có)

  // Tùy tab nội dung:
  "template_id": 5,                   // Tab Template
  "lang": "vi",                       // Tab Template
  "subject": "Override subject",      // Optional override
  "body": "<p>Override body</p>"      // Optional override
}
```

---

## Màn hình 2 — Quản lý Template (`/email/templates`)

### Wireframe — Danh sách template

```
┌─────────────────────────────────────────────────────────────────┐
│  📋 Email Templates                    [← Gửi Email]           │
│                                        [+ Tạo template mới]     │
├─────────────────────────────────────────────────────────────────┤
│  🔍 [Tìm kiếm theo tên...                              ]        │
├────────┬──────────────┬──────────────┬──────────────┬──────────┤
│  ID    │  Tên         │  Ngôn ngữ    │  Ngày tạo    │  Hành động│
├────────┼──────────────┼──────────────┼──────────────┼──────────┤
│  5     │ Welcome Email│ VI, EN       │ 01/01/2024   │ ✏️ 🗑️     │
│  4     │ Reset Pwd    │ VI           │ 15/12/2023   │ ✏️ 🗑️     │
│  3     │ Newsletter   │ VI, EN, JP   │ 01/12/2023   │ ✏️ 🗑️     │
│  ...   │ ...          │ ...          │ ...          │ ...      │
├────────┴──────────────┴──────────────┴──────────────┴──────────┤
│  Hiển thị 1-10 trong 25 templates          [← Prev] [Next →]  │
└─────────────────────────────────────────────────────────────────┘
```

### Wireframe — Form tạo / chỉnh sửa template

```
┌─────────────────────────────────────────────────────────────────┐
│  ← Quay lại                                                     │
│  ✏️ Tạo template mới  /  Chỉnh sửa: "Welcome Email"            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Tên template: *                                                │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Welcome Email                                             │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  Email gửi đi (from):                                          │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ noreply@incard.vn  (để trống = dùng cấu hình mặc định)   │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ── Nội dung theo ngôn ngữ ─────────────────────────────────── │
│                                                                 │
│  [VI] [EN] [+ Thêm ngôn ngữ]                         [🗑️ VI]  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Ngôn ngữ: VI                                              │ │
│  │                                                           │ │
│  │ Subject: *                                                │ │
│  │ ┌─────────────────────────────────────────────────────┐  │ │
│  │ │ Chào mừng bạn đến với InCard!                       │  │ │
│  │ └─────────────────────────────────────────────────────┘  │ │
│  │                                                           │ │
│  │ Nội dung: * (HTML)                                        │ │
│  │ ┌─────────────────────────────────────────────────────┐  │ │
│  │ │                                                     │  │ │
│  │ │   [Rich text / HTML editor]                         │  │ │
│  │ │                                                     │  │ │
│  │ └─────────────────────────────────────────────────────┘  │ │
│  │                              [👁 Preview]                 │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│              [Hủy]                      [💾 Lưu template]       │
└─────────────────────────────────────────────────────────────────┘
```

### Wireframe — Xác nhận xóa

```
┌───────────────────────────────────┐
│  ⚠️ Xóa template                  │
│                                   │
│  Bạn có chắc muốn xóa template   │
│  "Welcome Email"?                 │
│                                   │
│  Hành động này không thể hoàn    │
│  tác. Tất cả nội dung đa ngôn    │
│  ngữ sẽ bị xóa vĩnh viễn.       │
│                                   │
│      [Hủy]     [🗑️ Xóa]          │
└───────────────────────────────────┘
```

### Tính năng & Logic

#### Danh sách template

- Gọi `GET /api/emails/templates` khi mount component
- Hiển thị cột **Ngôn ngữ** = join các `lang` của `template.langs[]` (VD: "VI, EN")
- **Tìm kiếm:** filter client-side theo `template.name` (không cần API mới)
- **Phân trang:** client-side, 10 items/trang
- Nút **✏️** → navigate đến form chỉnh sửa
- Nút **🗑️** → mở modal xác nhận xóa

#### Form tạo/chỉnh sửa

**State quản lý langs:**
```typescript
type LangForm = {
  lang: string;     // 'vi', 'en', v.v.
  subject: string;  // bắt buộc
  content: string;  // bắt buộc (HTML)
}

type TemplateForm = {
  name: string;
  from: string;
  langs: LangForm[];
}
```

- **Tab ngôn ngữ:** click tab để switch, nút `+` mở input nhập mã ngôn ngữ mới
- **Xóa ngôn ngữ:** nút 🗑️ trên tab → confirm rồi xóa khỏi `langs[]`
- Phải có **ít nhất 1 ngôn ngữ** khi lưu
- **Chỉnh sửa:** prefill form từ `GET /api/emails/templates/:id`
- **⚠️ Lưu ý quan trọng:** Khi update và truyền `langs` → **toàn bộ langs cũ bị xóa, thay bằng langs mới** → cần load đầy đủ tất cả langs hiện tại vào form trước khi submit

#### Validation form template

| Field | Rule | Lỗi |
|---|---|---|
| `name` | Bắt buộc, không trống | "Tên template là bắt buộc" |
| `langs` | Ít nhất 1 lang | "Cần ít nhất một phiên bản ngôn ngữ" |
| `langs[i].lang` | Không trùng nhau | "Ngôn ngữ đã tồn tại" |
| `langs[i].subject` | Bắt buộc | "Subject là bắt buộc" |
| `langs[i].content` | Bắt buộc | "Nội dung là bắt buộc" |

#### API Calls

```typescript
// Lấy danh sách
GET /api/emails/templates

// Lấy chi tiết (khi chỉnh sửa)
GET /api/emails/templates/:id

// Tạo mới
POST /api/emails/templates
{
  "name": "Welcome Email",
  "from": "noreply@incard.vn",   // optional
  "langs": [
    { "lang": "vi", "subject": "Chào mừng!", "content": "<p>...</p>" },
    { "lang": "en", "subject": "Welcome!", "content": "<p>...</p>" }
  ]
}

// Cập nhật
PUT /api/emails/templates/:id
{
  "name": "Welcome Email v2",    // optional
  "langs": [...]                 // optional — nếu có: REPLACE toàn bộ
}

// Xóa
DELETE /api/emails/templates/:id
```

---

## Components dùng chung

| Component | Mô tả | Dùng ở |
|---|---|---|
| `HtmlEditor` | Rich text / raw HTML editor (gợi ý: TipTap hoặc textarea toggle) | Send form, Template form |
| `EmailPreviewModal` | Modal render HTML body an toàn (sandboxed iframe) | Send form, Template form |
| `RecipientModeSelector` | 3 radio mode + form tương ứng | Send form |
| `LangTabs` | Tab ngôn ngữ có thể thêm/xóa | Template form |
| `SendResultModal` | Hiển thị kết quả gửi bulk | Send form |
| `ConfirmDeleteModal` | Generic confirm dialog | Template list |

---

## Error States toàn cục

| HTTP Code | Hiển thị |
|---|---|
| `401` | Toast: "Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại." → redirect `/login` |
| `403` | Toast: "Bạn không có quyền thực hiện thao tác này" |
| `400` | Toast: hiển thị `message` từ API response |
| `404` | Toast: "Không tìm thấy dữ liệu" |
| Network error | Toast: "Lỗi kết nối. Vui lòng thử lại." |

---

## Navigation

```
/email
  ├── /email/send          ← Màn hình 1: Gửi email bulk
  └── /email/templates     ← Màn hình 2: Danh sách template
        └── /email/templates/new        ← Tạo mới
        └── /email/templates/:id/edit   ← Chỉnh sửa
```

---

## API Summary

| Method | Endpoint | Màn hình dùng |
|---|---|---|
| `POST` | `/api/emails/send` | Send form |
| `GET` | `/api/emails/templates` | Template list, Send form (dropdown) |
| `GET` | `/api/emails/templates/:id` | Template edit form |
| `POST` | `/api/emails/templates` | Template create form |
| `PUT` | `/api/emails/templates/:id` | Template edit form |
| `DELETE` | `/api/emails/templates/:id` | Template list |
