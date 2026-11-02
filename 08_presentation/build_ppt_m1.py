from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor

# --- COLOR PALETTE ---
GREEN = RGBColor(27, 67, 50)      # Deep Forest Green
TEAL = RGBColor(42, 157, 143)     # TraceRight Teal
AMBER = RGBColor(231, 111, 81)    # Warning/Alert
DARK = RGBColor(33, 37, 41)       # Text Dark
LIGHT_BG = RGBColor(248, 249, 250) # Off-white

prs = Presentation()
prs.slide_width = Inches(13.333)
prs.slide_height = Inches(7.5)
blank_slide_layout = prs.slide_layouts[6] # Blank layout for custom placement

def add_title_and_subtitle(slide, title_text, subtitle_text):
    # Add Title
    title_box = slide.shapes.add_textbox(Inches(1), Inches(1), Inches(11), Inches(1.5))
    tf = title_box.text_frame
    p = tf.add_paragraph()
    p.text = title_text
    p.font.size = Pt(44)
    p.font.bold = True
    p.font.color.rgb = GREEN
    p.font.name = 'Calibri'
    
    # Add Subtitle
    sub_box = slide.shapes.add_textbox(Inches(1), Inches(2.5), Inches(11), Inches(1))
    tf = sub_box.text_frame
    p = tf.add_paragraph()
    p.text = subtitle_text
    p.font.size = Pt(24)
    p.font.color.rgb = TEAL
    p.font.name = 'Calibri'

# =====================================================================
# SLIDE 1: TITLE SLIDE
# =====================================================================
slide1 = prs.slides.add_slide(blank_slide_layout)
# Background color
bg1 = slide1.shapes.add_shape(1, 0, 0, prs.slide_width, prs.slide_height)
bg1.fill.solid()
bg1.fill.fore_color.rgb = GREEN
bg1.line.color.rgb = GREEN

# Main Title
title_box = slide1.shapes.add_textbox(Inches(1), Inches(2.5), Inches(11), Inches(2))
tf = title_box.text_frame
p = tf.add_paragraph()
p.text = "TraceRight-SPROUT Consortium"
p.font.size = Pt(54)
p.font.bold = True
p.font.color.rgb = LIGHT_BG
p.font.name = 'Calibri'

# Subtitle
sub_box = slide1.shapes.add_textbox(Inches(1), Inches(4.5), Inches(11), Inches(1))
tf = sub_box.text_frame
p = tf.add_paragraph()
p.text = "End-to-End Digital MRV and EUDR-Compliant Traceability for African Agriculture"
p.font.size = Pt(24)
p.font.color.rgb = TEAL
p.font.name = 'Calibri'

# Footer
footer_box = slide1.shapes.add_textbox(Inches(1), Inches(6.5), Inches(11), Inches(0.5))
tf = footer_box.text_frame
p = tf.add_paragraph()
p.text = "Shimeles Tadesse Zelelew | Project SPROUT | November 19, 2026"
p.font.size = Pt(14)
p.font.color.rgb = LIGHT_BG

# =====================================================================
# SLIDE 2: THE PROBLEM
# =====================================================================
slide2 = prs.slides.add_slide(blank_slide_layout)
add_title_and_subtitle(slide2, "The $3B Problem", "The Compliance Gap Facing African Agriculture")

# Left Content - Bullet Points
left_box = slide2.shapes.add_textbox(Inches(1), Inches(4), Inches(6), Inches(3))
tf = left_box.text_frame
tf.word_wrap = True

points = [
    ("Regulatory Crisis: ", "EUDR (Dec 2026) requires 6-decimal GPS precision. Most smallholders lack this."),
    ("MRV Inefficiency: ", "Traditional carbon credit verification is slow, expensive, and prone to fraud."),
    ("Data Fragmentation: ", "Farm data is siloed between ECTMS, buyers, and carbon registries.")
]

for bold_text, normal_text in points:
    p = tf.add_paragraph()
    p.space_after = Pt(20)
    
    run = p.add_run()
    run.text = bold_text
    run.font.bold = True
    run.font.size = Pt(22)
    run.font.color.rgb = AMBER
    run.font.name = 'Calibri'
    
    run2 = p.add_run()
    run2.text = normal_text
    run2.font.size = Pt(22)
    run2.font.color.rgb = DARK
    run2.font.name = 'Calibri'

# Add a warning visual indicator on the right
right_box = slide2.shapes.add_shape(1, Inches(8), Inches(4), Inches(4), Inches(3))
right_box.fill.solid()
right_box.fill.fore_color.rgb = LIGHT_BG
right_box.line.color.rgb = AMBER
right_box.line.width = Pt(3)

tf = right_box.text_frame
tf.word_wrap = True
p = tf.add_paragraph()
p.text = "Dec 2026 Deadline"
p.font.size = Pt(32)
p.font.bold = True
p.font.color.rgb = AMBER
p.alignment = 1 # Center
p.font.name = 'Calibri'

p2 = tf.add_paragraph()
p2.text = "Threatens $3B+ in African exports"
p2.font.size = Pt(20)
p2.font.color.rgb = DARK
p2.alignment = 1
p2.font.name = 'Calibri'

prs.save(r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_Milestone1.pptx')
print("Milestone 1 complete: Slides 1 and 2 generated.")