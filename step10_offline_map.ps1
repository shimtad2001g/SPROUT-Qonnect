# =====================================================================
# TraceRight-SPROUT | Step 10: 100% Offline GIS Map
# =====================================================================
$ErrorActionPreference = 'Continue'
$ROOT = 'C:\SPROUT-Qonnect'
$DASH = Join-Path $ROOT '08_presentation'

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

Write-Host "=== GENERATING OFFLINE MAP ===" -ForegroundColor Cyan

$pyScript = @'
import geopandas as gpd
from shapely.geometry import Polygon
import matplotlib.pyplot as plt
import warnings

warnings.filterwarnings("ignore")

# Define the polygons (Gamo Gofa region)
poly1 = Polygon([(37.550001, 5.999999), (37.551001, 5.999999), (37.551001, 6.001001), (37.550001, 6.001001), (37.550001, 5.999999)])
poly2 = Polygon([(37.570001, 6.249999), (37.572001, 6.249999), (37.572001, 6.252001), (37.570001, 6.252001), (37.570001, 6.249999)])
poly3 = Polygon([(37.600001, 6.399999), (37.601001, 6.399999), (37.601001, 6.401001), (37.600001, 6.401001), (37.600001, 6.399999)])

gdf = gpd.GeoDataFrame({
    'Plot_ID': ['PLT-GAMO-0001', 'PLT-GAMO-0002', 'PLT-GAMO-0003'],
    'Zone': ['Kolla', 'Weyna Dega', 'Dega'],
    'Status': ['Verified', 'Verified', 'Rejected (R5)'],
    'geometry': [poly1, poly2, poly3]
}, crs="EPSG:4326")

# 100% Offline Plotting (No internet needed)
fig, ax = plt.subplots(figsize=(12, 8), facecolor='#F8F9FA')
ax.set_facecolor('#e9ecef') # Light gray background

colors = {'Verified': '#2A9D8F', 'Rejected (R5)': '#E76F51'}

# Plot the polygons (enlarged slightly so they are visible at this scale)
for status, color in colors.items():
    subset = gdf[gdf['Status'] == status]
    if not subset.empty:
        # Approximate buffer in degrees to make small plots visible
        subset.buffer(0.002).plot(ax=ax, color=color, alpha=0.9, edgecolor='white', linewidth=2, label=status)

# Add labels
for idx, row in gdf.iterrows():
    x, y = row.geometry.centroid.x, row.geometry.centroid.y
    ax.annotate(
        f"{row['Plot_ID']}\n{row['Zone']}", 
        xy=(x, y), xytext=(10, 10), textcoords="offset points",
        fontsize=11, fontweight='bold', color='white',
        bbox=dict(boxstyle="round,pad=0.5", fc=colors[row['Status']], ec="none", alpha=0.9)
    )

# Formatting to make it look like a professional GIS tool
ax.set_title("SPROUT GeoAI Spatial Verification - Gamo Gofa Region", fontsize=18, fontweight='bold', color='#1B4332', pad=20)
ax.set_xlabel("Longitude (WGS 84)", fontsize=12, color='#495057')
ax.set_ylabel("Latitude (WGS 84)", fontsize=12, color='#495057')

# Add a grid
ax.grid(True, linestyle='--', color='white', alpha=0.7, linewidth=1)

# Set map limits to zoom in on our plots
ax.set_xlim(37.54, 37.61)
ax.set_ylim(5.99, 6.41)

legend = ax.legend(loc='upper left', fontsize=12, title="EUDR Status", title_fontsize=12)
legend.get_frame().set_facecolor('white')
legend.get_frame().set_alpha(0.9)

plt.tight_layout()
out_path = r'C:\SPROUT-Qonnect\08_presentation\figures\realistic_satellite_map.png'
plt.savefig(out_path, dpi=300, bbox_inches='tight')
plt.close()

print("Offline Map successfully generated.")
'@

Write-Utf8NoBom -Path (Join-Path $DASH 'generate_maps_fix.py') -Text $pyScript

Write-Host "`n=== RUNNING GENERATOR ===" -ForegroundColor Cyan
Push-Location $DASH
python generate_maps_fix.py
Pop-Location

Write-Host "`n=== MAP COMPLETE ===" -ForegroundColor Green