from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN

# --- COLOR PALETTE ---
GREEN = RGBColor(27, 67, 50)      
TEAL = RGBColor(42, 157, 143)     
AMBER = RGBColor(231, 111, 81)    
DARK = RGBColor(33, 37, 41)       
LIGHT_BG = RGBColor(248, 249, 250)

# Load Milestone 2
prs = Presentation(r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_Milestone2.pptx')
blank_slide_layout = prs.slide_layouts[6]

def add_title_and_subtitle(slide, title_text, subtitle_text):
    title_box = slide.shapes.add_textbox(Inches(1), Inches(0.5), Inches(11), Inches(1))
    tf = title_box.text_frame
    p = tf.add_paragraph()
    p.text = title_text
    p.font.size = Pt(36)
    p.font.bold = True
    p.font.color.rgb = GREEN
    p.font.name = 'Calibri'
    
    sub_box = slide.shapes.add_textbox(Inches(1), Inches(1.5), Inches(11), Inches(0.5))
    tf = sub_box.text_frame
    p = tf.add_paragraph()
    p.text = subtitle_text
    p.font.size = Pt(20)
    p.font.color.rgb = TEAL
    p.font.name = 'Calibri'

# =====================================================================
# SLIDE 6: BUSINESS MODEL (FIVE PILLARS)
# =====================================================================
slide6 = prs.slides.add_slide(blank_slide_layout)
add_title_and_subtitle(slide6, "The Business Model", "A Five-Pillar Economic Engine")

pillars = [
    ("1. EUDR Traceability", "Geolocation and compliance for EU exports."),
    ("2. Climate Finance", "Bankable data for green credit."),
    ("3. Crop Insurance", "Satellite triggers for instant payouts."),
    ("4. Carbon Trade", "tCO2 tokens via Verra VM0047."),
    ("5. E-commerce", "Direct farmer-to-buyer marketplace.")
]

x_positions = [0.5, 3.0, 5.5, 8.0, 10.5]
for i, (title, desc) in enumerate(pillars):
    box = slide6.shapes.add_shape(1, Inches(x_positions[i]), Inches(3), Inches(2.2), Inches(3))
    box.fill.solid()
    box.fill.fore_color.rgb = LIGHT_BG
    box.line.color.rgb = TEAL
    box.line.width = Pt(2)
    
    tf = box.text_frame
    tf.word_wrap = True
    p = tf.add_paragraph()
    p.text = title
    p.font.bold = True
    p.font.size = Pt(18)
    p.font.color.rgb = GREEN
    p.alignment = PP_ALIGN.CENTER
    
    p2 = tf.add_paragraph()
    p2.text = desc
    p2.font.size = Pt(14)
    p2.font.color.rgb = DARK
    p2.alignment = PP_ALIGN.CENTER
    p2.space_before = Pt(10)

# =====================================================================
# SLIDE 7: IMPACT METRICS
# =====================================================================
slide7 = prs.slides.add_slide(blank_slide_layout)
add_title_and_subtitle(slide7, "Theory of Change", "Measurable Impact by Year 3")

metrics = [
    ("100,000 ha", "Climate", "Under verified sustainable management"),
    ("70%", "Economic", "Carbon revenue share directly to farmers"),
    ("100%", "Regulatory", "EUDR compliance for partner exporters"),
    ("50,000", "Social", "Farmers onboarded via local language apps")
]

x_positions = [0.5, 6.8]
y_positions = [2.5, 5.0]

for i, (stat, label, desc) in enumerate(metrics):
    col = i % 2
    row = i // 2
    x = x_positions[col]
    y = y_positions[row]
    
    box = slide7.shapes.add_shape(1, Inches(x), Inches(y), Inches(6), Inches(2))
    box.fill.solid()
    box.fill.fore_color.rgb = LIGHT_BG
    box.line.color.rgb = GREEN
    box.line.width = Pt(3)
    
    tf = box.text_frame
    p = tf.add_paragraph()
    p.text = f"{stat}  |  {label}"
    p.font.bold = True
    p.font.size = Pt(28)
    p.font.color.rgb = AMBER
    p.alignment = PP_ALIGN.CENTER
    
    p2 = tf.add_paragraph()
    p2.text = desc
    p2.font.size = Pt(16)
    p2.font.color.rgb = DARK
    p2.alignment = PP_ALIGN.CENTER

# =====================================================================
# SLIDE 8: ACCELERATED ROADMAP
# =====================================================================
slide8 = prs.slides.add_slide(blank_slide_layout)
add_title_and_subtitle(slide8, "Accelerated Roadmap", "Built Ahead of Schedule, Ready to Scale")

phases = [
    ("Phase 1 (0-6mo)", "Pilot scale in Gamo Gofa. Onboard 5,000 farmers. Migrate to PostGIS."),
    ("Phase 2 (6-12mo)", "ECTMS and EU TRACES integration. Polygon tCO2 tokenization."),
    ("Phase 3 (12-36mo)", "Scale across East Africa (Kenya, Uganda). Verra issuance.")
]

y_pos = 2.5
for title, desc in phases:
    box = slide8.shapes.add_shape(1, Inches(1), Inches(y_pos), Inches(11), Inches(1.2))
    box.fill.solid()
    box.fill.fore_color.rgb = LIGHT_BG
    box.line.color.rgb = TEAL
    box.line.width = Pt(2)
    
    tf = box.text_frame
    p = tf.add_paragraph()
    p.text = title
    p.font.bold = True
    p.font.size = Pt(22)
    p.font.color.rgb = GREEN
    
    p2 = tf.add_paragraph()
    p2.text = desc
    p2.font.size = Pt(16)
    p2.font.color.rgb = DARK
    
    y_pos += 1.4

# =====================================================================
# SLIDE 9: TEAM & CONSORTIUM
# =====================================================================
slide9 = prs.slides.add_slide(blank_slide_layout)
add_title_and_subtitle(slide9, "The Consortium", "Ethiopian Innovation + International Architecture")

left_box = slide9.shapes.add_textbox(Inches(1), Inches(2.5), Inches(5), Inches(4))
tf = left_box.text_frame
p = tf.add_paragraph()
p.text = "SPROUT Lead"
p.font.bold = True
p.font.size = Pt(24)
p.font.color.rgb = GREEN
p2 = tf.add_paragraph()
p2.text = "Shimeles Tadesse Zelelew"
p2.font.size = Pt(20)
p2.font.color.rgb = DARK
p3 = tf.add_paragraph()
p3.text = "GeoAI and spatial architecture expert. Built the live API, EUDR validator, and dashboard."
p3.font.size = Pt(16)
p3.font.color.rgb = DARK

right_box = slide9.shapes.add_textbox(Inches(7), Inches(2.5), Inches(5), Inches(4))
tf = right_box.text_frame
p = tf.add_paragraph()
p.text = "TraceRight Consortium"
p.font.bold = True
p.font.size = Pt(24)
p.font.color.rgb = GREEN
p2 = tf.add_paragraph()
p2.text = "NADAR Satellite & Qonnect"
p2.font.size = Pt(20)
p2.font.color.rgb = DARK
p3 = tf.add_paragraph()
p3.text = "Blockchain, satellite intelligence, and regulatory compliance experts."
p3.font.size = Pt(16)
p3.font.color.rgb = DARK

# =====================================================================
# SLIDE 10: THE ASK
# =====================================================================
slide10 = prs.slides.add_slide(blank_slide_layout)
add_title_and_subtitle(slide10, "Immediate Next Steps", "Five Actions to Integrate Systems")

box = slide10.shapes.add_shape(1, Inches(1), Inches(2.2), Inches(11), Inches(4.5))
box.fill.solid()
box.fill.fore_color.rgb = LIGHT_BG
box.line.color.rgb = AMBER
box.line.width = Pt(3)

tf = box.text_frame
asks = [
    "1. Nominate a technical counterpart for integration.",
    "2. Confirm the commercial model (Licensed API vs. Embedded Module).",
    "3. Share ECTMS and Hyperledger Fabric documentation.",
    "4. Confirm the first commercial target (EU Buyer, Carbon, or Insurance).",
    "5. Schedule the inception meeting to sign the alignment contract."
]

for ask in asks:
    p = tf.add_paragraph()
    p.text = ask
    p.font.size = Pt(20)
    p.font.color.rgb = DARK
    p.space_after = Pt(12)

# =====================================================================
# SLIDE 11: Q&A
# =====================================================================
slide11 = prs.slides.add_slide(blank_slide_layout)
bg = slide11.shapes.add_shape(1, 0, 0, prs.slide_width, prs.slide_height)
bg.fill.solid()
bg.fill.fore_color.rgb = GREEN
bg.line.color.rgb = GREEN

title_box = slide11.shapes.add_textbox(Inches(1), Inches(2), Inches(11), Inches(1.5))
tf = title_box.text_frame
p = tf.add_paragraph()
p.text = "Thank You"
p.font.size = Pt(64)
p.font.bold = True
p.font.color.rgb = LIGHT_BG
p.alignment = PP_ALIGN.CENTER

sub_box = slide11.shapes.add_textbox(Inches(1), Inches(3.5), Inches(11), Inches(1))
tf = sub_box.text_frame
p = tf.add_paragraph()
p.text = "Questions & Discussion"
p.font.size = Pt(32)
p.font.color.rgb = TEAL
p.alignment = PP_ALIGN.CENTER

links_box = slide11.shapes.add_textbox(Inches(1), Inches(5.5), Inches(11), Inches(1))
tf = links_box.text_frame
p = tf.add_paragraph()
p.text = "Live Dashboard: sprout-qonnect-clnhwfubq2y6y9bafzg.streamlit.app"
p.font.size = Pt(16)
p.font.color.rgb = LIGHT_BG
p.alignment = PP_ALIGN.CENTER
p2 = tf.add_paragraph()
p2.text = "GitHub: github.com/shimtad2001g/SPROUT-Qonnect"
p2.font.size = Pt(16)
p2.font.color.rgb = LIGHT_BG
p2.alignment = PP_ALIGN.CENTER

prs.save(r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_FINAL.pptx')
print("Milestone 3 complete: FINAL presentation generated.")