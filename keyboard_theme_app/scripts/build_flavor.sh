#!/bin/bash

# Flutter Multi-Brand Build Script
# This script builds different flavors of the wallpaper app

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored message
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Print usage
usage() {
    echo "Usage: $0 <flavor> [build_type]"
    echo ""
    echo "Flavors:"
    echo "  kedehun         - K-POP DEMON HUNTERS WALLPAPER"
    echo "  aespa_winter    - Aespa Winter Wallpaper"
    echo "  aespa_karina    - Aespa Karina Wallpaper"
    echo ""
    echo "Build Types:"
    echo "  apk            - Build APK (default)"
    echo "  appbundle      - Build App Bundle (for Play Store)"
    echo "  debug          - Build debug APK"
    echo ""
    echo "Examples:"
    echo "  $0 kedehun apk"
    echo "  $0 aespa_winter appbundle"
    exit 1
}

# Check if flavor is provided
if [ -z "$1" ]; then
    print_message "$RED" "Error: Flavor not specified"
    usage
fi

FLAVOR=$1
BUILD_TYPE=${2:-apk}

# Validate flavor
case $FLAVOR in
    kedehun|aespa_winter|aespa_karina)
        print_message "$GREEN" "Building flavor: $FLAVOR"
        ;;
    *)
        print_message "$RED" "Error: Invalid flavor '$FLAVOR'"
        usage
        ;;
esac

# Map underscores to camelCase for Gradle
GRADLE_FLAVOR=$(echo "$FLAVOR" | sed -E 's/_([a-z])/\U\1/g')

print_message "$YELLOW" "Step 1: Cleaning previous builds..."
flutter clean

print_message "$YELLOW" "Step 2: Getting dependencies..."
flutter pub get

print_message "$YELLOW" "Step 3: Building $BUILD_TYPE for $FLAVOR..."

case $BUILD_TYPE in
    apk)
        flutter build apk \
            --release \
            --flavor "$GRADLE_FLAVOR" \
            --dart-define=FLAVOR="$FLAVOR"
        OUTPUT_PATH="build/app/outputs/flutter-apk/app-${GRADLE_FLAVOR}-release.apk"
        ;;
    appbundle)
        flutter build appbundle \
            --release \
            --flavor "$GRADLE_FLAVOR" \
            --dart-define=FLAVOR="$FLAVOR"
        OUTPUT_PATH="build/app/outputs/bundle/${GRADLE_FLAVOR}Release/app-${GRADLE_FLAVOR}-release.aab"
        ;;
    debug)
        flutter build apk \
            --debug \
            --flavor "$GRADLE_FLAVOR" \
            --dart-define=FLAVOR="$FLAVOR"
        OUTPUT_PATH="build/app/outputs/flutter-apk/app-${GRADLE_FLAVOR}-debug.apk"
        ;;
    *)
        print_message "$RED" "Error: Invalid build type '$BUILD_TYPE'"
        usage
        ;;
esac

if [ -f "$OUTPUT_PATH" ]; then
    print_message "$GREEN" "✓ Build successful!"
    print_message "$GREEN" "Output: $OUTPUT_PATH"

    # Show file size
    SIZE=$(du -h "$OUTPUT_PATH" | cut -f1)
    print_message "$GREEN" "Size: $SIZE"
else
    print_message "$RED" "✗ Build failed - output file not found"
    exit 1
fi
