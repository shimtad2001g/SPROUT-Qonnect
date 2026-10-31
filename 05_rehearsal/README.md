# Phase 4 Rehearsal - Qonnect / ECTMS Integration

## What this demonstrates

The end-to-end flow from a Qonnect-shaped farm record to an
ECTMS-compatible GeoJSON FeatureCollection, exercising every SPROUT
endpoint defined in `01_discovery/00_alignment_contract.md`.

## How to run

From PowerShell, with the geospatial_auditor conda env active:

    cd C:\SPROUT-Qonnect\05_rehearsal\scripts
    python demo.py

For the latency benchmark:

    python latency_test.py

## Expected demo output

- 3 plot records processed
- 2 verified (PLT-GAMO-0001, PLT-GAMO-0002)
- 1 rejected (PLT-GAMO-0003, fails R5 area plausibility)
- Batch marked "partial" (correct behaviour)
- `output/ectms_featurecollection.json` ready for ECTMS submission

## What is NOT tested here

- Network latency (TestClient is in-process)
- ECTMS API authentication and rate limits (no ECTMS API access yet)
- Real Sentinel/GEDI inference (nearest-neighbour demo mode in API)
- Fabric chaincode integration (the consortium's DDS layer)

## Replacement rule

When real Qonnect data arrives:

1. Replace `input/qonnect_sample_batch.json` with the real export
2. No code change required - the pipeline reads the file and calls the same
   endpoints

When the real Sentinel/GEDI inference attaches in Phase 3:

1. Replace `_infer_*` functions in `03_api/app/main.py`
2. No change to the pipeline, the ECTMS exporter, or the API contract