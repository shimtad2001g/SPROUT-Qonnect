import matplotlib.pyplot as plt
from matplotlib.patches import Polygon
import matplotlib.patches as mpatches
import numpy as np
import warnings

warnings.filterwarnings("ignore")

# Colors
TEAL = '#2A9D8F'
AMBER = '#E76F51'
GREEN = '#1B4332'
DARK = '#212529'

# =====================================================================
# MAP 1: PLOT LABEL MAP (EUDR Article 9 Compliance)
# =====================================================================
fig1, ax1 = plt.subplots(figsize=(16, 9), facecolor='#F8F9FA')
ax1.set_facecolor('#e9ecef')

# Define exact plot polygons
poly1 = [(37.550001, 5.999999), (37.551001, 5.999999), (37.551001, 6.001001), (37.550001, 6.001001), (37.550001, 5.999999)]
poly2 = [(37.570001, 6.249999), (37.572001, 6.249999), (37.572001, 6.252001), (37.570001, 6.252001), (37.570001, 6.249999)]
poly3 = [(37.600001, 6.399999), (37.601001, 6.399999), (37.601001, 6.401001), (37.600001, 6.401001), (37.600001, 6.399999)]

plots = [
    {"id": "PLT-GAMO-0001", "area": "1.2 ha", "status": "Verified", "color": TEAL, "coords": poly1, "xytext": (40, -30)},
    {"id": "PLT-GAMO-0002", "area": "5.0 ha", "status": "Verified", "color": TEAL, "coords": poly2, "xytext": (40, 0)},
    {"id": "PLT-GAMO-0003", "area": "2.0 ha", "status": "REJECTED (R5)", "color": AMBER, "coords": poly3, "xytext": (40, 30)}
]

for p in plots:
    coords = p["coords"]
    cx = sum(x for x, y in coords) / len(coords)
    cy = sum(y for x, y in coords) / len(coords)
    
    # Draw exact polygon (magnified for visibility)
    box_size = 0.005
    square = [(cx-box_size, cy-box_size), (cx+box_size, cy-box_size), (cx+box_size, cy+box_size), (cx-box_size, cy+box_size)]
    ax1.add_patch(Polygon(square, closed=True, facecolor=p["color"], edgecolor='white', linewidth=2, alpha=0.8))
    ax1.scatter(cx, cy, s=80, color='black', zorder=5)
    
    # Annotation with ID and Area
    label_text = f"{p['id']}\nArea: {p['area']}\nStatus: {p['status']}"
    ax1.annotate(
        label_text, xy=(cx, cy), xytext=p["xytext"], textcoords="offset points",
        fontsize=12, fontweight='bold', color='white',
        bbox=dict(boxstyle="round,pad=0.6", fc=p["color"], ec="none", alpha=1.0),
        arrowprops=dict(arrowstyle="-", color=p["color"], linewidth=2)
    )

ax1.set_title("EUDR Plot-Level Verification (Article 9 Compliance)", fontsize=24, fontweight='bold', color=GREEN, pad=20)
ax1.set_xlabel("Longitude (WGS 84)", fontsize=14); ax1.set_ylabel("Latitude (WGS 84)", fontsize=14)
ax1.set_xlim(37.53, 37.63); ax1.set_ylim(5.95, 6.45)
ax1.grid(True, linestyle='--', color='#adb5bd', alpha=0.7)
plt.tight_layout()
plt.savefig(r'C:\SPROUT-Qonnect\08_presentation\figures\plot_label_map.png', dpi=300, bbox_inches='tight')
plt.close(fig1)

# =====================================================================
# MAP 2: PARCEL LEVEL MAP (Farm Subdivision)
# =====================================================================
fig2, ax2 = plt.subplots(figsize=(16, 9), facecolor='#F8F9FA')
ax2.set_facecolor('#e9ecef')

# Define a large Farm boundary
farm_bounds = [(37.54, 6.19), (37.58, 6.19), (37.58, 6.23), (37.54, 6.23), (37.54, 6.19)]

# Define 4 parcels within the farm
parcel_A = [(37.54, 6.21), (37.56, 6.21), (37.56, 6.23), (37.54, 6.23), (37.54, 6.21)] # Shade Coffee
parcel_B = [(37.56, 6.21), (37.58, 6.21), (37.58, 6.23), (37.56, 6.23), (37.56, 6.21)] # Maize
parcel_C = [(37.54, 6.19), (37.57, 6.19), (37.57, 6.21), (37.54, 6.21), (37.54, 6.19)] # Fallow
parcel_D = [(37.57, 6.19), (37.58, 6.19), (37.58, 6.21), (37.57, 6.21), (37.57, 6.19)] # Agroforestry

parcels = [
    {"name": "Parcel A\nShade Coffee", "coords": parcel_A, "color": GREEN},
    {"name": "Parcel B\nMaize", "coords": parcel_B, "color": '#E9C46A'},
    {"name": "Parcel C\nFallow", "coords": parcel_C, "color": '#A8DADC'},
    {"name": "Parcel D\nAgroforestry", "coords": parcel_D, "color": TEAL}
]

# Draw parcels
for p in parcels:
    ax2.add_patch(Polygon(p["coords"], closed=True, facecolor=p["color"], edgecolor='white', linewidth=2, alpha=0.8))
    cx = sum(x for x, y in p["coords"]) / len(p["coords"])
    cy = sum(y for x, y in p["coords"]) / len(p["coords"])
    ax2.text(cx, cy, p["name"], fontsize=12, fontweight='bold', color='white' if p["color"] in [GREEN, TEAL] else DARK, ha='center', va='center', bbox=dict(boxstyle="round,pad=0.3", fc=p["color"], ec="none", alpha=0.9))

# Draw Farm Boundary (Thick black line)
ax2.add_patch(Polygon(farm_bounds, closed=True, facecolor='none', edgecolor='black', linewidth=4, linestyle='--'))
ax2.text(37.56, 6.235, "Farm ID: FRM-GAMO-0001\nTotal Area: 12.5 ha", fontsize=14, fontweight='bold', color='black', ha='center', bbox=dict(boxstyle="round,pad=0.5", fc='white', ec='black', alpha=1.0))

ax2.set_title("Qonnect Parcel-Level Mapping (Farm Subdivision)", fontsize=24, fontweight='bold', color=GREEN, pad=20)
ax2.set_xlabel("Longitude (WGS 84)", fontsize=14); ax2.set_ylabel("Latitude (WGS 84)", fontsize=14)
ax2.set_xlim(37.53, 37.59); ax2.set_ylim(6.18, 6.24)
ax2.grid(True, linestyle='--', color='#adb5bd', alpha=0.7)
plt.tight_layout()
plt.savefig(r'C:\SPROUT-Qonnect\08_presentation\figures\parcel_level_map.png', dpi=300, bbox_inches='tight')
plt.close(fig2)

print("Plot Label and Parcel Level maps generated successfully.")