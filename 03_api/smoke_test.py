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
    check('batch has fabric_hash', len(d.get('fabric_hash', '')) == 64)

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