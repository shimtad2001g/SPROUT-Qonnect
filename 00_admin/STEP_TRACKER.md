# SPROUT-Qonnect - Build Tracker - COMPLETE

| # | Step | Status | Artifact |
|---|------|--------|----------|
| 1 | Environment audit + scaffold | DONE | 00_admin/environment_audit.csv |
| 2 | Phase 0 - Discovery & schema alignment | DONE | 01_discovery/ |
| 3 | Phase 1 - Database transformation | DONE | 02_database/ (SQLite) |
| 4 | Phase 2 - FastAPI service layer | DONE | 03_api/ (v0.9.1) |
| 5 | Phase 3 - Geospatial compliance hardening | DONE | 04_validation/ |
| 6 | Phase 4 - Qonnect/ECTMS integration rehearsal | DONE | 05_rehearsal/ |
| 7 | Phase 5 - Integration pack & Immediate Ask | DONE | 06_docs/ |

## All artifacts

### Discovery
- 01_discovery/00_alignment_contract.md
- 01_discovery/01_field_mapping.csv
- 01_discovery/02_eudr_geolocation_rules.md
- 01_discovery/03_qonnect_entity_model.md
- 01_discovery/04_open_questions.md

### Database
- 02_database/schema/01_schema_sqlite.sql
- 02_database/schema/01_schema_postgis.sql
- 02_database/scripts/load_seed.py
- 02_database/scripts/verify.py
- data/sprout.db

### API
- 03_api/app/main.py
- 03_api/app/services/eudr_validator.py
- 03_api/smoke_test.py
- 03_api/run_server.ps1
- 03_api/requirements.txt

### Validation
- 04_validation/sprout_geospatial_validation_report.md
- 04_validation/audit_seed_plots.csv
- 04_validation/audit_seed_plots.json
- 04_validation/calibration_status.json
- 04_validation/commingle_sim.json

### Rehearsal
- 05_rehearsal/scripts/pipeline.py
- 05_rehearsal/scripts/ectms_export.py
- 05_rehearsal/scripts/demo.py
- 05_rehearsal/scripts/latency_test.py
- 05_rehearsal/input/qonnect_sample_batch.json
- 05_rehearsal/output/pipeline_result.json
- 05_rehearsal/output/ectms_featurecollection.json
- 05_rehearsal/sequence_diagram.txt

### Integration pack
- 06_docs/SPROUT_Qonnect_Integration_Pack.md  (master index)
- 06_docs/00_executive_summary.md
- 06_docs/01_technical_capability.md
- 06_docs/02_immediate_ask.md
- 06_docs/03_demo_cheat_sheet.md

## Final status

All 7 phases complete. Integration pack delivered.
Ready for the Immediate Ask meeting with the TraceRight technical lead.

## Open items to track through the partnership

1. Forest classifier calibration (field survey required)
2. PostGIS migration (start Docker Desktop, re-run Step 3)
3. R2 precision enforcement in Qonnect client
4. R8 audit log write path
5. ECTMS API access (Ask 3)
6. Real Sentinel/GEDI inference (Phase 3 production upgrade)
7. Commercial model decision (Ask 2)
8. Inception meeting scheduling (Ask 5)

## The one command

    cd C:\SPROUT-Qonnect\05_rehearsal\scripts
    python demo.py