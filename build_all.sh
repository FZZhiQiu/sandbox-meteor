#!/bin/bash

# Sandbox Radar 项目构建汇总脚本

set -e  # 遇到错误时停止执行

echo "开始生成所有最终产物..."

# 创建发布目录
mkdir -p /data/data/com.termux/files/home/happy/dist

echo "复制C++核心库..."
cp -r /data/data/com.termux/files/home/happy/sandbox-radar/build/libsandbox_radar.so /data/data/com.termux/files/home/happy/dist/ 2>/dev/null || echo "警告: C++核心库未找到"
cp -r /data/data/com.termux/files/home/happy/sandbox-radar/build/sandbox_radar_exe /data/data/com.termux/files/home/happy/dist/ 2>/dev/null || echo "警告: C++可执行文件未找到"

echo "复制Web构建产物..."
cp -r /data/data/com.termux/files/home/happy/web-meteor-visualizer/dist /data/data/com.termux/files/home/happy/dist/web-visualizer 2>/dev/null || echo "警告: Web构建产物未找到"

echo "复制文档..."
cp /data/data/com.termux/files/home/happy/README.md /data/data/com.termux/files/home/happy/dist/ 2>/dev/null || echo "警告: README.md未找到"
cp /data/data/com.termux/files/home/happy/API.md /data/data/com.termux/files/home/happy/dist/ 2>/dev/null || echo "警告: API文档未找到"
cp /data/data/com.termux/files/home/happy/ARCHITECTURE.md /data/data/com.termux/files/home/happy/dist/ 2>/dev/null || echo "警告: 架构图文档未找到"
cp /data/data/com.termux/files/home/happy/STORYLINE_COUNTERFACTUAL.md /data/data/com.termux/files/home/happy/dist/ 2>/dev/null || echo "警告: 故事线和反事实文档未找到"

echo "检查Android APK..."
if [ -f "/data/data/com.termux/files/home/happy/android/app/build/outputs/apk/debug/app-debug.apk" ]; then
    cp /data/data/com.termux/files/home/happy/android/app/build/outputs/apk/debug/app-debug.apk /data/data/com.termux/files/home/happy/dist/ 2>/dev/null || echo "警告: Android APK未复制"
    echo "Android Debug APK 已复制到 dist 目录"
else
    echo "警告: Android Debug APK 未找到，可能需要先运行: cd android && ./gradlew assembleDebug"
fi

# 创建压缩包
cd /data/data/com.termux/files/home/happy/dist
zip -r ../sandbox-radar-build-$(date +%Y%m%d-%H%M%S).zip ./*

echo "所有最终产物已生成并打包！"
echo "产物位置: /data/data/com.termux/files/home/happy/dist/"
ls -la /data/data/com.termux/files/home/happy/dist/

echo "构建完成！"