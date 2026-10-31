# SPROUT-Qonnect Alignment Contract

Version 1.0
Date: see toolchain_versions.txt
Owner: Shimeles Tadesse Zelelew (Project SPROUT)
Status: INTERNAL DRAFT - to be ratified with the TraceRight technical lead

## 1. Purpose

This memo freezes the technical handshake between Project SPROUT and the
Qonnect platform before any code is integrated. It defines the join key,
the attribute names, the geometry envelope, and the batch linkage rule.
Nothing in the API or database layer may contradict this document.

## 2. The Join Key

SPROUT currently keys on ecological zone name (Wurch, Dega, Weyna Dega,
Kolla, Bereha) and validation-zone geometry. Qonnect keys on farm record,
plot polygon, and batch code. These do not join.

DECISION - the join key is `plot_id`.

  a) If Qonnect exposes a plot-level identifier, we consume it verbatim.
  b) If Qonnect exposes only farm-level identity, we define:
         plot_id = first 16 hex chars of
                   SHA-256( farm_id || "|" || normalised_WKT(plot_ring) )
     The normalisation rule must be identical on both sides or the
     integration silently fails. Normalisation = WKT with coordinates
     rounded to 6 decimals, ring closed, counter-clockwise exterior.

OPEN - confirm whether Qonnect distinguishes a farm from a plot. A farm
may contain several plots; EUDR operates at plot level.

## 3. Attribute Names (frozen)

  sprout_zone              enum   Wurch | Dega | Weyna Dega | Kolla | Bereha
  sprout_landcover         enum   land-cover class from the SSL pipeline
  sprout_forest_flag       bool   true = forest per EUDR definition
  sprout_agb_t_ha          float  above-ground biomass, tonnes per hectare
  sprout_agb_uncertainty   float  +/- tonnes per hectare (required for MRV)
  sprout_risk_score        float  0.0 to 1.0, deforestation risk vs baseline

Null policy: an attribute that cannot be computed is returned as JSON null
with a companion `reason` string. It is never silently omitted.

## 4. Geometry Envelope

  Format      : GeoJSON (RFC 7946)
  CRS         : WGS84 / EPSG:4326
  Precision   : minimum 6 decimal places on every coordinate
  Area rule   : plots > 4 ha must be polygons; plots <= 4 ha may be points
  Polygon     : closed ring, counter-clockwise exterior, no self-intersection
  No holes    : rejected in v1; revisit if multi-parcel plots appear

Standard response wrapper:

  {
    "plot_id": "...",
    "geometry": { GeoJSON },
    "attributes": { sprout_zone, sprout_landcover, sprout_forest_flag,
                    sprout_agb_t_ha, sprout_agb_uncertainty,
                    sprout_risk_score },
    "model_version": "...",
    "computed_at": "ISO-8601 UTC"
  }

## 5. Batch Linkage

  GET  /v1/batch/{batch_code}          -> aggregated summary + per-plot list
  POST /v1/batch/verify                -> { batch_code, plot_ids[] } -> summary

Aggregated fields: total_area_ha, aggregated_agb_t, worst_case_risk_score,
plot_count, ectms_batch_id (nullable until ECTMS access is confirmed).

## 6. What SPROUT Does Not Do

  - does not register farmers or capture consent
  - does not replace ECTMS batch registration
  - does not mint carbon tokens or hold title
  - does not assert legal EUDR compliance; it supplies spatial evidence
    that the consortium's compliance layer may rely on

## 7. Ratification

Two signatures required: one SPROUT lead, one TraceRight technical lead.
Until signed, this document governs internal SPROUT development only.