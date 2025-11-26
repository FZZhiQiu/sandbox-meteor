#!/bin/bash

# Web Meteor Visualizer 构建脚本

set -e  # 遇到错误时停止执行

echo "开始构建 Web Meteor Visualizer..."

# 创建构建目录
mkdir -p /data/data/com.termux/files/home/happy/web-meteor-visualizer/dist

# 复制文件到构建目录
cp -r /data/data/com.termux/files/home/happy/web-meteor-visualizer/index.html /data/data/com.termux/files/home/happy/web-meteor-visualizer/dist/
cp -r /data/data/com.termux/files/home/happy/web-meteor-visualizer/css /data/data/com.termux/files/home/happy/web-meteor-visualizer/dist/
cp -r /data/data/com.termux/files/home/happy/web-meteor-visualizer/js /data/data/com.termux/files/home/happy/web-meteor-visualizer/dist/
cp -r /data/data/com.termux/files/home/happy/web-meteor-visualizer/assets /data/data/com.termux/files/home/happy/web-meteor-visualizer/dist/ 2>/dev/null || echo "警告: assets 目录不存在"

echo "Web构建完成！文件已输出到 /data/data/com.termux/files/home/happy/web-meteor-visualizer/dist/"