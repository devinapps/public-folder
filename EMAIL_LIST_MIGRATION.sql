-- Email List & is_can_test Migration
-- Date: 2026-03-12
-- Phase D: Email List Management
--
-- Run in order. Safe to re-run (uses IF NOT EXISTS / IF NOT COLUMN).
-- ──────────────────────────────────────────────────────────────────

-- ── Step 1: Add is_can_test to users ─────────────────────────────
-- Mark users as "test recipients" for campaign testing
ALTER TABLE users
ADD COLUMN is_can_test TINYINT(1) NOT NULL DEFAULT 0;
-- Add index for fast lookup of test users
ALTER TABLE users
ADD INDEX idx_users_can_test (is_can_test);

-- ── Step 2: Create email_lists table ─────────────────────────────
CREATE TABLE email_lists (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(255) NOT NULL,
  description TEXT NULL,
  tags        JSON DEFAULT (JSON_ARRAY()),
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_email_lists_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── Step 3: Create email_list_members table ───────────────────────
-- user_id is nullable: supports emails outside of the users table
CREATE TABLE email_list_members (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  list_id    INT NOT NULL,
  user_id    INT NULL,
  email      VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  UNIQUE KEY uq_list_email (list_id, email),
  INDEX idx_list_members_list (list_id),
  INDEX idx_list_members_user (user_id),

  CONSTRAINT fk_list_members_list
    FOREIGN KEY (list_id) REFERENCES email_lists(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── Verify ────────────────────────────────────────────────────────

-- Check is_can_test column added to users
SELECT
  COLUMN_NAME,
  COLUMN_TYPE,
  IS_NULLABLE,
  COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'users'
  AND TABLE_SCHEMA = DATABASE()
  AND COLUMN_NAME = 'is_can_test';

-- Check new tables exist
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN ('email_lists', 'email_list_members');

-- Describe new tables
DESCRIBE email_lists;
DESCRIBE email_list_members;

-- Quick sanity: count test users
SELECT
  COUNT(*) as total_users,
  SUM(is_can_test) as test_users
FROM users;
