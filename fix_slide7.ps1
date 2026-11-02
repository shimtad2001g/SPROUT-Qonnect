# =====================================================================
# TraceRight-SPROUT | Fix Slide 7 Overlap (Clean Sweep)
# =====================================================================
$ErrorActionPreference = 'Continue'
$ROOT = 'C:\SPROUT-Qonnect'
$DASH = Join-Path $ROOT '08_presentation'

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

Write-Host "=== FIXING SLIDE 7 ===" -ForegroundColor Cyan

$pyScript = @'
from pptx import Presentation
from pptx.enum.shapes import MSO_SHAPE_TYPE

path = r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_FINAL_FIXED.pptx'
prs = Presentation(path)

# Slide 7 is index 6
slide7 = prs.slides[6]

# Iterate backwards to safely remove items while iterating
for i in range(len(slide7.shapes) - 1, -1, -1):
    shape = slide7.shapes[i]
    
    # Keep the Picture (the chart)
    if shape.shape_type == MSO_SHAPE_TYPE.PICTURE:
        continue
        
    # Keep the Title and Subtitle text
    if shape.has_text_frame:
        text = shape.text_frame.text
        if "Theory of Change" in text or "Measurable Impact" in text:
            continue
            
    # Delete everything else (the old text boxes and empty borders)
    sp = shape._element
    sp.getparent().remove(sp)

prs.save(path)
print("Slide 7 cleaned. Overlapping boxes removed.")
'@

Write-Utf8NoBom -Path (Join-Path $DASH 'fix_slide7.py') -Text $pyScript

Write-Host "`n=== RUNNING FIX ===" -ForegroundColor Cyan
Push-Location $DASH
python fix_slide7.py
Pop-Location

Write-Host "`n=== FIX COMPLETE ===" -ForegroundColor Green