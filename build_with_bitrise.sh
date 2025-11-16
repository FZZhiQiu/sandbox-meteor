#!/bin/bash

# Bitrise自动构建脚本
# 请确保已设置环境变量: BITRISE_ACCESS_TOKEN

set -e  # 遇到错误时退出

# 检查环境变量
if [ -z "$BITRISE_ACCESS_TOKEN" ]; then
    echo "错误: 请设置 BITRISE_ACCESS_TOKEN 环境变量"
    echo "示例: export BITRISE_ACCESS_TOKEN='your_token_here'"
    exit 1
fi

# 配置变量
APP_SLUG=""  # 您的Bitrise应用slug
BUILD_TRIGGER_URL="https://api.bitrise.io/v0.1/apps/$APP_SLUG/builds"
ZIP_FILE="android-project.zip"
APK_DIR="apk"
TEMP_DIR="temp_build"

echo "Sandbox Radar 60 FPS - Bitrise自动构建脚本"
echo "==========================================="

# 创建输出目录
mkdir -p $APK_DIR
mkdir -p $TEMP_DIR

# 1. 将当前项目压缩成zip
echo "1. 正在压缩项目文件..."
EXCLUDE_PATTERNS=(
    ".git"
    "node_modules"
    ".gradle"
    "build"
    "app/build"
    "*.apk"
    "*.aab"
    ".DS_Store"
    "*.log"
    "temp_build"
)

EXCLUDE_ARGS=""
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude=$pattern"
done

# 创建zip文件
eval "zip -r $ZIP_FILE . $EXCLUDE_ARGS"

if [ $? -ne 0 ]; then
    echo "错误: 项目压缩失败"
    exit 1
fi

echo "   ✓ 项目已压缩为 $ZIP_FILE ($(du -h $ZIP_FILE | cut -f1))"

# 2. 上传到Bitrise并触发构建
echo "2. 正在上传到Bitrise并触发构建..."

# 准备构建参数
BUILD_PARAMS='{
  "build_params": {
    "branch": "feat/60fps",
    "commit_message": "Build via API: 60 FPS version",
    "environments": [
      {
        "mapped_to": "ANDROID_BUILD_TYPE",
        "value": "release",
        "is_expand": true
      }
    ]
  }
}'

# 触发构建
echo "   发送构建请求..."
RESPONSE=$(curl -s -X POST \
  -H "Authorization: token $BITRISE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$BUILD_PARAMS" \
  "$BUILD_TRIGGER_URL")

# 检查响应
if [ $? -ne 0 ]; then
    echo "错误: 无法连接到Bitrise API"
    exit 1
fi

# 提取构建ID
BUILD_ID=$(echo $RESPONSE | grep -o '"build_number":[0-9]*' | cut -d':' -f2)
BUILD_URL=$(echo $RESPONSE | grep -o '"url":"[^"]*"' | cut -d'"' -f4)

if [ -z "$BUILD_ID" ]; then
    echo "错误: 无法从API响应中获取构建ID"
    echo "响应: $RESPONSE"
    exit 1
fi

echo "   ✓ 构建已触发 - ID: $BUILD_ID"
echo "   ✓ 构建URL: $BUILD_URL"

# 3. 循环查询构建状态直到完成
echo "3. 正在监控构建进度..."
BUILD_STATUS_URL="https://api.bitrise.io/v0.1/apps/$APP_SLUG/builds/$BUILD_ID"
CHECK_INTERVAL=30  # 每30秒检查一次
MAX_CHECKS=120     # 最多检查120次 (60分钟)

check_count=0
while [ $check_count -lt $MAX_CHECKS ]; do
    STATUS_RESPONSE=$(curl -s \
      -H "Authorization: token $BITRISE_ACCESS_TOKEN" \
      "$BUILD_STATUS_URL")
    
    BUILD_STATUS=$(echo $STATUS_RESPONSE | grep -o '"status_text":"[^"]*"' | cut -d'"' -f4)
    BUILD_PROGRESS=$(echo $STATUS_RESPONSE | grep -o '"progress_text":"[^"]*"' | cut -d'"' -f4)
    
    if [ "$BUILD_STATUS" = "in-progress" ]; then
        echo "   构建进行中... ($BUILD_PROGRESS)"
    elif [ "$BUILD_STATUS" = "finished" ]; then
        BUILD_RESULT=$(echo $STATUS_RESPONSE | grep -o '"status_text":"[^"]*"' | cut -d'"' -f4)
        if [ "$BUILD_RESULT" = "success" ]; then
            echo "   ✓ 构建成功完成!"
            break
        else
            echo "   ❌ 构建失败: $BUILD_RESULT"
            exit 1
        fi
    else
        echo "   构建状态: $BUILD_STATUS"
    fi
    
    sleep $CHECK_INTERVAL
    ((check_count++))
    
    if [ $check_count -ge $MAX_CHECKS ]; then
        echo "   ⚠️ 构建超时"
        exit 1
    fi
done

# 4. 下载APK
echo "4. 正在下载APK文件..."
ARTIFACTS_URL="https://api.bitrise.io/v0.1/apps/$APP_SLUG/builds/$BUILD_ID/artifacts"

ARTIFACTS_RESPONSE=$(curl -s \
  -H "Authorization: token $BITRISE_ACCESS_TOKEN" \
  "$ARTIFACTS_URL")

# 查找APK文件
APK_ARTIFACT_ID=$(echo $ARTIFACTS_RESPONSE | grep -o '"artifact_id":[0-9]*' | head -1 | cut -d':' -f2)
APK_NAME=$(echo $ARTIFACTS_RESPONSE | grep -o '"title":"[^"]*\.apk"' | head -1 | cut -d'"' -f4)

if [ -z "$APK_ARTIFACT_ID" ]; then
    echo "错误: 未找到APK文件"
    # 尝试查找所有构建产物
    echo "可用的构建产物:"
    echo $ARTIFACTS_RESPONSE | grep -o '"title":"[^"]*"' | cut -d'"' -f4
    exit 1
fi

echo "   找到APK文件: $APK_NAME"
echo "   Artifact ID: $APK_ARTIFACT_ID"

# 获取下载URL
ARTIFACT_URL="https://api.bitrise.io/v0.1/apps/$APP_SLUG/builds/$BUILD_ID/artifacts/$APK_ARTIFACT_ID"
DOWNLOAD_RESPONSE=$(curl -s \
  -H "Authorization: token $BITRISE_ACCESS_TOKEN" \
  "$ARTIFACT_URL")

DOWNLOAD_URL=$(echo $DOWNLOAD_RESPONSE | grep -o '"public_install_page_url":"[^"]*"' | cut -d'"' -f4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "错误: 无法获取下载URL"
    exit 1
fi

# 下载APK文件
echo "   下载中..."
curl -L -o "$APK_DIR/$APK_NAME" "$DOWNLOAD_URL"

if [ $? -eq 0 ]; then
    APK_SIZE=$(du -h "$APK_DIR/$APK_NAME" | cut -f1)
    echo "   ✓ APK已下载到: $APK_DIR/$APK_NAME ($APK_SIZE)"
    echo ""
    echo "构建完成!"
    echo "APK位置: $APK_DIR/$APK_NAME"
    echo "文件大小: $APK_SIZE"
    echo "构建ID: $BUILD_ID"
else
    echo "错误: 下载APK失败"
    exit 1
fi

# 清理临时文件
rm -f $ZIP_FILE

echo ""
echo "注意: 请确保您的Bitrise应用已正确配置，包含适当的构建工作流。"
echo "如果构建失败，请检查Bitrise构建日志以获取详细错误信息。"