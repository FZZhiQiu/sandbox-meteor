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
import subprocess
import re
from pathlib import Path

class MeteorologicalToolkit:
    """气象数据处理工具包"""
    
    def __init__(self):
        self.version = "1.0.0"
        self.author = "FZQ团队"
        self.supported_formats = ['netcdf', 'grib', 'csv', 'json', 'txt']
        self.meteorological_indices = {
            'CAPE': '对流有效位能',
            'K-Index': 'K指数',
            'TT-Index': 'TT指数',
            'LI': '抬升指数',
            'SI': '沙氏指数',
            'PWAT': '可降水量',
            'CIN': '对流抑制能量'
        }
    
    def check_environment(self):
        """检查环境状态"""
        print("🌦️ 气象数据处理工具包环境检查")
        print("="*40)
        
        # Python版本检查
        python_version = sys.version_info
        print(f"✅ Python版本: {python_version.major}.{python_version.minor}.{python_version.micro}")
        
        # 检查可用模块
        available_modules = []
        required_modules = ['os', 'sys', 'json', 'datetime', 'subprocess', 're']
        
        for module in required_modules:
            try:
                __import__(module)
                available_modules.append(module)
                print(f"✅ {module} 模块可用")
            except ImportError:
                print(f"❌ {module} 模块不可用")
        
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
            self.generate_install_commands(unavailable_science)
        
        # 创建工作目录
        work_dir = Path("./meteorological_data")
        work_dir.mkdir(exist_ok=True)
        print(f"📁 工作目录: {work_dir.absolute()}")
        
        return len(unavailable_science) == 0
    
    def generate_install_commands(self, modules):
        """生成安装命令"""
        print("\n📦 安装命令生成:")
        print("="*30)
        
        # pip安装命令
        pip_cmd = f"pip install {' '.join(modules)}"
        print(f"标准安装: {pip_cmd}")
        
        # 国内镜像安装
        mirrors = [
            "https://pypi.tuna.tsinghua.edu.cn/simple",
            "https://mirrors.aliyun.com/pypi/simple/",
            "https://pypi.douban.com/simple/"
        ]
        
        for mirror in mirrors:
            mirror_cmd = f"pip install -i {mirror} {' '.join(modules)}"
            print(f"镜像安装: {mirror_cmd}")
        
        # 分步安装
        for module in modules:
            print(f"单独安装: pip install {module}")
        
        # 离线安装建议
        print("\n📥 离线安装建议:")
        print("1. 下载对应版本的.whl文件")
        print("2. 使用: pip install /path/to/package.whl")
        print("3. 或使用: pip install --no-index --find-links=/path/to/packages package_name")
    
    def create_data_processor_script(self, data_type="netcdf"):
        """创建数据处理器脚本"""
        script_content = f'''#!/usr/bin/env python3
"""
气象数据处理器 - {data_type.upper()}格式
Author: FZQ团队
Generated: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""

import os
import sys
import json
import datetime
from pathlib import Path

class {data_type.title()}Processor:
    """{data_type.upper()}数据处理器"""
    
    def __init__(self):
        self.data_type = "{data_type}"
        self.work_dir = Path("./meteorological_data")
        self.work_dir.mkdir(exist_ok=True)
    
    def read_data(self, file_path):
        """读取{data_type}数据"""
        print(f"📖 读取{self.data_type}文件: {{file_path}}")
        
        if not os.path.exists(file_path):
            print(f"❌ 文件不存在: {{file_path}}")
            return None
        
        # 基础文件读取逻辑
        try:
            with open(file_path, 'rb') as f:
                content = f.read()
                print(f"✅ 成功读取文件，大小: {{len(content)}} 字节")
                return content
        except Exception as e:
            print(f"❌ 读取失败: {{e}}")
            return None
    
    def extract_metadata(self, data):
        """提取元数据"""
        print("🔍 提取元数据...")
        
        # 基础元数据提取
        metadata = {{
            'file_size': len(data) if data else 0,
            'processing_time': datetime.datetime.now().isoformat(),
            'data_type': self.data_type
        }}
        
        print(f"📊 元数据: {{metadata}}")
        return metadata
    
    def calculate_basic_stats(self, data):
        """计算基础统计"""
        print("📈 计算基础统计...")
        
        if not data:
            print("❌ 无数据可分析")
            return {{}}
        
        # 基础统计计算
        stats = {{
            'total_bytes': len(data),
            'estimated_lines': data.count(b'\n'),
            'has_header': b'\n' in data[:1000] if len(data) > 1000 else False
        }}
        
        print(f"📊 基础统计: {{stats}}")
        return stats
    
    def save_results(self, results, output_file):
        """保存结果"""
        output_path = self.work_dir / output_file
        
        try:
            with open(output_path, 'w', encoding='utf-8') as f:
                json.dump(results, f, indent=2, ensure_ascii=False, default=str)
            print(f"💾 结果已保存: {{output_path}}")
            return True
        except Exception as e:
            print(f"❌ 保存失败: {{e}}")
            return False

def main():
    """主函数"""
    processor = {data_type.title()}Processor()
    
    print("🌦️ 气象数据处理器启动")
    print(f"📋 数据类型: {{processor.data_type}}")
    print(f"📁 工作目录: {{processor.work_dir}}")
    
    # 示例处理流程
    data_file = input("请输入数据文件路径: ").strip()
    
    if data_file:
        # 读取数据
        data = processor.read_data(data_file)
        
        if data:
            # 提取元数据
            metadata = processor.extract_metadata(data)
            
            # 计算统计
            stats = processor.calculate_basic_stats(data)
            
            # 保存结果
            results = {{
                'metadata': metadata,
                'statistics': stats
            }}
            
            output_file = f"{{processor.data_type}}_results.json"
            processor.save_results(results, output_file)
    else:
        print("❌ 未提供数据文件路径")

if __name__ == "__main__":
    main()
'''
        
        script_path = Path(f"./meteorological_data/{data_type}_processor.py")
        with open(script_path, 'w', encoding='utf-8') as f:
            f.write(script_content)
        
        # 设置执行权限
        os.chmod(script_path, 0o755)
        print(f"📝 已创建 {data_type} 处理器: {script_path}")
        return script_path
    
    def generate_meteorological_indices_calculator(self):
        """生成气象指数计算器"""
        calculator_content = '''#!/usr/bin/env python3
"""
气象指数计算器
Author: FZQ团队
支持指数: CAPE, K-Index, TT-Index, LI, SI, PWAT, CIN
"""

import json
import datetime
from pathlib import Path

class MeteorologicalIndicesCalculator:
    """气象指数计算器"""
    
    def __init__(self):
        self.indices = {
            'CAPE': self.calculate_cape,
            'K-Index': self.calculate_k_index,
            'TT-Index': self.calculate_tt_index,
            'LI': self.calculate_li,
            'SI': self.calculate_si,
            'PWAT': self.print_pwat,
            'CIN': self.calculate_cin
        }
    
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
        
        result = {
            'CAPE': round(cape, 1),
            'temperature_c': round(t_c, 1),
            'dewpoint_c': round(td_c, 1),
            'pressure_hpa': pressure,
            'classification': self.classify_cape(cape),
            'timestamp': datetime.datetime.now().isoformat()
        }
        
        print(f"📊 CAPE: {cape:.1f} J/kg")
        return result
    
    def classify_cape(self, cape):
        """CAPE分类"""
        if cape < 100:
            return "弱对流"
        elif cape < 1000:
            return "中等对流"
        elif cape < 2500:
            return "强对流"
        elif cape < 4000:
            return "很强对流"
        else:
            return "极端对流"
    
    def calculate_k_index(self, t850, t700, t500, td850):
        """计算K指数"""
        print("📊 计算K-Index...")
        
        k_index = (t850 - t500) + (t850 - td850) - (t700 - t500)
        
        classification = self.classify_k_index(k_index)
        
        result = {
            'K-Index': round(k_index, 1),
            'T850': t850,
            'T700': t700,
            'T500': t500,
            'Td850': td850,
            'classification': classification,
            'timestamp': datetime.datetime.now().isoformat()
        }
        
        print(f"📊 K-Index: {k_index:.1f}")
        return result
    
    def classify_k_index(self, k_index):
        """K指数分类"""
        if k_index < 20:
            return "雷暴可能性很小"
        elif k_index < 25:
            return "孤立雷暴可能"
        elif k_index < 30:
            return " scattered雷暴可能"
        elif k_index < 35:
            return "雷暴可能性中等"
        elif k_index < 40:
            return "雷暴可能性大"
        else:
            return "雷暴可能性很大"
    
    def calculate_tt_index(self, t850, t500, td850):
        """计算TT指数"""
        print("📊 计算TT-Index...")
        
        tt_index = t850 + td850 - 2 * t500
        
        classification = self.classify_tt_index(tt_index)
        
        result = {
            'TT-Index': round(tt_index, 1),
            'T850': t850,
            'T500': t500,
            'Td850': td850,
            'classification': classification,
            'timestamp': datetime.datetime.now().isoformat()
        }
        
        print(f"📊 TT-Index: {tt_index:.1f}")
        return result
    
    def classify_tt_index(self, tt_index):
        """TT指数分类"""
        if tt_index < 44:
            return "无雷暴"
        elif tt_index < 47:
            return "孤立雷暴可能"
        elif tt_index < 50:
            return "scattered雷暴可能"
        elif tt_index < 55:
            return "雷暴可能"
        else:
            return "强雷暴可能"
    
    def calculate_li(self, t500, t700):
        """计算抬升指数"""
        print("📊 计算LI...")
        
        li = t500 - t700
        
        classification = self.classify_li(li)
        
        result = {
            'LI': round(li, 1),
            'T500': t500,
            'T700': t700,
            'classification': classification,
            'timestamp': datetime.datetime.now().isoformat()
        }
        
        print(f"📊 LI: {li:.1f}")
        return result
    
    def classify_li(self, li):
        """LI分类"""
        if li > 8:
            return "非常稳定"
        elif li > 6:
            return "稳定"
        elif li > 4:
            return "中等稳定"
        elif li > 2:
            return "弱不稳定"
        elif li > 0:
            return "不稳定"
        elif li > -4:
            return "很不稳定"
        else:
            return "极度不稳定"
    
    def calculate_si(self, t850, t500, td850):
        """计算沙氏指数"""
        print("📊 计算SI...")
        
        si = t850 - t500 - 9.5
        
        classification = self.classify_si(si)
        
        result = {
            'SI': round(si, 1),
            'T850': t850,
            'T500': t500,
            'Td850': td850,
            'classification': classification,
            'timestamp': datetime.datetime.now().isoformat()
        }
        
        print(f"📊 SI: {si:.1f}")
        return result
    
    def classify_si(self, si):
        """SI分类"""
        if si > 3:
            return "非常稳定"
        elif si > 0:
            return "稳定"
        elif si > -3:
            return "弱不稳定"
        else:
            return "不稳定"
    
    def print_pwat(self, moisture_profile):
        """计算可降水量"""
        print("💧 计算PWAT...")
        
        # 简化的PWAT计算
        if isinstance(moisture_profile, list):
            pwat = sum(moisture_profile) / len(moisture_profile) * 100
        else:
            pwat = moisture_profile
        
        classification = self.classify_pwat(pwat)
        
        result = {
            'PWAT': round(pwat, 1),
            'classification': classification,
            'timestamp': datetime.datetime.now().isoformat()
        }
        
        print(f"📊 PWAT: {pwat:.1f} mm")
        return result
    
    def classify_pwat(self, pwat):
        """PWAT分类"""
        if pwat < 10:
            return "干燥"
        elif pwat < 20:
            return "较干燥"
        elif pwat < 30:
            return "适中"
        elif pwat < 50:
            return "较湿润"
        else:
            return "很湿润"
    
    def calculate_cin(self, t_surface, t_parcel):
        """计算对流抑制能量"""
        print("🛡️ 计算CIN...")
        
        cin = (t_parcel - t_surface) * 1004  # 简化计算
        
        classification = self.classify_cin(cin)
        
        result = {
            'CIN': round(cin, 1),
            'T_surface': t_surface,
            'T_parcel': t_parcel,
            'classification': classification,
            'timestamp': datetime.datetime.now().isoformat()
        }
        
        print(f"📊 CIN: {cin:.1f} J/kg")
        return result
    
    def classify_cin(self, cin):
        """CIN分类"""
        if cin < 50:
            return "弱抑制"
        elif cin < 100:
            return "中等抑制"
        elif cin < 200:
            return "强抑制"
        else:
            return "很强抑制"
    
    def interactive_calculator(self):
        """交互式计算器"""
        print("🌦️ 气象指数交互式计算器")
        print("="*40)
        print("可用指数: {', '.join(self.indices.keys())}")
        
        while True:
            index_name = input("\n请输入要计算的指数名称 (或 'quit' 退出): ").strip()
            
            if index_name.lower() == 'quit':
                print("👋 再见!")
                break
            
            if index_name in self.indices:
                self.calculate_index_interactive(index_name)
            else:
                print(f"❌ 不支持的指数: {index_name}")
    
    def calculate_index_interactive(self, index_name):
        """交互式计算指定指数"""
        print(f"\n🔢 计算 {index_name} 指数")
        
        if index_name == 'CAPE':
            try:
                temp = float(input("输入温度 (K): "))
                dewpoint = float(input("输入露点 (K): "))
                pressure = float(input("输入气压 (hPa): "))
                result = self.calculate_cape(temp, dewpoint, pressure)
            except ValueError:
                print("❌ 输入格式错误")
                return
        
        elif index_name == 'K-Index':
            try:
                t850 = float(input("输入850hPa温度 (°C): "))
                t700 = float(input("输入700hPa温度 (°C): "))
                t500 = float(input("输入500hPa温度 (°C): "))
                td850 = float(input("输入850hPa露点 (°C): "))
                result = self.calculate_k_index(t850, t700, t500, td850)
            except ValueError:
                print("❌ 输入格式错误")
                return
        
        elif index_name == 'TT-Index':
            try:
                t850 = float(input("输入850hPa温度 (°C): "))
                t500 = float(input("输入500hPa温度 (°C): "))
                td850 = float(input("输入850hPa露点 (°C): "))
                result = self.calculate_tt_index(t850, t500, td850)
            except ValueError:
                print("❌ 输入格式错误")
                return
        
        elif index_name == 'LI':
            try:
                t500 = float(input("输入500hPa温度 (°C): "))
                t700 = float(input("输入700hPa温度 (°C): "))
                result = self.calculate_li(t500, t700)
            except ValueError:
                print("❌ 输入格式错误")
                return
        
        elif index_name == 'SI':
            try:
                t850 = float(input("输入850hPa温度 (°C): "))
                t500 = float(input("输入500hPa温度 (°C): "))
                td850 = float(input("输入850hPa露点 (°C): "))
                result = self.calculate_si(t850, t500, td850)
            except ValueError:
                print("❌ 输入格式错误")
                return
        
        elif index_name == 'PWAT':
            try:
                if input("输入湿度值列表吗? (y/n): ").lower() == 'y':
                    moisture_str = input("输入湿度值 (逗号分隔): ")
                    moisture_profile = [float(x.strip()) for x in moisture_str.split(',')]
                else:
                    moisture_profile = float(input("输入单一湿度值: "))
                result = self.print_pwat(moisture_profile)
            except ValueError:
                print("❌ 输入格式错误")
                return
        
        elif index_name == 'CIN':
            try:
                t_surface = float(input("输入地面温度 (K): "))
                t_parcel = float(input("输入气块温度 (K): "))
                result = self.calculate_cin(t_surface, t_parcel)
            except ValueError:
                print("❌ 输入格式错误")
                return
        
        # 保存结果
        self.save_calculation_result(result, index_name)
    
    def save_calculation_result(self, result, index_name):
        """保存计算结果"""
        work_dir = Path("./meteorological_data")
        work_dir.mkdir(exist_ok=True)
        
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{index_name}_{timestamp}.json"
        filepath = work_dir / filename
        
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(result, f, indent=2, ensure_ascii=False, default=str)
            print(f"💾 结果已保存: {filepath}")
        except Exception as e:
            print(f"❌ 保存失败: {e}")

def main():
    """主函数"""
    calculator = MeteorologicalIndicesCalculator()
    
    print("🌦️ 气象指数计算器启动")
    print("📋 支持指数: {', '.join(calculator.indices.keys())}")
    
    calculator.interactive_calculator()

if __name__ == "__main__":
    main()
'''
        
        calculator_path = Path("./meteorological_data/indices_calculator.py")
        with open(calculator_path, 'w', encoding='utf-8') as f:
            f.write(calculator_content)
        
        # 设置执行权限
        os.chmod(calculator_path, 0o755)
        print(f"📝 已创建气象指数计算器: {calculator_path}")
        return calculator_path
    
    def create_sample_data_generator(self):
        """创建示例数据生成器"""
        generator_content = '''#!/usr/bin/env python3
"""
气象数据示例生成器
Author: FZQ团队
"""

import json
import datetime
import random
from pathlib import Path

class MeteorologicalDataGenerator:
    """气象数据生成器"""
    
    def __init__(self):
        self.work_dir = Path("./meteorological_data")
        self.work_dir.mkdir(exist_ok=True)
    
    def generate_synthetic_soundings(self, num_hours=24):
        """生成探空数据"""
        print("🎈 生成探空数据...")
        
        soundings = []
        
        for hour in range(num_hours):
            # 生成高度层
            pressures = [1000, 925, 850, 700, 600, 500, 400, 300, 250, 200]
            
            sounding_data = []
            
            for pressure in pressures:
                # 生成温度 (随高度递减)
                base_temp = 288.15  # 15°C
                temp_lapse = 6.5  # 标准温度递减率
                temp = base_temp - (1000 - pressure) * temp_lapse / 1000
                
                # 添加随机扰动
                temp += random.uniform(-2, 2)
                
                # 生成露点温度
                dewpoint = temp - random.uniform(5, 15)
                
                # 生成风速
                wind_speed = random.uniform(5, 25)
                wind_direction = random.uniform(0, 360)
                
                sounding_data.append({
                    'pressure_hpa': pressure,
                    'temperature_k': round(temp, 2),
                    'dewpoint_k': round(dewpoint, 2),
                    'wind_speed_ms': round(wind_speed, 2),
                    'wind_direction_deg': round(wind_direction, 1),
                    'relative_humidity': round(100 * (2.718 ** ((17.27 * (dewpoint - 273.15)) / (dewpoint - 273.15 + 237.3))), 1)
                })
            
            soundings.append({
                'timestamp': (datetime.datetime.now() + datetime.timedelta(hours=hour)).isoformat(),
                'hour': hour,
                'sounding': sounding_data
            })
        
        return soundings
    
    def generate_surface_observation(self, num_stations=10):
        """生成地面观测数据"""
        print("🌍 生成地面观测数据...")
        
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

def main():
    """主函数"""
    generator = MeteorologicalDataGenerator()
    
    print("🌦️ 气象数据示例生成器启动")
    
    # 生成探空数据
    soundings = generator.generate_synthetic_soundings(24)
    generator.save_data(soundings, 'synthetic_soundings.json')
    
    # 生成地面观测
    observations = generator.generate_surface_observation(10)
    generator.save_data(observations, 'surface_observations.json')
    
    print("✅ 示例数据生成完成")

if __name__ == "__main__":
    main()
'''
        
        generator_path = Path("./meteorological_data/data_generator.py")
        with open(generator_path, 'w', encoding='utf-8') as f:
            f.write(generator_content)
        
        # 设置执行权限
        os.chmod(generator_path, 0o755)
        print(f"📝 已创建数据生成器: {generator_path}")
        return generator_path
    
    def run_demonstration(self):
        """运行演示"""
        print("🌦️ 气象数据处理工具包演示")
        print("="*40)
        
        # 检查环境
        env_ok = self.check_environment()
        
        if not env_ok:
            print("\n⚠️  环境不完整，但基础功能可用")
        
        # 创建处理器
        print("\n📝 创建数据处理器...")
        self.create_data_processor_script("netcdf")
        self.create_data_processor_script("csv")
        
        # 创建计算器
        print("\n📝 创建指数计算器...")
        self.generate_meteorological_indices_calculator()
        
        # 创建数据生成器
        print("\n📝 创建数据生成器...")
        self.create_sample_data_generator()
        
        print("\n✅ 演示完成!")
        print("\n🚀 可用工具:")
        print("1. python meteorological_data/netcdf_processor.py")
        print("2. python meteorological_data/csv_processor.py") 
        print("3. python meteorological_data/indices_calculator.py")
        print("4. python meteorological_data/data_generator.py")
        print("\n💡 提示: 运行上述脚本开始气象数据处理")

def main():
    """主函数"""
    toolkit = MeteorologicalToolkit()
    toolkit.run_demonstration()

if __name__ == "__main__":
    main()
