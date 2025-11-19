# Sandbox Meteor v1.0  
> 移动端 60 FPS 雷暴-生态-政策耦合沙盘 - Real-time Storm-Ecosystem-Policy Sandbox

## 🚀 核心功能

### @ai-nowcast（AI短时预测）
- **LSTM架构**：128参数轻量级模型，支持30分钟预测
- **Informer-Lite注意力机制**：支持2小时中期预测
- **SHAP可解释性**：提供预测结果的可解释性分析

### @gpu-eco（GPU加速）
- **<0.1ms响应时间**：移动端GPU加速计算
- **OpenCL/Vulkan支持**：跨平台GPU计算
- **批量处理**：支持多状态并行计算

### @storyline（叙事模式）- 可选模式
- **多种叙事风格**：科学、诗意、新闻风格
- **动态事件序列**：自动生成生态事件叙事
- **复杂度调节**：支持不同复杂度级别

### @counterfactual（反事实分析）- 可选模式
- **干预模板**：气候、碳、生物多样性等多种干预类型
- **敏感性分析**：评估系统对变化的敏感性
- **情景模拟**："如果...会怎样"的分析能力

## 📱 一键运行（Android）
```bash
./scripts/build-apk.sh   # 输出 apk 在 android-apk/build/outputs/
```

## 📁 目录结构

```
sandbox-radar/        # C++ 核心（AI预测、GPU加速）
├── lib/sandbox-eco/  # 核心生态引擎
│   ├── ai_nowcast.*  # AI预测系统
│   ├── gpu_eco.*     # GPU加速系统
│   ├── storyline_mode.* # 叙事模式
│   ├── counterfactual_mode.* # 反事实分析
│   └── eco_manager.* # 集成管理器
├── sources/components/ # React-Native组件
│   ├── MiniMap.jsx   # 小地图组件
│   └── EcoPolicySlider.jsx # 生态政策滑块
├── assets/data/      # 职业 & 生态 JSON（< 50 kB）
└── scripts/          # 构建 & 测试脚本
```

## 📊 论文数据

```bash
./scripts/export-paper-data.sh  # 生成 data/paper/ 含 NetCDF & CSV
```

## ⚡ 性能指标
- **AI预测**：30分钟预测 <0.21ms，2小时预测 <0.15ms
- **GPU加速**：响应时间 <0.13ms，满足实时要求
- **4096代理人 + 2048云粒子**：0.7 ms / step  
- **包体大小**：< 80 MB（含 LFS）  
- **帧率**：60 FPS 实测 OnePlus 11  
- **生态向量**：64维状态向量，支持多维度分析

## 🛠️ 架构特点

### EcoManager集成系统
- 统一管理AI预测、GPU加速、叙事和反事实分析
- 支持可选模式开关（storyline/counterfactual）
- 自动GPU加速回退到CPU

### 模块化设计
- 独立的AI预测模块
- GPU加速计算模块
- 可插拔的叙事和反事实模块
- 易于扩展和维护

## 📚 引用

```
@software{sandbox_meteor_v1,
  author = {FZZhiQiu},
  title  = {Sandbox Meteor: Real-time Storm-Ecosystem-Policy Sandbox},
  url    = {https://github.com/FZZhiQiu/sandbox-meteor},
  version = {1.0.0},
  year   = {2025}
}
```

## 🏷️ v1.0-storm-eco 特性
- 完整实现雷暴-生态-政策闭环模拟
- 支持移动端60 FPS实时渲染
- 轻量级AI模型，适合边缘计算
- 可解释AI预测系统
- GPU加速计算，性能优化