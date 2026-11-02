import geopandas as gpd
from shapely.geometry import Polygon
import matplotlib.pyplot as plt
import warnings

warnings.filterwarnings("ignore")

poly1 = Polygon([(37.550001, 5.999999), (37.551001, 5.999999), (37.551001, 6.001001), (37.550001, 6.001001), (37.550001, 5.999999)])
poly2 = Polygon([(37.570001, 6.249999), (37.572001, 6.249999), (37.572001, 6.252001), (37.570001, 6.252001), (37.570001, 6.249999)])
poly3 = Polygon([(37.600001, 6.399999), (37.601001, 6.399999), (37.601001, 6.401001), (37.600001, 6.401001), (37.600001, 6.399999)])

gdf = gpd.GeoDataFrame({
    'Plot_ID': ['PLT-GAMO-0001', 'PLT-GAMO-0002', 'PLT-GAMO-0003'],
    'Zone': ['Kolla', 'Weyna Dega', 'Dega'],
    'Status': ['Verified', 'Verified', 'Rejected (R5)'],
    'geometry': [poly1, poly2, poly3]
}, crs="EPSG:4326")

# Widescreen presentation size (12x7 ratio)
fig, ax = plt.subplots(figsize=(12, 7), facecolor='#F8F9FA')
ax.set_facecolor('#f1f3f5') 

colors = {'Verified': '#2A9D8F', 'Rejected (R5)': '#E76F51'}

for idx, row in gdf.iterrows():
    x, y = row.geometry.centroid.x, row.geometry.centroid.y
    color = colors[row['Status']]
    
    ax.scatter(x, y, s=250, color=color, edgecolor='white', linewidth=2, zorder=5)
    gpd.GeoSeries([row.geometry]).boundary.plot(ax=ax, color=color, linewidth=2, zorder=4)

    # Smart label placement based on which plot it is
    if idx == 0: # Plot 1 (Bottom)
        xytext = (40, 40)
        ha = 'left'
    elif idx == 1: # Plot 2 (Middle)
        xytext = (40, 0)
        ha = 'left'
    else: # Plot 3 (Top)
        xytext = (40, -40)
        ha = 'left'

    ax.annotate(
        f"{row['Plot_ID']}\n{row['Zone']}", 
        xy=(x, y), xytext=xytext, textcoords="offset points",
        fontsize=12, fontweight='bold', color='white', ha=ha,
        bbox=dict(boxstyle="round,pad=0.6", fc=color, ec="none", alpha=0.9),
        arrowprops=dict(arrowstyle="-", color=color, linewidth=2)
    )

# Formatting
ax.set_title("SPROUT GeoAI Validation - Gamo Gofa Region, Ethiopia", fontsize=20, fontweight='bold', color='#1B4332', pad=20)
ax.set_xlabel("Longitude (WGS 84)", fontsize=12, color='#495057')
ax.set_ylabel("Latitude (WGS 84)", fontsize=12, color='#495057')

# Grid and Layout
ax.grid(True, linestyle='--', color='#adb5bd', alpha=0.7, linewidth=1)

# We set specific wide limits to force a landscape box, ignoring 'equal' aspect
ax.set_xlim(37.53, 37.63)
ax.set_ylim(5.95, 6.45)

# Legend
import matplotlib.patches as mpatches
legend_elements = [
    mpatches.Patch(color='#2A9D8F', label='Verified'),
    mpatches.Patch(color='#E76F51', label='Rejected (R5)')
]
legend = ax.legend(handles=legend_elements, loc='lower right', fontsize=12, title="EUDR Status", title_fontsize=12)
legend.get_frame().set_facecolor('white')
legend.get_frame().set_alpha(1.0)

plt.tight_layout()
out_path = r'C:\SPROUT-Qonnect\08_presentation\figures\realistic_satellite_map.png'
plt.savefig(out_path, dpi=300, bbox_inches='tight')
plt.close()

print("Widescreen Map successfully generated.")
