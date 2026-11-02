"""NADAR ESA Sandbox API Adapter.

Currently uses local nearest-neighbour logic to simulate the NADAR response.
When the real NADAR API credentials are provided, only the fetch_prediction
function body needs to change. The return signature remains identical.
"""
from shapely.geometry import shape
from pyproj import Geod
import sqlite3
from pathlib import Path

DB_PATH = Path(r'C:\SPROUT-Qonnect\data\sprout.db')
GEOD = Geod(ellps='WGS84')
NEAREST_CUTOFF_M = 10000.0

def fetch_prediction(geom, attribute):
    """
    Simulates fetching data from the NADAR ESA sandbox.
    Returns: (value, confidence, reason)
    """
    if geom.is_empty:
        return None, 0.0, 'empty_geometry'

    point = geom if geom.geom_type == 'Point' else geom.centroid
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    rows = conn.execute('SELECT * FROM plots').fetchall()
    conn.close()
    
    from shapely import wkt as _wkt
    best_row, best_dist = None, float('inf')
    
    for row in rows:
        try:
            plot_geom = _wkt.loads(row['geom_wkt'])
        except Exception:
            continue
        plot_point = plot_geom if plot_geom.geom_type == 'Point' else plot_geom.centroid
        dist = GEOD.inv(point.x, point.y, plot_point.x, plot_point.y)[2]
        if dist < best_dist:
            best_row, best_dist = row, dist

    if best_row is None or best_dist > NEAREST_CUTOFF_M:
        return None, 0.0, 'no_nadar_coverage_within_10km'

    conf = 0.95 if best_dist < 100 else (0.85 if best_dist < 500 else 0.60)
    value = best_row[attribute]
    if attribute == 'sprout_forest_flag':
        value = bool(value)
        
    return value, conf, f'nadar_sandbox_adapter (dist={best_dist:.0f}m)'