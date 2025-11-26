# 气象沙盘模拟器

## 项目概述

这是一个基于 Flutter 开发的高性能气象沙盘模拟器，实现了真实气象学原理的数值模拟。项目采用模块化架构，支持实时风场模拟、水汽输送、降水过程、温度场演化等核心气象过程。

## 项目架构

```
project_root/
├── pubspec.yaml                    # 项目依赖配置
├── lib/                            # 源代码目录
│   ├── main.dart                   # 应用入口
│   ├── core/                       # 核心配置
│   │   └── app_config.dart         # 应用配置参数
│   ├── models/                     # 数据模型
│   │   └── meteorology_state.dart  # 气象状态模型
│   ├── controllers/                # 状态控制器
│   │   └── meteorology_controller.dart
│   ├── services/                   # 服务层（算法实现）
│   │   └── meteorology_service.dart
│   ├── render/                     # 渲染系统
│   │   └── meteorology_painter.dart
│   ├── ui/                         # 用户界面
│   │   ├── screens/
│   │   │   └── main_screen.dart    # 主界面
│   │   └── widgets/
│   │       ├── control_panel.dart  # 控制面板
│   │       └── status_bar.dart     # 状态栏
│   ├── utils/                      # 工具类
│   │   └── math_utils.dart         # 数学工具
│   └── data/                       # 数据管理
│       └── data_manager.dart       # 数据管理器
└── assets/                         # 资源文件
    ├── map/                        # 底图资源
    ├── icons/                      # 图例资源
    ├── color_maps/                 # 色卡资源
    └── sample_data/                # 示例数据
        └── initial_state.json      # 初始状态配置
```

## 核心功能

### 1. 气象变量模拟
- **温度场**: 基于热力学方程的温度演化
- **气压场**: 大气压力分布和变化
- **湿度场**: 水汽含量和相对湿度
- **风场**: 三维风场（u, v, w分量）
- **降水**: 基于微物理过程的降水模拟

### 2. 物理过程
- **平流过程**: 各气象变量的水平输送
- **扩散过程**: 湍流和分子扩散
- **热力过程**: 温度场的加热和冷却
- **动力过程**: 风场的动力调整

### 3. 可视化功能
- **实时渲染**: 60 FPS 高性能渲染
- **多变量显示**: 支持切换不同气象变量
- **色彩映射**: 科学标准的色彩方案
- **风场矢量**: 风场方向和强度显示

## 技术特点

### 1. 模块化设计
- **分离关注点**: 模型、视图、控制器分离
- **可扩展性**: 易于添加新的气象过程
- **可维护性**: 清晰的代码结构

### 2. 高性能计算
- **数值方法**: 有限差分方法求解偏微分方程
- **内存管理**: 高效的数据结构
- **渲染优化**: 自定义绘制和缓存机制

### 3. 科学准确性
- **真实参数**: 基于实际大气物理常数
- **标准算法**: 采用成熟的数值天气预报方法
- **单位制**: 统一使用国际单位制

## 安装和运行

### 环境要求
- Flutter SDK >= 3.24.0
- Dart SDK >= 3.3.0
- Android SDK (用于构建APK)

### 安装步骤

1. 克隆项目
```bash
git clone <repository_url>
cd meteorological_sandbox
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
flutter run
```

4. 构建APK
```bash
flutter build apk --release
```

## 使用指南

### 基本操作
1. **启动应用**: 点击"开始"按钮启动模拟
2. **变量切换**: 使用变量选择器切换显示的气象变量
3. **缩放控制**: 使用滑块或按钮调整显示缩放
4. **停止/重置**: 控制模拟的运行状态

### 高级功能
- **参数调节**: 通过配置文件修改模拟参数
- **数据导入**: 支持导入自定义初始状态
- **结果导出**: 保存模拟结果和图像

## 配置说明

### 网格配置 (lib/core/app_config.dart)
```dart
static const int gridNX = 100;  // X方向网格点数
static const int gridNY = 100;  // Y方向网格点数
static const int gridNZ = 20;   // Z方向网格点数
```

### 物理常数
```dart
static const double gravity = 9.81;           // 重力加速度
static const double gasConstant = 287.05;     // 气体常数
static const double specificHeat = 1004.0;    // 定压比热
```

### 模拟参数
```dart
static const double timeStep = 0.1;           // 时间步长
static const int simulationInterval = 3;      // 更新间隔
static const int targetFPS = 60;              // 目标帧率
```

## 数据格式

### 初始状态配置 (assets/sample_data/initial_state.json)
- 网格定义: 网格尺寸和边界
- 初始条件: 温度、气压、湿度、风场
- 扰动设置: 热力扰动、涡度扰动

## 算法说明

### Gemini CLI 协作部分
以下复杂气象算法需要与 Gemini CLI 协作实现：

1. **风场动力学方程**
   - Navier-Stokes方程简化版
   - 地转风平衡
   - 梯度风调整

2. **水汽扩散和对流**
   - 水汽输送方程
   - 对流参数化
   - 云微物理过程

3. **降水形成机制**
   - Kessler微物理方案
   - 碰撞增长过程
   - 相变潜热

4. **锋面动力学**
   - 锋生过程
   - 锋面移动
   - 锋面强度变化

5. **辐射传输**
   - 短波辐射
   - 长波辐射
   - 云辐射相互作用

6. **边界层过程**
   - 湍流参数化
   - 近地面层
   - 边界层高度

## 开发指南

### 添加新气象变量
1. 在 `MeteorologyVariable` 枚举中添加新变量
2. 在渲染器中添加对应的颜色映射
3. 在服务层实现相应的物理过程

### 扩展物理过程
1. 在 `services/` 目录下创建新的服务类
2. 在控制器中集成新的服务
3. 更新UI界面提供控制选项

### 性能优化
1. 使用 `flutter_performance_monitor` 监控性能
2. 优化网格计算算法
3. 实现并行计算（Isolate）

## 故障排除

### 常见问题
1. **模拟不稳定**: 调整时间步长和数值格式
2. **渲染卡顿**: 降低网格分辨率或优化绘制算法
3. **内存不足**: 优化数据结构或使用分块计算

### 调试技巧
1. 使用 `print` 语句输出关键变量
2. 检查数值计算的收敛性
3. 验证物理单位的一致性

## 许可证

本项目采用 MIT 许可证，详见 LICENSE 文件。

## 贡献指南

欢迎提交 Issue 和 Pull Request 来改进项目。

## 联系方式

如有问题或建议，请通过以下方式联系：
- GitHub Issues
- 邮箱: [developer@example.com]

---

**注意**: 本项目仅供教育和研究使用，不应用于实际的天气预报。