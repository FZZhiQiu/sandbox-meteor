// 全局变量
let scene, camera, renderer;
let volumeData = null;
let stormSystem = null;
let animationId = null;
let currentTime = new Date();
let meteorologicalSimulator = null;
let baseMapData = null;

// 暴露到全局作用域以便其他脚本访问
window.scene = scene;
window.camera = camera;
window.renderer = renderer;
window.volumeData = volumeData;
window.stormSystem = stormSystem;
window.meteorologicalSimulator = meteorologicalSimulator;
window.baseMapData = baseMapData;

// 初始化Three.js场景
function initThreeJS() {
    // 创建场景
    scene = new THREE.Scene();
    // 使用更暗的背景色以增强底图对比度
    scene.background = new THREE.Color(0x000022);
    // 设置雾效以适应厘米级精度场景
    scene.fog = new THREE.Fog(0x000022, 2, 15); // 缩小雾效范围以匹配厘米级场景

    // 创建相机
    camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.001, 50); // 调整近远平面以适应厘米级精度
    camera.position.set(0, 3, 8); // 调整相机位置以匹配厘米级场景
    camera.lookAt(0, 0, 0);

    // 创建渲染器
    const canvas = document.getElementById('webgl-canvas');
    renderer = new THREE.WebGLRenderer({ 
        canvas: canvas,
        antialias: true,
        alpha: true
    });
    renderer.setSize(canvas.clientWidth, canvas.clientHeight);
    renderer.setPixelRatio(window.devicePixelRatio);
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;

    // 添加光源
    const ambientLight = new THREE.AmbientLight(0x404040, 0.8); // 增加环境光以适应小尺度场景
    scene.add(ambientLight);

    const directionalLight = new THREE.DirectionalLight(0xffffff, 1.2); // 增加方向光强度
    directionalLight.position.set(5, 10, 7); // 调整光源位置以匹配厘米级场景
    directionalLight.castShadow = true;
    directionalLight.shadow.mapSize.width = 2048;
    directionalLight.shadow.mapSize.height = 2048;
    scene.add(directionalLight);

    const hemisphereLight = new THREE.HemisphereLight(0x80deea, 0x388e3c, 0.6); // 增加强度
    scene.add(hemisphereLight);
    
    // 创建底图
    if (typeof baseMapGenerator !== 'undefined') {
        const baseMapResult = baseMapGenerator.createBaseMapVisualization(scene, 64, 12);
        window.baseMapData = baseMapResult;
    }
    
    // 添加风暴系统
    stormSystem = new StormSystem();
    scene.add(stormSystem.group);

    // 生成初始体积数据
    generateVolumeData();

    // 添加事件监听器
    window.addEventListener('resize', onWindowResize);

    // 开始渲染循环
    animate();
}

// 生成体积数据
function generateVolumeData() {
    const size = 64; // 减小尺寸以提高性能
    const data = new Array(size * size * size).fill(0);
    
    // 生成模拟的气象数据
    for (let z = 0; z < size; z++) {
        for (let y = 0; y < size; y++) {
            for (let x = 0; x < size; x++) {
                const idx = z * size * size + y * size + x;
                
                // 创建基础气象结构
                const distCenter = Math.sqrt(
                    Math.pow(x - size/2, 2) + 
                    Math.pow(y - size/2, 2) + 
                    Math.pow(z - size/3, 2)
                );
                
                let value = 0;
                
                // 根据当前选择的风暴类型生成不同结构
                const stormType = document.querySelector('.storm-btn.active')?.dataset.type || 'cumulus';
                
                switch(stormType) {
                    case 'cumulus':
                        // 积云 - 柔和的云朵结构
                        value = generateCumulusStructure(x, y, z, size, distCenter);
                        break;
                    case 'thunderstorm':
                        // 雷暴 - 更强的对流结构
                        value = generateThunderstormStructure(x, y, z, size, distCenter);
                        break;
                    case 'supercell':
                        // 超级单体 - 带有旋转结构
                        value = generateSupercellStructure(x, y, z, size, distCenter);
                        break;
                    case 'hail':
                        // 冰雹 - 高反射率核心
                        value = generateHailStructure(x, y, z, size, distCenter);
                        break;
                    case 'tornado':
                        // 龙卷风 - 旋转柱状结构
                        value = generateTornadoStructure(x, y, z, size, distCenter);
                        break;
                    default:
                        value = generateCumulusStructure(x, y, z, size, distCenter);
                }
                
                // 添加一些随机噪声
                value += (Math.random() - 0.5) * 5;
                
                // 确保值在有效范围内
                value = Math.max(0, Math.min(80, value));
                
                data[idx] = value;
            }
        }
    }
    
    volumeData = {
        data: data,
        size: size,
        x: size,
        y: size,
        z: size
    };
    
    // 更新风暴系统
    stormSystem.updateData(volumeData);
}

// 生成积云结构
function generateCumulusStructure(x, y, z, size, distCenter) {
    let value = 0;
    const centerX = size / 2;
    const centerY = size / 2;
    const centerZ = size / 3;
    
    // 基础云朵形状
    if (distCenter < size / 2.5) {
        value = 30 * (1 - distCenter / (size / 2.5));
    }
    
    // 添加一些不规则性
    const noise = 10 * Math.sin(x * 0.3) * Math.cos(y * 0.2) * Math.sin(z * 0.4);
    value += noise;
    
    return Math.max(0, value);
}

// 生成雷暴结构
function generateThunderstormStructure(x, y, z, size, distCenter) {
    let value = 0;
    const centerX = size / 2;
    const centerY = size / 2;
    const centerZ = size / 3;
    
    // 强对流塔结构
    const verticalDist = Math.sqrt(Math.pow(x - centerX, 2) + Math.pow(y - centerY, 2));
    if (verticalDist < size / 4 && z > size / 4) {
        value = 50 * (1 - verticalDist / (size / 4)) * (z / size);
    }
    
    // 添加湍流效果
    const turbulence = 15 * Math.sin(x * 0.5) * Math.cos(y * 0.7) * Math.sin(z * 0.6);
    value += turbulence;
    
    return Math.max(0, value);
}

// 生成超级单体结构
function generateSupercellStructure(x, y, z, size, distCenter) {
    let value = 0;
    const centerX = size / 2;
    const centerY = size / 2;
    const centerZ = size / 3;
    
    // 旋转上升气流
    const angle = Math.atan2(y - centerY, x - centerX);
    const radius = Math.sqrt(Math.pow(x - centerX, 2) + Math.pow(y - centerY, 2));
    
    if (radius < size / 3 && z > size / 5) {
        // 旋转效应
        const rotationFactor = Math.sin(angle + z * 0.3) * 0.5 + 0.5;
        value = 60 * (1 - radius / (size / 3)) * (z / size) * rotationFactor;
    }
    
    return Math.max(0, value);
}

// 生成冰雹结构
function generateHailStructure(x, y, z, size, distCenter) {
    let value = 0;
    const centerX = size / 2;
    const centerY = size / 2;
    const centerZ = size / 3;
    
    // 高反射率核心（冰雹）
    const coreDist = Math.sqrt(Math.pow(x - centerX, 2) + Math.pow(y - centerY, 2) + Math.pow(z - centerZ * 1.5, 2));
    if (coreDist < size / 5) {
        value = 70; // 非常高的反射率
    } else {
        // 周围的风暴结构
        const stormDist = Math.sqrt(Math.pow(x - centerX, 2) + Math.pow(y - centerY, 2));
        if (stormDist < size / 2.5 && z > size / 6) {
            value = 45 * (1 - stormDist / (size / 2.5)) * (z / size);
        }
    }
    
    return Math.max(0, value);
}

// 生成龙卷风结构
function generateTornadoStructure(x, y, z, size, distCenter) {
    let value = 0;
    const centerX = size / 2;
    const centerY = size / 2;
    const centerZ = size / 4;
    
    // 旋转柱状结构
    const radius = Math.sqrt(Math.pow(x - centerX, 2) + Math.pow(y - centerY, 2));
    const angle = Math.atan2(y - centerY, x - centerX);
    
    if (radius < size / 8 && z < size / 2) {
        // 龙卷风漏斗
        const heightFactor = 1 - z / (size / 2);
        value = 55 * heightFactor;
        
        // 旋转效果
        value += 10 * Math.sin(angle + z * 2);
    }
    
    // 周围的风暴结构
    if (radius > size / 8 && radius < size / 3 && z < size / 2) {
        value = 35 * (1 - (radius - size/8) / (size/3 - size/8)) * (1 - z / (size/2));
    }
    
    return Math.max(0, value);
}

// 风暴系统类
class StormSystem {
    constructor() {
        this.group = new THREE.Group();
        this.volumeMeshes = [];
        this.currentMode = 'refl'; // 默认反射率模式
        this.resolution = 0.01; // 厘米级分辨率
        this.init();
    }
    
    init() {
        // 初始创建一些体积网格
        this.createVolumeMeshes();
    }
    
    createVolumeMeshes() {
        // 清除现有的体积网格
        this.volumeMeshes.forEach(mesh => {
            this.group.remove(mesh);
            mesh.geometry.dispose();
            if (mesh.material) mesh.material.dispose();
        });
        this.volumeMeshes = [];
        
        if (!volumeData) return;
        
        const { data, x, y, z, resolution = 0.01 } = volumeData; // 使用厘米级分辨率
        const maxVal = Math.max(...data);
        
        // 创建多个透明层来表示体积数据
        const step = 2; // 使用更高密度以体现厘米级精度
        for (let k = 0; k < z; k += step) {
            for (let j = 0; j < y; j += step) {
                for (let i = 0; i < x; i += step) {
                    const idx = k * y * x + j * x + i;
                    if (idx >= data.length) continue;
                    
                    const value = data[idx];
                    
                    // 只渲染超过阈值的点，降低阈值以体现更多细节
                    if (value > 5) {
                        const geometry = new THREE.SphereGeometry(0.05 * resolution * 1000, 8, 8); // 基于分辨率调整大小
                        
                        // 根据当前模式设置颜色
                        let color;
                        switch(this.currentMode) {
                            case 'refl':
                                color = this.getReflectivityColor(value);
                                break;
                            case 'vel':
                                color = this.getVelocityColor(value - 40); // 偏移以适应颜色映射
                                break;
                            case 'sw':
                                color = this.getSpectralWidthColor(value);
                                break;
                            case 'zdr':
                                color = this.getDifferentialReflectivityColor(value - 20); // 偏移
                                break;
                            case 'cc':
                                color = this.getCorrelationColor(value);
                                break;
                            case 'kdp':
                                color = this.getDifferentialPhaseColor(value - 40); // 偏移
                                break;
                            default:
                                color = this.getReflectivityColor(value);
                        }
                        
                        const material = new THREE.MeshBasicMaterial({
                            color: color,
                            transparent: true,
                            opacity: Math.min(0.6, value / maxVal * 0.8), // 调整透明度
                            depthWrite: false
                        });
                        
                        const mesh = new THREE.Mesh(geometry, material);
                        // 使用实际物理尺寸定位
                        mesh.position.set(
                            (i - x/2) * resolution * 100,
                            (k - z/2) * resolution * 100,  // 翻转Y和Z轴以匹配气象坐标系
                            (j - y/2) * resolution * 100
                        );
                        
                        this.group.add(mesh);
                        this.volumeMeshes.push(mesh);
                    }
                }
            }
        }
    }
    
    // 反射率颜色映射 (dBZ)
    getReflectivityColor(value) {
        // 气象雷达标准颜色映射
        if (value < 5) return new THREE.Color(0x008B8B); // 深青色 - 晴空
        else if (value < 15) return new THREE.Color(0x00FF00); // 绿色 - 小雨
        else if (value < 25) return new THREE.Color(0xADFF2F); // 黄绿色 - 中雨
        else if (value < 35) return new THREE.Color(0xFFFF00); // 黄色 - 大雨
        else if (value < 45) return new THREE.Color(0xFF8C00); // 橙色 - 大暴雨
        else if (value < 55) return new THREE.Color(0xFF0000); // 红色 - 极强降水
        else if (value < 65) return new THREE.Color(0x8B0000); // 深红色 - 可能冰雹
        else return new THREE.Color(0x8A2BE2); // 蓝紫色 - 强冰雹
    }
    
    // 多普勒速度颜色映射
    getVelocityColor(value) {
        // -20 to 20 m/s range
        const normalized = (value + 20) / 40; // 0 to 1
        if (normalized < 0.5) {
            // 蓝色系 (朝向雷达)
            const blueIntensity = (0.5 - normalized) * 2;
            return new THREE.Color(blueIntensity, blueIntensity * 0.7, 1.0);
        } else {
            // 红色系 (远离雷达)
            const redIntensity = (normalized - 0.5) * 2;
            return new THREE.Color(1.0, redIntensity * 0.7, redIntensity);
        }
    }
    
    // 谱宽颜色映射
    getSpectralWidthColor(value) {
        // 0 to 20 m/s range
        const normalized = Math.min(1.0, value / 20);
        const r = normalized;
        const g = 1 - normalized;
        const b = 0.5;
        return new THREE.Color(r, g, b);
    }
    
    // 差分反射率颜色映射
    getDifferentialReflectivityColor(value) {
        // -5 to 5 dB range
        const normalized = (value + 5) / 10; // 0 to 1
        if (normalized < 0.3) {
            return new THREE.Color(0.5, 0.5, 1.0); // 蓝色 - 负值
        } else if (normalized < 0.7) {
            return new THREE.Color(1.0, 1.0, 1.0); // 白色 - 接近零
        } else {
            return new THREE.Color(1.0, 0.5, 0.0); // 橙色 - 正值
        }
    }
    
    // 相关系数颜色映射
    getCorrelationColor(value) {
        // 0.8 to 1.0 range
        const normalized = (value - 0.8) * 5; // 0 to 1
        const intensity = Math.max(0, Math.min(1, normalized));
        return new THREE.Color(intensity, intensity, intensity);
    }
    
    // 比差分相位颜色映射
    getDifferentialPhaseColor(value) {
        // -200 to 200 deg/km range
        const normalized = (value + 200) / 400; // 0 to 1
        const r = normalized > 0.5 ? 1.0 : 2 * normalized;
        const b = normalized < 0.5 ? 1.0 : 2 * (1 - normalized);
        return new THREE.Color(r, 0.2, b);
    }
    
    updateData(newData) {
        if (newData) {
            volumeData = newData;
        }
        this.createVolumeMeshes();
    }
    
    setMode(mode) {
        this.currentMode = mode;
        this.createVolumeMeshes();
    }
    
    update(time) {
        // 旋转风暴系统以显示3D效果
        this.group.rotation.y = time * 0.1;
    }
}

// 动画循环
function animate() {
    animationId = requestAnimationFrame(animate);
    
    // 更新时间
    currentTime = new Date();
    document.getElementById('current-time').textContent = currentTime.toLocaleTimeString();
    
    // 更新风暴系统
    if (stormSystem) {
        // 如果有底图数据且有体积数据，进行海洋水汽生成
        if (window.baseMapData && volumeData && typeof baseMapGenerator !== 'undefined') {
            // 获取当前体积数据中的水汽场
            if (volumeData.data && volumeData.size) {
                // 使用底图数据更新水汽场
                volumeData.data = baseMapGenerator.calculateOceanMoistureGeneration(
                    window.baseMapData.baseMap, 
                    volumeData.data, 
                    0.1,  // dt
                    volumeData.size
                );
                
                // 应用风场修正
                // 这里可以应用风场影响，简化处理
            }
        }
        
        stormSystem.updateData(volumeData);
        stormSystem.update(currentTime.getTime() / 1000);
    }
    
    // 渲染场景
    renderer.render(scene, camera);
}

// 窗口大小调整
function onWindowResize() {
    const canvas = document.getElementById('webgl-canvas');
    camera.aspect = canvas.clientWidth / canvas.clientHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(canvas.clientWidth, canvas.clientHeight);
}

// 生成随机风暴类型描述
function getRandomStormDescription() {
    const descriptions = [
        "积云发展初期，对流活动较弱",
        "雷暴发展阶段，出现强上升气流",
        "超级单体风暴，具有旋转结构",
        "冰雹形成区域，高反射率核心",
        "龙卷风漏斗，强烈旋转特征",
        "飑线系统，多单体排列"
    ];
    return descriptions[Math.floor(Math.random() * descriptions.length)];
}

// 更新信息面板
function updateInfoPanel() {
    if (volumeData) {
        const avgRefl = volumeData.data.reduce((a, b) => a + b, 0) / volumeData.data.length;
        const maxRefl = Math.max(...volumeData.data);
        document.getElementById('reflectivity').textContent = maxRefl.toFixed(1);
        
        // 模拟风速值
        const windSpeed = (Math.random() * 30 + 5).toFixed(1);
        document.getElementById('wind-speed').textContent = windSpeed;
        
        // 随机风暴类型
        document.getElementById('storm-type').textContent = getRandomStormDescription();
    }
}

// 初始化函数
function init() {
    // 初始化气象模拟器
    meteorologicalSimulator = new MeteorologicalSimulator();
    
    initThreeJS();
    
    // 每秒更新一次信息面板
    setInterval(updateInfoPanel, 1000);
    
    // 设置默认风暴类型按钮状态
    document.querySelector('.preset-btn[data-type="cumulus"]').classList.add('active');
    
    // 设置默认图层状态
    document.querySelector('.layer-item').classList.add('active');
    
    // 将模拟器实例暴露到全局作用域
    window.meteorologicalSimulator = meteorologicalSimulator;
}

// 在页面加载完成后初始化
window.onload = init;