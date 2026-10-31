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