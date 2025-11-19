# Sandbox Meteor - Web 预览版

本项目是 Sandbox Meteor 气象模拟系统的 Web 预览版本，提供了一个实时的 256x256 像素 MiniMap 可视化界面，包含地形、生态系统水汽和代理人层的综合显示。

## 功能特点

- **实时 MiniMap 可视化**：256x256 像素的高分辨率气象/生态状态显示
- **三层叠加渲染**：地形底图、生态系统水汽层、代理人覆盖层
- **像素级精确渲染**：1:1 网格点到像素映射，无插值
- **生态系统集成**：64 维生态状态向量实时更新
- **代理人系统**：4096 个代理人以 0.5 像素圆形显示
- **政策控制面板**：可调节植被、减排、预算、建造政策

## 技术架构

- **前端**：Vue.js 3 + WebGL2
- **渲染**：WebGL 片段着色器实现三层纹理叠加
- **后端**：C++ 实现核心算法，通过 WASM 集成
- **数据格式**：Uint8 纹理用于高效渲染

## 文件结构

```
web-preview/
├── index.html          # 主页面，包含Vue组件和Canvas
├── preview.js          # WebGL渲染和数据更新逻辑
├── minimap_terrain.h   # 地形层更新接口
├── minimap_terrain.cc  # 地形层实现（陆地/海洋分布）
├── minimap_eco_qv.h    # 生态水汽层接口
├── minimap_eco_qv.cc   # 生态水汽计算实现
├── minimap_agents.h    # 代理人层接口
├── minimap_agents.cc   # 代理人层实现（0.5像素圆形）
├── minimap_agents_wasm.cc # 代理人WASM接口
├── build-agents.sh     # 代理人模块构建脚本
├── build-terrain-eco.sh # 地形/生态模块构建脚本
├── serve.py           # HTTP服务器（支持WASM MIME类型）
└── wasm/              # 预编译的WASM模块
    ├── agents-minimap.wasm
    └── terrain-eco.wasm
```

## 地形层实现

- **陆地颜色**：固定浅绿色 #8FBC8F (值: 143)
- **海洋颜色**：固定浅蓝色 #87CEEB (值: 135)
- **坐标转换**：1000x1000 世界坐标 → 256x256 像素网格，使用 floor(x/4) 量化

## 生态水汽层实现

- **计算公式**：qv_gen = max(0, EcoState[17]*0.01 - EcoState[7]*0.005)
- **对数压缩**：val = log10(qv_gen + 1e-6) * 50，范围裁剪至 0-255
- **动态更新**：基于 64 维生态状态向量实时计算

## 代理人层实现

- **数量**：4096 个代理人
- **显示**：0.5 像素（3x3 区域）圆形
- **颜色**：基于 profession_id % 256 的彩虹色编码
- **坐标转换**：世界坐标 → 256x256 像素网格

## 使用方法

1. 启动本地服务器：
   ```bash
   python3 serve.py
   ```

2. 访问 http://localhost:8000

## 构建说明

项目提供了构建脚本用于编译 WASM 模块：

- `build-agents.sh` - 构建代理人相关功能
- `build-terrain-eco.sh` - 构建地形和生态水汽功能

如果系统未安装 Emscripten，脚本将创建占位符文件以确保项目正常运行。

## 性能特点

- 所有渲染操作在 GPU 上执行
- 纹理更新频率优化（每秒更新一次各层）
- 像素级精确计算，避免插值误差
- 单次渲染调用处理全部三层数据

## 依赖

- Vue.js 3 (CDN)
- WebGL2 兼容浏览器
- 现代 JavaScript (ES6+) 支持

## 未来扩展

- 实时气象数据接入
- 更复杂的生态模型
- 交互式代理人控制
- 多时间步长预测显示