# PHP InCard-Biz - Create User Logic Documentation

**Project:** incard-biz (Laravel PHP)
**Focus:** Complete analysis of user registration/creation flow
**Date:** 2026-02-09
**Purpose:** Comprehensive understanding of all business logic related to creating users

---

## Table of Contents

1. [Overview](#overview)
2. [Database Schema](#database-schema)
3. [User Registration Flow](#user-registration-flow)
4. [Referral System](#referral-system)
5. [QR Code Serial System](#qr-code-serial-system)
6. [Business History Tracking](#business-history-tracking)
7. [Partner & Subscription Logic](#partner--subscription-logic)
8. [Group/Admin User Creation](#groupadmin-user-creation)
9. [Email Notifications](#email-notifications)
10. [Post-Registration Actions](#post-registration-actions)
11. [Observer Auto-Actions](#observer-auto-actions)
12. [Related Models & Relationships](#related-models--relationships)

---

## Overview

### Entry Points

**Web Registration:**
- Route: `GET /ref/{code}` → `HomeController::registerReferral()`
- Route: `POST /ref` → `HomeController::registerReferralStore()`

**API Registration:**
- Route: `POST /api/register` → `API\UserController::register()`
- Route: `POST /api/registerV2` → `API\UserController::registerV2()`

**Key Files:**
- `app/Http/Controllers/API/UserController.php` (Lines 253-423)
- `app/Http/Controllers/HomeController.php`
- `app/Observers/UserObserver.php`
- `app/Models/User.php`

---

## Database Schema

### Users Table

**Referral Fields:**
```php
'referral_code'     => string(6) nullable    // Mã referral của user này (auto-generated)
'referral_user_id'  => bigInteger nullable   // ID của user đã giới thiệu (parent referrer)
```

**QR Code Fields:**
```php
'qrcode_serial'     => string nullable       // Serial number của physical QR card
```

**Group/Admin Fields:**
```php
'admin_group_id'    => bigInteger nullable   // ID của admin quản lý (nếu là member)
'created_by'        => bigInteger nullable   // ID của user tạo account này
```

**Partner/Subscription Fields:**
```php
'is_from_partner'                => boolean default(0)
'is_partner_trial'               => boolean default(0)
'partner_trial_expired_date'     => date nullable
'partner_subscription_deadline'  => date nullable
'chat_credit'                    => integer default(0)
'renew_recommend_limit'          => integer default(0)
```

**Basic Fields:**
```php
'name'              => string
'email'             => string unique
'phone'             => string nullable
'password'          => string (hashed)
'type'              => enum('company', 'admin', 'super admin') default('company')
'lang'              => string default('vi')
'birthday'          => date nullable
'device_info'       => text nullable
'device_token'      => string nullable
```

---

### QrcodeGenerated Table

**Purpose:** Track physical QR code cards (pre-printed)

```php
'id'            => bigInteger primary key
'code'          => string(30)           // Serial code (unique)
'business_id'   => bigInteger nullable  // Business card linked (optional)
'user_id'       => bigInteger nullable  // User assigned (when registered)
'group_id'      => bigInteger nullable  // Group for bulk management
'status'        => string nullable      // Active/Inactive status
'note'          => text nullable        // Admin notes
'created_at'    => timestamp
'updated_at'    => timestamp
```

**Lifecycle:**
1. **Pre-generation** - Admin bulk imports codes via `SerialManagementController`
2. **Assignment** - User registers with `qrcode_serial` → link `user_id`
3. **Linking** - Optionally link to specific `business_id` (business card)

---

### BusinessHistory Table

**Purpose:** Track all activities related to business cards

```php
'id'            => bigInteger primary key
'business_id'   => bigInteger          // Business card ID
'type'          => string(10)          // Activity type: 'view', 'scan', 'referral'
'ip'            => string(30)          // Visitor IP address
'url'           => string(200)         // Original URL/slug
'created_at'    => timestamp
'updated_at'    => timestamp
```

**Type Values:**
- `'view'` - Someone viewed this business card profile
- `'scan'` - Someone scanned QR code of this card
- `'referral'` - Someone registered using this user's referral link

---

### Business Table

**Purpose:** Business cards/profiles (users can have multiple)

```php
'id'            => bigInteger primary key
'created_by'    => bigInteger          // User who created this card
'owner_id'      => bigInteger nullable // Primary owner
'owner_ids'     => json nullable       // Co-owners array
'title'         => string              // First name
'last_name'     => string              // Last name
'sub_title'     => string              // Company/Position
'slug'          => string unique       // URL-friendly identifier
// ... many more fields for contact info, social links, etc.
```

**Relationship with User:**
```php
// In User.php
public function business() {
    return $this->hasMany(Business::class, 'created_by');
}
```

---

## User Registration Flow

### API\UserController::register() - Full Flow

**File:** `app/Http/Controllers/API/UserController.php` (Lines 253-423)

#### Step 1: Input Processing

```php
$name = $request->first_name . ' ' . $request->last_name;
$email = $request->email;
$phone = $request->phone;
$group = $request->group;
$qrcode_serial = $request->qrcode_serial;
$referral_code = $request->referral_code;
$device_info = $request->device_info;
```

**Input Fields:**
- `first_name` (string) - Họ
- `last_name` (string) - Tên
- `email` (string, required) - Email address
- `phone` (string, optional) - Phone number
- `password` (string, required) - Plain text password
- `group` (integer, optional) - Admin group ID (nếu admin tạo sub-user)
- `qrcode_serial` (string, optional) - Physical QR card serial
- `referral_code` (string, optional) - Referral code của người giới thiệu
- `device_info` (text, optional) - Device information
- `year`, `month`, `day` (integers, optional) - Birthday components

---

#### Step 2: Duplicate Check

```php
$existUser = User::where('email', $email);

if($phone) {
    $existUser = $existUser->orWhere('phone', $phone);
}
$existUser = $existUser->first();

if($existUser) {
    sentryLog('Email/Phone đã tồn tại');
    return $this->error([], 'Email/Phone đã tồn tại');
}
```

**Validation:**
- ✅ Check email uniqueness
- ✅ Check phone uniqueness (if provided)
- ❌ Return error if either exists

**Difference from NestJS:**
- NestJS only checks email
- PHP checks BOTH email AND phone

---

#### Step 3: Birthday Processing

```php
$birthday = null;
if($request->year && $request->month && $request->day) {
    $birthday = $request->year . '-' . $request->month . '-' . $request->day;
}
```

**Format:** `YYYY-MM-DD`
**Example:** `1990-05-15`

---

#### Step 4: User Creation - Two Paths

**Path A: Group Member (Admin creates sub-user)**

```php
if($request->has('group') && $request->group) {
    $group = $request->group;
    $user = $new_user = auth()->user();

    if(!$user) {
        $user = User::where('id', $group)->first();  // Admin user
        $new_user = User::create([
            'name' => $name,
            'email' => $email,
            'phone' => $phone,
            'password' => Hash::make($request->password),
            'type' => 'company',
            'lang' => Utility::getValByName('default_language'),
            'created_by' => 1,
            'birthday' => $birthday,
            'device_info' => $device_info
        ]);
        $new_user->created_by = $new_user->id;  // Self-reference after creation
        $new_user->save();
    }
}
```

**Group Member Logic:**
- No email validation (trust admin)
- `created_by = 1` initially, then self-assign
- Member belongs to admin's group

---

**Path B: Normal Registration**

```php
else {
    $validatedData = $request->validate([
        'email' => 'required|string|email|max:255|unique:users',
    ]);

    $user = $new_user = User::create([
        'name' => $name,
        'email' => $email,
        'phone' => $phone,
        'password' => Hash::make($request->password),
        'type' => 'company',
        'lang' => Utility::getValByName('default_language'),
        'created_by' => 1,
        'birthday' => $birthday,
        'device_info' => $device_info
    ]);
    $user->created_by = $user->id;  // Self-reference
    $user->save();
}
```

**Normal User Logic:**
- Laravel validation for email
- Password hashed with `Hash::make()` (bcrypt)
- Default type: `'company'`
- Default language from config
- `created_by` self-reference pattern

---

## Referral System

### Step 5: Referral Code Processing

**Code Location:** Lines 325-342

```php
try {
    // Get referral code from request
    $referral_code = $request->referral_code;
    $user_referral = User::where('referral_code', $referral_code)->first();

    if($user_referral) {
        // Link new user to referrer
        $user->referral_user_id = $user_referral->id;
        $user->save();

        // Get referrer's first business card
        $business = $user_referral->business()->first();

        // Create history record for referrer
        $history_data = [
            'user_id' => $user_referral->id,        // Người được refer (referrer)
            'business_id' => $business ? $business->id : 0,
            'type' => 'referral',
            'ip' => $request->ip(),
            'url' => url($business ? $business->slug : ''),
        ];
        BusinessHistory::create($history_data);
    }
}
```

### Referral URL Format

**Generated by User Model:**

```php
// In User.php
public function referralUrl() {
    return route('home.register-referral', $this->referral_code);
}
```

**Example URL:** `https://incard.vn/ref/abc123`

### Referral Code Generation

**Auto-generated by UserObserver:**

```php
// app/Observers/UserObserver.php
public function created(User $user) {
    // Generate unique 6-character code
    do {
        $idhash = strtolower(Str::random(6));
        $count = User::where('referral_code', $idhash)->count();
    } while ($count != 0);

    $user->referral_code = $idhash;
    $user->save();
}
```

**Properties:**
- ✅ Automatically generated on user creation
- ✅ 6 characters lowercase alphanumeric
- ✅ Guaranteed unique (checks database)
- ✅ Immediately available after registration

### Referral Tracking

**What gets tracked:**

1. **User Relationship:**
   - `user.referral_user_id` = ID of referrer
   - Can query: "Who referred this user?"
   - Can query: "How many people did this user refer?"

2. **Business History:**
   - `business_history.type = 'referral'`
   - Links to referrer's business card
   - Tracks IP and timestamp
   - Can calculate: "Which business card generated most referrals?"

3. **Example Queries:**

```php
// Get all users referred by user ID 10
$referred_users = User::where('referral_user_id', 10)->get();

// Get referral count for user
$referral_count = User::where('referral_user_id', $user->id)->count();

// Get referral history for business card
$referral_history = BusinessHistory::where('business_id', $business_id)
                                   ->where('type', 'referral')
                                   ->get();
```

---

## QR Code Serial System

### Step 6: QR Code Serial Assignment

**Code Location:** Lines 344-351

```php
if($qrcode_serial) {
    // Save serial to user
    $user->qrcode_serial = $qrcode_serial;
    $user->save();

    // Link QR code record to user
    $qrcode = QrcodeGenerated::where('code', $qrcode_serial)->first();
    $qrcode->user_id = $user->id;
    $qrcode->save();
}
```
Lifecyc
### Physical QR Card le

**1. Pre-Generation (Admin Action):**

Admin uses `SerialManagementController` to:
- Create QR code group
- Import list of serial codes
- Generate physical QR images
- Store in `qrcode_generated` table with `user_id = NULL`

**Example:**
```php
QrcodeGenerated::create([
    'code' => 'ABC123XYZ',
    'group_id' => 1,
    'status' => 'active',
    'user_id' => null,        // Not assigned yet
    'business_id' => null,
]);
```

**2. Physical Printing:**
- QR codes printed on physical business cards
- Each card has unique serial number
- User receives physical card

**3. User Registration:**
- User scans QR code OR enters serial manually
- Registration form includes `qrcode_serial` field
- System finds pre-generated record
- Links `user_id` to record

**4. Business Card Linking (Optional):**
- When user creates business card, can link serial
- Updates `business_id` in `qrcode_generated` record

### Verification Method

```php
// In User.php
public function checkHasPhysicalCard() {
    return QrcodeGenerated::where('code', $this->qrcode_serial)
                          ->where('user_id', $this->id)
                          ->first();
}
```

**Use Cases:**
- Verify user owns physical card
- Unlock premium features for card owners
- Track card distribution

---

## Business History Tracking

### Step 7: History Creation for Referral

**Code Location:** Lines 332-341

```php
$business = $user_referral->business()->first();  // Get referrer's first card

$history_data = [
    'user_id' => $user_referral->id,              // Referrer user ID
    'business_id' => $business ? $business->id : 0,
    'type' => 'referral',
    'ip' => $request->ip(),                       // New user's IP
    'url' => url($business ? $business->slug : ''),
];
BusinessHistory::create($history_data);
```

### History Types

**Type: `'referral'`**
- Created when someone registers via referral link
- Tracks who referred whom
- Links to referrer's business card
- Records new user's IP

**Type: `'view'`**
- Created when someone views a business card profile
- Tracks card visibility

**Type: `'scan'`**
- Created when someone scans QR code on business card
- Tracks offline-to-online engagement

### Analytics Use Cases

**Business Intelligence:**

```php
// Most effective referrer
$top_referrer = BusinessHistory::where('type', 'referral')
    ->select('user_id', DB::raw('count(*) as total'))
    ->groupBy('user_id')
    ->orderBy('total', 'desc')
    ->first();

// Referral traffic by date
$referral_trend = BusinessHistory::where('type', 'referral')
    ->where('created_at', '>=', Carbon::now()->subDays(30))
    ->groupBy(DB::raw('DATE(created_at)'))
    ->select(DB::raw('DATE(created_at) as date'), DB::raw('count(*) as count'))
    ->get();

// Referrals by business card
$card_referrals = BusinessHistory::where('business_id', $card_id)
    ->where('type', 'referral')
    ->count();
```

---

## Partner & Subscription Logic

### Partner Detection

**Triggered by UserObserver when `referral_user_id` is set:**

```php
// app/Observers/UserObserver.php
public function updating(User $user) {
    if ($user->isDirty('referral_user_id')) {
        // Check if referrer is a PARTNER (from config)
        if(in_array($user->referral_user_id,
                   explode(',', config('constants.PARTNER_USER_ID')))) {

            // Activate partner benefits
            $user->is_from_partner = true;
            $user->is_partner_trial = true;

            // Grant credits and limits
            $user->chat_credit = 50;
            $user->renew_recommend_limit = 10;

            // Set expiration dates
            $user->partner_trial_expired_date = Carbon::now()->addDays(30);
            $user->partner_subscription_deadline = Carbon::now()->addDays(62);
        }
    }
}
```

### Partner Benefits

**What user receives:**

1. **Trial Status:**
   - `is_from_partner = true`
   - `is_partner_trial = true`
   - 30-day trial period

2. **Credits & Limits:**
   - `chat_credit = 50` (for AI chat feature)
   - `renew_recommend_limit = 10` (recommendation refresh quota)

3. **Deadlines:**
   - Trial expires: 30 days from registration
   - Subscription deadline: 62 days from registration

4. **Business Logic:**
   - If user subscribes before trial expires, upgrade limits
   - After trial expires, convert to free tier
   - Partner users have higher quotas than normal users

### Configuration

**config/constants.php:**
```php
'PARTNER_USER_ID' => '5,12,45,67',  // Comma-separated partner IDs
```

---

## Group/Admin User Creation

### Admin Group Hierarchy

**Concept:**
- Company admin can create sub-users (employees)
- Sub-users belong to admin's group
- Group ID stored in `admin_group_id`

### Registration Flow with Group

**Code Location:** Lines 280-300

```php
if($request->has('group') && $request->group) {
    $group = $request->group;
    $user = $new_user = auth()->user();  // Current admin (if authenticated)

    if(!$user) {
        // Not authenticated, get admin by group ID
        $user = User::where('id', $group)->first();

        $new_user = User::create([
            'name' => $name,
            'email' => $email,
            'phone' => $phone,
            'password' => Hash::make($request->password),
            'type' => 'company',
            'lang' => Utility::getValByName('default_language'),
            'created_by' => 1,
            'birthday' => $birthday,
            'device_info' => $device_info
        ]);
        $new_user->created_by = $new_user->id;
        $new_user->save();
    }
}
```

### Key Differences: Group vs Normal Registration

| Aspect | Normal Registration | Group Registration |
|--------|-------------------|-------------------|
| Email Validation | ✅ Laravel validation | ❌ Skip validation |
| Created By | Self (`user.id`) | Admin or self |
| Admin Group ID | NULL | Set to admin's ID |
| Contact Sync | No sync | Sync to admin |

### Contact Sync to Admin

**Code in User.php `me()` method:**

```php
$num_of_contact_sync_to_admin = $user->admin_group_id ? $num_of_contact : 0;
$belong_to_group_name = null;

if($user->admin_group_id) {
    $group = User::find($user->admin_group_id);
    $belong_to_group_name = $group ? $group->name : null;
}
```

**Group member's contacts:**
- Visible to admin
- Count tracked separately
- Admin can manage group members' data

---

## Email Notifications

### Step 8: Notification Sending

**Code Location:** Lines 353-370

```php
// 1. Notify Super Admins
$super_admins = User::where('type', 'super admin')->get();
foreach($super_admins as $s_admin) {
    Mail::to($s_admin->email)->send(new NotiRegisterSuperAdmin($s_admin, $business));
}

// 2. Notify Admin (if group registration)
if($request->has('group') && $request->group) {
    Mail::to($user->email)->send(new NotiRegisterSuperAdmin($user, $business));

    // 3. Notify New User (group member)
    Mail::to($new_user->email)->send(new SendGeneratedInfo($new_user, $business));
}
else {
    // 3. Notify New User (normal registration)
    Mail::to($new_user->email)->send(new SendGeneratedInfo($new_user, $business, $request->password));
}
```

### Email Types

**1. NotiRegisterSuperAdmin:**
- Recipient: All super admins
- Purpose: Alert about new registration
- Content: New user info + business card details
- Trigger: Every registration

**2. SendGeneratedInfo:**
- Recipient: New user
- Purpose: Welcome email + account credentials
- Content: Username, password (if provided), getting started guide
- Trigger: After successful registration

### Email Classes

**Files:**
- `app/Mail/NotiRegisterSuperAdmin.php`
- `app/Mail/SendGeneratedInfo.php`

**Mailable Structure:**
```php
class SendGeneratedInfo extends Mailable {
    public $user;
    public $business;
    public $password;

    public function __construct($user, $business, $password = null) {
        $this->user = $user;
        $this->business = $business;
        $this->password = $password;
    }

    public function build() {
        return $this->subject('Welcome to InCard')
                    ->view('emails.generated-info');
    }
}
```

---

## Post-Registration Actions

### Step 9: Token Generation

```php
$success['token'] = $user->createToken('MyApp')->accessToken;
```

**Authentication:**
- Laravel Passport OAuth2
- Access token for API authentication
- Returned in response for immediate use

---

### Step 10: Device Token Storage

```php
$user->device_token = request('device_token');
$user->save();
```

**Purpose:**
- Push notifications
- Mobile app integration
- FCM/APNS targeting

---

### Step 11: Referral Link & QR Generation

```php
$referral_link = $user->referralUrl();
$referral_link_qr_path = 'app/public/referral_qr/';
$referral_link_qr_full_path = 'app/public/referral_qr/' . $user['id'] . '.png';

if(!Storage::exists($referral_link_qr_full_path)) {
    try {
        if (!Storage::exists($referral_link_qr_path)) {
            Storage::makeDirectory($referral_link_qr_path);
        }

        // Generate QR code image
        QrCode::format('png')
               ->errorCorrection('H')
               ->size(500)
               ->generate($referral_link, storage_path($referral_link_qr_full_path));
    } catch(Exception $e) {
        Log::error($e);
        sentryLog($e->getMessage());
    }
}

$referral_qr = asset(Storage::url('referral_qr/'. $user['id'] . '.png'));
```

**Referral QR Code:**
- Generated immediately after registration
- Stored in `storage/app/public/referral_qr/{user_id}.png`
- 500x500px PNG image
- High error correction (level H)
- Encodes user's referral URL

**QR Code vs QR Serial:**

| Aspect | Referral QR | Physical QR Serial |
|--------|-------------|-------------------|
| Generated | Automatically (software) | Pre-generated (admin bulk import) |
| Purpose | Share referral link | Verify physical card ownership |
| Location | Digital (storage) | Physical card |
| Content | Referral URL | Serial code string |
| Database | File only | `qrcode_generated` table |

---

### Step 12: Response Data

```php
$num_of_card = $user->business()->count();
$user = $user->toArray();
$user['num_of_card'] = $num_of_card;
$user['referral_link'] = $referral_link;
$user['referral_qr'] = $referral_qr;

$success['user'] = $user;

return $this->success($success, 'Đăng ký thành công.');
```

**Response Structure:**
```json
{
  "status": true,
  "message": "Đăng ký thành công.",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 123,
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+84987654321",
      "type": "company",
      "referral_code": "abc123",
      "referral_link": "https://incard.vn/ref/abc123",
      "referral_qr": "https://incard.vn/storage/referral_qr/123.png",
      "num_of_card": 0
    }
  }
}
```

---

## Observer Auto-Actions

### UserObserver Events

**File:** `app/Observers/UserObserver.php`

### Event 1: created()

**Triggers:** After user inserted into database

```php
public function created(User $user) {
    // Auto-generate unique referral code
    do {
        $idhash = strtolower(Str::random(6));
        $count = User::where('referral_code', $idhash)->count();
    } while ($count != 0);

    $user->referral_code = $idhash;
    $user->save();
}
```

**Actions:**
- ✅ Generate 6-char referral code
- ✅ Check uniqueness
- ✅ Save immediately

---

### Event 2: updating()

**Triggers:** Before user update saved

```php
public function updating(User $user) {
    // Partner detection
    if ($user->isDirty('referral_user_id')) {
        if(in_array($user->referral_user_id,
                   explode(',', config('constants.PARTNER_USER_ID')))) {

            $user->is_from_partner = true;
            $user->is_partner_trial = true;
            $user->chat_credit = 50;
            $user->renew_recommend_limit = 10;
            $user->partner_trial_expired_date = Carbon::now()->addDays(30);
            $user->partner_subscription_deadline = Carbon::now()->addDays(62);
        }
    }

    // Subscription bonus calculation
    if ($user->isDirty('plan')) {
        $this->calculateSubscriptionBonus($user);
    }
}
```

**Actions:**
- ✅ Detect partner referrals
- ✅ Grant trial benefits
- ✅ Calculate plan bonuses

---

### Event 3: Subscription Bonus Logic

```php
private function calculateSubscriptionBonus(User $user) {
    $plan = Plan::find($user->plan);

    if($user->is_from_partner && $plan) {
        // Partner users get higher limits
        if($plan->name == 'Premium') {
            $user->renew_recommend_limit = 50;  // vs 30 for normal
            $user->chat_credit += 100;          // bonus credits
        }
    }
}
```

---

## Related Models & Relationships

### User Model Relationships

```php
// app/Models/User.php

// Business cards owned by user
public function business() {
    return $this->hasMany(Business::class, 'created_by');
}

// Business card owned (primary)
public function ownedBusiness() {
    return $this->hasOne(Business::class, 'owner_id');
}

// Contacts saved by user
public function contacts() {
    return $this->hasMany(Contacts::class, 'user_id');
}

// Appointments for user
public function appointments() {
    return $this->hasMany(Appoinment::class, 'user_id');
}

// Users referred by this user
public function referrals() {
    return $this->hasMany(User::class, 'referral_user_id');
}

// User who referred this user
public function referrer() {
    return $this->belongsTo(User::class, 'referral_user_id');
}

// Group members (if this user is admin)
public function groupMembers() {
    return $this->hasMany(User::class, 'admin_group_id');
}

// Physical QR card
public function qrCode() {
    return $this->hasOne(QrcodeGenerated::class, 'user_id');
}
```

---

### Business Model Analytics

```php
// app/Models/Business.php

// Total profile views
public function totalView() {
    return BusinessHistory::where('business_id', $this->id)
                          ->where('type', 'view')
                          ->count();
}

// Total QR scans
public function totalScan() {
    return BusinessHistory::where('business_id', $this->id)
                          ->where('type', 'scan')
                          ->count();
}

// Total referrals
public function totalReferral() {
    return BusinessHistory::where('business_id', $this->id)
                          ->where('type', 'referral')
                          ->count();
}

// Total appointments
public function totalAppointment() {
    return Appoinment::where('business_id', $this->id)->count();
}
```

---

## Summary: Complete User Creation Flow

### Flow Diagram

```
1. HTTP Request (POST /api/register)
   ↓
2. Input Validation (email/phone uniqueness)
   ↓
3. Birthday Processing (Y-M-D format)
   ↓
4. User Creation
   ├─ Path A: Group member (admin creates)
   └─ Path B: Normal registration
   ↓
5. UserObserver::created() → Auto-generate referral_code
   ↓
6. Referral Processing
   ├─ Find referrer by code
   ├─ Set user.referral_user_id
   └─ Create BusinessHistory (type='referral')
   ↓
7. UserObserver::updating() → Check if referrer is PARTNER
   ├─ If YES: Grant trial + credits + limits
   └─ If NO: Continue
   ↓
8. QR Serial Processing
   ├─ Set user.qrcode_serial
   └─ Link QrcodeGenerated.user_id
   ↓
9. Email Notifications
   ├─ Notify super admins
   ├─ Notify admin (if group)
   └─ Notify new user (welcome)
   ↓
10. Generate Access Token (Laravel Passport)
    ↓
11. Save Device Token (for push notifications)
    ↓
12. Generate Referral Link QR Code
    ├─ Create /storage/referral_qr/{id}.png
    └─ 500x500px, error correction H
    ↓
13. Return Response
    └─ Token + User data + Referral link + QR URL
```

---

## Key Differences from NestJS Implementation

| Feature | PHP (Laravel) | NestJS (Current) | Missing in NestJS |
|---------|---------------|------------------|-------------------|
| **Email Check** | ✅ | ✅ | - |
| **Phone Check** | ✅ | ❌ | YES - No phone uniqueness |
| **Password Hash** | ✅ bcrypt | ✅ bcrypt (fixed) | - |
| **Default Plan** | ❌ | ✅ Auto-assign | - |
| **GetStream User** | ❌ | ✅ Create | - |
| **Referral Code** | ✅ Auto-generate | ❌ | YES - No referral_code field |
| **Referral Tracking** | ✅ Full logic | ❌ | YES - No referral_user_id |
| **BusinessHistory** | ✅ Track referrals | ❌ | YES - No tracking table |
| **QR Serial** | ✅ Link physical card | ❌ | YES - No qrcode_serial |
| **Partner Detection** | ✅ Auto-upgrade | ❌ | YES - No partner logic |
| **Trial/Credits** | ✅ Grant benefits | ❌ | YES - No subscription fields |
| **Group/Admin** | ✅ Hierarchy | ❌ | YES - No admin_group_id |
| **Email Notifications** | ✅ 3 types | ❌ | YES - No mailers |
| **Device Token** | ✅ Save | ❌ | YES - No device_token field |
| **Referral QR** | ✅ Generate PNG | ❌ | YES - No QR generation |
| **Birthday** | ✅ Y-M-D parse | ❌ | YES - No birthday field |
| **Language** | ✅ Default lang | ❌ | YES - No lang field |
| **created_by** | ✅ Self-reference | ❌ | YES - No created_by field |

---

## File Reference Summary

**Controllers:**
- `app/Http/Controllers/API/UserController.php` (Lines 253-423)
- `app/Http/Controllers/HomeController.php` (Web registration)
- `app/Http/Controllers/Admin/SerialManagementController.php` (QR management)

**Models:**
- `app/Models/User.php`
- `app/Models/Business.php`
- `app/Models/BusinessHistory.php`
- `app/Models/QrcodeGenerated.php`

**Observers:**
- `app/Observers/UserObserver.php`

**Migrations:**
- `database/migrations/2022_12_02_105820_add_referral_code_to_user.php`
- `database/migrations/2022_11_08_174749_create_business_history.php`
- `database/migrations/2022_11_29_135727_create_qrcode_generated.php`
- `database/migrations/2023_09_14_161900_add_sericode_to_user.php`

**Mail:**
- `app/Mail/NotiRegisterSuperAdmin.php`
- `app/Mail/SendGeneratedInfo.php`

**Routes:**
- `routes/api.php` - `POST /api/register`
- `routes/web.php` - `GET /ref/{code}`, `POST /ref`

---

## Business Logic Priority Summary

**Critical Features (Core to registration):**
1. ✅ Email/Phone uniqueness validation
2. ✅ Password hashing
3. ✅ Referral code auto-generation
4. ✅ Referral tracking (user linkage)

**Important Features (Business requirements):**
5. ✅ QR serial linking (physical card ownership)
6. ✅ BusinessHistory tracking (analytics)
7. ✅ Partner detection & benefits
8. ✅ Email notifications

**Nice-to-Have Features:**
9. ✅ Group/Admin hierarchy
10. ✅ Referral QR generation
11. ✅ Device token storage

---

**End of Documentation**

**Last Updated:** 2026-02-09
**Author:** AI Analysis
**Source:** incard-biz PHP Laravel Project
