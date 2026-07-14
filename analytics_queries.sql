-- ACS 261 Internet Connectivity Tracker: assessed SQL queries
USE connectivity_tracker;

-- Q1. Dashboard: number of reports by problem category (JOIN + GROUP BY).
SELECT c.category_name, COUNT(DISTINCT r.report_id) AS reports
FROM connectivity_reports AS r
JOIN report_category_assignments AS rca ON rca.report_id = r.report_id
JOIN incident_categories AS c ON c.category_id = rca.category_id
WHERE r.status <> 'rejected'
GROUP BY c.category_id, c.category_name
ORDER BY reports DESC, c.category_name;

-- Q2. Dashboard: locations with three or more reports (JOIN + GROUP BY + HAVING).
SELECT CONCAT(l.campus_name, ' — ', l.building_name, ': ', l.area_name) AS location,
       COUNT(*) AS reports,
       SUM(r.severity IN ('high', 'critical')) AS urgent_reports
FROM connectivity_reports AS r
JOIN locations AS l ON l.location_id = r.location_id
WHERE r.status NOT IN ('rejected', 'duplicate')
GROUP BY l.location_id, l.campus_name, l.building_name, l.area_name
HAVING COUNT(*) >= 3
ORDER BY reports DESC, urgent_reports DESC;

-- Q3. Dashboard: daily trend (uses View 2).
SELECT report_date, total_reports, urgent_reports, resolved_reports, avg_resolution_minutes
FROM vw_dashboard_daily_trends
ORDER BY report_date;

-- Q4. Dashboard: category/location heat map (uses View 1).
SELECT campus_name, building_name, area_name, category_name,
       report_count, urgent_report_count, average_download_mbps, average_latency_ms
FROM vw_dashboard_location_category
ORDER BY report_count DESC, urgent_report_count DESC;

-- Q5. Urgent open reports that need ICT attention (multiple WHERE conditions + JOIN).
SELECT r.report_id, r.reported_at, r.severity, r.status,
       l.building_name, l.area_name, r.description
FROM connectivity_reports AS r
JOIN locations AS l ON l.location_id = r.location_id
WHERE r.severity IN ('high', 'critical')
  AND r.status IN ('submitted', 'under_review')
  AND r.reported_at >= '2026-06-24'
ORDER BY r.severity DESC, r.reported_at ASC;

-- Q6. Average speed and latency by location, retaining only locations with measurements.
SELECT l.building_name, l.area_name,
       COUNT(r.report_id) AS measured_reports,
       ROUND(AVG(r.measured_download_mbps), 2) AS avg_download_mbps,
       ROUND(AVG(r.measured_latency_ms), 0) AS avg_latency_ms
FROM connectivity_reports AS r
JOIN locations AS l ON l.location_id = r.location_id
WHERE r.measured_download_mbps IS NOT NULL
  AND r.status NOT IN ('rejected', 'duplicate')
GROUP BY l.location_id, l.building_name, l.area_name
HAVING COUNT(r.report_id) >= 1
ORDER BY avg_download_mbps ASC;

-- Q7. Providers whose open high/critical reports exceed the overall average (subquery).
SELECT p.provider_name, COUNT(*) AS open_urgent_reports
FROM connectivity_reports AS r
JOIN service_providers AS p ON p.provider_id = r.provider_id
WHERE r.severity IN ('high', 'critical')
  AND r.status IN ('submitted', 'under_review')
GROUP BY p.provider_id, p.provider_name
HAVING COUNT(*) > (
    SELECT AVG(provider_report_count)
    FROM (
        SELECT COUNT(*) AS provider_report_count
        FROM connectivity_reports
        WHERE severity IN ('high', 'critical')
          AND status IN ('submitted', 'under_review')
        GROUP BY provider_id
    ) AS provider_averages
);

-- Q8. Reports that have no uploaded evidence (correlated subquery).
SELECT r.report_id, r.reported_at, r.severity, r.description
FROM connectivity_reports AS r
WHERE NOT EXISTS (
    SELECT 1 FROM evidence_files AS e WHERE e.report_id = r.report_id
)
ORDER BY r.reported_at;

-- Q9. Suspected/confirmed duplicates and the report they match (self-join).
SELECT df.duplicate_flag_id, df.review_status, df.match_score,
       newer.report_id AS flagged_report, newer.reported_at AS flagged_at,
       earlier.report_id AS matching_report, earlier.reported_at AS matching_at,
       df.flag_reason
FROM duplicate_flags AS df
JOIN connectivity_reports AS newer ON newer.report_id = df.flagged_report_id
JOIN connectivity_reports AS earlier ON earlier.report_id = df.matching_report_id
ORDER BY df.created_at DESC;

-- Q10. Resolution time per resolved report and its category (JOIN + calculation).
SELECT r.report_id, c.category_name, l.building_name, l.area_name,
       TIMESTAMPDIFF(MINUTE, r.reported_at, r.resolved_at) AS resolution_minutes
FROM connectivity_reports AS r
JOIN report_category_assignments AS rca ON rca.report_id = r.report_id
JOIN incident_categories AS c ON c.category_id = rca.category_id
JOIN locations AS l ON l.location_id = r.location_id
WHERE r.status = 'resolved'
  AND r.resolved_at IS NOT NULL
ORDER BY resolution_minutes DESC;

-- Q11. Participation channel, including anonymous reporting rate (aggregation).
SELECT report_channel, COUNT(*) AS total_reports,
       SUM(is_anonymous) AS anonymous_reports,
       ROUND(100 * AVG(is_anonymous), 1) AS anonymous_percentage
FROM connectivity_reports
GROUP BY report_channel
ORDER BY total_reports DESC;

-- Q12. Semester report: every category with its share of all valid reports (subquery).
SELECT c.category_name,
       COUNT(DISTINCT r.report_id) AS report_count,
       ROUND(100 * COUNT(DISTINCT r.report_id) /
             (SELECT COUNT(*) FROM connectivity_reports WHERE status <> 'rejected'), 1) AS share_percent
FROM incident_categories AS c
LEFT JOIN report_category_assignments AS rca ON rca.category_id = c.category_id
LEFT JOIN connectivity_reports AS r ON r.report_id = rca.report_id AND r.status <> 'rejected'
GROUP BY c.category_id, c.category_name
ORDER BY report_count DESC, c.category_name;

-- Optional workflow demonstration: resolve report 4 and save a resolution note.
-- CALL sp_resolve_report(4, 'ICT reset the access point and confirmed service restoration.');
