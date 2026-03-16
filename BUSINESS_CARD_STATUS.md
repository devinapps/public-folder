# Business Card API — Trạng Thái Hiện Tại

> Cập nhật lần cuối: 2026-03-16

---

## ✅ Đã hoàn thiện (Backend sẵn sàng cho FE)

### Business Cards — `BusinessesController` (`/api/cards`)

| Endpoint | Method | Mô tả | Ghi chú |
|---|---|---|---|
| `/api/cards` | GET | List tất cả cards của user | Filter `?profiles_type=` |
| `/api/cards` | POST | Tạo card mới | Logo upload, auto-slug, auto QR gen |
| `/api/cards/:id` | GET | Lấy chi tiết card | Tracking view/scan, serial lookup `?type=serial` |
| `/api/cards/update/:id` | POST | Cập nhật card | Logo, banner, media, services, socials, contact_info, hours — 1 request |
| `/api/cards/:id` | DELETE | Xoá card | Cascade 8 bảng liên quan + unlink QR |
| `/api/cards/industries` | GET | Danh sách ngành nghề predefined | `?lang=vi` (default vi), public trong AuthGuard |
| `/api/cards/banner/:id` | POST | Upload banner riêng | — |
| `/api/cards/link-card/:id` | POST | Link NFC card vật lý | — |
| `/api/cards/:id/generate-deeplink` | POST | Tạo Firebase Dynamic Link | — |

### Check Card — `CheckCardController` (`/api/check-card`)

| Endpoint | Method | Mô tả | Ghi chú |
|---|---|---|---|
| `/api/check-card/:cardCode` | POST | Kiểm tra trạng thái QR vật lý | 6 status codes, `OptionalAuthGuard` |

### Public Profile — `BusinessesPublicController` (`/api/businesses`)

| Endpoint | Method | Mô tả | Ghi chú |
|---|---|---|---|
| `/api/businesses/public/:slug` | GET | Public profile | View/scan tracking, `@Public()` |

### Appointments — `AppointmentsController` (`/api/appointments`)

| Endpoint | Method | Mô tả | Ghi chú |
|---|---|---|---|
| `/api/appointments` | GET | Lịch hẹn nhận được | `created_by = userId` |
| `/api/appointments?requested=1` | GET | Lịch hẹn tôi đã đặt | `user_requested = userId` |
| `/api/appointments/add` | POST | Tạo booking mới | FCM notify owner, increment total_appointment |
| `/api/appointments/:id` | GET | Chi tiết appointment | Owner-only |
| `/api/appointments/update/:id` | POST | Cập nhật appointment | Partial update |
| `/api/appointments/accept/:id` | POST | Chấp nhận | FCM notify requester |
| `/api/appointments/reject/:id` | POST | Từ chối | FCM notify requester |
| `/api/appointments/delete/:id` | POST | Xoá | Decrement total_appointment |

### Public Appointments — Google Calendar Webhooks

| Endpoint | Method | Mô tả |
|---|---|---|
| `/api/public-appointments/add` | POST | Tạo từ Google Calendar (status=accepted) |
| `/api/public-appointments/update` | POST | Cập nhật từ Google Calendar (status=pending) |
| `/api/public-appointments/delete` | POST | Xoá từ Google Calendar |

---

## ❌ Chưa có — Cần implement thêm

### 1. Analytics Endpoint

```
GET /api/cards/:id/analytics
```

**Trạng thái**: Repository method `getLast15Days(businessId)` **đã tồn tại** tại
`src/modules/businesses/business-history.repository.ts:41` — chỉ cần thêm endpoint.

**Việc cần làm**:
1. Thêm method `getAnalytics(id, userId)` vào `businesses.service.ts`
   - Verify ownership (`ownerId === userId`)
   - Gọi `businessHistoryRepo.getLast15Days(id)`
   - Trả về `total_view`, `total_scan`, `total_appointment` + mảng 15 ngày
2. Thêm route vào `businesses.controller.ts`:
   ```typescript
   @Get(':id/analytics')
   async getAnalytics(@GetUser() user, @Param('id') id: string) { ... }
   ```

**Response mẫu**:
```json
{
  "status": true,
  "data": {
    "total_view": 142,
    "total_scan": 38,
    "total_appointment": 5,
    "last_15_days": [
      { "date": "2026-02-26", "views": 12, "scans": 3 },
      { "date": "2026-02-27", "views": 8, "scans": 1 },
      ...
    ]
  }
}
```

**Ưu tiên**: Cần làm trước khi bắt đầu FE Phase 2 (Analytics).

---

## 🔄 Backlog (Làm sau)

| Item | Lý do hoãn |
|---|---|
| Public profile FE page (`/profile/:slug`) | Không thuộc phase hiện tại |
| Invite co-owner (`owner_ids`) | PHP có nhưng NestJS chưa implement; không cần ngay |
| Appointment config endpoint riêng | `appointment-config.repository.ts` có nhưng `is_enable_appoinment` đã trả về trong `GET /api/cards/:id` |
| Testimonials / Business Hours CRUD riêng | Đã xử lý đủ trong `POST /api/cards/update/:id` |
| Industries POST/DELETE (thêm/xoá ngành cụ thể) | Hiện xử lý qua `industries[]` trong update card, đủ cho CMS |
| Analytics date filter (custom range) | Phase 2.x sau khi có chart cơ bản |

---

## Tóm tắt file quan trọng

| File | Mô tả |
|---|---|
| `src/modules/businesses/businesses.controller.ts` | 3 controllers: BusinessesController, CheckCardController, BusinessesPublicController |
| `src/modules/businesses/businesses.service.ts` | 22 methods (1228 lines) |
| `src/modules/businesses/businesses.repository.ts` | CRUD + view/scan counters |
| `src/modules/businesses/business-history.repository.ts` | `getLast15Days()` — sẵn sàng dùng |
| `src/modules/appointments/appointments.controller.ts` | 2 controllers: AppointmentsController, PublicAppointmentsController |
| `src/modules/appointments/appointments.service.ts` | 12 methods (330 lines) |
| `src/shared/schema.ts` | businesses, appointments, appointment_deatails (typo preserved) |
| `docs/BUSINESS_API_REFERENCE.md` | Full API reference với request/response examples |
| `docs/APPOINTMENT_API_REFERENCE.md` | Full Appointment API reference |
