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