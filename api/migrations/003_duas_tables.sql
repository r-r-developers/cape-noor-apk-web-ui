-- =============================================================================
-- Migration 003: Duas tables
-- =============================================================================
SET foreign_key_checks=0;

CREATE TABLE IF NOT EXISTS `duas_categories` (
    `id`      TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name_ar` VARCHAR(200) NOT NULL,
    `name_en` VARCHAR(200) NOT NULL,
    `icon`    VARCHAR(50)  DEFAULT NULL COMMENT 'Material icon name or emoji',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `duas` (
    `id`              SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `category_id`     TINYINT UNSIGNED  NOT NULL,
    `title_ar`        VARCHAR(500) DEFAULT NULL,
    `title_en`        VARCHAR(500) NOT NULL,
    `arabic`          TEXT         NOT NULL,
    `transliteration` TEXT         DEFAULT NULL,
    `translation`     TEXT         NOT NULL,
    `reference`       VARCHAR(500) DEFAULT NULL,
    `audio_url`       VARCHAR(500) DEFAULT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`category_id`) REFERENCES `duas_categories`(`id`) ON DELETE CASCADE,
    INDEX `idx_category` (`category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET foreign_key_checks=1;
