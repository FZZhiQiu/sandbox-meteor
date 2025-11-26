// 底图生成器 - 用于生成包含陆地和海洋的底图
class BaseMapGenerator {
    constructor() {
        // 陆地数据 - 用简单的几何形状模拟陆地
        this.landData = null;
        this.oceanData = null;
        this.resolution = 64; // 与体积数据分辨率一致
    }
    
    // 生成基础底图
    generateBaseMap(size = 64) {
        const map = new Array(size * size).fill(0); // 0表示海洋，1表示陆地
        
        // 创建一些简单的陆地形状
        for (let y = 0; y < size; y++) {
            for (let x = 0; x < size; x++) {
                const idx = y * size + x;
                
                // 创建几个陆地区域
                const dist1 = Math.sqrt(Math.pow(x - size * 0.3, 2) + Math.pow(y - size * 0.3, 2));
                const dist2 = Math.sqrt(Math.pow(x - size * 0.7, 2) + Math.pow(y - size * 0.6, 2));
                const dist3 = Math.sqrt(Math.pow(x - size * 0.5, 2) + Math.pow(y - size * 0.2, 2));
                
                // 用多个圆形创建陆地区域
                if (dist1 < size * 0.15 || dist2 < size * 0.18 || dist3 < size * 0.12) {
                    map[idx] = 1; // 陆地
                } else {
                    map[idx] = 0; // 海洋
                }
            }
        }
        
        return map;
    }
    
    // 生成包含边缘线的底图
    generateBaseMapWithEdges(size = 64) {
        const baseMap = this.generateBaseMap(size);
        const edgeMap = new Array(size * size).fill(0);
        
        // 检测陆地边缘 - 海洋和陆地的交界处
        for (let y = 1; y < size - 1; y++) {
            for (let x = 1; x < size - 1; x++) {
                const idx = y * size + x;
                const center = baseMap[idx];
                
                // 检查周围8个邻居
                let hasOceanNeighbor = false;
                let hasLandNeighbor = false;
                
                for (let dy = -1; dy <= 1; dy++) {
                    for (let dx = -1; dx <= 1; dx++) {
                        if (dy === 0 && dx === 0) continue;
                        
                        const neighborIdx = (y + dy) * size + (x + dx);
                        if (neighborIdx >= 0 && neighborIdx < size * size) {
                            if (baseMap[neighborIdx] === 0) hasOceanNeighbor = true;
                            if (baseMap[neighborIdx] === 1) hasLandNeighbor = true;
                        }
                    }
                }
                
                // 如果是陆地且有海洋邻居，则标记为边缘
                if (center === 1 && hasOceanNeighbor) {
                    edgeMap[idx] = 2; // 边缘线
                } else {
                    edgeMap[idx] = center;
                }
            }
        }
        
        return { baseMap, edgeMap };
    }
    
    // 在3D场景中创建底图可视化
    createBaseMapVisualization(scene, size = 64, scale = 10) {
        // 清除现有的底图对象
        const existingMap = scene.getObjectByName('baseMap');
        if (existingMap) {
            scene.remove(existingMap);
        }
        
        // 清除现有的陆地区域
        const existingLand = scene.getObjectByName('landAreas');
        if (existingLand) {
            scene.remove(existingLand);
        }
        
        // 清除现有的边缘线
        const existingEdges = scene.getObjectByName('landEdges');
        if (existingEdges) {
            scene.remove(existingEdges);
        }
        
        // 清除现有的海洋标签
        const existingLabels = scene.getObjectByName('oceanLabel');
        if (existingLabels) {
            scene.remove(existingLabels);
        }
        
        const { baseMap, edgeMap } = this.generateBaseMapWithEdges(size);
        
        // 创建地面平面（海洋区域）
        const planeGeometry = new THREE.PlaneGeometry(scale, scale);
        const planeMaterial = new THREE.MeshBasicMaterial({ 
            color: 0x003366,  // 更深的蓝色，增强对比度
            side: THREE.DoubleSide,
            wireframe: false,
            transparent: true,
            opacity: 0.95  // 增加透明度以提高可见性
        });
        
        const plane = new THREE.Mesh(planeGeometry, planeMaterial);
        plane.rotation.x = -Math.PI / 2; // 使平面水平
        plane.position.y = -2.1; // 稍微在陆地之下，避免Z-fighting
        plane.name = 'baseMap';
        scene.add(plane);
        
        // 创建陆地区域可视化
        this.createLandAreas(scene, baseMap, size, scale);
        
        // 创建陆地边缘线
        this.createLandEdges(scene, edgeMap, size, scale);
        
        // 创建海洋文字标签
        this.createOceanLabels(scene, size, scale);
        
        return { baseMap, edgeMap, plane };
    }
    
    // 创建陆地区域
    createLandAreas(scene, baseMap, size, scale) {
        // 创建陆地区域点
        const landPoints = [];
        const edgeSpacing = scale / size;
        
        for (let y = 0; y < size; y++) {
            for (let x = 0; x < size; x++) {
                const idx = y * size + x;
                
                if (baseMap[idx] === 1) { // 陆地区域
                    landPoints.push(
                        (x - size/2) * edgeSpacing,
                        -2, // 与海洋平面同一水平
                        (y - size/2) * edgeSpacing
                    );
                }
            }
        }
        
        if (landPoints.length > 0) {
            const geometry = new THREE.BufferGeometry();
            geometry.setAttribute('position', new THREE.Float32BufferAttribute(landPoints, 3));
            
            const material = new THREE.PointsMaterial({
                color: 0x2E8B57, // 更深的绿色，更明显的陆地颜色
                size: 0.25,     // 增大点的尺寸以提高可见性
                sizeAttenuation: false
            });
            
            const landPointsObj = new THREE.Points(geometry, material);
            landPointsObj.name = 'landAreas';
            scene.add(landPointsObj);
        }
    }
    
    // 创建海洋标签
    createOceanLabels(scene, size, scale) {
        // 创建"海洋"文字标签
        const canvas = document.createElement('canvas');
        const context = canvas.getContext('2d');
        canvas.width = 512;
        canvas.height = 128;
        
        // 设置更清晰的文本
        context.fillStyle = 'rgba(255, 255, 255, 0.9)'; // 增加不透明度
        context.font = 'bold 48px Arial'; // 增大字体
        context.textAlign = 'center';
        context.textBaseline = 'middle';
        context.fillText('海洋', canvas.width/2, canvas.height/2);
        
        // 添加边框以提高对比度
        context.strokeStyle = 'rgba(0, 0, 0, 0.8)';
        context.lineWidth = 4;
        context.strokeText('海洋', canvas.width/2, canvas.height/2);
        
        const texture = new THREE.CanvasTexture(canvas);
        texture.minFilter = THREE.LinearFilter; // 改善纹理质量
        
        const material = new THREE.MeshBasicMaterial({ 
            map: texture, 
            transparent: true,
            side: THREE.DoubleSide,
            depthWrite: false  // 避免深度冲突
        });
        
        const geometry = new THREE.PlaneGeometry(scale * 0.6, scale * 0.18); // 增大标签尺寸
        const oceanLabel = new THREE.Mesh(geometry, material);
        oceanLabel.rotation.x = -Math.PI / 2;
        oceanLabel.position.y = -1.85; // 稍高于地面，避免Z-fighting
        oceanLabel.position.x = 0;
        oceanLabel.position.z = 0;
        oceanLabel.name = 'oceanLabel';
        scene.add(oceanLabel);
    }
    
    // 创建陆地边缘线
    createLandEdges(scene, edgeMap, size, scale) {
        const edgePoints = [];
        const edgeSpacing = scale / size;
        
        for (let y = 0; y < size; y++) {
            for (let x = 0; x < size; x++) {
                const idx = y * size + x;
                
                if (edgeMap[idx] === 2) { // 边缘点
                    edgePoints.push(
                        (x - size/2) * edgeSpacing,
                        -1.95, // 稍高于地面
                        (y - size/2) * edgeSpacing
                    );
                }
            }
        }
        
        if (edgePoints.length > 0) {
            const geometry = new THREE.BufferGeometry();
            geometry.setAttribute('position', new THREE.Float32BufferAttribute(edgePoints, 3));
            
            const material = new THREE.PointsMaterial({
                color: 0xFFFF00, // 改为黄色，更明显的边缘线
                size: 0.20,     // 增大尺寸以提高可见性
                sizeAttenuation: false
            });
            
            const edgePointsObj = new THREE.Points(geometry, material);
            edgePointsObj.name = 'landEdges';
            scene.add(edgePointsObj);
        }
    }
    
    // 计算海洋水汽生成
    calculateOceanMoistureGeneration(baseMap, moistureData, dt = 1.0, size = 64) {
        const newMoisture = [...moistureData];
        
        for (let y = 0; y < size; y++) {
            for (let x = 0; x < size; x++) {
                const idx = y * size + x;
                
                // 如果是海洋区域，增加水汽
                if (baseMap[idx] === 0) {
                    // 海洋自产水汽，基于温度和风速的简化模型
                    const baseGenerationRate = 0.15; // 提高基础水汽生成率以更好地可视化
                    const windEffect = 1.0 + Math.random() * 0.5; // 风对蒸发的影响
                    const tempEffect = 1.0 + Math.random() * 0.3; // 温度对蒸发的影响
                    
                    // 在海洋表面层增加水汽
                    for (let z = 0; z < 5 && z < size; z++) { // 在前几层增加水汽
                        const volIdx = z * size * size + idx;
                        if (volIdx < newMoisture.length) {
                            newMoisture[volIdx] += baseGenerationRate * windEffect * tempEffect * dt;
                            // 限制最大水汽含量
                            newMoisture[volIdx] = Math.min(80, newMoisture[volIdx]);
                        }
                    }
                }
            }
        }
        
        return newMoisture;
    }
    
    // 计算风力风速
    calculateWindEffects(baseMap, windU, windV, windW, dt = 1.0, size = 64) {
        // 这里实现风场与地形的交互
        for (let z = 0; z < size; z++) {
            for (let y = 0; y < size; y++) {
                for (let x = 0; x < size; x++) {
                    const idx = z * size * size + y * size + x;
                    const surfaceIdx = y * size + x;
                    
                    // 如果在陆地表面，考虑地形对风的影响
                    if (z === 0 && baseMap[surfaceIdx] === 1) {
                        // 陆地表面摩擦效应
                        windU[idx] *= 0.92; // 减少水平风速
                        windV[idx] *= 0.92;
                        
                        // 地形抬升效应 - 陆地上的垂直运动
                        if (Math.random() < 0.15) { // 随机的小规模上升运动
                            windW[idx] = Math.min(5.0, windW[idx] + 0.15);
                        }
                    }
                }
            }
        }
        
        return { windU, windV, windW };
    }
}

// 创建全局底图生成器实例
const baseMapGenerator = new BaseMapGenerator();