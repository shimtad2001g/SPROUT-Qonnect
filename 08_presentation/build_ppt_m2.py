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

# Load Milestone 1
prs = Presentation(r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_Milestone1.pptx')
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
# SLIDE 3: ARCHITECTURE
# =====================================================================
slide3 = prs.slides.add_slide(blank_slide_layout)
add_title_and_subtitle(slide3, "The TraceRight-SPROUT Architecture", "A 4-Layer System Connecting Farmers to Global Markets")

layers = [
    ("Layer 1: Mobile Data Capture", "IME & Qonnect Origin (Offline-first, GPS polygons)", TEAL, LIGHT_BG),
    ("Layer 2: Fair AI Spatial Verification", "SPROUT GeoAI (Sentinel-1/2, GEDI, Biomass)", TEAL, LIGHT_BG),
    ("Layer 3: Permissioned Ledger", "Hyperledger Fabric (Smart Contracts, EUDR, Fabric Hash)", GREEN, LIGHT_BG),
    ("Layer 4: Public Ledger", "Polygon (NFT Passports, tCO2 Tokens)", GREEN, LIGHT_BG)
]

y_pos = 2.2
for title, desc, color, bg_color in layers:
    # Left colored bar
    bar = slide3.shapes.add_shape(1, Inches(1), Inches(y_pos), Inches(0.2), Inches(1))
    bar.fill.solid()
    bar.fill.fore_color.rgb = color
    bar.line.color.rgb = color
    
    # Content box
    box = slide3.shapes.add_shape(1, Inches(1.2), Inches(y_pos), Inches(11), Inches(1))
    box.fill.solid()
    box.fill.fore_color.rgb = bg_color
    box.line.color.rgb = RGBColor(220, 220, 220)
    
    tf = box.text_frame
    p = tf.add_paragraph()
    p.text = title
    p.font.bold = True
    p.font.size = Pt(20)
    p.font.color.rgb = color
    p.font.name = 'Calibri'
    
    p2 = tf.add_paragraph()
    p2.text = desc
    p2.font.size = Pt(16)
    p2.font.color.rgb = DARK
    p2.font.name = 'Calibri'
    
    y_pos += 1.1

# =====================================================================
# SLIDE 4: TRL 7 (SHOVEL-READY)
# =====================================================================
slide4 = prs.slides.add_slide(blank_slide_layout)
add_title_and_subtitle(slide4, "Proven Technical Readiness (TRL 7)", "The SPROUT AI Layer is Already Built and Operational")

left_box = slide4.shapes.add_textbox(Inches(1), Inches(2.5), Inches(7), Inches(4))
tf = left_box.text_frame
tf.word_wrap = True

points = [
    ("Live API (FastAPI): ", "Returns 6-decimal EUDR GeoJSON in milliseconds."),
    ("Cryptographic Hash: ", "SHA-256 Fabric integration already implemented."),
    ("EUDR Gatekeeping: ", "Automatically rejects non-compliant data before it hits the ledger."),
    ("Open Source Core: ", "Transparent, auditable, and ready for scale.")
]

for bold_text, normal_text in points:
    p = tf.add_paragraph()
    p.space_after = Pt(15)
    
    run = p.add_run()
    run.text = bold_text
    run.font.bold = True
    run.font.size = Pt(20)
    run.font.color.rgb = GREEN
    run.font.name = 'Calibri'
    
    run2 = p.add_run()
    run2.text = normal_text
    run2.font.size = Pt(20)
    run2.font.color.rgb = DARK
    run2.font.name = 'Calibri'

# Live Links Box on the right
right_box = slide4.shapes.add_shape(1, Inches(8.5), Inches(2.5), Inches(4), Inches(3.5))
right_box.fill.solid()
right_box.fill.fore_color.rgb = LIGHT_BG
right_box.line.color.rgb = TEAL
right_box.line.width = Pt(2)

tf = right_box.text_frame
tf.word_wrap = True
p = tf.add_paragraph()
p.text = "LIVE LINKS"
p.font.size = Pt(22)
p.font.bold = True
p.font.color.rgb = TEAL
p.alignment = PP_ALIGN.CENTER

p2 = tf.add_paragraph()
p2.text = "\nDashboard:\nstreamlit.app/\n\nCodebase:\ngithub.com/shimtad2001g/SPROUT-Qonnect"
p2.font.size = Pt(14)
p2.font.color.rgb = DARK
p2.alignment = PP_ALIGN.CENTER

# =====================================================================
# SLIDE 5: LIVE DEMO
# =====================================================================
slide5 = prs.slides.add_slide(blank_slide_layout)
# Full background
bg = slide5.shapes.add_shape(1, 0, 0, prs.slide_width, prs.slide_height)
bg.fill.solid()
bg.fill.fore_color.rgb = GREEN
bg.line.color.rgb = GREEN

# Big Text
title_box = slide5.shapes.add_textbox(Inches(1), Inches(2.5), Inches(11), Inches(2))
tf = title_box.text_frame
p = tf.add_paragraph()
p.text = "LIVE DEMO"
p.font.size = Pt(72)
p.font.bold = True
p.font.color.rgb = AMBER
p.alignment = PP_ALIGN.CENTER
p.font.name = 'Calibri'

# Subtitle
sub_box = slide5.shapes.add_textbox(Inches(1), Inches(4.5), Inches(11), Inches(1))
tf = sub_box.text_frame
p = tf.add_paragraph()
p.text = "TraceRight Consortium Portal"
p.font.size = Pt(32)
p.font.color.rgb = LIGHT_BG
p.alignment = PP_ALIGN.CENTER
p.font.name = 'Calibri'

# Footer instruction
footer_box = slide5.shapes.add_textbox(Inches(1), Inches(6), Inches(11), Inches(1))
tf = footer_box.text_frame
p = tf.add_paragraph()
p.text = "Switching to browser now..."
p.font.size = Pt(20)
p.font.color.rgb = TEAL
p.alignment = PP_ALIGN.CENTER
p.font.name = 'Calibri'

prs.save(r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_Milestone2.pptx')
print("Milestone 2 complete: Slides 3, 4, and 5 generated.")