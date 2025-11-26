#!/bin/bash

# Build script for Sandbox Meteor with enhanced features

echo "Building Sandbox Meteor with enhanced meteorological features..."

# Set up build environment
export ANDROID_NDK_HOME="/data/data/com.termux/files/home/android-apk/ndk/25.2.9519653"  # This path may vary
export CMAKE_ANDROID_NDK="/data/data/com.termux/files/home/android-apk/ndk/25.2.9519653"  # This path may vary

# Navigate to the project directory
cd /data/data/com.termux/files/home/happy/android-apk

echo "Project directory: $(pwd)"

# Create build directory if it doesn't exist
mkdir -p build_native

# Attempt to build with CMake
echo "Configuring with CMake..."
if cmake -H. -Bbuild_native -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-26 -DANDROID_STL=c++_static \
    -DCMAKE_BUILD_TYPE=Release -DENABLE_60FPS=ON; then
    
    echo "CMake configuration successful"
    
    echo "Building native library..."
    if cmake --build build_native --parallel; then
        echo "Build successful!"
        echo "Checking for output library..."
        find build_native -name "libsandbox_radar.so" -type f
    else
        echo "Build failed!"
        exit 1
    fi
else
    echo "CMake configuration failed!"
    echo "Checking if NDK path exists..."
    ls -la /data/data/com.termux/files/home/android-apk/ndk/ 2>/dev/null || echo "NDK path does not exist"
    exit 1
fi

echo "Enhanced Sandbox Meteor build completed successfully!"
