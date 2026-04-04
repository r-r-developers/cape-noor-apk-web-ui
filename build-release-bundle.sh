#!/bin/bash
# build-release-bundle.sh - Build signed app bundle for Google Play Store

set -e

PROJECT_DIR="/development/side-projects/salaah-time-fast-duah/flutter"
KEY_STORE_PATH="$HOME/cape-noor-release-key.jks"
OUTPUT_DIR="$PROJECT_DIR/build/app/outputs/bundle/release"
KEY_PROPERTIES_FILE="$PROJECT_DIR/android/key.properties"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Cape Noor - Google Play Store Bundle Builder${NC}"
echo "=================================================="

# Check signing config
if [ ! -f "$KEY_PROPERTIES_FILE" ]; then
    if [[ -n "$CAPE_NOOR_STORE_FILE" && -n "$CAPE_NOOR_STORE_PASSWORD" && -n "$CAPE_NOOR_KEY_ALIAS" && -n "$CAPE_NOOR_KEY_PASSWORD" ]]; then
        cat > "$KEY_PROPERTIES_FILE" << EOF
storePassword=$CAPE_NOOR_STORE_PASSWORD
keyPassword=$CAPE_NOOR_KEY_PASSWORD
keyAlias=$CAPE_NOOR_KEY_ALIAS
storeFile=$CAPE_NOOR_STORE_FILE
EOF
        echo -e "${GREEN}✓ Created android/key.properties from environment variables${NC}"
    fi
fi

if [ ! -f "$KEY_PROPERTIES_FILE" ]; then
    echo -e "${RED}ERROR: Missing $KEY_PROPERTIES_FILE${NC}"
    echo ""
    echo "Fix one of these ways:"
    echo "  1) Create android/key.properties from android/key.properties.example"
    echo "  2) Export env vars before running this script:"
    echo "     CAPE_NOOR_STORE_FILE"
    echo "     CAPE_NOOR_STORE_PASSWORD"
    echo "     CAPE_NOOR_KEY_ALIAS"
    echo "     CAPE_NOOR_KEY_PASSWORD"
    echo ""
    exit 1
fi

# Set environment variables
export PATH="/opt/flutter/bin:/usr/lib/android-sdk/platform-tools:$PATH"
export ANDROID_SDK_ROOT=/usr/lib/android-sdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

echo -e "${GREEN}✓ Environment configured${NC}"
echo "  Project: $PROJECT_DIR"
echo "  key.properties: $KEY_PROPERTIES_FILE"
echo ""

# Navigate to project
cd "$PROJECT_DIR"

# Build the app bundle
echo -e "${YELLOW}Building app bundle...${NC}"
flutter build appbundle --release --no-pub

# Check if build succeeded
if [ -f "$OUTPUT_DIR/app-release.aab" ]; then
    SIZE=$(du -h "$OUTPUT_DIR/app-release.aab" | cut -f1)
    echo ""
    echo -e "${GREEN}✓ Build successful!${NC}"
    echo ""
    echo "Bundle location:"
    echo "  $OUTPUT_DIR/app-release.aab"
    echo ""
    echo "Bundle size: $SIZE"
    echo ""
    echo "Next steps:"
    echo "  1. Go to https://play.google.com/console"
    echo "  2. Select 'Cape Noor' app"
    echo "  3. Release → Production → Create new release"
    echo "  4. Upload app-release.aab"
    echo "  5. Add release notes and submit"
    echo ""
else
    echo -e "${RED}✗ Build failed!${NC}"
    exit 1
fi
