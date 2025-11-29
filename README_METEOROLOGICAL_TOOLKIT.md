# 气象沙盘数据自动化处理工具包

## 🌦️ 概述

专业级气象数据处理工具包，支持Termux环境下的气象指数计算、数据生成和分析功能。

**版本**: 1.0.0  
**作者**: FZQ团队  
**Python要求**: 3.6+

## 🚀 快速开始

### 1. 运行演示版
```bash
python meteo_demo.py
```

### 2. 运行交互式版本
```bash
python meteo_toolkit.py
```

## 📊 支持的气象指数

### CAPE (对流有效位能)
- 计算公式：基于温度、露点、气压的简化算法
- 单位：J/kg
- 分类：弱对流、中等对流、强对流、很强对流、极端对流

### K-Index (K指数)
- 计算公式：(T850 - T500) + (T850 - Td850) - (T700 - T500)
- 单位：°C
- 用途：雷暴可能性评估

## 🛠️ 环境要求

### 基础环境
- Python 3.6+
- 标准库：os, sys, json, datetime, pathlib

### 推荐科学计算模块
```bash
pip install numpy xarray netCDF4 pandas matplotlib
```

### 国内镜像安装
```bash
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple numpy xarray netCDF4 pandas matplotlib
```

## 📁 文件结构

```
meteorological_data/
├── sample_observations.json     # 示例地面观测数据
├── CAPE_demo.json              # CAPE计算示例
├── K-Index_demo.json           # K指数计算示例
├── CAPE_comparison.json        # CAPE对比数据
├── K-Index_comparison.json     # K指数对比数据
└── demo_report.json            # 演示综合报告
```

## 💡 使用示例

### 1. CAPE计算
```python
from meteo_toolkit import MeteorologicalToolkit

toolkit = MeteorologicalToolkit()
result = toolkit.calculate_cape(298.15, 288.15, 1000)
print(f"CAPE: {result['CAPE']} J/kg")
```

### 2. K-Index计算
```python
result = toolkit.calculate_k_index(20, 10, -15, 15)
print(f"K-Index: {result['K-Index']}")
```

### 3. 生成示例数据
```python
data = toolkit.generate_sample_data(10)
toolkit.save_data(data, 'my_observations.json')
```

## 📈 输出格式

所有计算结果都保存为JSON格式，包含：
- 计算值和单位
- 分类或解释
- 输入参数
- 时间戳

## 🔧 扩展功能

工具包设计为模块化架构，可以轻松扩展：
- 添加新的气象指数计算
- 支持更多数据格式
- 集成外部数据源
- 自定义输出格式

## 📋 功能特性

✅ **环境检查** - 自动检测Python版本和可用模块  
✅ **指数计算** - CAPE、K-Index等专业气象指数  
✅ **数据生成** - 生成示例气象观测数据  
✅ **结果保存** - JSON格式保存计算结果  
✅ **错误处理** - 完善的异常处理机制  
✅ **中文支持** - 完整的中文界面和输出  

## 🎯 适用场景

- 气象教学和科研
- 天气分析和预报
- 数据处理脚本开发
- Termux移动端气象应用
- 气象数据可视化预处理

## 📞 技术支持

如有问题或建议，请联系FZQ团队。

---

*本工具包为气象沙盘模拟器项目的配套工具，提供专业的气象数据处理能力。*