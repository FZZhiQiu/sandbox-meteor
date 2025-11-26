# API 文档

## JNI API 列表

### SimulationController 类

#### nativeInit()
初始化模拟核心系统

**参数**: 无  
**返回值**: void  
**说明**: 初始化气象模拟核心，准备进行模拟计算

#### nativeAddMoistureInjection(float x, float y, float z, float intensity, float lift_height)
添加水汽注入到模拟空间

**参数**:  
- x: 注入点X坐标
- y: 注入点Y坐标  
- z: 注入点Z坐标
- intensity: 注入强度
- lift_height: 抬升高度

**返回值**: void  
**说明**: 在指定位置添加水汽，可影响局部对流发展

#### nativeUpdate(float delta_time)
执行模拟步骤

**参数**:  
- delta_time: 时间步长

**返回值**: void  
**说明**: 执行一个模拟步骤，推进系统状态

#### nativeGetRainfall()
获取当前降雨量

**参数**: 无  
**返回值**: float - 当前降雨量  
**说明**: 返回模拟区域的平均降雨量

#### nativeGetResources()
获取当前资源量

**参数**: 无  
**返回值**: int - 资源量  
**说明**: 返回当前可用资源量

#### nativeGetStatus()
获取模拟状态

**参数**: 无  
**返回值**: String - 状态描述  
**说明**: 返回当前模拟系统的状态描述

#### nativeIsEmergency()
检查是否为紧急状态

**参数**: 无  
**返回值**: boolean - 是否为紧急状态  
**说明**: 检查系统是否处于紧急状态

## C++ 核心模块 API

### MeteorCore 类

#### Initialize()
初始化气象核心系统

#### Step()
执行一个模拟步骤

#### GetGrid()
获取网格数据

#### GetSimTime()
获取模拟时间

### SimLoop 类

#### Start()
启动模拟循环（3秒间隔）

#### Stop()
停止模拟循环

#### GetSimTime()
获取当前模拟时间

#### GetGridData(float* output_data)
获取网格数据

#### HasNewData()
检查是否有新数据

### RenderLoop 类

#### Start()
启动渲染循环（60 FPS）

#### Stop()
停止渲染循环

#### GetFrameTime()
获取帧时间

#### IsRendering()
检查是否在渲染

### 插值系统 API

#### FieldInterpolator::Interpolate()
场数据插值

#### AgentInterpolator::InterpolateAgents()
代理位置插值

#### AudioInterpolator::InterpolateAudioParams()
音频参数插值

## Web 控制 API

### MeteorologicalSimulator 类

#### getCurrentData(stormType, size)
获取当前模拟数据

**参数**:  
- stormType: 风暴类型
- size: 数据网格大小

**返回**: 包含数据和元信息的对象

### VolumeVisualizer 类

#### createVolumeVisualization(data, mode)
创建体积数据可视化

**参数**:  
- data: 体积数据
- mode: 可视化模式（反射率、速度等）

**返回**: Three.js对象组

### MoistureBrush 类

#### applyBrush(volumeData, x, y, z)
应用水汽笔刷

## Android 侧控制接口

### MainActivity.kt
主要应用入口点

### MainApplication.kt
应用配置和初始化

### SimulationController.java
JNI接口控制器