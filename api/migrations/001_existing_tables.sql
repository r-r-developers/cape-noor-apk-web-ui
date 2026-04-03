-- =============================================================================
-- Migration 001: Existing tables (kept from old application)
-- These already exist if migrating from old_application.
-- Run CREATE TABLE IF NOT EXISTS to be safe.
-- =============================================================================
SET foreign_key_checks=0;

CREATE TABLE IF NOT EXISTS `users` (
    `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `username`     VARCHAR(50)  NOT NULL UNIQUE,
    `email`        VARCHAR(255) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `role`         ENUM('super_admin','mosque_admin','maintainer') NOT NULL DEFAULT 'maintainer',
    `is_active`    TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mosques` (
    `id`                  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `slug`                VARCHAR(100)  NOT NULL UNIQUE,
    `short_id`            CHAR(3)       NOT NULL UNIQUE,
    `name`                VARCHAR(255)  NOT NULL,
    `logo`                VARCHAR(500)  DEFAULT NULL,
    `address`             VARCHAR(500)  DEFAULT NULL,
    `phone`               VARCHAR(50)   DEFAULT NULL,
    `website`             VARCHAR(500)  DEFAULT NULL,
    `show_fasting`        TINYINT(1)    NOT NULL DEFAULT 1,
    `show_sidebars`       TINYINT(1)    NOT NULL DEFAULT 1,
    `color_primary`       VARCHAR(20)   NOT NULL DEFAULT '#22c55e',
    `color_gold`          VARCHAR(20)   NOT NULL DEFAULT '#d4af37',
    `color_bg`            VARCHAR(20)   NOT NULL DEFAULT '#0a0f1a',
    `announcements`       JSON          DEFAULT NULL,
    `social_media`        JSON          DEFAULT NULL,
    `sponsors`            JSON          DEFAULT NULL,
    `facebook_page_id`    VARCHAR(100)  DEFAULT NULL,
    `facebook_page_name`  VARCHAR(255)  DEFAULT NULL,
    `facebook_access_token` TEXT        DEFAULT NULL,
    `auto_approve`        TINYINT(1)    NOT NULL DEFAULT 0,
    `is_default`          TINYINT(1)    NOT NULL DEFAULT 0,
    `adhan_offsets`       JSON          DEFAULT NULL,
    `created_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_mosques` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`     INT UNSIGNED NOT NULL,
    `mosque_slug` VARCHAR(100) NOT NULL,
    `can_approve` TINYINT(1)   NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_user_mosque` (`user_id`, `mosque_slug`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pending_changes` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `mosque_slug` VARCHAR(100) NOT NULL,
    `submitted_by` INT UNSIGNED NOT NULL,
    `changes`     JSON         NOT NULL,
    `status`      ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
    `reviewed_by` INT UNSIGNED DEFAULT NULL,
    `review_note` TEXT         DEFAULT NULL,
    `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `reviewed_at` DATETIME     DEFAULT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`submitted_by`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `password_resets` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`    INT UNSIGNED NOT NULL,
    `token`      VARCHAR(64)  NOT NULL UNIQUE,
    `expires_at` DATETIME     NOT NULL,
    `used`       TINYINT(1)   NOT NULL DEFAULT 0,
    `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `settings` (
    `key`        VARCHAR(100) NOT NULL,
    `value`      TEXT         DEFAULT NULL,
    `updated_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET foreign_key_checks=1;
