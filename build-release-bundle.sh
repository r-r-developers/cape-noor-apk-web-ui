#!/bin/bash
# build-release-bundle.sh - Build signed app bundle for Google Play Store

set -e

PROJECT_DIR="/development/side-projects/salaah-time-fast-duah/flutter"
KEY_STORE_PATH="$HOME/cape-noor-release-key.jks"
OUTPUT_DIR="$PROJECT_DIR/build/app/outputs/bundle/release"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Cape Noor - Google Play Store Bundle Builder${NC}"
echo "=================================================="

# Check if key store exists
if [ ! -f "$KEY_STORE_PATH" ]; then
    echo -e "${RED}ERROR: Keystore not found at $KEY_STORE_PATH${NC}"
    echo ""
    echo "To create a keystore, run:"
    echo ""
    echo "keytool -genkey -v -keystore $KEY_STORE_PATH \\"
    echo "  -keyalg RSA -keysize 2048 -validity 10000 \\"
    echo "  -alias cape-noor-key \\"
    echo "  -keypass your_key_password \\"
    echo "  -storepass your_store_password"
    echo ""
    exit 1
fi

# Set environment variables
export PATH="/opt/flutter/bin:/usr/lib/android-sdk/platform-tools:$PATH"
export ANDROID_SDK_ROOT=/usr/lib/android-sdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

echo -e "${GREEN}✓ Environment configured${NC}"
echo "  Project: $PROJECT_DIR"
echo "  Keystore: $KEY_STORE_PATH"
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
