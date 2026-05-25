#!/bin/bash

# Build script for ByeByeDPI iOS
# This script compiles byedpi C code for iOS

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BYEDPI_DIR="$PROJECT_DIR/../byedpi"
BUILD_DIR="$PROJECT_DIR/build"
IOS_BUILD_DIR="$BUILD_DIR/ios"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== ByeByeDPI iOS Build Script ===${NC}"

# Check if byedpi source exists
if [ ! -d "$BYEDPI_DIR" ]; then
    echo -e "${YELLOW}byedpi source not found. Cloning from GitHub...${NC}"
    git clone https://github.com/ValdikSS/byedpi.git "$BYEDPI_DIR"
fi

# Create build directory
mkdir -p "$IOS_BUILD_DIR"

# iOS SDK path
IOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path)
IOS_CC=$(xcrun --sdk iphoneos --find clang)

# Architecture settings
ARCHS="arm64"
MIN_IOS_VERSION="14.0"

echo -e "${GREEN}Building for iOS architectures: ${ARCHS}${NC}"
echo -e "${GREEN}Minimum iOS version: ${MIN_IOS_VERSION}${NC}"

# Build for each architecture
for ARCH in $ARCHS; do
    echo -e "${YELLOW}Building for ${ARCH}...${NC}"
    
    ARCH_BUILD_DIR="$IOS_BUILD_DIR/$ARCH"
    mkdir -p "$ARCH_BUILD_DIR"
    
    # Set compiler flags
    case $ARCH in
        arm64)
            SDK_NAME="iphoneos"
            ;;
        *)
            echo -e "${RED}Unsupported architecture: ${ARCH}${NC}"
            exit 1
            ;;
    esac
    
    # Compile byedpi sources
    CFLAGS="-arch ${ARCH} -isysroot ${IOS_SDK} -miphoneos-version-min=${MIN_IOS_VERSION} -O2"
    
    cd "$BYEDPI_DIR"
    
    # Compile main byedpi sources
    SOURCES="byedpi.c desync.c tcp.c udp.c misc.c"
    OBJECTS=""
    
    for SRC in $SOURCES; do
        OBJ="$ARCH_BUILD_DIR/${SRC%.c}.o"
        echo "  Compiling ${SRC}..."
        $IOS_CC $CFLAGS -c -o "$OBJ" "$SRC" || {
            echo -e "${RED}Failed to compile ${SRC}${NC}"
            exit 1
        }
        OBJECTS="$OBJECTS $OBJ"
    done
    
    # Create static library
    LIB_PATH="$ARCH_BUILD_DIR/libbyedpi.a"
    echo "  Creating static library ${LIB_PATH}..."
    ar rcs "$LIB_PATH" $OBJECTS
    
    echo -e "${GREEN}✓ Built for ${ARCH}${NC}"
done

# Create universal library (lipo)
if [ $(echo $ARCHS | wc -w) -gt 1 ]; then
    echo -e "${YELLOW}Creating universal binary...${NC}"
    LIB_FILES=""
    for ARCH in $ARCHS; do
        LIB_FILES="$LIB_FILES $IOS_BUILD_DIR/$ARCH/libbyedpi.a"
    done
    
    lipo -create $LIB_FILES -output "$IOS_BUILD_DIR/libbyedpi.a"
    echo -e "${GREEN}✓ Created universal binary${NC}"
fi

# Copy headers
echo -e "${YELLOW}Copying headers...${NC}"
cp "$BYEDPI_DIR"/*.h "$PROJECT_DIR/ByeDPICore/include/" 2>/dev/null || true

echo -e "${GREEN}=== Build Complete ===${NC}"
echo -e "${GREEN}Output: ${IOS_BUILD_DIR}/libbyedpi.a${NC}"
echo ""
echo "Next steps:"
echo "1. Add the library to your Xcode project"
echo "2. Link against required system frameworks"
echo "3. Build and run on device"
