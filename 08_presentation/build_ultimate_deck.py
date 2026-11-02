from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
import os

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

def add_title_slide(title, subtitle):
    slide = prs.slides.add_slide(blank_slide_layout)
    bg = slide.shapes.add_shape(1, 0, 0, prs.slide_width, prs.slide_height)
    bg.fill.solid()
    bg.fill.fore_color.rgb = GREEN
    bg.line.color.rgb = GREEN
    
    tb = slide.shapes.add_textbox(Inches(1), Inches(2.5), Inches(11), Inches(2))
    p = tb.text_frame.add_paragraph()
    p.text = title
    p.font.size = Pt(48)
    p.font.bold = True
    p.font.color.rgb = LIGHT_BG
    p.alignment = PP_ALIGN.CENTER
    p.font.name = 'Calibri'
    
    sb = slide.shapes.add_textbox(Inches(1), Inches(4), Inches(11), Inches(1))
    p = sb.text_frame.add_paragraph()
    p.text = subtitle
    p.font.size = Pt(24)
    p.font.color.rgb = TEAL
    p.alignment = PP_ALIGN.CENTER
    p.font.name = 'Calibri'

def add_image_slide(title, subtitle, img_name, is_full_width=False):
    slide = prs.slides.add_slide(blank_slide_layout)
    
    # Title
    tb = slide.shapes.add_textbox(Inches(0.5), Inches(0.3), Inches(12), Inches(0.8))
    p = tb.text_frame.add_paragraph()
    p.text = title
    p.font.size = Pt(32)
    p.font.bold = True
    p.font.color.rgb = GREEN
    p.font.name = 'Calibri'
    
    if subtitle:
        sb = slide.shapes.add_textbox(Inches(0.5), Inches(1.0), Inches(12), Inches(0.5))
        p = sb.text_frame.add_paragraph()
        p.text = subtitle
        p.font.size = Pt(18)
        p.font.color.rgb = TEAL
        p.font.name = 'Calibri'
    
    # Image
    img_path = os.path.join(r'C:\SPROUT-Qonnect\08_presentation\figures', img_name)
    if os.path.exists(img_path):
        if is_full_width:
            slide.shapes.add_picture(img_path, Inches(0.5), Inches(1.6), width=Inches(12.3))
        else:
            slide.shapes.add_picture(img_path, Inches(1.5), Inches(1.6), width=Inches(10.3))
    else:
        print(f"WARNING: {img_name} not found.")

def add_two_image_slide(title, img_name_1, img_name_2):
    slide = prs.slides.add_slide(blank_slide_layout)
    tb = slide.shapes.add_textbox(Inches(0.5), Inches(0.3), Inches(12), Inches(0.8))
    p = tb.text_frame.add_paragraph()
    p.text = title
    p.font.size = Pt(32)
    p.font.bold = True
    p.font.color.rgb = GREEN
    p.font.name = 'Calibri'
    
    img1 = os.path.join(r'C:\SPROUT-Qonnect\08_presentation\figures', img_name_1)
    img2 = os.path.join(r'C:\SPROUT-Qonnect\08_presentation\figures', img_name_2)
    if os.path.exists(img1) and os.path.exists(img2):
        slide.shapes.add_picture(img1, Inches(0.5), Inches(1.6), width=Inches(6.0))
        slide.shapes.add_picture(img2, Inches(6.8), Inches(1.6), width=Inches(6.0))
    else:
        print(f"WARNING: Missing images for {title}")

# =====================================================================
# CORE PITCH (10-12 Slides)
# =====================================================================
add_title_slide("TraceRight-SPROUT Consortium", "End-to-End Digital MRV and EUDR-Compliant Traceability")

add_image_slide("The $3 Billion Compliance Gap", "EUDR 2026 Risk to African Exports", "fig1_eudr_risk.png", True)

add_image_slide("The Solution: 4-Layer Architecture", "Satellite to Blockchain", "ssl_fusion_map.png")

add_image_slide("EUDR Gatekeeping: Deforestation Risk", "AI detects non-compliance before it hits the ledger", "deforestation_risk_map.png")

add_image_slide("Live Demo: Valid vs Rejected Plots", "Real-time spatial verification", "realistic_satellite_map.png")

add_image_slide("Business Model: The 5 Pillars", "Driving Revenue and Impact", "insurance_payout_zones.png")

add_image_slide("Carbon Finance & Tokenization", "AGB estimation for tCO2 Tokens", "carbon_heatmap.png")

add_image_slide("Financial ROI for Funders", "Carbon Value: $2.25M / year potential", "fund_winning_carbon_value.png")

add_image_slide("Socio-Economic Impact", "70% Revenue Share to 50,000 Farmers", "fund_winning_socio_economic.png")

add_image_slide("Pan-African Expansion", "Scaling beyond Ethiopia", "africa_scale_map.png")

add_image_slide("Accelerated Roadmap", "Phase 1 to Phase 3", "fig3_roadmap.png", True)

add_title_slide("The Ask", "Ready to Integrate. Ready to Scale.")

# =====================================================================
# APPENDIX: DEEP TECH & SSL (Q&A Reference)
# =====================================================================
add_title_slide("Appendix: Technical Deep Dive", "Available for Q&A Review")

add_image_slide("EUDR Change Detection (2020 vs 2024)", "Time-series forest canopy analysis", "change_detection_map.png")

add_image_slide("Ecological Zonation", "Topographic classification (Wurch to Bereha)", "ecological_zones_map.png")

add_image_slide("SSL Anomaly Detection (Reconstruction Error)", "Self-Supervised Learning for Pest/Disease detection", "ssl_anomaly_map.png")

add_two_image_slide("Crop Insurance: Soil & Hail Damage", "insurance_soil_moisture.png", "ssl_hail_damage.png")

add_two_image_slide("Crop Insurance: Flood & Yield Prediction", "ssl_flood_footprint.png", "ssl_yield_prediction.png")

add_two_image_slide("SSL Temporal & Phenology Features", "ssl_temporal_similarity.png", "ssl_phenology.png")

add_two_image_slide("Advanced SSL Clustering & SOC", "ssl_clustering.png", "ssl_soc_proxy.png")

add_image_slide("Crop Insurance: Time Series Monitoring", "June to August NDVI Degradation", "insurance_time_series.png")

add_image_slide("Climate Resilience & Risk", "Parametric Insurance Shield", "fund_winning_climate_risk.png")

add_two_image_slide("AI Confidence & Impact Projections", "ssl_payout_confidence.png", "fig2_impact.png")

out_path = r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_ULTIMATE_26MAPS.pptx'
prs.save(out_path)
print(f"ULTIMATE 26-Map Presentation successfully built at: {out_path}")