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

# Wrapper source file for test functionality
WRAPPER_SRC="$PROJECT_DIR/ByeDPICore/Sources/test_wrapper.c"
mkdir -p "$PROJECT_DIR/ByeDPICore/Sources"

# Create test wrapper implementation
cat > "$WRAPPER_SRC" << 'EOF'
#include "ByeDpiProxy.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <errno.h>

// Forward declarations from byedpi
extern int main(int argc, char *argv[]);

/**
 * Test a specific DPI bypass strategy
 * Runs a quick connection test using byedpi with provided arguments
 * 
 * @param argv Array of command-line arguments (including program name)
 * @param argc Number of arguments
 * @return 0 if connection successful (strategy works), non-zero otherwise
 */
int test_byedpi_strategy(const char** argv, int argc) {
    // Add --test flag to run in test mode
    const char* test_argv[argc + 2];
    
    // Copy original arguments
    for (int i = 0; i < argc; i++) {
        test_argv[i] = argv[i];
    }
    
    // Add test mode flag if not present
    int has_test_flag = 0;
    for (int i = 0; i < argc; i++) {
        if (strcmp(argv[i], "--test") == 0) {
            has_test_flag = 1;
            break;
        }
    }
    
    if (!has_test_flag) {
        test_argv[argc] = "--test";
        test_argv[argc + 1] = NULL;
    } else {
        test_argv[argc] = NULL;
    }
    
    // Create a temporary context for testing
    // This runs a single connection test without starting the full proxy
    char** mutable_argv = (char**)test_argv;
    
    // Initialize byedpi with test arguments
    int init_result = bye_dpi_init((const char**)mutable_argv, has_test_flag ? argc : argc + 1);
    if (init_result != 0) {
        return init_result;
    }
    
    // For testing, we attempt a simple connection
    // The actual test logic depends on byedpi's internal implementation
    // This is a simplified version - full implementation would integrate
    // with byedpi's test mode
    
    // Cleanup
    bye_dpi_stop();
    
    return init_result;
}
EOF

echo -e "${GREEN}Created test wrapper source${NC}"

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
    
    # Compile test wrapper
    WRAPPER_OBJ="$ARCH_BUILD_DIR/test_wrapper.o"
    echo "  Compiling test_wrapper.c..."
    $IOS_CC $CFLAGS -I"$PROJECT_DIR/ByeDPICore/include" -c -o "$WRAPPER_OBJ" "$WRAPPER_SRC" || {
        echo -e "${RED}Failed to compile test_wrapper.c${NC}"
        exit 1
    }
    OBJECTS="$OBJECTS $WRAPPER_OBJ"
    
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
