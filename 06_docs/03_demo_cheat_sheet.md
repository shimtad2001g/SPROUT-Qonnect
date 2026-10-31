# Demo Cheat Sheet - For the Immediate Ask Meeting

## Before the meeting (5 minutes)

1. Open PowerShell
2. Activate the env if not already active:
       conda activate geospatial_auditor
3. Verify the demo works:
       cd C:\SPROUT-Qonnect\05_rehearsal\scripts
       python demo.py
4. Confirm the output shows:
   - "agb=45.2 +/- 8.1"  (not "A+-8.1" or a mojibake string)
   - One R5_area_plausible line for PLT-GAMO-0003 (not four)
   - PLT-GAMO-0003 total_ms under ~15ms (short-circuit active)
5. If any of those three are wrong, re-run step7a_fixes.ps1 - do not proceed.

## During the meeting

### 5-minute demo flow

**Minute 1 - Set the scene**
"The SPROUT API converts a Qonnect farm polygon into six EUDR-grade
spatial attributes in about 4 milliseconds per endpoint, on the same
database the consortium would use in production."

**Minutes 2-3 - Run the demo**

    cd C:\SPROUT-Qonnect\05_rehearsal\scripts
    python demo.py

Walk through the output:

- "Batch summary - 3 plots, 2 verified, 1 rejected, marked 'partial'"
- "PLT-GAMO-0003 was rejected because declared area (2.0ha) is 38.7%
  larger than the geodesic area (1.226ha). That is EUDR R5 catching a
  real data-entry error, not crashing."
- "ECTMS FeatureCollection has 3 features, 6-decimal coordinates,
  ready for EU TRACES submission."

**Minute 4 - Latency test (if asked)**

    python latency_test.py

"63 plots per second in-process. With network, expect 30-90 seconds
for a 1,000-plot batch."

**Minute 5 - The Ask**

Hand them the printed copy of 02_immediate_ask.md. Say:

"Five specific asks. Each has an evidence artifact attached. None is
open-ended."

### If they want to poke at the API live

    powershell -ExecutionPolicy Bypass -File C:\SPROUT-Qonnect\03_api\run_server.ps1

Then open http://127.0.0.1:8000/docs in a browser. Click any endpoint,
"Try it out", paste the sample polygon from the demo input file,
Execute.

## Anticipated questions and answers

**Q: Is the AGB model real?**
A: Not yet. Currently returns nearest-neighbour attribute from 3
seeded plots. The production Sentinel/GEDI model attaches to _infer_*
in app/main.py without changing the API contract. That is the Phase 3
upgrade task.

**Q: Is the forest classifier calibrated?**
A: No. The calibration report says so explicitly - verdict
INSUFFICIENT_DATA, deficit 29 labelled plots per class. This is
honest, not hidden. Field survey is on the roadmap.

**Q: What about the R2 precision check?**
A: Deferred to Qonnect's client serialization. Python floats cannot
reliably carry "6 decimal places" through JSON. Qonnect must produce
6-decimal GeoJSON at the boundary.

**Q: What if ECTMS refuses the GeoJSON?**
A: The format follows EU TRACES requirements as documented. When ECTMS
access is confirmed, we test against the real endpoint - that is Ask 3
in the letter.

**Q: What is the total time to full integration?**
A: Depends on Ask 4 (first target). For EU buyer: 4-6 weeks after ECTMS
access is shared. For carbon: 8-12 weeks (AGB validation more involved).
For insurance: 6-8 weeks.

**Q: Have you tested under real network conditions?**
A: No - TestClient is in-process. The 63-plots-per-second figure is the
application-layer ceiling; real HTTP adds round-trip time. Stated
explicitly in 01_technical_capability.md section 4.

## After the meeting

1. Note the answers to Ask 1-5 in 01_discovery/04_open_questions.md
2. Update 00_admin/STEP_TRACKER.md with the new status
3. Schedule the inception meeting