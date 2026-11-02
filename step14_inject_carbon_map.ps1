# =====================================================================
# TraceRight-SPROUT | Step 14: Inject Carbon Map into Slide 6
# =====================================================================
$ErrorActionPreference = 'Continue'
$ROOT = 'C:\SPROUT-Qonnect'
$DASH = Join-Path $ROOT '08_presentation'

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

Write-Host "=== INJECTING CARBON MAP ===" -ForegroundColor Cyan

$pyScript = @'
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor

# Load the latest MASTER presentation
path = r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_MASTER_FINAL.pptx'
prs = Presentation(path)

# Slide 6 is index 5 (Business Model)
slide6 = prs.slides[5]

# Colors
GREEN = RGBColor(27, 67, 50)      
TEAL = RGBColor(42, 157, 143)     
DARK = RGBColor(33, 37, 41)       

# 1. Clear the old 5 pillars text boxes and replace with a tighter list
for i in range(len(slide6.shapes) - 1, -1, -1):
    shape = slide6.shapes[i]
    if shape.has_text_frame:
        if "Business Model" in shape.text_frame.text or "5-Pillar" in shape.text_frame.text:
            continue # Keep the title
    sp = shape._element
    sp.getparent().remove(sp)

# 2. Add the 5 Pillars on the Left
pillars = [
    ("1. EUDR Traceability", "Geolocation & compliance"),
    ("2. Climate Finance", "Bankable green credit"),
    ("3. Crop Insurance", "Satellite triggers"),
    ("4. Carbon Trade", "tCO2 tokens via Verra"),
    ("5. E-commerce", "Direct farmer-to-buyer")
]

y_pos = 2.2
for title, desc in pillars:
    box = slide6.shapes.add_textbox(Inches(0.5), Inches(y_pos), Inches(5.5), Inches(0.8))
    tf = box.text_frame
    p = tf.add_paragraph()
    p.text = title
    p.font.bold = True
    p.font.size = Pt(20)
    p.font.color.rgb = GREEN
    p.font.name = 'Calibri'
    
    p2 = tf.add_paragraph()
    p2.text = desc
    p2.font.size = Pt(14)
    p2.font.color.rgb = TEAL
    p2.font.name = 'Calibri'
    y_pos += 1.1

# 3. Add the Carbon Map on the Right
img_path = r'C:\SPROUT-Qonnect\08_presentation\figures\carbon_heatmap.png'
# (X: 6.5 inches, Y: 2.2 inches, Width: 6.2 inches)
slide6.shapes.add_picture(img_path, Inches(6.2), Inches(2.2), width=Inches(6.5))

# Save to the Master file
out_path = r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_MASTER_FINAL.pptx'
prs.save(out_path)
print("Carbon Map injected into Slide 6.")
'@

Write-Utf8NoBom -Path (Join-Path $DASH 'inject_carbon_slide6.py') -Text $pyScript

Write-Host "`n=== RUNNING INJECTION ===" -ForegroundColor Cyan
Push-Location $DASH
python inject_carbon_slide6.py
Pop-Location

Write-Host "`n=== OPENING POWERPOINT ===" -ForegroundColor Cyan
Invoke-Item (Join-Path $DASH 'TraceRight_Proposal_MASTER_FINAL.pptx')

Write-Host "`n=== COMPLETE ===" -ForegroundColor Green