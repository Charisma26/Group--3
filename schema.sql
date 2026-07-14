-- ACS 261: Internet Connectivity Tracker
-- Target DBMS: MySQL 8.0+
-- Run this file before seed_data.sql and analytics_queries.sql.

DROP DATABASE IF EXISTS connectivity_tracker;
CREATE DATABASE connectivity_tracker
  CHARACTER SET utf8mb4
  -- utf8mb4_unicode_ci works in both MySQL 8 and the MariaDB version bundled with XAMPP.
  COLLATE utf8mb4_unicode_ci;
USE connectivity_tracker;

CREATE TABLE app_users (
    user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    university_email VARCHAR(254) NOT NULL UNIQUE,
    display_name VARCHAR(80) NOT NULL,
    user_role ENUM('student', 'moderator', 'ict_staff', 'administrator')
        NOT NULL DEFAULT 'student',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE locations (
    location_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    campus_name VARCHAR(80) NOT NULL,
    building_name VARCHAR(100) NOT NULL,
    area_name VARCHAR(100) NOT NULL,
    latitude DECIMAL(9,6) NULL,
    longitude DECIMAL(9,6) NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_location UNIQUE (campus_name, building_name, area_name),
    CONSTRAINT chk_coordinates CHECK (
        (latitude IS NULL AND longitude IS NULL)
        OR (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)
    )
) ENGINE=InnoDB;

CREATE TABLE service_providers (
    provider_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    provider_name VARCHAR(100) NOT NULL UNIQUE,
    provider_type ENUM('campus_ict', 'mobile_network', 'internet_service_provider')
        NOT NULL,
    contact_channel VARCHAR(150) NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE connection_types (
    connection_type_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    connection_name VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE incident_categories (
    category_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(80) NOT NULL UNIQUE,
    category_description VARCHAR(255) NOT NULL,
    default_priority ENUM('low', 'medium', 'high', 'critical') NOT NULL DEFAULT 'medium',
    is_active BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE connectivity_reports (
    report_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reporter_id BIGINT UNSIGNED NULL,
    location_id INT UNSIGNED NOT NULL,
    provider_id SMALLINT UNSIGNED NULL,
    connection_type_id TINYINT UNSIGNED NOT NULL,
    outage_started_at DATETIME NOT NULL,
    reported_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    severity ENUM('low', 'medium', 'high', 'critical') NOT NULL,
    description VARCHAR(1000) NOT NULL,
    measured_download_mbps DECIMAL(7,2) NULL,
    measured_latency_ms SMALLINT UNSIGNED NULL,
    report_channel ENUM('web', 'mobile_form', 'ussd', 'moderated_entry')
        NOT NULL DEFAULT 'web',
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    consent_to_use_aggregated_data BOOLEAN NOT NULL,
    status ENUM('submitted', 'under_review', 'resolved', 'rejected', 'duplicate')
        NOT NULL DEFAULT 'submitted',
    resolved_at DATETIME NULL,
    CONSTRAINT fk_reporter FOREIGN KEY (reporter_id)
        REFERENCES app_users (user_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_report_location FOREIGN KEY (location_id)
        REFERENCES locations (location_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_report_provider FOREIGN KEY (provider_id)
        REFERENCES service_providers (provider_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_report_connection FOREIGN KEY (connection_type_id)
        REFERENCES connection_types (connection_type_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_anonymous_reporter CHECK (
        (is_anonymous = TRUE AND reporter_id IS NULL)
        OR (is_anonymous = FALSE AND reporter_id IS NOT NULL)
    ),
    CONSTRAINT chk_report_times CHECK (reported_at >= outage_started_at),
    CONSTRAINT chk_measurements CHECK (
        (measured_download_mbps IS NULL OR measured_download_mbps >= 0)
        AND (measured_latency_ms IS NULL OR measured_latency_ms > 0)
    ),
    CONSTRAINT chk_resolution_time CHECK (
        resolved_at IS NULL OR resolved_at >= reported_at
    )
) ENGINE=InnoDB;

CREATE INDEX ix_report_dashboard
    ON connectivity_reports (location_id, provider_id, outage_started_at, status);
CREATE INDEX ix_report_status_time
    ON connectivity_reports (status, reported_at);

CREATE TABLE report_category_assignments (
    report_id BIGINT UNSIGNED NOT NULL,
    category_id SMALLINT UNSIGNED NOT NULL,
    assigned_by BIGINT UNSIGNED NULL,
    assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assignment_method ENUM('reporter', 'moderator', 'automatic') NOT NULL,
    PRIMARY KEY (report_id, category_id),
    CONSTRAINT fk_assignment_report FOREIGN KEY (report_id)
        REFERENCES connectivity_reports (report_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_assignment_category FOREIGN KEY (category_id)
        REFERENCES incident_categories (category_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_assignment_user FOREIGN KEY (assigned_by)
        REFERENCES app_users (user_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE evidence_files (
    evidence_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    report_id BIGINT UNSIGNED NOT NULL,
    uploaded_by BIGINT UNSIGNED NULL,
    storage_key VARCHAR(255) NOT NULL UNIQUE,
    file_type ENUM('photo', 'screenshot', 'document', 'speed_test') NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_size_bytes INT UNSIGNED NOT NULL,
    uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    moderation_status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    CONSTRAINT fk_evidence_report FOREIGN KEY (report_id)
        REFERENCES connectivity_reports (report_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_evidence_uploader FOREIGN KEY (uploaded_by)
        REFERENCES app_users (user_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_file_size CHECK (file_size_bytes > 0 AND file_size_bytes <= 10485760)
) ENGINE=InnoDB;

CREATE TABLE duplicate_flags (
    duplicate_flag_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    flagged_report_id BIGINT UNSIGNED NOT NULL,
    matching_report_id BIGINT UNSIGNED NOT NULL,
    match_score DECIMAL(5,2) NOT NULL,
    flag_reason VARCHAR(255) NOT NULL,
    review_status ENUM('pending', 'confirmed_duplicate', 'not_duplicate') NOT NULL DEFAULT 'pending',
    reviewed_by BIGINT UNSIGNED NULL,
    reviewed_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_flagged_report UNIQUE (flagged_report_id),
    CONSTRAINT chk_different_reports CHECK (flagged_report_id <> matching_report_id),
    CONSTRAINT chk_match_score CHECK (match_score BETWEEN 0 AND 100),
    CONSTRAINT fk_flagged_report FOREIGN KEY (flagged_report_id)
        REFERENCES connectivity_reports (report_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_matching_report FOREIGN KEY (matching_report_id)
        REFERENCES connectivity_reports (report_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_flag_reviewer FOREIGN KEY (reviewed_by)
        REFERENCES app_users (user_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE report_status_history (
    status_history_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    report_id BIGINT UNSIGNED NOT NULL,
    old_status ENUM('submitted', 'under_review', 'resolved', 'rejected', 'duplicate') NULL,
    new_status ENUM('submitted', 'under_review', 'resolved', 'rejected', 'duplicate') NOT NULL,
    changed_by BIGINT UNSIGNED NULL,
    change_note VARCHAR(500) NULL,
    changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_history_report FOREIGN KEY (report_id)
        REFERENCES connectivity_reports (report_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_history_user FOREIGN KEY (changed_by)
        REFERENCES app_users (user_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- View 1: main dashboard data by location and category.
CREATE VIEW vw_dashboard_location_category AS
SELECT
    l.campus_name,
    l.building_name,
    l.area_name,
    c.category_name,
    COUNT(DISTINCT r.report_id) AS report_count,
    SUM(r.severity IN ('high', 'critical')) AS urgent_report_count,
    ROUND(AVG(r.measured_download_mbps), 2) AS average_download_mbps,
    ROUND(AVG(r.measured_latency_ms), 0) AS average_latency_ms
FROM connectivity_reports AS r
JOIN locations AS l ON l.location_id = r.location_id
JOIN report_category_assignments AS rca ON rca.report_id = r.report_id
JOIN incident_categories AS c ON c.category_id = rca.category_id
WHERE r.status <> 'rejected'
GROUP BY l.location_id, c.category_id, l.campus_name, l.building_name, l.area_name, c.category_name;

-- View 2: daily trend and service-resolution performance.
CREATE VIEW vw_dashboard_daily_trends AS
SELECT
    DATE(r.reported_at) AS report_date,
    COUNT(*) AS total_reports,
    SUM(r.severity IN ('high', 'critical')) AS urgent_reports,
    SUM(r.status = 'resolved') AS resolved_reports,
    ROUND(AVG(CASE WHEN r.resolved_at IS NOT NULL
        THEN TIMESTAMPDIFF(MINUTE, r.reported_at, r.resolved_at) END), 1) AS avg_resolution_minutes
FROM connectivity_reports AS r
WHERE r.status <> 'rejected'
GROUP BY DATE(r.reported_at);

DELIMITER $$

-- Trigger 1: Every report starts with an auditable submitted status.
CREATE TRIGGER trg_report_created_history
AFTER INSERT ON connectivity_reports
FOR EACH ROW
BEGIN
    INSERT INTO report_status_history (report_id, old_status, new_status, change_note)
    VALUES (NEW.report_id, NULL, NEW.status, 'Report created');
END$$

-- Trigger 2: flag a likely duplicate when location, provider, connection type,
-- and report time match an active report within the preceding two hours.
CREATE TRIGGER trg_flag_likely_duplicate
AFTER INSERT ON connectivity_reports
FOR EACH ROW
BEGIN
    INSERT INTO duplicate_flags
        (flagged_report_id, matching_report_id, match_score, flag_reason)
    SELECT
        NEW.report_id,
        r.report_id,
        85.00,
        'Same location, provider and connection type reported within two hours'
    FROM connectivity_reports AS r
    WHERE r.report_id <> NEW.report_id
      AND r.location_id = NEW.location_id
      AND (r.provider_id = NEW.provider_id OR (r.provider_id IS NULL AND NEW.provider_id IS NULL))
      AND r.connection_type_id = NEW.connection_type_id
      AND r.reported_at BETWEEN DATE_SUB(NEW.reported_at, INTERVAL 2 HOUR) AND NEW.reported_at
      AND r.status <> 'rejected'
    ORDER BY r.reported_at DESC
    LIMIT 1;
END$$

-- Trigger 3: preserve every status change automatically.
CREATE TRIGGER trg_report_status_history
AFTER UPDATE ON connectivity_reports
FOR EACH ROW
BEGIN
    IF NEW.status <> OLD.status THEN
        INSERT INTO report_status_history (report_id, old_status, new_status, change_note)
        VALUES (NEW.report_id, OLD.status, NEW.status, 'Status changed through system workflow');
    END IF;
END$$

-- Stored procedure: used by a moderator/ICT workflow to close a report.
CREATE PROCEDURE sp_resolve_report (
    IN p_report_id BIGINT UNSIGNED,
    IN p_resolution_note VARCHAR(500)
)
BEGIN
    DECLARE v_rows_updated INT DEFAULT 0;

    UPDATE connectivity_reports
    SET status = 'resolved',
        resolved_at = COALESCE(resolved_at, CURRENT_TIMESTAMP)
    WHERE report_id = p_report_id
      AND status NOT IN ('rejected', 'duplicate');

    SET v_rows_updated = ROW_COUNT();
    IF v_rows_updated > 0 THEN
        UPDATE report_status_history
        SET change_note = p_resolution_note
        WHERE report_id = p_report_id
          AND new_status = 'resolved'
        ORDER BY status_history_id DESC
        LIMIT 1;
    END IF;
END$$

DELIMITER ;
