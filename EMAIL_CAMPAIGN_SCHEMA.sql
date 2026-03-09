-- Email Campaign Tables (Phase A)
-- Run these SQL statements directly on your database

-- Table: email_campaigns
CREATE TABLE IF NOT EXISTS email_campaigns (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  template_id INT,
  template_name VARCHAR(255),
  lang VARCHAR(10),
  recipient_mode VARCHAR(20) NOT NULL,
  subject TEXT,
  total INT DEFAULT 0,
  success INT DEFAULT 0,
  failed INT DEFAULT 0,
  failed_emails JSON DEFAULT (JSON_ARRAY()),
  open_count INT DEFAULT 0,
  click_count INT DEFAULT 0,
  status VARCHAR(20) DEFAULT 'sent',
  scheduled_at TIMESTAMP NULL,
  scheduled_payload JSON DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_email_campaigns_status (status),
  INDEX idx_email_campaigns_scheduled (scheduled_at, status)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table: email_unsubscribes
CREATE TABLE IF NOT EXISTS `email_unsubscribes` (
  `id` int AUTO_INCREMENT PRIMARY KEY,
  `email` varchar(255) NOT NULL UNIQUE,
  `reason` varchar(500),
  `unsubscribed_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE email_unsubscribes ADD COLUMN source VARCHAR(50) DEFAULT 'link';


-- Phase B table: Email Tracking Events
CREATE TABLE IF NOT EXISTS `email_tracking_events` (
  `id` int AUTO_INCREMENT PRIMARY KEY,
  `campaign_id` int NOT NULL,
  `email` varchar(255) NOT NULL,
  `event_type` varchar(20) NOT NULL,
  `url` text,
  `user_agent` text,
  `ip_address` varchar(45),
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_email_tracking_campaign (campaign_id),
  INDEX idx_email_tracking_event_type (event_type),
  UNIQUE INDEX idx_email_tracking_unique (campaign_id, email, event_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Verify tables created
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN ('email_campaigns', 'email_unsubscribes', 'email_tracking_events');
