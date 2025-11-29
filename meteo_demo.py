#!/usr/bin/env python3
"""
气象沙盘数据自动化处理工具包演示版
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
        self.save_data(cape_result, 'CAPE_demo.json')
        
        # 示例K指数计算
        print("\n示例K-Index计算:")
        k_result = self.calculate_k_index(20, 10, -15, 15)
        self.save_data(k_result, 'K-Index_demo.json')
        
        # 更多演示数据
        print("\n🎯 生成更多演示数据...")
        
        # 不同天气条件的CAPE计算
        demo_cases = [
            {"name": "冬季稳定大气", "temp": 273.15, "dewpoint": 268.15, "pressure": 1010},
            {"name": "春季不稳定大气", "temp": 288.15, "dewpoint": 280.15, "pressure": 1005},
            {"name": "夏季强对流", "temp": 303.15, "dewpoint": 295.15, "pressure": 995},
            {"name": "秋季中等对流", "temp": 293.15, "dewpoint": 285.15, "pressure": 1000}
        ]
        
        cape_results = []
        for case in demo_cases:
            print(f"\n计算 {case['name']} 的CAPE:")
            result = self.calculate_cape(case['temp'], case['dewpoint'], case['pressure'])
            result['case_name'] = case['name']
            cape_results.append(result)
        
        self.save_data(cape_results, 'CAPE_comparison.json')
        
        # K指数对比
        k_cases = [
            {"name": "稳定条件", "t850": 15, "t700": 5, "t500": -20, "td850": 10},
            {"name": "中等不稳定", "t850": 20, "t700": 10, "t500": -15, "td850": 15},
            {"name": "强不稳定", "t850": 25, "t700": 15, "t500": -10, "td850": 20}
        ]
        
        k_results = []
        for case in k_cases:
            print(f"\n计算 {case['name']} 的K-Index:")
            result = self.calculate_k_index(case['t850'], case['t700'], case['t500'], case['td850'])
            result['case_name'] = case['name']
            k_results.append(result)
        
        self.save_data(k_results, 'K-Index_comparison.json')
        
        # 生成综合报告
        print("\n📋 生成综合报告...")
        report = {
            'toolkit_info': {
                'version': self.version,
                'author': self.author,
                'generation_time': datetime.datetime.now().isoformat()
            },
            'environment_check': {
                'python_version': f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}",
                'working_directory': str(self.work_dir.absolute())
            },
            'demo_results': {
                'sample_data_generated': len(sample_data),
                'cape_calculations': len(cape_results),
                'kindex_calculations': len(k_results)
            },
            'files_created': [
                'sample_observations.json',
                'CAPE_demo.json', 
                'K-Index_demo.json',
                'CAPE_comparison.json',
                'K-Index_comparison.json'
            ]
        }
        
        self.save_data(report, 'demo_report.json')
        
        print("\n✅ 演示完成!")
        print(f"\n📁 数据保存在: {self.work_dir.absolute()}")
        print("\n📄 生成的文件:")
        for filename in report['files_created']:
            filepath = self.work_dir / filename
            if filepath.exists():
                size = filepath.stat().st_size
                print(f"  📄 {filename} ({size} bytes)")
        
        print("\n🚀 工具包功能:")
        print("✅ 环境检查和模块验证")
        print("✅ CAPE对流有效位能计算")
        print("✅ K-Index雷暴指数计算")
        print("✅ 气象数据生成和管理")
        print("✅ 结果保存和格式化输出")
        
        print("\n💡 使用建议:")
        print("1. 安装科学计算模块: pip install numpy xarray netCDF4 pandas matplotlib")
        print("2. 运行交互式版本: python meteo_toolkit.py")
        print("3. 查看生成的数据文件了解输出格式")
        print("4. 基于示例代码开发自定义气象分析功能")

def main():
    """主函数"""
    toolkit = MeteorologicalToolkit()
    
    print("🌦️ 气象数据处理工具包演示版")
    print(f"版本: {toolkit.version}")
    print(f"作者: {toolkit.author}")
    
    # 运行演示
    toolkit.run_demonstration()

if __name__ == "__main__":
    main()