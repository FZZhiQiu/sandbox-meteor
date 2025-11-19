#!/bin/bash

# Build script for MiniMap core components
# This script compiles the MiniMap core files to a placeholder WASM module

set -e  # Exit on any error

echo "Building MiniMap core components..."

# Create build directory if it doesn't exist
mkdir -p build

# Navigate to web-preview directory
cd "$(dirname "$0")"

# Check if g++ is available
if command -v g++ &> /dev/null; then
    echo "Compiling with g++..."
    
    # Attempt to compile with Emscripten if available
    if command -v emcc &> /dev/null; then
        EMSCRIPTEN_ROOT=$(dirname $(which emcc))
        echo "Found Emscripten at: $EMSCRIPTEN_ROOT"
        
        # Compile with Emscripten
        emcc minimap_core.cc minimap_wasm.cc -o wasm/minimap-core.wasm \
            -s WASM=1 \
            -s SIDE_MODULE=1 \
            -s EXPORTED_FUNCTIONS='["_minimap_update_wrapper", "_call_minimap_update"]' \
            -s EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' \
            -O3
        
        echo "MiniMap core compiled to WASM with Emscripten!"
    else
        echo "Emscripten not found. Creating a placeholder WASM module."
        echo "To build the actual WASM module, please install Emscripten:"
        echo "git clone https://github.com/emscripten-core/emsdk.git"
        echo "cd emsdk"
        echo "./emsdk install latest"
        echo "./emsdk activate latest"
        echo "source ./emsdk_env.sh"
        echo ""
        echo "Then run this script again."
        
        # Create a placeholder WASM file
        mkdir -p wasm
        cat > wasm/minimap-core.wasm << 'EOF'
// Placeholder for MiniMap Core WASM Module
// This file will be replaced when actual WASM is built

const MINIMAP_CORE_PLACEHOLDER = {
  initialized: false,
  
  async init() {
    console.log('MiniMap Core WASM Module (Placeholder Mode)');
    this.initialized = true;
    return this;
  },
  
  // Mock function that mimics the actual WASM API
  callMinimapUpdate(gridPtr, layerQcPtr, layerQrPtr, layerLtPtr, layerQvPtr) {
    console.log('Minimap update called with pointers (simulated)');
    
    // In a real implementation, this would call the actual WASM function:
    // Module._call_minimap_update(gridPtr, layerQcPtr, layerQrPtr, layerLtPtr, layerQvPtr);
    
    // For the placeholder, we'll return simulated data
    const size = 256 * 256;
    const qc = new Uint8Array(size);
    const qr = new Uint8Array(size);
    const lt = new Uint8Array(size);
    const qv = new Uint8Array(size);
    
    // Simulate data generation
    for (let i = 0; i < size; i++) {
      qc[i] = Math.floor(Math.random() * 256);
      qr[i] = Math.floor(Math.random() * 256);
      lt[i] = Math.floor(Math.random() * 100); // Lower values for lightning
      qv[i] = Math.floor(Math.random() * 256);
    }
    
    return { qc, qr, lt, qv };
  }
};

// Export for use in preview.js
if (typeof module !== 'undefined' && module.exports) {
  module.exports = MINIMAP_CORE_PLACEHOLDER;
} else {
  window.MiniMapCoreWASM = MINIMAP_CORE_PLACEHOLDER;
}
EOF

        echo "Created placeholder WASM module in wasm/minimap-core.wasm"
    fi
else
    echo "g++ not found. Creating a placeholder WASM module."
    
    # Create a placeholder WASM file
    mkdir -p wasm
    cat > wasm/minimap-core.wasm << 'EOF'
// Placeholder for MiniMap Core WASM Module
// This file will be replaced when actual WASM is built

const MINIMAP_CORE_PLACEHOLDER = {
  initialized: false,
  
  async init() {
    console.log('MiniMap Core WASM Module (Placeholder Mode)');
    this.initialized = true;
    return this;
  },
  
  // Mock function that mimics the actual WASM API
  callMinimapUpdate(gridPtr, layerQcPtr, layerQrPtr, layerLtPtr, layerQvPtr) {
    console.log('Minimap update called with pointers (simulated)');
    
    // In a real implementation, this would call the actual WASM function:
    // Module._call_minimap_update(gridPtr, layerQcPtr, layerQrPtr, layerLtPtr, layerQvPtr);
    
    // For the placeholder, we'll return simulated data
    const size = 256 * 256;
    const qc = new Uint8Array(size);
    const qr = new Uint8Array(size);
    const lt = new Uint8Array(size);
    const qv = new Uint8Array(size);
    
    // Simulate data generation
    for (let i = 0; i < size; i++) {
      qc[i] = Math.floor(Math.random() * 256);
      qr[i] = Math.floor(Math.random() * 256);
      lt[i] = Math.floor(Math.random() * 100); // Lower values for lightning
      qv[i] = Math.floor(Math.random() * 256);
    }
    
    return { qc, qr, lt, qv };
  }
};

// Export for use in preview.js
if (typeof module !== 'undefined' && module.exports) {
  module.exports = MINIMAP_CORE_PLACEHOLDER;
} else {
  window.MiniMapCoreWASM = MINIMAP_CORE_PLACEHOLDER;
}
EOF

    echo "Created placeholder WASM module in wasm/minimap-core.wasm"
fi

echo "Build process completed!"
echo "Your MiniMap core components are ready in the web-preview directory"
