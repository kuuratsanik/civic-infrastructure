# Open All Setup URLs - Quick Account Creation
# This opens all necessary websites in your browser

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OPENING ACCOUNT CREATION PAGES" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Opening essential accounts..." -ForegroundColor Green
Write-Host ""

# Priority 1 - Essential accounts
Write-Host "1. GitHub (code hosting)..." -ForegroundColor Cyan
Start-Process "https://github.com/signup"
Start-Sleep -Seconds 2

Write-Host "2. Vercel (website hosting)..." -ForegroundColor Cyan
Start-Process "https://vercel.com/signup"
Start-Sleep -Seconds 2

Write-Host "3. Netlify (website hosting)..." -ForegroundColor Cyan
Start-Process "https://app.netlify.com/signup"
Start-Sleep -Seconds 2

Write-Host "4. npm (package publishing)..." -ForegroundColor Cyan
Start-Process "https://www.npmjs.com/signup"
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  BROWSER TABS OPENED" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Create accounts in this order:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. GitHub - Create account (2 min)" -ForegroundColor White
Write-Host "   - Choose username carefully (will be public)" -ForegroundColor Gray
Write-Host "   - Suggestion: svenk-ai or autonomous-ai" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Vercel - Click 'Continue with GitHub' (30 sec)" -ForegroundColor White
Write-Host "   - Uses your GitHub account" -ForegroundColor Gray
Write-Host "   - Instant setup" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Netlify - Click 'Sign up with GitHub' (30 sec)" -ForegroundColor White
Write-Host "   - Uses your GitHub account" -ForegroundColor Gray
Write-Host "   - Instant setup" -ForegroundColor Gray
Write-Host ""
Write-Host "4. npm - Create account (2 min)" -ForegroundColor White
Write-Host "   - Use same username as GitHub" -ForegroundColor Gray
Write-Host "   - Verify email" -ForegroundColor Gray
Write-Host ""
Write-Host "Total time: 5 minutes" -ForegroundColor Green
Write-Host "Total cost: `$0" -ForegroundColor Green
Write-Host ""
Write-Host "After accounts are ready, run:" -ForegroundColor Yellow
Write-Host "  .\Upload-To-GitHub.ps1" -ForegroundColor Cyan
Write-Host ""
