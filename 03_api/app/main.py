"""SPROUT-Qonnect FastAPI service layer (Phase 2).

Reads from the SQLite database created in Phase 1.
Implements the alignment contract response envelope.
Enforces EUDR rules R3, R4, R5, R7 at the request boundary.
"""
from datetime import datetime, timezone
from pathlib import Path
import sqlite3
import hashlib
import json

from fastapi import FastAPI, HTTPException, Body
from pydantic import BaseModel, Field
from shapely.geometry import shape

from app.services.eudr_validator import validate_geometry
from app.services.nadar_client import fetch_prediction

DB_PATH = Path(r'C:\SPROUT-Qonnect\data\sprout.db')
MODEL_VERSION = 'sprout-ssl-agb-v0.9'

app = FastAPI(
    title='SPROUT-Qonnect API',
    version='0.9.2',
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

@app.post('/v1/zone')
def post_zone(req: PlotRequest = Body(...)):
    geom, passed = _validate(req)
    value, conf, reason = fetch_prediction(geom, 'sprout_zone')
    if value is None:
        raise HTTPException(404, detail={'reason': reason, 'rules_passed': passed})
    return _envelope(req.plot_id, {'sprout_zone': value}, passed, [], conf, reason)

@app.post('/v1/landcover')
def post_landcover(req: PlotRequest = Body(...)):
    geom, passed = _validate(req)
    lc, conf, reason = fetch_prediction(geom, 'sprout_landcover')
    if lc is None:
        raise HTTPException(404, detail={'reason': reason, 'rules_passed': passed})
    forest, _, _ = fetch_prediction(geom, 'sprout_forest_flag')
    return _envelope(req.plot_id,
        {'sprout_landcover': lc, 'sprout_forest_flag': forest},
        passed, [], conf, reason)

@app.post('/v1/agb')
def post_agb(req: PlotRequest = Body(...)):
    geom, passed = _validate(req)
    agb, conf, reason = fetch_prediction(geom, 'sprout_agb_t_ha')
    if agb is None:
        raise HTTPException(404, detail={'reason': reason, 'rules_passed': passed})
    unc, _, _ = fetch_prediction(geom, 'sprout_agb_uncertainty')
    return _envelope(req.plot_id,
        {'sprout_agb_t_ha': agb, 'sprout_agb_uncertainty': unc},
        passed, [], conf, reason)

@app.post('/v1/risk')
def post_risk(req: PlotRequest = Body(...)):
    geom, passed = _validate(req)
    risk, conf, reason = fetch_prediction(geom, 'sprout_risk_score')
    if risk is None:
        raise HTTPException(404, detail={'reason': reason, 'rules_passed': passed})
    return _envelope(req.plot_id,
        {'sprout_risk_score': risk,
         'risk_factors': ['baseline_year_2020', 'nadar_sandbox']},
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

    plots_list = [dict(p) for p in plots]
    fabric_hash = hashlib.sha256(json.dumps(plots_list, sort_keys=True).encode('utf-8')).hexdigest()

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
        'plots': plots_list,
        'fabric_hash': fabric_hash
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