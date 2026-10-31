# Launch the SPROUT-Qonnect API on http://127.0.0.1:8000
# Usage: powershell -ExecutionPolicy Bypass -File run_server.ps1
$env:PYTHONPATH = 'C:\SPROUT-Qonnect\03_api'
Write-Host "Starting SPROUT-Qonnect API..." -ForegroundColor Cyan
Write-Host "Docs: http://127.0.0.1:8000/docs" -ForegroundColor Cyan
Write-Host "Health: http://127.0.0.1:8000/v1/health" -ForegroundColor Cyan
Write-Host "Ctrl+C to stop." -ForegroundColor Cyan
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload