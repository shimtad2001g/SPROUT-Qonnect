# =====================================================================
# TraceRight-SPROUT | Fix Slide 9 Overlap
# =====================================================================
$ErrorActionPreference = 'Continue'
$ROOT = 'C:\SPROUT-Qonnect'
$DASH = Join-Path $ROOT '08_presentation'

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

Write-Host "=== FIXING SLIDE 9 ===" -ForegroundColor Cyan

$pyScript = @'
from pptx import Presentation
from pptx.util import Inches

# Load the MASTER presentation
prs = Presentation(r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_MASTER.pptx')

# Slide 9 is index 8
slide9 = prs.slides[8]

for shape in slide9.shapes:
    if shape.has_text_frame:
        # Find the Left Box (SPROUT Lead)
        if "SPROUT Lead" in shape.text_frame.text:
            shape.width = Inches(5.5) # Give it slightly more width
            shape.text_frame.word_wrap = True
            
        # Find the Right Box (TraceRight Consortium)
        if "TraceRight Consortium" in shape.text_frame.text:
            shape.left = Inches(7) # Keep it on the right
            shape.width = Inches(5.5)
            shape.text_frame.word_wrap = True

# Save as a new FINAL file so we don't break the original MASTER
prs.save(r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_FINAL_FIXED.pptx')
print("Slide 9 fixed and saved as TraceRight_Proposal_FINAL_FIXED.pptx")
'@

Write-Utf8NoBom -Path (Join-Path $DASH 'fix_slide9.py') -Text $pyScript

Write-Host "`n=== RUNNING FIX ===" -ForegroundColor Cyan
Push-Location $DASH
python fix_slide9.py
Pop-Location

Write-Host "`n=== FIX COMPLETE ===" -ForegroundColor Green