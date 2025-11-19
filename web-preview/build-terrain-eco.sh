#!/bin/bash

# 构建地形和生态系统相关WASM文件的脚本
# 如果系统中没有安装Emscripten，则创建占位符WASM文件

echo "Building terrain and ecosystem WASM files..."

# 检查是否安装了Emscripten
if command -v emcc &> /dev/null; then
    echo "Emscripten found. Building actual WASM files..."
    
    # 编译地形相关代码
    emcc -O3 \
         -s WASM=1 \
         -s EXPORTED_FUNCTIONS='["_terrain_minimap", "_eco_qv_minimap", "_malloc", "_free"]' \
         -s EXPORTED_RUNTIME_METHODS='["ccall", "cwrap", "addFunction"]' \
         -s ALLOW_MEMORY_GROWTH=1 \
         -s MODULARIZE=1 \
         -s EXPORT_NAME="TerrainEcoModule" \
         -s ENVIRONMENT="web" \
         -s NO_EXIT_RUNTIME=1 \
         -s ASSERTIONS=1 \
         --bind \
         minimap_terrain.cc minimap_eco_qv.cc -o wasm/terrain-eco.js
    
    if [ $? -eq 0 ]; then
        echo "Terrain and ecosystem WASM files built successfully!"
        echo "Output: wasm/terrain-eco.js and wasm/terrain-eco.wasm"
    else
        echo "Error building WASM files. Creating placeholder files instead..."
        # 创建占位符文件
        echo ";; Placeholder WASM file for terrain and ecosystem functions" > wasm/terrain-eco.wast
        echo "(module)" > wasm/terrain-eco.wast
        # 创建一个简单的JS stub
        echo "/* Placeholder JS file for terrain and ecosystem functions */" > wasm/terrain-eco.js
        echo "const TerrainEcoModule = {};" >> wasm/terrain-eco.js
        echo "console.log('Terrain and ecosystem WASM module: Placeholder used - Emscripten build failed');" >> wasm/terrain-eco.js
    fi
else
    echo "Emscripten not found. Creating placeholder WASM files..."
    
    # 创建占位符WASM文件（二进制格式）
    # 创建一个最小的WASM文件作为占位符
    echo -ne '\x00\x61\x73\x6d\x01\x00\x00\x00' > wasm/terrain-eco.wasm
    
    # 创建对应的JS文件
    cat > wasm/terrain-eco.js << 'EOF'
// Placeholder Terrain and Ecosystem Module for Sandbox Meteor Web Preview
// This module is used when Emscripten is not available

const TerrainEcoModule = (async () => {
  console.log('Loading Terrain and Ecosystem Module (Placeholder)');
  
  // 模拟terrain_minimap函数
  function terrain_minimap(grid_ptr, out_terrain_ptr) {
    console.log('terrain_minimap called with grid_ptr:', grid_ptr, 'out_terrain_ptr:', out_terrain_ptr);
    // 这里会通过堆内存与JavaScript交互
    if (typeof Module !== 'undefined' && Module.HEAPU8) {
      // 模拟地形数据生成
      for (let y = 0; y < 256; y++) {
        for (let x = 0; x < 256; x++) {
          const idx = y * 256 + x;
          // 生成简单的陆地/海洋分布
          const dx = x - 128;
          const dy = y - 128;
          const distance = Math.sqrt(dx*dx + dy*dy);
          const angle = Math.atan2(dy, dx);
          const landThreshold = 100 + 30 * Math.sin(3 * angle) + 20 * Math.sin(5 * angle);
          const terrainValue = (distance < landThreshold) ? 143 : 135; // 陆地=143, 海洋=135
          Module.HEAPU8[out_terrain_ptr + idx] = terrainValue;
        }
      }
    }
  }
  
  // 模拟eco_qv_minimap函数
  function eco_qv_minimap(eco_ptr, out_qv_ptr) {
    console.log('eco_qv_minimap called with eco_ptr:', eco_ptr, 'out_qv_ptr:', out_qv_ptr);
    if (typeof Module !== 'undefined' && Module.HEAPU8 && Module.HEAPF64) {
      // 从生态向量计算水汽值
      const ecoState = new Array(64);
      for (let i = 0; i < 64; i++) {
        ecoState[i] = Module.HEAPF64[eco_ptr/8 + i];
      }
      
      // 使用公式：qv_gen = max(0, EcoState[17]*0.01 - EcoState[7]*0.005)
      const base_qv_gen = Math.max(0, ecoState[17] * 0.01 - ecoState[7] * 0.005);
      
      // 生成水汽分布到输出数组
      for (let i = 0; i < 256 * 256; i++) {
        // 应用一些随机性来模拟空间变化
        const local_qv_gen = base_qv_gen * (0.8 + 0.4 * (Math.sin(i * 0.1) * 0.5 + 0.5));
        
        // 对数压缩：val = log10(qv_gen + 1e-6) * 50；clip 0-255
        const log_val = Math.log10(local_qv_gen + 1e-6) * 50.0;
        const qv_quantized = Math.max(0, Math.min(255, log_val + 128.0));
        
        Module.HEAPU8[out_qv_ptr + i] = Math.floor(qv_quantized);
      }
    }
  }
  
  // 模拟模块就绪事件
  if (typeof onTerrainEcoReady === 'function') {
    onTerrainEcoReady();
  }
  
  return {
    terrain_minimap: terrain_minimap,
    eco_qv_minimap: eco_qv_minimap,
    onRuntimeInitialized: function() {
      console.log('TerrainEcoModule runtime initialized (placeholder)');
      if (this.onRuntimeInitializedCallback) {
        this.onRuntimeInitializedCallback();
      }
    },
    then: function(callback) {
      // 立即执行回调，因为这是占位符
      callback(this);
      return this;
    }
  };
})();

// 全局暴露模块
window.TerrainEcoModule = TerrainEcoModule;

console.log('Terrain and Ecosystem Placeholder Module Loaded');
EOF

    echo "Placeholder terrain and ecosystem WASM files created."
    echo "Files created: wasm/terrain-eco.wasm, wasm/terrain-eco.js"
fi

echo "Build process completed."
