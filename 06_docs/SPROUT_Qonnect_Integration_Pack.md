# SPROUT x TraceRight - Integration Pack

**Version:** 1.0
**Date:** 2026-10-31
**Owner:** Shimeles Tadesse Zelelew (Project SPROUT)
**Status:** Delivered for consortium review

---

## What this pack is

A self-contained evidence bundle demonstrating that Project SPROUT is
ready to integrate as the plot-level geospatial verification layer of
the TraceRight five-pillar platform. Every claim is reproducible from
the artifacts listed below.

## Contents

| # | Document | Purpose |
|---|---|---|
| 1 | 00_executive_summary.md | One-page overview for non-technical stakeholders |
| 2 | 01_technical_capability.md | Full technical spec, endpoint contract, gaps |
| 3 | 02_immediate_ask.md | Five specific asks in letter form |
| 4 | 03_demo_cheat_sheet.md | How to run the demo, anticipated Q&A |
| 5 | This file | Navigation and status |

## Supporting artifacts (outside this folder)

### Discovery & contract (Phase 0)
- 01_discovery/00_alignment_contract.md - the technical handshake to sign
- 01_discovery/01_field_mapping.csv - SPROUT -> Qonnect -> ECTMS field names
- 01_discovery/02_eudr_geolocation_rules.md - the R1-R8 rules
- 01_discovery/03_qonnect_entity_model.md - OBSERVED / ASSUMED / TO CONFIRM
- 01_discovery/04_open_questions.md - the 6 questions the meeting must answer

### Database (Phase 1)
- 02_database/schema/01_schema_sqlite.sql - current schema
- 02_database/schema/01_schema_postgis.sql - migration target
- data/sprout.db - the live SQLite database

### API (Phase 2)
- 03_api/app/main.py - the FastAPI application
- 03_api/app/services/eudr_validator.py - the R3/R4/R5 validator
- 03_api/smoke_test.py - 25-assertion end-to-end test
- 03_api/run_server.ps1 - local launch helper

### Validation (Phase 3)
- 04_validation/sprout_geospatial_validation_report.md - the audit report
- 04_validation/audit_seed_plots.csv - per-plot pass/fail
- 04_validation/calibration_status.json - pending status, deficit details
- 04_validation/commingle_sim.json - commingling consistency proof

### Demo (Phase 4)
- 05_rehearsal/scripts/demo.py - the one command that runs everything
- 05_rehearsal/input/qonnect_sample_batch.json - Qonnect-shaped input
- 05_rehearsal/output/ectms_featurecollection.json - ECTMS-ready output
- 05_rehearsal/sequence_diagram.txt - the flow diagram

### Build tracker
- 00_admin/STEP_TRACKER.md - all 7 steps, status, deviations

## Status at delivery

| Phase | Artifact | Status |
|---|---|---|
| 0 | Discovery & contract | DONE |
| 1 | Database (SQLite; PostGIS pending Docker) | DONE |
| 2 | FastAPI service layer | DONE (v0.9.1) |
| 3 | Geospatial compliance hardening | DONE (calibration PENDING) |
| 4 | Qonnect/ECTMS integration rehearsal | DONE |
| 5 | Integration pack | DONE (this document) |

## The one command

    cd C:\SPROUT-Qonnect\05_rehearsal\scripts
    python demo.py

Expected: 3 plots -> 2 verified, 1 rejected -> batch marked "partial"
-> ECTMS GeoJSON with 3 features -> "Ready for the Immediate Ask meeting."

## Known limitations (stated honestly)

1. AGB inference is demo mode (nearest-neighbour, not real Sentinel/GEDI).
2. Forest classifier calibration is PENDING (needs field data).
3. R2 precision check deferred to Qonnect client serialization.
4. R8 audit log write path not instrumented.
5. PostGIS migration pending (Docker daemon was offline during build).
6. ECTMS API access not confirmed (ectms_batch_id is nullable).

Each limitation is a specific integration task, not a hidden defect.

## Next actions for the consortium

See 02_immediate_ask.md - five specific asks, each with an evidence
artifact attached.