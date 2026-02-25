#
# BACKEND DETECTION & INTEGRATION TOOL (PowerShell)
# Run: .\check_backend.ps1
#

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   BACKEND DETECTION TOOL - COOP COMMERCE (Windows)" -ForegroundColor Cyan
Write-Host "   Checks which API servers are running" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

function Test-Backend {
    param(
        [string]$Name,
        [string]$Url,
        [int]$TimeoutSeconds = 3
    )
    
    Write-Host -NoNewline "Checking $Name at $Url... "
    
    try {
        $response = Invoke-WebRequest -Uri "$Url/health" -TimeoutSec $TimeoutSeconds -ErrorAction Stop
        Write-Host "[OK] HEALTHY" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[FAIL] UNAVAILABLE" -ForegroundColor Red
        return $false
    }
}

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Endpoint,
        [int]$TimeoutSeconds = 3
    )
    
    Write-Host -NoNewline "  > Checking $Endpoint... "
    
    try {
        $response = Invoke-WebRequest -Uri "$Url$Endpoint" -Method HEAD -TimeoutSec $TimeoutSeconds -ErrorAction Stop
        Write-Host "[OK] EXISTS" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[FAIL] NOT FOUND" -ForegroundColor Red
        return $false
    }
}

Write-Host "Phase 1: Auto-Detection" -ForegroundColor Blue
Write-Host "============================================================" -ForegroundColor Blue
Write-Host ""

$backendFound = $false

# Test local backend
$localOk = Test-Backend "Local Backend" "http://localhost:3000" 3
if ($localOk) { $backendFound = $true }

# Test emulator backend
$emulatorOk = Test-Backend "Emulator Backend" "http://10.0.2.2:3000" 3
if ($emulatorOk) { $backendFound = $true }

# Test production backend
$prodOk = Test-Backend "Production Backend" "https://api.ncdfcoop.ng" 5
if ($prodOk) { $backendFound = $true }

# Test Firebase
$firebaseOk = Test-Backend "Firebase Cloud Functions" "https://us-central1-coop-commerce.cloudfunctions.net" 5
if ($firebaseOk) { $backendFound = $true }

Write-Host ""
Write-Host "Phase 2: Endpoint Verification" -ForegroundColor Blue
Write-Host "============================================================" -ForegroundColor Blue
Write-Host ""

if ($localOk) {
    Write-Host "Local Backend Found - Checking endpoints..." -ForegroundColor Green
    Test-Endpoint "Local" "http://localhost:3000" "/api/auth/login"
    Test-Endpoint "Local" "http://localhost:3000" "/api/auth/register"
    Test-Endpoint "Local" "http://localhost:3000" "/api/auth/google"
}
elseif ($emulatorOk) {
    Write-Host "Emulator Backend Found - Checking endpoints..." -ForegroundColor Green
    Test-Endpoint "Emulator" "http://10.0.2.2:3000" "/api/auth/login"
    Test-Endpoint "Emulator" "http://10.0.2.2:3000" "/api/auth/register"
}
elseif ($prodOk) {
    Write-Host "Production Backend Found - Checking endpoints..." -ForegroundColor Green
    Test-Endpoint "Production" "https://api.ncdfcoop.ng" "/api/auth/login"
    Test-Endpoint "Production" "https://api.ncdfcoop.ng" "/api/auth/register"
}
elseif ($firebaseOk) {
    Write-Host "Firebase Cloud Functions Found" -ForegroundColor Green
}

Write-Host ""
Write-Host "Phase 3: Diagnosis" -ForegroundColor Blue
Write-Host "============================================================" -ForegroundColor Blue
Write-Host ""

if ($backendFound) {
    Write-Host "[OK] BACKEND DETECTED" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your app will automatically:" -ForegroundColor Green
    Write-Host "  • Connect to the available backend"
    Write-Host "  • Use real authentication endpoints"
    Write-Host "  • Fall back to mock data if endpoints fail"
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Update API configuration in lib/core/api/api_config.dart"
    Write-Host "  2. Run the app: flutter run"
    Write-Host "  3. Test authentication (login/register)"
    Write-Host ""
}
else {
    Write-Host "[WARNING] NO REAL BACKEND DETECTED" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Your app is configured to use MOCK authentication."
    Write-Host ""
    Write-Host "To enable real backend, choose one:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Option A: Start Local Backend (Node.js/Python)" -ForegroundColor Yellow
    Write-Host "  cd backend" -ForegroundColor Gray
    Write-Host "  npm install; npm start (or Python equivalent)" -ForegroundColor Gray
    Write-Host "  Will run on http://localhost:3000" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Option B: Use Emulator Backend" -ForegroundColor Yellow
    Write-Host "  Same as Option A, but app will use http://10.0.2.2:3000" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Option C: Deploy to Production" -ForegroundColor Yellow
    Write-Host "  Update API_URL in lib/core/api/api_config.dart" -ForegroundColor Gray
    Write-Host "  Change _productionUrl to https://your-api.com" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Option D: Use Firebase Cloud Functions" -ForegroundColor Yellow
    Write-Host "  Deploy Node.js functions to Firebase" -ForegroundColor Gray
    Write-Host "  Update _firebaseUrl in api_config.dart" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "============================================================" 
Write-Host ""
Write-Host "For detailed setup instructions, see README_BACKEND_INTEGRATION.md" -ForegroundColor Cyan
Write-Host ""
