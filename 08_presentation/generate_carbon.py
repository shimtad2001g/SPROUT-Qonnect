import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Polygon
import matplotlib.colors as mcolors
import warnings

warnings.filterwarnings("ignore")

# 1. Create a synthetic 2D grid of Above-Ground Biomass (AGB) data
# Realistic range for Ethiopian highlands: 20 to 150 t/ha
x = np.linspace(37.45, 37.65, 100)
y = np.linspace(5.95, 6.45, 100)
X, Y = np.meshgrid(x, y)

# Simulate biomass concentration (higher in the south/center, lower in the north)
Z = 50 + 40 * np.exp(-((X - 37.55)**2 / 0.005 + (Y - 6.10)**2 / 0.02))
Z += np.random.normal(0, 5, Z.shape) # Add some natural variance

# 2. Setup the Plot (16:9 Widescreen)
fig, ax = plt.subplots(figsize=(16, 9), facecolor='#F8F9FA')
ax.set_facecolor('#f1f3f5')

# 3. Draw the Heatmap (Contour plot)
levels = np.linspace(20, 150, 20)
contour = ax.contourf(X, Y, Z, levels=levels, cmap='YlGn', alpha=0.85)

# Add a colorbar
cbar = plt.colorbar(contour, ax=ax, pad=0.02)
cbar.set_label('Above-Ground Biomass (tCO2e / ha)', fontsize=14, color='#1B4332', fontweight='bold')
cbar.ax.tick_params(labelsize=12)

# 4. Overlay the 3 specific plots
plots = [
    {"id": "PLT-GAMO-0001", "coords": [(37.550001, 5.999999), (37.551001, 5.999999), (37.551001, 6.001001), (37.550001, 6.001001), (37.550001, 5.999999)]},
    {"id": "PLT-GAMO-0002", "coords": [(37.570001, 6.249999), (37.572001, 6.249999), (37.572001, 6.252001), (37.570001, 6.252001), (37.570001, 6.249999)]},
    {"id": "PLT-GAMO-0003", "coords": [(37.600001, 6.399999), (37.601001, 6.399999), (37.601001, 6.401001), (37.600001, 6.401001), (37.600001, 6.399999)]}
]

for p in plots:
    coords = p["coords"]
    cx = sum(x for x, y in coords) / len(coords)
    cy = sum(y for x, y in coords) / len(coords)
    
    # Draw white outline for the farm
    box_size = 0.005
    square = [(cx-box_size, cy-box_size), (cx+box_size, cy-box_size), (cx+box_size, cy+box_size), (cx-box_size, cy+box_size)]
    ax.add_patch(Polygon(square, closed=True, facecolor='none', edgecolor='white', linewidth=3, zorder=5))
    ax.scatter(cx, cy, s=80, color='black', edgecolor='white', linewidth=2, zorder=6)

# 5. Formatting
ax.set_title("SPROUT GeoAI Carbon Stock Estimation - Gamo Gofa, Ethiopia", fontsize=24, fontweight='bold', color='#1B4332', pad=20)
ax.set_xlabel("Longitude (WGS 84)", fontsize=14, color='#495057')
ax.set_ylabel("Latitude (WGS 84)", fontsize=14, color='#495057')

ax.set_xlim(37.40, 37.75)
ax.set_ylim(5.85, 6.55)
ax.grid(True, linestyle='--', color='white', alpha=0.4, linewidth=1)

plt.tight_layout()
out_path = r'C:\SPROUT-Qonnect\08_presentation\figures\carbon_heatmap.png'
plt.savefig(out_path, dpi=300, bbox_inches='tight')
plt.close()

print(f"Carbon Heatmap successfully generated at: {out_path}")