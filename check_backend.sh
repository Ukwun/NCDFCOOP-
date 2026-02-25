#!/bin/bash
#
# BACKEND DETECTION & INTEGRATION GUIDE
# Run this script to detect which backends are available
#

echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║        BACKEND DETECTION TOOL - COOP COMMERCE                        ║"
echo "║        Checks which API servers are running and accessible            ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check_backend() {
    local name=$1
    local url=$2
    local timeout=$3
    
    echo -n "Checking $name at $url... "
    
    # Try to hit the health endpoint
    if curl -s -m $timeout "$url/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ HEALTHY${NC}"
        return 0
    else
        echo -e "${RED}❌ UNAVAILABLE${NC}"
        return 1
    fi
}

check_endpoint() {
    local name=$1
    local url=$2
    local endpoint=$3
    
    echo -n "  → Checking endpoint $endpoint... "
    
    if curl -s -I "$url$endpoint" 2>/dev/null | grep -q "200\|201\|400"; then
        echo -e "${GREEN}✅ EXISTS${NC}"
        return 0
    else
        echo -e "${RED}❌ NOT FOUND${NC}"
        return 1
    fi
}

echo -e "${BLUE}Phase 1: Auto-Detection${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

LOCAL_OK=0
EMULATOR_OK=0
PRODUCTION_OK=0
FIREBASE_OK=0

# Check local backend
check_backend "Local Backend" "http://localhost:3000" 3
[ $? -eq 0 ] && LOCAL_OK=1

# Check Android emulator backend
check_backend "Emulator Backend" "http://10.0.2.2:3000" 3
[ $? -eq 0 ] && EMULATOR_OK=1

# Check production backend
check_backend "Production Backend" "https://api.ncdfcoop.ng" 5
[ $? -eq 0 ] && PRODUCTION_OK=1

# Check Firebase Cloud Functions
check_backend "Firebase Cloud Functions" "https://us-central1-coop-commerce.cloudfunctions.net" 5
[ $? -eq 0 ] && FIREBASE_OK=1

echo ""
echo -e "${BLUE}Phase 2: Endpoint Verification${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $LOCAL_OK -eq 1 ]; then
    echo "✅ Local Backend Found - Checking endpoints..."
    check_endpoint "Local" "http://localhost:3000" "/api/auth/login"
    check_endpoint "Local" "http://localhost:3000" "/api/auth/register"
    check_endpoint "Local" "http://localhost:3000" "/api/auth/google"
    echo ""
elif [ $EMULATOR_OK -eq 1 ]; then
    echo "✅ Emulator Backend Found - Checking endpoints..."
    check_endpoint "Emulator" "http://10.0.2.2:3000" "/api/auth/login"
    check_endpoint "Emulator" "http://10.0.2.2:3000" "/api/auth/register"
    echo ""
elif [ $PRODUCTION_OK -eq 1 ]; then
    echo "✅ Production Backend Found - Checking endpoints..."
    check_endpoint "Production" "https://api.ncdfcoop.ng" "/api/auth/login"
    check_endpoint "Production" "https://api.ncdfcoop.ng" "/api/auth/register"
    echo ""
elif [ $FIREBASE_OK -eq 1 ]; then
    echo "✅ Firebase Cloud Functions Found"
    echo ""
fi

echo ""
echo -e "${BLUE}Phase 3: Diagnosis${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $LOCAL_OK -eq 1 ] || [ $EMULATOR_OK -eq 1 ] || [ $PRODUCTION_OK -eq 1 ] || [ $FIREBASE_OK -eq 1 ]; then
    echo -e "${GREEN}✅ BACKEND DETECTED${NC}"
    echo ""
    echo "Your app will automatically:"
    echo "  • Connect to the available backend"
    echo "  • Use real authentication endpoints"
    echo "  • Fall back to mock data if endpoints fail"
    echo ""
    echo "Next Steps:"
    echo "  1. Update API configuration if needed in lib/core/api/api_config.dart"
    echo "  2. Run the app: flutter run"
    echo "  3. Test authentication flow"
    echo ""
else
    echo -e "${YELLOW}⚠️  NO REAL BACKEND DETECTED${NC}"
    echo ""
    echo "Your app is configured to use MOCK authentication."
    echo ""
    echo "To enable real backend, you need to:"
    echo ""
    echo "Option A: Start a local backend"
    echo "  • Make sure Node.js backend is running on http://localhost:3000"
    echo "  • Or on http://10.0.2.2:3000 for Android emulator"
    echo "  • Backend must have /api/auth/* endpoints"
    echo ""
    echo "Option B: Deploy to production"
    echo "  • Update API_URL to your production server"
    echo "  • Configure endpoints in lib/core/api/api_config.dart"
    echo ""
    echo "Option C: Use Firebase Cloud Functions"
    echo "  • Deploy Cloud Functions for authentication"
    echo "  • Update FIREBASE_URL in api_config.dart"
    echo ""
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo "For more info, see README_BACKEND_INTEGRATION.md"
echo ""
