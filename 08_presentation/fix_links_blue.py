from pptx import Presentation
from pptx.util import Pt
from pptx.dml.color import RGBColor

path = r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_FINAL_FIXED.pptx'
prs = Presentation(path)

# Slide 4 is index 3
slide4 = prs.slides[3]

BLUE = RGBColor(0, 0, 255) # Pure Blue
TEAL = RGBColor(42, 157, 143)

for shape in slide4.shapes:
    if shape.has_text_frame and "LIVE LINKS" in shape.text_frame.text:
        # We found the box. Let's clear it and rewrite it properly.
        tf = shape.text_frame
        tf.clear()
        
        # Title
        p = tf.paragraphs[0]
        p.text = "LIVE LINKS"
        p.font.size = Pt(22)
        p.font.bold = True
        p.font.color.rgb = TEAL
        p.alignment = 1 # Center
        
        # Dashboard Link
        p2 = tf.add_paragraph()
        p2.text = "\nDashboard:\n"
        p2.font.size = Pt(14)
        p2.font.color.rgb = RGBColor(33, 37, 41) # Dark
        p2.alignment = 1
        
        run = p2.add_run()
        run.text = "sprout-qonnect-clnhwfubq2y6y9bafzg.streamlit.app"
        run.font.size = Pt(12)
        run.font.color.rgb = BLUE
        run.font.bold = True
        
        # Codebase Link
        p3 = tf.add_paragraph()
        p3.text = "\nCodebase:\n"
        p3.font.size = Pt(14)
        p3.font.color.rgb = RGBColor(33, 37, 41) # Dark
        p3.alignment = 1
        
        run2 = p3.add_run()
        run2.text = "github.com/shimtad2001g/SPROUT-Qonnect"
        run2.font.size = Pt(12)
        run2.font.color.rgb = BLUE
        run2.font.bold = True

prs.save(path)
print("Links on Slide 4 have been rewritten in BLUE.")