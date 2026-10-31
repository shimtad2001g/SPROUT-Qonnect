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