// Web Preview for Sandbox Meteor
// WASM glue code for MiniMap rendering

let wasmModule = null;
let ecoVector = new Array(64).fill(0.0);
let policyValues = { vegetation: 50, emission: 50, budget: 50, construction: 50 };

// 初始化WASM模块
async function initializeWASM() {
    try {
        // 注意：这里只是一个模拟，实际的WASM加载需要构建完成后
        console.log("Loading WASM module...");
        
        // 模拟WASM初始化成功
        console.log("WASM module loaded successfully");
        
        // 启动模拟循环
        startSimulation();
    } catch (error) {
        console.error("Failed to initialize WASM:", error);
    }
}

// 启动模拟循环
function startSimulation() {
    setInterval(() => {
        // 更新生态向量（模拟实际计算）
        updateEcoVector();
        
        // 触发UI更新
        if (window.updateEcoVector) {
            window.updateEcoVector(ecoVector);
        }
    }, 100); // 每100ms更新一次
}

// 更新生态向量
function updateEcoVector() {
    const time = Date.now() / 10000;
    
    // 模拟生态系统的动态变化
    for (let i = 0; i < 64; i++) {
        // 使用正弦波和随机数生成动态值
        const base = Math.sin(time + i * 0.1) * 0.3;
        const random = (Math.random() - 0.5) * 0.1;
        
        // 根据政策影响调整值
        const policyImpact = 
            (policyValues.vegetation / 100 * 0.1) +
            (policyValues.emission / 100 * -0.1) +
            (policyValues.budget / 100 * 0.05) +
            (policyValues.construction / 100 * -0.05);
        
        ecoVector[i] = base + random + policyImpact;
        
        // 限制值在合理范围内
        if (ecoVector[i] > 1.0) ecoVector[i] = 1.0;
        if (ecoVector[i] < -1.0) ecoVector[i] = -1.0;
    }
}

// 更新政策值
function updatePolicyValues(newPolicies) {
    policyValues = { ...newPolicies };
}

// 渲染MiniMap
function renderMiniMap(canvasId) {
    const canvas = document.getElementById(canvasId);
    if (!canvas) {
        console.error("Canvas not found:", canvasId);
        return;
    }
    
    const ctx = canvas.getContext('2d');
    const imageData = ctx.createImageData(256, 256);
    
    // 使用生态向量数据渲染256x256的MiniMap
    for (let y = 0; y < 256; y++) {
        for (let x = 0; x < 256; x++) {
            // 计算当前像素在生态向量中的索引
            const idx = (y * 256 + x) % 64;
            const value = ecoVector[idx];
            
            // 四色渲染：云水蓝、雨水绿、闪电红、水汽灰
            let r, g, b;
            
            if (idx < 16) {
                // 云/水: 蓝色系
                r = 50;
                g = 100 + Math.floor(Math.abs(value) * 100);
                b = 200 + Math.floor(value * 55);
            } else if (idx < 32) {
                // 雨: 绿色系
                r = 50 + Math.floor(Math.abs(value) * 50);
                g = 200 + Math.floor(value * 55);
                b = 100 - Math.floor(Math.abs(value) * 50);
            } else if (idx < 48) {
                // 闪电: 红色系
                r = 200 + Math.floor(value * 55);
                g = 50 + Math.floor(Math.abs(value) * 50);
                b = 50 + Math.floor(Math.abs(value) * 50);
            } else {
                // 水汽/其他: 灰色系
                const gray = 120 + Math.floor(value * 60);
                r = g = b = Math.max(0, Math.min(255, gray));
            }
            
            // 确保RGB值在有效范围内
            r = Math.max(0, Math.min(255, r));
            g = Math.max(0, Math.min(255, g));
            b = Math.max(0, Math.min(255, b));
            
            const pixelIdx = (y * 256 + x) * 4;
            imageData.data[pixelIdx] = r;     // R
            imageData.data[pixelIdx + 1] = g; // G
            imageData.data[pixelIdx + 2] = b; // B
            imageData.data[pixelIdx + 3] = 255; // A
        }
    }
    
    ctx.putImageData(imageData, 0, 0);
}

// 获取当前生态向量
function getEcoVector() {
    return [...ecoVector];
}

// 初始化
document.addEventListener('DOMContentLoaded', () => {
    initializeWASM();
    
    // 将函数暴露给全局作用域，以便Vue组件可以调用
    window.updatePolicyValues = updatePolicyValues;
    window.renderMiniMap = renderMiniMap;
    window.getEcoVector = getEcoVector;
});