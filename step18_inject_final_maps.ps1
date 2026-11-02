# =====================================================================
# TraceRight-SPROUT | Step 18: Inject Final Maps into Slides 3 & 6
# =====================================================================
$ErrorActionPreference = 'Continue'
$ROOT = 'C:\SPROUT-Qonnect'
$DASH = Join-Path $ROOT '08_presentation'

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

Write-Host "=== INJECTING FINAL MAPS ===" -ForegroundColor Cyan

$pyScript = @'
from pptx import Presentation
from pptx.util import Inches
from pptx.enum.shapes import MSO_SHAPE_TYPE

path = r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_MASTER_FINAL.pptx'
prs = Presentation(path)

# --- Slide 3: Ecological Zones Map ---
slide3 = prs.slides[2]
# Remove the existing right-side map (Change Detection)
for i in range(len(slide3.shapes) - 1, -1, -1):
    shape = slide3.shapes[i]
    if shape.shape_type == MSO_SHAPE_TYPE.PICTURE:
        sp = shape._element
        sp.getparent().remove(sp)
        break
# Add Ecological Zones Map
zones_path = r'C:\SPROUT-Qonnect\08_presentation\figures\ecological_zones_map.png'
slide3.shapes.add_picture(zones_path, Inches(6.3), Inches(2.2), width=Inches(6.4))

# --- Slide 6: Crop Insurance Map ---
slide6 = prs.slides[5]
# Remove the existing right-side map (Carbon Heatmap)
for i in range(len(slide6.shapes) - 1, -1, -1):
    shape = slide6.shapes[i]
    if shape.shape_type == MSO_SHAPE_TYPE.PICTURE:
        sp = shape._element
        sp.getparent().remove(sp)
        break
# Add Crop Insurance Map
insurance_path = r'C:\SPROUT-Qonnect\08_presentation\figures\crop_insurance_map.png'
slide6.shapes.add_picture(insurance_path, Inches(6.2), Inches(2.2), width=Inches(6.5))

prs.save(path)
print("Final maps injected into Slides 3 and 6.")
'@

Write-Utf8NoBom -Path (Join-Path $DASH 'inject_final_two.py') -Text $pyScript

Write-Host "`n=== RUNNING INJECTION ===" -ForegroundColor Cyan
Push-Location $DASH
python inject_final_two.py
Pop-Location

Write-Host "`n=== OPENING POWERPOINT ===" -ForegroundColor Cyan
Invoke-Item (Join-Path $DASH 'TraceRight_Proposal_MASTER_FINAL.pptx')

Write-Host "`n=== COMPLETE ===" -ForegroundColor Green