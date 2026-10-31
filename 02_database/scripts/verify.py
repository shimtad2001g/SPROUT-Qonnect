#!/usr/bin/env python3
"""SPROUT-Qonnect Step 3 verification."""
import argparse, sqlite3
from pathlib import Path

ROOT = Path(r'C:\SPROUT-Qonnect')
DB_SQLITE = ROOT / 'data' / 'sprout.db'
TABLES = ['zone_reference','plots','batches','batch_plots','agb_model_metadata','validation_log']

def report_counts(cur, ph):
    for t in TABLES:
        cur.execute(f'SELECT COUNT(*) FROM {t}')
        print(f'  {t:22s}: {cur.fetchone()[0]} rows')

def report_batch(cur, ph):
    cur.execute(f'''SELECT batch_code,plot_count,total_area_ha,
        aggregated_agb_t,worst_case_risk_score
        FROM batches WHERE batch_code = {ph}''',('QON-COF-2026-00001',))
    r = cur.fetchone()
    print(f'  batch={r[0]} plots={r[1]} area={r[2]:.2f}ha agb={r[3]:.2f}t risk={r[4]:.2f}')

def report_zones(cur):
    cur.execute('''SELECT sprout_zone,COUNT(*),AVG(sprout_agb_t_ha)
        FROM plots GROUP BY sprout_zone ORDER BY sprout_zone''')
    for r in cur.fetchall():
        print(f'  zone={r[0]:12s} plots={r[1]} avg_agb={r[2]:.1f} t/ha')

def verify_sqlite():
    conn = sqlite3.connect(DB_SQLITE); cur = conn.cursor()
    print('--- counts (sqlite) ---'); report_counts(cur,'?')
    print('--- batch aggregation ---'); report_batch(cur,'?')
    print('--- zone distribution ---'); report_zones(cur)
    conn.close()

def verify_postgis():
    import psycopg2
    conn = psycopg2.connect(host='localhost',port=5433,dbname='sprout',
                            user='postgres',password='sprout_dev')
    cur = conn.cursor()
    print('--- counts (postgis) ---'); report_counts(cur,'%s')
    print('--- batch aggregation ---'); report_batch(cur,'%s')
    print('--- zone distribution ---'); report_zones(cur)
    print('--- spatial check: geom area (EPSG:32637) vs declared area ---')
    cur.execute('''SELECT plot_id,area_ha,
        ST_Area(ST_Transform(geom,32637))/10000.0 AS geom_area_ha
        FROM plots ORDER BY plot_id''')
    for r in cur.fetchall():
        print(f'  {r[0]}: declared={r[1]:.3f}ha geom={r[2]:.3f}ha')
    conn.close()

if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--engine', choices=['postgis','sqlite'], required=True)
    a = ap.parse_args()
    verify_sqlite() if a.engine == 'sqlite' else verify_postgis()