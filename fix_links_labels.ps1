# =====================================================================
# TraceRight-SPROUT | Fix Invisible Labels on Slide 4
# =====================================================================
$ErrorActionPreference = 'Continue'
$ROOT = 'C:\SPROUT-Qonnect'
$DASH = Join-Path $ROOT '08_presentation'

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

Write-Host "=== FIXING LABELS ===" -ForegroundColor Cyan

$pyScript = @'
from pptx import Presentation
from pptx.util import Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN

path = r'C:\SPROUT-Qonnect\08_presentation\TraceRight_Proposal_FINAL_FIXED.pptx'
prs = Presentation(path)

# Slide 4 is index 3
slide4 = prs.slides[3]

DARK = RGBColor(33, 37, 41)     # Dark Gray/Black for high visibility
BLUE = RGBColor(0, 0, 255)      # Blue for links
TEAL = RGBColor(42, 157, 143)   # Teal for the title

for shape in slide4.shapes:
    if shape.has_text_frame and "LIVE LINKS" in shape.text_frame.text:
        tf = shape.text_frame
        tf.clear() # Clear the broken layout
        
        # 1. Title
        p = tf.paragraphs[0]
        p.text = "LIVE LINKS"
        p.font.size = Pt(22)
        p.font.bold = True
        p.font.color.rgb = TEAL
        p.alignment = PP_ALIGN.CENTER
        
        # 2. Dashboard Label (Now Dark!)
        p2 = tf.add_paragraph()
        p2.text = "\nDashboard:"
        p2.font.size = Pt(14)
        p2.font.color.rgb = DARK 
        p2.alignment = PP_ALIGN.CENTER
        
        # 3. Dashboard URL (Blue)
        p3 = tf.add_paragraph()
        p3.text = "sprout-qonnect-clnhwfubq2y6y9bafzg.streamlit.app"
        p3.font.size = Pt(12)
        p3.font.color.rgb = BLUE
        p3.font.bold = True
        p3.alignment = PP_ALIGN.CENTER
        
        # 4. Codebase Label (Now Dark!)
        p4 = tf.add_paragraph()
        p4.text = "\nCodebase:"
        p4.font.size = Pt(14)
        p4.font.color.rgb = DARK
        p4.alignment = PP_ALIGN.CENTER
        
        # 5. Codebase URL (Blue)
        p5 = tf.add_paragraph()
        p5.text = "github.com/shimtad2001g/SPROUT-Qonnect"
        p5.font.size = Pt(12)
        p5.font.color.rgb = BLUE
        p5.font.bold = True
        p5.alignment = PP_ALIGN.CENTER

prs.save(path)
print("Labels updated to DARK color.")
'@

Write-Utf8NoBom -Path (Join-Path $DASH 'fix_links_labels.py') -Text $pyScript

Write-Host "`n=== RUNNING FIX ===" -ForegroundColor Cyan
Push-Location $DASH
python fix_links_labels.py
Pop-Location

Write-Host "`n=== FIX COMPLETE ===" -ForegroundColor Green