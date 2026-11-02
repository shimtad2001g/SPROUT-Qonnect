# SPROUT-Qonnect Integration

Tailoring Project SPROUT (GeoAI: zones, land cover, AGB, risk) into a
plot-indexed, EUDR-grade service layer consumable by the Qonnect
agricultural traceability platform.

## Structure
- 00_admin      : audit logs, step tracker, contracts
- 01_discovery  : Phase 0 schema alignment artifacts
- 02_database   : schema DDL, seed data, loaders
- 03_api        : FastAPI service layer
- 04_validation : geospatial compliance + model validation
- 05_rehearsal  : Qonnect -> SPROUT -> batch end-to-end demo
- 06_docs       : integration pack, sequence diagrams
- data/         : raw / interim / processed (git-ignored)
- logs/         : transcripts (git-ignored)

## Status
See 00_admin/STEP_TRACKER.md

## Live Demo
[View the Live TraceRight Dashboard](https://sprout-qonnect-clnhwfubq2y6y9bafzg.streamlit.app/)
