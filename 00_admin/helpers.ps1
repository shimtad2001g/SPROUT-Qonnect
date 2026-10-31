function New-StepScript {
    param([string]$Name)
    $path = "C:\SPROUT-Qonnect\$Name.ps1"
    New-Item -Path $path -Force -ItemType File | Out-Null
    notepad $path
    Write-Host ""
    Write-Host "When Notepad closes, run:" -ForegroundColor Cyan
    Write-Host "  powershell -ExecutionPolicy Bypass -File `"$path`"" -ForegroundColor Cyan
}