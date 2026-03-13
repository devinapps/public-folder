# Admin User Management API Documentation

**Version:** 2.2.0
**Base URL:** `http://localhost:3001/api`
**Authentication:** JWT Bearer Token (Admin role required)
**Last Updated:** 2026-03-12

## 🎉 What's New in v2.2.0

### is_can_test (Phase D)
- ✅ **New field `is_can_test`**: Đánh dấu user là "test recipient" cho campaign testing
- ✅ **Toggle endpoint**: `PATCH /users/:id/can-test` — flip 0↔1 (Admin only)
- ✅ **Filter in send-email**: `is_can_test=true` trong `POST /api/emails/send` chỉ gửi cho test users

---

## 🎉 What's New in v2.1.0

### Security & Data Integrity
- ✅ **AdminGuard Protection**: Create and Update user endpoints now require admin role
- ✅ **Cascade Delete**: Deleting users now properly cascades to businesses and QR codes
- ✅ **Hardcoded Type**: All created users automatically get `type='company'`

### Impersonation System
- ✅ **Fully Functional**: Login As generates JWT token with impersonation metadata
- ✅ **Exit Impersonation**: Logout As restores admin session with proper token
- ✅ **Admin Tracking**: Impersonation tokens store admin user ID in JWT payload

### Data Loading & Export
- ✅ **Enhanced User Details**: `GET /users/:id` now includes businesses, QR codes, and QR groups
- ✅ **Database Pagination**: List users uses efficient database-level pagination with search (email OR name)
- ✅ **Excel Export**: Simplified format matching PHP requirements [No, Id, Name, Email]
- ✅ **QR Export**: SVG format with correct URL format `{business_slug}?utm=qr`

### Business Logic
- ✅ **Default Plan**: New users automatically assigned first plan from database
- ✅ **Plan Management**: Auto-enabled plan status for new users

---

## Table of Contents

- [Authentication](#authentication)
- [Error Handling](#error-handling)
- [API Endpoints](#api-endpoints)
  - [User CRUD Operations](#user-crud-operations)
  - [Plan Management](#plan-management)
  - [Utilities](#utilities)
  - [Referral System](#referral-system)
  - [Settings Management](#settings-management)
  - [Impersonation](#impersonation)
  - [Export Features](#export-features)

---

## Authentication

All endpoints (except `POST /check-email`) require JWT authentication with admin privileges.

### Required Headers
```http
Authorization: Bearer <your-jwt-token>
Content-Type: application/json
```

### Admin Role Requirements
User must have `type` field with one of these values:
- `admin`
- `super admin`
- `super_admin`

---

## Error Handling

### Standard Error Response
```json
{
  "status": false,
  "message": "Error message in Vietnamese",
  "data": null,
  "errors": []
}
```

### Common Error Codes

| Status Code | Description |
|-------------|-------------|
| 400 | Bad Request - Validation errors |
| 401 | Unauthorized - Invalid or missing token |
| 403 | Forbidden - Admin access required |
| 404 | Not Found - Resource doesn't exist |
| 500 | Internal Server Error |

---

## API Endpoints

### Quick Reference

| Category | Method | Endpoint | Description |
|----------|--------|----------|-------------|
| **CRUD** | GET | `/users` | List users with pagination |
| **CRUD** | GET | `/users/:id` | Get user with statistics |
| **CRUD** | POST | `/users` | Create new user |
| **CRUD** | PUT | `/users/:id` | Update user |
| **CRUD** | DELETE | `/users/:id` | Delete user |
| **Plans** | GET | `/users/:id/plans` | Get available plans |
| **Plans** | POST | `/users/:id/plans/:planId` | Assign plan to user |
| **Utils** | POST | `/users/check-email` | Check email existence |
| **Utils** | POST | `/users/:id/reset-password` | Reset user password |
| **Referral** | GET | `/users/:id/referrals` | Get user referrals |
| **Settings** | GET | `/users/:id/settings` | Get user settings |
| **Settings** | PUT | `/users/:id/settings` | Update user settings |
| **Admin** | GET | `/users/:id/login-as` | Impersonate user |
| **Admin** | GET | `/users/logout-as` | Exit impersonation |
| **Admin** | PATCH | `/users/:id/can-test` | Toggle is_can_test flag |
| **Export** | GET | `/users/export` | Export users to Excel |
| **Export** | GET | `/users/:id/export-qr` | Export QR codes as ZIP |

---

## User CRUD Operations

### 1. List Users with Pagination

Get paginated list of users with search and sorting capabilities.

**Endpoint:** `GET /api/users`

**Query Parameters:**
- `page` (optional) - Page number (default: 1)
- `limit` (optional) - Items per page (default: 10)
- `search` (optional) - Search term for name/email
- `sortBy` (optional) - Sort field (default: id)
- `sortOrder` (optional) - ASC or DESC (default: DESC)

**Request Example:**
```http
GET /api/users?page=1&limit=10&search=john&sortBy=name&sortOrder=ASC
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
  "status": true,
  "message": "Lấy danh sách người dùng thành công",
  "data": {
    "data": [
      {
        "id": 5,
        "name": "John Doe",
        "email": "john@example.com",
        "type": "company",
        "plan": 2
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "limit": 10,
      "totalRecords": 42
    }
  }
}
```

---

### 2. Get Single User with Statistics

Retrieve detailed user information including plan details and statistics.

**Endpoint:** `GET /api/users/:id`

**Path Parameters:**
- `id` (required) - User ID

**Request Example:**
```http
GET /api/users/5
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
  "status": true,
  "message": "Lấy thông tin người dùng thành công",
  "data": {
    "id": 5,
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+84123456789",
    "type": "company",
    "plan": 2,
    "planExpireDate": "2027-02-06T00:00:00.000Z",
    "referralCode": "JOHN2025",
    "planDetails": {
      "id": 2,
      "name": "Premium",
      "price": 99000,
      "duration": "month"
    },
    "totalContacts": 45,
    "totalAppointments": 12,
    "totalQrCodes": 3
  }
}
```

---

### 3. Create User

Create a new user account with automatic password hashing.

**Endpoint:** `POST /api/users`

**Request Body:**
```json
{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "password": "securePassword123",
  "phone": "+84987654321",
  "type": "company"
}
```

**Required Fields:**
- `email` (string) - Must be unique, valid email format
- `password` (string) - Plain text password (will be hashed automatically)

**Optional Fields:**
- `name` (string) - User's full name
- `phone` (string) - Phone number
- `type` (string) - User type (automatically set to "company")

**Security Implementation:**
- Password is automatically hashed using bcrypt with salt rounds: 10
- Email uniqueness validation before creation
- Default plan assignment (first plan in database or plan ID 1)
- Automatically creates corresponding GetStream user for activity feeds

**Success Response (200):**
```json
{
  "status": true,
  "message": "Tạo người dùng thành công",
  "data": {
    "id": 101,
    "name": "Jane Smith",
    "email": "jane@example.com",
    "type": "company",
    "plan": 1,
    "planIsActive": 1
  }
}
```

**Error Response (400) - Email Exists:**
```json
{
  "status": false,
  "message": "Email đã tồn tại trong hệ thống",
  "data": null,
  "errors": []
}
```

---

### 4. Update User

Update user information.

**Endpoint:** `PUT /api/users/:id`

**Path Parameters:**
- `id` (required) - User ID

**Request Body (all fields optional):**
```json
{
  "name": "Jane Smith Updated",
  "phone": "+84987654322",
  "type": "company"
}
```

**Success Response (200):**
```json
{
  "status": true,
  "message": "Cập nhật người dùng thành công",
  "data": {
    "id": 101,
    "name": "Jane Smith Updated",
    "email": "jane@example.com"
  }
}
```

---

### 5. Delete User

Delete a user account and associated data.

**Endpoint:** `DELETE /api/users/:id`

**Path Parameters:**
- `id` (required) - User ID

**Request Example:**
```http
DELETE /api/users/101
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
  "status": true,
  "message": "Xóa người dùng thành công",
  "data": {
    "deleted": true
  }
}
```

---

## Plan Management

### 6. Get Available Plans

List all subscription plans available for assignment.

**Endpoint:** `GET /api/users/:id/plans`

**Path Parameters:**
- `id` (required) - User ID

**Request Example:**
```http
GET /api/users/5/plans
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
  "status": true,
  "message": "Lấy danh sách gói dịch vụ thành công",
  "data": [
    {
      "id": 1,
      "name": "Free",
      "price": 0,
      "duration": "forever",
      "business": 1
    },
    {
      "id": 2,
      "name": "Premium",
      "price": 99000,
      "duration": "month",
      "business": -1
    }
  ]
}
```

---

### 7. Assign Plan to User

Assign a subscription plan to a user with optional expiration date.

**Endpoint:** `POST /api/users/:id/plans/:planId`

**Path Parameters:**
- `id` (required) - User ID
- `planId` (required) - Plan ID to assign

**Request Body (optional):**
```json
{
  "expireDate": "2027-02-06T00:00:00.000Z"
}
```

**Request Example:**
```http
POST /api/users/5/plans/2
Authorization: Bearer <token>
Content-Type: application/json

{
  "expireDate": "2027-02-06T00:00:00.000Z"
}
```

**Success Response (200):**
```json
{
  "status": true,
  "message": "Gán gói dịch vụ thành công",
  "data": {
    "id": 5,
    "plan": 2,
    "planIsActive": 1,
    "planExpireDate": "2027-02-06T00:00:00.000Z"
  }
}
```

---

## Utilities

### 8. Check Email Exists

Validate if an email address is already registered.

**Endpoint:** `POST /api/users/check-email`

**Authentication:** ❌ Not required (Public endpoint)

**Request Body:**
```json
{
  "email": "test@example.com"
}
```

**Request Example:**
```http
POST /api/users/check-email
Content-Type: application/json

{
  "email": "test@example.com"
}
```

**Success Response (200):**
```json
{
  "status": true,
  "message": "Email đã tồn tại",
  "data": {
    "exists": true
  }
}
```

---

### 9. Reset User Password

Admin-initiated password reset with bcrypt hashing.

**Endpoint:** `POST /api/users/:id/reset-password`

**Path Parameters:**
- `id` (required) - User ID

**Request Body:**
```json
{
  "password": "newSecurePassword123"
}
```

**Validation:**
- Password must be at least 6 characters

**Request Example:**
```http
POST /api/users/5/reset-password
Authorization: Bearer <token>
Content-Type: application/json

{
  "password": "newSecurePassword123"
}
```

**Success Response (200):**
```json
{
  "status": true,
  "message": "Đặt lại mật khẩu thành công",
  "data": {
    "updated": true
  }
}
```

**⚠️ Implementation Note:**

This endpoint is currently **NOT IMPLEMENTED** in the backend. The current implementation uses a 2-step password reset flow from the Laravel/incard-biz codebase:

**Alternative: Forgot Password Flow (2 steps)**

1. **Send Verification Code**
   - **Endpoint:** `POST /api/forgot-password`
   - **Request Body:** `{ "email": "user@example.com" }`
   - **Process:**
     - Generates 8-character verification code
     - Stores in `users.verify_code` with 2-minute expiration
     - Sends code via email
   - **Response:** `{ "status": true, "message": "Mã code đã được gởi đến email của bạn" }`

2. **Change Password with Code**
   - **Endpoint:** `POST /api/change-password`
   - **Request Body:**
     ```json
     {
       "code": "ABC12345",
       "password": "newPassword123",
       "password_confirm": "newPassword123"
     }
     ```
   - **Process:**
     - Validates verification code and expiration
     - Uses `Hash::make()` (bcrypt) to hash password
     - Updates `users.password`
     - Clears `users.verify_code`
   - **Response:** `{ "status": true, "message": "Thay đổi mật khẩu thành công!" }`

**Database Schema:**
- `users.verify_code` - 8-character verification code (nullable)
- `users.verify_code_expired` - Code expiration timestamp (nullable)

**Security Implementation:**
- Password hashing: Laravel's `Hash::make()` (bcrypt with default cost factor 10)
- Code expiration: 2 minutes from generation
- Code cleared after successful password change

**Recommended Implementation:**

For admin panel use case, implement the direct reset endpoint as documented above:
- No email verification required (admin has already verified identity)
- Direct password update with bcrypt hashing
- Simpler flow for admin operations

---

## Referral System

### 10. Get User Referrals

Retrieve list of users referred by this user.

**Endpoint:** `GET /api/users/:id/referrals`

**Path Parameters:**
- `id` (required) - User ID

**Request Example:**
```http
GET /api/users/5/referrals
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
  "status": true,
  "message": "Lấy danh sách giới thiệu thành công",
  "data": {
    "referralCode": "JOHN2025",
    "totalReferrals": 3,
    "referrals": [
      {
        "id": 10,
        "name": "Jane Smith",
        "email": "jane@example.com",
        "createdAt": "2026-01-15T10:00:00.000Z"
      }
    ]
  }
}
```

---

## Settings Management

### 11. Get User Settings

Retrieve user's custom settings (e.g., CRM configuration).

**Endpoint:** `GET /api/users/:id/settings`

**Path Parameters:**
- `id` (required) - User ID

**Request Example:**
```http
GET /api/users/5/settings
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
  "status": true,
  "message": "Lấy cài đặt thành công",
  "data": {
    "odoo_crm": {
      "crm_host": "https://odoo.example.com",
      "crm_database": "production_db",
      "crm_username": "user@example.com"
    },
    "notifications": {
      "email": true,
      "push": false
    }
  }
}
```

---

### 12. Update User Settings

Update user's custom settings. Settings are merged with existing configuration.

**Endpoint:** `PUT /api/users/:id/settings`

**Path Parameters:**
- `id` (required) - User ID

**Request Body (free-form JSON):**
```json
{
  "odoo_crm": {
    "crm_host": "https://new-odoo.example.com",
    "crm_database": "new_db",
    "crm_username": "newuser@example.com",
    "crm_password": "encrypted_password"
  }
}
```

**Request Example:**
```http
PUT /api/users/5/settings
Authorization: Bearer <token>
Content-Type: application/json

{
  "odoo_crm": {
    "crm_host": "https://new-odoo.example.com"
  }
}
```

**Success Response (200):**
```json
{
  "status": true,
  "message": "Cập nhật cài đặt thành công",
  "data": {
    "updated": true
  }
}
```

---

## Impersonation

### 13. Login As User (Impersonate)

Admin can impersonate a user to access their account.

**Endpoint:** `GET /api/users/:id/login-as`

**Authentication:** ✅ AuthGuard + AdminGuard required

**Path Parameters:**
- `id` (required) - User ID to impersonate

**Admin Authorization:**
- Accepts admin types: `'admin'`, `'super admin'`, `'super_admin'`
- Must have valid JWT token with admin privileges

**Request Example:**
```http
GET /api/users/5/login-as
Authorization: Bearer <admin-token>
```

**Success Response (200):**
```json
{
  "status": true,
  "message": "Đăng nhập với tư cách người dùng thành công",
  "data": {
    "impersonationToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "impersonatedUser": {
      "id": 5,
      "name": "John Doe",
      "email": "john@example.com",
      "type": "company"
    },
    "adminUser": {
      "id": 1,
      "name": "Admin User",
      "email": "admin@example.com"
    }
  }
}
```

**Implementation Notes:**

1. **JWT Token with Impersonation Metadata:**
   - Generates new JWT token for impersonated user
   - Token payload includes:
     ```typescript
     {
       userId: targetUser.id,
       email: targetUser.email,
       type: targetUser.type,
       impersonating: true,      // Flag for impersonation mode
       adminUserId: adminUser.id // Original admin's ID
     }
     ```

2. **Frontend Usage (Admin Panel):**
   - Store impersonation context in localStorage (session-style):
     ```typescript
     localStorage.setItem('admin_user_id', adminUser.id)
     localStorage.setItem('admin_user_name', adminUser.name)
     localStorage.setItem('temp_user_id', impersonatedUser.id)
     localStorage.setItem('temp_user_name', impersonatedUser.name)
     ```
   - **Do NOT replace admin JWT token** - keep using admin token for API calls
   - Impersonation is UI-only in admin panel

3. **Security:**
   - Original admin context is preserved
   - Can exit impersonation at any time via logout-as endpoint
   - Admin privileges remain active during impersonation

---

### 14. Logout As (Exit Impersonation)

Exit impersonation mode and return to admin account.

**Endpoint:** `GET /api/users/logout-as`

**Authentication:** ✅ AuthGuard required (any authenticated user)

**Request Example:**
```http
GET /api/users/logout-as
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
  "status": true,
  "message": "Thoát chế độ đăng nhập thay thành công",
  "data": {
    "adminToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "adminUser": {
      "id": 1,
      "name": "Admin User",
      "email": "admin@example.com",
      "type": "admin"
    }
  }
}
```

**Implementation Notes:**

1. **Token Validation:**
   - Decodes current JWT token
   - Checks for `impersonating: true` flag
   - Retrieves `adminUserId` from token metadata

2. **Frontend Usage:**
   - Clear impersonation context from localStorage:
     ```typescript
     localStorage.removeItem('admin_user_id')
     localStorage.removeItem('admin_user_name')
     localStorage.removeItem('temp_user_id')
     localStorage.removeItem('temp_user_name')
     ```
   - Show toast notification
   - Refresh page to restore admin UI context

3. **Error Handling:**
   - Returns error if not in impersonation mode: `"Bạn không đang trong chế độ đăng nhập thay"`
   - Returns error if admin user ID not found in token
    "message": "Đã thoát chế độ đăng nhập thay"
  }
}
```

---

## is_can_test Management

### 15. Toggle is_can_test (Test Recipient Flag)

Flip trạng thái `is_can_test` của user: `0 → 1` hoặc `1 → 0`. Dùng để đánh dấu user là "test recipient" — nhận email trước khi broadcast toàn bộ.

**Endpoint:** `PATCH /api/users/:id/can-test`

**Authentication:** ✅ AuthGuard + AdminGuard required

**Path Parameters:**
- `id` (required) - User ID

**Request Example:**
```http
PATCH /api/users/42/can-test
Authorization: Bearer <token>
```

> Không cần request body — backend tự flip giá trị hiện tại.

**Success Response (200):**
```json
{
  "status": true,
  "message": "Cập nhật thành công",
  "data": {
    "id": 42,
    "is_can_test": true
  }
}
```

**Errors:**

| HTTP | Message | Nguyên nhân |
|---|---|---|
| `404 Not Found` | `User #42 không tồn tại` | ID không hợp lệ |
| `401 Unauthorized` | `Token xác thực không được cung cấp` | Thiếu JWT |
| `403 Forbidden` | `Forbidden resource` | Không phải admin |

**Usage — Send Email to Test Users Only:**
```json
POST /api/emails/send
{
  "template_id": 3,
  "is_can_test": true
}
```
> Chỉ gửi cho users có `is_can_test=1`. Kết hợp được với `list_id`, `user_ids`, `user_types`, date range.

---

## Export Features

### 16. Export Users to Excel

Export all users to Excel file in simplified format matching PHP Laravel requirements.

**Endpoint:** `GET /api/users/export`

**Request Example:**
```http
GET /api/users/export
Authorization: Bearer <token>
```

**Response:**
- **Content-Type:** `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- **Content-Disposition:** `attachment; filename="users-list.xlsx"`
- **Body:** Binary Excel file

**Excel Columns (Simplified Format):**
- **No** - Row number (1, 2, 3, ...)
- **Id** - User ID
- **Name** - User name
- **Email** - User email

---

### 17. Export QR Codes to ZIP

Export user's QR codes as a ZIP file containing SVG images with business slug URLs.

**Endpoint:** `GET /api/users/:id/export-qr`

**Path Parameters:**
- `id` (required) - User ID

**Request Example:**
```http
GET /api/users/5/export-qr
Authorization: Bearer <token>
```

**Response:**
- **Content-Type:** `application/zip`
- **Content-Disposition:** `attachment; filename="qrcode_svg_{user_id}.zip"`
- **Body:** Binary ZIP file

**ZIP Contents:**
- `qrcode-{code}.svg` - QR code images in SVG format

**QR Code URL Format:**
- Uses business slug if available: `{APP_URL}/{business_slug}?utm=qr`
- Falls back to QR code: `{APP_URL}/{qr_code}?utm=qr`
- UTM parameter for tracking QR code scans

**Implementation Details:**
- QR codes are enriched with business data before export
- SVG format for scalable, high-quality output
- No metadata JSON files (simplified format)

**Error Response (404) - No QR Codes:**
```json
{
  "status": false,
  "message": "Người dùng không có mã QR nào"
}
```

---

## Development Notes

### Development Mode Bypass

When `ENABLE_TOKEN_BYPASS=true` in `.env`:
```http
Authorization: Bearer dev_token_13
```
This bypasses JWT validation and maps to admin user (ID: 13).

**⚠️ Warning:** Disable this in production!

### Database Connection

```env
MYSQL_HOST=your-db-host.example.com
MYSQL_PORT=3306
MYSQL_DATABASE=your_database_name
```

### Related Documentation

- [Implementation Summary](./IMPLEMENTATION_SUMMARY.md) - Technical implementation details
- [Existing Features API](./EXISTING_FEATURES_API.md) - Other API endpoints

---

**Last Updated:** 2026-02-06
**API Version:** 2.0.0
**Documentation Version:** 1.0.0
