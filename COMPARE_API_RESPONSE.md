# API Response Comparison — Business Cards & Appointments

So sánh response giữa **PHP (incard-biz)** và **NestJS (CMS_InCard_api)** cho từng endpoint.

> **Hướng dẫn sử dụng:**
> 1. Import `user-profiles-update.json` vào Postman
> 2. Set biến `base_url` và `token`
> 3. Chạy request → paste response vào cột **NestJS Response**
> 4. Ghi chú sự khác biệt vào phần **Diff / Notes**

---

## Environment

| | PHP | NestJS |
|---|---|---|
| Base URL | `http://<php-server>` | `http://localhost:3001` |
| Auth Header | `Bearer <token>` | `Bearer <token>` |
| Port | tuỳ config | 3001 (default) |

---

## Module 1: Business Cards (`/api/cards`)

---

### 1. GET /api/cards — Danh sách cards

**curl:**
```bash
curl -X GET "http://localhost:3001/api/cards" \
  -H "Authorization: Bearer {{token}}" \
  -H "Accept: application/json"
```

**curl (filter theo profiles_type):**
```bash
curl -X GET "http://localhost:3001/api/cards?profiles_type=mobile" \
  -H "Authorization: Bearer {{token}}" \
  -H "Accept: application/json"
```

| PHP Response | NestJS Response |
|---|---|
| *(paste here)* | {
    "status": true,
    "message": "",
    "data": [
        {
            "id": 6141,
            "slug": "bui-bui-thuan-9",
            "first_name": "Bui Bui",
            "last_name": "Thuan",
            "email": null,
            "phone": null,
            "title": "Intern",
            "company": "ABC",
            "bio": "noi dung bio",
            "industries": [
                {
                    "id": "460",
                    "name": "Heath"
                },
                {
                    "id": "461",
                    "name": "AI heathcare"
                }
            ],
            "services": [
                {
                    "id": "451",
                    "name": "Dịch vụ tư vấn văn phòng phẩm"
                },
                {
                    "id": "452",
                    "name": "Dịch vụ tư vấn thiết bị văn phòng"
                }
            ],
            "need_services": [],
            "sociallinks": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "social_links": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 03 03 21:26:34",
            "updated_at": "2026 03 03 21:35:38",
            "total_view": 2,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/bui-bui-thuan-9",
            "profiles_type": "mobile",
            "main_service": null,
            "key_strength": null,
            "looking_for": null,
            "collaboration": null,
            "product_services": [],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/bui-bui-thuan-9.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/bui-bui-thuan-9.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/IoL6t6ZAQ",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 7704,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6135,
            "slug": "damian-dan-17",
            "first_name": "Damian",
            "last_name": "Dan",
            "email": null,
            "phone": null,
            "title": "AI Agents & Automation Expert |  AI Software Architect & Consultant | Follow to learn: No-code AI Agents, Automation, and Business scaling tips.",
            "company": "Adaptify AI",
            "bio": "**Damian** – **AI Automation Expert & Founder of Adaptify AI**. Damian helps entrepreneurs and small to medium-sized businesses scale through AI agents, automation, and custom AI solutions. With a strong software engineering background, he designs practical systems that save time, increase revenue, and drive sustainable growth.",
            "industries": [
                {
                    "id": "462",
                    "name": "Artificial Intelligence"
                },
                {
                    "id": "463",
                    "name": "Business Automation"
                }
            ],
            "services": [],
            "need_services": [],
            "sociallinks": [],
            "social_links": [],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/logo_17701701731213467084.jpg",
            "created_at": "2026 02 04 15:56:13",
            "updated_at": "2026 02 05 21:08:07",
            "total_view": 5,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/damian-dan-17",
            "profiles_type": "web",
            "main_service": "- **Building AI agents** for workflow automation\r\n- **Delivering no-code AI** business solutions\r\n- **Developing custom AI systems** end-to-end\r\n- **Implementing AI frameworks** for scalable growth\r\n- **Optimizing operations** with intelligent automation\r\n- New ***service123***",
            "key_strength": "- **Designing scalable AI systems** for business growth\r\n- **Automating complex workflows** with AI agents\r\n- **Bridging no-code and custom AI** solutions\r\n- **Translating business needs** into AI architectures\r\n- **Driving efficiency and revenue** through automation",
            "looking_for": {
                "tech-focus": [
                    "AI agents",
                    "automation123"
                ],
                "company-size": [
                    "Startup",
                    "SME",
                    "Scale-up1123"
                ],
                "growth-target": "Scale SMBs123",
                "target-market": [
                    "Global",
                    "APAC",
                    "EU"
                ],
                "core-expertise": "AI automation123",
                "ops-strategy123": "Process Automation123",
                "engagement-model": "Project-based consulting123"
            },
            "collaboration": {
                "ideal-role": [
                    "Founder",
                    "CEO",
                    "Owner"
                ],
                "partner-types": [
                    "Customer",
                    "Tech Partner",
                    "Strategic Partner"
                ],
                "organization-type": [
                    "Startup",
                    "SME",
                    "Scale-up"
                ]
            },
            "product_services": [
                {
                    "id": 1,
                    "title": "AI Automation",
                    "link_title ": null,
                    "description": "null",
                    "purchase_link": null,
                    "image": "img_1770172181210005264.jpg"
                },
                {
                    "id": 2,
                    "title": "AI Agents",
                    "link_title ": null,
                    "description": "null",
                    "purchase_link": null,
                    "image": "img_17701721811238855588.jpg"
                },
                {
                    "id": 3,
                    "title": "No-Code AI Solutions",
                    "link_title ": null,
                    "description": "null",
                    "purchase_link": null,
                    "image": "img_17701721811764569873.jpg"
                }
            ],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/damian-dan-17.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/damian-dan-17.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/damian-dan-17",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 6946,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6132,
            "slug": "damian-dan-16",
            "first_name": "Damian123",
            "last_name": "Dan",
            "email": null,
            "phone": null,
            "title": "AI Agents & Automation Expert |  AI Software Architect & Consultant | Follow to learn: No-code AI Agents, Automation, and Business scaling tips.",
            "company": "Adaptify AI",
            "bio": "**Damian** – **AI Automation Expert & Founder of Adaptify AI**. Damian helps entrepreneurs and small to medium-sized businesses scale through AI agents, automation, and custom AI solutions. With a strong software engineering background, he designs practical systems that save time, increase revenue, and drive sustainable growth.",
            "industries": [
                {
                    "id": "462",
                    "name": "Artificial Intelligence"
                },
                {
                    "id": "463",
                    "name": "Business Automation"
                }
            ],
            "services": [],
            "need_services": [],
            "sociallinks": [],
            "social_links": [],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/logo_17700919011440808261.jpg",
            "created_at": "2026 02 03 18:11:41",
            "updated_at": "2026 02 24 16:12:07",
            "total_view": 6,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/damian-dan-16",
            "profiles_type": "web",
            "main_service": "- **Building AI agents** for workflow automation\r\n- **Delivering no-code AI** business solutions\r\n- **Developing custom AI systems** end-to-end\r\n- **Implementing AI frameworks** for scalable growth\r\n- **Optimizing operations** with intelligent automation\r\n- New service\r\n- New service",
            "key_strength": "- **Designing scalable AI systems** for business growth\r\n- **Automating complex workflows** with AI agents\r\n- **Bridging no-code and custom AI** solutions\r\n- **Translating business needs** into AI architectures\r\n- **Driving efficiency and revenue** through automation\r\n- New strength\r\n- New strength",
            "looking_for": {
                "tech-focus": "AI agents, automation",
                "company-size": [
                    "Startup",
                    "SME",
                    "Scale-up"
                ],
                "ops-strategy": "Process Automation",
                "growth-target": "Scale SMBs",
                "target-market": [
                    "Global",
                    "APAC",
                    "EU"
                ],
                "core-expertise": "AI automation",
                "engagement-model": "Project-based consulting"
            },
            "collaboration": {
                "ideal-role": [
                    "Founder",
                    "CEO",
                    "Owner"
                ],
                "partner-types": [
                    "Customer",
                    "Tech Partner",
                    "Strategic Partner"
                ],
                "organization-type": [
                    "Startup",
                    "SME",
                    "Scale-up"
                ]
            },
            "product_services": [
                {
                    "id": 1,
                    "title": "AI Automation",
                    "link_title ": null,
                    "description": "null",
                    "purchase_link": null,
                    "image": "img_17702758661176668849.jpg"
                },
                {
                    "id": 2,
                    "title": "AI Agents",
                    "link_title ": null,
                    "description": "null",
                    "purchase_link": null,
                    "image": "img_1770275866997710032.jpg"
                },
                {
                    "id": 3,
                    "title": "No-Code AI Solutions",
                    "link_title ": null,
                    "description": "null",
                    "purchase_link": null,
                    "image": "img_1770275866692337731.jpg"
                },
                {
                    "id": 4,
                    "title": "New Product",
                    "link_title ": null,
                    "description": "Product description...",
                    "purchase_link": null,
                    "image": "img_1770275866883377259.jpg"
                },
                {
                    "id": 5,
                    "title": "New Product",
                    "link_title ": null,
                    "description": "Product description...",
                    "purchase_link": null,
                    "image": "img_1770275866125832445.png"
                }
            ],
            "media": [
                {
                    "id": 1,
                    "title": "Featured Content",
                    "link_title ": null,
                    "description": null,
                    "video_link": null,
                    "image": "img_17702758661632236487.jpg"
                },
                {
                    "id": 2,
                    "title": null,
                    "link_title ": null,
                    "description": null,
                    "video_link": null,
                    "image": "img_1770275866440148064.jpg"
                },
                {
                    "id": 3,
                    "title": null,
                    "link_title ": null,
                    "description": null,
                    "video_link": null,
                    "image": "img_17702758661179288967.jpg"
                }
            ],
            "profile_qr": "http://localhost:3001/storage/profile_qr/damian-dan-16.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/damian-dan-16.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/damian-dan-16",
            "banner_img": null,
            "settings": {
                "phone_enable": "1",
                "zalo_enable": "1",
                "whatsapp_enable": "1"
            },
            "tags": [],
            "owner_id": 6946,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6131,
            "slug": "aruna-kumara-frm-6",
            "first_name": "Aruna",
            "last_name": "Kumara, FRM123",
            "email": null,
            "phone": null,
            "title": "Financial Services Expert | Former CEO (SMF1) | Executive Director |  \r\nBanking CEO of the Year 2023 - London | Risk Management Specia",
            "company": "Aureate Consulting Ltd",
            "bio": "**Senior Financial Services Executive** – **Former Banking CEO & Risk Leader**. Visionary finance, treasury, and risk management executive with deep banking expertise and a proven record of transforming institutions into profitable, compliant, and digitally enabled organizations. Recognized for strategic leadership, regulatory excellence, and driving fintech-led transformation across complex markets.",
            "industries": [
                {
                    "id": "467",
                    "name": "Banking"
                },
                {
                    "id": "468",
                    "name": "Financial Services"
                }
            ],
            "services": [],
            "need_services": [],
            "sociallinks": [],
            "social_links": [],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/logo_17700915971465167786.jpg",
            "created_at": "2026 02 03 18:06:37",
            "updated_at": "2026 02 03 18:12:10",
            "total_view": 3,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/aruna-kumara-frm-6",
            "profiles_type": "web",
            "main_service": "- Providing **financial services consulting** for **banks**.\r\n- Leading **risk management frameworks** and **governance**.\r\n- Advising on **treasury, ALM** and **FX strategy**.\r\n- Driving **digital transformation** in **banking operations**.\r\n- Supporting **regulatory readiness** and **PRA compliance**.",
            "key_strength": "- Driving **bank-wide transformation** with **measurable profitability**.\r\n- Leading **treasury and FX** with **market expertise**.\r\n- Delivering **robust risk governance** and **regulatory compliance**.\r\n- Championing **digital banking** and **fintech innovation**.\r\n- Building **high-performance leadership teams**.\r\n- Executing **strategic growth** in **regulated environments**.",
            "looking_for": {
                "tech-focus": "FinTech, Digital Banking",
                "company-size": [
                    "Enterprise",
                    "MNC",
                    "SME"
                ],
                "ops-strategy": "Digital Transformation",
                "growth-target": "Profitable scaling",
                "target-market": [
                    "UK",
                    "EU",
                    "Global"
                ],
                "core-expertise": "Risk, Treasury",
                "engagement-model": "Strategic advisory"
            },
            "collaboration": {
                "ideal-role": [
                    "CEO",
                    "Board Member",
                    "C-level"
                ],
                "partner-types": [
                    "Customer",
                    "Strategic Partner",
                    "Investor"
                ],
                "organization-type": [
                    "Enterprise",
                    "MNC",
                    "Agency/Consultancy"
                ]
            },
            "product_services": [
                {
                    "id": 1,
                    "title": "Financial Services Consulting",
                    "link_title ": null,
                    "description": "null",
                    "purchase_link": null,
                    "image": "img_17700916481071461314.jpg"
                },
                {
                    "id": 2,
                    "title": "Risk Management",
                    "link_title ": null,
                    "description": "null",
                    "purchase_link": null,
                    "image": "img_17700916481335195141.jpg"
                },
                {
                    "id": 3,
                    "title": "Treasury Management",
                    "link_title ": null,
                    "description": "null",
                    "purchase_link": null,
                    "image": "img_1770091648432542763.jpg"
                },
                {
                    "id": 4,
                    "title": "Digital Transformation",
                    "link_title ": null,
                    "description": "null",
                    "purchase_link": null,
                    "image": "img_17700916481576678175.jpg"
                },
                {
                    "id": 5,
                    "title": "Regulatory Compliance",
                    "link_title ": null,
                    "description": "null",
                    "purchase_link": null,
                    "image": "img_1770091648121595827.jpg"
                }
            ],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/aruna-kumara-frm-6.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/aruna-kumara-frm-6.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/aruna-kumara-frm-6",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 6946,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6130,
            "slug": "aruna-kumara-frm-5",
            "first_name": "Aruna",
            "last_name": "Kumara, FRM",
            "email": null,
            "phone": null,
            "title": "Financial Services Expert | Former CEO (SMF1) | Executive Director |                                                           \r\nBanking CEO of the Year 2023 - London | Risk Management Specia",
            "company": "Aureate Consulting Ltd",
            "bio": "**Senior Financial Services Executive** – **Former Banking CEO & Risk Leader**. Visionary finance, treasury, and risk management executive with deep banking expertise and a proven record of transforming institutions into profitable, compliant, and digitally enabled organizations. Recognized for strategic leadership, regulatory excellence, and driving fintech-led transformation across complex markets.",
            "industries": [
                {
                    "id": "467",
                    "name": "Banking"
                },
                {
                    "id": "468",
                    "name": "Financial Services"
                }
            ],
            "services": [],
            "need_services": [],
            "sociallinks": [],
            "social_links": [],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/logo_1770090997332506293.jpg",
            "created_at": "2026 02 03 17:56:37",
            "updated_at": "2026 02 03 18:14:45",
            "total_view": 3,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/aruna-kumara-frm-5",
            "profiles_type": "web",
            "main_service": "- Providing **financial services consulting** for **banks**.\r\n- Leading **risk management frameworks** and **governance**.\r\n- Advising on **treasury, ALM** and **FX strategy**.\r\n- Driving **digital transformation** in **banking operations**.\r\n- Supporting **regulatory readiness** and **PRA compliance**.",
            "key_strength": "- Driving **bank-wide transformation** with **measurable profitability**.\r\n- Leading **treasury and FX** with **market expertise**.\r\n- Delivering **robust risk governance** and **regulatory compliance**.\r\n- Championing **digital banking** and **fintech innovation**.\r\n- Building **high-performance leadership teams**.\r\n- Executing **strategic growth** in **regulated environments**.",
            "looking_for": {
                "tech-focus": "FinTech, Digital Banking",
                "company-size": [
                    "Enterprise",
                    "MNC",
                    "SME"
                ],
                "ops-strategy": "Digital Transformation",
                "growth-target": "Profitable scaling",
                "target-market": [
                    "UK",
                    "EU",
                    "Global"
                ],
                "core-expertise": "Risk, Treasury",
                "engagement-model": "Strategic advisory"
            },
            "collaboration": {
                "ideal-role": [
                    "CEO",
                    "Board Member",
                    "C-level"
                ],
                "partner-types": [
                    "Customer",
                    "Strategic Partner",
                    "Investor"
                ],
                "organization-type": [
                    "Enterprise",
                    "MNC",
                    "Agency/Consultancy"
                ]
            },
            "product_services": [
                {
                    "id": 1,
                    "title": "Financial Services Consulting",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                },
                {
                    "id": 2,
                    "title": "Risk Management",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                },
                {
                    "id": 3,
                    "title": "Treasury Management",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                },
                {
                    "id": 4,
                    "title": "Digital Transformation",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                },
                {
                    "id": 5,
                    "title": "Regulatory Compliance",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                }
            ],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/aruna-kumara-frm-5.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/aruna-kumara-frm-5.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/aruna-kumara-frm-5",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 6946,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6129,
            "slug": "damian-dan-15",
            "first_name": "Damian",
            "last_name": "Dan",
            "email": null,
            "phone": null,
            "title": "AI Agents & Automation Expert | AI Software Architect & Consultant | Follow to learn: No-code AI Agents, Automation, and Business scaling tips.",
            "company": "Adaptify AI",
            "bio": "**Damian** – **AI Automation Expert & Founder of Adaptify AI**. Damian helps entrepreneurs and small to medium-sized businesses scale through AI agents, automation, and custom AI solutions. With a strong software engineering background, he designs practical systems that save time, increase revenue, and drive sustainable growth.",
            "industries": [
                {
                    "id": "462",
                    "name": "Artificial Intelligence"
                },
                {
                    "id": "463",
                    "name": "Business Automation"
                }
            ],
            "services": [],
            "need_services": [],
            "sociallinks": [],
            "social_links": [],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/logo_1770090404394657935.jpg",
            "created_at": "2026 02 03 17:46:44",
            "updated_at": "2026 02 03 17:49:12",
            "total_view": 3,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/damian-dan-15",
            "profiles_type": "web",
            "main_service": "- **Building AI agents** for workflow automation\r\n- **Delivering no-code AI** business solutions\r\n- **Developing custom AI systems** end-to-end\r\n- **Implementing AI frameworks** for scalable growth\r\n- **Optimizing operations** with intelligent automation",
            "key_strength": "- **Designing scalable AI systems** for business growth\r\n- **Automating complex workflows** with AI agents\r\n- **Bridging no-code and custom AI** solutions\r\n- **Translating business needs** into AI architectures\r\n- **Driving efficiency and revenue** through automation",
            "looking_for": {
                "tech-focus": "AI agents, automation",
                "company-size": [
                    "Startup",
                    "SME",
                    "Scale-up"
                ],
                "ops-strategy": "Process Automation",
                "growth-target": "Scale SMBs",
                "target-market": [
                    "Global",
                    "APAC",
                    "EU"
                ],
                "core-expertise": "AI automation",
                "engagement-model": "Project-based consulting"
            },
            "collaboration": {
                "ideal-role": [
                    "Founder",
                    "CEO",
                    "Owner"
                ],
                "partner-types": [
                    "Customer",
                    "Tech Partner",
                    "Strategic Partner"
                ],
                "organization-type": [
                    "Startup",
                    "SME",
                    "Scale-up"
                ]
            },
            "product_services": [
                {
                    "id": 1,
                    "title": "AI Automation",
                    "link_title ": null,
                    "description": "null",
                    "purchase_link": null,
                    "image": "img_1770090538395793863.jpg"
                },
                {
                    "id": 2,
                    "title": "AI Agents",
                    "link_title ": null,
                    "description": "null",
                    "purchase_link": null,
                    "image": "img_1770090538938822169.jpg"
                },
                {
                    "id": 3,
                    "title": "No-Code AI Solutions",
                    "link_title ": null,
                    "description": "null",
                    "purchase_link": null,
                    "image": "img_17700905381431014324.jpg"
                }
            ],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/damian-dan-15.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/damian-dan-15.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/damian-dan-15",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 6946,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6128,
            "slug": "trang-nguyen-rose",
            "first_name": "Trang",
            "last_name": "Nguyen (Rose)123",
            "email": null,
            "phone": null,
            "title": "Talent Acquisition Manager (Northern) - Admicro - VCCorp | Career Match-Maker",
            "company": "Admicro",
            "bio": "**Trang Nguyen** – **Talent Acquisition Manager & Career Matchmaker**. HR professional with over 10 years of experience in talent acquisition across FMCG, finance, retail, marketing, and manufacturing. Passionate about matching the right talent with the right roles while sharing career insights through podcasting and content creation.",
            "industries": [
                {
                    "id": "478",
                    "name": "Human Resources"
                },
                {
                    "id": "479",
                    "name": "Recruitment"
                }
            ],
            "services": [],
            "need_services": [],
            "sociallinks": [],
            "social_links": [],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/logo_17700893352120033766.jpg",
            "created_at": "2026 02 03 17:28:55",
            "updated_at": "2026 02 03 17:36:34",
            "total_view": 0,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/trang-nguyen-rose",
            "profiles_type": "web",
            "main_service": "- Delivering **talent acquisition** for scaling organizations\r\n- Providing **strategic recruitment** planning support\r\n- Managing **employer branding** and hiring campaigns\r\n- Supporting **career matching** and talent advisory\r\n- Advising on **HR workforce** planning",
            "key_strength": "- **Strategic recruitment** across diverse industries\r\n- **End-to-end talent** acquisition leadership\r\n- **Employer branding** and candidate engagement\r\n- **HR planning** for business growth\r\n- **Career coaching** and mentorship",
            "looking_for": {
                "tech-focus": "HR systems",
                "company-size": [
                    "Enterprise",
                    "MNC",
                    "SME"
                ],
                "ops-strategy": "Rapid Scaling",
                "growth-target": "Hiring expansion",
                "target-market": [
                    "SEA",
                    "APAC",
                    "Global"
                ],
                "core-expertise": "Talent acquisition",
                "engagement-model": "Project-based"
            },
            "collaboration": {
                "ideal-role": [
                    "CEO",
                    "Founder",
                    "Head of Dept"
                ],
                "partner-types": [
                    "Customer",
                    "Strategic Partner",
                    "Media/Publisher"
                ],
                "organization-type": [
                    "Enterprise",
                    "MNC",
                    "SME"
                ]
            },
            "product_services": [
                {
                    "id": 1,
                    "title": "Talent Acquisition",
                    "link_title ": null,
                    "description": "Professional service offering tailored to your business needs.",
                    "purchase_link": null,
                    "image": null
                },
                {
                    "id": 2,
                    "title": "Recruitment Strategy",
                    "link_title ": null,
                    "description": "Professional service offering tailored to your business needs.",
                    "purchase_link": null,
                    "image": null
                },
                {
                    "id": 3,
                    "title": "Career Coaching",
                    "link_title ": null,
                    "description": "Professional service offering tailored to your business needs.",
                    "purchase_link": null,
                    "image": null
                }
            ],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/trang-nguyen-rose.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/trang-nguyen-rose.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/trang-nguyen-rose",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 6946,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6127,
            "slug": "damian-dan-14",
            "first_name": "Damian",
            "last_name": "Dan",
            "email": null,
            "phone": null,
            "title": "AIIIIIIII Agents & Automation Expert | AI Software Architect & Consultant | Follow to learn: No-code AI Agents, Automation, and Business scaling tips.",
            "company": "Adaptify AI",
            "bio": "**Damian** – **AI Automation Expert & Founder of Adaptify AI**. Damian helps entrepreneurs and small to medium-sized businesses scale through AI agents, automation, and custom AI solutions. With a strong software engineering background, he designs practical systems that save time, increase revenue, and drive sustainable growth.",
            "industries": [
                {
                    "id": "462",
                    "name": "Artificial Intelligence"
                },
                {
                    "id": "463",
                    "name": "Business Automation"
                }
            ],
            "services": [],
            "need_services": [],
            "sociallinks": [],
            "social_links": [],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/logo_17700883161711539518.jpg",
            "created_at": "2026 02 03 17:11:56",
            "updated_at": "2026 02 03 17:46:12",
            "total_view": 4,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/damian-dan-14",
            "profiles_type": "web",
            "main_service": "- **Building AI agents** for workflow automation\r\n- **Delivering no-code AI** business solutions\r\n- **Developing custom AI systems** end-to-end\r\n- **Implementing AI frameworks** for scalable growth\r\n- **Optimizing operations** with intelligent automation",
            "key_strength": "- **Designing scalable AI systems** for business growth\r\n- **Automating complex workflows** with AI agents\r\n- **Bridging no-code and custom AI** solutions\r\n- **Translating business needs** into AI architectures\r\n- **Driving efficiency and revenue** through automation",
            "looking_for": {
                "tech-focus": "AI agents, automation",
                "company-size": [
                    "Startup",
                    "SME",
                    "Scale-up"
                ],
                "ops-strategy": "Process Automation",
                "growth-target": "Scale SMBs",
                "target-market": [
                    "Global",
                    "APAC",
                    "EU"
                ],
                "core-expertise": "AI automation",
                "engagement-model": "Project-based consulting"
            },
            "collaboration": {
                "ideal-role": [
                    "Founder",
                    "CEO",
                    "Owner"
                ],
                "partner-types": [
                    "Customer",
                    "Tech Partner",
                    "Strategic Partner"
                ],
                "organization-type": [
                    "Startup",
                    "SME",
                    "Scale-up"
                ]
            },
            "product_services": [
                {
                    "id": 1,
                    "title": "AI Automation",
                    "link_title ": null,
                    "description": "null",
                    "purchase_link": null,
                    "image": "img_1770088927851875872.jpg"
                },
                {
                    "id": 2,
                    "title": "AI Agents",
                    "link_title ": null,
                    "description": "null",
                    "purchase_link": null,
                    "image": "img_1770088927304148465.jpg"
                },
                {
                    "id": 3,
                    "title": "No-Code AI Solutions",
                    "link_title ": null,
                    "description": "null",
                    "purchase_link": null,
                    "image": "img_1770088927902720491.jpg"
                }
            ],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/damian-dan-14.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/damian-dan-14.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/damian-dan-14",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 6946,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6114,
            "slug": "aruna-kumara-frm-4",
            "first_name": "Aruna",
            "last_name": "Kumara, FRM",
            "email": null,
            "phone": null,
            "title": "Financial Services Expert | Former CEO (SMF1) | Executive Director |                                                           \r\nBanking CEO of the Year 2023 - London | Risk Management Specia",
            "company": "Aureate Consulting Ltd",
            "bio": "**Senior Financial Services Executive** – **Former Banking CEO & Risk Leader**. Visionary finance, treasury, and risk management executive with deep banking expertise and a proven record of transforming institutions into profitable, compliant, and digitally enabled organizations. Recognized for strategic leadership, regulatory excellence, and driving fintech-led transformation across complex markets.",
            "industries": [
                {
                    "id": "467",
                    "name": "Banking"
                },
                {
                    "id": "468",
                    "name": "Financial Services"
                }
            ],
            "services": [],
            "need_services": [],
            "sociallinks": [],
            "social_links": [],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/logo_1769674937217633425.jpg",
            "created_at": "2026 01 29 22:22:17",
            "updated_at": "2026 02 03 17:05:35",
            "total_view": 7,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/aruna-kumara-frm-4",
            "profiles_type": "web",
            "main_service": "- Providing **financial services consulting** for **banks**.\r\n- Leading **risk management frameworks** and **governance**.\r\n- Advising on **treasury, ALM** and **FX strategy**.\r\n- Driving **digital transformation** in **banking operations**.\r\n- Supporting **regulatory readiness** and **PRA compliance**.",
            "key_strength": "- Driving **bank-wide transformation** with **measurable profitability**.\r\n- Leading **treasury and FX** with **market expertise**.\r\n- Delivering **robust risk governance** and **regulatory compliance**.\r\n- Championing **digital banking** and **fintech innovation**.\r\n- Building **high-performance leadership teams**.\r\n- Executing **strategic growth** in **regulated environments**.",
            "looking_for": {
                "tech-focus": "FinTech, Digital Banking",
                "company-size": [
                    "Enterprise",
                    "MNC",
                    "SME"
                ],
                "ops-strategy": "Digital Transformation",
                "growth-target": "Profitable scaling",
                "target-market": [
                    "UK",
                    "EU",
                    "Global"
                ],
                "core-expertise": "Risk, Treasury",
                "engagement-model": "Strategic advisory"
            },
            "collaboration": {
                "ideal-role": [
                    "CEO",
                    "Board Member",
                    "C-level"
                ],
                "partner-types": [
                    "Customer",
                    "Strategic Partner",
                    "Investor"
                ],
                "organization-type": [
                    "Enterprise",
                    "MNC",
                    "Agency/Consultancy"
                ]
            },
            "product_services": [
                {
                    "id": 1,
                    "title": "Financial Services Consulting",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                },
                {
                    "id": 2,
                    "title": "Risk Management",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                },
                {
                    "id": 3,
                    "title": "Treasury Management",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                },
                {
                    "id": 4,
                    "title": "Digital Transformation",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                },
                {
                    "id": 5,
                    "title": "Regulatory Compliance",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                }
            ],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/aruna-kumara-frm-4.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/aruna-kumara-frm-4.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/aruna-kumara-frm-4",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 6946,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6113,
            "slug": "damian-dan-13",
            "first_name": "Damian",
            "last_name": "Dan",
            "email": null,
            "phone": null,
            "title": "AI Agents & Automation Expert |  AI Software Architect & Consultant | Follow to learn: No-code AI Agents, Automation, and Business scaling tips.",
            "company": "Adaptify AI",
            "bio": "**Damian** – **AI Automation Expert & Founder of Adaptify AI**. Damian helps entrepreneurs and small to medium-sized businesses scale through AI agents, automation, and custom AI solutions. With a strong software engineering background, he designs practical systems that save time, increase revenue, and drive sustainable growth.",
            "industries": [
                {
                    "id": "462",
                    "name": "Artificial Intelligence"
                },
                {
                    "id": "463",
                    "name": "Business Automation"
                }
            ],
            "services": [],
            "need_services": [],
            "sociallinks": [],
            "social_links": [],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/logo_17696741401063654051.jpg",
            "created_at": "2026 01 29 22:09:00",
            "updated_at": "2026 02 03 17:05:42",
            "total_view": 3,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/damian-dan-13",
            "profiles_type": "web",
            "main_service": "- **Building AI agents** for workflow automation\r\n- **Delivering no-code AI** business solutions\r\n- **Developing custom AI systems** end-to-end\r\n- **Implementing AI frameworks** for scalable growth\r\n- **Optimizing operations** with intelligent automation",
            "key_strength": "- **Designing scalable AI systems** for business growth\r\n- **Automating complex workflows** with AI agents\r\n- **Bridging no-code and custom AI** solutions\r\n- **Translating business needs** into AI architectures\r\n- **Driving efficiency and revenue** through automation",
            "looking_for": {
                "tech-focus": "AI agents, automation",
                "company-size": [
                    "Startup",
                    "SME",
                    "Scale-up"
                ],
                "ops-strategy": "Process Automation",
                "growth-target": "Scale SMBs",
                "target-market": [
                    "Global",
                    "APAC",
                    "EU"
                ],
                "core-expertise": "AI automation",
                "engagement-model": "Project-based consulting"
            },
            "collaboration": {
                "ideal-role": [
                    "Founder",
                    "CEO",
                    "Owner"
                ],
                "partner-types": [
                    "Customer",
                    "Tech Partner",
                    "Strategic Partner"
                ],
                "organization-type": [
                    "Startup",
                    "SME",
                    "Scale-up"
                ]
            },
            "product_services": [
                {
                    "id": 1,
                    "title": "AI Automation",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                },
                {
                    "id": 2,
                    "title": "AI Agents",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                },
                {
                    "id": 3,
                    "title": "No-Code AI Solutions",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                }
            ],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/damian-dan-13.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/damian-dan-13.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/damian-dan-13",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 6946,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6112,
            "slug": "quy-nguyen-3",
            "first_name": "Quý",
            "last_name": "Nguyễn",
            "email": null,
            "phone": null,
            "title": "Comprehensive Digital Transformation Specialist for Businesses",
            "company": "Giba Business & Community",
            "bio": "**Quý Nguyễn (Eric Nguyễn)** – **Chuyên gia Chuyển đổi Số**. Hơn 5 năm kinh nghiệm dẫn dắt chuyển đổi số, nâng cấp phần mềm và xây dựng thương hiệu. Đồng sáng lập cộng đồng CRO Việt Nam, đồng hành cùng doanh nghiệp phát triển bền vững và mở rộng thị trường.",
            "industries": [
                {
                    "id": "464",
                    "name": "Digital Transformation"
                },
                {
                    "id": "465",
                    "name": "SaaS"
                },
                {
                    "id": "466",
                    "name": "Marketing"
                }
            ],
            "services": [],
            "need_services": [],
            "sociallinks": [],
            "social_links": [],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/logo_17696738731982675151.jpg",
            "created_at": "2026 01 29 22:04:33",
            "updated_at": "2026 01 29 22:05:38",
            "total_view": 0,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/quy-nguyen-3",
            "profiles_type": "web",
            "main_service": "- **Tư vấn** chiến lược **chuyển đổi số**\r\n- **Nâng cấp** hệ thống **phần mềm**\r\n- **Tối ưu** quy trình **vận hành**\r\n- **Xây dựng** chiến lược **thương hiệu**\r\n- **Tư vấn** marketing cho **SaaS**",
            "key_strength": "- **Dẫn dắt** chiến lược **chuyển đổi số**\r\n- **Tối ưu** quy trình bằng **công nghệ**\r\n- **Xây dựng** thương hiệu **bền vững**\r\n- **Kết nối** hệ sinh thái **SaaS**\r\n- **Tư duy** sáng tạo **hướng tăng trưởng**",
            "looking_for": {
                "tech-focus": "Chuyển đổi số",
                "company-size": [
                    "Startup",
                    "Scale-up",
                    "SME"
                ],
                "ops-strategy": "Digital Transformation",
                "growth-target": "Mở rộng thị trường",
                "target-market": [
                    "SEA",
                    "APAC",
                    "Global"
                ],
                "core-expertise": "Tối ưu vận hành",
                "engagement-model": "Tư vấn chiến lược"
            },
            "collaboration": {
                "ideal-role": [
                    "Founder",
                    "CEO",
                    "C-level"
                ],
                "partner-types": [
                    "Customer",
                    "Strategic Partner",
                    "Tech Partner"
                ],
                "organization-type": [
                    "Startup",
                    "Scale-up",
                    "SME"
                ]
            },
            "product_services": [
                {
                    "id": 1,
                    "title": "Digital Transformation Consulting",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                },
                {
                    "id": 2,
                    "title": "Software Optimization",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                },
                {
                    "id": 3,
                    "title": "Brand Strategy",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                },
                {
                    "id": 4,
                    "title": "SaaS Marketing",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                }
            ],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/quy-nguyen-3.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/quy-nguyen-3.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/quy-nguyen-3",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 6946,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6111,
            "slug": "damian-dan-12",
            "first_name": "Damian",
            "last_name": "Dan",
            "email": null,
            "phone": null,
            "title": "AI Agents & Automation Expert |  AI Software Architect & Consultant | Follow to learn: No-code AI Agents, Automation, and Business scaling tips.",
            "company": "Adaptify AI",
            "bio": "**Damian** – **AI Automation Expert & Founder of Adaptify AI**. Damian helps entrepreneurs and small to medium-sized businesses scale through AI agents, automation, and custom AI solutions. With a strong software engineering background, he designs practical systems that save time, increase revenue, and drive sustainable growth.",
            "industries": [
                {
                    "id": "462",
                    "name": "Artificial Intelligence"
                },
                {
                    "id": "463",
                    "name": "Business Automation"
                }
            ],
            "services": [],
            "need_services": [],
            "sociallinks": [],
            "social_links": [],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 01 29 21:30:31",
            "updated_at": "2026 01 29 21:34:34",
            "total_view": 1,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/damian-dan-12",
            "profiles_type": "web",
            "main_service": "- **Building AI agents** for workflow automation\r\n- **Delivering no-code AI** business solutions\r\n- **Developing custom AI systems** end-to-end\r\n- **Implementing AI frameworks** for scalable growth\r\n- **Optimizing operations** with intelligent automation",
            "key_strength": "- **Designing scalable AI systems** for business growth\r\n- **Automating complex workflows** with AI agents\r\n- **Bridging no-code and custom AI** solutions\r\n- **Translating business needs** into AI architectures\r\n- **Driving efficiency and revenue** through automation",
            "looking_for": {
                "tech-focus": "AI agents, automation",
                "company-size": [
                    "Startup",
                    "SME",
                    "Scale-up"
                ],
                "ops-strategy": "Process Automation",
                "growth-target": "Scale SMBs",
                "target-market": [
                    "Global",
                    "APAC",
                    "EU"
                ],
                "core-expertise": "AI automation",
                "engagement-model": "Project-based consulting"
            },
            "collaboration": {
                "ideal-role": [
                    "Founder",
                    "CEO",
                    "Owner"
                ],
                "partner-types": [
                    "Customer",
                    "Tech Partner",
                    "Strategic Partner"
                ],
                "organization-type": [
                    "Startup",
                    "SME",
                    "Scale-up"
                ]
            },
            "product_services": [
                {
                    "id": 1,
                    "title": "AI Automation",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                },
                {
                    "id": 2,
                    "title": "AI Agents",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                },
                {
                    "id": 3,
                    "title": "No-Code AI Solutions",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                }
            ],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/damian-dan-12.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/damian-dan-12.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/damian-dan-12",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 6946,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6110,
            "slug": "damian-dan-11",
            "first_name": "Damian",
            "last_name": "Dan",
            "email": null,
            "phone": null,
            "title": "AI Agents & Automation Expert |  AI Software Architect & Consultant | Follow to learn: No-code AI Agents, Automation, and Business scaling tips.",
            "company": "Adaptify AI",
            "bio": "**Damian** – **AI Automation Expert & Founder of Adaptify AI**. Damian helps entrepreneurs and small to medium-sized businesses scale through AI agents, automation, and custom AI solutions. With a strong software engineering background, he designs practical systems that save time, increase revenue, and drive sustainable growth.",
            "industries": [],
            "services": [],
            "need_services": [],
            "sociallinks": [],
            "social_links": [],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 01 29 21:25:34",
            "updated_at": "2026 01 29 21:34:44",
            "total_view": 1,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/damian-dan-11",
            "profiles_type": "web",
            "main_service": "- **Building AI agents** for workflow automation\r\n- **Delivering no-code AI** business solutions\r\n- **Developing custom AI systems** end-to-end\r\n- **Implementing AI frameworks** for scalable growth\r\n- **Optimizing operations** with intelligent automation",
            "key_strength": "- **Designing scalable AI systems** for business growth\r\n- **Automating complex workflows** with AI agents\r\n- **Bridging no-code and custom AI** solutions\r\n- **Translating business needs** into AI architectures\r\n- **Driving efficiency and revenue** through automation",
            "looking_for": {
                "tech-focus": "AI agents, automation",
                "company-size": [
                    "Startup",
                    "SME",
                    "Scale-up"
                ],
                "ops-strategy": "Process Automation",
                "growth-target": "Scale SMBs",
                "target-market": [
                    "Global",
                    "APAC",
                    "EU"
                ],
                "core-expertise": "AI automation",
                "engagement-model": "Project-based consulting"
            },
            "collaboration": {
                "ideal-role": [
                    "Founder",
                    "CEO",
                    "Owner"
                ],
                "partner-types": [
                    "Customer",
                    "Tech Partner",
                    "Strategic Partner"
                ],
                "organization-type": [
                    "Startup",
                    "SME",
                    "Scale-up"
                ]
            },
            "product_services": [
                {
                    "id": 1,
                    "title": "AI Automation",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                },
                {
                    "id": 2,
                    "title": "AI Agents",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                },
                {
                    "id": 3,
                    "title": "No-Code AI Solutions",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": null,
                    "image": null
                }
            ],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/damian-dan-11.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/damian-dan-11.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/damian-dan-11",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 6946,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6109,
            "slug": "bui-bui-thuan-8",
            "first_name": "Bui Bui",
            "last_name": "Thuan",
            "email": null,
            "phone": null,
            "title": "Intern",
            "company": "ABC",
            "bio": "noi dung bio",
            "industries": [
                {
                    "id": "460",
                    "name": "Heath"
                },
                {
                    "id": "461",
                    "name": "AI heathcare"
                }
            ],
            "services": [
                {
                    "id": "451",
                    "name": "Dịch vụ tư vấn văn phòng phẩm"
                },
                {
                    "id": "452",
                    "name": "Dịch vụ tư vấn thiết bị văn phòng"
                }
            ],
            "need_services": [],
            "sociallinks": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "social_links": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 01 29 21:17:35",
            "updated_at": "2026 01 29 21:26:10",
            "total_view": 0,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/bui-bui-thuan-8",
            "profiles_type": "mobile",
            "main_service": null,
            "key_strength": null,
            "looking_for": null,
            "collaboration": null,
            "product_services": [],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/bui-bui-thuan-8.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/bui-bui-thuan-8.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/bui-bui-thuan-8",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 7678,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6108,
            "slug": "bui-bui-thuan-7",
            "first_name": "Bui Bui",
            "last_name": "Thuan",
            "email": null,
            "phone": null,
            "title": "Intern",
            "company": "ABC",
            "bio": "noi dung bio",
            "industries": [
                {
                    "id": "451",
                    "name": "Ngành thang máy"
                },
                {
                    "id": "452",
                    "name": "Vật tư thang máy"
                }
            ],
            "services": [
                {
                    "id": "451",
                    "name": "Dịch vụ tư vấn văn phòng phẩm"
                },
                {
                    "id": "452",
                    "name": "Dịch vụ tư vấn thiết bị văn phòng"
                }
            ],
            "need_services": [],
            "sociallinks": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "social_links": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 01 29 21:13:54",
            "updated_at": "2026 01 29 21:26:12",
            "total_view": 0,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/bui-bui-thuan-7",
            "profiles_type": "mobile",
            "main_service": null,
            "key_strength": null,
            "looking_for": null,
            "collaboration": null,
            "product_services": [],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/bui-bui-thuan-7.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/bui-bui-thuan-7.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/bui-bui-thuan-7",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 7677,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6107,
            "slug": "bui-bui-thuan-6",
            "first_name": "Bui Bui",
            "last_name": "Thuan",
            "email": null,
            "phone": null,
            "title": "Intern",
            "company": "ABC",
            "bio": "noi dung bio",
            "industries": [
                {
                    "id": "451",
                    "name": "Ngành thang máy"
                },
                {
                    "id": "452",
                    "name": "Vật tư thang máy"
                }
            ],
            "services": [
                {
                    "id": "451",
                    "name": "Dịch vụ tư vấn văn phòng phẩm"
                },
                {
                    "id": "452",
                    "name": "Dịch vụ tư vấn thiết bị văn phòng"
                }
            ],
            "need_services": [],
            "sociallinks": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "social_links": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 01 29 21:12:29",
            "updated_at": "2026 01 29 21:26:13",
            "total_view": 0,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/bui-bui-thuan-6",
            "profiles_type": "mobile",
            "main_service": null,
            "key_strength": null,
            "looking_for": null,
            "collaboration": null,
            "product_services": [],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/bui-bui-thuan-6.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/bui-bui-thuan-6.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/bui-bui-thuan-6",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 7676,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6106,
            "slug": "bui-bui-thuan-5",
            "first_name": "Bui Bui",
            "last_name": "Thuan",
            "email": null,
            "phone": null,
            "title": "Intern",
            "company": "ABC",
            "bio": "noi dung bio",
            "industries": [
                {
                    "id": "457",
                    "name": "Vệ sinh"
                },
                {
                    "id": "459",
                    "name": "Sở thú"
                }
            ],
            "services": [
                {
                    "id": "451",
                    "name": "Dịch vụ tư vấn văn phòng phẩm"
                },
                {
                    "id": "452",
                    "name": "Dịch vụ tư vấn thiết bị văn phòng"
                }
            ],
            "need_services": [],
            "sociallinks": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "social_links": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 01 29 21:11:44",
            "updated_at": "2026 01 29 21:26:14",
            "total_view": 0,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/bui-bui-thuan-5",
            "profiles_type": "mobile",
            "main_service": null,
            "key_strength": null,
            "looking_for": null,
            "collaboration": null,
            "product_services": [],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/bui-bui-thuan-5.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/bui-bui-thuan-5.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/bui-bui-thuan-5",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 7675,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6105,
            "slug": "bui-bui-thuan-4",
            "first_name": "Bui Bui",
            "last_name": "Thuan",
            "email": null,
            "phone": null,
            "title": "Intern",
            "company": "ABC",
            "bio": "noi dung bio",
            "industries": [
                {
                    "id": "457",
                    "name": "Vệ sinh"
                },
                {
                    "id": "458",
                    "name": "Sở thú"
                }
            ],
            "services": [
                {
                    "id": "1",
                    "name": "Digital Marketing"
                },
                {
                    "id": "2",
                    "name": "Tư vấn nhân sự"
                }
            ],
            "need_services": [],
            "sociallinks": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "social_links": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 01 29 20:59:22",
            "updated_at": "2026 01 29 21:26:15",
            "total_view": 0,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/bui-bui-thuan-4",
            "profiles_type": "mobile",
            "main_service": null,
            "key_strength": null,
            "looking_for": null,
            "collaboration": null,
            "product_services": [],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/bui-bui-thuan-4.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/bui-bui-thuan-4.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/bui-bui-thuan-4",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 7674,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6103,
            "slug": "quy-nguyen-2",
            "first_name": "Quý",
            "last_name": "Nguyễn",
            "email": null,
            "phone": null,
            "title": "Comprehensive Digital Transformation Specialist for Businesses",
            "company": "Giba Business & Community",
            "bio": "**Quý Nguyễn (Eric Nguyễn)** – **Chuyên gia Chuyển đổi Số**. Hơn 5 năm kinh nghiệm dẫn dắt chuyển đổi số, nâng cấp phần mềm và xây dựng thương hiệu. Đồng sáng lập cộng đồng CRO Việt Nam, đồng hành cùng doanh nghiệp phát triển bền vững và mở rộng thị trường.",
            "industries": [],
            "services": [],
            "need_services": [],
            "sociallinks": [],
            "social_links": [],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 01 29 00:22:47",
            "updated_at": "2026 01 29 17:20:19",
            "total_view": 1,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/quy-nguyen-2",
            "profiles_type": "web",
            "main_service": "- **Tư vấn** chiến lược **chuyển đổi số**\r\n- **Nâng cấp** hệ thống **phần mềm**\r\n- **Tối ưu** quy trình **vận hành**\r\n- **Xây dựng** chiến lược **thương hiệu**\r\n- **Tư vấn** marketing cho **SaaS**",
            "key_strength": "- **Dẫn dắt** chiến lược **chuyển đổi số**\r\n- **Tối ưu** quy trình bằng **công nghệ**\r\n- **Xây dựng** thương hiệu **bền vững**\r\n- **Kết nối** hệ sinh thái **SaaS**\r\n- **Tư duy** sáng tạo **hướng tăng trưởng**",
            "looking_for": {
                "tech-focus": "Chuyển đổi số",
                "company-size": [
                    "Startup",
                    "Scale-up",
                    "SME"
                ],
                "ops-strategy": "Digital Transformation",
                "growth-target": "Mở rộng thị trường",
                "target-market": [
                    "SEA",
                    "APAC",
                    "Global"
                ],
                "core-expertise": "Tối ưu vận hành",
                "engagement-model": "Tư vấn chiến lược"
            },
            "collaboration": {
                "ideal-role": [
                    "Founder",
                    "CEO",
                    "C-level"
                ],
                "partner-types": [
                    "Customer",
                    "Strategic Partner",
                    "Tech Partner"
                ],
                "organization-type": [
                    "Startup",
                    "Scale-up",
                    "SME"
                ]
            },
            "product_services": [],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/quy-nguyen-2.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/quy-nguyen-2.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/quy-nguyen-2",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 6946,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6102,
            "slug": "1254-13",
            "first_name": "1254",
            "last_name": "13",
            "email": null,
            "phone": null,
            "title": "Intern",
            "company": "ABC",
            "bio": "noi dung bio",
            "industries": [
                {
                    "id": "1",
                    "name": "Agriculture"
                },
                {
                    "id": "2",
                    "name": "Chemical"
                }
            ],
            "services": [
                {
                    "id": "1",
                    "name": "Digital Marketing"
                },
                {
                    "id": "2",
                    "name": "Tư vấn nhân sự"
                }
            ],
            "need_services": [],
            "sociallinks": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "social_links": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 01 29 00:20:00",
            "updated_at": "2026 01 29 00:28:09",
            "total_view": 0,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/1254-13",
            "profiles_type": "mobile",
            "main_service": null,
            "key_strength": null,
            "looking_for": null,
            "collaboration": null,
            "product_services": [
                {
                    "id": 1,
                    "title": "Service 01",
                    "link_title ": null,
                    "description": null,
                    "purchase_link": "http://shop.com/",
                    "image": null
                }
            ],
            "media": [
                {
                    "id": 1,
                    "title": "media",
                    "link_title ": null,
                    "description": null,
                    "video_link": null,
                    "image": null
                }
            ],
            "profile_qr": "http://localhost:3001/storage/profile_qr/1254-13.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/1254-13.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/1254-13",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 7673,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6101,
            "slug": "paul-emmanuel-delattre",
            "first_name": "paul",
            "last_name": "emmanuel delattre",
            "email": null,
            "phone": null,
            "title": "Enterprise Architect",
            "company": "Hermès",
            "bio": "**Enterprise Architect** – **Digital Innovation Engineer**. Experienced consultant supporting IT departments of large enterprises through complex digital transformations. Brings strong enterprise architecture, cloud, and agile expertise to deliver sustainable business value.",
            "industries": [],
            "services": [],
            "need_services": [],
            "sociallinks": [],
            "social_links": [],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 01 29 00:18:09",
            "updated_at": "2026 01 29 17:20:20",
            "total_view": 1,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/paul-emmanuel-delattre",
            "profiles_type": "web",
            "main_service": "- Delivering **enterprise architecture** frameworks and roadmaps\r\n- Leading **digital transformation** initiatives end-to-end\r\n- Defining **IT strategy** aligned to business goals\r\n- Designing **cloud architecture** and target platforms\r\n- Enabling **agile and DevOps** practices",
            "key_strength": "- Driving **enterprise architecture** across complex ecosystems\r\n- Leading **digital transformation** for large organizations\r\n- Aligning **IT strategy** with business value\r\n- Enabling **agile at scale** delivery models\r\n- Bridging **business and technology** teams",
            "looking_for": {
                "tech-focus": "Enterprise IT, Cloud",
                "company-size": [
                    "Enterprise",
                    "MNC",
                    "SME"
                ],
                "ops-strategy": "Digital Transformation",
                "growth-target": "Enterprise modernization",
                "target-market": [
                    "EU",
                    "Global",
                    "APAC"
                ],
                "core-expertise": "Architecture, Transformation",
                "engagement-model": "Consulting projects"
            },
            "collaboration": {
                "ideal-role": [
                    "C-level",
                    "CIO",
                    "CTO"
                ],
                "partner-types": [
                    "Customer",
                    "Tech Partner",
                    "Strategic Partner"
                ],
                "organization-type": [
                    "Enterprise",
                    "MNC",
                    "Agency/Consultancy"
                ]
            },
            "product_services": [],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/paul-emmanuel-delattre.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/paul-emmanuel-delattre.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/paul-emmanuel-delattre",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 6946,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6100,
            "slug": "12-13",
            "first_name": "12",
            "last_name": "13",
            "email": null,
            "phone": null,
            "title": "Intern",
            "company": "ABC",
            "bio": "noi dung bio",
            "industries": [
                {
                    "id": "1",
                    "name": "Agriculture"
                },
                {
                    "id": "2",
                    "name": "Chemical"
                }
            ],
            "services": [
                {
                    "id": "1",
                    "name": "Digital Marketing"
                },
                {
                    "id": "2",
                    "name": "Tư vấn nhân sự"
                }
            ],
            "need_services": [],
            "sociallinks": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "social_links": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 01 29 00:10:32",
            "updated_at": "2026 01 29 00:11:15",
            "total_view": 1,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/12-13",
            "profiles_type": "mobile",
            "main_service": null,
            "key_strength": null,
            "looking_for": null,
            "collaboration": null,
            "product_services": [
                {
                    "id": 1,
                    "title": "Service 01",
                    "link_title ": null,
                    "description": "Service 01 - description",
                    "purchase_link": "http://shop.com/",
                    "image": null
                }
            ],
            "media": [
                {
                    "id": 1,
                    "title": "media",
                    "link_title ": null,
                    "description": "detia description",
                    "video_link": "http://youtube.com/",
                    "image": null
                }
            ],
            "profile_qr": "http://localhost:3001/storage/profile_qr/12-13.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/12-13.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/12-13",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 7672,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6099,
            "slug": "bui-bui123-thuan12313123aa123-1",
            "first_name": "Bui Bui123",
            "last_name": "Thuan12313123aa123",
            "email": null,
            "phone": null,
            "title": "Intern",
            "company": "ABC",
            "bio": "noi dung bio",
            "industries": [
                {
                    "id": "1",
                    "name": "Agriculture"
                },
                {
                    "id": "2",
                    "name": "Chemical"
                }
            ],
            "services": [
                {
                    "id": "1",
                    "name": "Digital Marketing"
                },
                {
                    "id": "2",
                    "name": "Tư vấn nhân sự"
                }
            ],
            "need_services": [],
            "sociallinks": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "social_links": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 01 28 23:55:41",
            "updated_at": "2026 01 29 00:28:44",
            "total_view": 1,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/bui-bui123-thuan12313123aa123-1",
            "profiles_type": "mobile",
            "main_service": null,
            "key_strength": null,
            "looking_for": null,
            "collaboration": null,
            "product_services": [
                {
                    "id": 1,
                    "title": "Service 01",
                    "link_title ": null,
                    "description": "Service 01 - description",
                    "purchase_link": "http://shop.com/",
                    "image": null
                }
            ],
            "media": [
                {
                    "id": 1,
                    "title": "media",
                    "link_title ": null,
                    "description": "detia description",
                    "video_link": "http://youtube.com/",
                    "image": null
                }
            ],
            "profile_qr": "http://localhost:3001/storage/profile_qr/bui-bui123-thuan12313123aa123-1.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/bui-bui123-thuan12313123aa123-1.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/bui-bui123-thuan12313123aa123-1",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 7671,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6098,
            "slug": "romuald-czlonkowski-4",
            "first_name": "Romuald",
            "last_name": "Czlonkowski",
            "email": null,
            "phone": null,
            "title": "AI Implementation Practicioner & Advisor | n8n-mcp.com founder (33k users)",
            "company": "The World Bank",
            "bio": "**Romuald** – **AI Implementation Advisor & Founder**. Independent consultant helping organizations turn complex AI into practical, revenue-driving solutions with measurable ROI. Advisor to the World Bank and former AI Solutions Director at an international digital agency.",
            "industries": [],
            "services": [],
            "need_services": [],
            "sociallinks": [],
            "social_links": [],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 01 28 23:41:15",
            "updated_at": "2026 01 29 17:20:22",
            "total_view": 1,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/romuald-czlonkowski-4",
            "profiles_type": "web",
            "main_service": "- Developing **AI strategy** aligned with **business goals**\r\n- Implementing **process automation** for **operational efficiency**\r\n- Delivering **generative AI solutions** for **new revenue**\r\n- Building **data analytics** and **decision systems**\r\n- Integrating **AI tools** with **existing systems**",
            "key_strength": "- Driving **measurable ROI** through **AI implementation**\r\n- Bridging **business strategy** with **AI technology**\r\n- Ensuring **enterprise-grade security** and **risk management**\r\n- Scaling teams with **vetted AI specialists**\r\n- Applying **global best practices** to **local markets**",
            "looking_for": {
                "tech-focus": "Applied AI",
                "company-size": [
                    "Startup",
                    "Scale-up",
                    "Enterprise"
                ],
                "ops-strategy": "Digital Transformation",
                "growth-target": "ROI-driven growth",
                "target-market": [
                    "Global",
                    "EU",
                    "APAC"
                ],
                "core-expertise": "AI implementation",
                "engagement-model": "Consulting projects"
            },
            "collaboration": {
                "ideal-role": [
                    "CEO",
                    "Founder",
                    "C-level"
                ],
                "partner-types": [
                    "Customer",
                    "Tech Partner",
                    "Strategic Partner"
                ],
                "organization-type": [
                    "Enterprise",
                    "Scale-up",
                    "Agency/Consultancy"
                ]
            },
            "product_services": [],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/romuald-czlonkowski-4.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/romuald-czlonkowski-4.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/romuald-czlonkowski-4",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 6946,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6097,
            "slug": "bui-bui123-thuan12313123aa123",
            "first_name": "Bui Bui123",
            "last_name": "Thuan12313123aa123",
            "email": null,
            "phone": null,
            "title": "Intern",
            "company": "ABC",
            "bio": "noi dung bio",
            "industries": [
                {
                    "id": "1",
                    "name": "Agriculture"
                },
                {
                    "id": "2",
                    "name": "Chemical"
                }
            ],
            "services": [
                {
                    "id": "1",
                    "name": "Digital Marketing"
                },
                {
                    "id": "2",
                    "name": "Tư vấn nhân sự"
                }
            ],
            "need_services": [],
            "sociallinks": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "social_links": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 01 28 23:39:18",
            "updated_at": "2026 01 29 00:10:14",
            "total_view": 2,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/bui-bui123-thuan12313123aa123",
            "profiles_type": "mobile",
            "main_service": null,
            "key_strength": null,
            "looking_for": null,
            "collaboration": null,
            "product_services": [
                {
                    "id": 1,
                    "title": "Service 01",
                    "link_title ": null,
                    "description": "Service 01 - description",
                    "purchase_link": "http://shop.com/",
                    "image": "img_17695931581053343123.png"
                }
            ],
            "media": [
                {
                    "id": 1,
                    "title": "media",
                    "link_title ": null,
                    "description": "detia description",
                    "video_link": "http://youtube.com/",
                    "image": "img_1769593158500532241.png"
                }
            ],
            "profile_qr": "http://localhost:3001/storage/profile_qr/bui-bui123-thuan12313123aa123.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/bui-bui123-thuan12313123aa123.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/bui-bui123-thuan12313123aa123",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 7670,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6095,
            "slug": "bui-bui123-thuan123123aa123-1",
            "first_name": "Bui Bui123",
            "last_name": "Thuan123123aa123",
            "email": null,
            "phone": null,
            "title": "Intern",
            "company": "ABC",
            "bio": "noi dung bio",
            "industries": [
                {
                    "id": "1",
                    "name": "Agriculture"
                },
                {
                    "id": "2",
                    "name": "Chemical"
                }
            ],
            "services": [
                {
                    "id": "1",
                    "name": "Digital Marketing"
                },
                {
                    "id": "2",
                    "name": "Tư vấn nhân sự"
                }
            ],
            "need_services": [],
            "sociallinks": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "social_links": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 01 28 22:55:02",
            "updated_at": "2026 01 28 23:40:09",
            "total_view": 2,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/bui-bui123-thuan123123aa123-1",
            "profiles_type": "mobile",
            "main_service": null,
            "key_strength": null,
            "looking_for": null,
            "collaboration": null,
            "product_services": [
                {
                    "id": 1,
                    "title": "Service 01",
                    "link_title ": null,
                    "description": "Service 01 - description",
                    "purchase_link": "http://shop.com/",
                    "image": "img_1769590502781126840.png"
                }
            ],
            "media": [
                {
                    "id": 1,
                    "title": "media",
                    "link_title ": null,
                    "description": "detia description",
                    "video_link": "http://youtube.com/",
                    "image": "img_17695905022018974184.png"
                }
            ],
            "profile_qr": "http://localhost:3001/storage/profile_qr/bui-bui123-thuan123123aa123-1.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/bui-bui123-thuan123123aa123-1.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/bui-bui123-thuan123123aa123-1",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 7669,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6094,
            "slug": "bui-bui123-thuan123123aa123",
            "first_name": "Bui Bui123",
            "last_name": "Thuan123123aa123",
            "email": null,
            "phone": null,
            "title": "Intern",
            "company": "ABC",
            "bio": "noi dung bio",
            "industries": [
                {
                    "id": "1",
                    "name": "Agriculture"
                },
                {
                    "id": "2",
                    "name": "Chemical"
                }
            ],
            "services": [
                {
                    "id": "1",
                    "name": "Digital Marketing"
                },
                {
                    "id": "2",
                    "name": "Tư vấn nhân sự"
                }
            ],
            "need_services": [],
            "sociallinks": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "social_links": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 01 28 22:53:42",
            "updated_at": "2026 01 28 22:55:29",
            "total_view": 3,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/bui-bui123-thuan123123aa123",
            "profiles_type": "mobile",
            "main_service": null,
            "key_strength": null,
            "looking_for": null,
            "collaboration": null,
            "product_services": [],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/bui-bui123-thuan123123aa123.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/bui-bui123-thuan123123aa123.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/bui-bui123-thuan123123aa123",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 7668,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6093,
            "slug": "bui-bui123-thuan123123aa-1",
            "first_name": "Bui Bui123",
            "last_name": "Thuan123123aa",
            "email": null,
            "phone": null,
            "title": "Intern",
            "company": "ABC",
            "bio": "noi dung bio",
            "industries": [
                {
                    "id": "1",
                    "name": "Agriculture"
                },
                {
                    "id": "2",
                    "name": "Chemical"
                }
            ],
            "services": [
                {
                    "id": "1",
                    "name": "Digital Marketing"
                },
                {
                    "id": "2",
                    "name": "Tư vấn nhân sự"
                }
            ],
            "need_services": [],
            "sociallinks": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "social_links": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 01 28 22:11:18",
            "updated_at": "2026 01 28 22:54:29",
            "total_view": 0,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/bui-bui123-thuan123123aa-1",
            "profiles_type": "mobile",
            "main_service": null,
            "key_strength": null,
            "looking_for": null,
            "collaboration": null,
            "product_services": [
                {
                    "id": 1,
                    "title": "Service 01",
                    "link_title ": null,
                    "description": "Service 01 - description",
                    "purchase_link": "http://shop.com/",
                    "image": "img_1769587878682319811.png"
                }
            ],
            "media": [
                {
                    "id": 1,
                    "title": "media",
                    "link_title ": null,
                    "description": "detia description",
                    "video_link": "http://youtube.com/",
                    "image": "img_1769587878775549654.png"
                }
            ],
            "profile_qr": "http://localhost:3001/storage/profile_qr/bui-bui123-thuan123123aa-1.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/bui-bui123-thuan123123aa-1.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/bui-bui123-thuan123123aa-1",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 7667,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6092,
            "slug": "bui-bui123-thuan123123aa",
            "first_name": "Bui Bui123",
            "last_name": "Thuan123123aa",
            "email": null,
            "phone": null,
            "title": "Intern",
            "company": "ABC",
            "bio": "noi dung bio",
            "industries": [
                {
                    "id": "1",
                    "name": "Agriculture"
                },
                {
                    "id": "2",
                    "name": "Chemical"
                }
            ],
            "services": [
                {
                    "id": "1",
                    "name": "Digital Marketing"
                },
                {
                    "id": "2",
                    "name": "Tư vấn nhân sự"
                }
            ],
            "need_services": [],
            "sociallinks": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "social_links": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 01 28 22:08:00",
            "updated_at": "2026 01 28 22:08:48",
            "total_view": 1,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/bui-bui123-thuan123123aa",
            "profiles_type": "mobile",
            "main_service": null,
            "key_strength": null,
            "looking_for": null,
            "collaboration": null,
            "product_services": [
                {
                    "id": 1,
                    "title": "Service 01",
                    "link_title ": null,
                    "description": "Service 01 - description",
                    "purchase_link": null,
                    "image": "img_17695876801991605124.png"
                }
            ],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/bui-bui123-thuan123123aa.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/bui-bui123-thuan123123aa.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/bui-bui123-thuan123123aa",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 7666,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6091,
            "slug": "bui-bui123-thuan12312",
            "first_name": "Bui Bui123",
            "last_name": "Thuan12312",
            "email": null,
            "phone": null,
            "title": "Intern",
            "company": "ABC",
            "bio": "noi dung bio",
            "industries": [
                {
                    "id": "1",
                    "name": "Agriculture"
                },
                {
                    "id": "2",
                    "name": "Chemical"
                }
            ],
            "services": [
                {
                    "id": "1",
                    "name": "Digital Marketing"
                },
                {
                    "id": "2",
                    "name": "Tư vấn nhân sự"
                }
            ],
            "need_services": [],
            "sociallinks": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "social_links": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebooko": "https://facebook",
                    "id": 1
                }
            ],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2026 01 28 21:47:27",
            "updated_at": "2026 01 28 22:08:39",
            "total_view": 2,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/bui-bui123-thuan12312",
            "profiles_type": "mobile",
            "main_service": null,
            "key_strength": null,
            "looking_for": null,
            "collaboration": null,
            "product_services": [],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/bui-bui123-thuan12312.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/bui-bui123-thuan12312.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/bui-bui123-thuan12312",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 7665,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6089,
            "slug": "bui-bui-thuan-3",
            "first_name": "Bui Bui",
            "last_name": "Thuan",
            "email": null,
            "phone": null,
            "title": "Intern",
            "company": "ABC",
            "bio": "noi dung bio",
            "industries": [
                {
                    "id": "1",
                    "name": "Agriculture"
                },
                {
                    "id": "2",
                    "name": "Chemical"
                }
            ],
            "services": [
                {
                    "id": "1",
                    "name": "Digital Marketing"
                },
                {
                    "id": "2",
                    "name": "Tư vấn nhân sự"
                }
            ],
            "need_services": [],
            "sociallinks": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebook": "https://facebook",
                    "id": 1
                }
            ],
            "social_links": [
                {
                    "zalo": "https://zalo",
                    "id": 0
                },
                {
                    "facebook": "https://facebook",
                    "id": 1
                }
            ],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/logo_17695805612097766595.png",
            "created_at": "2026 01 28 20:09:21",
            "updated_at": "2026 01 29 17:20:23",
            "total_view": 0,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/bui-bui-thuan-3",
            "profiles_type": "web",
            "main_service": "- Providing **fractional CSO leadership** for growth\\n- Delivering **sales velocity improvement** programs\\n- Designing **strategic selling** frameworks\\n- Deploying **sales process optimization** initiatives\\n- Coaching **executive sales teams** for results",
            "key_strength": "- Driving **sales velocity** through **proven metrics**\\n- Building **high-performance teams** across generations\\n- Executing **strategic go-to-market** programs\\n- Coaching **C-level leaders** for **behavior change**\\n- Translating **features to client value**",
            "looking_for": {
                "tech-focus": "Sales tech",
                "company-size": [
                    "Enterprise",
                    "MNC",
                    "SME"
                ],
                "ops-strategy": "Go-to-Market",
                "growth-target": "Sales acceleration",
                "target-market": [
                    "North America",
                    "US",
                    "Global"
                ],
                "core-expertise": "Revenue growth",
                "engagement-model": "Fractional leadership"
            },
            "collaboration": {
                "ideal-role": [
                    "CEO",
                    "Founder",
                    "C-level"
                ],
                "partner-types": [
                    "Customer",
                    "Strategic Partner",
                    "Talent/Candidate"
                ],
                "organization-type": [
                    "Enterprise",
                    "MNC",
                    "Agency/Consultancy"
                ]
            },
            "product_services": [],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/bui-bui-thuan-3.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/bui-bui-thuan-3.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/bui-bui-thuan-3",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 7664,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 5307,
            "slug": "ha-ha-1",
            "first_name": "Ha",
            "last_name": "ha",
            "email": null,
            "phone": null,
            "title": null,
            "company": null,
            "bio": null,
            "industries": [
                {
                    "id": "186",
                    "name": "Hàng không"
                }
            ],
            "services": [
                {
                    "id": "785",
                    "name": "Máy kéo thang máy"
                }
            ],
            "need_services": [
                {
                    "id": "781",
                    "name": "Thiết bị thang máy"
                },
                {
                    "id": "785",
                    "name": "Máy kéo thang máy"
                }
            ],
            "sociallinks": [],
            "social_links": [],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2025 08 13 22:25:00",
            "updated_at": "2025 11 24 19:00:54",
            "total_view": 3,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/ha-ha-1",
            "profiles_type": "mobile",
            "main_service": null,
            "key_strength": null,
            "looking_for": null,
            "collaboration": null,
            "product_services": [],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/ha-ha-1.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/ha-ha-1.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/ha-ha-1",
            "banner_img": null,
            "settings": {
                "phone_enable": "1",
                "zalo_enable": "1",
                "whatsapp_enable": "1"
            },
            "tags": [],
            "owner_id": 6946,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 5306,
            "slug": "ha-ha",
            "first_name": "Ha",
            "last_name": "ha",
            "email": null,
            "phone": null,
            "title": null,
            "company": null,
            "bio": null,
            "industries": [],
            "services": [],
            "need_services": [],
            "sociallinks": [],
            "social_links": [],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
            "created_at": "2025 08 13 22:24:33",
            "updated_at": "2026 02 24 16:05:45",
            "total_view": 3,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/ha-ha",
            "profiles_type": "mobile",
            "main_service": null,
            "key_strength": null,
            "looking_for": null,
            "collaboration": null,
            "product_services": [],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/ha-ha.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/ha-ha.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/ha-ha",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 6946,
            "password": null,
            "enable_password": 0
        },
        {
            "id": 6140,
            "slug": "tran-van-b",
            "first_name": "Tran",
            "last_name": "Van B",
            "email": "tranvanb@example.com",
            "phone": "0912345678",
            "title": "UI/UX Designer",
            "company": "Design Studio",
            "bio": "Designer chuyên nghiệp",
            "industries": [],
            "services": [],
            "need_services": [],
            "sociallinks": [],
            "social_links": [],
            "testimonials": [],
            "logo": "http://localhost:3001/storage/card_logo/logo_1772519113533424023668.png",
            "created_at": null,
            "updated_at": "2026 03 03 20:51:13",
            "total_view": 0,
            "total_scan": 0,
            "total_appointment": 0,
            "is_owner": true,
            "request_status": "not_requested",
            "profile_url": "http://localhost:3001/profile/tran-van-b",
            "profiles_type": "mobile",
            "main_service": null,
            "key_strength": null,
            "looking_for": null,
            "collaboration": null,
            "product_services": [],
            "media": [],
            "profile_qr": "http://localhost:3001/storage/profile_qr/tran-van-b.png",
            "contact_qr": "http://localhost:3001/storage/contact_qr/tran-van-b.png",
            "is_my_card": true,
            "deeplink": "http://localhost:3001/profile/tran-van-b",
            "banner_img": null,
            "settings": {
                "phone_enable": 1,
                "zalo_enable": 1,
                "whatsapp_enable": 1
            },
            "tags": [],
            "owner_id": 6946,
            "password": null,
            "enable_password": 0
        }
    ]
} |

**Expected shape:**
```json
{
  "status": true,
  "message": "",
  "data": [
    {
      "id": 1,
      "slug": "nguyen-van-a",
      "first_name": "Nguyen",
      "last_name": "Van A",
      "email": "owner@example.com",
      "phone": "0901234567",
      "title": "Senior Engineer",
      "company": "Tech Corp",
      "bio": "...",
      "profile_url": "APP_URL/profile/nguyen-van-a",
      "profile_qr": "APP_URL/storage/profile_qr/nguyen-van-a.png",
      "contact_qr": "APP_URL/storage/contact_qr/nguyen-van-a.png",
      "deeplink": "APP_URL/profile/nguyen-van-a",
      "banner_img": null,
      "logo": "APP_URL/storage/card_logo/...",
      "total_view": 0,
      "total_scan": 0,
      "total_appointment": 0,
      "is_owner": true,
      "is_my_card": true,
      "owner_id": 10,
      "sociallinks": [{"Facebook": "https://...", "id": 0}],
      "social_links": [{"Facebook": "https://...", "id": 0}],
      "testimonials": [],
      "industries": [{"id": "0", "name": "Agriculture"}],
      "services": [{"id": "0", "name": "Digital Marketing"}],
      "need_services": [],
      "product_services": [],
      "media": [],
      "settings": {"phone_enable": 1, "zalo_enable": 1},
      "password": null,
      "enable_password": 0,
      "tags": [],
      "profiles_type": "mobile",
      "main_service": null,
      "key_strength": null,
      "looking_for": null,
      "collaboration": null,
      "created_at": "...",
      "updated_at": "..."
    }
  ]
}
```

**Diff / Notes:**
```
(ghi chú sự khác biệt ở đây)
```

---

### 2. POST /api/cards — Tạo card mới

**curl:**
```bash
curl -X POST "http://localhost:3001/api/cards" \
  -H "Authorization: Bearer {{token}}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "first_name": "Nguyen",
    "last_name": "Van A",
    "email": "nguyenvana@example.com",
    "phone": "0901234567",
    "bio": "Chuyen gia cong nghe",
    "title": "Senior Engineer",
    "company": "Tech Corp",
    "profiles_type": "mobile",
    "social_link": {
      "Facebook": "https://facebook.com/nguyenvana",
      "LinkedIn": "https://linkedin.com/in/nguyenvana"
    }
  }'
```

| PHP Response | NestJS Response |
|---|---|
| *(paste here)* | {
    "status": true,
    "message": "Tạo danh thiếp thành công!",
    "data": {
        "id": 6142,
        "slug": "tran-van-b-2544",
        "first_name": "Tran",
        "last_name": "Van B",
        "email": "tranvaanb@example.com",
        "phone": "0912345678",
        "title": "UI/UX Designer",
        "company": "Design Studio",
        "bio": "Designer chuyên nghiệp",
        "industries": [],
        "services": [],
        "need_services": [],
        "sociallinks": [],
        "testimonials": [],
        "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
        "created_at": "2026 03 05 09:13:21",
        "updated_at": "2026 03 05 09:13:21",
        "total_view": 0,
        "total_scan": 0,
        "total_appointment": 0,
        "is_owner": true,
        "request_status": "not_requested",
        "profile_url": "http://localhost:3001/tran-van-b-2544",
        "profiles_type": "mobile",
        "main_service": null,
        "key_strength": null,
        "looking_for": null,
        "collaboration": null,
        "product_services": [],
        "media": []
    }
} |

**Expected shape (SUBSET — không có profile_qr, contact_qr, deeplink, banner_img, tags, owner_id, is_my_card):**
```json
{
  "status": true,
  "message": "Tạo danh thiếp thành công!",
  "data": {
    "id": 1,
    "slug": "nguyen-van-a",
    "first_name": "Nguyen",
    "last_name": "Van A",
    "email": "nguyenvana@example.com",
    "phone": "0901234567",
    "title": "Senior Engineer",
    "company": "Tech Corp",
    "bio": "...",
    "profile_url": "APP_URL/nguyen-van-a",
    "logo": "APP_URL/storage/card_logo/default_avatar.png",
    "sociallinks": [{"type": "Facebook", "value": "https://..."}],
    "testimonials": [],
    "industries": [],
    "services": [],
    "need_services": [],
    "product_services": [],
    "media": [],
    "password": null,
    "enable_password": null,
    "profiles_type": "mobile",
    "total_view": 0,
    "total_scan": 0,
    "total_appointment": 0,
    "is_owner": true,
    "created_at": "...",
    "updated_at": "..."
  }
}
```

> ⚠️ **profile_url** trong create/update KHÔNG có `/profile/` prefix (khác với index/detail)

**Diff / Notes:**
```
(ghi chú sự khác biệt ở đây)
```

---

### 3. GET /api/cards/:id — Chi tiết card

**curl:**
```bash
curl -X GET "http://localhost:3001/api/cards/1" \
  -H "Authorization: Bearer {{token}}" \
  -H "Accept: application/json"
```

**curl (quét QR — ghi scan history):**
```bash
curl -X GET "http://localhost:3001/api/cards/1?fromScan=1" \
  -H "Authorization: Bearer {{token}}" \
  -H "Accept: application/json"
```

> ⚠️ PHP dùng `?fromScan=1` (không phải `?type=scan`) để track scan history

| PHP Response | NestJS Response |
|---|---|
| *(paste here)* | {
    "status": true,
    "message": "",
    "data": {
        "id": 6132,
        "slug": "damian-dan-16",
        "first_name": "Damian123",
        "last_name": "Dan",
        "email": null,
        "phone": null,
        "title": "AI Agents & Automation Expert |  AI Software Architect & Consultant | Follow to learn: No-code AI Agents, Automation, and Business scaling tips.",
        "company": "Adaptify AI",
        "bio": "**Damian** – **AI Automation Expert & Founder of Adaptify AI**. Damian helps entrepreneurs and small to medium-sized businesses scale through AI agents, automation, and custom AI solutions. With a strong software engineering background, he designs practical systems that save time, increase revenue, and drive sustainable growth.",
        "industries": [
            {
                "id": "462",
                "name": "Artificial Intelligence"
            },
            {
                "id": "463",
                "name": "Business Automation"
            }
        ],
        "services": [],
        "need_services": [],
        "sociallinks": [],
        "social_links": [],
        "testimonials": [],
        "testimonials_is_enabled": 1,
        "logo": "http://localhost:3001/storage/card_logo/logo_17700919011440808261.jpg",
        "created_at": "2026 02 03 18:11:41",
        "updated_at": "2026 03 05 09:10:26",
        "total_view": 7,
        "total_scan": 0,
        "total_appointment": 0,
        "profile_qr": "http://localhost:3001/storage/profile_qr/damian-dan-16.png",
        "contact_qr": "http://localhost:3001/storage/contact_qr/damian-dan-16.png",
        "deeplink": "http://localhost:3001/profile/damian-dan-16",
        "is_owner": true,
        "request_status": "not_requested",
        "approved_at": null,
        "profile_url": "http://localhost:3001/profile/damian-dan-16",
        "hasPhysicalCard": false,
        "is_enable_appoinment": 1,
        "banner_img": null,
        "product_services": [
            {
                "id": 1,
                "title": "AI Automation",
                "link_title ": null,
                "description": "null",
                "purchase_link": null,
                "image": "img_17702758661176668849.jpg"
            },
            {
                "id": 2,
                "title": "AI Agents",
                "link_title ": null,
                "description": "null",
                "purchase_link": null,
                "image": "img_1770275866997710032.jpg"
            },
            {
                "id": 3,
                "title": "No-Code AI Solutions",
                "link_title ": null,
                "description": "null",
                "purchase_link": null,
                "image": "img_1770275866692337731.jpg"
            },
            {
                "id": 4,
                "title": "New Product",
                "link_title ": null,
                "description": "Product description...",
                "purchase_link": null,
                "image": "img_1770275866883377259.jpg"
            },
            {
                "id": 5,
                "title": "New Product",
                "link_title ": null,
                "description": "Product description...",
                "purchase_link": null,
                "image": "img_1770275866125832445.png"
            }
        ],
        "media": [
            {
                "id": 1,
                "title": "Featured Content",
                "link_title ": null,
                "description": null,
                "video_link": null,
                "image": "img_17702758661632236487.jpg"
            },
            {
                "id": 2,
                "title": null,
                "link_title ": null,
                "description": null,
                "video_link": null,
                "image": "img_1770275866440148064.jpg"
            },
            {
                "id": 3,
                "title": null,
                "link_title ": null,
                "description": null,
                "video_link": null,
                "image": "img_17702758661179288967.jpg"
            }
        ],
        "settings": {
            "phone_enable": "1",
            "zalo_enable": "1",
            "whatsapp_enable": "1"
        },
        "owner_id": 6946,
        "password": null,
        "enable_password": 0,
        "tags": [],
        "connected_id": null,
        "connected_name": null,
        "profiles_type": "web",
        "main_service": "- **Building AI agents** for workflow automation\r\n- **Delivering no-code AI** business solutions\r\n- **Developing custom AI systems** end-to-end\r\n- **Implementing AI frameworks** for scalable growth\r\n- **Optimizing operations** with intelligent automation\r\n- New service\r\n- New service",
        "key_strength": "- **Designing scalable AI systems** for business growth\r\n- **Automating complex workflows** with AI agents\r\n- **Bridging no-code and custom AI** solutions\r\n- **Translating business needs** into AI architectures\r\n- **Driving efficiency and revenue** through automation\r\n- New strength\r\n- New strength",
        "looking_for": {
            "tech-focus": "AI agents, automation",
            "company-size": [
                "Startup",
                "SME",
                "Scale-up"
            ],
            "ops-strategy": "Process Automation",
            "growth-target": "Scale SMBs",
            "target-market": [
                "Global",
                "APAC",
                "EU"
            ],
            "core-expertise": "AI automation",
            "engagement-model": "Project-based consulting"
        },
        "collaboration": {
            "ideal-role": [
                "Founder",
                "CEO",
                "Owner"
            ],
            "partner-types": [
                "Customer",
                "Tech Partner",
                "Strategic Partner"
            ],
            "organization-type": [
                "Startup",
                "SME",
                "Scale-up"
            ]
        }
    }
} |

**Expected shape (đầy đủ hơn getAll — bao gồm thêm):**
```json
{
  "status": true,
  "message": "",
  "data": {
    "id": 1,
    "slug": "nguyen-van-a",
    "first_name": "Nguyen",
    "last_name": "Van A",
    "profile_url": "APP_URL/profile/nguyen-van-a",
    "profile_qr": "APP_URL/storage/profile_qr/nguyen-van-a.png",
    "contact_qr": "APP_URL/storage/contact_qr/nguyen-van-a.png",
    "deeplink": "APP_URL/profile/nguyen-van-a",
    "banner_img": null,
    "sociallinks": [{"Facebook": "https://...", "id": 0}],
    "social_links": [{"Facebook": "https://...", "id": 0}],
    "industries": [{"id": "0", "name": "Agriculture"}],
    "services": [{"id": "0", "name": "Digital Marketing"}],
    "settings": {"phone_enable": 1, "zalo_enable": 1},
    "password": null,
    "enable_password": 0,
    "hasPhysicalCard": false,
    "is_enable_appoinment": 1,
    "approved_at": null,
    "connected_id": null,
    "connected_name": null,
    "testimonials_is_enabled": 1,
    "tags": [],
    "owner_id": 10,
    "is_my_card": true,
    "..."  : "..."
  }
}
```

**Diff / Notes:**
```
(ghi chú sự khác biệt ở đây)
```

---

### 4. POST /api/cards/update/:id — Cập nhật card

**curl:**
```bash
curl -X POST "http://localhost:3001/api/cards/update/1" \
  -H "Authorization: Bearer {{token}}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "first_name": "Nguyen",
    "last_name": "Van A Updated",
    "email": "updated@example.com",
    "phone": "0901234999",
    "bio": "Bio moi duoc cap nhat",
    "title": "Tech Lead",
    "company": "New Company Ltd",
    "social_link": {
      "Facebook": "https://facebook.com/updated",
      "LinkedIn": "https://linkedin.com/in/updated"
    },
    "settings": {
      "show_email": true,
      "show_phone": true
    }
  }'
```

> ⚠️ Method là **POST** (không phải PUT) — PHP behavior

| PHP Response | NestJS Response |
|---|---|
| *(paste here)* | {
    "status": true,
    "message": "Cập nhật danh thiếp thành công!",
    "data": {
        "id": 6142,
        "slug": "tran-van-b-2544",
        "first_name": "Nguyen",
        "last_name": "Van A Updated",
        "email": "updated@example.com",
        "phone": "0901234999",
        "title": "Tech Lead",
        "company": "New Company Ltd",
        "bio": "Bio mới được cập nhật",
        "industries": [],
        "services": [],
        "need_services": [],
        "sociallinks": [
            {
                "Facebook": "https://facebook.com/updated",
                "id": 0
            },
            {
                "LinkedIn": "https://linkedin.com/in/updated",
                "id": 1
            },
            {
                "Twitter": "",
                "id": 2
            }
        ],
        "testimonials": [],
        "logo": "http://localhost:3001/storage/card_logo/default_avatar.png",
        "created_at": "2026 03 05 09:13:21",
        "updated_at": "2026 03 05 09:16:32",
        "total_view": 0,
        "total_scan": 0,
        "total_appointment": 0,
        "is_owner": true,
        "request_status": "not_requested",
        "profile_url": "http://localhost:3001/tran-van-b-2544",
        "profiles_type": "mobile",
        "main_service": null,
        "key_strength": null,
        "looking_for": null,
        "collaboration": null,
        "product_services": [],
        "media": [],
        "settings": {
            "phone_enable": 1,
            "zalo_enable": 1,
            "whatsapp_enable": 1,
            "show_email": true,
            "show_phone": true
        }
    }
} |

**Expected shape (SUBSET — giống create, không có profile_qr, contact_qr, deeplink, banner_img, tags):**
```json
{
  "status": true,
  "message": "Cập nhật danh thiếp thành công!",
  "data": {
    "id": 1,
    "profile_url": "APP_URL/nguyen-van-a-updated",
    "..."  : "..."
  }
}
```

**Diff / Notes:**
```
- PHP KHÔNG kiểm tra ownership trong update — bất kỳ user login đều update được
- card_theme và theme_color luôn bị overwrite thành theme5 / color5-theme5
- matching_data bị reset về null
(ghi chú sự khác biệt ở đây)
```

---

### 5. POST /api/cards/banner/:id — Cập nhật banner

**curl:**
```bash
curl -X POST "http://localhost:3001/api/cards/banner/1" \
  -H "Authorization: Bearer {{token}}" \
  -H "Accept: application/json" \
  -F "banner_img=@/path/to/banner.jpg"
```

| PHP Response | NestJS Response |
|---|---|
| *(paste here)* | {
    "status": true,
    "message": "Cập nhật thành công",
    "data": {
        "banner_img": "http://localhost:3001/storage/banner_img/banner_6142.png"
    }
} |

**Expected shape:**
```json
{
  "status": true,
  "message": "Cập nhật thành công",
  "data": {
    "banner_img": "APP_URL/storage/banner_img/banner_1.png"
  }
}
```

**Diff / Notes:**
```
(ghi chú sự khác biệt ở đây)
```

---

### 6. POST /api/cards/link-card/:id — Liên kết thẻ NFC

**curl:**
```bash
curl -X POST "http://localhost:3001/api/cards/link-card/1" \
  -H "Authorization: Bearer {{token}}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "card_code": "NFC-ABC-12345"
  }'
```

| PHP Response | NestJS Response |
|---|---|
| *(paste here)* | *(paste here)* |

**Expected shape (success):**
```json
{
  "status": true,
  "message": "Liên kết thành công.",
  "data": { "...": "qrcode info" }
}
```

**Expected error (QR đã được link vào business khác):**
```json
{
  "status": false,
  "message": "Thẻ đã được liên kết. Vui lòng chọn thẻ khác.",
  "data": null
}
```

**Expected error (QR không tồn tại):**
```json
{
  "status": false,
  "message": "Mã code không tồn tại",
  "data": null
}
```

**Diff / Notes:**
```
(ghi chú sự khác biệt ở đây)
```

---

### 7. DELETE /api/cards/:id — Xóa card

**curl:**
```bash
curl -X DELETE "http://localhost:3001/api/cards/1" \
  -H "Authorization: Bearer {{token}}" \
  -H "Accept: application/json"
```

| PHP Response | NestJS Response |
|---|---|
| *(paste here)* | {
    "status": true,
    "message": "Xóa danh thiếp thành công!",
    "data": null
} |

**Expected shape:**
```json
{
  "status": true,
  "message": "Xóa danh thiếp thành công!",
  "data": null
}
```

**Expected error (không phải owner_id):**
```json
{
  "status": false,
  "message": "Thẻ không hợp lệ",
  "data": null
}
```

> ⚠️ PHP chỉ kiểm tra `owner_id = userId`, KHÔNG kiểm tra `created_by`

**Diff / Notes:**
```
(ghi chú sự khác biệt ở đây)
```

---

### 8. POST /api/check-card/:cardCode — Kiểm tra serial thẻ NFC

> ⚠️ Method là **POST** (không phải GET) — PHP behavior

**curl:**
```bash
curl -X POST "http://localhost:3001/api/check-card/NFC-ABC-12345" \
  -H "Authorization: Bearer {{token}}" \
  -H "Accept: application/json"
```

| PHP Response | NestJS Response |
|---|---|
| *(paste here)* |{
    "status": true,
    "message": "",
    "data": {
        "statusCode": 1,
        "profileId": 6141,
        "statusText": "Có profile"
    }
} |

**Expected shapes theo từng trạng thái:**
```json
// statusCode 1 — Has Profile (QR hoặc slug có business profile)
{ "status": true, "data": { "statusCode": 1, "profileId": 5, "statusText": "Has Profile" } }

// statusCode 2 — Card Available (thẻ tồn tại, chưa link cả business lẫn user)
{ "status": true, "data": { "statusCode": 2, "profileId": null, "statusText": "Card Available" } }

// statusCode 3 — Owned By Another (thẻ đã link vào user khác)
{ "status": true, "data": { "statusCode": 3, "profileId": null, "statusText": "Owned By Another" } }

// statusCode 4 — Owner No Profile (thẻ thuộc user này nhưng chưa có business)
{ "status": true, "data": { "statusCode": 4, "profileId": null, "statusText": "Owner No Profile" } }

// statusCode 5 — Has Account No Profile (unauthenticated: thẻ có user, không có business)
{ "status": true, "data": { "statusCode": 5, "profileId": null, "statusText": "Has Account No Profile" } }

// statusCode 6 — Unknown (thẻ không tồn tại, không có slug tương ứng)
{ "status": true, "data": { "statusCode": 6, "profileId": null, "statusText": "" } }
```

**Diff / Notes:**
```
(ghi chú sự khác biệt ở đây)
```

---

## Module 2: Appointments (`/api/appointments`)

---

### 9. GET /api/appointments — Lịch hẹn nhận được (chủ card)

**curl:**
```bash
curl -X GET "http://localhost:3001/api/appointments" \
  -H "Authorization: Bearer {{token}}" \
  -H "Accept: application/json"
```

| PHP Response | NestJS Response |
|---|---|
| *(paste here)* | {
    "status": true,
    "message": "",
    "data": [
        {
            "id": 542,
            "business_id": null,
            "name": null,
            "email": null,
            "phone": null,
            "date": "2025-09-17",
            "time": "09:00 10:00",
            "status": "accepted",
            "title": "Meeting with the Finance Department",
            "note": null,
            "user_requested": null,
            "google_calendar_id": "ntndaujlmnesuqbjagbq6jbakg",
            "created_by": 6946,
            "created_at": "2025 09 16 21:39:54",
            "updated_at": "2025 09 16 21:39:54",
            "business_name": ""
        }
    ]
} |

**Expected shape:**
```json
{
  "status": true,
  "message": "",
  "data": [
    {
      "id": 50,
      "businessId": 1,
      "name": "Tran Van B",
      "email": "tranvanb@example.com",
      "phone": "0912345678",
      "date": "2026-04-15",
      "time": "09:00",
      "note": "...",
      "title": "Tu van hop tac",
      "status": "pending",
      "createdBy": 10,
      "userRequested": 20,
      "googleCalendarId": null,
      "business_name": "Nguyen Van A",
      "createdAt": "...",
      "updatedAt": "..."
    }
  ]
}
```

> Query: `WHERE created_by=userId AND user_requested IS NULL`

**Diff / Notes:**
```
(ghi chú sự khác biệt ở đây)
```

---

### 10. GET /api/appointments?requested=1 — Lịch hẹn đã đặt (người đặt)

**curl:**
```bash
curl -X GET "http://localhost:3001/api/appointments?requested=1" \
  -H "Authorization: Bearer {{token}}" \
  -H "Accept: application/json"
```

| PHP Response | NestJS Response |
|---|---|
| *(paste here)* | {
    "status": true,
    "message": "",
    "data": []
}|

> Query: `WHERE user_requested=userId AND user_requested IS NOT NULL`

**Diff / Notes:**
```
(ghi chú sự khác biệt ở đây)
```

---

### 11. POST /api/appointments/add — Đặt lịch hẹn

**curl:**
```bash
curl -X POST "http://localhost:3001/api/appointments/add" \
  -H "Authorization: Bearer {{token}}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "card_id": 1,
    "name": "Tran Van B",
    "email": "tranvanb@example.com",
    "phone": "0912345678",
    "date": "2026-04-15",
    "time": "09:00",
    "title": "Tu van hop tac",
    "note": "Muon gap de thao luan du an moi"
  }'
```

> ⚠️ Field là `card_id` (không phải `business_id`)

| PHP Response | NestJS Response |
|---|---|
| *(paste here)* | {
    "status": true,
    "message": "Tạo lịch hẹn thành công!",
    "data": {
        "appointment": {
            "id": 589,
            "business_id": 6141,
            "name": "Tran Van B",
            "email": "tranvanb@example.com",
            "phone": "0912345678",
            "date": "2026-04-15",
            "time": "09:00",
            "status": "pending",
            "title": "Tư vấn hợp tác",
            "note": "Muốn gặp để thảo luận về dự án mới",
            "user_requested": 6946,
            "google_calendar_id": null,
            "created_by": 7704,
            "created_at": "2026 03 05 11:35:16",
            "updated_at": "2026 03 05 11:35:16"
        }
    }
} |

**Expected shape:**
```json
{
  "status": true,
  "message": "Tạo lịch hẹn thành công!",
  "data": {
    "appointment": {
      "id": 50,
      "businessId": 1,
      "name": "Tran Van B",
      "status": "pending",
      "createdBy": 10,
      "userRequested": 20,
      "..."  : "..."
    }
  }
}
```

**Expected error (card không tồn tại):**
```json
{
  "status": false,
  "message": "The khong hop le",
  "data": null
}
```

**Diff / Notes:**
```
- created_by = business.owner_id ?? business.created_by (KHÔNG phải auth userId)
- user_requested = auth userId (người đặt)
- status = 'pending' (luôn luôn)
- Tự động increment business.total_appointment
(ghi chú sự khác biệt ở đây)
```

---

### 12. GET /api/appointments/:id — Chi tiết lịch hẹn

**curl:**
```bash
curl -X GET "http://localhost:3001/api/appointments/50" \
  -H "Authorization: Bearer {{token}}" \
  -H "Accept: application/json"
```

| PHP Response | NestJS Response |
|---|---|
| *(paste here)* |{
    "status": true,
    "message": "",
    "data": {
        "id": 589,
        "business_id": 6141,
        "name": "Tran Van B",
        "email": "tranvanb@example.com",
        "phone": "0912345678",
        "date": "2026-04-15",
        "time": "09:00",
        "status": "pending",
        "title": "Tư vấn hợp tác",
        "note": "Muốn gặp để thảo luận về dự án mới",
        "user_requested": 6946,
        "google_calendar_id": null,
        "created_by": 7704,
        "created_at": "2026 03 05 11:35:16",
        "updated_at": "2026 03 05 11:35:16"
    }
} |

**Expected error (không phải chủ card):**
```json
{
  "status": false,
  "message": "Lich hen khong ton tai.",
  "data": null
}
```

> Query: `WHERE id=? AND created_by=userId`

**Diff / Notes:**
```
(ghi chú sự khác biệt ở đây)
```

---

### 13. POST /api/appointments/update/:id — Cập nhật lịch hẹn

**curl:**
```bash
curl -X POST "http://localhost:3001/api/appointments/update/50" \
  -H "Authorization: Bearer {{token}}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "Tran Van B Updated",
    "email": "updated@example.com",
    "phone": "0999999999",
    "date": "2026-04-20",
    "time": "14:00",
    "title": "Hop trien khai",
    "note": "Dia diem: van phong tang 3"
  }'
```

> ⚠️ Method là **POST** — PHP behavior

| PHP Response | NestJS Response |
|---|---|
| *(paste here)* | {
    "status": true,
    "message": "Cập nhật lịch hẹn thành công!",
    "data": {
        "appointment": {
            "id": 589,
            "business_id": 6141,
            "name": "Tran Van B Updated",
            "email": "updated@example.com",
            "phone": "0999999999",
            "date": "2026-04-20",
            "time": "14:00",
            "status": "pending",
            "title": "Họp triển khai",
            "note": "Địa điểm: văn phòng tầng 3",
            "user_requested": 6946,
            "google_calendar_id": null,
            "created_by": 7704,
            "created_at": "2026 03 05 11:35:16",
            "updated_at": "2026 03 05 12:00:20"
        }
    }
} |

**Expected shape:**
```json
{
  "status": true,
  "message": "Cập nhật lịch hẹn thành công!",
  "data": {
    "appointment": {
      "id": 50,
      "name": "Tran Van B Updated",
      "date": "2026-04-20",
      "time": "14:00",
      "status": "pending",
      "..."  : "..."
    }
  }
}
```

**Diff / Notes:**
```
- Cập nhật 7 fields: name, email, phone, date, time, title, note
- Chỉ chủ card (created_by = userId) mới update được
(ghi chú sự khác biệt ở đây)
```

---

### 14. POST /api/appointments/accept/:id — Chấp nhận lịch hẹn

**curl:**
```bash
curl -X POST "http://localhost:3001/api/appointments/accept/50" \
  -H "Authorization: Bearer {{token}}" \
  -H "Accept: application/json"
```

| PHP Response | NestJS Response |
|---|---|
| *(paste here)* |{
    "status": true,
    "message": "Cập nhật lịch hẹn thành công!",
    "data": {
        "appointment": {
            "id": 589,
            "business_id": 6141,
            "name": "Tran Van B Updated",
            "email": "updated@example.com",
            "phone": "0999999999",
            "date": "2026-04-20",
            "time": "14:00",
            "status": "accepted",
            "title": "Họp triển khai",
            "note": "Địa điểm: văn phòng tầng 3",
            "user_requested": 6946,
            "google_calendar_id": null,
            "created_by": 7704,
            "created_at": "2026 03 05 11:35:16",
            "updated_at": "2026 03 05 12:00:44"
        }
    }
} |

**Expected shape:**
```json
{
  "status": true,
  "message": "Cập nhật lịch hẹn thành công!",
  "data": {
    "appointment": {
      "id": 50,
      "status": "accepted",
      "..."  : "..."
    }
  }
}
```

**Diff / Notes:**
```
- Set status = 'accepted'
- Gửi FCM đến user_requested
- Xóa notifications liên quan (WHERE type LIKE '%Appointment%' AND data->id = id)
(ghi chú sự khác biệt ở đây)
```

---

### 15. POST /api/appointments/reject/:id — Từ chối lịch hẹn

**curl:**
```bash
curl -X POST "http://localhost:3001/api/appointments/reject/50" \
  -H "Authorization: Bearer {{token}}" \
  -H "Accept: application/json"
```

| PHP Response | NestJS Response |
|---|---|
| *(paste here)* | {
    "status": true,
    "message": "Cập nhật lịch hẹn thành công!",
    "data": {
        "appointment": {
            "id": 589,
            "business_id": 6141,
            "name": "Tran Van B Updated",
            "email": "updated@example.com",
            "phone": "0999999999",
            "date": "2026-04-20",
            "time": "14:00",
            "status": "rejected",
            "title": "Họp triển khai",
            "note": "Địa điểm: văn phòng tầng 3",
            "user_requested": 6946,
            "google_calendar_id": null,
            "created_by": 7704,
            "created_at": "2026 03 05 11:35:16",
            "updated_at": "2026 03 05 12:01:04"
        }
    }
} |

**Expected shape:**
```json
{
  "status": true,
  "message": "Cập nhật lịch hẹn thành công!",
  "data": {
    "appointment": {
      "id": 50,
      "status": "rejected",
      "..."  : "..."
    }
  }
}
```

**Diff / Notes:**
```
- Set status = 'rejected'
- Gửi FCM "hủy lịch hẹn" đến user_requested
- Xóa notifications (giống accept)
(ghi chú sự khác biệt ở đây)
```

---

### 16. POST /api/appointments/delete/:id — Xóa lịch hẹn

**curl:**
```bash
curl -X POST "http://localhost:3001/api/appointments/delete/50" \
  -H "Authorization: Bearer {{token}}" \
  -H "Accept: application/json"
```

> ⚠️ Method là **POST** (không phải DELETE) — PHP behavior

| PHP Response | NestJS Response |
|---|---|
| *(paste here)* | {
    "status": true,
    "message": "Xóa lịch hẹn thành công!",
    "data": null
} |

**Expected shape:**
```json
{
  "status": true,
  "message": "Xóa lịch hẹn thành công!",
  "data": null
}
```

**Diff / Notes:**
```
- Sau khi xóa: decrement business.total_appointment
- Chỉ chủ card (created_by = userId) mới xóa được
(ghi chú sự khác biệt ở đây)
```

---

## Module 3: Public Appointments (`/api/public-appointments`)

*(Không cần auth — dùng cho Google Calendar sync)*

---

### 17. POST /api/public-appointments/add

**curl:**
```bash
curl -X POST "http://localhost:3001/api/public-appointments/add" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "user_id": 10,
    "google_calendar_id": "abc123_google_event_id",
    "date": "2026-04-15",
    "time": "10:00",
    "title": "Google Calendar Event",
    "note": "Tao tu dong tu Google Calendar"
  }'
```

| PHP Response | NestJS Response |
|---|---|
| *(paste here)* | *(paste here)* |

**Expected shape:**
```json
{
  "status": true,
  "message": "Appointment created successfully!",
  "data": {
    "appointment": {
      "id": 99,
      "status": "accepted",
      "googleCalendarId": "abc123_google_event_id",
      "createdBy": 10,
      "..."  : "..."
    }
  }
}
```

> ⚠️ status = `'accepted'` (tự động — PHP behavior)

**Diff / Notes:**
```
(ghi chú sự khác biệt ở đây)
```

---

### 18. POST /api/public-appointments/update

**curl:**
```bash
curl -X POST "http://localhost:3001/api/public-appointments/update" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "user_id": 10,
    "google_calendar_id": "abc123_google_event_id",
    "date": "2026-04-20",
    "time": "11:00",
    "note": "Da cap nhat tu Google Calendar"
  }'
```

| PHP Response | NestJS Response |
|---|---|
| *(paste here)* | *(paste here)* |

**Expected shape:**
```json
{
  "status": true,
  "message": "Appointment updated successfully!",
  "data": {
    "appointment": {
      "id": 99,
      "status": "pending",
      "..."  : "..."
    }
  }
}
```

> ⚠️ status bị set = `'pending'` khi update (PHP behavior)

**Diff / Notes:**
```
(ghi chú sự khác biệt ở đây)
```

---

### 19. POST /api/public-appointments/delete

**curl:**
```bash
curl -X POST "http://localhost:3001/api/public-appointments/delete" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "user_id": 10,
    "google_calendar_id": "abc123_google_event_id"
  }'
```

| PHP Response | NestJS Response |
|---|---|
| *(paste here)* | *(paste here)* |

**Expected shape:**
```json
{
  "status": true,
  "message": "Appointment deleted successfully!",
  "data": null
}
```

**Diff / Notes:**
```
(ghi chú sự khác biệt ở đây)
```

---

## Error Cases

| # | Scenario | Expected |
|---|---|---|
| E1 | Gọi `/api/cards` không có token | HTTP 401 hoặc `{ status: false }` |
| E2 | POST `/api/cards` thiếu `first_name` | HTTP 400 BadRequest |
| E3 | POST `/api/cards` thiếu `last_name` | HTTP 400 BadRequest |
| E4 | DELETE `/api/cards/:id` — không phải `owner_id` | `{ status: false, message: 'Thẻ không hợp lệ' }` |
| E5 | DELETE `/api/cards/:id` — là `created_by` nhưng KHÔNG phải `owner_id` | `{ status: false }` — PHP chỉ check owner_id |
| E6 | POST `/api/appointments/add` thiếu `card_id` | HTTP 400 BadRequest |
| E7 | POST `/api/appointments/add` — `card_id` không tồn tại | `{ status: false, message: 'The khong hop le' }` |
| E8 | POST `/api/appointments/accept/:id` — không phải chủ card | `{ status: false, message: 'Lich hen khong ton tai.' }` |
| E9 | POST `/api/appointments/reject/:id` — không phải chủ card | `{ status: false, message: 'Lich hen khong ton tai.' }` |
| E10 | POST `/api/public-appointments/add` thiếu `user_id` | `{ status: false, message: 'User ID is required' }` |
| E11 | POST `/api/public-appointments/add` thiếu `google_calendar_id` | `{ status: false, message: 'Google Calendar ID is required' }` |
| E12 | POST `/api/check-card/INVALID-CODE` | `{ status: true, data: { statusCode: 6, profileId: null, statusText: '' } }` |
| E13 | POST `/api/cards/link-card/:id` — QR đã linked | `{ status: false, message: 'Thẻ đã được liên kết. Vui lòng chọn thẻ khác.' }` |

| Scenario | PHP Response | NestJS Response |
|---|---|---|
| E1 — No token | *(paste)* | *(paste)* |
| E2 — Thiếu first_name | *(paste)* | *(paste)* |
| E4 — Xóa không phải owner | *(paste)* | *(paste)* |
| E7 — card_id không tồn tại | *(paste)* | *(paste)* |
| E8 — Accept không phải chủ card | *(paste)* | *(paste)* |
| E10 — Thiếu user_id (public) | *(paste)* | *(paste)* |
| E12 — check-card code không tồn tại | *(paste)* | *(paste)* |
| E13 — link-card QR đã linked | *(paste)* | *(paste)* |

---

## Ghi chú chung về PHP behavior

| Điểm khác biệt | PHP | Ý nghĩa |
|---|---|---|
| Route prefix cards | `/api/cards` | Không phải `/api/businesses` |
| check-card method | `POST /api/check-card/:cardCode` | Không phải GET; **PUBLIC** (không cần auth) |
| scan tracking param | `?fromScan=1` | Không phải `?type=scan` |
| Update card method | `POST /api/cards/update/:id` | Không phải `PUT /api/cards/:id` |
| Delete appointment | `POST /api/appointments/delete/:id` | Không phải `DELETE /api/appointments/:id` |
| Create card — required | `first_name` + `last_name` | Không phải `title` |
| Create card — theme | Luôn `theme5` / `color5-theme5` | Set cả create lẫn update |
| Update card — industries field | Request dùng `industries` | Lưu vào DB column `category`; NestJS hỗ trợ cả `industries` lẫn `category` |
| Update card — ownership | Không kiểm tra | Bất kỳ user login đều update được |
| Update card — matching_data | Reset về null | Khi update bất kỳ field nào |
| Delete card — ownership | Chỉ check `owner_id` | Không check `created_by` |
| Add appointment — field | `card_id` | Không phải `business_id` |
| Add appointment — created_by | `business.owner_id ?? business.created_by` | Không phải auth userId |
| Add appointment — status | `pending` | Luôn luôn |
| Add public — status | `accepted` | Luôn luôn |
| Update public — status | `pending` | Luôn luôn set lại |
| profile_url index/detail | `APP_URL/profile/{slug}` | Có prefix `/profile/` |
| profile_url create/update | `APP_URL/{slug}` | Không có prefix `/profile/` |
| industries/services/need_services | `[{id, name}]` | PHP lưu `{"0":"name"}`, luôn transform |
| sociallinks | array of `{platform: url, id: index}` | Format PHP |
| social_links | same as sociallinks | NestJS thêm alias này |
| settings | object (parsed JSON) | NestJS parse sang object (tốt hơn PHP raw string) |
| banner response message | `"Cập nhật thành công"` | NestJS đã fix (trước đây trả `""`) |
| link-card response message | `"Liên kết thành công."` | NestJS đã fix (trước đây trả `""`) |
| Appointment messages | Có dấu tiếng Việt | `"Tạo lịch hẹn thành công!"` v.v. |
