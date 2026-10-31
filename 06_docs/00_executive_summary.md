# SPROUT x TraceRight - Executive Summary

**Prepared for:** The TraceRight Satellite International Consortium
**Prepared by:** Shimeles Tadesse Zelelew (Project SPROUT)
**Date:** 2026-10-31
**Status:** Delivered for consortium review

---

## The Partnership in One Sentence

Project SPROUT supplies the plot-level geospatial verification layer that
feeds TraceRight's five-pillar platform - EUDR compliance, climate finance,
crop insurance, carbon trade, and the Qonnect marketplace - with
EUDR-grade, auditable spatial evidence that the consortium's ledger,
token, and DDS layers can rely on.

## What SPROUT Delivers

For every Qonnect farm polygon, SPROUT returns six attributes:

- sprout_zone            one of five Ethiopian ecological zones
- sprout_landcover       land-cover class
- sprout_forest_flag     boolean, EUDR forest gate
- sprout_agb_t_ha        above-ground biomass, tonnes per hectare
- sprout_agb_uncertainty +/- t/ha, required for carbon MRV
- sprout_risk_score      0.0 to 1.0 deforestation risk vs 2020 baseline

Every response carries model_version and computed_at - EUDR R7 compliance
is built in, not bolted on.

## What Has Been Built and Tested

- A live API (FastAPI, 7 endpoints) matching the alignment contract
  response envelope, tested end-to-end against 25 smoke-test assertions.
- EUDR rules enforced at the request boundary. R3 (area rule),
  R4 (polygon validity), and R5 (declared vs geodesic area within 5%)
  run on every request. Failed requests return HTTP 422 with a rule_id.
- A proven batch pipeline. Qonnect-shaped input -> 4 SPROUT endpoints
  per plot -> batch summary -> ECTMS-compatible GeoJSON FeatureCollection.
  Measured at 63 plots/second in-process.
- An auditable validation report (04_validation/) reporting what passes,
  what fails, what is pending, and what is deferred. Honest.
- A commingling simulation proving batch aggregation is a pure function
  of the current plot set - a necessary precondition for mass-balance
  provenance attribution under ECX-style commingling.

## What Remains Pending

- Forest/agroforestry classifier calibration is PENDING. Requires at
  least 30 field-labelled plots per land-cover class. Deficit: 29/class.
- R2 (6 decimal place precision) is deferred to the Qonnect client
  serialization spec - Python's float parsing cannot reliably detect
  decimal places on the wire.
- R8 (validation_log write path) exists as a table but is not yet
  instrumented. Production integration requires this to be live.
- ECTMS API access is not confirmed. The ECTMS batch ID field is
  nullable until it is.

## The Ask

See 02_immediate_ask.md - five specific requests to the TraceRight
technical lead, each with an evidence artifact attached.

## The Evidence

Every claim in this summary is reproducible. See
SPROUT_Qonnect_Integration_Pack.md for the navigation map.