# Qonnect Entity Model - Working Reconstruction

This document records what is OBSERVED on the live Qonnect platform,
what is ASSUMED from the platform description, and what must be
CONFIRMED with the TraceRight team. Do not treat ASSUMED items as fact.

## Chain of entities

  Farmer Identity
      |
      v
  Digital Farm  ---- contains ---->  Plot (one or more)
      |                                  |
      |                                  v
      |                            Polygon boundary
      v
  Traceable Batch  <---- aggregates ---- Plot(s)
      |
      v
  Marketplace listing / escrow
      |
      v
  Buyer

## OBSERVED
- Digital farm record carries a GPS polygon boundary and verified hectares.
- Farms are described by zone, woreda, and GPS (example: Sinana, Bale, Oromia).
- Batches are QR-tagged with a code in the form QON-XXX-YYYY-NNNNN.
- A marketplace layer exists with escrow-style settlement.

## ASSUMED
- farm_id is a stable identifier; exact field name unknown.
- The polygon is stored as a GeoJSON geometry, not as a centroid.
- A batch references its source plots by some join list; exact structure unknown.
- Crop / commodity is a field on the farm record.

## TO CONFIRM WITH TRACERIGHT
1. Does a plot-level identifier exist, separate from farm_id?
2. Is the polygon stored at farm level, plot level, or both?
3. What is the exact batch-to-plot linkage structure?
4. Is there a farmer consent record, and what does it permit?
5. What identifier does ECTMS assign, and at which point in the chain?

## Consequence for SPROUT
If plots are not separately identified in Qonnect, SPROUT must either
derive plot_id deterministically (see Alignment Contract section 2) or
request that Qonnect add a plot entity. The second option is a product
change on their side and must be raised in the inception meeting.