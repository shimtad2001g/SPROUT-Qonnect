import matplotlib.pyplot as plt
from matplotlib.patches import Polygon
import matplotlib.patches as mpatches
import warnings

warnings.filterwarnings("ignore")

# Coordinates
poly1_coords = [(37.550001, 5.999999), (37.551001, 5.999999), (37.551001, 6.001001), (37.550001, 6.001001), (37.550001, 5.999999)]
poly2_coords = [(37.570001, 6.249999), (37.572001, 6.249999), (37.572001, 6.252001), (37.570001, 6.252001), (37.570001, 6.249999)]
poly3_coords = [(37.600001, 6.399999), (37.601001, 6.399999), (37.601001, 6.401001), (37.600001, 6.401001), (37.600001, 6.399999)]

plots = [
    {"id": "PLT-GAMO-0001", "zone": "Kolla", "status": "Verified", "coords": poly1_coords},
    {"id": "PLT-GAMO-0002", "zone": "Weyna Dega", "status": "Verified", "coords": poly2_coords},
    {"id": "PLT-GAMO-0003", "zone": "Dega", "status": "Rejected (R5)", "coords": poly3_coords}
]

colors = {"Verified": "#2A9D8F", "Rejected (R5)": "#E76F51"}

# Widescreen presentation size (16:9 ratio)
fig, ax = plt.subplots(figsize=(16, 9), facecolor='#F8F9FA')
ax.set_facecolor('#f1f3f5')

for p in plots:
    color = colors[p["status"]]
    coords = p["coords"]
    
    # Get center point
    cx = sum(x for x, y in coords) / len(coords)
    cy = sum(y for x, y in coords) / len(coords)

    # Draw a slightly larger box around the exact centroid for visual effect
    box_size = 0.008
    square = [(cx-box_size, cy-box_size), (cx+box_size, cy-box_size), (cx+box_size, cy+box_size), (cx-box_size, cy+box_size)]
    ax.add_patch(Polygon(square, closed=True, facecolor=color, edgecolor='white', alpha=0.6, zorder=4))

    # Draw the exact center point
    ax.scatter(cx, cy, s=150, color=color, edgecolor='white', linewidth=2, zorder=5)

    # Label positioning
    if p["id"] == "PLT-GAMO-0001":
        xytext = (40, -30)
    elif p["id"] == "PLT-GAMO-0002":
        xytext = (40, 0)
    else:
        xytext = (40, 30)

    ax.annotate(
        f"{p['id']}\n{p['zone']}",
        xy=(cx, cy), xytext=xytext, textcoords="offset points",
        fontsize=14, fontweight='bold', color='white',
        bbox=dict(boxstyle="round,pad=0.6", fc=color, ec="none", alpha=1.0),
        arrowprops=dict(arrowstyle="-", color=color, linewidth=2),
        zorder=6
    )

# Formatting
ax.set_title("SPROUT GeoAI Validation - Gamo Gofa Region, Ethiopia", fontsize=24, fontweight='bold', color='#1B4332', pad=20)
ax.set_xlabel("Longitude (WGS 84)", fontsize=14, color='#495057')
ax.set_ylabel("Latitude (WGS 84)", fontsize=14, color='#495057')

# Grid
ax.grid(True, linestyle='--', color='#adb5bd', alpha=0.7, linewidth=1)

# Force a WIDE landscape box (this prevents the vertical stretching)
ax.set_xlim(37.53, 37.63)
ax.set_ylim(5.95, 6.45)

# Legend
legend_elements = [
    mpatches.Patch(color='#2A9D8F', label='Verified'),
    mpatches.Patch(color='#E76F51', label='Rejected (R5)')
]
legend = ax.legend(handles=legend_elements, loc='upper left', fontsize=14, title="EUDR Status", title_fontsize=14)
legend.get_frame().set_facecolor('white')
legend.get_frame().set_alpha(1.0)

plt.tight_layout()
out_path = r'C:\SPROUT-Qonnect\08_presentation\figures\realistic_satellite_map.png'
plt.savefig(out_path, dpi=300, bbox_inches='tight')
plt.close()

print("Widescreen Map successfully generated.")