-- ============================================================
-- SENDER_GROUP_MIGRATION.sql
-- Tạo bảng sender_groups cho tính năng Sender Group
-- Database: stage1_incard_biz
-- Ngày: 2026-04-01
-- Chạy: mysql -u <user> -p stage1_incard_biz < SENDER_GROUP_MIGRATION.sql
-- ============================================================

-- Tạo bảng sender_groups
CREATE TABLE IF NOT EXISTS `sender_groups` (
  `id`            VARCHAR(36)   NOT NULL,
  `label`         VARCHAR(255)  NOT NULL,
  `from_name`     VARCHAR(255)  NOT NULL,
  `from_email`    VARCHAR(255)  NULL DEFAULT NULL,
  `reply_to`      VARCHAR(255)  NULL DEFAULT NULL,
  `signature_id`  VARCHAR(36)   NOT NULL,
  `is_default`    TINYINT(1)    NOT NULL DEFAULT 0,
  `created_at`    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  -- Đảm bảo chỉ 1 row is_default = 1 (enforce ở application layer,
  -- index này hỗ trợ query nhanh khi tìm default group)
  KEY `idx_sender_groups_is_default` (`is_default`),
  KEY `idx_sender_groups_signature_id` (`signature_id`),
  CONSTRAINT `fk_sender_groups_signature`
    FOREIGN KEY (`signature_id`)
    REFERENCES `email_signatures` (`id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Verify
SELECT 'sender_groups table created successfully' AS status;
DESCRIBE `sender_groups`;
