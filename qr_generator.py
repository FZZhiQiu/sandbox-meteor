#!/usr/bin/env python3
import qrcode
import socket
import sys

def get_local_ip():
    """获取本地IP地址"""
    try:
        # 创建一个socket连接到外部地址来获取本地IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "localhost"

def main():
    # 获取本地IP
    local_ip = get_local_ip()
    url = f"http://{local_ip}:8080"
    
    print(f"🌤️ 气象沙盘模拟器 Web版")
    print(f"📱 扫码访问: {url}")
    print(f"🔗 本地访问: http://localhost:8080")
    print()
    
    # 生成二维码图片
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(url)
    qr.make(fit=True)
    
    # 创建图片并保存
    img = qr.make_image(fill_color="black", back_color="white")
    img.save("/data/data/com.termux/files/home/happy/meteo_qr.png")
    
    print("✅ 二维码已保存为: meteo_qr.png")
    print()
    print("📋 使用说明:")
    print("1. 查看生成的 meteo_qr.png 文件")
    print("2. 用手机相机或微信扫码二维码")
    print("3. 在手机浏览器中打开气象沙盘")
    print("4. 实时查看气象数据和分析结果")
    print()
    print("💡 提示: 确保手机和设备在同一网络下")
    print(f"🌐 网络地址: {url}")

if __name__ == "__main__":
    main()