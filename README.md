# Internet Connectivity Tracker — ACS 261

This submission package proposes a **Citizen-Generated Internet Connectivity Tracker** for Daystar University students. It turns individual reports of Wi-Fi and mobile-internet problems into structured evidence that the ICT Directorate and network providers can use.

## Contents

| File | Purpose |
|---|---|
| `ACS261_Internet_Connectivity_Tracker_Report.md` | Complete report covering the eight required components. |
| `database/schema.sql` | MySQL 8.0 database, constraints, two views, two triggers, and one stored procedure. |
| `database/seed_data.sql` | Clearly labelled fictional demonstration data (18 reports). |
| `database/analytics_queries.sql` | Twelve assessed SQL queries and instructions for producing dashboard data. |
| `dashboard/dashboard.html` | Stand-alone demonstration dashboard based on the seed data. |

## Quick setup (MySQL 8.0)

1. Open MySQL Workbench and run `database/schema.sql`.
2. Run `database/seed_data.sql`.
3. Run the queries in `database/analytics_queries.sql` individually.
4. Open `dashboard/dashboard.html` in a browser for the presentation mock-up.

The seed data is synthetic. It illustrates the system and must not be represented as actual student reports.
