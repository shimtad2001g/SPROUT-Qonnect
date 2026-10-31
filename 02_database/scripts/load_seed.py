#!/usr/bin/env python3
"""SPROUT-Qonnect Step 3 seed loader. Supports postgis and sqlite."""
import argparse, sqlite3
from pathlib import Path

ROOT = Path(r'C:\SPROUT-Qonnect')
DB_SQLITE = ROOT / 'data' / 'sprout.db'
SCHEMA_SQLITE = ROOT / '02_database' / 'schema' / '01_schema_sqlite.sql'
STATUS_FILE = ROOT / '00_admin' / 'step3_engine.txt'

ZONES = [
    ('Wurch',     'High-altitude afro-alpine',  '>3200m',    'cold humid'),
    ('Dega',      'Highland cool',              '2300-3200m','cool humid'),
    ('Weyna Dega','Mid-altitude temperate',     '1500-2300m','warm humid'),
    ('Kolla',     'Lowland warm',               '500-1500m', 'warm sub-humid'),
    ('Bereha',    'Arid lowland',               '<500m',     'hot arid'),
]

PLOTS = [
    {'plot_id':'PLT-GAMO-0001','farm_id':'FRM-GAMO-0001','area_ha':1.2,
     'wkt':'POLYGON((37.550001 5.999999, 37.551001 5.999999, 37.551001 6.001001, 37.550001 6.001001, 37.550001 5.999999))',
     'zone':'Kolla','landcover':'agroforestry','forest_flag':False,
     'agb':45.2,'agb_u':8.1,'risk':0.35},
    {'plot_id':'PLT-GAMO-0002','farm_id':'FRM-GAMO-0002','area_ha':5.0,
     'wkt':'POLYGON((37.570001 6.249999, 37.572001 6.249999, 37.572001 6.252001, 37.570001 6.252001, 37.570001 6.249999))',
     'zone':'Weyna Dega','landcover':'forest','forest_flag':True,
     'agb':120.5,'agb_u':15.3,'risk':0.10},
    {'plot_id':'PLT-GAMO-0003','farm_id':'FRM-GAMO-0003','area_ha':2.0,
     'wkt':'POLYGON((37.600001 6.399999, 37.601001 6.399999, 37.601001 6.401001, 37.600001 6.401001, 37.600001 6.399999))',
     'zone':'Dega','landcover':'shrubland','forest_flag':False,
     'agb':60.8,'agb_u':9.5,'risk':0.25},
]

BATCH = {'batch_code':'QON-COF-2026-00001','ectms_batch_id':None,
         'plot_ids':['PLT-GAMO-0001','PLT-GAMO-0002','PLT-GAMO-0003']}

MODEL = {'model_version':'sprout-ssl-agb-v0.9',
         'trained_on':'Sentinel-1/2 + GEDI composites, 2020-2025',
         'validation_accuracy':0.82,
         'uncertainty_method':'ensemble std (5-fold)',
         'limitations':'No field calibration for shade-coffee; assumed uniform canopy density.'}

def batch_stats():
    total_area = sum(p['area_ha'] for p in PLOTS)
    total_agb  = sum(p['agb'] * p['area_ha'] for p in PLOTS)
    worst_risk = max(p['risk'] for p in PLOTS)
    return total_area, total_agb, worst_risk, len(PLOTS)

def load_sqlite():
    print('Loading SQLite at', DB_SQLITE)
    DB_SQLITE.parent.mkdir(parents=True, exist_ok=True)
    if DB_SQLITE.exists(): DB_SQLITE.unlink()
    conn = sqlite3.connect(DB_SQLITE); cur = conn.cursor()
    cur.executescript(SCHEMA_SQLITE.read_text(encoding='utf-8'))
    cur.executemany('INSERT INTO zone_reference (zone_name,zone_description,elevation_range,climate) VALUES (?,?,?,?)', ZONES)
    for p in PLOTS:
        cur.execute('''INSERT INTO plots (plot_id,farm_id,area_ha,geom_wkt,
            sprout_zone,sprout_landcover,sprout_forest_flag,sprout_agb_t_ha,
            sprout_agb_uncertainty,sprout_risk_score,model_version)
            VALUES (?,?,?,?,?,?,?,?,?,?,?)''',
            (p['plot_id'],p['farm_id'],p['area_ha'],p['wkt'],p['zone'],p['landcover'],
             int(p['forest_flag']),p['agb'],p['agb_u'],p['risk'],MODEL['model_version']))
    ta,tg,wr,pc = batch_stats()
    cur.execute('''INSERT INTO batches (batch_code,ectms_batch_id,total_area_ha,
        aggregated_agb_t,worst_case_risk_score,plot_count,verification_status)
        VALUES (?,?,?,?,?,?,?)''',(BATCH['batch_code'],BATCH['ectms_batch_id'],ta,tg,wr,pc,'pending'))
    for pid in BATCH['plot_ids']:
        cur.execute('INSERT INTO batch_plots (batch_code,plot_id) VALUES (?,?)',(BATCH['batch_code'],pid))
    cur.execute('''INSERT INTO agb_model_metadata (model_version,trained_on,
        validation_accuracy,uncertainty_method,limitations) VALUES (?,?,?,?,?)''',
        (MODEL['model_version'],MODEL['trained_on'],MODEL['validation_accuracy'],
         MODEL['uncertainty_method'],MODEL['limitations']))
    conn.commit(); conn.close()
    STATUS_FILE.write_text(f'sqlite\n{DB_SQLITE}\n', encoding='utf-8')
    print('SQLite loaded OK')

def load_postgis():
    import psycopg2
    print('Loading PostGIS on localhost:5433/sprout')
    conn = psycopg2.connect(host='localhost',port=5433,dbname='sprout',
                            user='postgres',password='sprout_dev')
    cur = conn.cursor()
    cur.execute('TRUNCATE batch_plots, batches, plots, zone_reference, agb_model_metadata RESTART IDENTITY CASCADE')
    cur.executemany('INSERT INTO zone_reference (zone_name,zone_description,elevation_range,climate) VALUES (%s,%s,%s,%s)', ZONES)
    for p in PLOTS:
        cur.execute('''INSERT INTO plots (plot_id,farm_id,area_ha,geom,
            sprout_zone,sprout_landcover,sprout_forest_flag,sprout_agb_t_ha,
            sprout_agb_uncertainty,sprout_risk_score,model_version)
            VALUES (%s,%s,%s,ST_GeomFromText(%s,4326),%s,%s,%s,%s,%s,%s,%s)''',
            (p['plot_id'],p['farm_id'],p['area_ha'],p['wkt'],p['zone'],p['landcover'],
             p['forest_flag'],p['agb'],p['agb_u'],p['risk'],MODEL['model_version']))
    ta,tg,wr,pc = batch_stats()
    cur.execute('''INSERT INTO batches (batch_code,ectms_batch_id,total_area_ha,
        aggregated_agb_t,worst_case_risk_score,plot_count,verification_status)
        VALUES (%s,%s,%s,%s,%s,%s,%s)''',(BATCH['batch_code'],BATCH['ectms_batch_id'],ta,tg,wr,pc,'pending'))
    for pid in BATCH['plot_ids']:
        cur.execute('INSERT INTO batch_plots (batch_code,plot_id) VALUES (%s,%s)',(BATCH['batch_code'],pid))
    cur.execute('''INSERT INTO agb_model_metadata (model_version,trained_on,
        validation_accuracy,uncertainty_method,limitations) VALUES (%s,%s,%s,%s,%s)''',
        (MODEL['model_version'],MODEL['trained_on'],MODEL['validation_accuracy'],
         MODEL['uncertainty_method'],MODEL['limitations']))
    conn.commit(); conn.close()
    STATUS_FILE.write_text('postgis\nlocalhost:5433/sprout\n', encoding='utf-8')
    print('PostGIS loaded OK')

if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--engine', choices=['postgis','sqlite'], required=True)
    a = ap.parse_args()
    load_sqlite() if a.engine == 'sqlite' else load_postgis()