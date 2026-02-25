# FCM Notification System Documentation

**Version:** 1.0.0
**Framework:** NestJS (Migrated from Laravel)
**Last Updated:** 2026-02-12
**Status:** ✅ Implemented & Tested (Phases 1-5 Complete)

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Reference](#quick-reference)
- [System Components](#system-components)
- [Data Flow](#data-flow)
- [Configuration](#configuration)
- [Queue System](#queue-system)
- [Notification Logic](#notification-logic)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [API Integration](#api-integration)
- [Migration from PHP](#migration-from-php)
- [Future Enhancements](#future-enhancements)

---

## Overview

### What is FCM Notification System?

The FCM (Firebase Cloud Messaging) Notification System is a **background notification service** that automatically sends push notifications to mobile app users when activities are approved. This system runs asynchronously using Redis-based queues to handle high volumes of notifications efficiently.

### Key Features

- ✅ **Automatic Notification Dispatch** - Triggers when admin approves activities
- ✅ **Multi-language Support** - Vietnamese & English with dynamic title variations
- ✅ **Scalable Queue System** - Redis + Bull Queue with chunking strategy
- ✅ **Smart Targeting** - Different logic for super admin posts vs regular user posts
- ✅ **High Performance** - Processes 100 users/chunk, 50 tokens/FCM batch
- ✅ **Reliable Delivery** - Retry logic with exponential backoff (3 attempts)
- ✅ **Complete Logging** - Emoji-based structured logs for easy debugging
- ✅ **Database Persistence** - Stores all notifications in `notifications` table
- ✅ **Notification Counter** - Increments user's `notification_num` field

### When Notifications Are Sent

| Trigger Event | Recipients | Condition |
|---------------|-----------|-----------|
| **Super Admin Post Approved** | ALL users with device tokens | Super admin is activity owner |
| **Regular User Post Approved** | User's contacts only | Regular user is activity owner |
| **Manual Approval** | Based on owner type | Admin approves pending activity |

**⚠️ IMPORTANT:** Notifications are NOT sent via API endpoints. They are dispatched automatically as background jobs when activities are approved.

---

## Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Activity Approval Flow                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  ActivitiesService.approve() → NotificationService.dispatch()   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Redis Queue (Bull)                           │
│  Job: activity-approved → ActivityApprovedProcessor             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│            Determine Recipients (Super Admin Logic)              │
│  - Super admin post → ALL users with device_token               │
│  - Regular user post → Contacts only (TODO: contact_requets)    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│               Chunk Users (100 users per chunk)                 │
│  Dispatch multiple jobs: activity-approved-chunk                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│         ActivityApprovedChunkProcessor (per chunk)              │
│  1. Load users & group by language (vi/en)                     │
│  2. Generate notification title & body                          │
│  3. Store notification in DB                                    │
│  4. Send FCM (50 tokens/batch via FcmService)                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              Firebase Cloud Messaging (FCM)                     │
│  Delivers push notifications to mobile devices                  │
└─────────────────────────────────────────────────────────────────┘
```

### Module Structure

```
src/modules/notifications/
├── fcm.service.ts                          # Firebase Admin SDK integration
├── notification.service.ts                  # Main orchestration service
├── notification.config.ts                   # Configuration & title variations
├── notifications.module.ts                  # Module definition
├── entities/
│   └── notification.entity.ts              # Database entity (Laravel schema)
├── interfaces/
│   └── notification-job.interface.ts       # Job data type definitions
├── processors/
│   ├── activity-approved.processor.ts      # Main job processor
│   └── activity-approved-chunk.processor.ts # Chunk processing
└── __tests__/
    ├── fcm.service.spec.ts                 # FCM service unit tests
    └── notification.service.spec.ts        # Notification service tests
```

---

## Quick Reference

### Queue Jobs

| Queue Name | Job Name | Processor | Purpose |
|------------|----------|-----------|---------|
| `notifications` | `activity-approved` | ActivityApprovedProcessor | Main job - determines recipients & dispatches chunks |
| `notifications` | `activity-approved-chunk` | ActivityApprovedChunkProcessor | Processes 100 users, sends FCM notifications |

### Configuration Constants

```typescript
NOTIFICATION_CONFIG = {
  QUEUE_NAME: 'notifications',
  QUEUE_JOB_APPROVED: 'activity-approved',
  QUEUE_JOB_APPROVED_CHUNK: 'activity-approved-chunk',
  USERS_PER_CHUNK: 100,        // Users per chunk job
  FCM_BATCH_SIZE: 50,          // Tokens per FCM multicast (Firebase limit)
}
```

### Database Tables Used

| Table | Purpose | Key Fields |
|-------|---------|------------|
| `notifications` | Store notification records | `id` (UUID), `type`, `notifiable_id`, `data`, `read_at` |
| `users` | User device tokens & preferences | `device_token`, `lang`, `notification_num` |
| `user_activities` | Activity details for notification | `id`, `user_id`, `content`, `file_uri` |
| `contact_requets` | User connections (TODO) | N/A - Table not yet available |

### Notification Title Variations

**Vietnamese (8 variations):**
- "InCard – Bản tin vừa phát hành"
- "InCard vừa cập nhật tin tức"
- "InCard News vừa có bản tin mới"
- "InCard News – Tin tức vừa cập nhật"
- "InCard – Tin hot vừa được đăng"
- "InCard – Bản tin mới nhất"
- "InCard News vừa phát hành"
- "Tin tức mới từ InCard"

**English (8 variations):**
- "InCard News – Latest news"
- "New post on InCard"
- "InCard – Latest update"
- "New update from InCard"
- "InCard News – Fresh update"
- "InCard just posted"
- "InCard – Breaking news"
- "Latest from InCard News"

**Custom Title Logic:**
- If activity owner is **super admin** → Random variation from list
- If activity owner is **regular user** → Use owner's full name

---

## System Components

### 1. FcmService

**File:** `fcm.service.ts`

**Purpose:** Firebase Admin SDK wrapper for sending push notifications

**Key Methods:**

#### `sendMulticastNotification(tokens: string[], data: NotificationData): Promise<BatchResponse>`

Sends notifications to up to 50 device tokens (Firebase limitation).

**Parameters:**
```typescript
interface NotificationData {
  title: string;       // Notification title (language-specific)
  body: string;        // Notification body (activity content preview)
  image?: string;      // Activity image URL (optional)
  id: string;          // Activity ID as string
  click_action?: string; // Default: 'FLUTTER_NOTIFICATION_CLICK'
}
```

**Example:**
```typescript
const response = await fcmService.sendMulticastNotification(
  ['token1', 'token2', 'token3'],
  {
    title: 'InCard – Bản tin vừa phát hành',
    body: 'Nội dung hoạt động...',
    image: 'https://example.com/image.jpg',
    id: '123'
  }
);
// response.successCount: 3
// response.failureCount: 0
```

**FCM Message Structure:**
```json
{
  "tokens": ["token1", "token2"],
  "notification": {
    "title": "InCard – Bản tin vừa phát hành",
    "body": "Nội dung hoạt động...",
    "imageUrl": "https://example.com/image.jpg"
  },
  "data": {
    "id": "123",
    "image": "https://example.com/image.jpg",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  },
  "android": { "priority": "high" },
  "apns": { "headers": { "apns-priority": "10" } }
}
```

#### `sendBatchNotifications(tokens: string[], data: NotificationData): Promise<void>`

Auto-chunks tokens into groups of 50 and sends in parallel.

**Example:**
```typescript
// Send to 250 tokens → splits into 5 batches of 50
await fcmService.sendBatchNotifications(
  allTokens, // 250 tokens
  notificationData
);
```

**PHP Equivalent:** `FcmService::sendMulticastNotification` (lines 18-84)

---

### 2. NotificationService

**File:** `notification.service.ts`

**Purpose:** Orchestration service for notification workflow

**Key Methods:**

#### `dispatchActivityApprovedNotification(activityId: number, approverId: number): Promise<void>`

Main entry point - dispatches the root notification job.

**Called from:** `ActivitiesService.approve()` (line 323)

**Example:**
```typescript
await notificationService.dispatchActivityApprovedNotification(124, 13);
// Logs: 🚀 [START] Dispatching notification job for activity 124 approved by 13
// Creates job in Redis queue
// Logs: ✅ [SUCCESS] Dispatched activity approved notification job (Job ID: 456)
```

#### `dispatchChunkedJobs(userIds: number[], activityId: number): Promise<void>`

Chunks user IDs into groups of 100 and dispatches separate jobs.

**Example:**
```typescript
await notificationService.dispatchChunkedJobs([1,2,3,...,250], 124);
// Logs: 📦 [CHUNKING] Splitting 250 users into 3 chunks (100 users/chunk)
// Dispatches 3 jobs: chunk 1 (100 users), chunk 2 (100 users), chunk 3 (50 users)
```

#### `storeNotification(userId: number, activityId: number, notificationData: any): Promise<void>`

Stores notification in database and increments user's notification counter.

**Database Operations:**
1. Inserts into `notifications` table (UUID primary key)
2. Increments `users.notification_num` by 1

**Example:**
```typescript
await notificationService.storeNotification(
  5,    // User ID
  124,  // Activity ID
  {
    message: 'Nội dung hoạt động...',
    activity_id: 124,
    user_name: 'John Doe'
  }
);
```

**Notification Record:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "type": "App\\Notifications\\ActivityApproved",
  "notifiable_type": "App\\Models\\User",
  "notifiable_id": 5,
  "data": "{\"message\":\"Nội dung...\",\"activity_id\":124}",
  "read_at": null,
  "created_at": "2026-02-12T10:00:00.000Z"
}
```

#### `getNotificationTitle(lang: string, userType: string, userName: string): string`

Generates notification title based on user type and language.

**Logic:**
```typescript
if (userType === 'super admin') {
  return getRandomNotificationTitle(lang); // Random variation
} else {
  return userName; // Use user's full name
}
```

**Examples:**
```typescript
getNotificationTitle('vi', 'super admin', 'Admin')
// → "InCard – Bản tin vừa phát hành" (random)

getNotificationTitle('en', 'regular', 'John Doe')
// → "John Doe"
```

**PHP Equivalent:** `SendActivityApprovedNotification::dispatch` (lines 18-42)

---

### 3. ActivityApprovedProcessor

**File:** `processors/activity-approved.processor.ts`

**Purpose:** Main job processor - determines recipients and dispatches chunk jobs

**Queue Job:** `activity-approved`

**Process Flow:**

```typescript
@Process(NOTIFICATION_CONFIG.QUEUE_JOB_APPROVED)
async processActivityApproved(job: Job<ActivityApprovedJobData>) {
  const { activityId, approverId } = job.data;

  // 1. Load activity & approver
  const activity = await activityRepository.findOne({ where: { id: activityId } });
  const approver = await userRepository.findOne({ where: { id: approverId } });

  // 2. Determine recipients
  let userIds: number[] = [];

  if (approver.type === 'super admin' && activity.user_id === approver.id) {
    // Super admin post → ALL users with device tokens
    const users = await userRepository.find({
      where: { device_token: Not(IsNull()) }
    });
    userIds = users.map(u => u.id);
  } else {
    // Regular user post → Contacts only
    // TODO: Fetch from contact_requets table
    // Fallback: Send to activity owner only
    if (activity.user.device_token) {
      userIds = [activity.user_id];
    }
  }

  // 3. Dispatch chunk jobs
  await notificationService.dispatchChunkedJobs(userIds, activityId);
}
```

**Recipient Determination Logic:**

| Condition | Recipients | Query |
|-----------|-----------|-------|
| Super admin is activity owner | ALL users with `device_token` | `SELECT id FROM users WHERE device_token IS NOT NULL` |
| Regular user is activity owner | User's contacts (TODO) | Fallback: Activity owner only |

**Logs Example:**
```
🔔 [MAIN JOB] Processing activity approved notification for activity 124 approved by 13
📖 [DB] Loading activity 124...
✓ Activity loaded: "Nội dung hoạt động mới..."
📖 [DB] Loading approver 13...
✓ Approver loaded: admin@example.com (type: super admin)
✓ Activity owner: admin@example.com (ID: 13)
👑 [SUPER ADMIN] Super admin post detected - sending to ALL users
📖 [DB] Fetching all users with device tokens...
✓ Found 250 users with device tokens
📤 [DISPATCH] Dispatching chunk jobs for 250 recipients
✅ [MAIN JOB COMPLETE] Successfully processed activity approved notification
```

**PHP Equivalent:** `SendActivityApprovedNotification::handle` (lines 43-83)

---

### 4. ActivityApprovedChunkProcessor

**File:** `processors/activity-approved-chunk.processor.ts`

**Purpose:** Processes 100 users per job - sends FCM notifications

**Queue Job:** `activity-approved-chunk`

**Process Flow:**

```typescript
@Process(NOTIFICATION_CONFIG.QUEUE_JOB_APPROVED_CHUNK)
async processActivityApprovedChunk(job: Job<ActivityApprovedChunkJobData>) {
  const { activityId, userIds } = job.data;

  // 1. Load activity
  const activity = await activityRepository.findOne({ where: { id: activityId } });

  // 2. Load users with device tokens
  const users = await userRepository.find({
    where: {
      id: In(userIds),
      device_token: Not(IsNull())
    }
  });

  // 3. Group users by language
  const usersByLang = users.reduce((acc, user) => {
    const lang = user.lang || 'vi';
    if (!acc[lang]) acc[lang] = [];
    acc[lang].push(user);
    return acc;
  }, {} as Record<string, User[]>);

  // 4. Send notifications per language group
  for (const [lang, langUsers] of Object.entries(usersByLang)) {
    const title = notificationService.getNotificationTitle(
      lang,
      activity.user.type,
      activity.user.full_name
    );

    const body = getActivityBody(activity, lang);

    // 5. Store notifications in DB
    for (const user of langUsers) {
      await notificationService.storeNotification(user.id, activityId, {
        message: body,
        activity_id: activityId,
        user_name: activity.user.full_name
      });
    }

    // 6. Send FCM (auto-chunks to 50 tokens/batch)
    const tokens = langUsers
      .map(u => u.device_token)
      .filter(t => t);

    await fcmService.sendBatchNotifications(tokens, {
      title,
      body,
      image: activity.file_uri,
      id: String(activityId)
    });
  }
}
```

**Language Grouping Example:**

```
100 users in chunk:
- 75 users with lang='vi'
- 20 users with lang='en'
- 5 users with lang=null (default to 'vi')

Groups:
- vi: 80 users → 2 FCM batches (50 + 30)
- en: 20 users → 1 FCM batch (20)
```

**Logs Example:**
```
🔔 [CHUNK JOB] Processing chunk for activity 124 with 100 users
📖 [DB] Loading activity 124...
✓ Activity loaded
📖 [DB] Loading 100 users with device tokens...
✓ Found 95 users with device tokens (5 users had null tokens)
🌐 [LANGUAGES] Users grouped by language: vi:75, en:20
📲 [FCM] Sending to 75 Vietnamese users...
📲 [FCM BATCH] Sending batch 1/2: 50 tokens
✅ [FCM RESULT] Sent to 50 tokens | ✓ Success: 50 | ✗ Failed: 0
📲 [FCM BATCH] Sending batch 2/2: 25 tokens
✅ [FCM RESULT] Sent to 25 tokens | ✓ Success: 25 | ✗ Failed: 0
💾 [DB] Stored 75 notifications for Vietnamese users
📲 [FCM] Sending to 20 English users...
✅ [FCM RESULT] Sent to 20 tokens | ✓ Success: 20 | ✗ Failed: 0
💾 [DB] Stored 20 notifications for English users
✅ [CHUNK COMPLETE] Successfully processed chunk for activity 124
```

**PHP Equivalent:** `SendActivityApprovedChunkJob::handle` (lines 88-156)

---

## Data Flow

### Complete Notification Flow (250 Users Example)

```
Step 1: Activity Approved
├─ POST /db-feeds/activities/approve { id: 124 }
├─ ActivitiesService.approve(124, adminUser)
├─ Status changed: Pending → Approved
├─ GetStream activity created
└─ NotificationService.dispatchActivityApprovedNotification(124, 13)

Step 2: Main Job Queued
├─ Job: activity-approved
├─ Data: { activityId: 124, approverId: 13 }
└─ Redis Queue: 1 job pending

Step 3: Main Job Processing (ActivityApprovedProcessor)
├─ Load activity 124 (with user relation)
├─ Load approver 13
├─ Check: approver.type = 'super admin', activity.user_id = 13
├─ Decision: Send to ALL users
├─ Query: SELECT id FROM users WHERE device_token IS NOT NULL
├─ Result: 250 user IDs
└─ Dispatch chunked jobs: 3 chunks (100, 100, 50)

Step 4: Chunk Jobs Queued
├─ Job 1: activity-approved-chunk { activityId: 124, userIds: [1...100] }
├─ Job 2: activity-approved-chunk { activityId: 124, userIds: [101...200] }
└─ Job 3: activity-approved-chunk { activityId: 124, userIds: [201...250] }

Step 5: Chunk Job 1 Processing (ActivityApprovedChunkProcessor)
├─ Load 100 users with device_token
├─ Filter: 95 users have valid tokens (5 null)
├─ Group by language: vi=75, en=20
│
├─ Vietnamese Group (75 users):
│   ├─ Generate title: "InCard – Bản tin vừa phát hành"
│   ├─ Generate body: "Nội dung hoạt động..."
│   ├─ Store 75 notifications in DB
│   ├─ Increment notification_num for 75 users
│   ├─ Send FCM batch 1: 50 tokens
│   │   └─ Success: 50/50
│   └─ Send FCM batch 2: 25 tokens
│       └─ Success: 25/25
│
└─ English Group (20 users):
    ├─ Generate title: "New post on InCard"
    ├─ Generate body: "Activity content..."
    ├─ Store 20 notifications in DB
    ├─ Increment notification_num for 20 users
    └─ Send FCM batch: 20 tokens
        └─ Success: 20/20

Step 6: Chunk Jobs 2 & 3 (Same Process)
├─ Job 2: 95 users → 75 vi + 20 en
└─ Job 3: 48 users → 40 vi + 8 en

Final Result:
├─ Total users processed: 250
├─ Total valid tokens: 238 (12 users had null device_token)
├─ Total notifications stored: 238
├─ Total FCM batches sent: 5 (50+50+50+50+38)
├─ Total successes: 238
├─ Total failures: 0
└─ Processing time: ~3-5 seconds (parallel processing)
```

### Job Data Structures

**ActivityApprovedJobData:**
```typescript
interface ActivityApprovedJobData {
  activityId: number;   // Activity ID that was approved
  approverId: number;   // User ID who approved it
}
```

**ActivityApprovedChunkJobData:**
```typescript
interface ActivityApprovedChunkJobData {
  activityId: number;   // Activity ID
  userIds: number[];    // Array of user IDs to notify (max 100)
}
```

---

## Configuration

### Environment Variables

**Required:**
```env
# Firebase Configuration
FIREBASE_CREDENTIALS=your-firebase-adminsdk-credentials.json

# Redis Configuration (for Bull Queue)
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_PASSWORD=null    # Set to actual password or null
```

### Firebase Credentials File

**Location:** Project root (same level as `package.json`)

**File:** `your-firebase-adminsdk-credentials.json`

**Content Structure:**
```json
{
  "type": "service_account",
  "project_id": "your-firebase-project-id",
  "private_key_id": "your-private-key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxx@your-project.iam.gserviceaccount.com",
  "client_id": "your-client-id",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "your-client-cert-url"
}
```

**⚠️ Security:** This file contains sensitive credentials and should NEVER be committed to Git. Add to `.gitignore`:
```
# Firebase credentials
*-firebase-adminsdk-*.json
```

### Module Configuration

**File:** `app.module.ts`

```typescript
import { BullModule } from '@nestjs/bull';

@Module({
  imports: [
    // Bull Queue Configuration
    BullModule.forRoot({
      redis: {
        host: process.env.REDIS_HOST || '127.0.0.1',
        port: parseInt(process.env.REDIS_PORT || '6379'),
        password: process.env.REDIS_PASSWORD === 'null'
          ? undefined
          : process.env.REDIS_PASSWORD,
      },
    }),

    // Notifications Module
    NotificationsModule,

    // Other modules...
  ],
})
export class AppModule {}
```

### Notification Configuration

**File:** `notification.config.ts`

```typescript
export const NOTIFICATION_CONFIG = {
  QUEUE_NAME: 'notifications',
  QUEUE_JOB_APPROVED: 'activity-approved',
  QUEUE_JOB_APPROVED_CHUNK: 'activity-approved-chunk',
  USERS_PER_CHUNK: 100,
  FCM_BATCH_SIZE: 50,
};

export const NOTIFICATION_TITLES_VI = [
  'InCard – Bản tin vừa phát hành',
  'InCard vừa cập nhật tin tức',
  'InCard News vừa có bản tin mới',
  'InCard News – Tin tức vừa cập nhật',
  'InCard – Tin hot vừa được đăng',
  'InCard – Bản tin mới nhất',
  'InCard News vừa phát hành',
  'Tin tức mới từ InCard',
];

export const NOTIFICATION_TITLES_EN = [
  'InCard News – Latest news',
  'New post on InCard',
  'InCard – Latest update',
  'New update from InCard',
  'InCard News – Fresh update',
  'InCard just posted',
  'InCard – Breaking news',
  'Latest from InCard News',
];
```

---

## Queue System

### Bull Queue Architecture

```
Redis Server (127.0.0.1:6379)
│
├─ Queue: notifications
│  ├─ Job Type: activity-approved (Main)
│  │  ├─ Priority: Normal
│  │  ├─ Attempts: 3
│  │  ├─ Backoff: Exponential (2000ms)
│  │  └─ Processor: ActivityApprovedProcessor
│  │
│  └─ Job Type: activity-approved-chunk (Chunked)
│     ├─ Priority: Normal
│     ├─ Attempts: 3
│     ├─ Backoff: Exponential (2000ms)
│     ├─ Delay: index * 100ms (to avoid overwhelming FCM)
│     └─ Processor: ActivityApprovedChunkProcessor
│
└─ Queue Monitoring: Bull Board (optional)
```

### Job States

| State | Description |
|-------|-------------|
| `waiting` | Job is in queue, waiting to be processed |
| `active` | Job is currently being processed |
| `completed` | Job finished successfully |
| `failed` | Job failed after all retry attempts |
| `delayed` | Job is delayed (for chunk jobs with stagger) |

### Retry Strategy

```typescript
{
  attempts: 3,                    // Retry up to 3 times
  backoff: {
    type: 'exponential',         // Exponential backoff
    delay: 2000,                 // Base delay: 2 seconds
  }
}
// Retry delays: 2s, 4s, 8s
```

### Queue Monitoring

**Install Bull Board (Optional):**
```bash
npm install @bull-board/express
```

**Setup:**
```typescript
import { createBullBoard } from '@bull-board/api';
import { BullAdapter } from '@bull-board/api/bullAdapter';
import { ExpressAdapter } from '@bull-board/express';

const serverAdapter = new ExpressAdapter();
createBullBoard({
  queues: [new BullAdapter(notificationQueue)],
  serverAdapter,
});

serverAdapter.setBasePath('/admin/queues');
app.use('/admin/queues', serverAdapter.getRouter());
```

**Access:** `http://localhost:3001/admin/queues`

---

## Notification Logic

### Title Generation

```typescript
function getActivityNotificationTitle(
  lang: string,
  userType: string,
  userName: string
): string {
  if (userType === 'super admin') {
    // Random variation from title array
    return getRandomNotificationTitle(lang);
  } else {
    // Use user's full name
    return userName;
  }
}
```

**Examples:**

| User Type | Language | User Name | Result |
|-----------|----------|-----------|--------|
| super admin | vi | Admin | "InCard – Bản tin vừa phát hành" (random) |
| super admin | en | Admin | "New post on InCard" (random) |
| regular | vi | Nguyễn Văn A | "Nguyễn Văn A" |
| regular | en | John Doe | "John Doe" |

### Body Generation

```typescript
function getActivityBody(activity: UserActivity, lang: string): string {
  const content = lang === 'vi' ? activity.content : activity.content_en;

  // Truncate to 100 characters
  if (content.length > 100) {
    return content.substring(0, 97) + '...';
  }

  return content;
}
```

**Examples:**
```
Vietnamese:
"Chào mừng các bạn đến với InCard! Đây là nền tảng kết nối doanh nghiệp hàng đầu..."

English:
"Welcome to InCard! This is the leading business networking platform for professionals in Vietnam..."
```

### Recipient Selection Logic

**Super Admin Post (approver = activity owner):**
```sql
-- Send to ALL users with device tokens
SELECT id, device_token, lang, full_name
FROM users
WHERE device_token IS NOT NULL;
```

**Regular User Post:**
```sql
-- TODO: Send to user's contacts
-- Current implementation: Fallback to activity owner only
SELECT id, device_token, lang, full_name
FROM users
WHERE id = ? AND device_token IS NOT NULL;
```

**Future Implementation (when `contact_requets` table available):**
```sql
-- Get user's contacts
SELECT DISTINCT u.id, u.device_token, u.lang, u.full_name
FROM users u
INNER JOIN contact_requets cr ON (
  (cr.from_user_id = ? AND cr.to_user_id = u.id) OR
  (cr.to_user_id = ? AND cr.from_user_id = u.id)
)
WHERE cr.status = 'accepted'
  AND u.device_token IS NOT NULL;
```

### Database Storage

**Notification Record:**
```typescript
{
  id: UUID,                               // Auto-generated UUID v4
  type: 'App\\Notifications\\ActivityApproved',
  notifiable_type: 'App\\Models\\User',
  notifiable_id: userId,
  data: JSON.stringify({
    message: 'Nội dung hoạt động...',
    activity_id: 124,
    user_name: 'Nguyễn Văn A',
    image: 'https://...'
  }),
  read_at: null,
  created_at: timestamp,
  updated_at: timestamp
}
```

**User Counter Increment:**
```sql
UPDATE users
SET notification_num = notification_num + 1
WHERE id = ?;
```

---

## Testing

### Unit Tests

**Location:** `src/modules/notifications/__tests__/`

**Test Files:**
- `fcm.service.spec.ts` (4 tests)
- `notification.service.spec.ts` (8 tests)

**Run Tests:**
```bash
# Run all notification tests
npm test -- --testPathPatterns=notifications

# Run specific test file
npm test -- fcm.service.spec

# Run with coverage
npm test -- --coverage --testPathPatterns=notifications
```

**Test Results:**
```
Test Suites: 2 passed, 2 total
Tests:       12 passed, 12 total
Snapshots:   0 total
Time:        3.456 s
```

### Integration Testing via API

**Prerequisites:**
1. ✅ Redis running on `localhost:6379`
2. ✅ PostgreSQL database connected
3. ✅ Firebase credentials file in place
4. ✅ `.env` file configured
5. ✅ NestJS app running on `localhost:3001`

**Test Flow:**

**Step 1: Start Application**
```bash
npm run start:dev
```

**Step 2: Login as Admin**
```http
POST http://localhost:3001/api/auth/login
Content-Type: application/json

{
  "email": "admin@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "status": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 13,
      "type": "super admin"
    }
  }
}
```

**Step 3: Create Activity (as Super Admin)**
```http
POST http://localhost:3001/api/external/db-feeds/activities/create
Authorization: Bearer <your-token>
Content-Type: multipart/form-data

title=Test Notification
content=Đây là nội dung test notification system
```

**Response:**
```json
{
  "status": true,
  "data": {
    "id": 124,
    "status": "Pending",  // Super admin posts need approval
    "user_id": 13
  }
}
```

**Step 4: Approve Activity**
```http
POST http://localhost:3001/api/external/db-feeds/activities/approve
Authorization: Bearer <your-token>
Content-Type: application/json

{
  "id": 124
}
```

**Response:**
```json
{
  "status": true,
  "message": "Phê duyệt hoạt động thành công",
  "data": {
    "id": 124,
    "status": "Approved",
    "approved_by": 13,
    "getstream_activity_id": "..."
  }
}
```

**Step 5: Check Console Logs**

```
Activity 124 approved and published to GetStream
🚀 [START] Dispatching notification job for activity 124 approved by 13
✅ [SUCCESS] Dispatched activity approved notification job for activity 124 (Job ID: 456)
Dispatched notification job for activity 124

🔔 [MAIN JOB] Processing activity approved notification for activity 124 approved by 13
📖 [DB] Loading activity 124...
✓ Activity loaded: "Đây là nội dung test notification system"
📖 [DB] Loading approver 13...
✓ Approver loaded: admin@example.com (type: super admin)
✓ Activity owner: admin@example.com (ID: 13)
👑 [SUPER ADMIN] Super admin post detected - sending to ALL users
📖 [DB] Fetching all users with device tokens...
✓ Found 250 users with device tokens
📤 [DISPATCH] Dispatching chunk jobs for 250 recipients
📦 [CHUNKING] Splitting 250 users into 3 chunks (100 users/chunk)
📤 [CHUNK 1/3] Dispatching job for 100 users
📤 [CHUNK 2/3] Dispatching job for 100 users
📤 [CHUNK 3/3] Dispatching job for 50 users
✅ [CHUNKS DISPATCHED] All 3 chunk jobs dispatched successfully
✅ [MAIN JOB COMPLETE] Successfully processed activity approved notification for activity 124

🔔 [CHUNK JOB] Processing chunk for activity 124 with 100 users
📖 [DB] Loading activity 124...
✓ Activity loaded
📖 [DB] Loading 100 users with device tokens...
✓ Found 95 users with device tokens
🌐 [LANGUAGES] Users grouped by language: vi:75, en:20
📲 [FCM] Sending to 75 Vietnamese users...
🚀 [FCM] Sending to 50 tokens...
✅ [FCM RESULT] Sent to 50 tokens | ✓ Success: 50 | ✗ Failed: 0
🚀 [FCM] Sending to 25 tokens...
✅ [FCM RESULT] Sent to 25 tokens | ✓ Success: 25 | ✗ Failed: 0
💾 [DB] Stored 75 notifications for Vietnamese users
📲 [FCM] Sending to 20 English users...
✅ [FCM RESULT] Sent to 20 tokens | ✓ Success: 20 | ✗ Failed: 0
💾 [DB] Stored 20 notifications for English users
✅ [CHUNK COMPLETE] Successfully processed chunk for activity 124
```

**Step 6: Verify Database**

```sql
-- Check notifications created
SELECT COUNT(*) FROM notifications
WHERE type = 'App\\Notifications\\ActivityApproved';
-- Expected: 238 (total valid tokens)

-- Check notification counters incremented
SELECT id, email, notification_num
FROM users
WHERE device_token IS NOT NULL
LIMIT 10;

-- Check specific notification
SELECT * FROM notifications
WHERE notifiable_id = 5
ORDER BY created_at DESC
LIMIT 1;
```

### Manual Test Script

**File:** `test-notification-manual.ts`

**Usage:**
```bash
npx ts-node test-notification-manual.ts
```

**What it does:**
- Dispatches a test notification job directly
- Bypasses API endpoints
- Useful for testing queue processing in isolation

---

## Troubleshooting

### Common Issues

#### 1. Redis Connection Failed

**Error:**
```
Error: connect ECONNREFUSED 127.0.0.1:6379
```

**Solution:**
```bash
# Check if Redis is running
redis-cli ping
# Expected: PONG

# If not running, start Redis
# Windows: redis-server.exe
# Linux/Mac: redis-server
# Docker: docker run -d -p 6379:6379 redis
```

#### 2. Firebase Initialization Failed

**Error:**
```
Failed to initialize Firebase Admin SDK
Error: ENOENT: no such file or directory
```

**Solution:**
1. Check Firebase credentials file exists:
   ```bash
   ls -la *-firebase-adminsdk-*.json
   ```
2. Verify `.env` file:
   ```env
   FIREBASE_CREDENTIALS=your-firebase-adminsdk-credentials.json
   ```
3. Ensure file is in project root (same level as `package.json`)

#### 3. No Notifications Sent

**Symptoms:**
- Job completes successfully
- No FCM notifications received on mobile
- Logs show: `⚠️ [NO RECIPIENTS] No recipients found`

**Possible Causes:**

**A. No Users with Device Tokens**
```sql
-- Check user tokens
SELECT COUNT(*) FROM users WHERE device_token IS NOT NULL;
-- If 0, no users have registered device tokens
```

**B. Activity Owner Has No Token (Regular User Post)**
```sql
-- Check activity owner's token
SELECT u.id, u.email, u.device_token
FROM users u
INNER JOIN user_activities ua ON ua.user_id = u.id
WHERE ua.id = 124;
-- If device_token is NULL, owner won't receive notification
```

**C. Contact Table Not Implemented (Regular User Post)**
```
⚠️ [CONTACTS MISSING] contact_requets table not available - fallback to owner only
```
- Regular user posts only send to activity owner (fallback)
- Full contacts implementation pending

**Solution:**
1. Add test device tokens to users:
   ```sql
   UPDATE users
   SET device_token = 'test-token-123'
   WHERE id IN (1, 2, 3);
   ```
2. Test with super admin post (sends to ALL users)

#### 4. FCM Failures

**Logs:**
```
⚠️ [FCM FAILURES] 5 notification(s) failed
   ✗ Token 1: messaging/invalid-registration-token - Invalid token
   ✗ Token 3: messaging/registration-token-not-registered - Token not registered
```

**Common FCM Error Codes:**

| Error Code | Description | Action |
|------------|-------------|--------|
| `messaging/invalid-registration-token` | Token format is invalid | Remove invalid token from database |
| `messaging/registration-token-not-registered` | Token is no longer valid | Remove expired token from database |
| `messaging/message-rate-exceeded` | Too many messages to device | Implement rate limiting |
| `messaging/server-unavailable` | FCM server down | Retry later (automatic with backoff) |

**Auto-cleanup Solution:**
```typescript
// In FcmService.sendMulticastNotification
if (response.failureCount > 0) {
  const invalidTokens = [];
  response.responses.forEach((resp, idx) => {
    if (!resp.success &&
        (resp.error?.code === 'messaging/invalid-registration-token' ||
         resp.error?.code === 'messaging/registration-token-not-registered')) {
      invalidTokens.push(tokens[idx]);
    }
  });

  // Clean up invalid tokens
  await this.cleanupInvalidTokens(invalidTokens);
}
```

#### 5. Jobs Stuck in Queue

**Symptoms:**
- Jobs stay in `waiting` state
- No processing happening
- Bull Board shows active jobs = 0

**Check:**
```bash
# Check Redis connection
redis-cli ping

# Check queue status
redis-cli LLEN bull:notifications:waiting
redis-cli LLEN bull:notifications:active
redis-cli LLEN bull:notifications:completed
redis-cli LLEN bull:notifications:failed
```

**Solution:**
1. Restart application (processors not registered)
2. Check processor decorators:
   ```typescript
   @Processor(NOTIFICATION_CONFIG.QUEUE_NAME)  // Must match queue name
   export class ActivityApprovedProcessor {
     @Process(NOTIFICATION_CONFIG.QUEUE_JOB_APPROVED)  // Must match job name
   }
   ```
3. Check module imports:
   ```typescript
   @Module({
     providers: [
       ActivityApprovedProcessor,  // Must be registered
       ActivityApprovedChunkProcessor,
     ]
   })
   ```

#### 6. Database Constraint Violations

**Error:**
```
QueryFailedError: duplicate key value violates unique constraint "notifications_pkey"
```

**Cause:** UUID generation failed or duplicate ID

**Solution:**
```typescript
// Ensure @BeforeInsert() is present in notification.entity.ts
@BeforeInsert()
generateId() {
  if (!this.id) {
    this.id = uuidv4();
  }
}
```

#### 7. Memory Issues (Large User Base)

**Symptoms:**
- Server crashes during notification processing
- Out of memory errors
- Slow performance

**Solutions:**

**A. Reduce Chunk Size**
```typescript
// notification.config.ts
export const NOTIFICATION_CONFIG = {
  USERS_PER_CHUNK: 50,  // Reduce from 100 to 50
};
```

**B. Add Chunk Delay**
```typescript
// notification.service.ts
delay: index * 500,  // Increase from 100ms to 500ms
```

**C. Implement Pagination**
```typescript
// Instead of loading all users at once
const users = await this.userRepository.find({
  select: ['id'],
  where: { device_token: Not(IsNull()) },
  take: 1000,  // Limit to 1000 users
});
```

---

## API Integration

### Integration Points

**1. Activity Approval**

**File:** `activities.service.ts` (line 323)

```typescript
async approve(activityId: number, approver: User): Promise<UserActivity> {
  // ... existing approval logic ...

  // Update status to Approved
  activity.status = ActivityStatus.Approved;
  activity.approved_by = approver.id;
  activity.approved_at = new Date();

  // Publish to GetStream
  const getstreamId = await this.publishToGetStream(activity);
  activity.getstream_activity_id = getstreamId;

  await this.activityRepository.save(activity);

  this.logger.log(`Activity ${activity.id} approved and published to GetStream`);

  // 🔔 NOTIFICATION INTEGRATION POINT
  await this.notificationService.dispatchActivityApprovedNotification(
    activity.id,
    approver.id,
  );

  this.logger.log(`Dispatched notification job for activity ${activity.id}`);

  return activity;
}
```

**2. Activity Creation (Auto-Approval for Regular Users)**

**File:** `activities.service.ts`

```typescript
async create(createDto: CreateActivityDto, user: User): Promise<UserActivity> {
  // ... create activity logic ...

  if (user.type === 'super admin') {
    // Super admin posts need approval (no notification yet)
    activity.status = ActivityStatus.Pending;
  } else {
    // Regular user posts are auto-approved
    activity.status = ActivityStatus.Approved;
    const getstreamId = await this.publishToGetStream(activity);
    activity.getstream_activity_id = getstreamId;

    await this.activityRepository.save(activity);

    // 🔔 NOTIFICATION FOR AUTO-APPROVED ACTIVITIES
    await this.notificationService.dispatchActivityApprovedNotification(
      activity.id,
      user.id,  // User is both creator and approver
    );
  }

  return activity;
}
```

### Module Dependencies

**File:** `activities.module.ts`

```typescript
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([UserActivity]),
    GetStreamModule,
    NotificationsModule,  // Import NotificationsModule
  ],
  controllers: [ActivitiesController, ActivitiesPublicController],
  providers: [ActivitiesService],
  exports: [ActivitiesService],
})
export class ActivitiesModule {}
```

**File:** `activities.service.ts`

```typescript
import { NotificationService } from '../notifications/notification.service';

@Injectable()
export class ActivitiesService {
  constructor(
    @InjectRepository(UserActivity)
    private activityRepository: Repository<UserActivity>,
    private getstreamService: GetStreamService,
    private notificationService: NotificationService,  // Inject NotificationService
  ) {}
}
```

---

## Migration from PHP

### Laravel vs NestJS Comparison

| Component | Laravel (PHP) | NestJS (TypeScript) |
|-----------|---------------|---------------------|
| **Queue System** | Laravel Queue | Bull Queue |
| **Queue Backend** | Redis | Redis |
| **Job Class** | `SendActivityApprovedNotification` | `ActivityApprovedProcessor` |
| **Chunk Job** | `SendActivityApprovedChunkJob` | `ActivityApprovedChunkProcessor` |
| **FCM Library** | Custom cURL multi-handle | Firebase Admin SDK |
| **ORM** | Eloquent | TypeORM |
| **Notification Storage** | Laravel Notifications | Manual repository save |
| **Config** | `config/constants.php` | `notification.config.ts` |

### Code Equivalents

**PHP (Laravel):**
```php
// Dispatch job
SendActivityApprovedNotification::dispatch($activityId, $approverId);

// Job handle method
class SendActivityApprovedNotification implements ShouldQueue {
    public function handle() {
        $activity = UserActivity::with('user')->find($this->activityId);

        // Determine recipients
        if ($approver->type === 'super admin' && $activity->user_id === $approver->id) {
            $userIds = User::whereNotNull('device_token')->pluck('id')->toArray();
        }

        // Dispatch chunks
        $chunks = array_chunk($userIds, 100);
        foreach ($chunks as $chunk) {
            SendActivityApprovedChunkJob::dispatch($this->activityId, $chunk);
        }
    }
}
```

**NestJS (TypeScript):**
```typescript
// Dispatch job
await this.notificationService.dispatchActivityApprovedNotification(activityId, approverId);

// Job processor
@Processor('notifications')
export class ActivityApprovedProcessor {
  @Process('activity-approved')
  async processActivityApproved(job: Job<ActivityApprovedJobData>) {
    const activity = await this.activityRepository.findOne({
      where: { id: job.data.activityId },
      relations: ['user'],
    });

    // Determine recipients
    if (approver.type === 'super admin' && activity.user_id === approver.id) {
      const users = await this.userRepository.find({
        where: { device_token: Not(IsNull()) },
      });
      userIds = users.map(u => u.id);
    }

    // Dispatch chunks
    await this.notificationService.dispatchChunkedJobs(userIds, activityId);
  }
}
```

### Key Differences

**1. Queue Job Dispatch:**
- **Laravel:** `Job::dispatch($data)`
- **NestJS:** `queue.add(jobName, data)`

**2. Job Processing:**
- **Laravel:** `public function handle()` method
- **NestJS:** `@Process('job-name')` decorator

**3. FCM Sending:**
- **Laravel:** Custom cURL multi-handle implementation
- **NestJS:** Firebase Admin SDK (`sendEachForMulticast`)

**4. Notification Storage:**
- **Laravel:** `$user->notify(new ActivityApproved($data))`
- **NestJS:** Manual repository save with UUID generation

**5. Database Queries:**
- **Laravel:** `User::whereNotNull('device_token')->get()`
- **NestJS:** `repository.find({ where: { device_token: Not(IsNull()) } })`

### Migration Checklist

- [x] Install dependencies (firebase-admin, @nestjs/bull, bull)
- [x] Configure Redis connection
- [x] Copy Firebase credentials from PHP project
- [x] Create notification.entity.ts matching Laravel schema
- [x] Implement FcmService (replace cURL with Firebase SDK)
- [x] Implement NotificationService (dispatch logic)
- [x] Implement ActivityApprovedProcessor (main job)
- [x] Implement ActivityApprovedChunkProcessor (chunk job)
- [x] Add device_token, lang, notification_num to User entity
- [x] Integrate with ActivitiesService.approve()
- [x] Add structured logging (emoji-based)
- [x] Create unit tests (12 tests)
- [x] Test via API approve endpoint
- [ ] Implement contact_requets table integration (future)

---

## Future Enhancements

### Phase 6: Contact Integration (Planned)

**Current Limitation:**
Regular user posts only send notifications to the activity owner (fallback logic).

**Planned Implementation:**

**1. Create Contact Entity:**
```typescript
@Entity('contact_requets')  // Note: Table name has typo from PHP
export class ContactRequest {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  from_user_id: number;

  @Column()
  to_user_id: number;

  @Column({ type: 'varchar', length: 20 })
  status: string;  // accepted, pending, rejected

  @CreateDateColumn()
  created_at: Date;
}
```

**2. Update Recipient Logic:**
```typescript
// In ActivityApprovedProcessor
if (approver.type === 'super admin' && activity.user_id === approver.id) {
  // Super admin post → ALL users
  userIds = await this.getAllUsersWithTokens();
} else {
  // Regular user post → User's contacts
  userIds = await this.getUserContacts(activityOwner.id);
}

async getUserContacts(userId: number): Promise<number[]> {
  const contacts = await this.contactRepository
    .createQueryBuilder('cr')
    .select('DISTINCT u.id')
    .innerJoin('users', 'u', `
      (cr.from_user_id = :userId AND cr.to_user_id = u.id) OR
      (cr.to_user_id = :userId AND cr.from_user_id = u.id)
    `)
    .where('cr.status = :status', { status: 'accepted' })
    .andWhere('u.device_token IS NOT NULL')
    .setParameter('userId', userId)
    .getRawMany();

  return contacts.map(c => c.id);
}
```

**3. Add Logging:**
```typescript
this.logger.log(`📇 [CONTACTS] Found ${userIds.length} contacts for user ${activityOwner.id}`);
```

**Files to Modify:**
- `src/modules/contacts/entities/contact-request.entity.ts` (create)
- `src/modules/notifications/processors/activity-approved.processor.ts` (update)

---

### Phase 7: Advanced Features (Future)

**1. Notification Preferences**

Allow users to control notification types:
```typescript
@Column({ type: 'json', nullable: true })
notification_preferences: {
  activity_approved: boolean;
  new_contact: boolean;
  comment_added: boolean;
};
```

**2. Scheduled Notifications**

Batch notifications instead of real-time:
```typescript
// Queue job to run every hour
@Cron('0 * * * *')
async processBatchedNotifications() {
  // Process all pending notifications from last hour
}
```

**3. Push Notification Analytics**

Track delivery & engagement:
```typescript
@Entity('notification_analytics')
export class NotificationAnalytics {
  @Column()
  notification_id: string;

  @Column()
  delivered_at: Date;

  @Column({ nullable: true })
  opened_at: Date;

  @Column({ type: 'varchar' })
  device_platform: string;  // ios, android
}
```

**4. Rich Notifications**

Add actions, images, custom sounds:
```typescript
const message: MulticastMessage = {
  notification: {
    title: data.title,
    body: data.body,
    imageUrl: data.image,
  },
  android: {
    notification: {
      sound: 'default',
      color: '#FF5722',
      clickAction: 'FLUTTER_NOTIFICATION_CLICK',
    },
  },
  apns: {
    payload: {
      aps: {
        sound: 'default',
        badge: 1,
        category: 'ACTIVITY_APPROVED',
      },
    },
  },
};
```

**5. Notification Grouping**

Group multiple notifications:
```typescript
android: {
  notification: {
    tag: 'activity_notifications',
    notificationCount: 5,
  },
}
```

---

## Related Documentation

- [News Feed Management API](./NEWS_FEED_MANAGEMENT_API.md) - Activity approval endpoints
- [Testing Guide](../TEST-NOW.md) - Step-by-step API testing instructions
- [PHP Reference](../../incard-biz/app/Jobs/SendActivityApprovedNotification.php) - Original Laravel implementation
- [Firebase Admin SDK Docs](https://firebase.google.com/docs/admin/setup) - Official Firebase documentation
- [Bull Queue Docs](https://docs.bullmq.io/) - Queue system documentation

---

## Quick Start Checklist

### Development Setup

- [ ] Install Redis: `brew install redis` / `apt install redis` / Download Windows build
- [ ] Start Redis: `redis-server`
- [ ] Copy Firebase credentials to project root
- [ ] Update `.env` with Firebase credentials path
- [ ] Update `.env` with Redis connection details
- [ ] Run migrations (if needed)
- [ ] Install dependencies: `npm install`
- [ ] Start application: `npm run start:dev`
- [ ] Run tests: `npm test -- --testPathPatterns=notifications`

### Testing Notifications

- [ ] Login as admin to get JWT token
- [ ] Create activity as super admin (status: Pending)
- [ ] Approve activity via API
- [ ] Check console logs for notification flow
- [ ] Verify notifications in database:
  ```sql
  SELECT COUNT(*) FROM notifications;
  SELECT id, email, notification_num FROM users WHERE device_token IS NOT NULL LIMIT 5;
  ```
- [ ] Check Redis queue (optional):
  ```bash
  redis-cli LLEN bull:notifications:completed
  ```

### Production Deployment

- [ ] Ensure Redis is running and accessible
- [ ] Verify Firebase credentials are in secure location
- [ ] Set production environment variables
- [ ] Configure Redis password for security
- [ ] Set up Bull Board for queue monitoring (optional)
- [ ] Configure log aggregation (Winston, Datadog, etc.)
- [ ] Set up alerting for failed jobs
- [ ] Test with staging environment first
- [ ] Monitor memory usage under load
- [ ] Implement rate limiting if needed

---

**Last Updated:** 2026-02-12
**Version:** 1.0.0
**Implementation Status:** ✅ Complete (Phases 1-5)
**Next Phase:** Contact Integration (Phase 6)

---

## Contact & Support

For questions or issues with the FCM notification system:
1. Check this documentation first
2. Review console logs with emoji markers (🚀 ✅ ❌ ⚠️ 📦 📲 💾)
3. Check [Troubleshooting](#troubleshooting) section
4. Review [Testing](#testing) section for validation steps
5. Check related PHP code for business logic reference

**Maintainer:** Development Team
**Last Review:** 2026-02-12
