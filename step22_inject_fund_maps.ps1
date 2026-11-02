# =====================================================================
# TraceRight-SPROUT | Step 22: Inject Fund-Winning Maps into Slides 7 & 11
# =====================================================================
$ErrorActionPreference = 'Continue'
$ROOT = 'C:\SPROUT-Qonnect'
$DASH = Join-Path $ROOT '08_presentation'

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

Write-Host "=== INJECTING FUND-WINNING MAPS ===" -ForegroundColor Cyan

$pyScript = @'
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE_TYPE

# Load the final MASTER presentation
path = r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_MASTER_FINAL.pptx'
prs = Presentation(path)

# Colors
LIGHT_BG = RGBColor(248, 249, 250)

# =====================================================================
# SLIDE 7: SOCIO-ECONOMIC IMPACT
# =====================================================================
slide7 = prs.slides[6]

# 1. Remove existing text boxes (except titles)
for i in range(len(slide7.shapes) - 1, -1, -1):
    shape = slide7.shapes[i]
    if shape.has_text_frame:
        if "Theory of Change" in shape.text_frame.text or "Measurable" in shape.text_frame.text:
            continue
    sp = shape._element
    sp.getparent().remove(sp)

# 2. Add the Socio-Economic Map
img_se = r'C:\SPROUT-Qonnect\08_presentation\figures\fund_winning_socio_economic.png'
slide7.shapes.add_picture(img_se, Inches(1.5), Inches(2.2), width=Inches(10.3))

# =====================================================================
# SLIDE 11: CARBON VALUE (THANK YOU)
# =====================================================================
slide11 = prs.slides[10]

# 1. Resize the text boxes to make room for the map on the right
for shape in slide11.shapes:
    if shape.has_text_frame:
        if "Thank You" in shape.text_frame.text:
            shape.left = Inches(0.5)
            shape.width = Inches(5)
            shape.text_frame.paragraphs[0].alignment = 0 # Left align
        if "Questions &" in shape.text_frame.text:
            shape.left = Inches(0.5)
            shape.width = Inches(5)
            shape.text_frame.paragraphs[0].alignment = 0 # Left align
        if "Live Dashboard" in shape.text_frame.text or "GitHub" in shape.text_frame.text:
            shape.left = Inches(0.5)
            shape.width = Inches(5)
            shape.text_frame.paragraphs[0].alignment = 0 # Left align

# 2. Add the Carbon Value Map on the right side
img_carbon = r'C:\SPROUT-Qonnect\08_presentation\figures\fund_winning_carbon_value.png'
# Add a white border around the image for contrast
pic = slide11.shapes.add_picture(img_carbon, Inches(5.8), Inches(1.2), width=Inches(7))
pic.line.color.rgb = LIGHT_BG
pic.line.width = Pt(2)

# Save the updated presentation
prs.save(path)
print("Fund-Winning Maps injected into Slides 7 and 11.")
'@

Write-Utf8NoBom -Path (Join-Path $DASH 'inject_fund_maps.py') -Text $pyScript

Write-Host "`n=== RUNNING INJECTION ===" -ForegroundColor Cyan
Push-Location $DASH
python inject_fund_maps.py
Pop-Location

Write-Host "`n=== OPENING POWERPOINT ===" -ForegroundColor Cyan
Invoke-Item (Join-Path $DASH 'TraceRight_Proposal_MASTER_FINAL.pptx')

Write-Host "`n=== COMPLETE ===" -ForegroundColor Green