# SPROUT-Qonnect Geospatial Validation Report

**Generated:** 2026-10-31T10:23:51+00:00
**Project:** Project SPROUT x TraceRight consortium
**Model version:** sprout-ssl-agb-v0.9
**Database engine:** SQLite (PostGIS migration pending Docker daemon)
**Status:** Internal draft for consortium review

---

## Executive Summary

Of the 3 seeded geometries, **2 passed all applicable EUDR rules** and **1 failed at least one**. Commingling simulation over 10 synthetic plots maintains internal aggregation consistency across all tested removal scenarios.

**Forest/agroforestry calibration is PENDING.** The current seed data has one example per land-cover class; precision and recall cannot be computed from it. A field survey (>=30 points per class) is the prerequisite. This report does NOT claim the forest classifier is calibrated.

---

## 1. Seed Geometry Audit (EUDR rules R3, R4, R5)

| Plot ID | Declared area | Rules passed | Rules failed | Verdict |
|---------|---------------|--------------|--------------|---------|
| PLT-GAMO-0001 | 1.2 ha | 4 | none | **PASS** |
| PLT-GAMO-0002 | 5.0 ha | 4 | none | **PASS** |
| PLT-GAMO-0003 | 2.0 ha | 3 | R5_area_plausible | **FAIL** |

### Failing plots â€” evidence

**PLT-GAMO-0003**
- `R5_area_plausible`: declared=2.000ha geodesic=1.226ha delta=38.7% (tolerance 5%)

---

## 2. Forest / Agroforestry Calibration Status

**Verdict: INSUFFICIENT_DATA**

| Class | Plots observed | Avg AGB (t/ha) |
|-------|----------------|----------------|
| agroforestry | 1 | 45.2 |
| forest | 1 | 120.5 |
| shrubland | 1 | 60.8 |

Minimum required per class: **30** (field-labelled). Deficit: **29** per class.

**Method when field data is available:**
- Stratified field survey: >=30 ground-truth points per class
- Confusion matrix computed against SPROUT landcover prediction
- Per-class precision and recall reported with 95% Wilson CI
- Forest flag threshold tuned on shade-coffee plots specifically
- Any plot with agroforestry landcover MUST return forest_flag=false

**Next action:** Defer calibration until field data collection; seed data is for pipeline verification only. Report to the consortium that calibration is PENDING, not complete.

---

## 3. Commingling Simulation

10 synthetic plots aggregated into a single batch; aggregation recomputed after partial-plot removal.

| Scenario | Plots remaining | Total area | Aggregated AGB | Worst risk | Consistent |
|----------|-----------------|------------|----------------|------------|------------|
| full_batch | 10 | 31.3328 ha | 2174.5046 t | 0.493 | YES |
| remove_first_3 | 7 | 21.9322 ha | 1599.862 t | 0.493 | YES |
| remove_last_5 | 5 | 15.6669 ha | 964.1164 t | 0.345 | YES |
| remove_random_4 | 8 | 25.0656 ha | 1569.1961 t | 0.493 | YES |

**Interpretation:** batch aggregation is a pure function of the current plot set; removing a subset (as happens when a batch is split or a plot is re-assigned) recalculates correctly. This is a necessary precondition for mass-balance provenance attribution under ECX-style commingling.

---

## 4. Deferred rules and known limitations

| Rule | Status | Reason |
|------|--------|--------|
| R1 (CRS) | Enforced | WGS84 assumed at API boundary via GeoJSON |
| R2 (6 decimal places) | Deferred | Cannot be enforced on parsed floats; belongs in the Qonnect client serialization spec |
| R3 (area rule) | Enforced | Tests cover point >4ha rejection |
| R4 (polygon validity) | Enforced | Ring closure, CCW, self-intersect |
| R5 (area plausibility) | Enforced | 5% declared-vs-geodesic tolerance |
| R6 (2020 baseline) | Data layer | Stored as column, not constant |
| R7 (response integrity) | Enforced | model_version + computed_at on every response |
| R8 (audit trail) | Partial | Validation_log table exists; write path not yet instrumented |


**Not verified by this report:**

- Real-world AGB model accuracy (seed data only)
- Forest vs shade-coffee classification correctness (pending field calibration)
- ECTMS batch identifier linkage (pending ECTMS API access)
- Polygon overlap / mass-balance attribution under real commingling

---

## 5. Sign-off checklist for the TraceRight technical lead

Items to verify before integrating SPROUT into the Fabric DDS pipeline:

- [ ] Confirm plot-level identifier exists in Qonnect (see Open Question Q1)
- [ ] Confirm ECTMS batch ID field name and API contract (Q2)
- [ ] Confirm farmer polygon consent regime (Q3)
- [ ] Review the R2 deferral â€” is the Qonnect client serialization guaranteed to produce 6 decimals?
- [ ] Review the R8 gap â€” who writes to validation_log in production?
- [ ] Review the calibration deferral â€” is PENDING acceptable for the first EUDR tranche, or is a field survey required before go-live?

---

*This report is a factual record of the SPROUT-Qonnect build state. It is not a compliance assertion. Legal EUDR compliance is the responsibility of the consortium's DDS layer.*