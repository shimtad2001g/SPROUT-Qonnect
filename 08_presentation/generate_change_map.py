import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Polygon
import warnings

warnings.filterwarnings("ignore")

# Setup 1x2 Subplots (Side by Side)
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 8), facecolor='#F8F9FA')

# --- SIMULATE FOREST CANOPY DATA ---
x = np.linspace(37.45, 37.65, 200)
y = np.linspace(5.95, 6.45, 200)
X, Y = np.meshgrid(x, y)

# 2020 Baseline: Full dense forest
Forest_2020 = np.exp(-((X - 37.55)**2 / 0.01 + (Y - 6.10)**2 / 0.02))
Forest_2020 += np.random.normal(0, 0.05, Forest_2020.shape)
Forest_2020 = np.clip(Forest_2020, 0, 1)

# 2024 Current: Forest lost in the top right corner (simulated deforestation)
Forest_2024 = Forest_2020.copy()
deforestation_zone = ((X > 37.58) & (Y > 6.30))
Forest_2024[deforestation_zone] = Forest_2024[deforestation_zone] * 0.1 # Trees removed

# --- PLOT 1: 2020 ---
ax1.set_facecolor('#f1f3f5')
c1 = ax1.contourf(X, Y, Forest_2020, levels=20, cmap='Greens', alpha=0.9)
ax1.set_title("2020 Baseline Forest Canopy", fontsize=18, fontweight='bold', color='#1B4332', pad=15)
ax1.set_xlabel("Longitude", fontsize=12)
ax1.set_ylabel("Latitude", fontsize=12)
ax1.set_xlim(37.40, 37.75)
ax1.set_ylim(5.85, 6.55)

# --- PLOT 2: 2024 ---
ax2.set_facecolor('#f1f3f5')
c2 = ax2.contourf(X, Y, Forest_2024, levels=20, cmap='Greens', alpha=0.9)
ax2.set_title("2024 Current Canopy (Change Detection)", fontsize=18, fontweight='bold', color='#E76F51', pad=15)
ax2.set_xlabel("Longitude", fontsize=12)
ax2.set_xlim(37.40, 37.75)
ax2.set_ylim(5.85, 6.55)

# --- HIGHLIGHT THE DEFORESTATION ZONE IN RED ---
# Draw a red rectangle over the deforested area in the 2024 map
rect = plt.Rectangle((37.58, 6.30), 0.07, 0.15, linewidth=3, edgecolor='#E76F51', facecolor='none', zorder=5)
ax2.add_patch(rect)
ax2.annotate('Illegal Deforestation\nFlagged by SPROUT AI', 
             xy=(37.615, 6.375), xytext=(37.65, 6.45), textcoords="data",
             fontsize=12, fontweight='bold', color='white',
             bbox=dict(boxstyle="round,pad=0.5", fc='#E76F51', ec="none", alpha=1.0),
             arrowprops=dict(arrowstyle="-", color='#E76F51', linewidth=2))

plt.tight_layout()
out_path = r'C:\SPROUT-Qonnect\08_presentation\figures\change_detection_map.png'
plt.savefig(out_path, dpi=300, bbox_inches='tight')
plt.close()

print(f"Change Detection Map generated at: {out_path}")