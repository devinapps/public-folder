# Email List & is_can_test — Backend Implementation Plan

**Version:** 1.0
**Date:** 2026-03-12
**Phase:** D (Email List Management)
**Status:** 📋 PLANNING

---

## Overview

Hai tính năng mới cho Email Campaign:

1. **Email Lists** — Quản lý danh sách user/email tùy chỉnh để gửi campaign
2. **is_can_test** — Đánh dấu user là "test user" để thử nghiệm campaign trước khi broadcast

---

## Database Schema

### Bảng mới: `email_lists`

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

### Bảng mới: `email_list_members`

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

> `user_id` nullable: cho phép thêm email bên ngoài hệ thống (không có trong `users` table)

### Column mới: `users.is_can_test`

```sql
ALTER TABLE users
ADD COLUMN is_can_test TINYINT(1) NOT NULL DEFAULT 0
AFTER updated_at;
```

---

## Drizzle Schema Changes (`src/shared/schema.ts`)

### 1. Thêm `isCanTest` vào bảng `users`

```typescript
// Trong định nghĩa mysqlTable('users', {...})
isCanTest: tinyint('is_can_test').default(0),
```

### 2. Thêm bảng `emailLists`

```typescript
export const emailLists = mysqlTable('email_lists', {
  id: serial('id').primaryKey(),
  name: varchar('name', { length: 255 }).notNull(),
  description: text('description'),
  tags: json('tags').$type<string[]>().default([]),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

export const insertEmailListSchema = createInsertSchema(emailLists).omit({
  id: true, createdAt: true, updatedAt: true,
});
export type EmailList = typeof emailLists.$inferSelect;
export type InsertEmailList = z.infer<typeof insertEmailListSchema>;
```

### 3. Thêm bảng `emailListMembers`

```typescript
export const emailListMembers = mysqlTable('email_list_members', {
  id: serial('id').primaryKey(),
  listId: int('list_id').notNull(),
  userId: int('user_id'),
  email: varchar('email', { length: 255 }).notNull(),
  createdAt: timestamp('created_at').defaultNow(),
});

export const insertEmailListMemberSchema = createInsertSchema(emailListMembers).omit({
  id: true, createdAt: true,
});
export type EmailListMember = typeof emailListMembers.$inferSelect;
export type InsertEmailListMember = z.infer<typeof insertEmailListMemberSchema>;
```

---

## API Endpoints

### Email Lists CRUD

| Method   | Endpoint                         | Mô tả                          | Auth  |
|----------|----------------------------------|--------------------------------|-------|
| `GET`    | `/api/email-lists`               | Danh sách lists (pagination)   | Admin |
| `POST`   | `/api/email-lists`               | Tạo list mới                   | Admin |
| `GET`    | `/api/email-lists/:id`           | Chi tiết 1 list + member count | Admin |
| `PUT`    | `/api/email-lists/:id`           | Cập nhật name/description/tags | Admin |
| `DELETE` | `/api/email-lists/:id`           | Xóa list (cascade members)     | Admin |

### List Members

| Method   | Endpoint                              | Mô tả                                         | Auth  |
|----------|---------------------------------------|-----------------------------------------------|-------|
| `GET`    | `/api/email-lists/:id/members`        | Danh sách members (pagination + search email) | Admin |
| `POST`   | `/api/email-lists/:id/members`        | Thêm members (by user_ids hoặc emails)        | Admin |
| `DELETE` | `/api/email-lists/:id/members`        | Remove members (by user_ids hoặc emails)      | Admin |

### is_can_test

| Method   | Endpoint                    | Mô tả                             | Auth  |
|----------|-----------------------------|-----------------------------------|-------|
| `PATCH`  | `/api/users/:id/can-test`   | Toggle is_can_test cho user       | Admin |

### Send Email — Filter mới

`POST /api/emails/send` bổ sung 2 field:

| Field         | Type      | Mô tả                                          |
|---------------|-----------|------------------------------------------------|
| `list_id`     | `number`  | Gửi cho tất cả members trong Email List        |
| `is_can_test` | `boolean` | Nếu `true` → chỉ gửi cho users có `is_can_test=true` |

> **Priority filter**: `user_emails` > `list_id` > `user_ids/types/date` + `is_can_test` áp dụng lên bất kỳ filter nào

---

## Files cần tạo/sửa

### Tạo mới

```
src/modules/email/
├── email-list.repository.ts       ← CRUD emailLists + emailListMembers
├── email-list.controller.ts       ← REST endpoints
└── dto/
    └── email-list.dto.ts          ← CreateEmailListDto, UpdateEmailListDto, AddMembersDto
```

### Sửa đổi

| File | Thay đổi |
|------|----------|
| `src/shared/schema.ts` | Thêm `isCanTest` vào users, thêm `emailLists`, `emailListMembers` |
| `src/modules/email/email.module.ts` | Import + provide `EmailListRepository`, `EmailListController` |
| `src/common/repository.module.ts` | Export `EmailListRepository` |
| `src/modules/email/dto/send-email.dto.ts` | Thêm `list_id?: number`, `is_can_test?: boolean` |
| `src/modules/email/email.service.ts` | Handle `list_id` + `is_can_test` trong `resolveRecipients()` |
| `src/modules/users/users.controller.ts` | Thêm `PATCH /:id/can-test` endpoint |
| `src/modules/users/users.repository.ts` | Thêm `updateCanTest(id, value)` method |

---

## Implementation Logic

### `resolveRecipients()` — Updated Flow

```
1. user_emails? → return early (highest priority, no DB query)
2. list_id? → query email_list_members WHERE list_id = ?
   → JOIN users ON email = users.email (để lấy user data cho personalization)
3. user_ids / user_types / created_from+to → query users table
4. None of above → all users
5. is_can_test = true? → filter result WHERE is_can_test = 1 (áp dụng sau step 2/3/4)
```

> Khi `list_id` được dùng, `recipient_mode` = `'list'`

### `POST /api/email-lists/:id/members` — Add Logic

```
Input: { user_ids?: number[], emails?: string[] }

1. Nếu có user_ids:
   - Query users WHERE id IN (user_ids) → lấy email
   - Insert vào email_list_members với user_id + email
2. Nếu có emails (raw):
   - Query users WHERE email IN (emails) → lấy user_id nếu có
   - Insert vào email_list_members (user_id có thể NULL)
3. ON DUPLICATE KEY: bỏ qua (upsert với IGNORE)
4. Trả về { added: N, skipped: M }
```

### `PATCH /api/users/:id/can-test` — Toggle Logic

```typescript
// Lấy giá trị hiện tại, flip 0↔1
const user = await usersRepo.findById(id);
const newValue = user.isCanTest ? 0 : 1;
await usersRepo.updateCanTest(id, newValue);
return { id, is_can_test: newValue };
```

---

## DTO Specification

### `CreateEmailListDto`

```typescript
{
  name: string;           // required, min 1
  description?: string;   // optional
  tags?: string[];        // optional, default []
}
```

### `UpdateEmailListDto`

```typescript
{
  name?: string;
  description?: string;
  tags?: string[];
}
```

### `AddMembersDto`

```typescript
{
  user_ids?: number[];    // thêm by user ID
  emails?: string[];      // thêm by email (raw)
}
// Phải có ít nhất 1 trong 2
```

### `RemoveMembersDto`

```typescript
{
  user_ids?: number[];
  emails?: string[];
}
// Phải có ít nhất 1 trong 2
```

### `SendEmailDto` — bổ sung

```typescript
list_id?: number;       // Email List ID
is_can_test?: boolean;  // Chỉ gửi cho test users
```

---

## Response Format

### GET /api/email-lists

```json
{
  "status": true,
  "message": "OK",
  "data": {
    "lists": [
      {
        "id": 1,
        "name": "Beta Users Q1 2026",
        "description": "Danh sách user thử nghiệm tháng 1-3",
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

### GET /api/email-lists/:id/members

```json
{
  "status": true,
  "message": "OK",
  "data": {
    "list": { "id": 1, "name": "Beta Users Q1 2026" },
    "members": [
      { "id": 1, "user_id": 42, "email": "user@example.com", "created_at": "..." }
    ],
    "pagination": { "page": 1, "limit": 20, "total": 250, "pages": 13 }
  }
}
```

### POST /api/email-lists/:id/members

```json
{
  "status": true,
  "message": "Thêm members thành công",
  "data": { "added": 8, "skipped": 2 }
}
```

### PATCH /api/users/:id/can-test

```json
{
  "status": true,
  "message": "Cập nhật thành công",
  "data": { "id": 42, "is_can_test": true }
}
```

---

## Migration File

Xem: [`EMAIL_LIST_MIGRATION.sql`](EMAIL_LIST_MIGRATION.sql)

---

## Execution Order

1. ✅ Chạy SQL migration trong DBeaver (`EMAIL_LIST_MIGRATION.sql`)
2. ✅ Cập nhật `src/shared/schema.ts`
3. ✅ Chạy `npm run db:push`
4. ✅ Tạo `email-list.dto.ts`
5. ✅ Tạo `email-list.repository.ts`
6. ✅ Tạo `email-list.controller.ts`
7. ✅ Cập nhật `email.module.ts` + `repository.module.ts`
8. ✅ Cập nhật `send-email.dto.ts` + `email.service.ts`
9. ✅ Cập nhật `users.controller.ts` + `users.repository.ts`
10. ✅ Run `npm test`
