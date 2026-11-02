# =====================================================================
# TraceRight-SPROUT | Step 17: Generate Crop Insurance & Ecological Zones
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

Write-Host "=== GENERATING FINAL TWO MAPS ===" -ForegroundColor Cyan

$pyCode = @'
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Polygon
import matplotlib.colors as mcolors
import matplotlib.patches as mpatches
import warnings

warnings.filterwarnings("ignore")

# =====================================================================
# MAP 1: CROP INSURANCE (NDVI ANOMALY)
# =====================================================================
fig1, ax1 = plt.subplots(figsize=(12, 8), facecolor='#F8F9FA')
ax1.set_facecolor('#f1f3f5')

# Simulate NDVI (Normalized Difference Vegetation Index)
x = np.linspace(37.45, 37.65, 150)
y = np.linspace(5.95, 6.45, 150)
X, Y = np.meshgrid(x, y)

# Create a healthy baseline
NDVI = 0.8 - 0.1 * np.abs(X - 37.55) - 0.1 * np.abs(Y - 6.20)
# Introduce a severe drought anomaly (crop failure)
NDVI -= 0.5 * np.exp(-((X - 37.58)**2 / 0.001 + (Y - 6.35)**2 / 0.002))
NDVI += np.random.normal(0, 0.02, NDVI.shape)
NDVI = np.clip(NDVI, 0, 1)

# Plot NDVI Heatmap
contour1 = ax1.contourf(X, Y, NDVI, levels=20, cmap='RdYlGn', alpha=0.85)
cbar1 = plt.colorbar(contour1, ax=ax1, pad=0.02)
cbar1.set_label('NDVI (Vegetation Health)', fontsize=14, fontweight='bold', color='#1B4332')
cbar1.ax.tick_params(labelsize=12)

# Highlight the failed crop zone (Insurance Trigger)
circle = plt.Circle((37.58, 6.35), 0.03, color='#E76F51', fill=False, linewidth=3, zorder=5)
ax1.add_patch(circle)
ax1.annotate('Drought Anomaly\nInsurance Triggered', 
             xy=(37.58, 6.35), xytext=(37.62, 6.42),
             fontsize=12, fontweight='bold', color='white',
             bbox=dict(boxstyle="round,pad=0.5", fc='#E76F51', ec="none", alpha=1.0),
             arrowprops=dict(arrowstyle="-", color='#E76F51', linewidth=2))

ax1.set_title("SPROUT GeoAI Crop Insurance - Parametric Trigger", fontsize=20, fontweight='bold', color='#1B4332', pad=20)
ax1.set_xlabel("Longitude", fontsize=12); ax1.set_ylabel("Latitude", fontsize=12)
ax1.set_xlim(37.40, 37.75); ax1.set_ylim(5.85, 6.55)
plt.tight_layout()
insurance_path = r'C:\SPROUT-Qonnect\08_presentation\figures\crop_insurance_map.png'
plt.savefig(insurance_path, dpi=300, bbox_inches='tight')
plt.close(fig1)

# =====================================================================
# MAP 2: ECOLOGICAL ZONES (ELEVATION)
# =====================================================================
fig2, ax2 = plt.subplots(figsize=(12, 8), facecolor='#F8F9FA')
ax2.set_facecolor('#f1f3f5')

# Simulate Elevation (m) - Gamo Gofa ranges from ~500m (Kolla) to >3200m (Wurch)
# We will simulate a terrain gradient from South (Low) to North (High)
Elevation = 500 + (Y - 5.95) * 5000 
Elevation += np.random.normal(0, 100, Elevation.shape) 

# Define Ethiopia's Ecological Zones colors based on elevation
# Bereha (<500m), Kolla (500-1500), Weyna Dega (1500-2300), Dega (2300-3200), Wurch (>3200)
levels = [0, 500, 1500, 2300, 3200, 4500]
colors_zones = ['#E9C46A', '#F4A261', '#2A9D8F', '#264653', '#8AB17D'] 
cmap_zones = mcolors.ListedColormap(colors_zones)
norm = mcolors.BoundaryNorm(levels, cmap_zones.N)

contour2 = ax2.contourf(X, Y, Elevation, levels=levels, cmap=cmap_zones, norm=norm, alpha=0.85)

# Create custom legend for zones
legend_patches = [
    mpatches.Patch(color='#8AB17D', label='Wurch (>3200m)'),
    mpatches.Patch(color='#264653', label='Dega (2300-3200m)'),
    mpatches.Patch(color='#2A9D8F', label='Weyna Dega (1500-2300m)'),
    mpatches.Patch(color='#F4A261', label='Kolla (500-1500m)'),
    mpatches.Patch(color='#E9C46A', label='Bereha (<500m)')
]
ax2.legend(handles=legend_patches, loc='lower left', title="Agro-Ecological Zones", title_fontsize=12, fontsize=11)

ax2.set_title("SPROUT GeoAI Agro-Ecological Zonation", fontsize=20, fontweight='bold', color='#1B4332', pad=20)
ax2.set_xlabel("Longitude", fontsize=12); ax2.set_ylabel("Latitude", fontsize=12)
ax2.set_xlim(37.40, 37.75); ax2.set_ylim(5.85, 6.55)
plt.tight_layout()
zones_path = r'C:\SPROUT-Qonnect\08_presentation\figures\ecological_zones_map.png'
plt.savefig(zones_path, dpi=300, bbox_inches='tight')
plt.close(fig2)

print("Crop Insurance Map and Ecological Zones Map generated successfully.")
'@

$pyPath = Join-Path $DASH 'generate_final_two_maps.py'
Write-Utf8NoBom -Path $pyPath -Text $pyCode

Write-Host "`n=== RUNNING GENERATOR ===" -ForegroundColor Cyan
python $pyPath

Write-Host "`n=== COMPLETE ===" -ForegroundColor Green
Write-Host "Images saved to $FIGS"