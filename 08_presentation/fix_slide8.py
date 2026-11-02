from pptx import Presentation

# Load the current fixed presentation
path = r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_FINAL_FIXED.pptx'
prs = Presentation(path)

# Slide 8 is index 7
slide8 = prs.slides[7]

# We need to remove the old text boxes that are overlapping the chart.
# They contain the text "Phase 1", "Phase 2", etc., but are NOT the chart image.
for shape in list(slide8.shapes):
    if shape.has_text_frame:
        text = shape.text_frame.text
        if "Phase 1" in text or "Phase 2" in text or "Phase 3" in text:
            sp = shape._element
            sp.getparent().remove(sp)

prs.save(path)
print("Overlapping text boxes on Slide 8 have been successfully removed.")