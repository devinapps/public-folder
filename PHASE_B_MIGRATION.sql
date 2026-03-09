-- Phase B Migration: Add Unique Constraint for Email Tracking Deduplication
-- This ensures opens are only counted once per email per campaign (prevents double-counting)
-- Clicks are allowed to have duplicates (users can click multiple times)

-- First, check if the unique constraint already exists
-- If email_tracking_events table already exists without the unique constraint, we need to add it

-- Drop existing constraint if it exists (use with caution in production!)
-- ALTER TABLE email_tracking_events DROP INDEX IF EXISTS idx_email_tracking_unique;

-- Add the unique constraint to prevent duplicate opens
-- This constraint ensures: (campaign_id, email, event_type) tuple is unique
-- So each email can only record one 'open' event per campaign
-- But can record multiple 'click' events
ALTER TABLE email_tracking_events
ADD CONSTRAINT idx_email_tracking_unique UNIQUE KEY (campaign_id, email, event_type);

-- Verify the constraint was added
SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_NAME = 'email_tracking_events'
AND CONSTRAINT_NAME = 'idx_email_tracking_unique';

-- Show table structure to verify
DESCRIBE email_tracking_events;

-- Show all indexes on the table
SHOW INDEXES FROM email_tracking_events;
