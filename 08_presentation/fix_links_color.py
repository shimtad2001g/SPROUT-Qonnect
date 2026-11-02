from pptx import Presentation
from pptx.dml.color import RGBColor

# Load the previously fixed presentation
path = r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_FINAL_FIXED.pptx'
prs = Presentation(path)

GREEN = RGBColor(27, 67, 50)      # Deep Forest Green
AMBER = RGBColor(231, 111, 81)    # Warning/Alert
DARK = RGBColor(33, 37, 41)

for slide in prs.slides:
    for shape in slide.shapes:
        if shape.has_text_frame:
            for paragraph in shape.text_frame.paragraphs:
                text = paragraph.text
                if "streamlit.app" in text or "github.com" in text or "Live Dashboard" in text:
                    # If it's the final Q&A slide (dark green background), make it AMBER
                    if "Thank You" in "".join([s.text for s in slide.shapes if s.has_text_frame]):
                        paragraph.font.color.rgb = AMBER
                        paragraph.font.bold = True
                    # If it's the TRL 7 slide (light box), make it GREEN
                    else:
                        paragraph.font.color.rgb = GREEN
                        paragraph.font.bold = True

prs.save(r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_FINAL_FIXED.pptx')
print("Colors updated. Links should now be visible.")