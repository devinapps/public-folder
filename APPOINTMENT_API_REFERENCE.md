# Appointment API Reference

**Last updated:** 2026-03-04
**Base URL:** `{APP_URL}/api`
**Auth:** `Authorization: Bearer <jwt_token>` (trừ public-appointments)

---

## Tổng quan endpoints

| Method | Endpoint | Auth | Mô tả |
|--------|----------|------|-------|
| GET | `/api/appointments` | ✅ JWT | Danh sách lịch hẹn |
| POST | `/api/appointments/add` | ✅ JWT | Tạo lịch hẹn mới |
| GET | `/api/appointments/:id` | ✅ JWT | Chi tiết lịch hẹn |
| POST | `/api/appointments/update/:id` | ✅ JWT | Cập nhật lịch hẹn |
| POST | `/api/appointments/accept/:id` | ✅ JWT | Chấp nhận lịch hẹn |
| POST | `/api/appointments/reject/:id` | ✅ JWT | Từ chối lịch hẹn |
| POST | `/api/appointments/delete/:id` | ✅ JWT | Xóa lịch hẹn |
| POST | `/api/public-appointments/add` | ❌ Public | Tạo từ Google Calendar webhook |
| POST | `/api/public-appointments/update` | ❌ Public | Cập nhật từ Google Calendar webhook |
| POST | `/api/public-appointments/delete` | ❌ Public | Xóa từ Google Calendar webhook |

---

## Cấu trúc dữ liệu Appointment

Tất cả response trả appointment đều theo format snake_case (PHP-compatible):

```json
{
  "id": 1,
  "business_id": 42,
  "name": "Nguyen Van A",
  "email": "a@gmail.com",
  "phone": "0901234567",
  "date": "2026-03-10",
  "time": "09:00",
  "status": "pending",
  "title": "Tư vấn sản phẩm",
  "note": "Ghi chú thêm",
  "user_requested": 13,
  "google_calendar_id": null,
  "created_by": 5,
  "created_at": "2026 03 03 14:27:14",
  "updated_at": "2026 03 03 14:27:14"
}
```

**Trạng thái (status):**

| Value | Mô tả |
|-------|-------|
| `pending` | Chờ xác nhận |
| `accepted` | Đã chấp nhận |
| `rejected` | Đã từ chối |

---

## 1. GET `/api/appointments`

**Mô tả:** Lấy danh sách lịch hẹn theo vai trò của user.

**Query params:**

| Param | Value | Mô tả |
|-------|-------|-------|
| `requested` | `1` hoặc `true` | Lấy lịch hẹn **mà user đã đặt** (`user_requested = userId`) |
| _(absent)_ | — | Lấy lịch hẹn **mà user nhận được** (`created_by = userId AND user_requested IS NULL`) |

**Request:**
```
GET /api/appointments
GET /api/appointments?requested=1
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": true,
  "message": "",
  "data": [
    {
      "id": 1,
      "business_id": 42,
      "name": "Nguyen Van A",
      "email": "a@gmail.com",
      "phone": "0901234567",
      "date": "2026-03-10",
      "time": "09:00",
      "status": "pending",
      "title": "Tư vấn",
      "note": null,
      "user_requested": 13,
      "google_calendar_id": null,
      "created_by": 5,
      "created_at": "2026 03 03 14:27:14",
      "updated_at": "2026 03 03 14:27:14",
      "business_name": "Nguyen Van B"
    }
  ]
}
```

**Notes:**
- `business_name` là `{business.title} {business.lastName}` — PHP appends thêm field này.
- Kết quả sắp xếp theo `date DESC`.
- `requested=1`: user xem lại lịch mình đã book cho người khác.
- `requested=0` (default): chủ card xem lịch khách book cho mình.

---

## 2. POST `/api/appointments/add`

**Mô tả:** Đặt lịch hẹn với chủ một business card.

**Request:**
```
POST /api/appointments/add
Authorization: Bearer <token>
Content-Type: application/json

{
  "card_id": 42,           (required) — business card ID
  "name": "Nguyen Van A",  (required)
  "email": "a@gmail.com",  (optional)
  "phone": "0901234567",   (optional)
  "date": "2026-03-10",    (optional)
  "time": "09:00",         (optional)
  "title": "Tư vấn",      (optional)
  "note": "Ghi chú"        (optional)
}
```

**Response:**
```json
{
  "status": true,
  "message": "Tao lich hen thanh cong!",
  "data": {
    "appointment": {
      "id": 1,
      "business_id": 42,
      "name": "Nguyen Van A",
      "email": "a@gmail.com",
      "phone": "0901234567",
      "date": "2026-03-10",
      "time": "09:00",
      "status": "pending",
      "title": "Tư vấn",
      "note": "Ghi chú",
      "user_requested": 13,
      "google_calendar_id": null,
      "created_by": 5,
      "created_at": "2026 03 03 14:27:14",
      "updated_at": "2026 03 03 14:27:14"
    }
  }
}
```

**Response (error):**
```json
{
  "status": false,
  "message": "The khong hop le",
  "data": null
}
```

**Side effects:**
- `created_by` = `business.owner_id ?? business.created_by` (chủ card, không phải người đặt).
- `user_requested` = userId của người đặt.
- `status` = `"pending"` mặc định.
- Ghi record `business_histories` type `"booked"`.
- `UPDATE businesses SET total_appointment = total_appointment + 1`.
- Gửi FCM push notification đến chủ card (fire and forget).

---

## 3. GET `/api/appointments/:id`

**Mô tả:** Chi tiết một lịch hẹn. Chỉ chủ card (`created_by = userId`) mới xem được.

**Request:**
```
GET /api/appointments/1
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": true,
  "message": "",
  "data": {
    "id": 1,
    "business_id": 42,
    "name": "Nguyen Van A",
    "email": "a@gmail.com",
    "phone": "0901234567",
    "date": "2026-03-10",
    "time": "09:00",
    "status": "pending",
    "title": "Tư vấn",
    "note": null,
    "user_requested": 13,
    "google_calendar_id": null,
    "created_by": 5,
    "created_at": "2026 03 03 14:27:14",
    "updated_at": "2026 03 03 14:27:14"
  }
}
```

**Response (not found / no permission):**
```json
{
  "status": false,
  "message": "Lich hen khong ton tai.",
  "data": null
}
```

---

## 4. POST `/api/appointments/update/:id`

**Mô tả:** Cập nhật thông tin lịch hẹn. Chỉ chủ card mới được cập nhật.

**Request:**
```
POST /api/appointments/update/1
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Nguyen Van B",   (optional)
  "email": "b@gmail.com",   (optional)
  "phone": "0909999999",    (optional)
  "date": "2026-03-15",     (optional)
  "time": "10:00",          (optional)
  "title": "Tư vấn mới",   (optional)
  "note": "Ghi chú mới"     (optional)
}
```

**Response:**
```json
{
  "status": true,
  "message": "Cap nhat lich hen thanh cong!",
  "data": {
    "appointment": {
      "id": 1,
      "business_id": 42,
      "name": "Nguyen Van B",
      "email": "b@gmail.com",
      "phone": "0909999999",
      "date": "2026-03-15",
      "time": "10:00",
      "status": "pending",
      "title": "Tư vấn mới",
      "note": "Ghi chú mới",
      "user_requested": 13,
      "google_calendar_id": null,
      "created_by": 5,
      "created_at": "2026 03 03 14:27:14",
      "updated_at": "2026 03 04 10:00:00"
    }
  }
}
```

**Notes:** Chỉ update các field được gửi lên (partial update). `status` không thể update qua endpoint này.

---

## 5. POST `/api/appointments/accept/:id`

**Mô tả:** Chấp nhận lịch hẹn. Chỉ chủ card (`created_by = userId`) mới được thực hiện.

**Request:**
```
POST /api/appointments/accept/1
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": true,
  "message": "Cap nhat lich hen thanh cong!",
  "data": {
    "appointment": {
      "id": 1,
      "status": "accepted",
      ...
    }
  }
}
```

**Side effects:**
- `UPDATE appointment_deatails SET status = 'accepted'`.
- Gửi FCM push notification đến `user_requested`: *"{ownerName} vua chap nhan lich hen cua ban."*
- Xóa notifications trong bảng `notifications` WHERE `type LIKE '%Appointment%'` AND `data->id = appointmentId`.

---

## 6. POST `/api/appointments/reject/:id`

**Mô tả:** Từ chối lịch hẹn. Chỉ chủ card mới được thực hiện.

**Request:**
```
POST /api/appointments/reject/1
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": true,
  "message": "Cap nhat lich hen thanh cong!",
  "data": {
    "appointment": {
      "id": 1,
      "status": "rejected",
      ...
    }
  }
}
```

**Side effects:**
- `UPDATE appointment_deatails SET status = 'rejected'`.
- Gửi FCM push notification đến `user_requested`: *"{ownerName} vua huy lich hen cua ban."*
- Xóa notifications trong bảng `notifications` (giống accept).

---

## 7. POST `/api/appointments/delete/:id`

**Mô tả:** Xóa lịch hẹn. Chỉ chủ card mới được xóa. **Dùng POST, không phải DELETE** (PHP behavior).

**Request:**
```
POST /api/appointments/delete/1
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": true,
  "message": "Xoa lich hen thanh cong!",
  "data": null
}
```

**Side effects:**
- Xóa row trong `appointment_deatails`.
- `UPDATE businesses SET total_appointment = GREATEST(0, total_appointment - 1)`.

---

## 8. POST `/api/public-appointments/add`

**Mô tả:** Tạo lịch hẹn từ Google Calendar webhook. **Không cần auth.**

**Request:**
```
POST /api/public-appointments/add
Content-Type: application/json

{
  "user_id": 5,                          (required)
  "google_calendar_id": "gcal_event_id", (required)
  "date": "2026-03-10",                  (optional)
  "time": "09:00",                       (optional)
  "title": "Google Calendar event",       (optional)
  "note": "Ghi chú"                       (optional)
}
```

**Response:**
```json
{
  "status": true,
  "message": "Appointment created successfully!",
  "data": {
    "appointment": {
      "id": 10,
      "business_id": null,
      "name": null,
      "email": null,
      "phone": null,
      "date": "2026-03-10",
      "time": "09:00",
      "status": "accepted",
      "title": "Google Calendar event",
      "note": "Ghi chú",
      "user_requested": null,
      "google_calendar_id": "gcal_event_id",
      "created_by": 5,
      "created_at": "2026 03 04 08:00:00",
      "updated_at": "2026 03 04 08:00:00"
    }
  }
}
```

**Notes:**
- `status` = `"accepted"` ngay khi tạo (PHP behavior cho Google Calendar).
- `business_id`, `name`, `email`, `phone`, `user_requested` = null (không qua flow booking thông thường).

---

## 9. POST `/api/public-appointments/update`

**Mô tả:** Cập nhật lịch hẹn từ Google Calendar webhook. Tìm appointment theo `user_id` + `google_calendar_id`.

**Request:**
```
POST /api/public-appointments/update
Content-Type: application/json

{
  "user_id": 5,
  "google_calendar_id": "gcal_event_id",
  "date": "2026-03-12",
  "time": "10:00",
  "title": "Updated event",
  "note": "Note mới"
}
```

**Response:**
```json
{
  "status": true,
  "message": "Appointment updated successfully!",
  "data": {
    "appointment": {
      "id": 10,
      "status": "pending",
      ...
    }
  }
}
```

**Notes:** `status` được reset về `"pending"` khi update từ Google Calendar (PHP behavior).

---

## 10. POST `/api/public-appointments/delete`

**Mô tả:** Xóa lịch hẹn từ Google Calendar webhook.

**Request:**
```
POST /api/public-appointments/delete
Content-Type: application/json

{
  "user_id": 5,
  "google_calendar_id": "gcal_event_id"
}
```

**Response:**
```json
{
  "status": true,
  "message": "Appointment deleted successfully!",
  "data": null
}
```

---

## Flow đầy đủ: Đặt lịch hẹn

```
1. User B xem profile card của User A
   → GET /api/businesses/public/{slug}
   → Response có is_enable_appoinment: 1 → hiện nút "Đặt lịch"

2. User B đặt lịch
   → POST /api/appointments/add
   → body: { card_id, name, email, phone, date, time, title, note }
   → Side effects:
     ├── INSERT appointment (status='pending', created_by=ownerA, user_requested=userB)
     ├── INSERT business_histories (type='booked')
     ├── UPDATE businesses SET total_appointment++
     └── FCM push → User A: "{userBName} vua dat lich hen cho ban."

3. User A (chủ card) xem lịch nhận được
   → GET /api/appointments        (không có requested param)
   → Trả danh sách lịch của card A

4a. User A chấp nhận
    → POST /api/appointments/accept/1
    → UPDATE status='accepted'
    → FCM push → User B: "{userAName} vua chap nhan lich hen cua ban."

4b. User A từ chối
    → POST /api/appointments/reject/1
    → UPDATE status='rejected'
    → FCM push → User B: "{userAName} vua huy lich hen cua ban."

5. User B xem lịch đã đặt
   → GET /api/appointments?requested=1
   → Trả danh sách lịch đã book
```

---

## Notes so sánh với PHP

| Field / Behavior | NestJS | PHP | Trạng thái |
|-----------------|--------|-----|-----------|
| Response format | `snake_case` via `toSnakeCase()` | `snake_case` | ✅ Đúng |
| `created_at` format | `"2026 03 03 14:27:14"` | `"2026 03 03 14:27:14"` | ✅ Đúng |
| `business_name` trong list | ✅ Có | ✅ Có | ✅ Đúng |
| `status` initial value | `"pending"` | `"pending"` | ✅ Đúng |
| `created_by` | `business.owner_id` | `business.owner_id` | ✅ Đúng |
| `user_requested` | userId đặt lịch | userId đặt lịch | ✅ Đúng |
| FCM notification khi add | ✅ Có | ✅ Có | ✅ Đúng |
| FCM notification khi accept/reject | ✅ Có | ✅ Có | ✅ Đúng |
| Delete notifications khi accept/reject | ✅ Có | ✅ Có | ✅ Đúng |
| total_appointment decrement khi delete | ✅ Có (`GREATEST(0,...)`) | ✅ Có | ✅ Đúng |
| Table name | `appointment_deatails` (typo giữ nguyên) | `appointment_deatails` | ✅ Đúng |
| Public endpoints status | `add`=`accepted`, `update`=`pending` | Giống | ✅ Đúng |
