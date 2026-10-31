# =====================================================================
# SPROUT-Qonnect | STEP 7c: Final docs + tracker + artifact tree
# =====================================================================
$ErrorActionPreference = 'Continue'
$ROOT = 'C:\SPROUT-Qonnect'
$DOCS = Join-Path $ROOT '06_docs'
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
Start-Transcript -Path (Join-Path $ROOT "logs\step7c_$stamp.log") -Force | Out-Null

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

# --- 7c.1 demo cheat sheet -----------------------------------------
Write-Host "=== 7c.1 DEMO CHEAT SHEET ===" -ForegroundColor Cyan
$cheat = @'
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
'@
Write-Utf8NoBom -Path (Join-Path $DOCS '03_demo_cheat_sheet.md') -Text $cheat
Write-Host "03_demo_cheat_sheet.md written"

# --- 7c.2 master index ----------------------------------------------
Write-Host "`n=== 7c.2 MASTER INDEX ===" -ForegroundColor Cyan
$master = @'
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
'@
Write-Utf8NoBom -Path (Join-Path $DOCS 'SPROUT_Qonnect_Integration_Pack.md') -Text $master
Write-Host "SPROUT_Qonnect_Integration_Pack.md written"

# --- 7c.3 final tracker ---------------------------------------------
Write-Host "`n=== 7c.3 FINAL TRACKER ===" -ForegroundColor Cyan
$tracker = @'
# SPROUT-Qonnect - Build Tracker - COMPLETE

| # | Step | Status | Artifact |
|---|------|--------|----------|
| 1 | Environment audit + scaffold | DONE | 00_admin/environment_audit.csv |
| 2 | Phase 0 - Discovery & schema alignment | DONE | 01_discovery/ |
| 3 | Phase 1 - Database transformation | DONE | 02_database/ (SQLite) |
| 4 | Phase 2 - FastAPI service layer | DONE | 03_api/ (v0.9.1) |
| 5 | Phase 3 - Geospatial compliance hardening | DONE | 04_validation/ |
| 6 | Phase 4 - Qonnect/ECTMS integration rehearsal | DONE | 05_rehearsal/ |
| 7 | Phase 5 - Integration pack & Immediate Ask | DONE | 06_docs/ |

## All artifacts

### Discovery
- 01_discovery/00_alignment_contract.md
- 01_discovery/01_field_mapping.csv
- 01_discovery/02_eudr_geolocation_rules.md
- 01_discovery/03_qonnect_entity_model.md
- 01_discovery/04_open_questions.md

### Database
- 02_database/schema/01_schema_sqlite.sql
- 02_database/schema/01_schema_postgis.sql
- 02_database/scripts/load_seed.py
- 02_database/scripts/verify.py
- data/sprout.db

### API
- 03_api/app/main.py
- 03_api/app/services/eudr_validator.py
- 03_api/smoke_test.py
- 03_api/run_server.ps1
- 03_api/requirements.txt

### Validation
- 04_validation/sprout_geospatial_validation_report.md
- 04_validation/audit_seed_plots.csv
- 04_validation/audit_seed_plots.json
- 04_validation/calibration_status.json
- 04_validation/commingle_sim.json

### Rehearsal
- 05_rehearsal/scripts/pipeline.py
- 05_rehearsal/scripts/ectms_export.py
- 05_rehearsal/scripts/demo.py
- 05_rehearsal/scripts/latency_test.py
- 05_rehearsal/input/qonnect_sample_batch.json
- 05_rehearsal/output/pipeline_result.json
- 05_rehearsal/output/ectms_featurecollection.json
- 05_rehearsal/sequence_diagram.txt

### Integration pack
- 06_docs/SPROUT_Qonnect_Integration_Pack.md  (master index)
- 06_docs/00_executive_summary.md
- 06_docs/01_technical_capability.md
- 06_docs/02_immediate_ask.md
- 06_docs/03_demo_cheat_sheet.md

## Final status

All 7 phases complete. Integration pack delivered.
Ready for the Immediate Ask meeting with the TraceRight technical lead.

## Open items to track through the partnership

1. Forest classifier calibration (field survey required)
2. PostGIS migration (start Docker Desktop, re-run Step 3)
3. R2 precision enforcement in Qonnect client
4. R8 audit log write path
5. ECTMS API access (Ask 3)
6. Real Sentinel/GEDI inference (Phase 3 production upgrade)
7. Commercial model decision (Ask 2)
8. Inception meeting scheduling (Ask 5)

## The one command

    cd C:\SPROUT-Qonnect\05_rehearsal\scripts
    python demo.py
'@
Write-Utf8NoBom -Path (Join-Path $ROOT '00_admin\STEP_TRACKER.md') -Text $tracker
Write-Host "STEP_TRACKER.md updated (final)"

# --- 7c.4 verify: docs folder ---------------------------------------
Write-Host "`n=== 7c.4 VERIFY DOCS FOLDER ===" -ForegroundColor Cyan
Get-ChildItem -Path $DOCS -File |
    Select-Object Name, @{n='KB';e={[math]::Round($_.Length/1024,1)}}, LastWriteTime |
    Format-Table -AutoSize | Out-String | Write-Host

$count = (Get-ChildItem -Path $DOCS -File).Count
if ($count -ge 5) {
    Write-Host "PASS: $count documents in 06_docs/ (expected 5)" -ForegroundColor Green
} else {
    Write-Host "FAIL: only $count documents in 06_docs/ (expected 5)" -ForegroundColor Red
}

# --- 7c.5 verify: final artifact tree -------------------------------
Write-Host "`n=== 7c.5 FINAL ARTIFACT TREE ===" -ForegroundColor Cyan
$files = Get-ChildItem -Path $ROOT -Recurse -File |
    Where-Object { $_.FullName -notmatch '\\logs\\|\\__pycache__\\|\.venv\\|\.git\\' }
$files |
    Select-Object @{n='Path';e={$_.FullName.Replace($ROOT,'.')}}, @{n='KB';e={[math]::Round($_.Length/1024,1)}} |
    Sort-Object Path |
    Format-Table -AutoSize | Out-String | Write-Host

Write-Host "Total tracked files: $($files.Count)" -ForegroundColor Cyan

# --- 7c.6 final summary ---------------------------------------------
Write-Host "`n=== 7c.6 FINAL SUMMARY ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Step 7c complete. All 7 phases done." -ForegroundColor Green
Write-Host ""
Write-Host "  The one command:"
Write-Host "    cd C:\SPROUT-Qonnect\05_rehearsal\scripts; python demo.py"
Write-Host ""
Write-Host "  Integration pack:"
Write-Host "    C:\SPROUT-Qonnect\06_docs\SPROUT_Qonnect_Integration_Pack.md"
Write-Host ""
Write-Host "  Tracker (final):"
Write-Host "    C:\SPROUT-Qonnect\00_admin\STEP_TRACKER.md"
Write-Host ""
Write-Host "  Ready for the Immediate Ask meeting." -ForegroundColor Green

Stop-Transcript | Out-Null