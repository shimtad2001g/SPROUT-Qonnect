# =====================================================================
# SPROUT-Qonnect | STEP 7a: Pipeline fix + Demo fix + Re-run
# =====================================================================
$ErrorActionPreference = 'Continue'
$ROOT = 'C:\SPROUT-Qonnect'
$SCR  = Join-Path $ROOT '05_rehearsal\scripts'
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
Start-Transcript -Path (Join-Path $ROOT "logs\step7a_$stamp.log") -Force | Out-Null

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

Write-Host "=== 7a.1 FIX PIPELINE ===" -ForegroundColor Cyan
$pipeline = @'
"""Qonnect -> SPROUT -> batch pipeline (rehearsal).

Fixes: (1) 422 short-circuits remaining endpoints; (2) errors deduped by rule_id.
"""
import json, time
from datetime import datetime, timezone
from pathlib import Path
import sys

sys.path.insert(0, r'C:\SPROUT-Qonnect\03_api')
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)
ENDPOINTS = ['zone', 'landcover', 'agb', 'risk']
ATTR_MAP = {
    'zone': ['sprout_zone'],
    'landcover': ['sprout_landcover', 'sprout_forest_flag'],
    'agb': ['sprout_agb_t_ha', 'sprout_agb_uncertainty'],
    'risk': ['sprout_risk_score'],
}

def _now_iso():
    return datetime.now(timezone.utc).isoformat(timespec='seconds')

def verify_plot(plot):
    record = {
        'plot_id': plot['plot_id'], 'geometry': plot['geometry'],
        'declared_area_ha': plot.get('area_ha'), 'status': 'verified',
        'attributes': {}, 'timings_ms': {}, 'errors': [],
        'model_version': None, 'computed_at': None,
    }
    body = {'plot_id': plot['plot_id'], 'geometry': plot['geometry'],
            'area_ha': plot.get('area_ha')}
    for ep in ENDPOINTS:
        t0 = time.perf_counter()
        r = client.post(f'/v1/{ep}', json=body)
        record['timings_ms'][ep] = round((time.perf_counter() - t0) * 1000.0, 2)
        if r.status_code == 200:
            payload = r.json()
            for key in ATTR_MAP[ep]:
                record['attributes'][key] = payload['attributes'].get(key)
            record['model_version'] = payload.get('model_version')
            record['computed_at'] = payload.get('computed_at')
        elif r.status_code == 422:
            record['status'] = 'rejected'
            for f in r.json().get('detail', {}).get('rules_failed', []):
                rec = {'rule_id': f.get('rule_id'), 'message': f.get('message')}
                if rec not in record['errors']:
                    record['errors'].append(rec)
            break
        elif r.status_code == 404:
            record['status'] = 'no_coverage'
            reason = r.json().get('detail', {}).get('reason', 'unknown')
            rec = {'rule_id': 'coverage', 'message': reason}
            if rec not in record['errors']:
                record['errors'].append(rec)
    return record

def run_pipeline(input_path):
    with open(input_path, encoding='utf-8') as f:
        qonnect = json.load(f)
    batch_code = None
    plot_records = []
    t0 = time.perf_counter()
    for farm in qonnect['farms']:
        batch_code = farm.get('batch_code', batch_code)
        for plot in farm['plots']:
            rec = verify_plot(plot)
            rec['farm_id'] = farm['farm_id']
            rec['crop'] = farm.get('crop')
            rec['batch_code'] = farm.get('batch_code')
            plot_records.append(rec)
    batch_elapsed_ms = (time.perf_counter() - t0) * 1000.0
    verified = [r for r in plot_records if r['status'] == 'verified']
    rejected = [r for r in plot_records if r['status'] != 'verified']
    total_area_ha = sum((r['declared_area_ha'] or 0.0) for r in verified)
    aggregated_agb = sum(
        (r['attributes'].get('sprout_agb_t_ha') or 0.0) * (r['declared_area_ha'] or 0.0)
        for r in verified
    )
    worst_risk = max((r['attributes'].get('sprout_risk_score') or 0.0) for r in verified) if verified else 0.0
    return {
        'input_file': str(input_path),
        'batch': {
            'batch_code': batch_code, 'ectms_batch_id': None,
            'plot_count_total': len(plot_records),
            'plot_count_verified': len(verified),
            'plot_count_rejected': len(rejected),
            'total_area_ha': round(total_area_ha, 4),
            'aggregated_agb_t': round(aggregated_agb, 4),
            'worst_case_risk_score': round(worst_risk, 4),
            'verification_status': 'verified' if not rejected else 'partial',
            'batch_elapsed_ms': round(batch_elapsed_ms, 2),
            'avg_plot_ms': round(batch_elapsed_ms / max(len(plot_records), 1), 2),
            'model_version': verified[0]['model_version'] if verified else None,
            'computed_at': _now_iso(),
        },
        'plots': plot_records,
    }
'@
Write-Utf8NoBom -Path (Join-Path $SCR 'pipeline.py') -Text $pipeline
Write-Host "pipeline.py fixed"

Write-Host "`n=== 7a.2 FIX DEMO ===" -ForegroundColor Cyan
$demo = @'
"""End-to-end demo: Qonnect -> SPROUT -> ECTMS GeoJSON."""
import json, sys
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')
except Exception:
    pass

sys.path.insert(0, str(Path(__file__).parent))
from pipeline import run_pipeline
from ectms_export import export

ROOT = Path(r'C:\SPROUT-Qonnect')
IN   = ROOT / '05_rehearsal' / 'input'  / 'qonnect_sample_batch.json'
OUT  = ROOT / '05_rehearsal' / 'output'
OUT.mkdir(parents=True, exist_ok=True)
pipeline_out = OUT / 'pipeline_result.json'
ectms_out    = OUT / 'ectms_featurecollection.json'

print('=' * 68)
print('SPROUT-Qonnect | End-to-End Integration Demo')
print('=' * 68)
print(f'Input : {IN.name}')
print()
print('Running pipeline...')
result = run_pipeline(IN)
with open(pipeline_out, 'w', encoding='utf-8') as f:
    json.dump(result, f, indent=2, ensure_ascii=False)
print(f'Pipeline result: {pipeline_out.name}')
print()

print('-' * 68)
print('BATCH SUMMARY')
print('-' * 68)
b = result['batch']
for k in ['batch_code','verification_status','plot_count_total',
          'plot_count_verified','plot_count_rejected','total_area_ha',
          'aggregated_agb_t','worst_case_risk_score',
          'batch_elapsed_ms','avg_plot_ms']:
    print(f'  {k:25s}: {b[k]}')
print()

print('-' * 68)
print('PER-PLOT VERDICT')
print('-' * 68)
for r in result['plots']:
    mark = 'OK    ' if r['status'] == 'verified' else 'REJECT'
    print(f'  [{mark}] {r["plot_id"]}  area={r["declared_area_ha"]}ha  '
          f'total_ms={sum(r["timings_ms"].values()):.1f}')
    if r['status'] == 'verified':
        a = r['attributes']
        print(f'           zone={a.get("sprout_zone")}  '
              f'lc={a.get("sprout_landcover")}  '
              f'forest={a.get("sprout_forest_flag")}  '
              f'agb={a.get("sprout_agb_t_ha")} +/- {a.get("sprout_agb_uncertainty")}  '
              f'risk={a.get("sprout_risk_score")}')
    else:
        for err in r['errors']:
            print(f'           {err["rule_id"]}: {err["message"][:80]}')
print()

print('Exporting ECTMS GeoJSON...')
collection = export(result, ectms_out)
print(f'ECTMS GeoJSON: {ectms_out.name}')
print(f'  features: {len(collection["features"])}')
print(f'  status  : {collection["verification_status"]}')
print()

print('-' * 68)
print('WHAT THIS PROVES')
print('-' * 68)
print(f'  [1] {b["plot_count_total"]} Qonnect-shaped plot records flowed through')
print(f'      all 4 SPROUT endpoints in {b["batch_elapsed_ms"]:.0f} ms.')
print(f'  [2] {b["plot_count_verified"]} verified, {b["plot_count_rejected"]} rejected '
      f'(rejection is a first-class state, not a crash).')
print(f'  [3] Batch is marked "{b["verification_status"]}" -- a partial batch.')
print(f'  [4] ECTMS FeatureCollection is ready for the EU TRACES submission.')
print(f'  [5] Every feature carries model_version and computed_at (EUDR R7).')
print()
print('Ready for the Immediate Ask meeting.')
'@
Write-Utf8NoBom -Path (Join-Path $SCR 'demo.py') -Text $demo
Write-Host "demo.py fixed (UTF-8 stdout, +/- not ±)"

Write-Host "`n=== 7a.3 RE-RUN DEMO ===" -ForegroundColor Cyan
$env:PYTHONIOENCODING = 'utf-8'
Push-Location $SCR
python demo.py
Pop-Location

Write-Host "`n=== 7a.4 VERIFY ECTMS OUTPUT ===" -ForegroundColor Cyan
python -c "import json; from pathlib import Path; p=Path(r'C:\SPROUT-Qonnect\05_rehearsal\output\ectms_featurecollection.json'); d=json.loads(p.read_text(encoding='utf-8')); print('features:',len(d['features'])); print('status:',d['verification_status']); r=[f for f in d['features'] if f['properties']['verification_status']=='rejected']; print('rejected:',len(r)); print('reasons:',[x['rule_id'] for x in r[0]['properties'].get('rejection_reasons',[])] if r else [])"

Write-Host "`n=== STEP 7a COMPLETE ===" -ForegroundColor Green

Stop-Transcript | Out-Null