"""Assemble the geospatial validation report from the Step 5 artifacts."""
import json, csv
from pathlib import Path
from datetime import datetime, timezone

ROOT = Path(r'C:\SPROUT-Qonnect')
VAL = ROOT / '04_validation'
OUT = VAL / 'sprout_geospatial_validation_report.md'

def load(path):
    with open(path, encoding='utf-8') as f:
        return json.load(f)

audit = load(VAL / 'audit_seed_plots.json')
calib = load(VAL / 'calibration_status.json')
commingle = load(VAL / 'commingle_sim.json')

with open(VAL / 'audit_seed_plots.csv', encoding='utf-8') as f:
    csv_rows = list(csv.DictReader(f))

now = datetime.now(timezone.utc).isoformat(timespec='seconds')

# Headline verdict
seed_pass = sum(1 for r in csv_rows if r['verdict'] == 'PASS')
seed_fail = sum(1 for r in csv_rows if r['verdict'] == 'FAIL')
commingle_ok = all(r['recomputed_consistent'] for r in commingle['results'])

lines = []
lines.append('# SPROUT-Qonnect Geospatial Validation Report')
lines.append('')
lines.append(f'**Generated:** {now}')
lines.append('**Project:** Project SPROUT x TraceRight consortium')
lines.append('**Model version:** sprout-ssl-agb-v0.9')
lines.append('**Database engine:** SQLite (PostGIS migration pending Docker daemon)')
lines.append('**Status:** Internal draft for consortium review')
lines.append('')
lines.append('---')
lines.append('')
lines.append('## Executive Summary')
lines.append('')
lines.append(
    f'Of the {len(csv_rows)} seeded geometries, **{seed_pass} passed all '
    f'applicable EUDR rules** and **{seed_fail} failed at least one**. '
    f'Commingling simulation over {commingle["synthetic_plot_count"]} '
    f'synthetic plots {"maintains" if commingle_ok else "does not maintain"} '
    f'internal aggregation consistency across all tested removal scenarios.'
)
lines.append('')
lines.append(
    '**Forest/agroforestry calibration is PENDING.** The current seed data '
    'has one example per land-cover class; precision and recall cannot be '
    'computed from it. A field survey (>=30 points per class) is the '
    'prerequisite. This report does NOT claim the forest classifier is '
    'calibrated.'
)
lines.append('')
lines.append('---')
lines.append('')
lines.append('## 1. Seed Geometry Audit (EUDR rules R3, R4, R5)')
lines.append('')
lines.append('| Plot ID | Declared area | Rules passed | Rules failed | Verdict |')
lines.append('|---------|---------------|--------------|--------------|---------|')
for r in csv_rows:
    lines.append(
        f'| {r["plot_id"]} | {r["declared_area_ha"]} ha | '
        f'{r["rules_passed_count"]} | {r["rules_failed"] or "none"} | '
        f'**{r["verdict"]}** |'
    )
lines.append('')
if seed_fail > 0:
    lines.append('### Failing plots â€” evidence')
    lines.append('')
    for detail in audit:
        if detail['rules_failed']:
            lines.append(f'**{detail["plot_id"]}**')
            for failure in detail['rules_failed']:
                lines.append(f'- `{failure["rule_id"]}`: {failure["message"]}')
            lines.append('')
lines.append('---')
lines.append('')
lines.append('## 2. Forest / Agroforestry Calibration Status')
lines.append('')
lines.append(f'**Verdict: {calib["verdict"]}**')
lines.append('')
lines.append('| Class | Plots observed | Avg AGB (t/ha) |')
lines.append('|-------|----------------|----------------|')
for c in calib['classes_present']:
    lines.append(f'| {c["class"]} | {c["n"]} | {c["avg_agb_t_ha"]} |')
lines.append('')
lines.append(
    f'Minimum required per class: **{calib["min_per_class_required"]}** '
    f'(field-labelled). Deficit: **{calib["deficit_per_class"]}** per class.'
)
lines.append('')
lines.append('**Method when field data is available:**')
for m in calib['method_when_ready']:
    lines.append(f'- {m}')
lines.append('')
lines.append(f'**Next action:** {calib["next_action"]}')
lines.append('')
lines.append('---')
lines.append('')
lines.append('## 3. Commingling Simulation')
lines.append('')
lines.append(
    f'{commingle["synthetic_plot_count"]} synthetic plots aggregated into '
    f'a single batch; aggregation recomputed after partial-plot removal.'
)
lines.append('')
lines.append('| Scenario | Plots remaining | Total area | Aggregated AGB | Worst risk | Consistent |')
lines.append('|----------|-----------------|------------|----------------|------------|------------|')
for r in commingle['results']:
    a = r['aggregation']
    lines.append(
        f'| {r["scenario"]} | {a["plot_count"]} | {a["total_area_ha"]} ha | '
        f'{a["aggregated_agb_t"]} t | {a["worst_case_risk_score"]} | '
        f'{"YES" if r["recomputed_consistent"] else "NO"} |'
    )
lines.append('')
lines.append('**Interpretation:** batch aggregation is a pure function of the '
             'current plot set; removing a subset (as happens when a batch is '
             'split or a plot is re-assigned) recalculates correctly. This is '
             'a necessary precondition for mass-balance provenance attribution '
             'under ECX-style commingling.')
lines.append('')
lines.append('---')
lines.append('')
lines.append('## 4. Deferred rules and known limitations')
lines.append('')
lines.append(
    '| Rule | Status | Reason |\n'
    '|------|--------|--------|\n'
    '| R1 (CRS) | Enforced | WGS84 assumed at API boundary via GeoJSON |\n'
    '| R2 (6 decimal places) | Deferred | Cannot be enforced on parsed '
    'floats; belongs in the Qonnect client serialization spec |\n'
    '| R3 (area rule) | Enforced | Tests cover point >4ha rejection |\n'
    '| R4 (polygon validity) | Enforced | Ring closure, CCW, self-intersect |\n'
    '| R5 (area plausibility) | Enforced | 5% declared-vs-geodesic tolerance |\n'
    '| R6 (2020 baseline) | Data layer | Stored as column, not constant |\n'
    '| R7 (response integrity) | Enforced | model_version + computed_at on '
    'every response |\n'
    '| R8 (audit trail) | Partial | Validation_log table exists; write path '
    'not yet instrumented |\n'
)
lines.append('')
lines.append('**Not verified by this report:**')
lines.append('')
lines.append('- Real-world AGB model accuracy (seed data only)')
lines.append('- Forest vs shade-coffee classification correctness (pending field calibration)')
lines.append('- ECTMS batch identifier linkage (pending ECTMS API access)')
lines.append('- Polygon overlap / mass-balance attribution under real commingling')
lines.append('')
lines.append('---')
lines.append('')
lines.append('## 5. Sign-off checklist for the TraceRight technical lead')
lines.append('')
lines.append('Items to verify before integrating SPROUT into the Fabric DDS pipeline:')
lines.append('')
lines.append('- [ ] Confirm plot-level identifier exists in Qonnect (see Open Question Q1)')
lines.append('- [ ] Confirm ECTMS batch ID field name and API contract (Q2)')
lines.append('- [ ] Confirm farmer polygon consent regime (Q3)')
lines.append('- [ ] Review the R2 deferral â€” is the Qonnect client serialization ' 
             'guaranteed to produce 6 decimals?')
lines.append('- [ ] Review the R8 gap â€” who writes to validation_log in production?')
lines.append('- [ ] Review the calibration deferral â€” is PENDING acceptable for '
             'the first EUDR tranche, or is a field survey required before go-live?')
lines.append('')
lines.append('---')
lines.append('')
lines.append('*This report is a factual record of the SPROUT-Qonnect build '
             'state. It is not a compliance assertion. Legal EUDR compliance '
             'is the responsibility of the consortium\'s DDS layer.*')

OUT.write_text('\n'.join(lines), encoding='utf-8')
print(f'Report written: {OUT.name} ({len(lines)} lines)')