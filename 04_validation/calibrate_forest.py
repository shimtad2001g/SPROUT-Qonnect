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