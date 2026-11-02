from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN

# Colors
GREEN = RGBColor(27, 67, 50)      
TEAL = RGBColor(42, 157, 143)     
AMBER = RGBColor(231, 111, 81)    
DARK = RGBColor(33, 37, 41)       
LIGHT_BG = RGBColor(248, 249, 250)

prs = Presentation()
prs.slide_width = Inches(13.333)
prs.slide_height = Inches(7.5)
blank_slide_layout = prs.slide_layouts[6]

def add_qa_slide(question_num, stakeholder, question, answer, coach_tip):
    slide = prs.slides.add_slide(blank_slide_layout)
    bg = slide.shapes.add_shape(1, 0, 0, prs.slide_width, prs.slide_height)
    bg.fill.solid()
    bg.fill.fore_color.rgb = LIGHT_BG
    
    # Header
    header = slide.shapes.add_textbox(Inches(0.5), Inches(0.3), Inches(12), Inches(0.8))
    p = header.text_frame.add_paragraph()
    p.text = f"Q&A PLAYBOOK - Round {question_num}: {stakeholder}"
    p.font.size = Pt(24)
    p.font.bold = True
    p.font.color.rgb = GREEN
    
    # Question Box
    q_box = slide.shapes.add_shape(1, Inches(0.5), Inches(1.2), Inches(12.3), Inches(1.3))
    q_box.fill.solid()
    q_box.fill.fore_color.rgb = AMBER
    q_box.line.color.rgb = AMBER
    tf = q_box.text_frame
    tf.word_wrap = True
    p = tf.add_paragraph()
    p.text = f'"{question}"'
    p.font.size = Pt(18)
    p.font.bold = True
    p.font.color.rgb = RGBColor(255, 255, 255)
    
    # Answer Box
    a_box = slide.shapes.add_textbox(Inches(0.5), Inches(2.8), Inches(12.3), Inches(3.5))
    tf = a_box.text_frame
    tf.word_wrap = True
    p = tf.add_paragraph()
    p.text = answer
    p.font.size = Pt(16)
    p.font.color.rgb = DARK
    p.line_spacing = 1.2
    
    # Coach Tip Box
    c_box = slide.shapes.add_shape(1, Inches(0.5), Inches(6.4), Inches(12.3), Inches(0.8))
    c_box.fill.solid()
    c_box.fill.fore_color.rgb = TEAL
    c_box.line.color.rgb = TEAL
    tf = c_box.text_frame
    p = tf.add_paragraph()
    p.text = f"COACH'S TIP: {coach_tip}"
    p.font.size = Pt(14)
    p.font.bold = True
    p.font.color.rgb = RGBColor(255, 255, 255)

# =====================================================================
# SLIDE 1: TITLE
# =====================================================================
slide1 = prs.slides.add_slide(blank_slide_layout)
bg1 = slide1.shapes.add_shape(1, 0, 0, prs.slide_width, prs.slide_height)
bg1.fill.solid()
bg1.fill.fore_color.rgb = GREEN
bg1.line.color.rgb = GREEN

title_box = slide1.shapes.add_textbox(Inches(1), Inches(2.5), Inches(11), Inches(2))
p = title_box.text_frame.add_paragraph()
p.text = "TraceRight-SPROUT Consortium"
p.font.size = Pt(48)
p.font.bold = True
p.font.color.rgb = LIGHT_BG
p.alignment = PP_ALIGN.CENTER

sub_box = slide1.shapes.add_textbox(Inches(1), Inches(4), Inches(11), Inches(1))
p = sub_box.text_frame.add_paragraph()
p.text = "The Mock Q&A Playbook"
p.font.size = Pt(32)
p.font.color.rgb = TEAL
p.alignment = PP_ALIGN.CENTER

# =====================================================================
# SLIDE 2: ROUND 1 (TADESSE / MOBILE)
# =====================================================================
add_qa_slide(
    1, "Tadesse (Integration)",
    "How do we ensure the app doesn't crash on a cheap phone, and how does the data sync to your SPROUT API?",
    "â€¢ Mobile side: IME/Qonnect apps are lightweight, using native GPS to draw polygons with minimal battery/power.\nâ€¢ Sync side: Data is stored locally in an encrypted DB on the phone, and pushed to the SPROUT API when a 3G/Wi-Fi signal is reached.\nâ€¢ Server side: The heavy lifting (EUDR validation, Biomass calculation, SHA-256 hashing) happens on the cloud API, not the phone.\nâ€¢ Scale: We use a cooperative batch-sync model (uploading hundreds of farmers at once) for the 1.5M ECTMS producers.",
    "Project absolute confidence. You built this specifically for the African reality: low-end phones, poor internet, and cooperative structures."
)

# =====================================================================
# SLIDE 3: ROUND 2 (FUNDER / CORRUPTION)
# =====================================================================
add_qa_slide(
    2, "EU Funder (Trust & Payouts)",
    "How do we know a corrupt cooperative leader won't take the farmer's phone and steal the 70% carbon credit payout?",
    "â€¢ Biometric KYC: The IME app binds the polygon to the farmer's biometric identity, not just the phone.\nâ€¢ Legal Framework: Ethiopian Directive 1141/2026 grants exclusive legal title of carbon credits directly to the farmer.\nâ€¢ Smart Contracts: When carbon is sold, the stablecoin payout is split (70/30) and routed directly to the farmer's digital wallet, bypassing the cooperative leader entirely.\nâ€¢ Fraud Alert: Any biometric mismatch instantly flags a fraud alert and rejects the EU buyer's Due Diligence Statement (DDS).",
    "This is your strongest answer. It shows you understand the real-world corruption risks in African agriculture and use blockchain to solve them."
)

# =====================================================================
# SLIDE 4: ROUND 3 (TADESSE / SCALING)
# =====================================================================
add_qa_slide(
    3, "Tadesse (Scaling & Fabric)",
    "What happens when NADAR sends 100,000 plots at once? How does the API handle the load, and how does it get into my Fabric ledger?",
    "â€¢ Async Load Handling: The API drops the bulk file into a message queue. Containerized workers process it in parallel (e.g., 20 workers processing 5,000 plots each).\nâ€¢ Database: We migrate to PostGIS, using spatial indexing (GIST) for millisecond query times on millions of records.\nâ€¢ Fabric Handoff: We do not send 100,000 transactions to Fabric. We validate the batch and generate ONE master SHA-256 hash per sub-batch (e.g., 1,000 plots) to keep your Go chaincode lean and fast.",
    "Focus on words like 'Asynchronous,' 'Message Queue,' and 'Spatial Indexing.' This proves you are an enterprise architect, not just a data scientist."
)

# =====================================================================
# SLIDE 5: ROUND 4 (FUNDER / WHY YOU)
# =====================================================================
add_qa_slide(
    4, "EU Funder (Competition)",
    "There are European AI companies and NGOs using drones. Why should we fund TraceRight-SPROUT instead of them?",
    "â€¢ Satellites vs. Drones: Drones cost too much to scale. Sentinel-1/2/GEDI satellite data allows us to map 1.5M farmers instantly with near-zero marginal cost.\nâ€¢ African Context: We are built for fragmented smallholders, offline-first mobile, and ECTMS integration.\nâ€¢ Financial Engine: Competitors just show a map. We extract the carbon, hash to Fabric, and trigger smart-contract payouts.\nâ€¢ TRL 7: We didn't bring a PowerPoint. We brought a live API, a cloud dashboard, and open-source code. The technical risk is gone.",
    "Do not insult the competitors. Respect them, but clearly draw the line between their high-cost/high-connectivity models and your scalable, Africa-first model."
)

# Save the presentation
out_path = r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Consortium_QA_Playbook.pptx'
prs.save(out_path)
print(f"Q&A Playbook successfully saved to {out_path}")