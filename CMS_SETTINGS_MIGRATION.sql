-- ============================================================
-- Migration: CMS Settings & Email Signatures
-- Description: Move ai-settings and email-signature from
--              file-based JSON storage to MySQL tables.
-- Run once on target DB before deploying new code.
-- ============================================================

-- ------------------------------------------------------------
-- Table 1: setting_ai_email (key-value store)
-- Stores global CMS settings (AI email config, etc.)
-- ------------------------------------------------------------
CREATE TABLE setting_ai_email (
  `key`      VARCHAR(100)  NOT NULL,
  value      LONGTEXT      NOT NULL,
  updated_at TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- Table 2: email_signatures
-- Stores multiple email signatures, one can be set as active.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS email_signatures (
  id         VARCHAR(36)   NOT NULL,
  label      VARCHAR(255)  NOT NULL DEFAULT '',
  name       VARCHAR(255)  NOT NULL DEFAULT '',
  title      VARCHAR(255)  NOT NULL DEFAULT '',
  company    VARCHAR(255)  NOT NULL DEFAULT '',
  phone      VARCHAR(100)  NOT NULL DEFAULT '',
  email      VARCHAR(255)  NOT NULL DEFAULT '',
  website    VARCHAR(500)  NOT NULL DEFAULT '',
  is_active  TINYINT(1)    NOT NULL DEFAULT 0,
  created_at TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- Seed: AI Email Settings (migrate từ data/ai-settings.json)
-- INSERT IGNORE = không ghi đè nếu đã có
-- ------------------------------------------------------------
INSERT IGNORE INTO setting_ai_email (`key`, value) VALUES (
  'ai_email_settings',
  '{"model":"gpt-4.1-mini","systemPrompt":"You are a professional email content writer. Your output will be converted from markdown to HTML for an email newsletter.\n\nDetect the language of the user''s prompt and write the email body in that same language.\n\n## Email Structure\n\nWrite the email body following this flow — adapt the sections naturally to fit the content:\n\n1. **Opening** — A warm, engaging sentence that states the purpose of the email. Bold the key phrase or announcement (1-2 sentences).\n2. **Body** — Present the main content. Use one or more of these patterns depending on context:\n   - **Bullet list** — When listing features, benefits, steps, or multiple points, use markdown bullet points (`- item`). Bold the lead keyword or phrase in each bullet.\n   - **Short paragraphs** — When explaining a single idea or telling a story, write 2-3 concise sentences. Bold the most important phrase in each paragraph.\n3. **Call to Action** — A clear, specific closing that tells the reader what to do next (1-2 sentences). Bold the action itself.\n\n## Formatting Rules\n\n- Use **markdown bold** (`**text**`) to highlight section headers, key phrases, important numbers, dates, or action items within sentences.\n- Use markdown bullet points (`- item`) when the content has 2 or more parallel ideas, features, benefits, or steps. Do NOT force bullets when the content flows better as prose.\n- Separate sections with a blank line.\n- Do NOT use headings (`#`, `##`). Do NOT use numbered lists. Only use bold and bullet points for formatting.\n- Do NOT output raw HTML tags — write only in markdown.\n\n## Content Rules\n\n- Tone: Professional yet friendly and conversational.\n- Be concise — the entire email should be readable in under 60 seconds.\n- Do NOT include a subject line in the output.\n- Do NOT add a sign-off or signature (e.g. \"Best regards\", \"Sincerely\") — the signature is handled separately.\n- Do NOT wrap the output in a code block or add any meta commentary.","subjectSystemPrompt":"You are an email subject line writer.\nDetect the language of the user''s prompt and write the subject line in that same language.\nOutput ONLY the subject line as plain text — no quotes, no punctuation at the end unless needed, no explanation.\nKeep it short (under 10 words ideally).\nMake it compelling — use action words, create curiosity, or highlight a clear benefit.","userPromptTemplate":"{input}"}'
);

-- ------------------------------------------------------------
-- Verify
-- ------------------------------------------------------------
SELECT `key`, LEFT(value, 80) AS value_preview, updated_at FROM setting_ai_email;
SELECT COUNT(*) AS signature_count FROM email_signatures;



-- Add from email into email_templates if not exists
ALTER TABLE email_templates
  ADD COLUMN from_name VARCHAR(191) NULL AFTER `from`;

UPDATE email_templates
  SET from_name = 'InCard'
  WHERE from_name IS NULL;

ALTER TABLE email_templates
  CHANGE COLUMN `from` `reply_to` VARCHAR(191) NULL

ALTER TABLE email_templates
  ADD COLUMN `from_email` VARCHAR(191) NULL
  AFTER `from_name`;