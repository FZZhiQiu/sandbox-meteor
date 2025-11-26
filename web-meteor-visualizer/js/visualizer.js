// 可视化功能模块
class VolumeVisualizer {
    constructor() {
        this.volumeData = null;
        this.meshes = [];
        this.isInitialized = false;
    }

    // 初始化体积渲染器
    init() {
        this.isInitialized = true;
    }

    // 创建体积数据的可视化表示
    createVolumeVisualization(data, mode = 'refl') {
        if (!data) return new THREE.Group();
        
        const group = new THREE.Group();
        const { data: volumeData, x, y, z, resolution = 0.01 } = data; // 使用厘米级分辨率
        const maxVal = Math.max(...volumeData);
        
        // 使用更高效的可视化方法 - 使用点精灵或小立方体
        const step = 1; // 使用更高密度以体现厘米级精度
        const geometry = new THREE.BufferGeometry();
        const positions = [];
        const colors = [];
        const sizes = [];
        
        for (let k = 0; k < z; k += step) {
            for (let j = 0; j < y; j += step) {
                for (let i = 0; i < x; i += step) {
                    const idx = k * y * x + j * x + i;
                    if (idx >= volumeData.length) continue;
                    
                    const value = volumeData[idx];
                    
                    // 只处理超过阈值的点
                    if (value > 5) { // 降低阈值以体现更多细节
                        // 位置 - 使用实际物理尺寸
                        positions.push(
                            (i - x/2) * resolution * 100, // 调整缩放以适应可视化
                            (k - z/2) * resolution * 100,  // 翻转Y和Z轴以匹配气象坐标系
                            (j - y/2) * resolution * 100
                        );
                        
                        // 颜色
                        let color;
                        switch(mode) {
                            case 'refl':
                                color = this.getReflectivityColor(value);
                                break;
                            case 'vel':
                                color = this.getVelocityColor(value - 40);
                                break;
                            case 'sw':
                                color = this.getSpectralWidthColor(value);
                                break;
                            case 'zdr':
                                color = this.getDifferentialReflectivityColor(value - 20);
                                break;
                            case 'cc':
                                color = this.getCorrelationColor(value);
                                break;
                            case 'kdp':
                                color = this.getDifferentialPhaseColor(value - 40);
                                break;
                            default:
                                color = this.getReflectivityColor(value);
                        }
                        
                        colors.push(color.r, color.g, color.b);
                        
                        // 尺寸 - 基于分辨率调整
                        sizes.push(Math.min(0.1, value / maxVal * 0.2 * resolution * 1000));
                    }
                }
            }
        }
        
        if (positions.length > 0) {
            geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
            geometry.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3));
            geometry.setAttribute('size', new THREE.Float32BufferAttribute(sizes, 1));
            
            // 创建点精灵材质
            const material = new THREE.ShaderMaterial({
                uniforms: {
                    pointTexture: { value: new THREE.TextureLoader().load('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==') } // 1x1白色png
                },
                vertexShader: `
                    attribute float size;
                    varying float vAlpha;
                    void main() {
                        vAlpha = 0.7;
                        vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
                        gl_PointSize = size * max(1.0, 30.0 * (1.0 / -mvPosition.z));
                        gl_Position = projectionMatrix * mvPosition;
                    }
                `,
                fragmentShader: `
                    uniform sampler2D pointTexture;
                    varying vec3 vColor;
                    varying float vAlpha;
                    void main() {
                        gl_FragColor = vec4(vColor, vAlpha);
                        gl_FragColor = gl_FragColor * texture2D(pointTexture, gl_PointCoord);
                        if (gl_FragColor.a < 0.1) discard;
                    }
                `,
                blending: THREE.AdditiveBlending,
                depthTest: false,
                transparent: true,
                vertexColors: true
            });
            
            const points = new THREE.Points(geometry, material);
            group.add(points);
        }
        
        return group;
    }

    // 反射率颜色映射 (dBZ) - 中国气象局标准
    getReflectivityColor(value) {
        // 中国气象局标准反射率颜色映射，增强对比度
        if (value < 5) return new THREE.Color(0x0000FF); // 深蓝色 - 5dBZ以下
        else if (value < 10) return new THREE.Color(0x0099FF); // 蓝色 - 5-10dBZ
        else if (value < 15) return new THREE.Color(0x00FF00); // 绿色 - 10-15dBZ
        else if (value < 20) return new THREE.Color(0x33FF00); // 浅绿 - 15-20dBZ
        else if (value < 25) return new THREE.Color(0xFFFF00); // 黄色 - 20-25dBZ
        else if (value < 30) return new THREE.Color(0xFF9900); // 橙色 - 25-30dBZ
        else if (value < 35) return new THREE.Color(0xFF0000); // 红色 - 30-35dBZ
        else if (value < 40) return new THREE.Color(0xFF3399); // 粉红 - 35-40dBZ
        else if (value < 45) return new THREE.Color(0xCC00CC); // 紫色 - 40-45dBZ
        else if (value < 50) return new THREE.Color(0x9900CC); // 深紫 - 45-50dBZ
        else if (value < 55) return new THREE.Color(0xFF00FF); // 品红 - 50-55dBZ
        else if (value < 60) return new THREE.Color(0xFF6600); // 橙红色 - 55-60dBZ
        else if (value < 65) return new THREE.Color(0xFF0000); // 鲜红色 - 60-65dBZ
        else if (value < 70) return new THREE.Color(0x990000); // 深红色 - 65-70dBZ
        else return new THREE.Color(0xFFFFFF); // 白色 - 70dBZ以上
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

    // 更新可视化
    updateVisualization(newData, mode = 'refl') {
        if (newData) {
            this.volumeData = newData;
        }
        
        // 这里可以实现更新逻辑
    }
}

// 天气模式生成器
class WeatherPatternGenerator {
    constructor() {
        this.patterns = {};
    }

    // 生成层状云模式
    generateStratiform(x, y, z, size) {
        const data = new Array(size * size * size).fill(0);
        
        for (let k = 0; k < size; k++) {
            for (let j = 0; j < size; j++) {
                for (let i = 0; i < size; i++) {
                    const idx = k * size * size + j * size + i;
                    
                    // 层状云结构 - 较为均匀的分布
                    let baseValue = 15;
                    
                    // 添加大尺度变化
                    baseValue += 10 * Math.sin(i * 0.1) * Math.cos(j * 0.1) * Math.sin(k * 0.05);
                    
                    // 添加小尺度湍流
                    baseValue += 5 * Math.sin(i * 0.5) * Math.cos(j * 0.7) * Math.sin(k * 0.3);
                    
                    data[idx] = Math.max(0, Math.min(80, baseValue));
                }
            }
        }
        
        return data;
    }

    // 生成对流性降水模式
    generateConvective(x, y, z, size) {
        const data = new Array(size * size * size).fill(0);
        
        // 生成多个对流单体
        const numCells = 5 + Math.floor(Math.random() * 5);
        const cells = [];
        
        for (let i = 0; i < numCells; i++) {
            cells.push({
                x: Math.random() * size,
                y: Math.random() * size,
                z: Math.random() * size * 0.7, // 避免在顶部
                strength: 40 + Math.random() * 40,
                size: 5 + Math.random() * 10
            });
        }
        
        for (let k = 0; k < size; k++) {
            for (let j = 0; j < size; j++) {
                for (let i = 0; i < size; i++) {
                    const idx = k * size * size + j * size + i;
                    
                    let value = 0;
                    
                    // 计算到最近对流单体的距离
                    for (const cell of cells) {
                        const dist = Math.sqrt(
                            Math.pow(i - cell.x, 2) + 
                            Math.pow(j - cell.y, 2) + 
                            Math.pow(k - cell.z, 2)
                        );
                        
                        // 使用高斯函数创建单体结构
                        const contribution = cell.strength * Math.exp(-Math.pow(dist, 2) / (2 * Math.pow(cell.size, 2)));
                        value = Math.max(value, contribution);
                    }
                    
                    // 添加一些背景噪声
                    value += (Math.random() - 0.5) * 5;
                    
                    data[idx] = Math.max(0, Math.min(80, value));
                }
            }
        }
        
        return data;
    }

    // 生成飑线模式
    generateSquallLine(x, y, z, size) {
        const data = new Array(size * size * size).fill(0);
        
        // 飑线通常呈现线性结构
        const lineAngle = Math.random() * Math.PI * 2;
        const lineOffset = Math.random() * size;
        
        for (let k = 0; k < size; k++) {
            for (let j = 0; j < size; j++) {
                for (let i = 0; i < size; i++) {
                    const idx = k * size * size + j * size + i;
                    
                    // 计算到飑线的距离
                    const distToLine = Math.abs(
                        Math.cos(lineAngle) * i + 
                        Math.sin(lineAngle) * j - 
                        lineOffset
                    );
                    
                    let value = 0;
                    
                    // 飑线核心区域
                    if (distToLine < 5) {
                        value = 60 * (1 - distToLine / 5);
                        
                        // 垂直发展
                        if (k > size * 0.2) {
                            value *= (k / (size * 0.8));
                        }
                    }
                    
                    // 前沿湍流区
                    if (distToLine > 5 && distToLine < 10) {
                        value = 20 * (1 - (distToLine - 5) / 5);
                    }
                    
                    // 添加一些随机性
                    value += (Math.random() - 0.5) * 10;
                    
                    data[idx] = Math.max(0, Math.min(80, value));
                }
            }
        }
        
        return data;
    }
}

// 水汽笔刷类
class MoistureBrush {
    constructor(radius = 0.02, strength = 10) { // 0.02米 = 2厘米
        this.radius = radius;
        this.strength = strength;
        this.enabled = false;
        this.position = new THREE.Vector3(0, 0, 0);
    }
    
    // 应用水汽笔刷到数据
    applyBrush(volumeData, x, y, z) {
        if (!this.enabled) return;
        
        const { data, size } = volumeData;
        const brushX = Math.floor(this.position.x / (volumeData.resolution || 0.01) + size/2);
        const brushY = Math.floor(this.position.y / (volumeData.resolution || 0.01) + size/2);
        const brushZ = Math.floor(this.position.z / (volumeData.resolution || 0.01) + size/2);
        
        // 计算笔刷影响范围
        const radiusInCells = Math.ceil(this.radius / (volumeData.resolution || 0.01));
        
        for (let k = Math.max(0, brushZ - radiusInCells); k < Math.min(size, brushZ + radiusInCells); k++) {
            for (let j = Math.max(0, brushY - radiusInCells); j < Math.min(size, brushY + radiusInCells); j++) {
                for (let i = Math.max(0, brushX - radiusInCells); i < Math.min(size, brushX + radiusInCells); i++) {
                    const idx = k * size * size + j * size + i;
                    if (idx >= data.length) continue;
                    
                    // 计算到笔刷中心的距离
                    const distX = (i - brushX) * (volumeData.resolution || 0.01);
                    const distY = (j - brushY) * (volumeData.resolution || 0.01);
                    const distZ = (k - brushZ) * (volumeData.resolution || 0.01);
                    const distance = Math.sqrt(distX*distX + distY*distY + distZ*distZ);
                    
                    if (distance <= this.radius) {
                        // 使用高斯分布使边缘更平滑，距离中心越远增加的水汽越少
                        const influence = this.strength * Math.exp(-Math.pow(distance, 2) / (2 * Math.pow(this.radius/3, 2)));
                        // 限制最大水汽值
                        data[idx] = Math.min(80, data[idx] + influence);
                    }
                }
            }
        }
    }
}

// 气象数据模拟器
class MeteorologicalSimulator {
    constructor() {
        this.generator = new WeatherPatternGenerator();
        this.currentTime = 0;
        this.stormTypes = [
            'cumulus', 
            'thunderstorm', 
            'supercell', 
            'hail', 
            'tornado',
            'stratiform',
            'convective',
            'squall'
        ];
        // 设置厘米级分辨率 (0.01米 = 1厘米)
        this.resolution = 0.01;
        // 创建水汽笔刷
        this.moistureBrush = new MoistureBrush(0.02, 5); // 2厘米半径，强度5
    }

    // 获取当前模拟数据
    getCurrentData(stormType, size = 64) {
        let data;
        
        switch(stormType) {
            case 'cumulus':
                data = this.generateCumulusData(size);
                break;
            case 'thunderstorm':
                data = this.generateThunderstormData(size);
                break;
            case 'supercell':
                data = this.generateSupercellData(size);
                break;
            case 'hail':
                data = this.generateHailData(size);
                break;
            case 'tornado':
                data = this.generateTornadoData(size);
                break;
            case 'stratiform':
                data = this.generator.generateStratiform(0, 0, 0, size);
                break;
            case 'convective':
                data = this.generator.generateConvective(0, 0, 0, size);
                break;
            case 'squall':
                data = this.generator.generateSquallLine(0, 0, 0, size);
                break;
            default:
                data = this.generateCumulusData(size);
        }
        
        return {
            data: data,
            size: size,
            x: size,
            y: size,
            z: size,
            timestamp: Date.now(),
            resolution: this.resolution, // 添加分辨率信息
            physical_size: size * this.resolution // 添加物理尺寸信息
        };
    }

    // 生成积云数据
    generateCumulusData(size) {
        const data = new Array(size * size * size).fill(0);
        
        for (let z = 0; z < size; z++) {
            for (let y = 0; y < size; y++) {
                for (let x = 0; x < size; x++) {
                    const idx = z * size * size + y * size + x;
                    
                    // 积云形状
                    const distCenter = Math.sqrt(
                        Math.pow(x - size/2, 2) + 
                        Math.pow(y - size/2, 2) + 
                        Math.pow(z - size/3, 2)
                    );
                    
                    let value = 0;
                    if (distCenter < size / 2.5) {
                        value = 30 * (1 - distCenter / (size / 2.5));
                    }
                    
                    // 添加不规则性
                    const noise = 10 * Math.sin(x * 0.3) * Math.cos(y * 0.2) * Math.sin(z * 0.4);
                    value += noise;
                    
                    data[idx] = Math.max(0, Math.min(80, value));
                }
            }
        }
        
        return data;
    }

    // 生成雷暴数据
    generateThunderstormData(size) {
        const data = new Array(size * size * size).fill(0);
        
        for (let z = 0; z < size; z++) {
            for (let y = 0; y < size; y++) {
                for (let x = 0; x < size; x++) {
                    const idx = z * size * size + y * size + x;
                    
                    // 强对流塔
                    const horizontalDist = Math.sqrt(
                        Math.pow(x - size/2, 2) + 
                        Math.pow(y - size/2, 2)
                    );
                    
                    let value = 0;
                    if (horizontalDist < size / 4 && z > size / 6) {
                        value = 50 * (1 - horizontalDist / (size / 4)) * (z / size);
                    }
                    
                    // 添加湍流
                    const turbulence = 15 * Math.sin(x * 0.5) * Math.cos(y * 0.7) * Math.sin(z * 0.6);
                    value += turbulence;
                    
                    data[idx] = Math.max(0, Math.min(80, value));
                }
            }
        }
        
        return data;
    }

    // 生成超级单体数据
    generateSupercellData(size) {
        const data = new Array(size * size * size).fill(0);
        
        for (let z = 0; z < size; z++) {
            for (let y = 0; y < size; y++) {
                for (let x = 0; x < size; x++) {
                    const idx = z * size * size + y * size + x;
                    
                    // 旋转上升气流
                    const dx = x - size/2;
                    const dy = y - size/2;
                    const angle = Math.atan2(dy, dx);
                    const radius = Math.sqrt(dx * dx + dy * dy);
                    
                    let value = 0;
                    if (radius < size / 3 && z > size / 6) {
                        // 旋转效应
                        const rotationFactor = Math.sin(angle + z * 0.3) * 0.5 + 0.5;
                        value = 60 * (1 - radius / (size / 3)) * (z / size) * rotationFactor;
                    }
                    
                    data[idx] = Math.max(0, Math.min(80, value));
                }
            }
        }
        
        return data;
    }

    // 生成冰雹数据
    generateHailData(size) {
        const data = new Array(size * size * size).fill(0);
        
        for (let z = 0; z < size; z++) {
            for (let y = 0; y < size; y++) {
                for (let x = 0; x < size; x++) {
                    const idx = z * size * size + y * size + x;
                    
                    // 高反射率冰雹核心
                    const coreDist = Math.sqrt(
                        Math.pow(x - size/2, 2) + 
                        Math.pow(y - size/2, 2) + 
                        Math.pow(z - size/2.5, 2)
                    );
                    
                    let value = 0;
                    if (coreDist < size / 6) {
                        value = 70; // 非常高的反射率
                    } else {
                        // 周围的风暴结构
                        const stormDist = Math.sqrt(
                            Math.pow(x - size/2, 2) + 
                            Math.pow(y - size/2, 2)
                        );
                        if (stormDist < size / 2.5 && z > size / 8) {
                            value = 45 * (1 - stormDist / (size / 2.5)) * (z / size);
                        }
                    }
                    
                    data[idx] = Math.max(0, Math.min(80, value));
                }
            }
        }
        
        return data;
    }

    // 生成龙卷风数据
    generateTornadoData(size) {
        const data = new Array(size * size * size).fill(0);
        
        for (let z = 0; z < size; z++) {
            for (let y = 0; y < size; y++) {
                for (let x = 0; x < size; x++) {
                    const idx = z * size * size + y * size + x;
                    
                    // 龙卷风漏斗结构
                    const dx = x - size/2;
                    const dy = y - size/2;
                    const radius = Math.sqrt(dx * dx + dy * dy);
                    const angle = Math.atan2(dy, dx);
                    
                    let value = 0;
                    if (radius < size / 10 && z < size / 2) {
                        // 龙卷风核心
                        const heightFactor = 1 - z / (size / 2);
                        value = 55 * heightFactor;
                        value += 10 * Math.sin(angle + z * 2); // 旋转效果
                    }
                    
                    // 周围的风暴结构
                    if (radius > size / 10 && radius < size / 3 && z < size / 2) {
                        value = 35 * (1 - (radius - size/10) / (size/3 - size/10)) * (1 - z / (size/2));
                    }
                    
                    data[idx] = Math.max(0, Math.min(80, value));
                }
            }
        }
        
        return data;
    }
}

// 初始化可视化器
const volumeVisualizer = new VolumeVisualizer();
volumeVisualizer.init();

// 初始化气象模拟器
const meteorologicalSimulator = new MeteorologicalSimulator();