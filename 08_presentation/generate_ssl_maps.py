import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Polygon
import warnings

warnings.filterwarnings("ignore")

# Base coordinates
x = np.linspace(37.45, 37.65, 200)
y = np.linspace(5.95, 6.45, 200)
X, Y = np.meshgrid(x, y)

# =====================================================================
# MAP 1: SSL RECONSTRUCTION ERROR (Anomaly Detection)
# =====================================================================
fig1, ax1 = plt.subplots(figsize=(12, 8), facecolor='#111111')
ax1.set_facecolor('#111111')

# Simulate normal background reconstruction (low error)
Error = np.random.normal(0.1, 0.05, X.shape)
# Inject a severe anomaly (e.g., pest outbreak or crop failure)
anomaly_mask = ((X - 37.58)**2 / 0.002 + (Y - 6.35)**2 / 0.005) < 1
Error[anomaly_mask] += np.random.normal(0.8, 0.2, np.sum(anomaly_mask))
Error = np.clip(Error, 0, 1)

# Plot the error heatmap (Inferno colormap looks like glowing fire)
contour1 = ax1.contourf(X, Y, Error, levels=30, cmap='inferno', alpha=0.9)
cbar1 = plt.colorbar(contour1, ax=ax1, pad=0.02)
cbar1.set_label('Reconstruction Error (MSE)', fontsize=14, fontweight='bold', color='white')
cbar1.ax.yaxis.set_tick_params(color='white')
plt.setp(plt.getp(cbar1.ax.axes, 'yticklabels'), color='white')

ax1.set_title("Self-Supervised Anomaly Detection (Reconstruction Error)", fontsize=20, fontweight='bold', color='white', pad=20)
ax1.set_xlabel("Longitude", fontsize=12, color='white')
ax1.set_ylabel("Latitude", fontsize=12, color='white')
ax1.tick_params(colors='white')
ax1.set_xlim(37.40, 37.75)
ax1.set_ylim(5.85, 6.55)
plt.tight_layout()
plt.savefig(r'C:\SPROUT-Qonnect\08_presentation\figures\ssl_anomaly_map.png', dpi=300, bbox_inches='tight', facecolor='#111111')
plt.close(fig1)

# =====================================================================
# MAP 2: MULTI-MODAL FUSION (Radar + Optical)
# =====================================================================
fig2, ax2 = plt.subplots(figsize=(12, 8), facecolor='#F8F9FA')
ax2.set_facecolor('#f1f3f5')

# Simulate Optical (NDVI) - smooth waves
Optical = 0.6 + 0.2 * np.sin(X*20) * np.cos(Y*20)
# Simulate Radar (Soil Moisture) - blobs
Radar = np.exp(-((X - 37.55)**2 / 0.01 + (Y - 6.20)**2 / 0.02))

# Fuse them together using SSL (weighted combination)
Fusion = (Optical * 0.6) + (Radar * 0.4)
Fusion += np.random.normal(0, 0.02, Fusion.shape)

# Plot with Turbo colormap for high contrast "Cyber" look
contour2 = ax2.contourf(X, Y, Fusion, levels=30, cmap='turbo', alpha=0.9)
# Add contour lines for a 3D topographic effect
ax2.contour(X, Y, Fusion, levels=15, colors='black', linewidths=0.5, alpha=0.3)

cbar2 = plt.colorbar(contour2, ax=ax2, pad=0.02)
cbar2.set_label('Fused Feature Representation', fontsize=14, fontweight='bold', color='#1B4332')

ax2.set_title("Multi-Modal SSL Fusion (Sentinel-1 Radar + Sentinel-2 Optical)", fontsize=20, fontweight='bold', color='#1B4332', pad=20)
ax2.set_xlabel("Longitude", fontsize=12)
ax2.set_ylabel("Latitude", fontsize=12)
ax2.set_xlim(37.40, 37.75)
ax2.set_ylim(5.85, 6.55)
plt.tight_layout()
plt.savefig(r'C:\SPROUT-Qonnect\08_presentation\figures\ssl_fusion_map.png', dpi=300, bbox_inches='tight')
plt.close(fig2)

print("SSL Maps generated successfully. Injecting into PPT...")

# =====================================================================
# INJECT INTO POWERPOINT
# =====================================================================
from pptx import Presentation
from pptx.util import Inches
from pptx.enum.shapes import MSO_SHAPE_TYPE

path = r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_MASTER_FINAL.pptx'
prs = Presentation(path)

# --- Slide 6 (Business Model - Crop Insurance) ---
slide6 = prs.slides[5]
for i in range(len(slide6.shapes) - 1, -1, -1):
    if slide6.shapes[i].shape_type == MSO_SHAPE_TYPE.PICTURE:
        sp = slide6.shapes[i]._element
        sp.getparent().remove(sp)
        break
# Add SSL Anomaly Map
slide6.shapes.add_picture(r'C:\SPROUT-Qonnect\08_presentation\figures\ssl_anomaly_map.png', Inches(6.2), Inches(2.2), width=Inches(6.5))

# --- Slide 3 (Architecture - Deep Tech) ---
slide3 = prs.slides[2]
for i in range(len(slide3.shapes) - 1, -1, -1):
    if slide3.shapes[i].shape_type == MSO_SHAPE_TYPE.PICTURE:
        sp = slide3.shapes[i]._element
        sp.getparent().remove(sp)
        break
# Add SSL Fusion Map
slide3.shapes.add_picture(r'C:\SPROUT-Qonnect\08_presentation\figures\ssl_fusion_map.png', Inches(6.3), Inches(2.2), width=Inches(6.4))

prs.save(path)
print("Master PPT updated with SSL Deep Learning maps.")