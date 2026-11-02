# =====================================================================
# TraceRight-SPROUT | Step 15: Generate & Inject Deforestation & Africa Maps
# =====================================================================
$ErrorActionPreference = 'Continue'
$ROOT = 'C:\SPROUT-Qonnect'
$DASH = Join-Path $ROOT '08_presentation'
$FIGS = Join-Path $DASH 'figures'

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

Write-Host "=== GENERATING BONUS MAPS ===" -ForegroundColor Cyan

$pyCode = @'
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Polygon
import matplotlib.patches as mpatches
import warnings
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor

warnings.filterwarnings("ignore")

# =====================================================================
# MAP 1: DEFORESTATION RISK (Slide 2)
# =====================================================================
fig1, ax1 = plt.subplots(figsize=(12, 8), facecolor='#F8F9FA')
ax1.set_facecolor('#f1f3f5')

# Simulate risk (0 = safe, 1 = high risk)
x = np.linspace(37.45, 37.65, 100)
y = np.linspace(5.95, 6.45, 100)
X, Y = np.meshgrid(x, y)
# Create a "blob" of high risk in the north (near Plot 3)
Risk = np.exp(-((X - 37.60)**2 / 0.005 + (Y - 6.40)**2 / 0.01)) 
Risk += np.random.normal(0, 0.05, Risk.shape) # Add noise
Risk = np.clip(Risk, 0, 1)

# Plot Risk Heatmap
contour = ax1.contourf(X, Y, Risk, levels=20, cmap='RdYlGn_r', alpha=0.8)
cbar = plt.colorbar(contour, ax=ax1, pad=0.02)
cbar.set_label('Deforestation Risk (EUDR R6)', fontsize=14, fontweight='bold', color='#1B4332')
cbar.ax.tick_params(labelsize=12)

# Overlay the 3 plots
plots = [
    {"id": "PLT-GAMO-0001", "coords": [(37.550001, 5.999999), (37.551001, 5.999999), (37.551001, 6.001001), (37.550001, 6.001001), (37.550001, 5.999999)]},
    {"id": "PLT-GAMO-0002", "coords": [(37.570001, 6.249999), (37.572001, 6.249999), (37.572001, 6.252001), (37.570001, 6.252001), (37.570001, 6.249999)]},
    {"id": "PLT-GAMO-0003", "coords": [(37.600001, 6.399999), (37.601001, 6.399999), (37.601001, 6.401001), (37.600001, 6.401001), (37.600001, 6.399999)]}
]
for p in plots:
    coords = p["coords"]
    cx = sum(x for x, y in coords) / len(coords)
    cy = sum(y for x, y in coords) / len(coords)
    ax1.scatter(cx, cy, s=120, color='black', edgecolor='white', linewidth=2, zorder=5)
    ax1.annotate(p["id"], xy=(cx, cy), xytext=(10, 10), textcoords="offset points",
                 fontsize=10, fontweight='bold', color='black', 
                 bbox=dict(boxstyle="round,pad=0.3", fc='white', ec="black", alpha=0.8))

ax1.set_title("EUDR Deforestation Risk Assessment - Gamo Gofa", fontsize=20, fontweight='bold', color='#1B4332', pad=20)
ax1.set_xlabel("Longitude", fontsize=12); ax1.set_ylabel("Latitude", fontsize=12)
ax1.set_xlim(37.40, 37.75); ax1.set_ylim(5.85, 6.55)
plt.tight_layout()
risk_path = r'C:\SPROUT-Qonnect\08_presentation\figures\deforestation_risk_map.png'
plt.savefig(risk_path, dpi=300, bbox_inches='tight')
plt.close(fig1)

# =====================================================================
# MAP 2: PAN-AFRICAN SCALE (Slide 8)
# =====================================================================
fig2, ax2 = plt.subplots(figsize=(12, 8), facecolor='#1B4332')
ax2.set_facecolor('#1B4332')

# Define nodes (stylized coordinates)
nodes = {
    'Ethiopia (Pilot)': (0, 0, '#E76F51', 400), # Central, Amber
    'Kenya': (1, -2, '#2A9D8F', 200),
    'Uganda': (-1, -1, '#2A9D8F', 200),
    'Rwanda': (-1.5, -2.5, '#2A9D8F', 150),
    'Tanzania': (0.5, -4, '#2A9D8F', 250),
    'Zambia': (-0.5, -6, '#2A9D8F', 150)
}

# Draw connecting lines (expansion routes)
for name, (x, y, c, s) in nodes.items():
    if name != 'Ethiopia (Pilot)':
        ax2.plot([0, x], [0, y], color='#F8F9FA', linewidth=2, linestyle='--', alpha=0.6)
        # Add arrowhead
        ax2.annotate('', xy=(x, y), xytext=(0, 0),
                     arrowprops=dict(arrowstyle="->", color='#F8F9FA', lw=2, alpha=0.6))

# Draw nodes
for name, (x, y, c, s) in nodes.items():
    ax2.scatter(x, y, color=c, s=s, edgecolor='white', linewidth=2, zorder=5)
    # Label
    y_offset = 0.4 if name == 'Ethiopia (Pilot)' else -0.5
    ax2.text(x, y + y_offset, name, color='white', fontsize=12, fontweight='bold', ha='center', zorder=6)

ax2.set_title("TraceRight Pan-African Expansion Roadmap", fontsize=24, fontweight='bold', color='white', pad=20)
ax2.axis('off') # Hide axes

# Add a subtle grid for tech feel
ax2.grid(True, linestyle=':', color='white', alpha=0.1)
ax2.set_xlim(-3, 3)
ax2.set_ylim(-7, 2)

plt.tight_layout()
africa_path = r'C:\SPROUT-Qonnect\08_presentation\figures\africa_scale_map.png'
plt.savefig(africa_path, dpi=300, bbox_inches='tight', facecolor='#1B4332')
plt.close(fig2)

print("Both maps generated successfully. Now injecting into PPT...")

# =====================================================================
# INJECT INTO POWERPOINT
# =====================================================================
path = r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_MASTER_FINAL.pptx'
prs = Presentation(path)

# --- Slide 2 (The Problem) ---
slide2 = prs.slides[1]
# Remove the old right-side text box
for i in range(len(slide2.shapes) - 1, -1, -1):
    shape = slide2.shapes[i]
    if shape.has_text_frame and "Dec 2026 Deadline" in shape.text_frame.text:
        sp = shape._element
        sp.getparent().remove(sp)
        break
# Add Risk Map
slide2.shapes.add_picture(risk_path, Inches(6.5), Inches(2.2), width=Inches(6.2))

# --- Slide 8 (Roadmap) ---
slide8 = prs.slides[7]
# Remove the old Gantt chart to make room
for i in range(len(slide8.shapes) - 1, -1, -1):
    shape = slide8.shapes[i]
    if shape.shape_type == 13: # Picture
        sp = shape._element
        sp.getparent().remove(sp)
        break
# Add the Africa Scale Map
slide8.shapes.add_picture(africa_path, Inches(2.0), Inches(2.2), width=Inches(9.3))

prs.save(path)
print(f"Success! Maps generated and injected into {path}")
'@

$pyPath = Join-Path $DASH 'generate_bonus_maps.py'
Write-Utf8NoBom -Path $pyPath -Text $pyCode

Write-Host "`n=== RUNNING GENERATOR ===" -ForegroundColor Cyan
python $pyPath

Write-Host "`n=== OPENING POWERPOINT ===" -ForegroundColor Cyan
Invoke-Item (Join-Path $DASH 'TraceRight_Proposal_MASTER_FINAL.pptx')

Write-Host "`n=== COMPLETE ===" -ForegroundColor Green