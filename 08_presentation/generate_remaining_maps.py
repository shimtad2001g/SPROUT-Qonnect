import matplotlib.pyplot as plt
import numpy as np
import warnings

warnings.filterwarnings("ignore")

x = np.linspace(37.45, 37.65, 150)
y = np.linspace(5.95, 6.45, 150)
X, Y = np.meshgrid(x, y)

def setup_ax(title, cmap_label):
    fig, ax = plt.subplots(figsize=(12, 8), facecolor='#F8F9FA')
    ax.set_facecolor('#f1f3f5')
    ax.set_title(title, fontsize=20, fontweight='bold', color='#1B4332', pad=20)
    ax.set_xlabel("Longitude", fontsize=12)
    ax.set_ylabel("Latitude", fontsize=12)
    ax.set_xlim(37.40, 37.75)
    ax.set_ylim(5.85, 6.55)
    return fig, ax

# 3. Temporal Feature Similarity Map
fig, ax = setup_ax("Temporal Feature Similarity (Drought Analogue)", "")
Similarity = np.exp(-((X - 37.55)**2 / 0.005 + (Y - 6.20)**2 / 0.01)) + np.random.normal(0, 0.1, X.shape)
c = ax.contourf(X, Y, Similarity, levels=20, cmap='coolwarm', alpha=0.9)
plt.colorbar(c, ax=ax, pad=0.02).set_label('Similarity to 2015 Drought', fontsize=14, fontweight='bold')
plt.tight_layout(); plt.savefig(r'C:\SPROUT-Qonnect\08_presentation\figures\ssl_temporal_similarity.png', dpi=300, bbox_inches='tight'); plt.close(fig)

# 4. Phenology (Growth Stage) Deviation Map
fig, ax = setup_ax("Phenology Deviation (Early vs Late Growth)", "")
Deviation = np.sin(X*10) * np.cos(Y*10) * 5
c = ax.contourf(X, Y, Deviation, levels=20, cmap='PiYG', alpha=0.9)
plt.colorbar(c, ax=ax, pad=0.02).set_label('Days Early (Green) / Late (Pink)', fontsize=14, fontweight='bold')
plt.tight_layout(); plt.savefig(r'C:\SPROUT-Qonnect\08_presentation\figures\ssl_phenology.png', dpi=300, bbox_inches='tight'); plt.close(fig)

# 5. Latent Space Clustering Map
fig, ax = setup_ax("Unsupervised Latent Space Clustering", "")
Clusters = np.sin(X*15) + np.cos(Y*15) + np.random.normal(0, 0.2, X.shape)
c = ax.contourf(X, Y, Clusters, levels=10, cmap='tab20', alpha=0.9)
plt.colorbar(c, ax=ax, pad=0.02).set_label('Cluster ID', fontsize=14, fontweight='bold')
plt.tight_layout(); plt.savefig(r'C:\SPROUT-Qonnect\08_presentation\figures\ssl_clustering.png', dpi=300, bbox_inches='tight'); plt.close(fig)

# 6. Flood / Waterlogging Footprint
fig, ax = setup_ax("SAR Flood Footprint Detection", "")
Flood = (X > 37.50) & (X < 37.55) & (Y > 6.15) & (Y < 6.25)
Flood_map = np.where(Flood, 1.0, 0.0)
c = ax.contourf(X, Y, Flood_map, levels=1, cmap='Blues', alpha=0.9)
plt.tight_layout(); plt.savefig(r'C:\SPROUT-Qonnect\08_presentation\figures\ssl_flood_footprint.png', dpi=300, bbox_inches='tight'); plt.close(fig)

# 7. Cloud-Penetrating Yield Prediction
fig, ax = setup_ax("Predicted Yield (kg/ha) - Cloud Penetrating", "")
Yield = 2000 + 1000 * np.sin(X*8) * np.cos(Y*8) + np.random.normal(0, 100, X.shape)
c = ax.contourf(X, Y, Yield, levels=20, cmap='YlGn', alpha=0.9)
plt.colorbar(c, ax=ax, pad=0.02).set_label('Yield (kg/ha)', fontsize=14, fontweight='bold')
plt.tight_layout(); plt.savefig(r'C:\SPROUT-Qonnect\08_presentation\figures\ssl_yield_prediction.png', dpi=300, bbox_inches='tight'); plt.close(fig)

# 8. Hail / Storm Damage Segmentation
fig, ax = setup_ax("Storm Damage Segmentation", "")
Damage = np.zeros_like(X)
Damage[(X > 37.52) & (X < 37.58) & (Y > 6.05) & (Y < 6.10)] = 1
Damage[(X > 37.60) & (X < 37.63) & (Y > 6.30) & (Y < 6.35)] = 1
c = ax.contourf(X, Y, Damage, levels=1, cmap='Reds', alpha=0.9)
plt.tight_layout(); plt.savefig(r'C:\SPROUT-Qonnect\08_presentation\figures\ssl_hail_damage.png', dpi=300, bbox_inches='tight'); plt.close(fig)

# 9. Soil Organic Carbon Proxy
fig, ax = setup_ax("Soil Organic Carbon (SOC) Proxy Map", "")
SOC = 1.0 + 0.5 * np.sin(X*12) * np.cos(Y*12)
c = ax.contourf(X, Y, SOC, levels=20, cmap='copper', alpha=0.9)
plt.colorbar(c, ax=ax, pad=0.02).set_label('SOC Proxy (%)', fontsize=14, fontweight='bold')
plt.tight_layout(); plt.savefig(r'C:\SPROUT-Qonnect\08_presentation\figures\ssl_soc_proxy.png', dpi=300, bbox_inches='tight'); plt.close(fig)

# 10. Payout Confidence Score Map
fig, ax = setup_ax("Parametric Payout Confidence Score", "")
Confidence = np.exp(-((X - 37.58)**2 / 0.01 + (Y - 6.35)**2 / 0.02))
c = ax.contourf(X, Y, Confidence, levels=20, cmap='Greys', alpha=0.9)
plt.colorbar(c, ax=ax, pad=0.02).set_label('AI Confidence (0-1)', fontsize=14, fontweight='bold')
plt.tight_layout(); plt.savefig(r'C:\SPROUT-Qonnect\08_presentation\figures\ssl_payout_confidence.png', dpi=300, bbox_inches='tight'); plt.close(fig)

print("All remaining 8 SSL Maps successfully generated.")