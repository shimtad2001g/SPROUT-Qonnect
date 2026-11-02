# =====================================================================
# SPROUT-Qonnect | STEP 8: TraceRight Consortium Portal (Streamlit)
# =====================================================================
$ErrorActionPreference = 'Continue'
$ROOT = 'C:\SPROUT-Qonnect'
$DASH = Join-Path $ROOT '07_dashboard'
New-Item -ItemType Directory -Force -Path $DASH | Out-Null

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

Write-Host "=== 8.1 BUILDING DASHBOARD ===" -ForegroundColor Cyan

$app = @'
import streamlit as st
import json
import httpx
from pathlib import Path
import pandas as pd

# CONFIGURATION
API_URL = "http://127.0.0.1:8000"
DB_PATH = Path(r"C:\SPROUT-Qonnect\data\sprout.db")
BATCH_CODE = "QON-COF-2026-00001"

st.set_page_config(page_title="TraceRight Consortium Portal", layout="wide")

# HEADER
st.title("🌍 TraceRight Satellite International Consortium")
st.markdown("**End-to-End Traceability • Deforestation Monitoring • Carbon Accounting**")
st.divider()

# SIDEBAR - LAYER NAVIGATION
layer = st.sidebar.radio(
    "Select Architecture Layer",
    [
        "🌱 Layer 1 & 2: Mobile & Fair AI (SPROUT)",
        "🔗 Layer 3: Permissioned Ledger (Fabric)",
        "🪙 Layer 4: Public Ledger (Polygon)",
        "🏛️ External: ECTMS & EU TRACES"
    ]
)

# FETCH DATA (Simulated via API or Direct DB for demo)
def get_batch_data():
    try:
        r = httpx.get(f"{API_URL}/v1/batch/{BATCH_CODE}")
        if r.status_code == 200:
            return r.json()
    except:
        pass
    
    # Fallback mock
    return {
        "batch_code": BATCH_CODE,
        "verification_status": "partial",
        "plot_count_total": 3,
        "plot_count_verified": 2,
        "plot_count_rejected": 1,
        "total_area_ha": 6.2,
        "aggregated_agb_t": 656.74,
        "worst_case_risk_score": 0.35,
        "plots": [
            {"plot_id": "PLT-GAMO-0001", "sprout_zone": "Kolla", "sprout_landcover": "agroforestry", "sprout_forest_flag": False, "sprout_agb_t_ha": 45.2, "sprout_agb_uncertainty": 8.1},
            {"plot_id": "PLT-GAMO-0002", "sprout_zone": "Weyna Dega", "sprout_landcover": "forest", "sprout_forest_flag": True, "sprout_agb_t_ha": 120.5, "sprout_agb_uncertainty": 15.3},
            {"plot_id": "PLT-GAMO-0003", "sprout_zone": "Dega", "sprout_landcover": "shrubland", "sprout_forest_flag": False, "sprout_agb_t_ha": 60.8, "sprout_agb_uncertainty": 9.5, "status": "rejected", "reason": "R5_area_plausible"}
        ]
    }

data = get_batch_data()

# =====================================================================
# LAYER 1 & 2: MOBILE & FAIR AI
# =====================================================================
if layer == "🌱 Layer 1 & 2: Mobile & Fair AI (SPROUT)":
    st.header("Layer 1 & 2: Mobile Data Capture & Fair AI Analysis")
    
    col1, col2 = st.columns(2)
    with col1:
        st.info("📱 **Layer 1: Mobile Layer**")
        st.write("IME Ime App & Qonnect Origin App")
        st.write("- Offline GPS polygon mapping")
        st.write("- Geo-tagged farm boundaries")
        st.write("- Farmer consent capture")
        
    with col2:
        st.success("🧠 **Layer 2: Fair AI Layer**")
        st.write("SPROUT GeoAI & NADAR Deforestation Detection")
        st.write("- Land-use classification")
        st.write("- Shade coffee detection")
        st.write("- Farm risk scoring")
        
    st.divider()
    
    st.subheader(f"Batch: {data['batch_code']} - Plot Analysis")
    
    for plot in data['plots']:
        with st.expander(f"📍 {plot['plot_id']} - {plot.get('sprout_zone', 'Unknown')}", expanded=True):
            c1, c2, c3, c4 = st.columns(4)
            c1.metric("Ecological Zone", plot.get('sprout_zone', 'N/A'))
            c2.metric("Land Cover", plot.get('sprout_landcover', 'N/A'))
            c3.metric("Forest Flag", "YES" if plot.get('sprout_forest_flag') else "NO")
            
            agb = plot.get('sprout_agb_t_ha', 0)
            unc = plot.get('sprout_agb_uncertainty', 0)
            c4.metric("AGB (t/ha)", f"{agb} ± {unc}")
            
            if plot.get('status') == 'rejected':
                st.error(f"❌ **REJECTED** by EUDR Rule: {plot.get('reason')}")
            else:
                st.success("✅ Verified by SPROUT GeoAI")

# =====================================================================
# LAYER 3: PERMISSIONED LEDGER
# =====================================================================
elif layer == "🔗 Layer 3: Permissioned Ledger (Fabric)":
    st.header("Layer 3: Hyperledger Fabric Permissioned Ledger")
    st.write("Smart Contracts & Chain of Custody")
    
    st.subheader("Smart Contract Status")
    sc1, sc2, sc3 = st.columns(3)
    sc1.success("✅ EUDR Compliance\n\nDue diligence • Risk assessment")
    sc2.warning("⏳ Chain of Custody\n\nBatch tracking • Provenance records")
    sc3.success("✅ Rainforest Alliance\n\nSustainability criteria • Audit verification")
    
    st.divider()
    
    st.subheader("Consortium Node Validation")
    nodes = ["ECTA", "Ethiopian Forest Development", "Qonnect", "Dedego", "SPROUT", "Nadar", "EU Buyer Node"]
    for node in nodes:
        st.write(f"- 🟢 {node} (Synced)")
        
    st.divider()
    
    st.subheader("Batch Verification Status")
    if data['verification_status'] == 'partial':
        st.error(f"⚠️ **Batch marked PARTIAL**: {data['plot_count_rejected']} plot(s) failed EUDR validation. EU Buyer Node will reject DDS generation.")
    else:
        st.success("✅ **Batch fully VERIFIED**: All plots passed SPROUT GeoAI. Ready for EU TRACES.")
        
    st.write("**Rejected Plots:**")
    for plot in data['plots']:
        if plot.get('status') == 'rejected':
            st.write(f"- {plot['plot_id']}: {plot.get('reason')}")

# =====================================================================
# LAYER 4: PUBLIC LEDGER
# =====================================================================
elif layer == "🪙 Layer 4: Public Ledger (Polygon)":
    st.header("Layer 4: Public Ledger (Polygon)")
    st.write("NFT Product Passports & tCO2 Tokens")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.info("🎫 **NFT Product Passport**")
        st.write("Unique NFT per coffee batch")
        st.write("- Immutable traceability record")
        st.write("- QR for consumer transparency")
        
        st.image("https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=" + data['batch_code'], caption=f"NFT: {data['batch_code']}")
        
    with col2:
        st.success("🌱 **tCO₂ Token**")
        st.write("1 token = 1 tonne CO₂e")
        st.write("Carbon credit tokenization")
        
        agb_t = data['aggregated_agb_t']
        tco2 = agb_t * 0.5
        st.metric(label="Estimated tCO₂ Tokenizable", value=f"{tco2:,.2f} tCO₂e")
        
        if data['verification_status'] != 'verified':
            st.warning("⚠️ Tokenization paused due to rejected plots in batch.")
        else:
            st.button("Mint tCO₂ Tokens (Polygon)")

# =====================================================================
# EXTERNAL: ECTMS & EU TRACES
# =====================================================================
else:
    st.header("External Systems Integration")
    
    st.info("🏛️ **ECTMS (Ethiopian Coffee Traceability Management System)**")
    st.write("National system sync • Regulatory reporting")
    st.write("Status: 🟢 Connected")
    
    st.divider()
    
    st.success("🇪🇺 **EU TRACES / Information System**")
    st.write("EU import compliance • TRACES NT integration")
    
    if data['verification_status'] == 'verified':
        st.button("Generate DDS (Due Diligence Statement)")
        st.download_button(
            label="Download ECTMS GeoJSON",
            data=json.dumps(data, indent=2),
            file_name=f"{data['batch_code']}_ectms.json",
            mime="application/json"
        )
    else:
        st.error("⛔ Cannot generate DDS. Batch is PARTIAL. Resolve rejected plots in Layer 2.")
'@

Write-Utf8NoBom -Path (Join-Path $DASH 'app.py') -Text $app

$runDash = @'
# Launch the TraceRight Consortium Portal
$env:PYTHONPATH = 'C:\SPROUT-Qonnect\03_api'
Write-Host "Starting TraceRight Dashboard..." -ForegroundColor Cyan
Write-Host "Open: http://127.0.0.1:8501" -ForegroundColor Green
streamlit run C:\SPROUT-Qonnect\07_dashboard\app.py
'@
Write-Utf8NoBom -Path (Join-Path $DASH 'run_dashboard.ps1') -Text $runDash

Write-Host "Dashboard written to $DASH\app.py"
Write-Host "=== STEP 8 COMPLETE ===" -ForegroundColor Green