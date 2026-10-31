# =====================================================================
# SPROUT-Qonnect | STEP 4: Phase 2 - FastAPI Service Layer
# =====================================================================
$ErrorActionPreference = 'Continue'
$ROOT = 'C:\SPROUT-Qonnect'
$API  = Join-Path $ROOT '03_api'
New-Item -ItemType Directory -Force -Path (Join-Path $API 'app') | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
Start-Transcript -Path (Join-Path $ROOT "logs\step4_api_$stamp.log") -Force | Out-Null

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

# --- 4.0 requirements.txt --------------------------------------------
Write-Host "=== 4.0 REQUIREMENTS ===" -ForegroundColor Cyan
$req = @'
fastapi>=0.139.0
uvicorn[standard]>=0.50.0
pydantic>=2.13.0
shapely>=2.1.0
pyproj>=3.7.0
httpx>=0.28.0
'@
Write-Utf8NoBom -Path (Join-Path $API 'requirements.txt') -Text $req
Write-Host "requirements.txt written"

# --- 4.1 app/__init__.py ---------------------------------------------
Write-Utf8NoBom -Path (Join-Path $API 'app\__init__.py') -Text ''

# --- 4.2 app/main.py -------------------------------------------------
Write-Host "=== 4.2 APP ===" -ForegroundColor Cyan
$main = @'
"""SPROUT-Qonnect FastAPI service layer (Phase 2).

Reads from the SQLite database created in Phase 1.
Implements the alignment contract response envelope.
Enforces EUDR rules R3, R4, R5, R7 at the request boundary.
Returns nearest-neighbour estimates in demo mode; the _infer_* functions
are the only place that changes when the real Sentinel/GEDI model attaches.
"""
from datetime import datetime, timezone
from pathlib import Path
import sqlite3

from fastapi import FastAPI, HTTPException, Body
from pydantic import BaseModel, Field
from shapely.geometry import shape, mapping
from shapely.validation import explain_validity
from pyproj import Geod

DB_PATH = Path(r'C:\SPROUT-Qonnect\data\sprout.db')
MODEL_VERSION = 'sprout-ssl-agb-v0.9'
GEOD = Geod(ellps='WGS84')
NEAREST_CUTOFF_M = 10000.0

app = FastAPI(
    title='SPROUT-Qonnect API',
    version='0.9.0',
    description='SPROUT GeoAI spatial-verification service for the Qonnect platform.',
)

# ---------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------
class Geometry(BaseModel):
    type: str
    coordinates: list

class PlotRequest(BaseModel):
    plot_id: str = Field(..., min_length=3)
    geometry: Geometry
    area_ha: float | None = None
    date: str | None = None
    baseline_year: int = 2020

# ---------------------------------------------------------------------
# DB helpers
# ---------------------------------------------------------------------
def _connect():
    if not DB_PATH.exists():
        raise HTTPException(500, detail=f'Database not found at {DB_PATH}')
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec='seconds')

def _envelope(plot_id: str, attrs: dict, passed: list, failed: list,
              confidence: float, reason: str) -> dict:
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

# ---------------------------------------------------------------------
# Geometry validation (EUDR rules R3, R4, R5)
# ---------------------------------------------------------------------
def _validate_geometry(req: PlotRequest) -> tuple:
    passed, failed = [], []
    geom_dict = req.geometry.model_dump()

    # R3: area rule
    if geom_dict['type'] == 'Point':
        if req.area_ha is not None and req.area_ha > 4.0:
            failed.append('R3_area_rule: point cannot claim >4ha')
            return None, passed, failed
        passed.append('R3_area_rule')

    # R4: validity
    try:
        geom = shape(geom_dict)
    except Exception as exc:
        failed.append(f'R4_parse: {exc}')
        return None, passed, failed

    if not geom.is_valid:
        failed.append(f'R4_validity: {explain_validity(geom)}')
        return geom, passed, failed
    passed.append('R4_validity')

    if geom_dict['type'] == 'Polygon':
        ring = geom_dict['coordinates'][0]
        if ring[0] != ring[-1]:
            failed.append('R4_ring_closed: first vertex != last vertex')
        else:
            passed.append('R4_ring_closed')

        if geom.exterior.is_ccw:
            passed.append('R4_ccw')
        else:
            failed.append('R4_ccw: exterior ring must be counter-clockwise')

        # R5: declared vs geodesic area (within 5%)
        if req.area_ha is not None:
            try:
                geom_area_m2 = abs(GEOD.geometry_area_perimeter(geom)[0])
                geom_area_ha = geom_area_m2 / 10000.0
                delta = abs(geom_area_ha - req.area_ha) / max(req.area_ha, 1e-9)
                if delta <= 0.05:
                    passed.append('R5_area_plausible')
                else:
                    failed.append(
                        f'R5_area_plausible: declared={req.area_ha:.3f}ha '
                        f'geodesic={geom_area_ha:.3f}ha delta={delta*100:.1f}%'
                    )
            except Exception as exc:
                failed.append(f'R5_area_compute: {exc}')

    return geom, passed, failed

# ---------------------------------------------------------------------
# Nearest-neighbour demo inference (replaced in Phase 3)
# ---------------------------------------------------------------------
def _nearest_plot(geom):
    if geom.is_empty:
        return None, float('inf')
    point = geom if geom.geom_type == 'Point' else geom.centroid
    conn = _connect()
    rows = conn.execute('SELECT * FROM plots').fetchall()
    conn.close()
    best_row, best_dist = None, float('inf')
    for row in rows:
        try:
            plot_geom = shape(eval_wkt(row['geom_wkt']))
        except Exception:
            continue
        plot_point = plot_geom if plot_geom.geom_type == 'Point' else plot_geom.centroid
        dist = GEOD.inv(point.x, point.y, plot_point.x, plot_point.y)[2]
        if dist < best_dist:
            best_row, best_dist = row, dist
    return best_row, best_dist

def eval_wkt(wkt: str):
    from shapely import wkt as _wkt
    return _wkt.loads(wkt)

def _confidence(dist_m: float) -> float:
    if dist_m < 100: return 0.95
    if dist_m < 500: return 0.85
    if dist_m < 2000: return 0.60
    if dist_m < 10000: return 0.30
    return 0.0

def _infer(geom, attribute: str):
    row, dist = _nearest_plot(geom)
    if row is None or dist > NEAREST_CUTOFF_M:
        return None, 0.0, 'no_seeded_plot_within_10km'
    conf = _confidence(dist)
    value = row[attribute]
    if attribute == 'sprout_forest_flag':
        value = bool(value)
    return value, conf, f'nearest_neighbour_demo_mode (dist={dist:.0f}m)'

# ---------------------------------------------------------------------
# Attribute endpoints
# ---------------------------------------------------------------------
def _run_pipeline(req: PlotRequest, attribute: str, extra_attrs: dict = None):
    geom, passed, failed = _validate_geometry(req)
    if failed:
        raise HTTPException(422, detail={'rules_failed': failed, 'rules_passed': passed})
    value, conf, reason = _infer(geom, attribute)
    if value is None:
        raise HTTPException(404, detail={'reason': reason, 'rules_passed': passed})
    attrs = {attribute: value}
    if extra_attrs:
        attrs.update(extra_attrs)
    return _envelope(req.plot_id, attrs, passed, [], conf, reason)

@app.post('/v1/zone')
def post_zone(req: PlotRequest = Body(...)):
    return _run_pipeline(req, 'sprout_zone')

@app.post('/v1/landcover')
def post_landcover(req: PlotRequest = Body(...)):
    geom, passed, failed = _validate_geometry(req)
    if failed:
        raise HTTPException(422, detail={'rules_failed': failed, 'rules_passed': passed})
    lc, conf, reason = _infer(geom, 'sprout_landcover')
    if lc is None:
        raise HTTPException(404, detail={'reason': reason, 'rules_passed': passed})
    forest, _, _ = _infer(geom, 'sprout_forest_flag')
    return _envelope(req.plot_id,
        {'sprout_landcover': lc, 'sprout_forest_flag': forest},
        passed, [], conf, reason)

@app.post('/v1/agb')
def post_agb(req: PlotRequest = Body(...)):
    geom, passed, failed = _validate_geometry(req)
    if failed:
        raise HTTPException(422, detail={'rules_failed': failed, 'rules_passed': passed})
    agb, conf, reason = _infer(geom, 'sprout_agb_t_ha')
    if agb is None:
        raise HTTPException(404, detail={'reason': reason, 'rules_passed': passed})
    unc, _, _ = _infer(geom, 'sprout_agb_uncertainty')
    return _envelope(req.plot_id,
        {'sprout_agb_t_ha': agb, 'sprout_agb_uncertainty': unc},
        passed, [], conf, reason)

@app.post('/v1/risk')
def post_risk(req: PlotRequest = Body(...)):
    geom, passed, failed = _validate_geometry(req)
    if failed:
        raise HTTPException(422, detail={'rules_failed': failed, 'rules_passed': passed})
    risk, conf, reason = _infer(geom, 'sprout_risk_score')
    if risk is None:
        raise HTTPException(404, detail={'reason': reason, 'rules_passed': passed})
    return _envelope(req.plot_id,
        {'sprout_risk_score': risk,
         'risk_factors': ['baseline_year_2020', 'demo_nearest_neighbour']},
        passed, [], conf, reason)

# ---------------------------------------------------------------------
# Batch endpoint
# ---------------------------------------------------------------------
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

# ---------------------------------------------------------------------
# Meta endpoints
# ---------------------------------------------------------------------
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
Write-Host "app/main.py written"

# --- 4.3 smoke_test.py -----------------------------------------------
Write-Host "=== 4.3 SMOKE TEST ===" -ForegroundColor Cyan
$smoke = @'
"""End-to-end smoke test for the SPROUT-Qonnect API.
Runs in-process via TestClient; no server start required.
"""
import sys, json
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)
PASS = []
FAIL = []

def check(name, condition, detail=''):
    if condition:
        PASS.append(name); print(f'PASS  {name}')
    else:
        FAIL.append(name); print(f'FAIL  {name}  {detail}')

# Valid Gamo Gofa polygon (matches seed PLT-GAMO-0001)
VALID_POLY = {
    'type': 'Polygon',
    'coordinates': [[
        [37.550001, 5.999999],
        [37.551001, 5.999999],
        [37.551001, 6.001001],
        [37.550001, 6.001001],
        [37.550001, 5.999999],
    ]],
}
BODY = {'plot_id': 'PLT-TEST-001', 'geometry': VALID_POLY, 'area_ha': 1.2}

# --- health ---
r = client.get('/v1/health')
check('health 200', r.status_code == 200, r.text[:200])
check('health db_reachable', r.json().get('db_reachable') is True)
check('health plot_count=3', r.json().get('plot_count') == 3)

# --- schema ---
r = client.get('/v1/schema')
check('schema 200', r.status_code == 200)
check('schema lists 7 paths', len(r.json().get('paths', {})) >= 7)

# --- zone ---
r = client.post('/v1/zone', json=BODY)
check('zone 200', r.status_code == 200, r.text[:300])
if r.status_code == 200:
    d = r.json()
    check('zone has attributes', 'sprout_zone' in d['attributes'])
    check('zone has model_version', d.get('model_version') == 'sprout-ssl-agb-v0.9')
    check('zone has computed_at', 'computed_at' in d)
    check('zone rules_passed non-empty', len(d['validation']['rules_passed']) > 0)

# --- landcover ---
r = client.post('/v1/landcover', json=BODY)
check('landcover 200', r.status_code == 200, r.text[:300])
if r.status_code == 200:
    d = r.json()
    check('landcover has forest_flag', 'sprout_forest_flag' in d['attributes'])

# --- agb ---
r = client.post('/v1/agb', json=BODY)
check('agb 200', r.status_code == 200, r.text[:300])
if r.status_code == 200:
    d = r.json()
    check('agb has uncertainty', 'sprout_agb_uncertainty' in d['attributes'])

# --- risk ---
r = client.post('/v1/risk', json=BODY)
check('risk 200', r.status_code == 200, r.text[:300])
if r.status_code == 200:
    d = r.json()
    check('risk in 0..1', 0.0 <= d['attributes']['sprout_risk_score'] <= 1.0)

# --- batch ---
r = client.get('/v1/batch/QON-COF-2026-00001')
check('batch 200', r.status_code == 200, r.text[:300])
if r.status_code == 200:
    d = r.json()
    check('batch plot_count=3', d.get('plot_count') == 3)
    check('batch has 3 plots', len(d.get('plots', [])) == 3)
    check('batch area=8.20', abs(d.get('total_area_ha', 0) - 8.20) < 0.001)

# --- negative: unknown batch ---
r = client.get('/v1/batch/BOGUS-CODE')
check('unknown batch 404', r.status_code == 404, r.text[:200])

# --- negative: point claiming >4ha ---
bad_body = {'plot_id': 'PLT-BAD-POINT',
            'geometry': {'type': 'Point', 'coordinates': [37.55, 6.0]},
            'area_ha': 8.0}
r = client.post('/v1/zone', json=bad_body)
check('point>4ha 422', r.status_code == 422, r.text[:200])
if r.status_code == 422:
    check('R3 rule named in error',
          'R3_area_rule' in json.dumps(r.json()))

# --- negative: self-intersecting polygon ---
bad_poly = {
    'type': 'Polygon',
    'coordinates': [[
        [37.550001, 5.999999],
        [37.551001, 6.001001],
        [37.551001, 5.999999],
        [37.550001, 6.001001],
        [37.550001, 5.999999],
    ]],
}
r = client.post('/v1/zone', json={'plot_id': 'PLT-BAD-BOWTIE',
                                   'geometry': bad_poly, 'area_ha': 1.2})
check('self-intersect 422', r.status_code == 422, r.text[:200])
if r.status_code == 422:
    check('R4 rule named in error',
          'R4_validity' in json.dumps(r.json()))

# --- summary ---
print()
print(f'{"="*50}')
print(f'PASSED: {len(PASS)}   FAILED: {len(FAIL)}')
print(f'{"="*50}')
if FAIL:
    print('FAILURES:')
    for f in FAIL:
        print(f'  - {f}')
    sys.exit(1)
print('ALL CHECKS PASSED')
'@
Write-Utf8NoBom -Path (Join-Path $API 'smoke_test.py') -Text $smoke
Write-Host "smoke_test.py written"

# --- 4.4 run_server.ps1 ----------------------------------------------
$runServer = @'
# Launch the SPROUT-Qonnect API on http://127.0.0.1:8000
# Usage: powershell -ExecutionPolicy Bypass -File run_server.ps1
$env:PYTHONPATH = 'C:\SPROUT-Qonnect\03_api'
Write-Host "Starting SPROUT-Qonnect API..." -ForegroundColor Cyan
Write-Host "Docs: http://127.0.0.1:8000/docs" -ForegroundColor Cyan
Write-Host "Health: http://127.0.0.1:8000/v1/health" -ForegroundColor Cyan
Write-Host "Ctrl+C to stop." -ForegroundColor Cyan
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
'@
Write-Utf8NoBom -Path (Join-Path $API 'run_server.ps1') -Text $runServer
Write-Host "run_server.ps1 written"

# --- 4.5 dependency check --------------------------------------------
Write-Host "`n=== 4.5 DEPENDENCY CHECK ===" -ForegroundColor Cyan
$depCheck = python -c "import fastapi, uvicorn, pydantic, shapely, pyproj, httpx; from fastapi.testclient import TestClient; print('deps ok')" 2>&1
if ($depCheck -match 'deps ok') {
    Write-Host "All imports OK" -ForegroundColor Green
} else {
    Write-Host "Missing deps: $depCheck" -ForegroundColor Yellow
    Write-Host "Running: pip install -r $API\requirements.txt"
    python -m pip install -r (Join-Path $API 'requirements.txt')
}

# --- 4.6 syntax check ------------------------------------------------
Write-Host "`n=== 4.6 SYNTAX CHECK ===" -ForegroundColor Cyan
$env:PYTHONPATH = $API
$syntax = python -c "import sys; sys.path.insert(0, r'$API'); from app.main import app; print('app imported ok, routes:', len(app.routes))" 2>&1
$syntax | Write-Host
if ($syntax -match 'app imported ok') {
    Write-Host "Syntax OK" -ForegroundColor Green
} else {
    Write-Host "Syntax FAILED - see above" -ForegroundColor Red
    Stop-Transcript | Out-Null
    exit 1
}

# --- 4.7 run smoke test ----------------------------------------------
Write-Host "`n=== 4.7 SMOKE TEST ===" -ForegroundColor Cyan
Push-Location $API
python smoke_test.py
$smokeExit = $LASTEXITCODE
Pop-Location
if ($smokeExit -eq 0) {
    Write-Host "`nSmoke test PASSED" -ForegroundColor Green
} else {
    Write-Host "`nSmoke test FAILED" -ForegroundColor Red
}

# --- 4.8 update tracker ----------------------------------------------
$tracker = @'
# SPROUT-Qonnect - Build Tracker

| # | Step | Status | Artifact |
|---|------|--------|----------|
| 1 | Environment audit + scaffold | DONE | 00_admin/environment_audit.csv |
| 2 | Phase 0 - Discovery & schema alignment | DONE | 01_discovery/ |
| 3 | Phase 1 - Database transformation | DONE | 02_database/ (SQLite) |
| 4 | Phase 2 - FastAPI service layer | DONE (pending endorsement) | 03_api/ |
| 5 | Phase 3 - Geospatial compliance hardening | NOT STARTED | 04_validation/ |
| 6 | Phase 4 - Qonnect/ECTMS integration rehearsal | NOT STARTED | 05_rehearsal/ |
| 7 | Phase 5 - Integration pack & Immediate Ask | NOT STARTED | 06_docs/ |

## Step 4 artifacts

- 03_api/app/main.py          (FastAPI app, all 7 endpoints)
- 03_api/smoke_test.py        (in-process end-to-end test)
- 03_api/run_server.ps1       (local launch helper)
- 03_api/requirements.txt

## Endpoint inventory

  GET  /v1/health
  GET  /v1/schema
  POST /v1/zone
  POST /v1/landcover
  POST /v1/agb
  POST /v1/risk
  GET  /v1/batch/{batch_code}

## Known deviations

- Nearest-neighbour demo inference: the _infer_* functions return the
  closest seeded plot's attribute with a distance-based confidence.
  Real inference attaches in Phase 3/4 without changing the API contract.
- Precision check (EUDR R2) not enforced at API boundary: float parsing
  makes decimal-place detection unreliable. Deferred to the serialization
  layer in the client integration spec.
'@
Write-Utf8NoBom -Path (Join-Path $ROOT '00_admin\STEP_TRACKER.md') -Text $tracker

Write-Host "`n=== STEP 4 COMPLETE ===" -ForegroundColor Green

Stop-Transcript | Out-Null