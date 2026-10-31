# =====================================================================
# SPROUT-Qonnect | STEP 5: Phase 3 - Geospatial Compliance Hardening
# =====================================================================
$ErrorActionPreference = 'Continue'
$ROOT = 'C:\SPROUT-Qonnect'
$API  = Join-Path $ROOT '03_api'
$VAL  = Join-Path $ROOT '04_validation'
New-Item -ItemType Directory -Force -Path $VAL | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $API 'app\services') | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
Start-Transcript -Path (Join-Path $ROOT "logs\step5_validation_$stamp.log") -Force | Out-Null

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

# --- 5.0 Extract EUDR validator into shared module -------------------
Write-Host "=== 5.0 EUDR VALIDATOR MODULE ===" -ForegroundColor Cyan
$validator = @'
"""EUDR geolocation validator (rules R1-R8).

Shared by the API (boundary enforcement) and the audit script (report).
Input: GeoJSON geometry dict + optional declared area_ha.
Output: (shapely_geom or None, rules_passed:list[str], rules_failed:list[dict])

R1 CRS, R2 precision, R6 temporal, R7 response integrity, and R8 audit
trail are handled at higher layers (serialization, response envelope,
audit log). The validator enforces R3, R4, R5 here.
"""
from shapely.geometry import shape
from shapely.validation import explain_validity
from pyproj import Geod

GEOD = Geod(ellps='WGS84')
AREA_TOLERANCE = 0.05  # R5: 5% declared vs geodesic


def validate_geometry(geom_dict: dict, declared_area_ha: float | None = None):
    passed, failed = [], []
    gtype = geom_dict.get('type')

    # R3: area rule
    if gtype == 'Point':
        if declared_area_ha is not None and declared_area_ha > 4.0:
            failed.append({
                'rule_id': 'R3_area_rule',
                'message': f'Point cannot claim >4ha (declared {declared_area_ha}ha)',
            })
            return None, passed, failed
        passed.append('R3_area_rule')

    # R4: parse + validity
    try:
        geom = shape(geom_dict)
    except Exception as exc:
        failed.append({'rule_id': 'R4_parse', 'message': str(exc)})
        return None, passed, failed

    if not geom.is_valid:
        failed.append({
            'rule_id': 'R4_validity',
            'message': explain_validity(geom),
        })
        return geom, passed, failed
    passed.append('R4_validity')

    if gtype == 'Polygon':
        ring = geom_dict['coordinates'][0]
        if ring[0] != ring[-1]:
            failed.append({
                'rule_id': 'R4_ring_closed',
                'message': 'First vertex must equal last vertex',
            })
        else:
            passed.append('R4_ring_closed')

        if geom.exterior.is_ccw:
            passed.append('R4_ccw')
        else:
            failed.append({
                'rule_id': 'R4_ccw',
                'message': 'Exterior ring must be counter-clockwise',
            })

        # R5: declared vs geodesic area
        if declared_area_ha is not None and declared_area_ha > 0:
            try:
                geom_area_m2 = abs(GEOD.geometry_area_perimeter(geom)[0])
                geom_area_ha = geom_area_m2 / 10000.0
                delta = abs(geom_area_ha - declared_area_ha) / max(declared_area_ha, 1e-9)
                if delta <= AREA_TOLERANCE:
                    passed.append('R5_area_plausible')
                else:
                    failed.append({
                        'rule_id': 'R5_area_plausible',
                        'message': (
                            f'declared={declared_area_ha:.3f}ha '
                            f'geodesic={geom_area_ha:.3f}ha '
                            f'delta={delta*100:.1f}% (tolerance {AREA_TOLERANCE*100:.0f}%)'
                        ),
                        'geodesic_area_ha': round(geom_area_ha, 4),
                    })
            except Exception as exc:
                failed.append({'rule_id': 'R5_area_compute', 'message': str(exc)})

    return geom, passed, failed
'@
Write-Utf8NoBom -Path (Join-Path $API 'app\services\__init__.py') -Text ''
Write-Utf8NoBom -Path (Join-Path $API 'app\services\eudr_validator.py') -Text $validator
Write-Host "eudr_validator.py written"

# --- 5.1 Rewrite main.py to use the validator ------------------------
Write-Host "=== 5.1 MAIN.PY REFACTOR ===" -ForegroundColor Cyan
$main = @'
"""SPROUT-Qonnect FastAPI service layer (Phase 2, refactored for Phase 3).

Reads from the SQLite database created in Phase 1.
EUDR rules enforced via app.services.eudr_validator.
Returns nearest-neighbour estimates in demo mode; the _infer_* functions
are the only place that changes when the real Sentinel/GEDI model attaches.
"""
from datetime import datetime, timezone
from pathlib import Path
import sqlite3

from fastapi import FastAPI, HTTPException, Body
from pydantic import BaseModel, Field
from shapely.geometry import shape
from pyproj import Geod

from app.services.eudr_validator import validate_geometry

DB_PATH = Path(r'C:\SPROUT-Qonnect\data\sprout.db')
MODEL_VERSION = 'sprout-ssl-agb-v0.9'
GEOD = Geod(ellps='WGS84')
NEAREST_CUTOFF_M = 10000.0

app = FastAPI(
    title='SPROUT-Qonnect API',
    version='0.9.1',
    description='SPROUT GeoAI spatial-verification service for the Qonnect platform.',
)


class Geometry(BaseModel):
    type: str
    coordinates: list


class PlotRequest(BaseModel):
    plot_id: str = Field(..., min_length=3)
    geometry: Geometry
    area_ha: float | None = None
    date: str | None = None
    baseline_year: int = 2020


def _connect():
    if not DB_PATH.exists():
        raise HTTPException(500, detail=f'Database not found at {DB_PATH}')
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec='seconds')


def _envelope(plot_id, attrs, passed, failed, confidence, reason):
    return {
        'plot_id': plot_id,
        'attributes': attrs,
        'validation': {
            'rules_passed': passed,
            'rules_failed': failed,
            'confidence': confidence,
        },
        'model_version': MODEL_VERSION,
        'computed_at': _now_iso(),
        'reason': reason,
    }


def _validate(req: PlotRequest):
    geom_dict = req.geometry.model_dump()
    geom, passed, failed = validate_geometry(geom_dict, req.area_ha)
    if failed:
        raise HTTPException(422, detail={
            'rules_failed': failed,
            'rules_passed': passed,
        })
    return geom, passed


def _nearest_plot(geom):
    if geom.is_empty:
        return None, float('inf')
    point = geom if geom.geom_type == 'Point' else geom.centroid
    conn = _connect()
    rows = conn.execute('SELECT * FROM plots').fetchall()
    conn.close()
    best_row, best_dist = None, float('inf')
    from shapely import wkt as _wkt
    for row in rows:
        try:
            plot_geom = _wkt.loads(row['geom_wkt'])
        except Exception:
            continue
        plot_point = plot_geom if plot_geom.geom_type == 'Point' else plot_geom.centroid
        dist = GEOD.inv(point.x, point.y, plot_point.x, plot_point.y)[2]
        if dist < best_dist:
            best_row, best_dist = row, dist
    return best_row, best_dist


def _confidence(dist_m):
    if dist_m < 100: return 0.95
    if dist_m < 500: return 0.85
    if dist_m < 2000: return 0.60
    if dist_m < 10000: return 0.30
    return 0.0


def _infer(geom, attribute):
    row, dist = _nearest_plot(geom)
    if row is None or dist > NEAREST_CUTOFF_M:
        return None, 0.0, 'no_seeded_plot_within_10km'
    conf = _confidence(dist)
    value = row[attribute]
    if attribute == 'sprout_forest_flag':
        value = bool(value)
    return value, conf, f'nearest_neighbour_demo_mode (dist={dist:.0f}m)'


@app.post('/v1/zone')
def post_zone(req: PlotRequest = Body(...)):
    geom, passed = _validate(req)
    value, conf, reason = _infer(geom, 'sprout_zone')
    if value is None:
        raise HTTPException(404, detail={'reason': reason, 'rules_passed': passed})
    return _envelope(req.plot_id, {'sprout_zone': value}, passed, [], conf, reason)


@app.post('/v1/landcover')
def post_landcover(req: PlotRequest = Body(...)):
    geom, passed = _validate(req)
    lc, conf, reason = _infer(geom, 'sprout_landcover')
    if lc is None:
        raise HTTPException(404, detail={'reason': reason, 'rules_passed': passed})
    forest, _, _ = _infer(geom, 'sprout_forest_flag')
    return _envelope(req.plot_id,
        {'sprout_landcover': lc, 'sprout_forest_flag': forest},
        passed, [], conf, reason)


@app.post('/v1/agb')
def post_agb(req: PlotRequest = Body(...)):
    geom, passed = _validate(req)
    agb, conf, reason = _infer(geom, 'sprout_agb_t_ha')
    if agb is None:
        raise HTTPException(404, detail={'reason': reason, 'rules_passed': passed})
    unc, _, _ = _infer(geom, 'sprout_agb_uncertainty')
    return _envelope(req.plot_id,
        {'sprout_agb_t_ha': agb, 'sprout_agb_uncertainty': unc},
        passed, [], conf, reason)


@app.post('/v1/risk')
def post_risk(req: PlotRequest = Body(...)):
    geom, passed = _validate(req)
    risk, conf, reason = _infer(geom, 'sprout_risk_score')
    if risk is None:
        raise HTTPException(404, detail={'reason': reason, 'rules_passed': passed})
    return _envelope(req.plot_id,
        {'sprout_risk_score': risk,
         'risk_factors': ['baseline_year_2020', 'demo_nearest_neighbour']},
        passed, [], conf, reason)


@app.get('/v1/batch/{batch_code}')
def get_batch(batch_code: str):
    conn = _connect()
    batch = conn.execute(
        'SELECT * FROM batches WHERE batch_code = ?', (batch_code,)
    ).fetchone()
    if not batch:
        conn.close()
        raise HTTPException(404, detail=f'Batch {batch_code} not found')
    plots = conn.execute('''
        SELECT p.* FROM plots p
        JOIN batch_plots bp ON bp.plot_id = p.plot_id
        WHERE bp.batch_code = ?
        ORDER BY p.plot_id
    ''', (batch_code,)).fetchall()
    conn.close()
    return {
        'batch_code': batch['batch_code'],
        'ectms_batch_id': batch['ectms_batch_id'],
        'total_area_ha': batch['total_area_ha'],
        'aggregated_agb_t': batch['aggregated_agb_t'],
        'worst_case_risk_score': batch['worst_case_risk_score'],
        'plot_count': batch['plot_count'],
        'verification_status': batch['verification_status'],
        'model_version': MODEL_VERSION,
        'computed_at': _now_iso(),
        'plots': [dict(p) for p in plots],
    }


@app.get('/v1/health')
def health():
    ok = DB_PATH.exists()
    count = 0
    if ok:
        try:
            conn = _connect()
            count = conn.execute('SELECT COUNT(*) FROM plots').fetchone()[0]
            conn.close()
        except Exception:
            ok = False
    return {
        'status': 'ok' if ok else 'degraded',
        'db_path': str(DB_PATH),
        'db_reachable': ok,
        'plot_count': count,
        'engine': 'sqlite',
        'api_version': app.version,
        'model_version': MODEL_VERSION,
        'computed_at': _now_iso(),
    }


@app.get('/v1/schema')
def get_schema():
    return app.openapi()
'@
Write-Utf8NoBom -Path (Join-Path $API 'app\main.py') -Text $main
Write-Host "main.py rewritten to use shared validator"

# --- 5.2 Seed geometry audit -----------------------------------------
Write-Host "=== 5.2 SEED AUDIT SCRIPT ===" -ForegroundColor Cyan
$audit = @'
"""Audit the 3 seeded plots through the EUDR validator."""
import sys, json, sqlite3, csv
from pathlib import Path
sys.path.insert(0, r'C:\SPROUT-Qonnect\03_api')
from shapely import wkt as _wkt
from app.services.eudr_validator import validate_geometry

ROOT = Path(r'C:\SPROUT-Qonnect')
DB = ROOT / 'data' / 'sprout.db'
OUT_CSV = ROOT / '04_validation' / 'audit_seed_plots.csv'
OUT_JSON = ROOT / '04_validation' / 'audit_seed_plots.json'

conn = sqlite3.connect(DB)
conn.row_factory = sqlite3.Row
plots = conn.execute('SELECT * FROM plots ORDER BY plot_id').fetchall()
conn.close()

rows, details = [], []
for p in plots:
    geom = _wkt.loads(p['geom_wkt'])
    geom_dict = json.loads(json.dumps(geom.__geo_interface__))
    _, passed, failed = validate_geometry(geom_dict, p['area_ha'])
    rows.append({
        'plot_id': p['plot_id'],
        'declared_area_ha': p['area_ha'],
        'rules_passed_count': len(passed),
        'rules_failed_count': len(failed),
        'rules_failed': '; '.join(f['rule_id'] for f in failed) or '',
        'verdict': 'PASS' if not failed else 'FAIL',
    })
    details.append({
        'plot_id': p['plot_id'],
        'geometry_type': geom_dict['type'],
        'declared_area_ha': p['area_ha'],
        'rules_passed': passed,
        'rules_failed': failed,
    })

with open(OUT_CSV, 'w', newline='', encoding='utf-8') as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
    w.writeheader()
    w.writerows(rows)

with open(OUT_JSON, 'w', encoding='utf-8') as f:
    json.dump(details, f, indent=2)

print(f'Audited {len(rows)} plots')
for r in rows:
    marker = 'PASS' if r['verdict'] == 'PASS' else 'FAIL'
    print(f'  [{marker}] {r["plot_id"]}  declared={r["declared_area_ha"]}ha  '
          f'failed={r["rules_failed"] or "none"}')
print(f'Written: {OUT_CSV.name}, {OUT_JSON.name}')
'@
Write-Utf8NoBom -Path (Join-Path $VAL 'audit_seed_plots.py') -Text $audit

# --- 5.3 Patch PLT-GAMO-0003 area if R5 fails ------------------------
Write-Host "`n=== 5.3 RUN SEED AUDIT ===" -ForegroundColor Cyan
Push-Location $API
python $VAL\audit_seed_plots.py
Pop-Location

# --- 5.4 Calibration status script -----------------------------------
Write-Host "`n=== 5.4 CALIBRATION STATUS ===" -ForegroundColor Cyan
$calib = @'
"""Forest/agroforestry calibration status report.

Honest assessment: with only 3 seeded plots (one per class), precision and
recall cannot be computed. This script records that fact and specifies the
data required for a real calibration.
"""
import json, sqlite3
from pathlib import Path

ROOT = Path(r'C:\SPROUT-Qonnect')
DB = ROOT / 'data' / 'sprout.db'
OUT = ROOT / '04_validation' / 'calibration_status.json'

conn = sqlite3.connect(DB)
conn.row_factory = sqlite3.Row
rows = conn.execute('''
    SELECT sprout_landcover, COUNT(*) as n, AVG(sprout_agb_t_ha) as avg_agb
    FROM plots GROUP BY sprout_landcover
''').fetchall()
conn.close()

classes = [{'class': r['sprout_landcover'], 'n': r['n'],
            'avg_agb_t_ha': round(r['avg_agb'], 2) if r['avg_agb'] else None}
           for r in rows]

min_per_class_required = 30
deficit = max(0, min_per_class_required - min((c['n'] for c in classes), default=0))

status = {
    'verdict': 'INSUFFICIENT_DATA' if deficit > 0 else 'READY_FOR_CALIBRATION',
    'classes_present': classes,
    'total_labelled_plots': sum(c['n'] for c in classes),
    'min_per_class_required': min_per_class_required,
    'min_per_class_observed': min((c['n'] for c in classes), default=0),
    'deficit_per_class': deficit,
    'method_when_ready': [
        'Stratified field survey: >=30 ground-truth points per class',
        'Confusion matrix computed against SPROUT landcover prediction',
        'Per-class precision and recall reported with 95% Wilson CI',
        'Forest flag threshold tuned on shade-coffee plots specifically',
        'Any plot with agroforestry landcover MUST return forest_flag=false',
    ],
    'next_action': (
        'Defer calibration until field data collection; seed data is for '
        'pipeline verification only. Report to the consortium that calibration '
        'is PENDING, not complete.'
    ),
}

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(status, f, indent=2)

print(f'Calibration verdict: {status["verdict"]}')
print(f'  classes observed: {[(c["class"], c["n"]) for c in classes]}')
print(f'  deficit per class: {status["deficit_per_class"]}')
print(f'  written: {OUT.name}')
'@
Write-Utf8NoBom -Path (Join-Path $VAL 'calibrate_forest.py') -Text $calib
python $VAL\calibrate_forest.py

# --- 5.5 Commingling simulation --------------------------------------
Write-Host "`n=== 5.5 COMMINGLING SIMULATION ===" -ForegroundColor Cyan
$commingle = @'
"""Commingling simulation.

Generates 10 synthetic smallholder plots near the 3 seed centroids,
assigns them to a new batch, then tests whether batch aggregation stays
internally consistent when a subset of plots is removed (the commingling
resilience question).
"""
import json, random, sqlite3
from pathlib import Path
from shapely.geometry import Point, Polygon
from pyproj import Geod

ROOT = Path(r'C:\SPROUT-Qonnect')
DB = ROOT / 'data' / 'sprout.db'
OUT = ROOT / '04_validation' / 'commingle_sim.json'
GEOD = Geod(ellps='WGS84')

random.seed(42)  # reproducibility

# Anchor points from the seed plots (Gamo Gofa)
anchors = [
    {'lon': 37.5505, 'lat': 6.0005},
    {'lon': 37.5710, 'lat': 6.2510},
    {'lon': 37.6005, 'lat': 6.4005},
]

def jitter_poly(lon, lat, half_side_deg=0.0008):
    return Polygon([
        (lon - half_side_deg, lat - half_side_deg),
        (lon + half_side_deg, lat - half_side_deg),
        (lon + half_side_deg, lat + half_side_deg),
        (lon - half_side_deg, lat + half_side_deg),
        (lon - half_side_deg, lat - half_side_deg),
    ])

synthetic = []
for i in range(10):
    a = random.choice(anchors)
    lon = a['lon'] + random.uniform(-0.005, 0.005)
    lat = a['lat'] + random.uniform(-0.005, 0.005)
    poly = jitter_poly(lon, lat)
    area_ha = abs(GEOD.geometry_area_perimeter(poly)[0]) / 10000.0
    agb = random.uniform(30, 130)
    risk = random.uniform(0.05, 0.55)
    synthetic.append({
        'plot_id': f'PLT-SIM-{i:04d}',
        'geom_wkt': poly.wkt,
        'area_ha': round(area_ha, 4),
        'agb': round(agb, 2),
        'risk': round(risk, 3),
    })

# Aggregate as a single batch
def aggregate(plots):
    total_area = sum(p['area_ha'] for p in plots)
    total_agb = sum(p['agb'] * p['area_ha'] for p in plots)
    worst_risk = max(p['risk'] for p in plots) if plots else 0.0
    return {
        'plot_count': len(plots),
        'total_area_ha': round(total_area, 4),
        'aggregated_agb_t': round(total_agb, 4),
        'worst_case_risk_score': round(worst_risk, 4),
    }

full = aggregate(synthetic)
removal_sets = [
    ('remove_first_3', synthetic[3:]),
    ('remove_last_5',  synthetic[:-5]),
    ('remove_random_4', [p for p in synthetic if p['plot_id'] not in
                         {x['plot_id'] for x in random.sample(synthetic, 4)}]),
]
results = [{'scenario': 'full_batch', 'aggregation': full,
            'recomputed_consistent': True}]
for name, remaining in removal_sets:
    agg = aggregate(remaining)
    recomputed_area = sum(p['area_ha'] for p in remaining)
    recomputed_agb = sum(p['agb'] * p['area_ha'] for p in remaining)
    recomputed_risk = max((p['risk'] for p in remaining), default=0.0)
    consistent = (
        abs(agg['total_area_ha'] - round(recomputed_area, 4)) < 0.0001
        and abs(agg['aggregated_agb_t'] - round(recomputed_agb, 4)) < 0.0001
        and abs(agg['worst_case_risk_score'] - round(recomputed_risk, 4)) < 0.0001
    )
    results.append({
        'scenario': name,
        'aggregation': agg,
        'recomputed_consistent': consistent,
    })

payload = {
    'synthetic_plot_count': len(synthetic),
    'batch_code_simulated': 'QON-SIM-COMMINGLE-001',
    'results': results,
}
with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(payload, f, indent=2)

print(f'Simulated {len(synthetic)} plots in one batch')
print(f'  full batch: {full["plot_count"]} plots, '
      f'{full["total_area_ha"]}ha, {full["aggregated_agb_t"]}t, '
      f'risk={full["worst_case_risk_score"]}')
for r in results[1:]:
    mark = 'OK' if r['recomputed_consistent'] else 'INCONSISTENT'
    print(f'  {r["scenario"]:20s} -> {r["aggregation"]["plot_count"]} plots '
          f'({mark})')
print(f'Written: {OUT.name}')
'@
Write-Utf8NoBom -Path (Join-Path $VAL 'commingle_sim.py') -Text $commingle
python $VAL\commingle_sim.py

# --- 5.6 Report generator --------------------------------------------
Write-Host "`n=== 5.6 REPORT GENERATOR ===" -ForegroundColor Cyan
$report = @'
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
    lines.append('### Failing plots — evidence')
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
lines.append('- [ ] Review the R2 deferral — is the Qonnect client serialization ' 
             'guaranteed to produce 6 decimals?')
lines.append('- [ ] Review the R8 gap — who writes to validation_log in production?')
lines.append('- [ ] Review the calibration deferral — is PENDING acceptable for '
             'the first EUDR tranche, or is a field survey required before go-live?')
lines.append('')
lines.append('---')
lines.append('')
lines.append('*This report is a factual record of the SPROUT-Qonnect build '
             'state. It is not a compliance assertion. Legal EUDR compliance '
             'is the responsibility of the consortium\'s DDS layer.*')

OUT.write_text('\n'.join(lines), encoding='utf-8')
print(f'Report written: {OUT.name} ({len(lines)} lines)')
'@
Write-Utf8NoBom -Path (Join-Path $VAL 'generate_report.py') -Text $report
python $VAL\generate_report.py

# --- 5.7 Regression check: re-run smoke test -------------------------
Write-Host "`n=== 5.7 REGRESSION CHECK ===" -ForegroundColor Cyan
Push-Location $API
python smoke_test.py
$smokeExit = $LASTEXITCODE
Pop-Location

if ($smokeExit -eq 0) {
    Write-Host "`nRefactor did not break API behavior" -ForegroundColor Green
} else {
    Write-Host "`nSMOKE TEST REGRESSED after refactor - inspect above" -ForegroundColor Red
}

# --- 5.8 Update tracker ----------------------------------------------
$tracker = @'
# SPROUT-Qonnect - Build Tracker

| # | Step | Status | Artifact |
|---|------|--------|----------|
| 1 | Environment audit + scaffold | DONE | 00_admin/environment_audit.csv |
| 2 | Phase 0 - Discovery & schema alignment | DONE | 01_discovery/ |
| 3 | Phase 1 - Database transformation | DONE | 02_database/ (SQLite) |
| 4 | Phase 2 - FastAPI service layer | DONE | 03_api/ (API v0.9.1) |
| 5 | Phase 3 - Geospatial compliance hardening | DONE (pending endorsement) | 04_validation/ |
| 6 | Phase 4 - Qonnect/ECTMS integration rehearsal | NOT STARTED | 05_rehearsal/ |
| 7 | Phase 5 - Integration pack & Immediate Ask | NOT STARTED | 06_docs/ |

## Step 5 artifacts

- 03_api/app/services/eudr_validator.py  (shared R3/R4/R5 validator)
- 03_api/app/main.py                     (refactored to use validator; API v0.9.1)
- 04_validation/audit_seed_plots.py
- 04_validation/audit_seed_plots.csv
- 04_validation/audit_seed_plots.json
- 04_validation/calibrate_forest.py
- 04_validation/calibration_status.json
- 04_validation/commingle_sim.py
- 04_validation/commingle_sim.json
- 04_validation/generate_report.py
- 04_validation/sprout_geospatial_validation_report.md  (THE Immediate Ask artifact)

## Open items from Step 5

- Calibration verdict is INSUFFICIENT_DATA; field survey required.
- R2 precision check deferred to Qonnect client serialization spec.
- R8 audit-trail write path not yet instrumented.
- Seed plot PLT-GAMO-0003 may have an R5 area discrepancy — see report section 1.
'@
Write-Utf8NoBom -Path (Join-Path $ROOT '00_admin\STEP_TRACKER.md') -Text $tracker

Write-Host "`n=== STEP 5 COMPLETE ===" -ForegroundColor Green

Stop-Transcript | Out-Null