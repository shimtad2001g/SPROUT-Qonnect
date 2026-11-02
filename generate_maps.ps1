# =====================================================================
# TraceRight-SPROUT | Generate Realistic Satellite Maps
# =====================================================================
$ErrorActionPreference = 'Continue'
$ROOT = 'C:\SPROUT-Qonnect'
$FIGS = Join-Path $ROOT '08_presentation\figures'
New-Item -ItemType Directory -Force -Path $FIGS | Out-Null

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

Write-Host "=== GENERATING REALISTIC SATELLITE MAPS ===" -ForegroundColor Cyan

$pyScript = @'
import geopandas as gpd
from shapely.geometry import Polygon
import matplotlib.pyplot as plt
import contextily as ctx
import warnings

# Suppress warnings from contextily/matplotlib
warnings.filterwarnings("ignore")

# 1. Define the polygons exactly as they are in the demo (Gamo Gofa region)
# Plot 1 (Kolla - Verified)
poly1 = Polygon([
    (37.550001, 5.999999), (37.551001, 5.999999), 
    (37.551001, 6.001001), (37.550001, 6.001001), 
    (37.550001, 5.999999)
])

# Plot 2 (Weyna Dega - Verified)
poly2 = Polygon([
    (37.570001, 6.249999), (37.572001, 6.249999), 
    (37.572001, 6.252001), (37.570001, 6.252001), 
    (37.570001, 6.249999)
])

# Plot 3 (Dega - Rejected R5)
poly3 = Polygon([
    (37.600001, 6.399999), (37.601001, 6.399999), 
    (37.601001, 6.401001), (37.600001, 6.401001), 
    (37.600001, 6.399999)
])

# 2. Create a GeoDataFrame
gdf = gpd.GeoDataFrame({
    'Plot_ID': ['PLT-GAMO-0001', 'PLT-GAMO-0002', 'PLT-GAMO-0003'],
    'Zone': ['Kolla', 'Weyna Dega', 'Dega'],
    'Status': ['Verified', 'Verified', 'Rejected (R5)'],
    'geometry': [poly1, poly2, poly3]
}, crs="EPSG:4326")

# 3. Project to Web Mercator (required for contextily satellite basemaps)
gdf_merc = gdf.to_crs(epsg=3857)

# 4. Plotting
fig, ax = plt.subplots(figsize=(12, 8), facecolor='#F8F9FA')

# Colors: Green for verified, Red/Amber for rejected
colors = {'Verified': '#2A9D8F', 'Rejected (R5)': '#E76F51'}

for status, color in colors.items():
    subset = gdf_merc[gdf_merc['Status'] == status]
    if not subset.empty:
        subset.plot(ax=ax, color=color, alpha=0.7, edgecolor='white', linewidth=2, label=status)

# Add labels for each plot
for idx, row in gdf_merc.iterrows():
    # Place label at the centroid of the polygon
    x, y = row.geometry.centroid.x, row.geometry.centroid.y
    ax.annotate(
        f"{row['Plot_ID']}\n{row['Zone']}", 
        xy=(x, y), xytext=(5, 5), textcoords="offset points",
        fontsize=10, fontweight='bold', color='white',
        bbox=dict(boxstyle="round,pad=0.3", fc=colors[row['Status']], ec="none", alpha=0.9)
    )

# 5. Add Satellite Basemap (Esri World Imagery)
try:
    ctx.add_basemap(ax, source=ctx.providers.Esri.WorldImagery, zoom=14, alpha=0.8)
except Exception as e:
    print(f"Warning: Could not load satellite imagery. Generating blank map. Error: {e}")

# 6. Formatting
ax.set_title("SPROUT GeoAI Validation - Gamo Gofa Region", fontsize=18, fontweight='bold', color='#1B4332', pad=15)
ax.set_axis_off() # Hide the axis numbers

# Add legend
legend = ax.legend(loc='lower right', fontsize=12, title="EUDR Status", title_fontsize=12)
legend.get_frame().set_facecolor('white')
legend.get_frame().set_alpha(0.9)

plt.tight_layout()
out_path = r'C:\SPROUT-Qonnect\08_presentation\figures\realistic_satellite_map.png'
plt.savefig(out_path, dpi=300, bbox_inches='tight')
plt.close()

print(f"Realistic map successfully generated at: {out_path}")
'@

Write-Utf8NoBom -Path (Join-Path $ROOT '08_presentation\generate_maps.py') -Text $pyScript

Write-Host "`n=== RUNNING MAP GENERATOR ===" -ForegroundColor Cyan
Push-Location (Join-Path $ROOT '08_presentation')
python generate_maps.py
Pop-Location

Write-Host "`n=== MAP GENERATION COMPLETE ===" -ForegroundColor Green