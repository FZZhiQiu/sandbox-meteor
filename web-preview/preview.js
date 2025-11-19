// Web Preview for Sandbox Meteor
// JavaScript interface for MiniMap with terrain, eco-qv and agent overlays

let gl = null;
let program = null;
let positionBuffer = null;
let ecoVector = new Array(64).fill(0.0);
let policyValues = { vegetation: 50, emission: 50, budget: 50, construction: 50 };
let layerTextures = []; // 用于存储3个独立纹理（地形、水汽、代理人）
let minimapData = {
    terrain: new Uint8Array(256 * 256),  // 地形底图
    qv: new Uint8Array(256 * 256),       // 生态水汽
    agents: new Uint8Array(256 * 256)    // 代理人层
};

// 模拟地形数据更新函数
function simulateTerrainUpdate() {
    // 初始化地形层 - 模拟陆地和海洋分布
    for (let y = 0; y < 256; y++) {
        for (let x = 0; x < 256; x++) {
            // 创建一个简单的陆地/海洋分布
            // 使用正弦波和距离中心的距离来模拟地形
            const dx = x - 128;
            const dy = y - 128;
            const distance = Math.sqrt(dx*dx + dy*dy);
            const angle = Math.atan2(dy, dx);
            
            // 创建大陆形状
            const landThreshold = 100 + 30 * Math.sin(3 * angle) + 20 * Math.sin(5 * angle);
            
            // 陆地：固定浅绿 #8FBC8F (143)，海洋：固定浅蓝 #87CEEB (135)
            const terrainValue = (distance < landThreshold) ? 143 : 135;
            const idx = y * 256 + x;
            minimapData.terrain[idx] = terrainValue;
        }
    }
}

// 模拟生态水汽更新函数
function simulateEcoQvUpdate() {
    // 使用ecoVector的值计算水汽生成
    // 公式：qv_gen = max(0, EcoState[17]*0.01 - EcoState[7]*0.005)
    const base_qv_gen = Math.max(0, ecoVector[17] * 0.01 - ecoVector[7] * 0.005);
    
    for (let i = 0; i < 256 * 256; i++) {
        // 应用一些随机性来模拟空间变化
        const local_qv_gen = base_qv_gen * (0.8 + 0.4 * (Math.sin(i * 0.1) * 0.5 + 0.5));
        
        // 对数压缩：val = log10(qv_gen + 1e-6) * 50；clip 0-255
        const log_val = Math.log10(local_qv_gen + 1e-6) * 50.0;
        const qv_quantized = Math.max(0, Math.min(255, log_val + 128.0));
        
        minimapData.qv[i] = Math.floor(qv_quantized);
    }
}

// 模拟代理人数据更新函数
function simulateAgentsUpdate() {
    // 初始化代理人层为0
    for (let i = 0; i < 256 * 256; i++) {
        minimapData.agents[i] = 0;
    }
    
    // 模拟4096个代理人的随机分布
    // 在实际实现中，这会调用agents_minimap函数
    for (let i = 0; i < 100; i++) {  // 模拟100个代理人，实际应为4096
        // 随机位置
        const x = Math.random() * 255;
        const y = Math.random() * 255;
        
        // 职业ID
        const professionId = i % 256;
        
        // 将世界坐标量化到256x256网格
        const idx = Math.floor(x);
        const idy = Math.floor(y);
        
        // 以idx,idy为中心画0.5像素圆（3x3区域）
        for (let dy = -1; dy <= 1; dy++) {
            for (let dx = -1; dx <= 1; dx++) {
                const px = idx + dx;
                const py = idy + dy;
                
                if (px >= 0 && px < 256 && py >= 0 && py < 256) {
                    const maskIdx = py * 256 + px;
                    // 使用职业ID作为颜色值
                    minimapData.agents[maskIdx] = professionId;
                }
            }
        }
    }
}

// WebGL 初始化
function initializeWebGL(canvasId) {
    const canvas = document.getElementById(canvasId);
    if (!canvas) {
        console.error("Canvas not found:", canvasId);
        return;
    }
    
    // 尝试获取WebGL2上下文
    gl = canvas.getContext('webgl2') || canvas.getContext('experimental-webgl2');
    if (!gl) {
        console.error("WebGL2 not supported, falling back to WebGL");
        gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
    }
    
    if (!gl) {
        console.error("WebGL not supported");
        return;
    }
    
    console.log("WebGL initialized successfully");
    
    // 创建着色器程序
    createShaderProgram();
    
    // 创建纹理
    createTextures();
    
    // 创建缓冲区
    createBuffers();
    
    // 启动模拟循环
    startSimulation();
}

// 创建着色器程序
function createShaderProgram() {
    // 顶点着色器
    const vertexShaderSource = `
        attribute vec2 a_position;
        varying vec2 v_texCoord;
        
        void main() {
            gl_Position = vec4(a_position, 0.0, 1.0);
            v_texCoord = a_position * 0.5 + 0.5; // 转换到纹理坐标系
        }
    `;
    
    // 片段着色器 - 包含地形、水汽和代理人层
    const fragmentShaderSource = `
        precision mediump float;
        
        varying vec2 v_texCoord;
        uniform sampler2D u_texture0;  // terrain - 地形底图
        uniform sampler2D u_texture1;  // qv - 生态水汽
        uniform sampler2D u_texture2;  // agents - 代理人
        
        void main() {
            vec2 texSize = vec2(256.0, 256.0);
            vec2 uv = v_texCoord * texSize;
            vec2 texCoord = uv / texSize;
            
            // 从地形纹理采样 - 作为底图
            float terrain = texture2D(u_texture0, texCoord).r;
            
            // 从水汽纹理采样
            float qv = texture2D(u_texture1, texCoord).r;
            
            // 从代理人纹理采样
            float agent = texture2D(u_texture2, texCoord).r;
            
            // 基础颜色：根据地形值决定陆地或海洋
            vec3 baseColor;
            if (terrain > 140.0) {  // 陆地
                baseColor = vec3(0.56, 0.74, 0.56);  // 浅绿色
            } else {  // 海洋
                baseColor = vec3(0.53, 0.81, 0.92);  // 浅蓝色
            }
            
            // 叠加水汽效果（淡蓝色调）
            vec3 qvColor = vec3(0.7, 0.8, 1.0);  // 水汽的淡蓝色
            float qvStrength = qv / 255.0;  // 归一化水汽值
            vec3 qvEffect = mix(baseColor, qvColor, qvStrength * 0.4);  // 适度混合，避免完全覆盖地形颜色
            
            // 如果代理人层有值，叠加代理人颜色
            if (agent > 0.0) {
                // 代理人颜色：基于职业ID的彩虹色
                float hue = agent / 255.0;
                vec3 agentColor = vec3(
                    abs(hue * 6.0 - 3.0) - 1.0,
                    2.0 - abs(hue * 6.0 - 2.0),
                    2.0 - abs(hue * 6.0 - 4.0)
                );
                agentColor = clamp(agentColor, 0.0, 1.0);
                
                // 将代理人显示为0.5像素的实心圆点，覆盖在地形和水汽之上
                gl_FragColor = vec4(agentColor, 1.0);
            } else {
                gl_FragColor = vec4(qvEffect, 1.0);
            }
        }
    `;
    
    const vertexShader = createShader(gl, gl.VERTEX_SHADER, vertexShaderSource);
    const fragmentShader = createShader(gl, gl.FRAGMENT_SHADER, fragmentShaderSource);
    
    program = gl.createProgram();
    gl.attachShader(program, vertexShader);
    gl.attachShader(program, fragmentShader);
    gl.linkProgram(program);
    
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
        console.error("Failed to link shader program:", gl.getProgramInfoLog(program));
    }
    
    gl.useProgram(program);
}

// 创建着色器
function createShader(gl, type, source) {
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
        console.error("Error compiling shader:", gl.getShaderInfoLog(shader));
        gl.deleteShader(shader);
        return null;
    }
    
    return shader;
}

// 创建纹理
function createTextures() {
    // 创建3个独立的纹理，分别对应地形、水汽、代理人
    for (let i = 0; i < 3; i++) {
        const texture = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, texture);
        
        // 设置纹理参数
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);  // 使用NEAREST避免插值
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        
        // 创建空的纹理
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RED, 256, 256, 0, gl.RED, gl.UNSIGNED_BYTE, null);
        
        layerTextures.push(texture);
    }
    
    // 设置采样器
    const uTexture0Location = gl.getUniformLocation(program, "u_texture0");
    const uTexture1Location = gl.getUniformLocation(program, "u_texture1");
    const uTexture2Location = gl.getUniformLocation(program, "u_texture2");
    
    gl.uniform1i(uTexture0Location, 0);
    gl.uniform1i(uTexture1Location, 1);
    gl.uniform1i(uTexture2Location, 2);
}

// 创建缓冲区
function createBuffers() {
    // 创建顶点位置缓冲区
    positionBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
    
    // 定义一个全屏四边形的顶点
    const positions = [
        -1, -1,
        1, -1,
        -1, 1,
        -1, 1,
        1, -1,
        1, 1
    ];
    
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(positions), gl.STATIC_DRAW);
    
    // 绑定位置属性
    const positionLocation = gl.getAttribLocation(program, "a_position");
    gl.enableVertexAttribArray(positionLocation);
    gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);
}

// 更新WebGL渲染
function updateWebGL(newEcoVector) {
    if (!gl || !program) return;
    
    // 更新生态向量
    ecoVector = [...newEcoVector];
    
    // 每秒调用一次各层更新（在实际实现中，这会调用WASM函数）
    if (Math.floor(Date.now() / 1000) % 1 === 0) {
        simulateTerrainUpdate();   // 地形层（静态）
        simulateEcoQvUpdate();     // 水汽层（动态）
        simulateAgentsUpdate();    // 代理人层（动态）
    }
    
    // 更新纹理数据
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, layerTextures[0]);
    gl.texSubImage2D(gl.TEXTURE_2D, 0, 0, 0, 256, 256, gl.RED, gl.UNSIGNED_BYTE, minimapData.terrain);
    
    gl.activeTexture(gl.TEXTURE1);
    gl.bindTexture(gl.TEXTURE_2D, layerTextures[1]);
    gl.texSubImage2D(gl.TEXTURE_2D, 0, 0, 0, 256, 256, gl.RED, gl.UNSIGNED_BYTE, minimapData.qv);
    
    // 更新代理人纹理
    gl.activeTexture(gl.TEXTURE2);
    gl.bindTexture(gl.TEXTURE_2D, layerTextures[2]);
    gl.texSubImage2D(gl.TEXTURE_2D, 0, 0, 0, 256, 256, gl.RED, gl.UNSIGNED_BYTE, minimapData.agents);
    
    // 渲染
    render();
}

// 渲染函数
function render() {
    if (!gl || !program) return;
    
    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
    gl.clearColor(0, 0, 0, 0);
    gl.clear(gl.COLOR_BUFFER_BIT);
    
    gl.useProgram(program);
    
    // 绑定纹理
    for (let i = 0; i < 3; i++) {
        gl.activeTexture(gl.TEXTURE0 + i);
        gl.bindTexture(gl.TEXTURE_2D, layerTextures[i]);
    }
    
    // 绘制
    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
    gl.drawArrays(gl.TRIANGLES, 0, 6);
}

// 启动模拟循环
function startSimulation() {
    // 启动模拟循环
    setInterval(() => {
        // 更新生态向量（模拟实际计算）
        updateEcoVector();
        
        // 触发UI更新（如果Vue应用存在）
        if (window.updateMinimapFromEcoVector) {
            window.updateMinimapFromEcoVector(ecoVector);
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
    
    // 模拟每秒调用一次各层更新
    if (Math.floor(Date.now() / 1000) % 1 === 0) {
        simulateTerrainUpdate();   // 地形层（静态）
        simulateEcoQvUpdate();     // 水汽层（动态）
        simulateAgentsUpdate();    // 代理人层（动态）
    }
}

// 更新政策值
function updatePolicyValues(newPolicies) {
    policyValues = { ...newPolicies };
}

// 获取当前生态向量
function getEcoVector() {
    return [...ecoVector];
}

// 初始化
document.addEventListener('DOMContentLoaded', () => {
    // 将函数暴露给全局作用域，以便Vue组件可以调用
    window.initializeWebGL = initializeWebGL;
    window.updateWebGL = updateWebGL;
    window.updatePolicyValues = updatePolicyValues;
    window.getEcoVector = getEcoVector;
    window.startSimulation = startSimulation;
    
    // 如果页面已加载，尝试初始化
    if (document.getElementById('minimap')) {
        initializeWebGL('minimap');
    }
});