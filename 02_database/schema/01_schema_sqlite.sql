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