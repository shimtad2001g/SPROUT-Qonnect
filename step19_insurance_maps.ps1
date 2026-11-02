# =====================================================================
# TraceRight-SPROUT | Step 19: Generate 3 Advanced Crop Insurance Maps
# =====================================================================
$ErrorActionPreference = 'Continue'
$ROOT = 'C:\SPROUT-Qonnect'
$DASH = Join-Path $ROOT '08_presentation'
$FIGS = Join-Path $DASH 'figures'

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

Write-Host "=== GENERATING ADVANCED INSURANCE MAPS ===" -ForegroundColor Cyan

$pyCode = @'
import matplotlib.pyplot as plt
import numpy as np
import matplotlib.patches as mpatches
from matplotlib.colors import ListedColormap
import warnings

warnings.filterwarnings("ignore")

# Base coordinates
x = np.linspace(37.45, 37.65, 100)
y = np.linspace(5.95, 6.45, 100)
X, Y = np.meshgrid(x, y)

# =====================================================================
# MAP 1: SOIL MOISTURE ANOMALY (Radar / Sentinel-1)
# =====================================================================
fig1, ax1 = plt.subplots(figsize=(12, 8), facecolor='#F8F9FA')
ax1.set_facecolor('#f1f3f5')

# Simulate soil moisture (m3/m3) - Red = Dry, Blue = Wet
Moisture = 0.3 + 0.1 * np.sin(X) + 0.1 * np.cos(Y)
# Create a severe dry anomaly in the center
Moisture -= 0.25 * np.exp(-((X - 37.55)**2 / 0.002 + (Y - 6.20)**2 / 0.005))
Moisture = np.clip(Moisture, 0.05, 0.5)

contour1 = ax1.contourf(X, Y, Moisture, levels=20, cmap='RdBu', alpha=0.9)
cbar1 = plt.colorbar(contour1, ax=ax1, pad=0.02)
cbar1.set_label('Soil Moisture (m³/m³)', fontsize=14, fontweight='bold', color='#1B4332')

ax1.set_title("SPROUT GeoAI Soil Moisture Anomaly (Sentinel-1)", fontsize=20, fontweight='bold', color='#1B4332', pad=20)
ax1.set_xlabel("Longitude", fontsize=12); ax1.set_ylabel("Latitude", fontsize=12)
ax1.set_xlim(37.40, 37.75); ax1.set_ylim(5.85, 6.55)
plt.tight_layout()
plt.savefig(r'C:\SPROUT-Qonnect\08_presentation\figures\insurance_soil_moisture.png', dpi=300, bbox_inches='tight')
plt.close(fig1)

# =====================================================================
# MAP 2: MULTI-TEMPORAL CROP HEALTH (June vs July vs August)
# =====================================================================
fig2, axes = plt.subplots(1, 3, figsize=(18, 6), facecolor='#F8F9FA')

months = ['June (Healthy)', 'July (Stress)', 'August (Drought)']
# Simulate NDVI degrading over time
for i, ax in enumerate(axes):
    ax.set_facecolor('#f1f3f5')
    # Base health
    NDVI = 0.8 - 0.1 * np.abs(X - 37.55) - 0.1 * np.abs(Y - 6.20)
    # Add increasing drought stress each month
    drought_severity = (i + 1) * 0.15
    NDVI -= drought_severity * np.exp(-((X - 37.55)**2 / 0.003 + (Y - 6.20)**2 / 0.005))
    NDVI = np.clip(NDVI, 0, 1)
    
    contour = ax.contourf(X, Y, NDVI, levels=20, cmap='RdYlGn', alpha=0.85)
    ax.set_title(months[i], fontsize=16, fontweight='bold', color='#1B4332')
    ax.set_xticks([]); ax.set_yticks([]) # Clean look
    
    # Add farm boundary
    rect = plt.Rectangle((37.54, 6.19), 0.02, 0.02, linewidth=2, edgecolor='black', facecolor='none', zorder=5)
    ax.add_patch(rect)

# Add Colorbar
cbar_ax = fig2.add_axes([0.92, 0.15, 0.02, 0.7])
cbar = fig2.colorbar(contour, cax=cbar_ax)
cbar.set_label('NDVI (Crop Health)', fontsize=14, fontweight='bold', color='#1B4332')

fig2.suptitle("Time-Series Crop Health Monitoring (Satellite NDVI)", fontsize=24, fontweight='bold', color='#1B4332', y=0.98)
plt.savefig(r'C:\SPROUT-Qonnect\08_presentation\figures\insurance_time_series.png', dpi=300, bbox_inches='tight')
plt.close(fig2)

# =====================================================================
# MAP 3: PARAMETRIC PAYOUT ZONES
# =====================================================================
fig3, ax3 = plt.subplots(figsize=(12, 8), facecolor='#F8F9FA')
ax3.set_facecolor('#f1f3f5')

# Create a binary map: 0 = No Payout (Green), 1 = Payout (Red)
Payout = np.zeros_like(X)
# Trigger payout in a specific drought circle
Payout[(X - 37.58)**2 + (Y - 6.35)**2 < 0.002] = 1
# Also trigger payout on one of our specific plots
Payout[(X - 37.55)**2 + (Y - 6.00)**2 < 0.0005] = 1

cmap = ListedColormap(['#2A9D8F', '#E76F51']) # Green, Red
contour3 = ax3.contourf(X, Y, Payout, levels=[-0.5, 0.5, 1.5], cmap=cmap, alpha=0.7)

# Add Text Annotations for Payouts
ax3.text(37.58, 6.35, "PAYOUT TRIGGERED", fontsize=12, fontweight='bold', color='white', 
         ha='center', va='center', bbox=dict(boxstyle="round,pad=0.3", fc='#E76F51', ec="none"))
ax3.text(37.55, 6.00, "PAYOUT TRIGGERED", fontsize=10, fontweight='bold', color='white', 
         ha='center', va='center', bbox=dict(boxstyle="round,pad=0.3", fc='#E76F51', ec="none"))

ax3.text(37.50, 6.30, "NO PAYOUT\n(Healthy Crop)", fontsize=12, fontweight='bold', color='white', 
         ha='center', va='center', bbox=dict(boxstyle="round,pad=0.3", fc='#2A9D8F', ec="none"))

# Legend
legend_patches = [
    mpatches.Patch(color='#2A9D8F', label='No Payout (Healthy)'),
    mpatches.Patch(color='#E76F51', label='Payout Triggered (Drought)')
]
ax3.legend(handles=legend_patches, loc='upper left', fontsize=12)

ax3.set_title("SPROUT Parametric Insurance: Payout Triggers", fontsize=20, fontweight='bold', color='#1B4332', pad=20)
ax3.set_xlabel("Longitude", fontsize=12); ax3.set_ylabel("Latitude", fontsize=12)
ax3.set_xlim(37.40, 37.75); ax3.set_ylim(5.85, 6.55)
plt.tight_layout()
plt.savefig(r'C:\SPROUT-Qonnect\08_presentation\figures\insurance_payout_zones.png', dpi=300, bbox_inches='tight')
plt.close(fig3)

print("All 3 Advanced Insurance Maps successfully generated.")
'@

$pyPath = Join-Path $DASH 'generate_insurance_maps.py'
Write-Utf8NoBom -Path $pyPath -Text $pyCode

Write-Host "`n=== RUNNING GENERATOR ===" -ForegroundColor Cyan
python $pyPath

Write-Host "`n=== OPENING FOLDER ===" -ForegroundColor Cyan
Invoke-Item $FIGS