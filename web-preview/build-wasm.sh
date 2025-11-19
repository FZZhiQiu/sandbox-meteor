#!/bin/bash

# Sandbox Meteor - Build WASM for Web Preview
# This script compiles the core simulation to WASM without affecting the main APK build

set -e  # Exit on any error

echo "Building WASM for Sandbox Meteor Web Preview..."

# Create wasm directory if it doesn't exist
mkdir -p wasm

# Navigate to the web-preview directory
cd "$(dirname "$0")"

# Find the sandbox-radar directory relative to the current location
SANDBOX_RADAR_PATH="../sandbox-radar"

if [ ! -d "$SANDBOX_RADAR_PATH" ]; then
    echo "Error: sandbox-radar directory not found at $SANDBOX_RADAR_PATH"
    exit 1
fi

echo "Using sandbox-radar at: $SANDBOX_RADAR_PATH"

# Build configuration for WASM
BUILD_DIR="wasm-build"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure CMake for WASM
# Note: This assumes Emscripten is installed and in PATH
if command -v emcc &> /dev/null; then
    EMSCRIPTEN_ROOT=$(dirname $(which emcc))
    echo "Found Emscripten at: $EMSCRIPTEN_ROOT"
    
    # Set up the CMake toolchain for Emscripten
    cmake -DCMAKE_TOOLCHAIN_FILE="$EMSCRIPTEN_ROOT/cmake/Modules/Platform/Emscripten.cmake" \
          -DPLATFORM=WASM \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_RUNTIME_OUTPUT_DIRECTORY="$PWD/../wasm" \
          -S "$SANDBOX_RADAR_PATH" -B .
    
    # Build only the necessary libraries for the web preview
    make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    
    # Copy the resulting WASM file to the wasm directory
    if [ -f "sandbox_radar.wasm" ]; then
        cp sandbox_radar.wasm ../wasm/
        echo "WASM build completed successfully!"
        echo "Output: $(pwd)/../wasm/sandbox_radar.wasm"
    else
        # If the expected file doesn't exist, try to find any .wasm file
        if ls "$SANDBOX_RADAR_PATH"/*.wasm 1> /dev/null 2>&1; then
            cp "$SANDBOX_RADAR_PATH"/*.wasm ../wasm/ 2>/dev/null || true
            echo "WASM file copied to wasm directory"
        else
            echo "Warning: No WASM file found, creating a placeholder"
            echo "console.log('Sandbox Radar WASM Module Placeholder');" > ../wasm/sandbox_radar.js
            echo "Building WASM requires Emscripten to be installed"
            echo "Install with: git clone https://github.com/emscripten-core/emsdk.git && cd emsdk && ./emsdk install latest && ./emsdk activate latest"
        fi
    fi
else
    echo "Emscripten not found. Creating a placeholder WASM build script."
    echo "To build the actual WASM module, please install Emscripten:"
    echo "git clone https://github.com/emscripten-core/emsdk.git"
    echo "cd emsdk"
    echo "./emsdk install latest"
    echo "./emsdk activate latest"
    echo "source ./emsdk_env.sh"
    echo ""
    echo "Then run this script again."
    
    # Create a placeholder WASM file for the web preview to work
    mkdir -p ../wasm
    cat > ../wasm/sandbox_radar.js << 'EOF'
// Placeholder for Sandbox Radar WASM Module
// This file will be replaced when actual WASM is built

const WASM_PLACEHOLDER = {
  initialized: false,
  
  async init() {
    console.log('Sandbox Radar WASM Module (Placeholder Mode)');
    this.initialized = true;
    return this;
  },
  
  // Mock functions that mimic the actual WASM API
  getEcoVector() {
    // Return a mock 64-dimensional eco vector
    const vector = new Array(64);
    for (let i = 0; i < 64; i++) {
      vector[i] = Math.sin(Date.now()/1000 + i) * 0.3 + (Math.random() - 0.5) * 0.1;
    }
    return vector;
  },
  
  updatePolicy(vegetation, emission, budget, construction) {
    console.log('Policy updated (veg:', vegetation, 'em:', emission, 'bud:', budget, 'con:', construction, ')');
  },
  
  getMiniMapData() {
    // Return a mock 256x256 minimap data
    const data = new Array(256 * 256 * 4); // RGBA
    for (let i = 0; i < data.length; i++) {
      data[i] = Math.floor(Math.random() * 256);
    }
    return data;
  }
};

// Export for use in preview.js
if (typeof module !== 'undefined' && module.exports) {
  module.exports = WASM_PLACEHOLDER;
} else {
  window.SandboxRadarWASM = WASM_PLACEHOLDER;
}
EOF

    echo "Created placeholder WASM module in wasm/sandbox_radar.js"
fi

echo "Build process completed!"
echo "Your web preview is ready in the web-preview directory"
echo "Run 'python serve.py' to start the preview server"
