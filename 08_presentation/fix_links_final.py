from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN

path = r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_FINAL_FIXED.pptx'
prs = Presentation(path)

# Slide 4 is index 3
slide4 = prs.slides[3]

# 1. Find and delete the old broken box
for shape in slide4.shapes:
    if shape.has_text_frame and "LIVE LINKS" in shape.text_frame.text:
        sp = shape._element
        sp.getparent().remove(sp)
        break

# Colors
TEAL = RGBColor(42, 157, 143)     
BLUE = RGBColor(0, 0, 255)        
BLACK = RGBColor(0, 0, 0)         # Standard visible black

# 2. Create the new box
txBox = slide4.shapes.add_textbox(Inches(8.5), Inches(2.5), Inches(4), Inches(3.5))
tf = txBox.text_frame
tf.word_wrap = True

# Title
p1 = tf.paragraphs[0]
p1.text = "LIVE LINKS"
p1.font.size = Pt(22)
p1.font.bold = True
p1.font.color.rgb = TEAL
p1.alignment = PP_ALIGN.CENTER
p1.space_after = Pt(20)

# Dashboard Label
p2 = tf.add_paragraph()
p2.text = "Dashboard:"
p2.font.size = Pt(16)
p2.font.bold = True
p2.font.color.rgb = BLACK
p2.alignment = PP_ALIGN.CENTER

# Dashboard URL
p3 = tf.add_paragraph()
p3.text = "sprout-qonnect-clnhwfubq2y6y9bafzg.streamlit.app"
p3.font.size = Pt(12)
p3.font.bold = True
p3.font.color.rgb = BLUE
p3.alignment = PP_ALIGN.CENTER
p3.space_after = Pt(20)

# Codebase Label
p4 = tf.add_paragraph()
p4.text = "Codebase:"
p4.font.size = Pt(16)
p4.font.bold = True
p4.font.color.rgb = BLACK
p4.alignment = PP_ALIGN.CENTER

# Codebase URL
p5 = tf.add_paragraph()
p5.text = "github.com/shimtad2001g/SPROUT-Qonnect"
p5.font.size = Pt(12)
p5.font.bold = True
p5.font.color.rgb = BLUE
p5.alignment = PP_ALIGN.CENTER

prs.save(path)
print("Links box completely rebuilt and colored correctly.")