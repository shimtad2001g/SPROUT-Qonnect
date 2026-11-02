import matplotlib.pyplot as plt
import numpy as np
from pptx import Presentation
from pptx.util import Inches, Pt

# --- COLOR PALETTE FOR MATPLOTLIB ---
GREEN = '#1B4332'
TEAL = '#2A9D8F'
AMBER = '#E76F51'
DARK = '#212529'
LIGHT_BG = '#F8F9FA'

figs_dir = r'C:\SPROUT-Qonnect\08_presentation\figures'

# =====================================================================
# FIGURE 1: EUDR EXPORT RISK (Slide 2)
# =====================================================================
plt.figure(figsize=(8, 5), facecolor=LIGHT_BG)
years = ['2024', '2025', '2026\n(EUDR Enforced)']
exports = [2.8, 3.0, 0.5] # Billions USD
colors = [GREEN, GREEN, AMBER]

bars = plt.bar(years, exports, color=colors, width=0.5)
plt.title('African Agricultural Exports to EU ($ Billions)', fontsize=16, color=DARK, pad=15, fontweight='bold')
plt.ylabel('Value in $ Billions', fontsize=12, color=DARK)
plt.ylim(0, 3.5)
plt.grid(axis='y', linestyle='--', alpha=0.7)

for bar in bars:
    yval = bar.get_height()
    plt.text(bar.get_x() + bar.get_width()/2, yval + 0.1, f"${yval}B", ha='center', va='bottom', fontsize=14, fontweight='bold', color=DARK)

plt.tight_layout()
plt.savefig(f'{figs_dir}/fig1_eudr_risk.png', dpi=300)
plt.close()

# =====================================================================
# FIGURE 2: IMPACT PROJECTION (Slide 7)
# =====================================================================
fig, ax1 = plt.figure(figsize=(10, 5), facecolor=LIGHT_BG), plt.gca()
years = ['Year 1', 'Year 2', 'Year 3']
hectares = [10000, 45000, 100000]
farmers = [5000, 22000, 50000]

# Bar chart for Hectares
ax1.bar(years, hectares, color=TEAL, width=0.4, label='Hectares Verified')
ax1.set_ylabel('Hectares Verified', color=TEAL, fontsize=12, fontweight='bold')
ax1.tick_params(axis='y', labelcolor=TEAL)
ax1.set_ylim(0, 120000)

# Line chart for Farmers
ax2 = ax1.twinx()
ax2.plot(years, farmers, color=AMBER, marker='o', linewidth=3, markersize=8, label='Farmers Onboarded')
ax2.set_ylabel('Farmers Onboarded', color=AMBER, fontsize=12, fontweight='bold')
ax2.tick_params(axis='y', labelcolor=AMBER)
ax2.set_ylim(0, 60000)

plt.title('Theory of Change: 3-Year Impact Projection', fontsize=16, color=DARK, pad=15, fontweight='bold')
fig.tight_layout()
plt.savefig(f'{figs_dir}/fig2_impact.png', dpi=300)
plt.close()

# =====================================================================
# FIGURE 3: ROADMAP GANTT (Slide 8)
# =====================================================================
fig, ax = plt.subplots(figsize=(10, 4), facecolor=LIGHT_BG)
tasks = ['Phase 1: Pilot (Gamo Gofa)', 'Phase 2: Integration (ECTMS)', 'Phase 3: Pan-African Scale']
starts = [0, 6, 12]
durations = [6, 6, 24]
colors = [TEAL, GREEN, DARK]

for i, (task, start, duration, color) in enumerate(zip(tasks, starts, durations, colors)):
    ax.barh(task, duration, left=start, height=0.5, color=color, edgecolor='white')
    ax.text(start + duration/2, i, f"{duration} Months", va='center', ha='center', color='white', fontweight='bold')

ax.set_xlabel('Months from Inception', fontsize=12, color=DARK, fontweight='bold')
ax.set_xlim(0, 36)
ax.set_xticks([0, 6, 12, 18, 24, 30, 36])
ax.invert_yaxis()  # Top to bottom
plt.title('Accelerated Implementation Roadmap', fontsize=16, color=DARK, pad=15, fontweight='bold')
plt.grid(axis='x', linestyle='--', alpha=0.7)
plt.tight_layout()
plt.savefig(f'{figs_dir}/fig3_roadmap.png', dpi=300)
plt.close()

print("Figures generated successfully.")

# =====================================================================
# INJECT FIGURES INTO POWERPOINT
# =====================================================================
prs = Presentation(r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_FINAL.pptx')

# Slide 2: Add Fig 1 (EUDR Risk)
slide2 = prs.slides[1]
# Clear existing text box on the right to make room for the chart
for shape in slide2.shapes:
    if shape.has_text_frame and "Dec 2026 Deadline" in shape.text_frame.text:
        sp = shape._element
        sp.getparent().remove(sp)
slide2.shapes.add_picture(f'{figs_dir}/fig1_eudr_risk.png', Inches(6.5), Inches(2.5), width=Inches(6))

# Slide 7: Add Fig 2 (Impact)
slide7 = prs.slides[6]
# Remove the 4 text boxes we created earlier
for shape in list(slide7.shapes):
    if shape.has_text_frame and ("100,000 ha" in shape.text_frame.text or "70%" in shape.text_frame.text):
        sp = shape._element
        sp.getparent().remove(sp)
slide7.shapes.add_picture(f'{figs_dir}/fig2_impact.png', Inches(1.5), Inches(2.5), width=Inches(10))

# Slide 8: Add Fig 3 (Roadmap)
slide8 = prs.slides[7]
# Remove the 3 text boxes we created earlier
for shape in list(slide8.shapes):
    if shape.has_text_frame and "Phase 1 (0-6mo)" in shape.text_frame.text:
        sp = shape._element
        sp.getparent().remove(sp)
slide8.shapes.add_picture(f'{figs_dir}/fig3_roadmap.png', Inches(1.5), Inches(2.5), width=Inches(10))

prs.save(r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_MASTER.pptx')
print("Master Presentation with figures saved.")