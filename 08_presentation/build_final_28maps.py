from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from PIL import Image
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

def add_smart_picture(slide, img_name, left_in, top_in, max_w_in, max_h_in):
    img_path = os.path.join(r'C:\SPROUT-Qonnect\08_presentation\figures', img_name)
    if not os.path.exists(img_path):
        print(f"WARNING: {img_name} not found.")
        return
    img = Image.open(img_path)
    img_w, img_h = img.size
    aspect = img_w / img_h

    if (max_w_in / max_h_in) > aspect:
        height = Inches(max_h_in)
        width = Inches(max_h_in * aspect)
    else:
        width = Inches(max_w_in)
        height = Inches(max_w_in / aspect)

    left = Inches(left_in) + (Inches(max_w_in) - width) / 2
    top = Inches(top_in) + (Inches(max_h_in) - height) / 2

    slide.shapes.add_picture(img_path, left, top, width=width, height=height)

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
    
    sb = slide.shapes.add_textbox(Inches(1), Inches(4), Inches(11), Inches(1))
    p = sb.text_frame.add_paragraph()
    p.text = subtitle
    p.font.size = Pt(24)
    p.font.color.rgb = TEAL
    p.alignment = PP_ALIGN.CENTER

def add_image_slide(title, subtitle, img_name):
    slide = prs.slides.add_slide(blank_slide_layout)
    tb = slide.shapes.add_textbox(Inches(0.5), Inches(0.3), Inches(12), Inches(0.8))
    p = tb.text_frame.add_paragraph()
    p.text = title
    p.font.size = Pt(32)
    p.font.bold = True
    p.font.color.rgb = GREEN
    
    if subtitle:
        sb = slide.shapes.add_textbox(Inches(0.5), Inches(1.0), Inches(12), Inches(0.5))
        p = sb.text_frame.add_paragraph()
        p.text = subtitle
        p.font.size = Pt(18)
        p.font.color.rgb = TEAL
    add_smart_picture(slide, img_name, left_in=0.5, top_in=1.6, max_w_in=12.3, max_h_in=5.5)

def add_two_image_slide(title, img_name_1, img_name_2):
    slide = prs.slides.add_slide(blank_slide_layout)
    tb = slide.shapes.add_textbox(Inches(0.5), Inches(0.3), Inches(12), Inches(0.8))
    p = tb.text_frame.add_paragraph()
    p.text = title
    p.font.size = Pt(32)
    p.font.bold = True
    p.font.color.rgb = GREEN
    add_smart_picture(slide, img_name_1, left_in=0.5, top_in=1.6, max_w_in=6.0, max_h_in=5.5)
    add_smart_picture(slide, img_name_2, left_in=6.8, top_in=1.6, max_w_in=6.0, max_h_in=5.5)

# =====================================================================
# CORE PITCH (Slides 1-12)
# =====================================================================
add_title_slide("TraceRight-SPROUT Consortium", "End-to-End Digital MRV and EUDR-Compliant Traceability")
add_image_slide("The $3 Billion Compliance Gap", "EUDR 2026 Risk to African Exports", "fig1_eudr_risk.png")
add_image_slide("The Solution: 4-Layer Architecture", "Satellite to Blockchain", "ssl_fusion_map.png")
add_image_slide("EUDR Gatekeeping: Deforestation Risk", "AI detects non-compliance before it hits the ledger", "deforestation_risk_map.png")
add_image_slide("Live Demo: Valid vs Rejected Plots", "Real-time spatial verification", "realistic_satellite_map.png")
add_image_slide("Business Model: The 5 Pillars", "Driving Revenue and Impact", "insurance_payout_zones.png")
add_image_slide("Carbon Finance & Tokenization", "AGB estimation for tCO2 Tokens", "carbon_heatmap.png")
add_image_slide("Financial ROI for Funders", "Carbon Value: $2.25M / year potential", "fund_winning_carbon_value.png")
add_image_slide("Socio-Economic Impact", "70% Revenue Share to 50,000 Farmers", "fund_winning_socio_economic.png")
add_image_slide("Pan-African Expansion", "Scaling beyond Ethiopia", "africa_scale_map.png")
add_image_slide("Accelerated Roadmap", "Phase 1 to Phase 3", "fig3_roadmap.png")
add_title_slide("The Ask", "Ready to Integrate. Ready to Scale.")

# =====================================================================
# APPENDIX: DEEP TECH, SSL & EUDR (Slides 13-30)
# =====================================================================
add_title_slide("Appendix: Technical Deep Dive", "Available for Q&A Review")

# --- EUDR & Plot Level ---
add_image_slide("EUDR Plot-Level Verification", "Article 9 Compliance & Plot Labels", "plot_label_map.png")
add_image_slide("Qonnect Parcel-Level Mapping", "Farm Subdivision & Land Use", "parcel_level_map.png")
add_image_slide("EUDR Change Detection (2020 vs 2024)", "Time-series forest canopy analysis", "change_detection_map.png")
add_image_slide("Ecological Zonation", "Topographic classification (Wurch to Bereha)", "ecological_zones_map.png")

# --- Deep Learning & Crop Insurance ---
add_image_slide("SSL Anomaly Detection (Reconstruction Error)", "Self-Supervised Learning for Pest/Disease detection", "ssl_anomaly_map.png")
add_two_image_slide("Crop Insurance: Soil & Hail Damage", "insurance_soil_moisture.png", "ssl_hail_damage.png")
add_two_image_slide("Crop Insurance: Flood & Yield Prediction", "ssl_flood_footprint.png", "ssl_yield_prediction.png")
add_two_image_slide("SSL Temporal & Phenology Features", "ssl_temporal_similarity.png", "ssl_phenology.png")
add_two_image_slide("Advanced SSL Clustering & SOC", "ssl_clustering.png", "ssl_soc_proxy.png")
add_image_slide("Crop Insurance: Time Series Monitoring", "June to August NDVI Degradation", "insurance_time_series.png")

# --- Climate & Projections ---
add_image_slide("Climate Resilience & Risk", "Parametric Insurance Shield", "fund_winning_climate_risk.png")
add_two_image_slide("AI Confidence & Impact Projections", "ssl_payout_confidence.png", "fig2_impact.png")

out_path = r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_ULTIMATE_28MAPS.pptx'
prs.save(out_path)
print(f"Final 28-Map Presentation successfully built at: {out_path}")