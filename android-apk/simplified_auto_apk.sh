#!/bin/bash

# Simplified APK Build Script for Termux
# Focuses on essential build steps without complex workflow monitoring

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🚀 Simplified APK Build Script${NC}"
echo -e "${PURPLE}==============================${NC}\n"

# Check if in the correct directory
if [ ! -f "settings.gradle" ] || [ ! -f "build.gradle" ] || [ ! -d "app" ]; then
    echo -e "${RED}❌ Error: Not in the correct Android project directory${NC}"
    exit 1
fi

# Function to check if required tools are available
check_tools() {
    echo -e "${YELLOW}🔍 Checking required tools...${NC}"
    
    if ! command -v java &> /dev/null; then
        echo -e "${RED}❌ Error: Java is not installed or not in PATH${NC}"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        echo -e "${RED}❌ Error: Git is not installed or not in PATH${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Required tools found${NC}"
}

# Function to prepare for build
prepare_build() {
    echo -e "${YELLOW}🔧 Preparing build environment...${NC}"
    
    # Check if Android environment variables are set
    if [ -z "$ANDROID_HOME" ]; then
        echo -e "${YELLOW}⚠️  ANDROID_HOME not set, attempting to auto-detect...${NC}"
        
        # Try to find Android SDK in common locations
        if [ -d "$HOME/android-sdk" ]; then
            export ANDROID_HOME="$HOME/android-sdk"
        elif [ -d "$HOME/Android/Sdk" ]; then
            export ANDROID_HOME="$HOME/Android/Sdk"
        elif [ -d "/data/data/com.termux/files/home/android-sdk" ]; then
            export ANDROID_HOME="/data/data/com.termux/files/home/android-sdk"
        fi
        
        if [ -n "$ANDROID_HOME" ]; then
            export ANDROID_SDK_ROOT="$ANDROID_HOME"
            export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/bin"
        fi
    fi
    
    echo -e "${GREEN}✅ Build environment prepared${NC}"
}

# Function to check and update Gradle wrapper if needed
check_gradle_wrapper() {
    echo -e "${YELLOW}📦 Checking Gradle wrapper...${NC}"
    
    # Ensure the gradle-wrapper.jar exists and is valid
    GRADLE_WRAPPER_JAR="gradle/wrapper/gradle-wrapper.jar"
    if [ ! -f "$GRADLE_WRAPPER_JAR" ]; then
        echo -e "${RED}❌ Error: Gradle wrapper JAR file not found: $GRADLE_WRAPPER_JAR${NC}"
        exit 1
    fi
    
    # Check if it's a valid JAR file
    if ! unzip -t "$GRADLE_WRAPPER_JAR" >/dev/null 2>&1; then
        echo -e "${RED}❌ Error: Gradle wrapper JAR file is corrupted: $GRADLE_WRAPPER_JAR${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Gradle wrapper is valid${NC}"
}

# Function to run a basic build check
run_build_check() {
    echo -e "${YELLOW}🔍 Running build configuration check...${NC}"
    
    # Try a simple configuration check with minimal options
    ./gradlew --dry-run --console=plain --quiet || {
        echo -e "${YELLOW}⚠️  Build configuration has issues, but continuing...${NC}"
    }
    
    echo -e "${GREEN}✅ Build configuration check completed${NC}"
}

# Function to clean build outputs
clean_build() {
    echo -e "${YELLOW}🧹 Cleaning previous build outputs...${NC}"
    
    # Kill any existing Gradle daemons to avoid conflicts
    pkill -f "GradleDaemon" 2>/dev/null || true
    
    # Remove build outputs
    rm -rf app/build/ 2>/dev/null || true
    rm -rf build/ 2>/dev/null || true
    
    echo -e "${GREEN}✅ Build outputs cleaned${NC}"
}

# Function to build APK
build_apk() {
    echo -e "${YELLOW}🏗️  Building APK...${NC}"
    echo -e "${CYAN}This may take a few minutes...${NC}"
    
    # Build with minimal options to reduce resource usage
    ./gradlew assembleDebug \
        --no-daemon \
        -x test \
        -x lint \
        --console=plain \
        --max-workers=1 \
        -Dorg.gradle.jvmargs="-Xmx2g -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError" || {
            echo -e "${RED}❌ Error: Build failed${NC}"
            echo -e "${RED}💡 Try checking the build log for specific errors${NC}"
            return 1
        }
    
    echo -e "${GREEN}✅ APK build completed${NC}"
}

# Function to verify APK output
verify_apk() {
    echo -e "${YELLOW}🔍 Verifying APK output...${NC}"
    
    APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
    if [ -f "$APK_PATH" ]; then
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        echo -e "${GREEN}✅ APK found: $APK_PATH${NC}"
        echo -e "${GREEN}📊 APK Size: $APK_SIZE${NC}"
        
        # Copy to apk directory for consistency
        mkdir -p apk
        cp "$APK_PATH" "apk/sandbox-meteor-debug.apk"
        echo -e "${GREEN}📁 Copied to: apk/sandbox-meteor-debug.apk${NC}"
    else
        echo -e "${RED}❌ Error: APK was not created at $APK_PATH${NC}"
        return 1
    fi
}

# Main execution
main() {
    check_tools
    prepare_build
    check_gradle_wrapper
    clean_build
    run_build_check
    
    if build_apk; then
        verify_apk
        echo -e "\n${GREEN}🎉 Build completed successfully!${NC}"
        echo -e "${GREEN}📁 APK location: apk/sandbox-meteor-debug.apk${NC}"
        return 0
    else
        echo -e "\n${RED}❌ Build failed!${NC}"
        echo -e "${RED}💡 Check the build logs for more details${NC}"
        return 1
    fi
}

# Run main function
main "$@"
