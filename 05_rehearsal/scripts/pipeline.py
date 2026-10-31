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