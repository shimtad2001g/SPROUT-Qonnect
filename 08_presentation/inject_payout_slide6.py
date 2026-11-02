from pptx import Presentation
from pptx.util import Inches
from pptx.enum.shapes import MSO_SHAPE_TYPE

# Load the final MASTER presentation
path = r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_MASTER_FINAL.pptx'
prs = Presentation(path)

# Slide 6 is index 5 (Business Model)
slide6 = prs.slides[5]

# 1. Remove the existing map from the right side
for i in range(len(slide6.shapes) - 1, -1, -1):
    shape = slide6.shapes[i]
    if shape.shape_type == MSO_SHAPE_TYPE.PICTURE:
        sp = shape._element
        sp.getparent().remove(sp)
        break

# 2. Add the Payout Zones Map
img_path = r'C:\SPROUT-Qonnect\08_presentation\figures\insurance_payout_zones.png'
# (Left, Top, Width) - Placing it on the right side
slide6.shapes.add_picture(img_path, Inches(6.2), Inches(2.2), width=Inches(6.5))

# Save the updated presentation
prs.save(path)
print("Payout Zones Map injected into Slide 6.")