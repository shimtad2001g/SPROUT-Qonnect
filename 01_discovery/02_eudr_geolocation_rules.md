# EUDR Geolocation Rules - SPROUT Enforcement Specification

Derived from Regulation (EU) 2023/1115 and the Information System
geolocation requirements. Every SPROUT geometry must pass all checks
below before it is stored or returned. Anything that fails is rejected
at ingestion, not corrected silently.

## R1 - Coordinate Reference System
WGS84 / EPSG:4326 only. Any other CRS is reprojected on receipt and the
reprojection is logged.

## R2 - Coordinate Precision
Minimum 6 decimal places for latitude and longitude. 6 decimals is
roughly 11 cm at the equator. Fewer decimals is a hard reject.

## R3 - Area Rule
  plots > 4 ha  ->  full polygon required
  plots <= 4 ha ->  single point accepted
Mixed submissions (a point claiming 8 ha) are rejected.

## R4 - Polygon Validity
  - ring must be closed (first vertex == last vertex)
  - exterior ring counter-clockwise
  - no self-intersection
  - no interior rings in v1
  - area computed geodesically, not in degrees

## R5 - Plausibility
  - the polygon must fall inside the country boundary of the declared origin
  - the declared area_ha must agree with the geometric area within 5%
  - the polygon must not overlap a previously registered plot by > 2%
    (overlap above threshold triggers a commingling review, not auto-reject)

## R6 - Temporal Baseline
Deforestation risk is assessed against the 31 December 2020 forest
baseline. SPROUT stores the baseline year as a column, not a constant,
so that a future regulatory change is a data update, not a code rewrite.

## R7 - Response Integrity
Every response carries model_version and computed_at. A spatial claim
without a version stamp is not usable as EUDR evidence.

## R8 - Audit Trail
Each validation run appends to a validation log: input hash, rule results,
pass/fail, timestamp. The log is the defensible record.