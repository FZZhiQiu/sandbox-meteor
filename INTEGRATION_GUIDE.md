# Gemini CLI 算法集成指南

## 概述

本指南说明如何将 Gemini CLI 返回的气象算法集成到 Flutter 气象沙盘项目中。所有求解器框架已准备就绪，只需将具体算法替换相应的 TODO 部分。

## 集成流程

### 步骤 1：获取 Gemini CLI 算法

1. 将 `GEMINI_ALGORITHM_REQUEST.md` 的内容提交给 Gemini CLI
2. 获取完整的数学公式和数值算法
3. 确保输出包含所有6个模块的详细实现

### 步骤 2：算法转换

将 Gemini CLI 返回的算法按以下方式转换：

#### 数学公式 → Dart 代码
```dart
// Gemini 输出：∂u/∂t = -1/ρ ∂p/∂x + fv
// 转换为：
final dpdx = (pressure[k][j][i+1] - pressure[k][j][i-1]) / (2 * dx);
final coriolisU = f * vWind[k][j][i];
final newUWind = uWind[k][j][i] + dt * (-dpdx / 1000.0 + coriolisU);
```

#### 伪代码 → 实际实现
```dart
// Gemini 输出伪代码：
// for each grid point:
//   calculate gradient
//   apply boundary condition
//   update with time step

// 转换为：
for (int k = 1; k < nz - 1; k++) {
  for (int j = 1; j < ny - 1; j++) {
    for (int i = 1; i < nx - 1; i++) {
      // 具体计算逻辑
    }
  }
}
```

### 步骤 3：模块集成

#### 3.1 风场求解器 (wind_solver.dart)
**替换位置：** `solveWindField()` 方法中的 TODO 部分
**关键集成点：**
- 气压梯度力计算
- 科里奥利力计算
- 平流项计算
- 湍流粘性项
- 边界条件应用

#### 3.2 水汽扩散服务 (diffusion_service.dart)
**替换位置：** `solveDiffusion()` 方法中的 TODO 部分
**关键集成点：**
- 平流项离散化
- 扩散项计算
- 对流触发机制
- 饱和约束条件

#### 3.3 降水求解器 (precipitation_solver.dart)
**替换位置：** `_calculateMicrophysicsProcesses()` 方法
**关键集成点：**
- Kessler微物理过程
- 自动转化率计算
- 碰并过程
- 雨水下沉计算

#### 3.4 锋面求解器 (fronts_solver.dart)
**替换位置：** `_calculateFrontogenesisField()` 方法
**关键集成点：**
- 锋生函数计算
- 锋面识别算法
- 锋面移动速度
- 锋面强度计算

#### 3.5 辐射求解器 (radiation_solver.dart)
**替换位置：** `_calculateShortWaveRadiation()` 和 `_calculateLongWaveRadiation()` 方法
**关键集成点：**
- 太阳高度角计算
- 大气透过率计算
- 辐射加热率
- 云辐射相互作用

#### 3.6 边界层求解器 (boundary_layer_solver.dart)
**替换位置：** `_calculateStabilityFunction()` 方法
**关键集成点：**
- M-O相似理论实现
- 稳定性函数计算
- 湍流交换系数
- 边界层高度确定

### 步骤 4：验证和测试

#### 4.1 数值稳定性检查
```dart
// 每个求解器都有 checkStability() 方法
final stabilityStatus = meteorologyService.getStabilityStatus();
print('Stability status: $stabilityStatus');
```

#### 4.2 物理合理性验证
- 温度范围：150K - 350K
- 气压范围：500hPa - 1100hPa
- 风速范围：0 - 100 m/s
- 湿度范围：0% - 100%

#### 4.3 质量守恒检查
- 水物质总量守恒
- 能量平衡验证
- 动量守恒检查

### 步骤 5：性能优化

#### 5.1 内存优化
```dart
// 使用预分配数组避免频繁内存分配
final tempArray = List.generate(nz, (k) => 
    List.generate(ny, (j) => List.filled(nx, 0.0)));
```

#### 5.2 计算优化
```dart
// 避免重复计算
final temp = temperature[k][j][i];
final press = pressure[k][j][i];
// 多次使用 temp 和 press
```

#### 5.3 并行化考虑
- 为未来的 Isolate 实现预留接口
- 确保算法可并行化

## 常见问题和解决方案

### Q1: 数值不稳定
**症状：** 模拟结果发散或产生异常值
**解决方案：**
- 检查 CFL 条件
- 减小时间步长
- 增加数值扩散

### Q2: 物理不合理
**症状：** 温度、湿度超出合理范围
**解决方案：**
- 添加物理约束
- 检查单位一致性
- 验证边界条件

### Q3: 性能问题
**症状：** 模拟运行缓慢
**解决方案：**
- 优化网格循环
- 减少不必要的计算
- 使用高效的数据结构

## 集成检查清单

- [ ] 所有 6 个求解器的 TODO 部分已替换
- [ ] 数值稳定性检查通过
- [ ] 物理合理性验证通过
- [ ] 质量守恒检查通过
- [ ] 性能测试满足要求
- [ ] 边界条件正确应用
- [ ] 单位换算正确
- [ ] 内存泄漏检查通过

## 调试工具

### 1. 日志输出
```dart
print('Wind field max speed: $maxWindSpeed');
print('Temperature range: $minTemp - $maxTemp');
```

### 2. 中间结果检查
```dart
// 保存中间状态用于分析
if (step % 100 == 0) {
  _saveIntermediateState(step);
}
```

### 3. 可视化调试
- 使用渲染器显示中间结果
- 检查各变量的空间分布
- 验证时间演化趋势

## 后续优化方向

1. **算法优化**
   - 更高阶的数值格式
   - 自适应时间步长
   - 多尺度方法

2. **性能提升**
   - GPU 加速计算
   - 并行计算实现
   - 内存访问优化

3. **物理完善**
   - 更复杂的微物理过程
   - 地形效应考虑
   - 海陆风模拟

## 技术支持

如果在集成过程中遇到问题：
1. 检查数学公式的正确转换
2. 验证数值离散化的准确性
3. 确认边界条件的合理设置
4. 测试简化版本的算法

确保每个模块的集成都经过充分测试后再进行下一步集成工作。