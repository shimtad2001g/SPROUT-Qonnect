# =====================================================================
# SPROUT-Qonnect | STEP 3: Phase 1 - Database Transformation
# Detects Docker; uses PostGIS if up, SQLite otherwise.
# =====================================================================
$ErrorActionPreference = 'Continue'
$ROOT = 'C:\SPROUT-Qonnect'
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
Start-Transcript -Path (Join-Path $ROOT "logs\step3_db_$stamp.log") -Force | Out-Null

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

# --- 3.0 Schema: PostGIS ---------------------------------------------
Write-Host "=== 3.0 WRITING SCHEMA FILES ===" -ForegroundColor Cyan
$schemaPg = @'
CREATE TABLE IF NOT EXISTS zone_reference (
    zone_id SERIAL PRIMARY KEY,
    zone_name TEXT UNIQUE NOT NULL,
    zone_description TEXT,
    elevation_range TEXT,
    climate TEXT
);

CREATE TABLE IF NOT EXISTS plots (
    plot_id TEXT PRIMARY KEY,
    farm_id TEXT NOT NULL,
    area_ha DOUBLE PRECISION,
    geom geometry(GEOMETRY, 4326),
    sprout_zone TEXT REFERENCES zone_reference(zone_name),
    sprout_landcover TEXT,
    sprout_forest_flag BOOLEAN,
    sprout_agb_t_ha DOUBLE PRECISION,
    sprout_agb_uncertainty DOUBLE PRECISION,
    sprout_risk_score DOUBLE PRECISION,
    model_version TEXT,
    last_updated TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS plots_geom_idx ON plots USING GIST (geom);

CREATE TABLE IF NOT EXISTS batches (
    batch_code TEXT PRIMARY KEY,
    ectms_batch_id TEXT,
    total_area_ha DOUBLE PRECISION,
    aggregated_agb_t DOUBLE PRECISION,
    worst_case_risk_score DOUBLE PRECISION,
    plot_count INTEGER,
    verification_status TEXT,
    last_updated TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS batch_plots (
    batch_code TEXT REFERENCES batches(batch_code) ON DELETE CASCADE,
    plot_id TEXT REFERENCES plots(plot_id) ON DELETE CASCADE,
    PRIMARY KEY (batch_code, plot_id)
);

CREATE TABLE IF NOT EXISTS agb_model_metadata (
    model_version TEXT PRIMARY KEY,
    trained_on TEXT,
    validation_accuracy DOUBLE PRECISION,
    uncertainty_method TEXT,
    limitations TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS validation_log (
    log_id SERIAL PRIMARY KEY,
    input_hash TEXT,
    rule_results TEXT,
    passed BOOLEAN,
    validated_at TIMESTAMPTZ DEFAULT NOW()
);
'@
Write-Utf8NoBom -Path (Join-Path $ROOT '02_database\schema\01_schema_postgis.sql') -Text $schemaPg

# --- 3.1 Schema: SQLite ----------------------------------------------
$schemaSq = @'
CREATE TABLE IF NOT EXISTS zone_reference (
    zone_id INTEGER PRIMARY KEY AUTOINCREMENT,
    zone_name TEXT UNIQUE NOT NULL,
    zone_description TEXT,
    elevation_range TEXT,
    climate TEXT
);

CREATE TABLE IF NOT EXISTS plots (
    plot_id TEXT PRIMARY KEY,
    farm_id TEXT NOT NULL,
    area_ha REAL,
    geom_wkt TEXT,
    sprout_zone TEXT REFERENCES zone_reference(zone_name),
    sprout_landcover TEXT,
    sprout_forest_flag INTEGER,
    sprout_agb_t_ha REAL,
    sprout_agb_uncertainty REAL,
    sprout_risk_score REAL,
    model_version TEXT,
    last_updated TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS batches (
    batch_code TEXT PRIMARY KEY,
    ectms_batch_id TEXT,
    total_area_ha REAL,
    aggregated_agb_t REAL,
    worst_case_risk_score REAL,
    plot_count INTEGER,
    verification_status TEXT,
    last_updated TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS batch_plots (
    batch_code TEXT REFERENCES batches(batch_code) ON DELETE CASCADE,
    plot_id TEXT REFERENCES plots(plot_id) ON DELETE CASCADE,
    PRIMARY KEY (batch_code, plot_id)
);

CREATE TABLE IF NOT EXISTS agb_model_metadata (
    model_version TEXT PRIMARY KEY,
    trained_on TEXT,
    validation_accuracy REAL,
    uncertainty_method TEXT,
    limitations TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS validation_log (
    log_id INTEGER PRIMARY KEY AUTOINCREMENT,
    input_hash TEXT,
    rule_results TEXT,
    passed INTEGER,
    validated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
'@
Write-Utf8NoBom -Path (Join-Path $ROOT '02_database\schema\01_schema_sqlite.sql') -Text $schemaSq
Write-Host "schema files written"

# --- 3.2 Seed loader -------------------------------------------------
$loader = @'
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
'@
Write-Utf8NoBom -Path (Join-Path $ROOT '02_database\scripts\load_seed.py') -Text $loader

# --- 3.3 Verifier ----------------------------------------------------
$verifier = @'
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
'@
Write-Utf8NoBom -Path (Join-Path $ROOT '02_database\scripts\verify.py') -Text $verifier
Write-Host "loader + verifier written"

# --- 3.4 Detect Docker daemon ----------------------------------------
Write-Host "`n=== 3.4 DOCKER DETECTION ===" -ForegroundColor Cyan
$dockerUp = $false
try {
    $info = docker info --format '{{.ServerVersion}}' 2>&1
    if ($LASTEXITCODE -eq 0 -and $info -and ($info -notmatch 'error')) {
        $dockerUp = $true
        Write-Host "Docker daemon UP (server $info)" -ForegroundColor Green
    } else {
        Write-Host "Docker daemon DOWN: $info" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Docker detection error: $_" -ForegroundColor Yellow
}

$engine = 'sqlite'
if ($dockerUp) {
    try {
        Write-Host "`nPulling PostGIS image (cached if up to date)..."
        docker pull postgis/postgis:16-3.4
        if ($LASTEXITCODE -eq 0) {
            docker rm -f sprout-postgis 2>$null | Out-Null
            Write-Host "Starting PostGIS container on port 5433..."
            docker run -d --name sprout-postgis `
                -e POSTGRES_PASSWORD=sprout_dev `
                -e POSTGRES_DB=sprout `
                -p 5433:5432 `
                postgis/postgis:16-3.4 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $ready = $false
                for ($i = 0; $i -lt 24; $i++) {
                    Start-Sleep -Seconds 5
                    $stat = docker exec sprout-postgis pg_isready -U postgres 2>&1
                    if ($stat -match 'accepting connections') {
                        $ready = $true; break
                    }
                    Write-Host "  waiting for PostGIS ($(($i+1)*5)s)..."
                }
                if ($ready) { $engine = 'postgis'; Write-Host "PostGIS ready" -ForegroundColor Green }
                else { Write-Host "PostGIS not ready after 120s; falling back to SQLite" -ForegroundColor Yellow }
            }
        } else {
            Write-Host "docker pull failed; falling back to SQLite" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Docker path error: $_; falling back to SQLite" -ForegroundColor Yellow
    }
}

Write-Host "`n=== ENGINE SELECTED: $engine ===" -ForegroundColor Cyan

# --- 3.5 Apply DDL + load + verify -----------------------------------
if ($engine -eq 'postgis') {
    Write-Host "`nApplying PostGIS DDL via docker cp + psql..."
    $schemaPath = Join-Path $ROOT '02_database\schema\01_schema_postgis.sql'
    docker cp $schemaPath sprout-postgis:/tmp/schema.sql | Out-Null
    docker exec sprout-postgis psql -U postgres -d sprout -v ON_ERROR_STOP=1 -f /tmp/schema.sql
    Write-Host "`nLoading seed..."
    python (Join-Path $ROOT '02_database\scripts\load_seed.py') --engine postgis
    Write-Host "`nVerifying..."
    python (Join-Path $ROOT '02_database\scripts\verify.py') --engine postgis
} else {
    Write-Host "`nLoading seed (SQLite)..."
    python (Join-Path $ROOT '02_database\scripts\load_seed.py') --engine sqlite
    Write-Host "`nVerifying..."
    python (Join-Path $ROOT '02_database\scripts\verify.py') --engine sqlite
}

# --- 3.6 Update tracker ----------------------------------------------
$tracker = @'
# SPROUT-Qonnect - Build Tracker

| # | Step | Status | Artifact |
|---|------|--------|----------|
| 1 | Environment audit + scaffold | DONE | 00_admin/environment_audit.csv |
| 2 | Phase 0 - Discovery & schema alignment | DONE | 01_discovery/ |
| 3 | Phase 1 - Database transformation | DONE (pending endorsement) | 02_database/ |
| 4 | Phase 2 - FastAPI service layer | NOT STARTED | 03_api/ |
| 5 | Phase 3 - Geospatial compliance hardening | NOT STARTED | 04_validation/ |
| 6 | Phase 4 - Qonnect/ECTMS integration rehearsal | NOT STARTED | 05_rehearsal/ |
| 7 | Phase 5 - Integration pack & Immediate Ask | NOT STARTED | 06_docs/ |

## Step 3 artifacts

- 02_database/schema/01_schema_postgis.sql
- 02_database/schema/01_schema_sqlite.sql
- 02_database/scripts/load_seed.py
- 02_database/scripts/verify.py
- 00_admin/step3_engine.txt     (records which engine was used)
- data/sprout.db                (only if SQLite path ran)

## Known deviations

- PostGIS runs on port 5433 to avoid local conflicts.
- SQLite fallback stores geometry as WKT TEXT; migrate to PostGIS before Phase 3.
'@
Write-Utf8NoBom -Path (Join-Path $ROOT '00_admin\STEP_TRACKER.md') -Text $tracker

Write-Host "`n=== STEP 3 COMPLETE ===" -ForegroundColor Green
Write-Host "Engine: $engine"
Write-Host "Engine record: $ROOT\00_admin\step3_engine.txt"

Stop-Transcript | Out-Null