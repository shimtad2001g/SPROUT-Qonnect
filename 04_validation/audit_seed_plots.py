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