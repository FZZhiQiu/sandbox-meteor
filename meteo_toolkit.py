#!/usr/bin/env python3
"""
气象沙盘数据自动化处理工具包
Author: FZQ团队
Version: 1.0.0
"""

import os
import sys
import json
import datetime
import random
from pathlib import Path

class MeteorologicalToolkit:
    """气象数据处理工具包"""
    
    def __init__(self):
        self.version = "1.0.0"
        self.author = "FZQ团队"
        self.work_dir = Path("./meteorological_data")
        self.work_dir.mkdir(exist_ok=True)
    
    def check_environment(self):
        """检查环境状态"""
        print("🌦️ 气象数据处理工具包环境检查")
        print("="*40)
        
        # Python版本检查
        python_version = sys.version_info
        print(f"✅ Python版本: {python_version.major}.{python_version.minor}.{python_version.micro}")
        
        # 检查科学计算模块
        science_modules = ['numpy', 'xarray', 'netCDF4', 'pandas', 'matplotlib']
        unavailable_science = []
        
        for module in science_modules:
            try:
                __import__(module)
                print(f"✅ {module} 科学计算模块可用")
            except ImportError:
                unavailable_science.append(module)
        
        if unavailable_science:
            print(f"⚠️  需要安装的科学模块: {', '.join(unavailable_science)}")
            print("💡 安装命令: pip install numpy xarray netCDF4 pandas matplotlib")
        
        print(f"📁 工作目录: {self.work_dir.absolute()}")
        return len(unavailable_science) == 0
    
    def calculate_cape(self, temperature, dewpoint, pressure):
        """计算对流有效位能 (简化版)"""
        print("🌪️ 计算CAPE...")
        
        # 简化的CAPE计算公式
        t_c = temperature - 273.15  # 转换为摄氏度
        td_c = dewpoint - 273.15
        
        # 基础CAPE估算 (J/kg)
        if t_c > 25 and td_c > 15:
            cape = 2000 + (t_c - 25) * 100 + (td_c - 15) * 50
        elif t_c > 20 and td_c > 10:
            cape = 1000 + (t_c - 20) * 80 + (td_c - 10) * 40
        else:
            cape = max(0, (t_c - 15) * 50 + (td_c - 5) * 30)
        
        # 分类
        if cape < 100:
            classification = "弱对流"
        elif cape < 1000:
            classification = "中等对流"
        elif cape < 2500:
            classification = "强对流"
        elif cape < 4000:
            classification = "很强对流"
        else:
            classification = "极端对流"
        
        result = {
            'CAPE': round(cape, 1),
            'temperature_c': round(t_c, 1),
            'dewpoint_c': round(td_c, 1),
            'pressure_hpa': pressure,
            'classification': classification,
            'timestamp': datetime.datetime.now().isoformat()
        }
        
        print(f"📊 CAPE: {cape:.1f} J/kg ({classification})")
        return result
    
    def calculate_k_index(self, t850, t700, t500, td850):
        """计算K指数"""
        print("📊 计算K-Index...")
        
        k_index = (t850 - t500) + (t850 - td850) - (t700 - t500)
        
        # 分类
        if k_index < 20:
            classification = "雷暴可能性很小"
        elif k_index < 25:
            classification = "孤立雷暴可能"
        elif k_index < 30:
            classification = "scattered雷暴可能"
        elif k_index < 35:
            classification = "雷暴可能性中等"
        elif k_index < 40:
            classification = "雷暴可能性大"
        else:
            classification = "雷暴可能性很大"
        
        result = {
            'K-Index': round(k_index, 1),
            'T850': t850,
            'T700': t700,
            'T500': t500,
            'Td850': td850,
            'classification': classification,
            'timestamp': datetime.datetime.now().isoformat()
        }
        
        print(f"📊 K-Index: {k_index:.1f} ({classification})")
        return result
    
    def generate_sample_data(self, num_stations=10):
        """生成示例气象数据"""
        print("🌍 生成示例气象数据...")
        
        observations = []
        
        for i in range(num_stations):
            obs = {
                'station_id': f'STATION{i+1:03d}',
                'latitude': round(random.uniform(30, 45), 4),
                'longitude': round(random.uniform(110, 130), 4),
                'timestamp': datetime.datetime.now().isoformat(),
                'temperature_c': round(random.uniform(-10, 35), 1),
                'dewpoint_c': round(random.uniform(-20, 25), 1),
                'pressure_hpa': round(random.uniform(990, 1020), 1),
                'wind_speed_ms': round(random.uniform(0, 20), 1),
                'wind_direction_deg': round(random.uniform(0, 360), 1),
                'humidity_percent': round(random.uniform(20, 95), 1),
                'weather_code': random.choice(['CLR', 'FEW', 'SCT', 'BKN', 'OVC', 'RA', 'SN']),
                'visibility_km': round(random.uniform(1, 10), 1)
            }
            
            observations.append(obs)
        
        return observations
    
    def save_data(self, data, filename):
        """保存数据"""
        filepath = self.work_dir / filename
        
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False, default=str)
            print(f"💾 数据已保存: {filepath}")
            return True
        except Exception as e:
            print(f"❌ 保存失败: {e}")
            return False
    
    def interactive_calculator(self):
        """交互式计算器"""
        print("🌦️ 气象指数交互式计算器")
        print("="*40)
        print("可用指数: CAPE, K-Index")
        
        while True:
            index_name = input("\n请输入要计算的指数名称 (或 'quit' 退出): ").strip()
            
            if index_name.lower() == 'quit':
                print("👋 再见!")
                break
            
            if index_name.upper() == 'CAPE':
                try:
                    temp = float(input("输入温度 (K): "))
                    dewpoint = float(input("输入露点 (K): "))
                    pressure = float(input("输入气压 (hPa): "))
                    result = self.calculate_cape(temp, dewpoint, pressure)
                    self.save_calculation_result(result, 'CAPE')
                except ValueError:
                    print("❌ 输入格式错误")
            
            elif index_name.upper() == 'K-INDEX' or index_name == 'K':
                try:
                    t850 = float(input("输入850hPa温度 (°C): "))
                    t700 = float(input("输入700hPa温度 (°C): "))
                    t500 = float(input("输入500hPa温度 (°C): "))
                    td850 = float(input("输入850hPa露点 (°C): "))
                    result = self.calculate_k_index(t850, t700, t500, td850)
                    self.save_calculation_result(result, 'K-Index')
                except ValueError:
                    print("❌ 输入格式错误")
            
            else:
                print(f"❌ 不支持的指数: {index_name}")
    
    def save_calculation_result(self, result, index_name):
        """保存计算结果"""
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{index_name}_{timestamp}.json"
        self.save_data(result, filename)
    
    def run_demonstration(self):
        """运行演示"""
        print("🌦️ 气象数据处理工具包演示")
        print("="*40)
        
        # 检查环境
        env_ok = self.check_environment()
        
        if not env_ok:
            print("\n⚠️  环境不完整，但基础功能可用")
        
        # 生成示例数据
        print("\n📝 生成示例数据...")
        sample_data = self.generate_sample_data(5)
        self.save_data(sample_data, 'sample_observations.json')
        
        # 演示计算
        print("\n🔬 演示指数计算...")
        
        # 示例CAPE计算
        print("示例CAPE计算:")
        cape_result = self.calculate_cape(298.15, 288.15, 1000)
        self.save_calculation_result(cape_result, 'CAPE_demo')
        
        # 示例K指数计算
        print("\n示例K-Index计算:")
        k_result = self.calculate_k_index(20, 10, -15, 15)
        self.save_calculation_result(k_result, 'K-Index_demo')
        
        print("\n✅ 演示完成!")
        print(f"\n📁 数据保存在: {self.work_dir.absolute()}")
        print("\n🚀 可用功能:")
        print("1. 交互式指数计算")
        print("2. 生成示例气象数据")
        print("3. 数据保存和管理")
        print("\n💡 提示: 输入 'python meteo_toolkit.py' 重新启动")

def main():
    """主函数"""
    toolkit = MeteorologicalToolkit()
    
    print("🌦️ 气象数据处理工具包")
    print(f"版本: {toolkit.version}")
    print(f"作者: {toolkit.author}")
    
    # 运行演示
    toolkit.run_demonstration()
    
    # 启动交互式计算器
    print("\n" + "="*40)
    toolkit.interactive_calculator()

if __name__ == "__main__":
    main()