from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN

# Load the fixed presentation (the one with the blue links and clean text)
path = r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_FINAL_FIXED.pptx'
prs = Presentation(path)

# Slide 3 is index 2
slide3 = prs.slides[2]

# Colors
GREEN = RGBColor(27, 67, 50)      
TEAL = RGBColor(42, 157, 143)     
DARK = RGBColor(33, 37, 41)       
LIGHT_BG = RGBColor(248, 249, 250)

# 1. Clear existing shapes on Slide 3 (except the Title)
for i in range(len(slide3.shapes) - 1, -1, -1):
    shape = slide3.shapes[i]
    if shape.has_text_frame:
        if "Architecture" in shape.text_frame.text or "4-Layer" in shape.text_frame.text:
            continue # Keep Title and Subtitle
    sp = shape._element
    sp.getparent().remove(sp)

# 2. Add the Map on the Right Side
img_path = r'C:\SPROUT-Qonnect\08_presentation\figures\realistic_satellite_map.png'
# Placing it at (X: 6.5 inches, Y: 2.0 inches) with a width of 6.2 inches
slide3.shapes.add_picture(img_path, Inches(6.5), Inches(2.2), width=Inches(6.2))

# 3. Re-add the 4 Layers on the Left Side
layers = [
    ("Layer 1: Mobile Data Capture", "IME & Qonnect Origin (Offline-first)", TEAL),
    ("Layer 2: Fair AI Spatial Verification", "SPROUT GeoAI (Sentinel-1/2, GEDI)", TEAL),
    ("Layer 3: Permissioned Ledger", "Hyperledger Fabric (Smart Contracts)", GREEN),
    ("Layer 4: Public Ledger", "Polygon (NFT Passports, tCO2 Tokens)", GREEN)
]

y_pos = 2.2
for title, desc, color in layers:
    # Colored vertical bar
    bar = slide3.shapes.add_shape(1, Inches(0.5), Inches(y_pos), Inches(0.1), Inches(0.9))
    bar.fill.solid()
    bar.fill.fore_color.rgb = color
    bar.line.color.rgb = color

    # Text Box
    box = slide3.shapes.add_textbox(Inches(0.7), Inches(y_pos), Inches(5.5), Inches(0.9))
    tf = box.text_frame
    tf.word_wrap = True
    
    p = tf.add_paragraph()
    p.text = title
    p.font.bold = True
    p.font.size = Pt(18)
    p.font.color.rgb = color
    p.font.name = 'Calibri'

    p2 = tf.add_paragraph()
    p2.text = desc
    p2.font.size = Pt(14)
    p2.font.color.rgb = DARK
    p2.font.name = 'Calibri'

    y_pos += 1.2

# Save as the final Master file
out_path = r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_MASTER_FINAL.pptx'
prs.save(out_path)

print(f"Slide 3 rebuilt with map. Saved to {out_path}")