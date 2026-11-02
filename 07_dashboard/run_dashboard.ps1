# Launch the TraceRight Consortium Portal
$env:PYTHONPATH = 'C:\SPROUT-Qonnect\03_api'
Write-Host "Starting TraceRight Dashboard..." -ForegroundColor Cyan
Write-Host "Open: http://127.0.0.1:8501" -ForegroundColor Green
streamlit run C:\SPROUT-Qonnect\07_dashboard\app.py