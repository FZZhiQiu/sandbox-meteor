#!/usr/bin/env python3
import subprocess
import socket
import json
import time
import qrcode
import os

def get_local_ip():
    """获取本地IP地址"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "localhost"

def start_expo_server():
    """启动Expo开发服务器"""
    print("🚀 启动气象沙盘模拟器移动端...")
    
    # 设置环境变量
    env = os.environ.copy()
    env['CI'] = '1'  # 非交互模式
    env['EXPO_NO_DOTENV'] = '1'  # 跳过环境文件
    
    try:
        # 启动Expo开发服务器
        process = subprocess.Popen(
            ['npx', 'expo', 'start', '--port', '19006', '--web'],
            cwd='/data/data/com.termux/files/home/happy',
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # 等待服务器启动
        time.sleep(10)
        
        # 检查进程状态
        if process.poll() is None:
            print("✅ Expo开发服务器已启动")
            return True
        else:
            stdout, stderr = process.communicate()
            print(f"❌ 启动失败: {stderr}")
            return False
            
    except Exception as e:
        print(f"❌ 启动异常: {e}")
        return False

def generate_qr_code():
    """生成二维码"""
    local_ip = get_local_ip()
    expo_url = f"exp://{local_ip}:19006"
    
    print(f"📱 移动端访问地址: {expo_url}")
    print(f"🌐 Web端访问地址: http://{local_ip}:19006")
    print()
    
    # 生成二维码
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(expo_url)
    qr.make(fit=True)
    
    # 保存二维码图片
    img = qr.make_image(fill_color="black", back_color="white")
    img.save("/data/data/com.termux/files/home/happy/expo_qr.png")
    
    print("✅ 二维码已生成: expo_qr.png")
    print()
    print("📋 使用说明:")
    print("1. 确保手机安装了Expo Go应用")
    print("2. 用手机相机扫码上方二维码")
    print("3. 或在Expo Go中手动输入地址")
    print("4. 即可体验气象沙盘模拟器移动端")
    print()
    print("💡 提示: 确保手机和设备在同一WiFi网络下")

def main():
    print("🌤️ 气象沙盘模拟器 - 移动端开发模式")
    print("=" * 50)
    
    # 启动服务器
    if start_expo_server():
        # 生成二维码
        generate_qr_code()
        
        print("🔄 服务器运行中...")
        print("📱 扫码体验移动端气象沙盘")
        print("⚡ 实时数据 | 流畅动画 | 专业算法")
        
        # 保持运行
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\n🛑 服务器已停止")
    else:
        print("❌ 无法启动服务器，请检查配置")

if __name__ == "__main__":
    main()