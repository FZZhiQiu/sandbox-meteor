#!/bin/bash
# 增量构建脚本 - 为Android APK添加新模块

echo "开始为Android APK添加新模块..."

# 复制新模块的源文件到Android项目中（如果需要）
# 实际上，由于CMakeLists.txt使用GLOB_RECURSE，新文件会被自动包含

# 检查CMakeLists.txt是否已更新
echo "验证CMakeLists.txt配置..."
if grep -q "ionosphere\|carbon\|urban" CMakeLists.txt; then
    echo "CMakeLists.txt 已包含新模块"
else
    echo "CMakeLists.txt 需要更新"
fi

# 尝试构建Android项目
echo "构建Android项目..."
if [ -f "gradlew" ]; then
    ./gradlew clean
    echo "Gradle构建文件已清理"
else
    echo "警告: 未找到gradlew文件"
fi

echo "新模块已准备就绪，可以进行APK构建"
echo "电离层模块 (Ionosphere) - 电子密度和短波吸收"
echo "碳循环模块 (Carbon Cycle) - 海洋-陆地-大气通量平衡" 
echo "城市模块 (Urban) - 排热、污染、灌溉、政策"