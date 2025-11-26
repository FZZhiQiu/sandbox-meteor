// 控制模块
document.addEventListener('DOMContentLoaded', function() {
    // 初始化控制
    initControls();
    
    // 设置图层控制事件
    setupLayerControls();
    
    // 设置风暴类型按钮事件
    setupStormTypeButtons();
    
    // 设置参数滑块事件
    setupParameterSliders();
    
    // 设置工具按钮事件
    setupToolButtons();
    
    // 设置视图控制按钮事件
    setupViewControls();
    
    // 初始化dat.GUI控制
    initGUIControls();
    
    // 设置画布点击事件以支持笔刷
    setupCanvasInteraction();
    
    // 设置移动端触摸事件
    setupTouchEvents();
});

// 设置图层控制事件
function setupLayerControls() {
    const layerOptions = document.querySelectorAll('.layer-option');
    layerOptions.forEach(option => {
        option.addEventListener('click', function() {
            // 移除所有活动状态
            layerOptions.forEach(opt => opt.classList.remove('active'));
            
            // 添加活动状态到当前项
            this.classList.add('active');
            
            // 获取图层数据属性并更新显示
            const layerType = this.dataset.layer;
            let mode;
            if (layerType === 'reflectivity') {
                mode = 'refl';
            } else if (layerType === 'velocity') {
                mode = 'vel';
            } else if (layerType === 'spectrum') {
                mode = 'sw';
            }
            
            // 更新雷达模式
            if (mode && window.stormSystem) {
                window.stormSystem.setMode(mode);
            }
        });
    });
}

// 设置视图控制按钮
function setupViewControls() {
    const resetViewBtn = document.getElementById('reset-view-btn');
    resetViewBtn.addEventListener('click', function() {
        if (window.camera) {
            window.camera.position.set(0, 2, 5);
            window.camera.lookAt(0, 0, 0);
        }
    });
    
    const autoRotateBtn = document.getElementById('auto-rotate-btn');
    autoRotateBtn.addEventListener('click', function() {
        if (window.meteorControls) {
            window.meteorControls.autoRotate = !window.meteorControls.autoRotate;
            this.textContent = window.meteorControls.autoRotate ? '↻' : '↻';
        }
    });
    
    const fullscreenBtn = document.getElementById('fullscreen-btn');
    if (fullscreenBtn) {
        fullscreenBtn.addEventListener('click', function() {
            const elem = document.getElementById('main-view');
            if (elem.requestFullscreen) {
                elem.requestFullscreen();
            } else if (elem.mozRequestFullScreen) { /* Firefox */
                elem.mozRequestFullScreen();
            } else if (elem.webkitRequestFullscreen) { /* Chrome, Safari & Opera */
                elem.webkitRequestFullscreen();
            } else if (elem.msRequestFullscreen) { /* IE/Edge */
                elem.msRequestFullscreen();
            }
        });
    }
}

// 设置移动端触摸事件
function setupTouchEvents() {
    // 为移动端添加触摸支持
    const canvas = document.getElementById('webgl-canvas');
    
    // 简单的触摸事件处理
    canvas.addEventListener('touchstart', function(e) {
        // 在移动端启用笔刷时处理触摸
        if (window.meteorologicalSimulator && 
            window.meteorologicalSimulator.moistureBrush && 
            window.meteorologicalSimulator.moistureBrush.enabled) {
            
            const touch = e.touches[0];
            const mouseEvent = new MouseEvent('click', {
                clientX: touch.clientX,
                clientY: touch.clientY
            });
            canvas.dispatchEvent(mouseEvent);
        }
    }, { passive: true });
    
    // 确保移动端可以滚动
    const controlPanel = document.getElementById('control-panel');
    if (controlPanel) {
        controlPanel.addEventListener('touchstart', function(e) {
            // 允许面板内容滚动
            console.log('Touch started on control panel');
        }, { passive: true });
    }
}

// 设置设置按钮事件
document.addEventListener('DOMContentLoaded', function() {
    const settingsBtn = document.getElementById('settings-btn');
    if (settingsBtn) {
        settingsBtn.addEventListener('click', function() {
            // 这里可以打开设置面板或显示设置菜单
            alert('设置功能正在开发中...');
            console.log('Settings button clicked');
        });
    }
});

// 初始化控制
function initControls() {
    // 设置默认值（如果元素存在）
    const tempElement = document.getElementById('temperature');
    if (tempElement) tempElement.value = 20;
    
    const humidityElement = document.getElementById('humidity');
    if (humidityElement) humidityElement.value = 60;
    
    const pressureElement = document.getElementById('pressure');
    if (pressureElement) pressureElement.value = 1013;
    
    const windSpeedElement = document.getElementById('wind-speed-ctrl');
    if (windSpeedElement) windSpeedElement.value = 10;
}

// 设置风暴类型按钮
function setupStormTypeButtons() {
    const stormButtons = document.querySelectorAll('.preset-btn');
    stormButtons.forEach(button => {
        button.addEventListener('click', function() {
            // 更新活动按钮
            document.querySelectorAll('.preset-btn').forEach(btn => {
                btn.classList.remove('active');
            });
            this.classList.add('active');
            
            // 生成新的体积数据
            const stormType = this.dataset.type;
            generateNewVolumeData(stormType);
            
            // 更新风暴类型显示
            updateStormTypeDisplay(stormType);
        });
    });
}

// 设置雷达模式按钮
function setupRadarModeButtons() {
    const modeButtons = document.querySelectorAll('.mode-btn');
    modeButtons.forEach(button => {
        button.addEventListener('click', function() {
            // 更新活动按钮
            document.querySelectorAll('.mode-btn').forEach(btn => {
                btn.classList.remove('active');
            });
            this.classList.add('active');
            
            // 获取模式
            const mode = this.dataset.mode;
            
            // 更新可视化
            if (stormSystem) {
                stormSystem.setMode(mode);
            }
            
            // 更新雷达模式显示
            updateRadarModeDisplay(mode);
        });
    });
}

// 设置参数滑块
function setupParameterSliders() {
    // 温度滑块
    const tempSlider = document.getElementById('temp-slider');
    const tempValue = document.getElementById('temp-value');
    tempSlider.addEventListener('input', function() {
        updateParameterDisplay('temperature', this.value + '°C');
        if (tempValue) tempValue.textContent = this.value + '°C';
    });
    
    // 湿度滑块
    const humiditySlider = document.getElementById('humid-slider');
    const humidValue = document.getElementById('humid-value');
    humiditySlider.addEventListener('input', function() {
        updateParameterDisplay('humidity', this.value + '%');
        if (humidValue) humidValue.textContent = this.value + '%';
    });
    
    // 水汽滑块
    const moistureSlider = document.getElementById('moist-slider');
    const moistValue = document.getElementById('moist-value');
    moistureSlider.addEventListener('input', function() {
        updateParameterDisplay('moisture', this.value + '%');
        if (moistValue) moistValue.textContent = this.value + '%';
    });
}

// 更新参数显示
function updateParameterDisplay(param, value) {
    // 在实际应用中，这里会更新模型参数
    // 暂时只更新显示
    console.log(`${param} updated to ${value}`);
}

// 生成新的体积数据
function generateNewVolumeData(stormType) {
    // 使用气象模拟器生成新数据
    const newData = meteorologicalSimulator.getCurrentData(stormType, 64);
    
    // 更新体积数据
    if (stormSystem) {
        stormSystem.updateData(newData);
    }
    
    // 更新全局体积数据
    volumeData = newData;
    
    console.log(`Generated new data for storm type: ${stormType}`);
}

// 更新风暴类型显示
function updateStormTypeDisplay(stormType) {
    let description = '';
    switch(stormType) {
        case 'cumulus':
            description = '积云 - 对流发展初期';
            break;
        case 'thunderstorm':
            description = '雷暴 - 强对流天气';
            break;
        case 'supercell':
            description = '超级单体 - 旋转风暴结构';
            break;
        case 'hail':
            description = '冰雹 - 高反射率核心';
            break;
        case 'tornado':
            description = '龙卷风 - 强烈旋转特征';
            break;
        case 'stratiform':
            description = '层状云 - 大范围层状降水';
            break;
        case 'convective':
            description = '对流性降水 - 分布式对流';
            break;
        case 'squall':
            description = '飑线 - 线性对流系统';
            break;
        default:
            description = '未知风暴类型';
    }
    
    document.getElementById('storm-type').textContent = description;
}

// 更新雷达模式显示
function updateRadarModeDisplay(mode) {
    let description = '';
    switch(mode) {
        case 'refl':
            description = '反射率 (dBZ)';
            break;
        case 'vel':
            description = '多普勒速度 (m/s)';
            break;
        case 'sw':
            description = '谱宽 (m/s)';
            break;
        case 'zdr':
            description = '差分反射率';
            break;
        case 'cc':
            description = '相关系数';
            break;
        case 'kdp':
            description = '比差分相位';
            break;
        default:
            description = '未知模式';
    }
    
    document.getElementById('reflectivity').textContent = description;
}

// 设置工具按钮事件
function setupToolButtons() {
    const moistureBrushBtn = document.getElementById('moisture-brush-btn');
    if (moistureBrushBtn) {
        moistureBrushBtn.addEventListener('click', function() {
            // 切换笔刷启用状态
            if (window.meteorologicalSimulator && window.meteorologicalSimulator.moistureBrush) {
                window.meteorologicalSimulator.moistureBrush.enabled = !window.meteorologicalSimulator.moistureBrush.enabled;
                
                if (window.meteorologicalSimulator.moistureBrush.enabled) {
                    this.classList.add('active');
                    // 更新按钮文本或状态
                    const toolText = this.querySelector('.tool-text');
                    if (toolText) toolText.textContent = '水汽笔刷 (启用)';
                } else {
                    this.classList.remove('active');
                    const toolText = this.querySelector('.tool-text');
                    if (toolText) toolText.textContent = '水汽笔刷';
                }
            } else {
                console.log('Meteorological simulator or moisture brush not initialized');
            }
        });
    }
}

// 设置画布交互事件
function setupCanvasInteraction() {
    const canvas = document.getElementById('webgl-canvas');
    
    canvas.addEventListener('click', function(event) {
        if (!window.meteorologicalSimulator || 
            !window.meteorologicalSimulator.moistureBrush || 
            !window.meteorologicalSimulator.moistureBrush.enabled) {
            return;
        }
        
        // 获取鼠标位置相对于画布的坐标
        const rect = canvas.getBoundingClientRect();
        const mouseX = ((event.clientX - rect.left) / rect.width) * 2 - 1;
        const mouseY = -((event.clientY - rect.top) / rect.height) * 2 + 1;
        
        // 创建射线以确定3D位置
        const vector = new THREE.Vector3(mouseX, mouseY, 1);
        vector.unproject(window.camera);
        const dir = vector.sub(window.camera.position).normalize();
        const distance = 2; // 设置一个固定距离，因为我们知道风暴大致在场景中心
        const pos = window.camera.position.clone().add(dir.multiplyScalar(distance));
        
        // 设置笔刷位置
        window.meteorologicalSimulator.moistureBrush.position.copy(pos);
        
        // 应用笔刷到当前体积数据
        if (window.volumeData) {
            window.meteorologicalSimulator.moistureBrush.applyBrush(window.volumeData, pos.x, pos.y, pos.z);
            
            // 更新可视化
            if (window.stormSystem) {
                window.stormSystem.updateData(window.volumeData);
            }
        }
    });
}

// 初始化dat.GUI控制
function initGUIControls() {
    const gui = new dat.GUI({ autoPlace: false });
    const guiContainer = document.getElementById('gui-container');
    guiContainer.appendChild(gui.domElement);
    
    // 控制对象
    const controls = {
        rotationSpeed: 0.1,
        pointSize: 0.3,
        opacity: 0.7,
        threshold: 15,
        autoRotate: true,
        resetView: function() {
            camera.position.set(0, 10, 30);
            camera.lookAt(0, 0, 0);
        }
    };
    
    // 添加控制项
    gui.add(controls, 'rotationSpeed', 0, 0.5).name('旋转速度');
    gui.add(controls, 'pointSize', 0.1, 1.0).name('点大小');
    gui.add(controls, 'opacity', 0.1, 1.0).name('透明度');
    gui.add(controls, 'threshold', 0, 50).name('阈值');
    gui.add(controls, 'autoRotate').name('自动旋转');
    gui.add(controls, 'resetView').name('重置视角');
    
    // 添加性能监控
    const perfFolder = gui.addFolder('性能');
    perfFolder.add({ 'FPS': 60 }, 'FPS').listen().name('帧率');
    perfFolder.add({ '点数量': 0 }, '点数量').listen().name('渲染点数');
    perfFolder.open();
    
    // 保存对控制的引用以便在动画循环中使用
    window.meteorControls = controls;
}

// 更新控制信息
function updateControlInfo() {
    if (window.meteorControls && stormSystem && stormSystem.volumeMeshes) {
        // 更新性能信息
        document.querySelector('.fps-display') && 
            (document.querySelector('.fps-display').textContent = 
                `FPS: ${Math.floor(60)}`); // 简化的FPS显示
        
        // 更新点数量
        document.querySelector('.points-display') && 
            (document.querySelector('.points-display').textContent = 
                `点数: ${stormSystem.volumeMeshes.length}`);
    }
}

// 实时更新控制
function updateControls() {
    // 如果有控制引用，应用设置
    if (window.meteorControls) {
        // 应用旋转速度
        if (stormSystem) {
            stormSystem.group.rotation.y += window.meteorControls.rotationSpeed * 0.1;
        }
        
        // 应用自动旋转
        if (window.meteorControls.autoRotate && stormSystem) {
            stormSystem.group.rotation.y += 0.005;
        }
        
        // 更新控制信息
        updateControlInfo();
    }
}

// 更新动画循环中的控制
const originalAnimate = animate;
animate = function() {
    // 执行原始动画
    if (typeof originalAnimate === 'function') {
        originalAnimate();
    }
    
    // 更新控制
    updateControls();
};