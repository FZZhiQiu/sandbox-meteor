#!/usr/bin/env python3
"""
气象数据处理器 - 利用新工具链
"""

import json
import sqlite3
import subprocess
import sys
from pathlib import Path
from datetime import datetime, timedelta

class MeteoDataProcessor:
    def __init__(self, db_path="meteorological_data.db"):
        self.db_path = db_path
        self.conn = sqlite3.connect(db_path)
        self.cursor = self.conn.cursor()
        self.init_database()
    
    def init_database(self):
        """初始化数据库表"""
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS weather_data (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                temperature REAL,
                humidity REAL,
                pressure REAL,
                wind_speed REAL,
                wind_direction TEXT,
                location TEXT DEFAULT '气象沙盘模拟器'
            )
        ''')
        self.conn.commit()
    
    def fetch_api_data(self):
        """从气象 API 获取数据"""
        try:
            result = subprocess.run(
                ['curl', '-s', 'http://localhost:3000/weather'],
                capture_output=True, text=True, check=True
            )
            data = json.loads(result.stdout)
            return data
        except Exception as e:
            print(f"获取 API 数据失败: {e}")
            return None
    
    def process_with_jq(self, data):
        """使用 jq 处理 JSON 数据"""
        try:
            # 提取关键气象数据
            temp = data.get('temperature', 0)
            humidity = data.get('humidity', 0)
            pressure = data.get('pressure', 0)
            wind_speed = data.get('windSpeed', 0)
            
            # 使用 jq 风格化输出
            json_data = json.dumps({
                'timestamp': datetime.now().isoformat(),
                'temperature_celsius': round(temp, 2),
                'humidity_percent': round(humidity, 2),
                'pressure_hpa': round(pressure, 2),
                'wind_speed_kmh': round(wind_speed, 2),
                'data_quality': 'good' if 15 <= temp <= 35 and 30 <= humidity <= 70 else 'warning'
            }, indent=2)
            
            print("🔍 jq 格式化输出:")
            print(json_data)
            return json.loads(json_data)
            
        except Exception as e:
            print(f"jq 处理失败: {e}")
            return data
    
    def save_to_database(self, data):
        """保存到 SQLite 数据库"""
        try:
            self.cursor.execute('''
                INSERT INTO weather_data 
                (timestamp, temperature, humidity, pressure, wind_speed, wind_direction)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (
                data.get('timestamp'),
                data.get('temperature_celsius'),
                data.get('humidity_percent'),
                data.get('pressure_hpa'),
                data.get('wind_speed_kmh'),
                '模拟风向'
            ))
            self.conn.commit()
            print(f"✅ 数据已保存到数据库: {self.db_path}")
        except Exception as e:
            print(f"数据库保存失败: {e}")
    
    def get_statistics(self):
        """获取统计信息"""
        try:
            self.cursor.execute('''
                SELECT 
                    COUNT(*) as total_records,
                    AVG(temperature) as avg_temp,
                    MIN(temperature) as min_temp,
                    MAX(temperature) as max_temp,
                    AVG(humidity) as avg_humidity
                FROM weather_data 
                WHERE timestamp > datetime('now', '-1 hour')
            ''')
            
            stats = self.cursor.fetchone()
            if stats and stats[0] > 0:
                print("\n📊 过去1小时统计:")
                print(f"  记录数: {stats[0]}")
                print(f"  平均温度: {stats[1]:.2f}°C")
                print(f"  温度范围: {stats[2]:.2f}°C - {stats[3]:.2f}°C")
                print(f"  平均湿度: {stats[4]:.2f}%")
            
        except Exception as e:
            print(f"统计查询失败: {e}")
    
    def run_analysis(self):
        """运行完整分析流程"""
        print("🌤️ 开始气象数据分析...")
        
        # 1. 获取 API 数据
        print("\n📡 获取气象数据...")
        data = self.fetch_api_data()
        if not data:
            return
        
        # 2. 使用 jq 处理数据
        print("\n🔍 数据处理中...")
        processed_data = self.process_with_jq(data)
        
        # 3. 保存到数据库
        print("\n💾 保存数据...")
        self.save_to_database(processed_data)
        
        # 4. 显示统计信息
        print("\n📈 生成统计报告...")
        self.get_statistics()
        
        print("\n✅ 分析完成!")

def main():
    processor = MeteoDataProcessor()
    processor.run_analysis()

if __name__ == "__main__":
    main()