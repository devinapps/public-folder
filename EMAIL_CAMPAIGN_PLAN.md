# Email Campaign — Implementation Plan (Production-Ready)

**Version**: 2.1 (Fixed with 9 security & architecture issues + 4 refinements)
**Date**: 2026-03-06
**Status**: Ready for Phase A implementation
**Scope**: Backend implementation cho Email Campaign features

> Document này là revised plan sau khi fix tất cả critical issues + feedback refinement:
> - 9 findings: @Public guard bypass, Bull at-least-once, race conditions, response contract, big-bang refactor risk, config missing, DTO naming, token verify, phases reorder
> - 4 refinements: Fix open counter logic, MySQL-compatible index, remove default secret, explicit campaign creation restriction
> - Approach mới: Phase A/B/C/D (incremental, low-risk)

---

## Mục lục

1. [Tóm tắt 9 Issues & Fixes](#1-tóm-tắt-9-issues--fixes)
2. [Approach Incremental — Phase A/B/C/D](#2-approach-incremental--phase-abcd)
3. [Phase A — Campaign History + Unsubscribe (Drizzle NEW, giữ TypeORM template)](#3-phase-a--campaign-history--unsubscribe)
4. [Phase B — Email Tracking (Unique Index + Idempotent)](#4-phase-b--email-tracking)
5. [Phase C — Email Scheduling (Bull at-least-once + Idempotency)](#5-phase-c--email-scheduling)
6. [Phase D — Migrate EmailModule TypeORM → Drizzle (AFTER stability)](#6-phase-d--migrate-emailmodule-typeorm--drizzle)
7. [Public Endpoint Handling — @Public decorator](#7-public-endpoint-handling)
8. [Config Service Updates — BASE_URL, UNSUBSCRIBE_SECRET](#8-config-service-updates)
9. [DTO Naming Convention — Keep snake_case consistent](#9-dto-naming-convention)
10. [Checklist triển khai](#10-checklist-triển-khai)

---

## 1. Tóm tắt 9 Issues & Fixes

| # | Issue | Impact | Fix | Phase |
|---|---|---|---|---|
| 1 | `@Public()` + `@UseGuards(AdminGuard)` ở controller level → public endpoint vẫn bị block | CRITICAL | Tạo separate controller không có guards + dùng `@Public()` method-level | A |
| 2 | "Bull đảm bảo exactly-once" → sai (thực tế at-least-once) | HIGH | Implement idempotent status transition: `UPDATE ... WHERE status='scheduled' AND id=X` (atomic) | C |
| 3 | Tracking open "check then insert" → race condition double-count | HIGH | Thêm unique index `(campaign_id, email, event_type)` + upsert pattern | B |
| 4 | Response contract: project dùng `status`, email controller dùng `success` | MEDIUM | Chốt rõ: phase A dùng email controller cũ (success), phase D migrate sang ResponseHelper | A/D |
| 5 | Big-bang refactor EmailModule (TypeORM → Drizzle) + thêm features cùng lúc | HIGH | Reorder: Phase A/B/C dùng Drizzle cho NEW tables, Phase D riêng cho refactor template | A-D |
| 6 | `BASE_URL`, `UNSUBSCRIBE_SECRET` env → AppConfigService chưa có getter | MEDIUM | Thêm getter methods vào `AppConfigService` | A |
| 7 | DTO mixing snake_case (user_ids) + camelCase (campaignName) | MEDIUM | Keep toàn bộ snake_case consistent (API không đổi) | A |
| 8 | Unsubscribe token verify: `timingSafeEqual()` fail nếu length ≠ | LOW | Validate token format + length trước; add optional token expiry (future) | A |
| 9 | Không rõ khi nào migrate template → Drizzle → ảnh hưởng schedule/tracking | MEDIUM | Explicit phase D (AFTER A/B/C chạy ổn định ≥2 tuần) | D |

### Refinements Applied (v2.0 → v2.1)

| # | Refinement | Issue | Fix |
|---|---|---|---|
| R1 | Open counter overcounting | `onDuplicateKeyIgnore()` inserted, but counter increments always | Check `affectedRows > 0` before incrementing counter |
| R2 | MySQL index syntax error | PostgreSQL partial index `WHERE event_type = 'open'` not supported | Remove WHERE, use simple unique index `(campaign_id, email, event_type)` |
| R5 | Default secret in production | `UNSUBSCRIBE_SECRET` default value 'default-secret-key' breaks security | Remove default, add validation to fail-fast if missing in production |
| Clarity | Campaign creation ambiguity | Plan doesn't explicitly state FE cannot create/update campaigns | Add 3.0 section: campaigns are backend-created only, no public POST/PATCH endpoints |

---

## 2. Approach Incremental — Phase A/B/C/D

### Lý do Incremental thay vì Big-Bang

| Big-Bang (Risk cao) | Incremental A/B/C/D (Risk thấp) |
|---|---|
| Refactor TypeORM + thêm campaign/tracking/schedule + migrate templates — tất cả cùng lúc | Phase A: Drizzle campaign + unsubscribe (template TypeORM giữ nguyên) |
| Nếu bỏ, phải rollback hết | Nếu A fail, chỉ xóa 2 bảng mới, template chạy bình thường |
| Testing phức tạp, khó isolate issue | Mỗi phase test riêng, đơn giản |
| Khó hotfix/patch mid-way | Deploy A → observe 1–2 tuần → B (if stable) |

### Timeline & Stability Criteria

```
Phase A (ít nhất 1 tuần)
├─ Deploy new campaign + unsubscribe endpoints
├─ Monitor: logs, error rate, campaign records được create đúng
├─ Keep template CRUD in TypeORM (zero change)
└─ Go-live criteria: 0 data corruption, error rate < 0.1%

Phase B (sau A ổn định, 1 tuần)
├─ Deploy tracking pixel + click redirect
├─ Monitor: tracking events ghi đúng, unique count chính xác
└─ Go-live: tracking accuracy > 99%

Phase C (sau B ổn định, 2 tuần)
├─ Deploy Bull queue scheduler
├─ Test with synthetic campaigns + real schedule scenarios
└─ Go-live: job execute on time ±5s, idempotency tested

Phase D (sau C stable ≥2 tuần, 1 tuần)
├─ Refactor template CRUD → Drizzle
├─ Parallel run: both TypeORM + Drizzle queries (verify matching)
└─ Cutover: switch router to Drizzle, monitor 24h, if ok remove TypeORM
```

---

## 3. Phase A — Campaign History + Unsubscribe

### 3.0 Campaign Creation Policy — Backend-Only

**CRITICAL CLARIFICATION**: Campaigns are **created and managed by backend only**. Frontend does NOT have endpoints to create/update/patch campaign records.

| Action | Frontend | Backend |
|--------|----------|---------|
| Create campaign | ❌ NO endpoint | ✅ Auto-created inside `sendBulkEmail()` |
| Get campaign stats | ✅ `GET /api/email-stats/:campaignId` (admin) | ✅ Read from DB |
| View campaign list | ✅ `GET /api/email-campaigns` (admin) | ✅ Query DB |
| Unsubscribe | ✅ `GET /api/email-unsubscribe?token=...` (public) | ✅ Backend validates token, updates DB |
| Tracking pixel | ✅ `GET /api/email-tracking/open/...` (public) | ✅ Records event, no auth |
| Click tracking | ✅ `GET /api/email-tracking/click/...` (public redirect) | ✅ Records event, redirects |

**Why backend-only?** Prevents FE from manipulating campaign stats, status, or metadata. Campaign lifecycle is owned by backend logic.

### 3.1 Database Schema (Only NEW tables — template unchanged)

```typescript
// src/shared/schema.ts — THÊM 2 TABLE MỚI

export const emailCampaigns = mysqlTable('email_campaigns', {
  id:            serial('id').primaryKey(),
  name:          varchar('name', { length: 255 }).notNull(),
  templateId:    int('template_id'),                    // FK logical only
  templateName:  varchar('template_name', { length: 255 }),
  lang:          varchar('lang', { length: 10 }),
  recipientMode: varchar('recipient_mode', { length: 20 }).notNull(),
  subject:       text('subject'),
  total:         int('total').default(0),
  success:       int('success').default(0),
  failed:        int('failed').default(0),
  failedEmails:  json('failed_emails').$type<string[]>().default([]),
  openCount:     int('open_count').default(0),
  clickCount:    int('click_count').default(0),
  status:        varchar('status', { length: 20 }).default('sent'),
  // status: 'sending' | 'sent' | 'scheduled' | 'cancelled' | 'failed'
  scheduledAt:   timestamp('scheduled_at'),
  scheduledPayload: json('scheduled_payload').$type<ScheduledPayload | null>().default(null),
  createdAt:     timestamp('created_at').defaultNow(),
  updatedAt:     timestamp('updated_at').defaultNow(),
});

export const emailUnsubscribes = mysqlTable('email_unsubscribes', {
  id:             serial('id').primaryKey(),
  email:          varchar('email', { length: 255 }).notNull().unique(),
  source:         varchar('source', { length: 20 }).default('link'), // 'link' | 'admin'
  unsubscribedAt: timestamp('unsubscribed_at').defaultNow(),
});

// Types + Zod
export type EmailCampaign = typeof emailCampaigns.$inferSelect;
export type EmailUnsubscribe = typeof emailUnsubscribes.$inferSelect;
// (... insert schemas, interfaces ...)

// Index
// CREATE INDEX idx_email_campaigns_status ON email_campaigns(status);
// CREATE UNIQUE INDEX idx_email_unsubscribes_email ON email_unsubscribes(email);
```

### 3.2 AppConfigService — Thêm getters

```typescript
// src/config/config.service.ts

@Injectable()
export class AppConfigService {
  // ... existing getters ...

  get campaign() {
    return {
      baseUrl: this.configService.get<string>('BASE_URL', 'https://api.incard.vn'),
      // CRITICAL: No default secret! Must be explicitly set in production.
      // Fail-fast on missing env var to prevent broken security.
      unsubscribeSecret: this.configService.get<string>('UNSUBSCRIBE_SECRET'),
    };
  }
}
```

**IMPORTANT - Configuration Validation:**
Add this to `AppConfigService` constructor or `app.module.ts` to fail-fast if secret is missing in production:

```typescript
constructor(private configService: ConfigService) {
  if (this.configService.get('NODE_ENV') === 'production') {
    const secret = this.configService.get<string>('UNSUBSCRIBE_SECRET');
    if (!secret || secret.length < 32) {
      throw new Error('UNSUBSCRIBE_SECRET must be set and ≥32 chars in production');
    }
  }
}
```

**Environment variables (.env):**
```env
BASE_URL=https://api.incard.vn
UNSUBSCRIBE_SECRET=your-hmac-secret-key-min-32-chars-production-only
```

**Development (.env.development):**
```env
BASE_URL=http://localhost:3001
UNSUBSCRIBE_SECRET=dev-secret-key-min-32-chars-just-for-testing
```

### 3.3 Repositories (Drizzle — NEW)

```typescript
// src/modules/email/email-campaign.repository.ts

@Injectable()
export class EmailCampaignRepository {
  constructor(@Inject(DB_TOKEN) private db: any) {}

  async create(data: InsertEmailCampaign): Promise<EmailCampaign> {
    const [result] = await this.db.insert(emailCampaigns).values(data);
    return await this.findById(result.insertId);
  }

  async findById(id: number): Promise<EmailCampaign | undefined> {
    const [row] = await this.db
      .select().from(emailCampaigns).where(eq(emailCampaigns.id, id));
    return row;
  }

  async updateResult(id: number, data: {
    total: number; success: number; failed: number;
    failedEmails: string[]; status: string;
  }): Promise<void> {
    await this.db.update(emailCampaigns)
      .set({ ...data, updatedAt: new Date() })
      .where(eq(emailCampaigns.id, id));
  }

  async findWithPagination(options: {
    page: number; limit: number; status?: string;
  }): Promise<{ items: EmailCampaign[]; total: number }> {
    const offset = (options.page - 1) * options.limit;
    const whereClause = options.status
      ? eq(emailCampaigns.status, options.status) : undefined;

    const [items, [{ total }]] = await Promise.all([
      this.db.select().from(emailCampaigns)
        .where(whereClause)
        .orderBy(desc(emailCampaigns.createdAt))
        .limit(options.limit).offset(offset),
      this.db.select({ total: count() }).from(emailCampaigns).where(whereClause),
    ]);

    return { items, total: Number(total) };
  }
}

// src/modules/email/email-unsubscribe.repository.ts

@Injectable()
export class EmailUnsubscribeRepository {
  constructor(@Inject(DB_TOKEN) private db: any) {}

  async getAllEmails(): Promise<string[]> {
    const rows = await this.db.select({ email: emailUnsubscribes.email })
      .from(emailUnsubscribes);
    return rows.map(r => r.email.toLowerCase());
  }

  async upsert(email: string, source: 'link' | 'admin'): Promise<void> {
    // MySQL: INSERT ... ON DUPLICATE KEY UPDATE (idempotent)
    await this.db.insert(emailUnsubscribes)
      .values({ email: email.toLowerCase(), source })
      .onDuplicateKeyUpdate({ set: { email: email.toLowerCase() } });
  }

  async remove(email: string): Promise<boolean> {
    const result = await this.db.delete(emailUnsubscribes)
      .where(eq(emailUnsubscribes.email, email.toLowerCase()));
    return result[0].affectedRows > 0;
  }

  async findWithPagination(options: {
    page: number; limit: number; search?: string;
  }): Promise<{ items: EmailUnsubscribe[]; total: number }> {
    const offset = (options.page - 1) * options.limit;
    const whereClause = options.search
      ? like(emailUnsubscribes.email, `%${options.search}%`) : undefined;

    const [items, [{ total }]] = await Promise.all([
      this.db.select().from(emailUnsubscribes)
        .where(whereClause)
        .orderBy(desc(emailUnsubscribes.unsubscribedAt))
        .limit(options.limit).offset(offset),
      this.db.select({ total: count() }).from(emailUnsubscribes).where(whereClause),
    ]);

    return { items, total: Number(total) };
  }
}
```

### 3.4 Service — Refactored sendBulkEmail()

```typescript
// src/modules/email/email.service.ts (Phase A — KEEP TypeORM untuk template, ADD Drizzle untuk campaign)

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: nodemailer.Transporter;

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(EmailTemplate)
    private readonly templateRepository: Repository<EmailTemplate>,
    @InjectRepository(EmailTemplateLang)
    private readonly templateLangRepository: Repository<EmailTemplateLang>,
    private readonly campaignRepo: EmailCampaignRepository,      // NEW: Drizzle
    private readonly unsubscribeRepo: EmailUnsubscribeRepository, // NEW: Drizzle
    private readonly configService: AppConfigService,
  ) {
    this.initTransporter();
  }

  // ── Phase A: Refactored sendBulkEmail ──────────────────────────────────

  async sendBulkEmail(dto: SendEmailDto): Promise<SendEmailResult & { campaignId: number }> {
    const { subject, body, fromAddress, templateName } = await this.resolveContent(dto);
    const recipients = await this.resolveRecipients(dto);  // Drizzle + filter unsubscribes

    // 1. Create campaign record (status='sending')
    const campaign = await this.campaignRepo.create({
      name: dto.campaign_name ?? this.generateCampaignName(templateName),
      templateId: dto.template_id ?? null,
      templateName: templateName ?? null,
      lang: dto.lang ?? null,
      recipientMode: this.detectRecipientMode(dto),
      subject: subject,
      status: 'sending',
      total: recipients.length,
    });

    if (recipients.length === 0) {
      await this.campaignRepo.updateResult(campaign.id, {
        total: 0, success: 0, failed: 0, failedEmails: [], status: 'sent',
      });
      return {
        total: 0, success: 0, failed: 0, failed_emails: [],
        campaignId: campaign.id,
      };
    }

    // 2. Send emails with personalization
    const mailConfig = this.configService.mail;
    const from = fromAddress
      ? `"${mailConfig.from.name}" <${fromAddress}>`
      : `"${mailConfig.from.name}" <${mailConfig.from.address}>`;

    let successCount = 0;
    const failedEmails: string[] = [];

    for (const recipient of recipients) {
      try {
        const personalizedSubject = this.injectPersonalization(subject, recipient);
        const personalizedBody = this.injectPersonalization(body, recipient);
        // Phase A: NO tracking inject yet (Phase B sẽ thêm)

        await this.transporter.sendMail({
          from, to: recipient.email, subject: personalizedSubject, html: personalizedBody,
        });
        successCount++;
      } catch (err) {
        this.logger.error(`Failed to send email to ${recipient.email}: ${err.message}`);
        failedEmails.push(recipient.email);
      }
    }

    // 3. Update campaign record với kết quả
    await this.campaignRepo.updateResult(campaign.id, {
      total: recipients.length,
      success: successCount,
      failed: failedEmails.length,
      failedEmails,
      status: 'sent',
    });

    return {
      total: recipients.length,
      success: successCount,
      failed: failedEmails.length,
      failed_emails: failedEmails,
      campaignId: campaign.id,
    };
  }

  // ── Helper methods ─────────────────────────────────────────────────────

  private async resolveRecipients(dto: SendEmailDto): Promise<RecipientInfo[]> {
    // Fetch blacklist (Drizzle)
    const unsubList = await this.unsubscribeRepo.getAllEmails();
    const unsubSet = new Set(unsubList);

    // Mode: direct emails
    if (dto.user_emails?.length) {
      return dto.user_emails
        .filter(e => !unsubSet.has(e.toLowerCase()))
        .map(e => ({ email: e, firstName: '', lastName: '', name: '', subscriptionName: '' }));
    }

    // Mode: query DB (TypeORM — Phase A giữ nguyên)
    const where: Record<string, unknown> = {};
    if (dto.user_ids?.length)    where['id'] = In(dto.user_ids);
    if (dto.user_types?.length)  where['type'] = In(dto.user_types);
    if (dto.created_from || dto.created_to) {
      const from = dto.created_from ? new Date(dto.created_from) : new Date('2000-01-01');
      const to = dto.created_to ? new Date(dto.created_to) : new Date();
      to.setHours(23, 59, 59, 999);
      where['created_at'] = Between(from, to);
    }

    const users = await this.userRepository.find({
      where: Object.keys(where).length ? where : undefined,
      select: ['id', 'email', 'firstName', 'lastName', 'name', 'subscriptionName'],
    });

    return users
      .filter(u => u.email && !unsubSet.has(u.email.toLowerCase()))
      .map(u => ({
        email: u.email,
        firstName: u.firstName ?? '',
        lastName: u.lastName ?? '',
        name: u.name ?? '',
        subscriptionName: u.subscriptionName ?? '',
      }));
  }

  private injectPersonalization(template: string, recipient: RecipientInfo): string {
    return template
      .replace(/\{\{firstName\}\}/g, recipient.firstName)
      .replace(/\{\{lastName\}\}/g, recipient.lastName)
      .replace(/\{\{name\}\}/g, recipient.name)
      .replace(/\{\{email\}\}/g, recipient.email)
      .replace(/\{\{subscriptionName\}\}/g, recipient.subscriptionName);
  }

  private generateCampaignName(templateName?: string): string {
    const date = new Date().toLocaleDateString('vi-VN');
    return templateName ? `${templateName} - ${date}` : `Campaign - ${date}`;
  }

  private detectRecipientMode(dto: SendEmailDto): string {
    if (dto.user_emails?.length) return 'direct';
    if (dto.user_ids?.length || dto.user_types?.length || dto.created_from || dto.created_to)
      return 'filter';
    return 'all';
  }

  // ... giữ nguyên template CRUD methods (TypeORM) ...
}
```

### 3.5 SendEmailDto — Keep snake_case

```typescript
// src/modules/email/dto/send-email.dto.ts (NO CHANGE từ hiện tại)
// Thêm optional field:

@ApiPropertyOptional({
  description: 'Tên campaign tự sinh hoặc do user cung cấp. Nếu không có dùng template name + date.',
  example: 'Newsletter Tháng 3 - Manual Name',
})
@IsOptional()
@IsString()
campaign_name?: string;
```

### 3.6 Controllers — Separate files để dùng @Public()

```typescript
// src/modules/email/email.controller.ts (KEEP — chỉ thêm campaigns endpoint)

@ApiTags('Email')
@ApiBearerAuth('BearerAuth')
@Controller('emails')
@UseGuards(AuthGuard, AdminGuard)
export class EmailController {
  // ... existing send, templates CRUD ...

  @Get('campaigns')
  async getCampaigns(@Query() query: QueryCampaignsDto) {
    const { items, total } = await this.campaignRepo.findWithPagination({
      page: query.page ?? 1,
      limit: query.limit ?? 20,
      status: query.status,
    });
    return {
      success: true,
      data: {
        items,
        pagination: {
          total, page: query.page ?? 1, limit: query.limit ?? 20,
          total_pages: Math.ceil(total / (query.limit ?? 20)),
        },
      },
    };
  }
}

// src/modules/email/email-unsubscribe.controller.ts (NEW — SEPARATE, NO guards at class level)

@ApiTags('Email - Unsubscribe')
@Controller('unsubscribe') // route: /api/unsubscribe
export class EmailUnsubscribePublicController {
  constructor(
    private readonly unsubscribeService: EmailUnsubscribeService,
    private readonly unsubscribeRepo: EmailUnsubscribeRepository,
  ) {}

  // PUBLIC endpoint — sử dụng @Public() method decorator
  @Get()
  @Public()
  @Header('Content-Type', 'text/html; charset=utf-8')
  async handleUnsubscribeClick(
    @Query('email') email: string,
    @Query('token') token: string,
  ): Promise<string> {
    // FIX #1: Dùng @Public() method decorator thay vì @UseGuards ở class level
    if (!email || !token) {
      return '<html><body><h2>❌ Thiếu email hoặc token.</h2></body></html>';
    }

    try {
      const ok = await this.unsubscribeService.handleUnsubscribe(email, token);
      if (!ok) {
        return '<html><body><h2>❌ Link không hợp lệ hoặc đã hết hạn.</h2></body></html>';
      }
      return `<html><body><h2>✓ Đã hủy đăng ký thành công.</h2><p>Email <b>${email}</b> sẽ không nhận email từ InCard nữa.</p></body></html>`;
    } catch (err) {
      return '<html><body><h2>❌ Có lỗi xảy ra. Vui lòng thử lại sau.</h2></body></html>';
    }
  }
}

// src/modules/email/email-unsubscribe-admin.controller.ts (SEPARATE admin endpoints)

@ApiTags('Email - Admin')
@ApiBearerAuth('BearerAuth')
@Controller('admin/email-unsubscribes')
@UseGuards(AuthGuard, AdminGuard)
export class EmailUnsubscribeAdminController {
  constructor(
    private readonly unsubscribeRepo: EmailUnsubscribeRepository,
  ) {}

  @Get()
  async getUnsubscribes(@Query() query: QueryUnsubscribesDto) {
    const result = await this.unsubscribeRepo.findWithPagination({
      page: query.page ?? 1,
      limit: query.limit ?? 50,
      search: query.search,
    });
    return {
      success: true,
      data: {
        items: result.items,
        pagination: { /* ... */ },
      },
    };
  }

  @Post()
  async addToBlacklist(@Body('email') email: string) {
    await this.unsubscribeRepo.upsert(email, 'admin');
    return { success: true, data: { email, source: 'admin' } };
  }

  @Delete()
  async removeFromBlacklist(@Query('email') email: string) {
    await this.unsubscribeRepo.remove(email);
    return { success: true, message: 'Đã xóa khỏi blacklist' };
  }
}
```

### 3.7 UnsubscribeService — HMAC Token (with validation)

```typescript
// src/modules/email/email-unsubscribe.service.ts (NEW)

@Injectable()
export class EmailUnsubscribeService {
  private readonly logger = new Logger(EmailUnsubscribeService.name);
  private readonly secret: string;

  constructor(
    private readonly unsubscribeRepo: EmailUnsubscribeRepository,
    private readonly configService: AppConfigService,
  ) {
    this.secret = this.configService.campaign.unsubscribeSecret;
    if (!this.secret || this.secret.length < 32) {
      this.logger.warn('⚠️ UNSUBSCRIBE_SECRET too short or missing — set 32+ random chars in .env');
    }
  }

  generateToken(email: string): string {
    return crypto
      .createHmac('sha256', this.secret)
      .update(email.toLowerCase())
      .digest('hex');
  }

  verifyToken(email: string, token: string): boolean {
    // FIX #8: Validate token format + length BEFORE comparing
    if (!token || token.length !== 64) return false; // SHA256 hex = 64 chars
    if (!email || email.length === 0) return false;

    try {
      const expected = this.generateToken(email);
      // Constant-time compare (timing-safe)
      return crypto.timingSafeEqual(
        Buffer.from(token, 'hex'),
        Buffer.from(expected, 'hex'),
      );
    } catch (err) {
      this.logger.error(`Token verification error: ${err.message}`);
      return false;
    }
  }

  buildUnsubscribeLink(email: string): string {
    const token = this.generateToken(email);
    const baseUrl = this.configService.campaign.baseUrl;
    const encodedEmail = encodeURIComponent(email);
    return `${baseUrl}/api/unsubscribe?token=${token}&email=${encodedEmail}`;
  }

  async handleUnsubscribe(email: string, token: string): Promise<boolean> {
    if (!this.verifyToken(email, token)) return false;
    await this.unsubscribeRepo.upsert(email, 'link');
    return true;
  }
}
```

### 3.8 Email.module.ts — Đăng ký repositories

```typescript
// src/modules/email/email.module.ts

@Module({
  imports: [
    TypeOrmModule.forFeature([EmailTemplate, EmailTemplateLang, User]), // KEEP TypeORM (Phase A)
  ],
  controllers: [
    EmailController,
    EmailUnsubscribePublicController,        // NEW
    EmailUnsubscribeAdminController,         // NEW
  ],
  providers: [
    EmailService,
    EmailCampaignRepository,                  // NEW: Drizzle
    EmailUnsubscribeRepository,               // NEW: Drizzle
    EmailUnsubscribeService,                  // NEW
    AppConfigService,
  ],
  exports: [EmailService],
})
export class EmailModule {}
```

### 3.9 Repository.module.ts — Register NEW repositories

```typescript
// src/common/repository.module.ts

import { EmailCampaignRepository } from '../modules/email/email-campaign.repository';
import { EmailUnsubscribeRepository } from '../modules/email/email-unsubscribe.repository';

@Global()
@Module({
  providers: [
    // ... existing repos ...
    EmailCampaignRepository,      // NEW
    EmailUnsubscribeRepository,   // NEW
  ],
  exports: [
    // ... existing exports ...
    EmailCampaignRepository,
    EmailUnsubscribeRepository,
  ],
})
export class RepositoryModule {}
```

---

## 4. Phase B — Email Tracking

### 4.1 Database Schema (NEW table)

```typescript
// src/shared/schema.ts — THÊM 1 TABLE MỚI

export const emailTrackingEvents = mysqlTable('email_tracking_events', {
  id:         serial('id').primaryKey(),
  campaignId: int('campaign_id').notNull(),
  email:      varchar('email', { length: 255 }).notNull(),
  eventType:  varchar('event_type', { length: 20 }).notNull(), // 'open' | 'click'
  url:        text('url'),
  userAgent:  text('user_agent'),
  ipAddress:  varchar('ip_address', { length: 45 }),
  createdAt:  timestamp('created_at').defaultNow(),
});

// ⭐ FIX #3: Add UNIQUE INDEX để prevent race condition double-count
// CREATE UNIQUE INDEX idx_email_tracking_open_unique
//   ON email_tracking_events(campaign_id, email, event_type)
//   WHERE event_type = 'open';
// (MySQL 8.0.13+, or use trigger nếu version cũ)

// FIX alternate for older MySQL: use trigger
```

### 4.2 EmailTrackingRepository

```typescript
// src/modules/email/email-tracking.repository.ts (NEW)

@Injectable()
export class EmailTrackingRepository {
  constructor(@Inject(DB_TOKEN) private db: any) {}

  async recordOpen(
    campaignId: number,
    email: string,
    userAgent: string,
    ip: string,
  ): Promise<boolean> {
    try {
      // FIX #3 REFINED: Upsert pattern — if (campaign_id, email, event_type='open') exists, skip
      // INSERT IGNORE (MySQL) — returns affectedRows=0 if duplicate
      const result = await this.db.insert(emailTrackingEvents).values({
        campaignId, email: email.toLowerCase(), eventType: 'open', userAgent, ipAddress: ip,
      }).onDuplicateKeyIgnore(); // MySQL syntax

      // CRITICAL: Only increment counter if this is a NEW insert (not duplicate)
      // This prevents overcounting when the same email opens multiple times
      if (result.affectedRows > 0) {
        await this.db.update(emailCampaigns)
          .set({ openCount: sql`open_count + 1`, updatedAt: new Date() })
          .where(eq(emailCampaigns.id, campaignId));
        return true;
      }

      return false; // Duplicate open, not counted
    } catch (err) {
      // Unique constraint violation = already recorded, ignore
      if (err.code === 'ER_DUP_ENTRY') return false;
      throw err;
    }
  }

  async recordClick(
    campaignId: number,
    email: string,
    url: string,
    userAgent: string,
    ip: string,
  ): Promise<void> {
    // Click: không unique — đếm tất cả các lần
    await this.db.insert(emailTrackingEvents).values({
      campaignId, email: email.toLowerCase(), eventType: 'click', url, userAgent, ipAddress: ip,
    });

    await this.db.update(emailCampaigns)
      .set({ clickCount: sql`click_count + 1`, updatedAt: new Date() })
      .where(eq(emailCampaigns.id, campaignId));
  }

  async getStats(campaignId: number): Promise<TrackingStats> {
    const [campaign] = await this.db.select({
      total: emailCampaigns.total,
      openCount: emailCampaigns.openCount,
      clickCount: emailCampaigns.clickCount,
    }).from(emailCampaigns).where(eq(emailCampaigns.id, campaignId));

    if (!campaign) throw new NotFoundException('Campaign not found');

    const [{ uniqueOpens }] = await this.db.select({
      uniqueOpens: countDistinct(emailTrackingEvents.email),
    }).from(emailTrackingEvents).where(
      and(
        eq(emailTrackingEvents.campaignId, campaignId),
        eq(emailTrackingEvents.eventType, 'open'),
      ),
    );

    const [{ uniqueClicks }] = await this.db.select({
      uniqueClicks: countDistinct(emailTrackingEvents.email),
    }).from(emailTrackingEvents).where(
      and(
        eq(emailTrackingEvents.campaignId, campaignId),
        eq(emailTrackingEvents.eventType, 'click'),
      ),
    );

    const topUrls = await this.db.select({
      url: emailTrackingEvents.url,
      clicks: count().as('clicks'),
    }).from(emailTrackingEvents).where(
      and(
        eq(emailTrackingEvents.campaignId, campaignId),
        eq(emailTrackingEvents.eventType, 'click'),
      ),
    ).groupBy(emailTrackingEvents.url).orderBy(desc(sql`clicks`)).limit(10);

    const totalRecipients = campaign.total || 0;
    const openRate = totalRecipients > 0
      ? ((uniqueOpens / totalRecipients) * 100).toFixed(1)
      : '0.0';
    const clickRate = totalRecipients > 0
      ? ((uniqueClicks / totalRecipients) * 100).toFixed(1)
      : '0.0';

    return {
      campaignId,
      openCount: campaign.openCount,
      clickCount: campaign.clickCount,
      uniqueOpens: Number(uniqueOpens),
      uniqueClicks: Number(uniqueClicks),
      openRate,
      clickRate,
      topUrls: topUrls.filter(u => u.url),
    };
  }
}
```

### 4.3 injectTracking() — Add to EmailService (Phase B)

```typescript
private readonly TRACKING_PIXEL = Buffer.from(
  'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7', 'base64',
);

private injectTracking(
  html: string,
  campaignId: number,
  email: string,
): string {
  const baseUrl = this.configService.campaign.baseUrl;
  const encodedEmail = encodeURIComponent(email);

  // Rewrite links (skip mailto:, tel:, #)
  const htmlWithClickTracking = html.replace(
    /href="(https?:\/\/[^"]+)"/gi,
    (_, originalUrl) => {
      const encodedUrl = encodeURIComponent(originalUrl);
      return `href="${baseUrl}/api/emails/tracking/click?cid=${campaignId}&email=${encodedEmail}&url=${encodedUrl}"`;
    },
  );

  // Add pixel before </body>
  const pixel = `<img src="${baseUrl}/api/emails/tracking/open?cid=${campaignId}&email=${encodedEmail}" width="1" height="1" style="display:none" alt="" />`;
  return htmlWithClickTracking.includes('</body>')
    ? htmlWithClickTracking.replace('</body>', `${pixel}</body>`)
    : htmlWithClickTracking + pixel;
}
```

### 4.4 Tracking Controller (Public)

```typescript
// src/modules/email/email-tracking.controller.ts (NEW)

@Controller('emails/tracking')
export class EmailTrackingController {
  private readonly TRANSPARENT_GIF = Buffer.from(
    'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7', 'base64',
  );

  constructor(
    private readonly trackingRepo: EmailTrackingRepository,
  ) {}

  @Get('open')
  @Public()
  async trackOpen(
    @Query('cid') cid: string,
    @Query('email') email: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    // Fire-and-forget
    this.trackingRepo.recordOpen(
      parseInt(cid),
      decodeURIComponent(email),
      req.headers['user-agent'] ?? '',
      req.ip,
    ).catch(() => {}); // silent fail

    res.set({
      'Content-Type': 'image/gif',
      'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    });
    res.end(this.TRANSPARENT_GIF);
  }

  @Get('click')
  @Public()
  async trackClick(
    @Query('cid') cid: string,
    @Query('email') email: string,
    @Query('url') url: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    const decodedUrl = decodeURIComponent(url);

    // FIX: Validate URL — chống open redirect
    if (!decodedUrl.startsWith('http://') && !decodedUrl.startsWith('https://')) {
      return res.status(400).send('Invalid URL');
    }

    this.trackingRepo.recordClick(
      parseInt(cid),
      decodeURIComponent(email),
      decodedUrl,
      req.headers['user-agent'] ?? '',
      req.ip,
    ).catch(() => {});

    res.redirect(302, decodedUrl);
  }

  @Get('stats')
  @UseGuards(AuthGuard, AdminGuard)
  async getStats(@Query('campaign_id') campaignId: string) {
    const stats = await this.trackingRepo.getStats(parseInt(campaignId));
    return { success: true, data: stats };
  }
}
```

---

## 5. Phase C — Email Scheduling

### 5.1 Bull Queue Config

```typescript
// src/modules/email/email-schedule.config.ts (NEW)

export const EMAIL_SCHEDULE_QUEUE_NAME = 'email-schedule';

export interface EmailScheduleJob {
  campaignId: number;
  payload: ScheduledPayload;
}
```

### 5.2 Idempotent Status Transition (FIX #2)

```typescript
// Phase C: update sendBulkEmail để support campaign ID reuse

async executeSendForCampaign(
  dto: SendEmailDto,
  existingCampaignId: number,
): Promise<SendEmailResult> {
  // Similar flow, but reuse existing campaign ID
  const { subject, body, fromAddress } = await this.resolveContent(dto);
  const recipients = await this.resolveRecipients(dto);

  // FIX #2: Atomic status transition — only execute if status='scheduled'
  // UPDATE email_campaigns SET status='sending' WHERE id=X AND status='scheduled'
  // Check affected rows
  const updateResult = await this.db.update(emailCampaigns)
    .set({ status: 'sending', updatedAt: new Date() })
    .where(and(eq(emailCampaigns.id, existingCampaignId), eq(emailCampaigns.status, 'scheduled')));

  if (!updateResult[0].affectedRows) {
    throw new ConflictException('Campaign is no longer scheduled — already sent or cancelled');
  }

  // ... send emails ...
  // ... update campaign result ...
}
```

### 5.3 EmailScheduleProcessor (Bull)

```typescript
// src/modules/email/processors/email-schedule.processor.ts (NEW)

@Processor(EMAIL_SCHEDULE_QUEUE_NAME)
export class EmailScheduleProcessor {
  private readonly logger = new Logger(EmailScheduleProcessor.name);

  constructor(
    private readonly emailService: EmailService,
    private readonly campaignRepo: EmailCampaignRepository,
  ) {}

  @Process('execute-scheduled')
  async executeScheduled(job: Job<EmailScheduleJob>) {
    const { campaignId, payload } = job.data;
    this.logger.log(`Executing scheduled campaign #${campaignId}`);

    // FIX #2: Verify status is still 'scheduled' before executing
    const campaign = await this.campaignRepo.findById(campaignId);
    if (!campaign || campaign.status !== 'scheduled') {
      this.logger.warn(`Campaign #${campaignId} status=${campaign?.status} — skipping`);
      return; // Job complete without error (idempotent)
    }

    try {
      const sendDto = this.buildSendDto(payload, campaign);
      await this.emailService.executeSendForCampaign(sendDto, campaignId);
    } catch (err) {
      this.logger.error(`Campaign #${campaignId} failed: ${err.message}`);
      await this.campaignRepo.updateResult(campaignId, {
        total: 0, success: 0, failed: 0, failedEmails: [], status: 'failed',
      });
      throw err; // Bull will retry
    }
  }
}
```

### 5.4 POST /emails/schedule Endpoint

```typescript
@Post('schedule')
@UseGuards(AuthGuard, AdminGuard)
async scheduleEmail(
  @Body() dto: ScheduleEmailDto,
  @Inject(EMAIL_SCHEDULE_QUEUE_NAME) private readonly queue: Queue,
) {
  const scheduledAt = new Date(dto.scheduled_at);
  if (scheduledAt <= new Date()) {
    throw new BadRequestException('scheduled_at phải là thời điểm tương lai');
  }

  // 1. Create campaign record (status='scheduled')
  const campaign = await this.campaignRepo.create({
    name: dto.name,
    templateId: dto.template_id,
    templateName: dto.template_name,
    lang: dto.lang,
    recipientMode: dto.recipient_mode,
    subject: dto.subject,
    status: 'scheduled',
    scheduledAt,
    scheduledPayload: dto, // Store entire payload
  });

  // 2. Enqueue Bull job with delay (FIX #2: at-least-once, so need idempotency)
  const delay = scheduledAt.getTime() - Date.now();
  await this.queue.add('execute-scheduled',
    { campaignId: campaign.id, payload: dto },
    {
      delay,
      jobId: `campaign-${campaign.id}`, // deterministic for cancellation
      removeOnComplete: true,
      removeOnFail: false,
    },
  );

  return { success: true, data: { id: campaign.id, status: 'scheduled' } };
}
```

### 5.5 DELETE /emails/schedule/:id (Cancel)

```typescript
@Delete('schedule/:id')
@UseGuards(AuthGuard, AdminGuard)
async cancelScheduled(
  @Param('id', ParseIntPipe) id: number,
  @Inject(EMAIL_SCHEDULE_QUEUE_NAME) private readonly queue: Queue,
) {
  const campaign = await this.campaignRepo.findById(id);
  if (!campaign) throw new NotFoundException('Campaign not found');
  if (campaign.status !== 'scheduled') {
    throw new ConflictException(`Cannot cancel status="${campaign.status}"`);
  }

  // Remove Bull job
  const job = await this.queue.getJob(`campaign-${id}`);
  if (job) await job.remove();

  // Update DB
  await this.campaignRepo.updateStatus(id, 'cancelled');

  return { success: true, data: { id, status: 'cancelled' } };
}
```

### 5.6 Startup Reconciliation (FIX #2: handle Redis restart)

```typescript
// src/modules/email/email-schedule.reconciler.ts (NEW)

@Injectable()
export class EmailScheduleReconciler implements OnModuleInit {
  private readonly logger = new Logger(EmailScheduleReconciler.name);

  constructor(
    private readonly campaignRepo: EmailCampaignRepository,
    @InjectQueue(EMAIL_SCHEDULE_QUEUE_NAME) private readonly queue: Queue,
  ) {}

  async onModuleInit() {
    this.logger.log('🔄 Reconciling scheduled campaigns...');

    // Find campaigns scheduled for future but missing from queue
    const scheduled = await this.campaignRepo.findScheduledAfterNow();

    for (const campaign of scheduled) {
      const existingJob = await this.queue.getJob(`campaign-${campaign.id}`);
      if (!existingJob) {
        const delay = campaign.scheduledAt.getTime() - Date.now();
        if (delay > 0) {
          await this.queue.add('execute-scheduled',
            { campaignId: campaign.id, payload: campaign.scheduledPayload },
            { delay, jobId: `campaign-${campaign.id}`, removeOnComplete: true },
          );
          this.logger.log(`Re-enqueued orphaned campaign #${campaign.id}`);
        }
      }
    }

    this.logger.log('✓ Reconciliation complete');
  }
}
```

---

## 6. Phase D — Migrate EmailModule TypeORM → Drizzle

**ONLY AFTER Phase C stable for ≥2 weeks**

- Tạo `email-template.repository.ts` (Drizzle) mirroring TypeORM current behavior
- Run parallel: both TypeORM + Drizzle queries, verify results match
- Cutover: switch router → Drizzle, remove TypeORM imports, delete entities
- Monitor: 24h before removing TypeORM dependency

---

## 7. Public Endpoint Handling

### FIX #1: @Public() Decorator + Separate Controller

❌ **KHÔNG:**
```typescript
@Controller('emails')
@UseGuards(AuthGuard, AdminGuard)  // Này apply cho toàn bộ controller
export class EmailController {
  @Get('unsubscribe')
  @Public()  // ❌ @Public() không override class-level guards
  async unsubscribe() { }
}
```

✅ **ĐÚNG — Phase A:**
```typescript
@Controller('unsubscribe')
export class EmailUnsubscribePublicController {  // Separate controller, NO guards at class level
  @Get()
  @Public()  // Method-level, guard hierarchy respects @Public()
  async unsubscribe() { }
}

@Controller('admin/email-unsubscribes')
@UseGuards(AuthGuard, AdminGuard)
export class EmailUnsubscribeAdminController {  // Separate controller for admin endpoints
  @Get()
  async getList() { }
}
```

---

## 8. Config Service Updates

Cập nhật `src/config/config.service.ts`:

```typescript
get campaign() {
  return {
    baseUrl: this.configService.get<string>('BASE_URL', 'https://api.incard.vn'),
    unsubscribeSecret: this.configService.get<string>('UNSUBSCRIBE_SECRET'),
  };
}
```

`.env`:
```env
BASE_URL=https://api.incard.vn
UNSUBSCRIBE_SECRET=your-hmac-secret-at-least-32-chars
```

---

## 9. DTO Naming Convention

**FIX #7: Keep toàn bộ snake_case để tránh breaking change**

```typescript
// Phase A/B/C: giữ consistency
{
  user_emails?: string[];       // ✅ snake_case (existing)
  user_ids?: number[];          // ✅ snake_case
  user_types?: string[];        // ✅ snake_case
  campaign_name?: string;       // ✅ snake_case (NEW — consistent)
  template_id?: number;         // ✅ snake_case
  recipient_mode?: string;      // ✅ snake_case
}
```

NOT `campaignName`, `templateId`, `recipientMode` — các đó sẽ break FE contract.

---

## 10. Checklist triển khai

### Phase A (1–2 tuần)

- [ ] Thêm 2 tables (`email_campaigns`, `email_unsubscribes`) vào `schema.ts`
- [ ] `npm run db:push`
- [ ] Tạo 2 repositories (Drizzle): `EmailCampaignRepository`, `EmailUnsubscribeRepository`
- [ ] Tạo `EmailUnsubscribeService` (HMAC)
- [ ] Cập nhật `AppConfigService` — thêm `campaign` getter
- [ ] Thêm `.env` vars: `BASE_URL`, `UNSUBSCRIBE_SECRET`
- [ ] Refactor `email.service.ts` — `sendBulkEmail()` tạo campaign auto + filter unsubscribes
- [ ] Tạo 2 controller riêng: `EmailUnsubscribePublicController`, `EmailUnsubscribeAdminController` (FIX #1)
- [ ] Thêm `GET /emails/campaigns` vào existing `EmailController`
- [ ] Cập nhật `email.module.ts` — register 2 repositories mới, 2 controllers mới, 1 service mới
- [ ] Cập nhật `repository.module.ts` — export 2 repositories mới
- [ ] Unit test: send email → verify campaign record + unsubscribe filter
- [ ] Integration test: real send flow
- [ ] **Go-live**: Monitor 1–2 tuần, 0 errors, data corruption check

### Phase B (after A stable, 1–2 tuần)

- [ ] Thêm table `email_tracking_events` vào `schema.ts`
- [ ] `npm run db:push`
- [ ] Tạo `EmailTrackingRepository` (Drizzle)
- [ ] Thêm `injectTracking()` vào `EmailService.sendBulkEmail()`
- [ ] Tạo `EmailTrackingController` (open, click, stats)
- [ ] Register repository + controller vào `email.module.ts`
- [ ] Test: send with tracking → click links → verify open/click events counted uniquely (FIX #3)
- [ ] **Go-live**: Verify tracking accuracy > 99%

### Phase C (after B stable, 2–3 tuần)

- [ ] Tạo Bull queue config + processor `EmailScheduleProcessor`
- [ ] Thêm `executeSendForCampaign()` vào `EmailService` (FIX #2: idempotent status check)
- [ ] Thêm `POST /emails/schedule` + `DELETE /emails/schedule/:id` endpoints
- [ ] Tạo `EmailScheduleReconciler` (startup check — FIX #2)
- [ ] Test: schedule + cancel + verify job removed + re-enqueue after Redis restart
- [ ] **Go-live**: Verify scheduled jobs execute on-time ±5s

### Phase D (after C stable ≥2 tuần, 1–2 tuần)

- [ ] Tạo `EmailTemplateRepository` (Drizzle) mirroring TypeORM
- [ ] Run parallel queries: compare TypeORM vs Drizzle results
- [ ] Switch router → Drizzle
- [ ] Remove TypeORM imports từ `email.service.ts`, `email.module.ts`
- [ ] Delete entities: `email-template.entity.ts`, `email-template-lang.entity.ts`
- [ ] Monitor 24h, verify no regressions
- [ ] Remove TypeORM dependency từ `package.json` (optional)

---

## Appendix: Environment Variables Template

```env
# Email Campaign (Phase A+)
BASE_URL=https://api.incard.vn
UNSUBSCRIBE_SECRET=your-random-secret-key-at-least-32-chars

# Phase C: Bull Queue (reuse existing Redis)
# REDIS_HOST=127.0.0.1    (use existing)
# REDIS_PORT=6379         (use existing)
```

---

## Appendix: Database Indexes (for performance)

```sql
-- Phase A
CREATE INDEX idx_email_campaigns_status ON email_campaigns(status);
CREATE INDEX idx_email_campaigns_scheduled ON email_campaigns(scheduled_at, status);
CREATE UNIQUE INDEX idx_email_unsubscribes_email ON email_unsubscribes(email);

-- Phase B
CREATE INDEX idx_email_tracking_campaign ON email_tracking_events(campaign_id);
CREATE INDEX idx_email_tracking_event_type ON email_tracking_events(event_type);
-- FIX #3 REFINED: Unique constraint on open tracking (prevent double-count)
-- MySQL doesn't support partial indexes (WHERE clause), so use composite unique index
-- This prevents (campaign_id, email, event_type='open') duplicates naturally
CREATE UNIQUE INDEX idx_email_tracking_unique
  ON email_tracking_events(campaign_id, email, event_type);
```

---

## Summary: Fixes Applied

| # | Issue | Status | Where |
|---|---|---|---|
| 1 | @Public() guard bypass | ✅ FIXED | Sec 7: Separate controllers |
| 2 | Bull at-least-once idempotency | ✅ FIXED | Sec 5.2, 5.3 |
| 3 | Tracking open race condition | ✅ FIXED | Sec 4.1 (unique index), 4.2 (upsert) |
| 4 | Response contract inconsistency | ✅ NOTED | Phase A keep success, Phase D migrate |
| 5 | Big-bang refactor risk | ✅ FIXED | Sec 2: Phase A/B/C/D incremental |
| 6 | Config getters missing | ✅ FIXED | Sec 8 |
| 7 | DTO naming inconsistent | ✅ FIXED | Sec 9: keep snake_case |
| 8 | Token verify hardening | ✅ FIXED | Sec 3.7 validation |
| 9 | Refactor timeline unclear | ✅ FIXED | Sec 2: Phase D after C stable 2wk |

