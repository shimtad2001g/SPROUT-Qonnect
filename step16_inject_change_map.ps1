# =====================================================================
# TraceRight-SPROUT | Step 16: Inject Change Detection Map into Slide 3
# =====================================================================
$ErrorActionPreference = 'Continue'
$ROOT = 'C:\SPROUT-Qonnect'
$DASH = Join-Path $ROOT '08_presentation'

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

Write-Host "=== INJECTING CHANGE DETECTION MAP ===" -ForegroundColor Cyan

$pyScript = @'
from pptx import Presentation
from pptx.util import Inches
from pptx.enum.shapes import MSO_SHAPE_TYPE

# Load the MASTER presentation
path = r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_MASTER_FINAL.pptx'
prs = Presentation(path)

# Slide 3 is index 2 (Architecture)
slide3 = prs.slides[2]

# 1. Remove the existing map from the right side
for i in range(len(slide3.shapes) - 1, -1, -1):
    shape = slide3.shapes[i]
    if shape.shape_type == MSO_SHAPE_TYPE.PICTURE:
        sp = shape._element
        sp.getparent().remove(sp)
        break

# 2. Add the new Change Detection Map
img_path = r'C:\SPROUT-Qonnect\08_presentation\figures\change_detection_map.png'
# (Left, Top, Width) - Placing it on the right side
slide3.shapes.add_picture(img_path, Inches(6.3), Inches(2.2), width=Inches(6.4))

# Save the updated presentation
prs.save(path)
print("Change Detection Map injected into Slide 3.")
'@

Write-Utf8NoBom -Path (Join-Path $DASH 'inject_change_slide3.py') -Text $pyScript

Write-Host "`n=== RUNNING INJECTION ===" -ForegroundColor Cyan
Push-Location $DASH
python inject_change_slide3.py
Pop-Location

Write-Host "`n=== OPENING POWERPOINT ===" -ForegroundColor Cyan
Invoke-Item (Join-Path $DASH 'TraceRight_Proposal_MASTER_FINAL.pptx')

Write-Host "`n=== COMPLETE ===" -ForegroundColor Green