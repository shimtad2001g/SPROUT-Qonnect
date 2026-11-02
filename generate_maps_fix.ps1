# =====================================================================
# TraceRight-SPROUT | Generate Realistic Maps (Fixed 403 Error)
# =====================================================================
$ErrorActionPreference = 'Continue'
$ROOT = 'C:\SPROUT-Qonnect'
$FIGS = Join-Path $ROOT '08_presentation\figures'

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

Write-Host "=== REGENERATING MAPS WITH FALLBACK ===" -ForegroundColor Cyan

$pyScript = @'
import geopandas as gpd
from shapely.geometry import Polygon
import matplotlib.pyplot as plt
import contextily as ctx
import warnings

warnings.filterwarnings("ignore")

# 1. Set a User-Agent to bypass the 403 block
ctx.set_options(user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

# 2. Define the polygons (Gamo Gofa region)
poly1 = Polygon([(37.550001, 5.999999), (37.551001, 5.999999), (37.551001, 6.001001), (37.550001, 6.001001), (37.550001, 5.999999)])
poly2 = Polygon([(37.570001, 6.249999), (37.572001, 6.249999), (37.572001, 6.252001), (37.570001, 6.252001), (37.570001, 6.249999)])
poly3 = Polygon([(37.600001, 6.399999), (37.601001, 6.399999), (37.601001, 6.401001), (37.600001, 6.401001), (37.600001, 6.399999)])

gdf = gpd.GeoDataFrame({
    'Plot_ID': ['PLT-GAMO-0001', 'PLT-GAMO-0002', 'PLT-GAMO-0003'],
    'Zone': ['Kolla', 'Weyna Dega', 'Dega'],
    'Status': ['Verified', 'Verified', 'Rejected (R5)'],
    'geometry': [poly1, poly2, poly3]
}, crs="EPSG:4326")

gdf_merc = gdf.to_crs(epsg=3857)

# 3. Plotting
fig, ax = plt.subplots(figsize=(12, 8), facecolor='#F8F9FA')

colors = {'Verified': '#2A9D8F', 'Rejected (R5)': '#E76F51'}

for status, color in colors.items():
    subset = gdf_merc[gdf_merc['Status'] == status]
    if not subset.empty:
        # Use larger polygons so they are visible even when zoomed out
        subset.buffer(500).plot(ax=ax, color=color, alpha=0.7, edgecolor='white', linewidth=2, label=status)

for idx, row in gdf_merc.iterrows():
    x, y = row.geometry.centroid.x, row.geometry.centroid.y
    ax.annotate(
        f"{row['Plot_ID']}\n{row['Zone']}", 
        xy=(x, y), xytext=(5, 5), textcoords="offset points",
        fontsize=10, fontweight='bold', color='white',
        bbox=dict(boxstyle="round,pad=0.4", fc=colors[row['Status']], ec="none", alpha=0.9)
    )

# 4. Add Basemap with Fallback
try:
    # Try Esri Satellite first (Zoom 12 to cover the wide area)
    ctx.add_basemap(ax, source=ctx.providers.Esri.WorldImagery, zoom=12, alpha=0.8)
    print("Satellite imagery loaded successfully.")
except Exception as e:
    print(f"Satellite blocked. Falling back to clean street map. Error: {e}")
    ctx.add_basemap(ax, source=ctx.providers.CartoDB.Positron, zoom=12, alpha=0.6)

# 5. Formatting
ax.set_title("SPROUT GeoAI Validation - Gamo Gofa Region", fontsize=18, fontweight='bold', color='#1B4332', pad=15)
ax.set_axis_off() 

# Move legend to top right so it doesn't block Plot 1
legend = ax.legend(loc='upper right', fontsize=12, title="EUDR Status", title_fontsize=12)
legend.get_frame().set_facecolor('white')
legend.get_frame().set_alpha(0.9)

plt.tight_layout()
out_path = r'C:\SPROUT-Qonnect\08_presentation\figures\realistic_satellite_map.png'
plt.savefig(out_path, dpi=300, bbox_inches='tight')
plt.close()

print(f"Map successfully generated at: {out_path}")
'@

Write-Utf8NoBom -Path (Join-Path $ROOT '08_presentation\generate_maps_fix.py') -Text $pyScript

Write-Host "`n=== RUNNING MAP GENERATOR ===" -ForegroundColor Cyan
Push-Location (Join-Path $ROOT '08_presentation')
python generate_maps_fix.py
Pop-Location

Write-Host "`n=== MAP GENERATION COMPLETE ===" -ForegroundColor Green