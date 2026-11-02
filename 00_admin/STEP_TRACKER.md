# SPROUT-Qonnect - Build Tracker

| # | Step | Status | Artifact |
|---|------|--------|----------|
| 1 | Environment audit + scaffold | DONE | 00_admin/environment_audit.csv |
| 2 | Phase 0 - Discovery & schema alignment | DONE | 01_discovery/ |
| 3 | Phase 1 - Database transformation | DONE (pending endorsement) | 02_database/ |
| 4 | Phase 2 - FastAPI service layer | NOT STARTED | 03_api/ |
| 5 | Phase 3 - Geospatial compliance hardening | NOT STARTED | 04_validation/ |
| 6 | Phase 4 - Qonnect/ECTMS integration rehearsal | NOT STARTED | 05_rehearsal/ |
| 7 | Phase 5 - Integration pack & Immediate Ask | NOT STARTED | 06_docs/ |

## Step 3 artifacts

- 02_database/schema/01_schema_postgis.sql
- 02_database/schema/01_schema_sqlite.sql
- 02_database/scripts/load_seed.py
- 02_database/scripts/verify.py
- 00_admin/step3_engine.txt     (records which engine was used)
- data/sprout.db                (only if SQLite path ran)

## Known deviations

- PostGIS runs on port 5433 to avoid local conflicts.
- SQLite fallback stores geometry as WKT TEXT; migrate to PostGIS before Phase 3.