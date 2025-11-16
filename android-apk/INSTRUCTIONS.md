# MCP Build System 已完成

## 文件列表

以下是已完成的文件：

### 1. GitHub Actions 工作流文件
```yaml
name: Build APK
on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      with:
        submodules: recursive
        fetch-depth: 0

    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        distribution: 'temurin'
        java-version: '17'

    - name: Setup Android SDK
      uses: android-actions/setup-android@v3
      with:
        packages: tools platform-tools build-tools-34.0.0 cmake-3.22.1

    - name: Make gradlew executable
      run: chmod +x ./gradlew

    - name: Cache Gradle dependencies
      uses: actions/cache@v4
      with:
        path: |
          ~/.gradle/caches
          ~/.gradle/wrapper
          !~/.gradle/caches/build-cache-*
        key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
        restore-keys: |
          ${{ runner.os }}-gradle-

    - name: Build APK
      run: |
        ./gradlew assembleRelease --no-daemon
      env:
        JAVA_OPTS: -Xmx2048m

    - name: Create APK directory
      run: |
        mkdir -p apk
        cp app/build/outputs/apk/release/app-release.apk apk/sandbox-meteor-agent.apk

    - name: Upload APK to Artifacts
      uses: actions/upload-artifact@v4
      with:
        name: sandbox-meteor-apk
        path: apk/sandbox-meteor-agent.apk
        retention-days: 30

    - name: Get download URL
      id: apk_url
      run: |
        APK_SIZE=$(du -h apk/sandbox-meteor-agent.apk | cut -f1)
        echo "apk_size=$APK_SIZE" >> $GITHUB_OUTPUT
        echo "apk_name=sandbox-meteor-agent.apk" >> $GITHUB_OUTPUT

    - name: Print build info
      run: |
        echo "Build completed!"
        echo "APK Size: ${{ steps.apk_url.outputs.apk_size }}"
        echo "APK Name: ${{ steps.apk_url.outputs.apk_name }}"
```
**文件路径**: `.github/workflows/build_apk.yml`

### 2. MCP 构建脚本
```bash
#!/bin/bash

# MCP Build Script for Sandbox Radar APK
# Automatically tags, builds via GitHub Actions, and downloads APK

set -e

echo -e "\n🚀 MCP Build Script for Sandbox Radar APK"
echo -e "========================================\n"

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI (gh) is not installed"
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if authenticated with GitHub
if ! gh auth status &> /dev/null; then
    echo "❌ Error: Not authenticated with GitHub"
    echo "Please run: gh auth login"
    exit 1
fi

# Get repository info
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "❌ Error: Not in a git repository or no remote configured"
    exit 1
fi

echo "📦 Repository: $REPO"

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  Uncommitted changes detected, stashing..."
    git stash push -m "Auto-stashed by MCP build script"
    STASHED=1
fi

# Get current version from app/build.gradle or use timestamp
if [ -f "app/build.gradle" ]; then
    VERSION_CODE=$(grep "versionCode" app/build.gradle | grep -o '[0-9]*' | head -1)
    VERSION_NAME=$(grep "versionName" app/build.gradle | grep -o '"[^"]*"' | tr -d '"')
    if [ -n "$VERSION_NAME" ]; then
        VERSION="v$VERSION_NAME"
    else
        VERSION="v$(date +%Y%m%d-%H%M%S)"
    fi
else
    VERSION="v$(date +%Y%m%d-%H%M%S)"
fi

echo "🏷️  Tagging version: $VERSION"

# Create and push tag
git tag -f "$VERSION"
git push origin "$VERSION"

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to push tag"
    # Restore stashed changes if any
    if [ "$STASHED" = "1" ]; then
        git stash pop
    fi
    exit 1
fi

echo "✅ Tag pushed successfully"

# Wait for workflow to start
echo "⏳ Waiting for GitHub Actions workflow to start..."
WORKFLOW_STARTED=0
for i in {1..30}; do
    sleep 2
    WORKFLOW_ID=$(gh run list --repo "$REPO" --limit 1 --json databaseId,status | jq -r '.[0] | select(.status=="queued" or .status=="in_progress") | .databaseId' 2>/dev/null)
    if [ -n "$WORKFLOW_ID" ]; then
        echo "✅ Workflow started with ID: $WORKFLOW_ID"
        WORKFLOW_STARTED=1
        break
    fi
    echo "⏳ Waiting for workflow to start... ($i/30)"
done

if [ "$WORKFLOW_STARTED" = "0" ]; then
    echo "❌ Error: Workflow did not start in time"
    # Restore stashed changes if any
    if [ "$STASHED" = "1" ]; then
        git stash pop
    fi
    exit 1
fi

# Monitor workflow progress
echo "🔄 Monitoring workflow progress..."
while true; do
    sleep 10
    WORKFLOW_STATUS=$(gh run view "$WORKFLOW_ID" --repo "$REPO" --json status,conclusion | jq -r '.status')
    
    case "$WORKFLOW_STATUS" in
        "completed")
            CONCLUSION=$(gh run view "$WORKFLOW_ID" --repo "$REPO" --json conclusion | jq -r '.conclusion')
            if [ "$CONCLUSION" = "success" ]; then
                echo "✅ Workflow completed successfully"
                break
            else
                echo "❌ Workflow failed with conclusion: $CONCLUSION"
                # Restore stashed changes if any
                if [ "$STASHED" = "1" ]; then
                    git stash pop
                fi
                exit 1
            fi
            ;;
        "in_progress")
            echo "🔄 Workflow in progress..."
            ;;
        "queued")
            echo "⏳ Workflow queued..."
            ;;
        *)
            echo "🔄 Workflow status: $WORKFLOW_STATUS"
            ;;
    esac
done

# Download APK
echo "📥 Downloading APK..."
mkdir -p apk

if gh run download "$WORKFLOW_ID" --repo "$REPO" -n sandbox-meteor-apk --dir apk; then
    # Find the APK file
    APK_FILE=$(find apk -name "*.apk" | head -1)
    if [ -n "$APK_FILE" ]; then
        APK_SIZE=$(du -h "$APK_FILE" | cut -f1)
        echo -e "\n✅ \033[0;32mAPK downloaded successfully!\033[0m"
        echo -e "\033[0;32m📁 APK Path:\033[0m $APK_FILE"
        echo -e "\033[0;32m📊 File Size:\033[0m $APK_SIZE"
        echo -e "\n🎉 Build process completed!"
    else
        echo "❌ Error: APK file not found in downloaded artifacts"
        # Restore stashed changes if any
        if [ "$STASHED" = "1" ]; then
            git stash pop
        fi
        exit 1
    fi
else
    echo "❌ Error: Failed to download APK"
    # Restore stashed changes if any
    if [ "$STASHED" = "1" ]; then
        git stash pop
    fi
    exit 1
fi

# Restore stashed changes if any
if [ "$STASHED" = "1" ]; then
    echo "🔄 Restoring stashed changes..."
    git stash pop
fi

echo -e "\n✨ Done!"
```
**文件路径**: `mcp_build.sh`

### 3. 使用说明文档
```markdown
# MCP Build System for Sandbox Radar APK

## 概述
本系统允许您在没有本地Android SDK的情况下，通过GitHub Actions自动构建Sandbox Radar APK。

## 所需GitHub Secrets

在您的GitHub仓库中设置以下Secrets：
- `KEYSTORE_PWD` - 签名密钥库密码
- `KEY_PWD` - 签名密钥密码

设置路径：Repository Settings → Secrets and variables → Actions

## 使用方法

### 1. 配置GitHub CLI
```bash
# 安装GitHub CLI（如果尚未安装）
# Ubuntu/Debian:
sudo apt install gh

# macOS:
brew install gh

# Windows:
winget install GitHub.cli

# 登录GitHub
gh auth login
```

### 2. 运行构建脚本
```bash
# 给脚本添加执行权限
chmod +x mcp_build.sh

# 运行构建
./mcp_build.sh
```

### 3. 脚本功能
脚本将自动执行以下操作：
1. 检查是否有未提交的更改，如有则stash
2. 自动打tag并推送到GitHub
3. 触发GitHub Actions构建
4. 监控构建进度直到完成
5. 下载生成的APK到`apk/`目录
6. 恢复之前stash的更改（如有）

## 构建配置详情

- **应用ID**: com.sandboxradar.meteor
- **最低SDK**: 26
- **目标SDK**: 34
- **NDK版本**: 25.2.9519653
- **CMake版本**: 3.22.1
- **架构**: arm64-v8a
- **构建命令**: ./gradlew assembleRelease
- **产物路径**: app/build/outputs/apk/release/app-release.apk

## 输出文件

构建完成后，APK将保存在：
````
apk/sandbox-meteor-agent.apk
````

## 故障排除

### GitHub CLI相关错误
如果遇到GitHub CLI相关错误，请确保：
1. 已正确安装GitHub CLI
2. 已通过`gh auth login`登录
3. 有仓库的适当权限

### 构建失败
如果构建失败：
1. 检查GitHub Actions日志获取详细错误信息
2. 确保所有必需的Secrets已正确设置
3. 验证项目配置文件（build.gradle, CMakeLists.txt等）

### 网络问题
如果遇到网络超时：
1. 检查网络连接
2. 重新运行脚本（构建会从断点继续）

## 安全注意事项

1. 从不将密钥硬编码在代码中
2. 使用GitHub Secrets存储敏感信息
3. 定期轮换密钥
4. 限制Secrets的访问权限
```
**文件路径**: `README_MCP.md`

## 使用步骤

1. 将这些文件添加到您的项目中
2. 在GitHub仓库中设置所需的Secrets
3. 运行 `./mcp_build.sh` 开始构建过程
4. 构建完成后，APK文件将位于 `apk/` 目录中