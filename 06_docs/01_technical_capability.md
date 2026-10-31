# SPROUT - Technical Capability Statement

**For:** TraceRight technical lead
**From:** Shimeles Tadesse Zelelew
**Version:** 0.9.1 (API) / sprout-ssl-agb-v0.9 (model)
**Date:** 2026-10-31

---

## 1. Endpoint Contract

All endpoints enforce the alignment contract response envelope
(01_discovery/00_alignment_contract.md):

    {
      "plot_id": "...",
      "attributes": { six sprout_* fields },
      "validation": { "rules_passed": [...], "rules_failed": [...],
                      "confidence": 0.0-1.0 },
      "model_version": "sprout-ssl-agb-v0.9",
      "computed_at": "ISO-8601 UTC",
      "reason": "nearest_neighbour_demo_mode"
    }

Endpoint inventory:

    /v1/zone      POST   polygon + area_ha -> sprout_zone
    /v1/landcover POST   polygon          -> sprout_landcover, forest_flag
    /v1/agb       POST   polygon + area_ha -> agb_t_ha, agb_uncertainty
    /v1/risk      POST   polygon + year   -> sprout_risk_score
    /v1/batch/{code} GET                  -> aggregated batch summary
    /v1/health    GET                     -> status, plot_count, engine
    /v1/schema    GET                     -> OpenAPI JSON

Interactive documentation at /docs when run locally.

## 2. EUDR Validation Enforced at Boundary

    R1 - CRS is WGS84                          Assumed at API boundary
    R2 - 6 decimal precision                   DEFERRED to Qonnect client
    R3 - Area rule (>4ha polygon, <=4ha point) ENFORCED (422 R3_area_rule)
    R4 - Polygon validity (closed, CCW)        ENFORCED (422 R4_*)
    R5 - Declared vs geodesic area <=5%        ENFORCED (422 R5_area_plausible)
    R6 - 2020 baseline as data, not constant   Stored as column
    R7 - model_version + computed_at on all    ENFORCED (response envelope)
    R8 - Audit trail                           Table exists, write path pending

## 3. Batch Pipeline

Input: a Qonnect-shaped farm/plot JSON
(05_rehearsal/input/qonnect_sample_batch.json).

Flow: for every plot -> 4 SPROUT calls -> verified/rejected/no_coverage ->
batch aggregation -> ECTMS FeatureCollection.

Rejection semantics: a geometry that fails R3, R4, or R5 SHORT-CIRCUITS
remaining endpoint calls (validation is geometry-level, not endpoint-level).
The plot is recorded as rejected with its rule failures. The batch is
marked "partial", never silently dropped.

Output: 05_rehearsal/output/ectms_featurecollection.json - a GeoJSON
FeatureCollection ready for EU TRACES submission, with 6-decimal
coordinates and all SPROUT attributes as properties.

## 4. Measured Performance (Step 6 Rehearsal)

Latency measured via FastAPI TestClient (in-process; network excluded):

    Endpoint       p50       p95      max
    /v1/zone       3.67 ms   7.59 ms  22.99 ms
    /v1/landcover  3.48 ms   7.76 ms  10.31 ms
    /v1/agb        3.46 ms   7.58 ms   9.75 ms
    /v1/risk       3.47 ms   7.54 ms   8.51 ms

50 plots x 4 endpoints = 200 calls in 799 ms. Throughput: 63 plots/s.

Network, TLS, and Fabric latency are NOT included. For a 1,000-plot
batch under real HTTP, expect 30-90 seconds end-to-end depending on RTT.

## 5. Demo Command

    cd C:\SPROUT-Qonnect\05_rehearsal\scripts
    python demo.py

Expected output: 3 plots processed (2 verified, 1 rejected), batch
marked "partial", ECTMS FeatureCollection with 3 features, elapsed ~200ms.

## 6. Known Gaps (Stated Honestly)

1. AGB model is demo-mode. _infer_* returns nearest-neighbour attribute
   from seeded plots, not real Sentinel/GEDI inference. When production
   attaches, only _infer_* changes; the API contract does not.
2. Calibration pending. See 04_validation/calibration_status.json.
   Deficit 29 labelled plots per class.
3. R2 precision check deferred. Must be enforced in Qonnect's
   serialization layer, not in Python floats on the wire.
4. R8 audit log not instrumented. Table exists; writes need wiring.
5. PostGIS migration pending. Currently SQLite (Docker daemon was offline
   during build). Migration requires no code change to the API.
6. ECTMS API access not confirmed. ectms_batch_id is nullable.

Each of these gaps is a specific integration task, not a hidden defect.

## 7. What SPROUT Does Not Do

- Does not register farmers or capture consent
- Does not replace ECTMS batch registration
- Does not mint carbon tokens or hold title
- Does not assert legal EUDR compliance; supplies spatial evidence that
  the consortium's DDS layer may rely on