-- =============================================================================
-- Migration 002: App user tables (for Flutter app users — separate from admin)
-- =============================================================================
SET foreign_key_checks=0;

CREATE TABLE IF NOT EXISTS `app_users` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`          VARCHAR(255) NOT NULL,
    `email`         VARCHAR(255) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `is_active`     TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- JWT refresh tokens (covers both app_users and admin users)
CREATE TABLE IF NOT EXISTS `refresh_tokens` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`     INT UNSIGNED NOT NULL,
    `user_type`   ENUM('app_user','super_admin','mosque_admin','maintainer') NOT NULL DEFAULT 'app_user',
    `token_hash`  VARCHAR(128) NOT NULL UNIQUE COMMENT 'SHA-256 of the raw token',
    `expires_at`  DATETIME     NOT NULL,
    `revoked`     TINYINT(1)   NOT NULL DEFAULT 0,
    `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_token_hash` (`token_hash`),
    INDEX `idx_user` (`user_id`, `user_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Password resets for app users
CREATE TABLE IF NOT EXISTS `app_password_resets` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`    INT UNSIGNED NOT NULL,
    `token_hash` VARCHAR(128) NOT NULL UNIQUE COMMENT 'SHA-256 of the raw token',
    `expires_at` DATETIME     NOT NULL,
    `used`       TINYINT(1)   NOT NULL DEFAULT 0,
    `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`user_id`) REFERENCES `app_users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- FCM device tokens
CREATE TABLE IF NOT EXISTS `device_tokens` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `app_user_id` INT UNSIGNED DEFAULT NULL COMMENT 'NULL for anonymous devices',
    `token`       VARCHAR(500) NOT NULL UNIQUE,
    `platform`    ENUM('android','ios','web') NOT NULL DEFAULT 'android',
    `mosque_slug` VARCHAR(100) DEFAULT NULL,
    `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_mosque` (`mosque_slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Daily prayer logging
CREATE TABLE IF NOT EXISTS `prayer_logs` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `app_user_id` INT UNSIGNED NOT NULL,
    `date`        DATE         NOT NULL,
    `prayer`      ENUM('fajr','thuhr','asr','maghrib','isha') NOT NULL,
    `status`      ENUM('prayed','missed','qadha') NOT NULL DEFAULT 'prayed',
    `logged_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_log` (`app_user_id`, `date`, `prayer`),
    FOREIGN KEY (`app_user_id`) REFERENCES `app_users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Quran bookmarks
CREATE TABLE IF NOT EXISTS `quran_bookmarks` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `app_user_id` INT UNSIGNED NOT NULL,
    `surah`       TINYINT UNSIGNED NOT NULL,
    `ayah`        SMALLINT UNSIGNED NOT NULL,
    `note`        TEXT         DEFAULT NULL,
    `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_bookmark` (`app_user_id`, `surah`, `ayah`),
    FOREIGN KEY (`app_user_id`) REFERENCES `app_users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Per-user settings (key-value, JSON values)
CREATE TABLE IF NOT EXISTS `user_settings` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `app_user_id` INT UNSIGNED NOT NULL,
    `key`         VARCHAR(100) NOT NULL,
    `value`       TEXT         NOT NULL,
    `updated_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_user_key` (`app_user_id`, `key`),
    FOREIGN KEY (`app_user_id`) REFERENCES `app_users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET foreign_key_checks=1;
