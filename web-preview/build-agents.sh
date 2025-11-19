#!/bin/bash

# Build script for MiniMap agents overlay
# This script compiles the MiniMap agents files to a placeholder WASM module

set -e  # Exit on any error

echo "Building MiniMap agents overlay components..."

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
        emcc minimap_agents.cc minimap_agents_wasm.cc -o wasm/agents-minimap.wasm \
            -s WASM=1 \
            -s SIDE_MODULE=1 \
            -s EXPORTED_FUNCTIONS='["_agents_minimap_wrapper", "_call_agents_minimap"]' \
            -s EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' \
            -O3
        
        echo "MiniMap agents overlay compiled to WASM with Emscripten!"
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
        cat > wasm/agents-minimap.wasm << 'EOF'
// Placeholder for MiniMap Agents WASM Module
// This file will be replaced when actual WASM is built

const MINIMAP_AGENTS_PLACEHOLDER = {
  initialized: false,
  
  async init() {
    console.log('MiniMap Agents WASM Module (Placeholder Mode)');
    this.initialized = true;
    return this;
  },
  
  // Mock function that mimics the actual WASM API
  callAgentsMinimap(outMaskPtr) {
    console.log('Agents minimap update called (simulated)');
    
    // In a real implementation, this would call the actual WASM function:
    // Module._call_agents_minimap(outMaskPtr);
    
    // For the placeholder, we'll return simulated agent data
    const size = 256 * 256;
    const agentMask = new Uint8Array(size);
    
    // Simulate 100 agents with random positions and profession IDs
    for (let i = 0; i < 100; i++) {
      const x = Math.floor(Math.random() * 255);
      const y = Math.floor(Math.random() * 255);
      const professionId = i % 256;
      
      // Draw a 0.5 pixel circle (3x3 area) for each agent
      for (let dy = -1; dy <= 1; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
          const px = x + dx;
          const py = y + dy;
          
          if (px >= 0 && px < 256 && py >= 0 && py < 256) {
            const idx = py * 256 + px;
            agentMask[idx] = professionId;
          }
        }
      }
    }
    
    return agentMask;
  }
};

// Export for use in preview.js
if (typeof module !== 'undefined' && module.exports) {
  module.exports = MINIMAP_AGENTS_PLACEHOLDER;
} else {
  window.MiniMapAgentsWASM = MINIMAP_AGENTS_PLACEHOLDER;
}
EOF

        echo "Created placeholder WASM module in wasm/agents-minimap.wasm"
    fi
else
    echo "g++ not found. Creating a placeholder WASM module."
    
    # Create a placeholder WASM file
    mkdir -p wasm
    cat > wasm/agents-minimap.wasm << 'EOF'
// Placeholder for MiniMap Agents WASM Module
// This file will be replaced when actual WASM is built

const MINIMAP_AGENTS_PLACEHOLDER = {
  initialized: false,
  
  async init() {
    console.log('MiniMap Agents WASM Module (Placeholder Mode)');
    this.initialized = true;
    return this;
  },
  
  // Mock function that mimics the actual WASM API
  callAgentsMinimap(outMaskPtr) {
    console.log('Agents minimap update called (simulated)');
    
    // In a real implementation, this would call the actual WASM function:
    // Module._call_agents_minimap(outMaskPtr);
    
    // For the placeholder, we'll return simulated agent data
    const size = 256 * 256;
    const agentMask = new Uint8Array(size);
    
    // Simulate 100 agents with random positions and profession IDs
    for (let i = 0; i < 100; i++) {
      const x = Math.floor(Math.random() * 255);
      const y = Math.floor(Math.random() * 255);
      const professionId = i % 256;
      
      // Draw a 0.5 pixel circle (3x3 area) for each agent
      for (let dy = -1; dy <= 1; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
          const px = x + dx;
          const py = y + dy;
          
          if (px >= 0 && px < 256 && py >= 0 && py < 256) {
            const idx = py * 256 + px;
            agentMask[idx] = professionId;
          }
        }
      }
    }
    
    return agentMask;
  }
};

// Export for use in preview.js
if (typeof module !== 'undefined' && module.exports) {
  module.exports = MINIMAP_AGENTS_PLACEHOLDER;
} else {
  window.MiniMapAgentsWASM = MINIMAP_AGENTS_PLACEHOLDER;
}
EOF

    echo "Created placeholder WASM module in wasm/agents-minimap.wasm"
fi

echo "Build process completed!"
echo "Your MiniMap agents overlay components are ready in the web-preview directory"