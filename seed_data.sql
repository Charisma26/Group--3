-- Fictional demonstration data only. Do not present it as real student evidence.
USE connectivity_tracker;

INSERT INTO app_users (university_email, display_name, user_role) VALUES
('aisha.student@daystar.ac.ke', 'Aisha', 'student'),
('brian.student@daystar.ac.ke', 'Brian', 'student'),
('carol.moderator@daystar.ac.ke', 'Carol', 'moderator'),
('dan.ict@daystar.ac.ke', 'Dan', 'ict_staff');

INSERT INTO locations (campus_name, building_name, area_name, latitude, longitude) VALUES
('Main Campus', 'Agape Library', 'Library Wing', -1.455100, 36.959400),
('Main Campus', 'Hope Centre', 'Study Area', -1.455230, 36.959670),
('Main Campus', 'Amphitheater', 'Outside Entrance', -1.454850, 36.959100),
('Athi River Campus', 'Hostel A', 'Common Room', -1.456100, 36.960100),
('Main Campus', 'School of Business', 'Room B12', -1.454510, 36.959950),
('Main Campus', 'Hostel C', 'Laundry Area', -1.456400, 36.960700);

INSERT INTO service_providers (provider_name, provider_type, contact_channel) VALUES
('Daystar ICT', 'campus_ict', 'icthelpdesk@daystar.ac.ke'),
('Safaricom', 'mobile_network', 'Customer care'),
('Airtel Kenya', 'mobile_network', 'Customer care'),
('Telkom Kenya', 'mobile_network', 'Customer care');

INSERT INTO connection_types (connection_name) VALUES
('Campus Wi-Fi'), ('Mobile data'), ('Ethernet');

INSERT INTO incident_categories (category_name, category_description, default_priority) VALUES
('Complete outage', 'No usable internet connection is available.', 'critical'),
('Intermittent connection', 'Connection repeatedly drops or reconnects.', 'high'),
('Slow connection', 'Connection works but is too slow for normal academic tasks.', 'medium'),
('Login or captive portal failure', 'User cannot authenticate or accept the Wi-Fi portal.', 'high'),
('Weak or no coverage', 'Signal is too weak or absent in a location.', 'high');

-- is_anonymous = 1 is used only when reporter_id is NULL.
INSERT INTO connectivity_reports
    (reporter_id, location_id, provider_id, connection_type_id, outage_started_at,
     reported_at, severity, description, measured_download_mbps, measured_latency_ms,
     report_channel, is_anonymous, consent_to_use_aggregated_data, status, resolved_at)
VALUES
(1, 1, 1, 1, '2026-06-24 07:40:00', '2026-06-24 08:15:00', 'critical', 'Wi-Fi unavailable before morning study session.', NULL, NULL, 'web', 0, 1, 'resolved', '2026-06-24 11:20:00'),
(2, 2, 1, 1, '2026-06-24 12:00:00', '2026-06-24 12:25:00', 'high', 'Connection drops every few minutes in the study area.', 1.20, 310, 'mobile_form', 0, 1, 'under_review', NULL),
(NULL, 1, 1, 1, '2026-06-25 09:10:00', '2026-06-25 09:30:00', 'medium', 'Pages load very slowly near the library shelves.', 0.45, 480, 'web', 1, 1, 'resolved', '2026-06-25 14:10:00'),
(1, 2, 1, 1, '2026-06-25 14:30:00', '2026-06-25 14:45:00', 'high', 'Video lecture disconnects repeatedly.', 0.90, 365, 'mobile_form', 0, 1, 'submitted', NULL),
(2, 3, 2, 2, '2026-06-25 17:00:00', '2026-06-25 17:10:00', 'medium', 'Campus Wi-Fi unavailable outside and mobile data is used instead.', 3.50, 180, 'web', 0, 1, 'resolved', '2026-06-25 19:00:00'),
(NULL, 4, 1, 1, '2026-06-26 08:15:00', '2026-06-26 08:35:00', 'high', 'Hostel common room connection is too slow for coursework upload.', 0.30, 590, 'ussd', 1, 1, 'under_review', NULL),
(1, 5, 1, 1, '2026-06-26 10:00:00', '2026-06-26 10:10:00', 'critical', 'No Wi-Fi in Room B12 during class.', NULL, NULL, 'web', 0, 1, 'resolved', '2026-06-26 12:00:00'),
(2, 5, 1, 1, '2026-06-26 10:20:00', '2026-06-26 10:25:00', 'critical', 'Same Room B12 Wi-Fi outage observed by another student.', NULL, NULL, 'web', 0, 1, 'duplicate', NULL),
(NULL, 3, 1, 1, '2026-06-26 19:00:00', '2026-06-26 19:20:00', 'high', 'No Wi-Fi signal near the Amphitheater entrance.', NULL, NULL, 'mobile_form', 1, 1, 'submitted', NULL),
(1, 1, 1, 1, '2026-06-27 07:30:00', '2026-06-27 07:45:00', 'high', 'Library connection drops while downloading journal articles.', 1.10, 300, 'web', 0, 1, 'resolved', '2026-06-27 10:15:00'),
(2, 4, 1, 1, '2026-06-27 20:00:00', '2026-06-27 20:15:00', 'medium', 'Hostel common room speed is below 1 Mbps.', 0.70, 410, 'mobile_form', 0, 1, 'resolved', '2026-06-28 08:00:00'),
(NULL, 2, 1, 1, '2026-06-28 09:00:00', '2026-06-28 09:10:00', 'high', 'Study area Wi-Fi keeps reconnecting.', 0.85, 370, 'web', 1, 1, 'under_review', NULL),
(1, 1, 1, 1, '2026-06-28 11:00:00', '2026-06-28 11:15:00', 'medium', 'Captive portal rejects valid student login.', NULL, NULL, 'web', 0, 1, 'submitted', NULL),
(2, 3, 1, 1, '2026-06-28 16:30:00', '2026-06-28 16:40:00', 'critical', 'Complete Wi-Fi outage near the Amphitheater before an event.', NULL, NULL, 'mobile_form', 0, 1, 'resolved', '2026-06-28 18:45:00'),
(NULL, 2, 1, 1, '2026-06-28 21:00:00', '2026-06-28 21:20:00', 'high', 'Repeated disconnections during group assignment work.', 1.00, 330, 'ussd', 1, 1, 'under_review', NULL),
(1, 1, 1, 1, '2026-06-29 08:00:00', '2026-06-29 08:10:00', 'medium', 'Downloads are very slow in the library wing.', 0.55, 455, 'web', 0, 1, 'resolved', '2026-06-29 12:30:00'),
(2, 4, 1, 1, '2026-06-29 18:00:00', '2026-06-29 18:15:00', 'high', 'Weak Wi-Fi signal in Hostel A common room.', NULL, NULL, 'mobile_form', 0, 1, 'submitted', NULL),
(NULL, 2, 1, 1, '2026-06-29 22:00:00', '2026-06-29 22:10:00', 'high', 'Connection drops during online revision.', 0.95, 340, 'web', 1, 1, 'submitted', NULL);

INSERT INTO report_category_assignments (report_id, category_id, assigned_by, assignment_method) VALUES
(1, 1, 3, 'moderator'), (2, 2, 3, 'moderator'), (3, 3, 3, 'moderator'),
(4, 2, 3, 'moderator'), (5, 4, 3, 'moderator'), (6, 3, 3, 'moderator'),
(7, 1, 3, 'moderator'), (8, 1, 3, 'automatic'), (9, 5, 3, 'moderator'),
(10, 2, 3, 'moderator'), (11, 3, 3, 'moderator'), (12, 2, 3, 'moderator'),
(13, 4, 3, 'moderator'), (14, 1, 3, 'moderator'), (15, 2, 3, 'moderator'),
(16, 3, 3, 'moderator'), (17, 5, 3, 'moderator'), (18, 2, 3, 'moderator');

INSERT INTO evidence_files
    (report_id, uploaded_by, storage_key, file_type, mime_type, file_size_bytes, moderation_status)
VALUES
(3, NULL, 'demo/2026/06/25/speedtest-report-3.png', 'speed_test', 'image/png', 352140, 'approved'),
(10, 1, 'demo/2026/06/27/speedtest-report-10.png', 'screenshot', 'image/png', 412800, 'approved'),
(13, 1, 'demo/2026/06/28/login-portal-report-13.jpg', 'photo', 'image/jpeg', 502100, 'pending');

-- Confirm the automatically raised sample flag for report 8.
UPDATE duplicate_flags
SET review_status = 'confirmed_duplicate', reviewed_by = 3, reviewed_at = '2026-06-26 10:35:00'
WHERE flagged_report_id = 8;
