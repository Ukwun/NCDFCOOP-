#!/bin/bash
# Setup script for real-time sync components
# Run: bash scripts/setup_realtime.sh

set -e

echo "🚀 Setting up Real-Time Sync Components"
echo "========================================"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${BLUE}✓ Checking prerequisites...${NC}"

if ! command -v firebase &> /dev/null; then
    echo -e "${YELLOW}⚠ Firebase CLI not found. Installing...${NC}"
    npm install -g firebase-tools
fi

if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}⚠ Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi

# Step 1: Install dependencies
echo -e "\n${BLUE}Step 1: Installing Node dependencies...${NC}"
npm install

# Step 2: Deploy Cloud Functions
echo -e "\n${BLUE}Step 2: Deploying Cloud Functions...${NC}"
read -p "Deploy functions to Firebase? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd functions || exit 1
    npm install
    firebase deploy --only functions
    cd ..
    echo -e "${GREEN}✓ Functions deployed${NC}"
else
    echo -e "${YELLOW}⊘ Skipped function deployment${NC}"
fi

# Step 3: Verify Flutter dependencies
echo -e "\n${BLUE}Step 3: Verifying Flutter dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✓ Flutter dependencies installed${NC}"

# Step 4: Create test data (optional)
echo -e "\n${BLUE}Step 4: Setup test data${NC}"
read -p "Create load test data in Firestore? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    node scripts/setup_test_data.js
    echo -e "${GREEN}✓ Test data created${NC}"
else
    echo -e "${YELLOW}⊘ Skipped test data creation${NC}"
fi

# Step 5: Configuration
echo -e "\n${BLUE}Step 5: Configuration${NC}"
cat > .env.local <<EOF
# Real-Time Sync Configuration
FIREBASE_PROJECT_ID=$(firebase projects:list | head -2 | tail -1 | awk '{print $1}')
LOAD_TEST_CONCURRENT_USERS=100
LOAD_TEST_DURATION_MINUTES=5
LOAD_TEST_UPDATE_INTERVAL_MS=2000
EOF

echo -e "${GREEN}✓ Configuration created (.env.local)${NC}"

# Final summary
echo -e "\n${GREEN}✅ Setup Complete!${NC}"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Run the app:        flutter run"
echo "2. Test load testing:  npm run load-test"
echo "3. View functions log: firebase functions:log"
echo "4. Read guide:         cat docs/LOAD_TESTING_GUIDE.md"
echo ""
echo "For more info, see: REALTIME_SYNC_COMPLETE.md"
