from pptx import Presentation
from pptx.util import Inches

# Load the MASTER presentation
prs = Presentation(r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_MASTER.pptx')

# Slide 9 is index 8
slide9 = prs.slides[8]

for shape in slide9.shapes:
    if shape.has_text_frame:
        # Find the Left Box (SPROUT Lead)
        if "SPROUT Lead" in shape.text_frame.text:
            shape.width = Inches(5.5) # Give it slightly more width
            shape.text_frame.word_wrap = True
            
        # Find the Right Box (TraceRight Consortium)
        if "TraceRight Consortium" in shape.text_frame.text:
            shape.left = Inches(7) # Keep it on the right
            shape.width = Inches(5.5)
            shape.text_frame.word_wrap = True

# Save as a new FINAL file so we don't break the original MASTER
prs.save(r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_FINAL_FIXED.pptx')
print("Slide 9 fixed and saved as TraceRight_Proposal_FINAL_FIXED.pptx")