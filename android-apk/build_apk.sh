#!/bin/bash
# Sandbox Radar 60 FPS APK 构建脚本

echo "Sandbox Radar 60 FPS APK Build Script"
echo "====================================="

# 检查是否在Android SDK环境中
if [ -z "$ANDROID_HOME" ]; then
    echo "警告: ANDROID_HOME 环境变量未设置"
    echo "请设置 ANDROID_HOME 指向您的 Android SDK 目录"
    echo ""
    echo "示例:"
    echo "  export ANDROID_HOME=/path/to/android-sdk"
    echo "  export PATH=\$PATH:\$ANDROID_HOME/tools:\$ANDROID_HOME/platform-tools"
    echo ""
fi

# 显示构建说明
echo "构建说明:"
echo "---------"
echo "1. 确保您在具有完整Android SDK的环境中"
echo "2. 运行以下命令构建Release APK:"
echo "   ./gradlew assembleRelease"
echo ""
echo "3. 或运行以下命令构建AAB (用于Google Play):"
echo "   ./gradlew bundleRelease"
echo ""
echo "输出文件位置:"
echo "-------------"
echo "APK: app/build/outputs/apk/release/app-release.apk"
echo "AAB: app/build/outputs/bundle/release/app-release.aab"
echo "Mapping: app/build/outputs/mapping/release/mapping.txt"
echo ""
echo "注意: Release版本需要签名配置，密钥信息从环境变量读取:"
echo "  KEYSTORE_PWD - 密钥库密码"
echo "  KEY_PWD - 密钥密码"