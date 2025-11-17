# Sandbox Meteor APK 构建方案

本文档描述了构建Sandbox Meteor APK的多种方案，包括主要方案和5种备用方案。

## 🚀 主要构建方案

### GitHub Actions (推荐)
- **描述**: 使用已配置的GitHub Actions工作流进行云构建
- **优势**: 无需本地环境配置，自动处理依赖
- **使用方法**: 
  ```bash
  git add .
  git commit -m "Trigger build"
  git push origin main
  ```
- **APK位置**: GitHub Actions Artifacts

## 🛠️ 备用构建方案 (1-5)

### 方案1: Docker本地构建
- **描述**: 使用Docker容器进行本地构建
- **配置文件**: `Dockerfile`
- **使用方法**:
  ```bash
  docker build -t sandbox-meteor-builder .
  docker run --rm -v $(pwd)/apk:/workspace/app/build/outputs/apk/debug/ sandbox-meteor-builder
  ```
- **优势**: 环境隔离，一致性好
- **要求**: 已安装Docker

### 方案2: Android Studio构建
- **描述**: 在桌面版Android Studio中打开项目进行构建
- **配置文件**: `ANDROID_STUDIO_IMPORT.md`
- **使用方法**: 
  1. 在Android Studio中打开项目 (`/data/data/com.termux/files/home/happy/android-apk`)
  2. 等待项目同步
  3. Build > Build Bundle(s) / APK(s) > Build APK
- **优势**: 图形界面，调试方便
- **要求**: Android Studio IDE

### 方案3: Bitrise构建
- **描述**: 使用Bitrise CI/CD服务进行云构建
- **配置文件**: `BITRISE_SETUP.md`, `build_with_bitrise.sh`
- **使用方法**:
  ```bash
  # 配置Bitrise访问令牌和应用slug
  export BITRISE_ACCESS_TOKEN="your_token"
  export APP_SLUG="your_app_slug"
  ./build_with_bitrise.sh
  ```
- **优势**: 专业CI服务，功能丰富
- **要求**: Bitrise账户

### 方案4: Termux完整SDK构建
- **描述**: 在Termux中安装完整Android SDK进行本地构建
- **配置文件**: `TERMUX_SDK_INSTALL.sh`
- **使用方法**:
  ```bash
  bash TERMUX_SDK_INSTALL.sh
  ~/build_apk_local.sh
  ```
- **优势**: 完全本地构建，无网络依赖
- **要求**: Termux环境，足够存储空间

### 方案5: 预构建环境构建
- **描述**: 在GitHub Codespaces、Gitpod等预配置环境中构建
- **配置文件**: `.devcontainer.json`
- **使用方法**:
  1. 在Codespaces/Gitpod中打开项目
  2. 环境自动配置
  3. 运行构建命令
- **优势**: 零配置，云端资源
- **要求**: GitHub账户或Gitpod账户

## 📋 统一构建管理

### 使用构建回退脚本
项目包含一个统一的构建管理脚本 `build_fallback.sh`，可自动尝试各种构建方案：

```bash
# 显示使用说明
./build_fallback.sh -h

# 尝试所有构建方案（自动选择）
./build_fallback.sh

# 直接使用Docker构建
./build_fallback.sh docker
```

## 📁 相关文件位置

```
项目根目录/
├── Dockerfile                  # 方案1: Docker构建配置
├── ANDROID_STUDIO_IMPORT.md    # 方案2: Android Studio导入说明
├── BITRISE_SETUP.md            # 方案3: Bitrise配置说明
├── TERMUX_SDK_INSTALL.sh       # 方案4: Termux SDK安装脚本
├── .devcontainer.json          # 方案5: 预构建环境配置
├── build_fallback.sh           # 统一构建管理脚本
└── .github/workflows/          # GitHub Actions配置
    └── build_apk.yml
```

## 🎯 构建产物

所有构建方案的APK产物都将生成在以下位置：
- Debug版本: `app/build/outputs/apk/debug/app-debug.apk`
- Release版本: `app/build/outputs/apk/release/app-release.apk`
- 复制版本: `apk/sandbox-meteor-debug.apk` 或 `apk/sandbox-meteor-release.apk`

## 🔧 故障排除

### 构建失败常见原因
1. **网络问题**: 下载依赖失败
2. **存储空间不足**: 清理不必要的文件
3. **环境配置错误**: 检查SDK和NDK配置
4. **权限问题**: 确保脚本有执行权限

### 清理构建缓存
```bash
# 清理Gradle缓存
./gradlew clean

# 删除构建输出
rm -rf app/build/

# 清理Gradle包装器缓存
rm -rf ~/.gradle/caches/
```

### 检查构建日志
```bash
# 查看详细构建日志
./gradlew assembleDebug --info

# 查看堆栈跟踪
./gradlew assembleDebug --stacktrace
```