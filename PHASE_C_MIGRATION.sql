-- Phase C Migration: Email Scheduling Support
-- This migration adds indexes for efficient scheduled campaign queries
-- All required schema columns (scheduled_at, scheduled_payload, status) already exist in email_campaigns table

-- ── 2026-03-12: Add body column to email_campaigns ──────────────────────────
-- Stores the resolved email body at time of sending for campaign history/audit
ALTER TABLE email_campaigns
ADD COLUMN body LONGTEXT NULL AFTER subject;

-- ── 2026-03-13: Add multi-language body/subject columns ──────────────────────
-- Stores per-language content for campaigns sent with send_by_lang=true
ALTER TABLE email_campaigns
ADD COLUMN subject_vi TEXT NULL AFTER body,
ADD COLUMN body_vi LONGTEXT NULL AFTER subject_vi,
ADD COLUMN subject_en TEXT NULL AFTER body_vi,
ADD COLUMN body_en LONGTEXT NULL AFTER subject_en;

-- Verify email_campaigns table structure (should already have these from Phase A+B)
DESCRIBE email_campaigns;

-- Add index for fast lookup of scheduled campaigns (if not exists)
ALTER TABLE email_campaigns
ADD INDEX IF NOT EXISTS idx_email_campaigns_scheduled (status, scheduled_at);

-- Verify indexes were added
SHOW INDEXES FROM email_campaigns;

-- Verify the table has all required columns for Phase C
SELECT
  COLUMN_NAME,
  COLUMN_TYPE,
  IS_NULLABLE,
  COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'email_campaigns'
  AND TABLE_SCHEMA = DATABASE()
  AND COLUMN_NAME IN ('status', 'scheduled_at', 'scheduled_payload', 'created_at', 'updated_at')
ORDER BY ORDINAL_POSITION;

-- Quick sanity check: Count existing campaigns
SELECT
  COUNT(*) as total_campaigns,
  COUNT(DISTINCT status) as unique_statuses,
  MIN(created_at) as oldest_campaign,
  MAX(created_at) as newest_campaign
FROM email_campaigns;
