# Sandbox Meteor 60 FPS - 高性能气象模拟应用

## 项目概述

Sandbox Meteor 是一款高级3D天气模拟应用，支持60 FPS渲染，专注于实时气象数据处理与渲染。该应用基于Sandbox Radar技术，为用户提供沉浸式气象模拟体验。

## 核心特性

- **60 FPS渲染**: 采用解耦模拟架构，保持物理精度的同时实现流畅视觉效果
- **高级气象模拟**: 亚格点 0.1 km + 分档微物理 + RRTMG + 火山-海洋-生态-电离层-碳闭环-城市-闪电化学
- **现代化UI**: 简约黑白配色方案，提供清晰、专业的界面体验
- **高性能计算**: 使用C++原生代码实现核心模拟引擎
- **60 FPS / 144 MB / 10 k Agent / 快照误差 < 1e-3**

## 技术规格

- **应用ID**: `com.sandboxradar.meteor`
- **版本**: 3.2.0-60fps
- **API级别**: 最小26 (Android 8.0), 目标34 (Android 14)
- **架构**: 仅arm64-v8a (优化性能和减小体积)
- **渲染性能**: 60 FPS 高帧率渲染

## 技术架构

### 60 FPS特性
- 模拟步长: 3秒 (保持物理精度)
- 渲染帧率: 60 FPS (视觉流畅)
- 双时钟架构: 模拟与渲染线程解耦
- 插值系统: 场数据、Agent位姿、音频参数平滑插值
- 性能优化: 针对移动设备GPU优化的渲染管线
- 原生库: 使用C++实现高性能模拟引擎

### C++原生代码
项目包含高性能C++原生代码，通过JNI接口与Java/Kotlin代码交互：

- **主库**: `sandbox_radar` (共享库)
- **主要模块**: 核心模拟引擎、插值系统
- **特殊模块**: 辐射模块 (`radiation.cc`)、火山模块 (`volcano.cc`)
- **编译选项**: 启用 `-O3` 优化和 `-ffast-math`

### 项目结构
```
android-apk/
├── build.gradle (Project-level)
├── settings.gradle
├── app/
│   └── src/
│       └── main/
│           ├── AndroidManifest.xml
│           ├── java/
│           │   └── com/sandboxradar/meteor/
│           └── res/
└── src/ (原生C++代码)
    ├── core/
    ├── interpolate/
    ├── jni_interface.cc
    ├── radiation.cc
    └── volcano.cc
```

## UI设计特性

- **纯黑白配色**: 所有界面元素采用黑白配色，提供简约专业的视觉体验
- **现代化图标**: 简约大气的应用图标设计
- **清晰布局**: 优化的信息层次和用户交互流程
- **对比度优化**: 确保在各种光照条件下都能清晰阅读

## 项目关系

此项目是 Happy Coder 生态系统的一部分，与主项目结构关系如下：

- `happy/sandbox-meteor`: Android原生高性能气象模拟应用
- `happy/sandbox-radar`: C++核心库，提供模拟引擎
- `happy/sources`: React Native主应用，提供UI和业务逻辑

## 设计理念

Sandbox Meteor 致力于将复杂的气象模拟技术带给普通用户，通过直观的3D可视化和高性能渲染，让用户能够探索和理解大气现象。应用的设计遵循简约主义原则，专注于核心功能，确保用户可以专注于气象模拟本身。