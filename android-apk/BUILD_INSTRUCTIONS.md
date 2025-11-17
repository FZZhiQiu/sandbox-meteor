# 如何构建Sandbox Meteor 60 FPS APK

## 主要构建方法（推荐）

使用GitHub Actions进行云构建，这是最稳定可靠的方法：

1. 推送代码到GitHub仓库以触发构建：
```bash
git add .
git commit -m "Trigger build"
git push origin main
```

2. 在GitHub Actions中查看构建进度
3. 从Artifacts下载生成的APK

## GitHub Codespaces 构建（云端推荐）

这是最适合您当前环境的构建方式，无需在本地安装任何软件：

1. 登录 GitHub (https://github.com)
2. 导航到您的仓库: https://github.com/FZZhiQiu/sandbox-meteor
3. 点击绿色的 "<> Code" 按钮
4. 选择 "Codespaces" 标签
5. 点击 "Create codespace on main" 按钮
6. 等待Codespaces环境自动配置（基于 `.devcontainer/devcontainer.json`）
7. 在终端中运行构建命令：
   ```bash
   ./gradlew assembleDebug --no-daemon -x test -x lint
   ```
8. 构建成功后，APK 文件将在 `app/build/outputs/apk/debug/app-debug.apk` 位置生成
9. 在文件资源管理器中右键点击APK文件并选择"Download"

**详细步骤**: `GITHUB_CODESPACES_BUILD.md`

## Android Studio 构建（本地可选）

如果您在桌面系统上，也可以使用Android Studio：

1. 安装最新版 Android Studio
2. 打开 Android Studio
3. 选择 "Open an existing Android Studio project" 或 "Open"
4. 导航到项目根目录 `/data/data/com.termux/files/home/happy/android-apk`
5. 选择 `build.gradle` (Project) 文件并打开
6. 等待项目同步完成（可能需要几分钟）
7. 点击菜单栏 "Build" → "Build Bundle(s) / APK(s)" → "Build APK(s)"
8. 构建成功后，APK 文件将在 `app/build/outputs/apk/debug/app-debug.apk` 位置生成

**详细步骤**: `ANDROID_STUDIO_BUILD_STEPS.md`

## 备用构建方案

如果GitHub Actions构建失败，请按以下顺序尝试备用方案：

### 方案1：Docker本地构建
使用预配置的Docker环境构建APK：
```bash
# 构建Docker镜像
docker build -t sandbox-meteor-builder .

# 运行构建并输出APK到本地apk目录
docker run --rm -v $(pwd)/apk:/workspace/app/build/outputs/apk/debug/ sandbox-meteor-builder
```

**配置文件**: `Dockerfile`

### 方案2：Android Studio构建
使用Android Studio图形界面构建：
1. 打开Android Studio
2. 选择"Open an existing Android Studio project"
3. 导航到项目根目录
4. 等待项目同步完成
5. 选择 "Build" → "Build Bundle(s) / APK(s)" → "Build APK(s)"

**配置说明**: `ANDROID_STUDIO_IMPORT.md`

### 方案3：Bitrise构建
使用Bitrise CI/CD服务：
1. 在Bitrise上创建应用
2. 配置工作流和环境变量
3. 运行 `./build_with_bitrise.sh`

**配置文件**: `BITRISE_SETUP.md`, `build_with_bitrise.sh`

### 方案4：Termux完整SDK构建
在Termux中安装完整Android SDK：
```bash
# 安装完整SDK环境
bash TERMUX_SDK_INSTALL.sh

# 构建APK
~/build_apk_local.sh
```

**配置文件**: `TERMUX_SDK_INSTALL.sh`

### 方案5：预配置环境构建
使用GitHub Codespaces或Gitpod：
- 在Codespaces/Gitpod中打开项目
- 环境将自动配置（基于`.devcontainer.json`）
- 运行构建命令

**配置文件**: `.devcontainer.json`

## 统一构建管理器

运行统一管理脚本，自动尝试所有构建方法：
```bash
./build_fallback.sh
```

## 环境要求（如果本地构建）

1. Android SDK (包含build-tools, platform-tools)
2. Android NDK (版本25.2.9519653)
3. Java 17 或更高版本
4. Gradle 8.4 或使用项目自带的gradle wrapper
5. CMake 3.22.1

## 本地Gradle构建步骤（备用）

如果需要使用命令行Gradle构建：

### 1. 确保环境设置
```bash
# 检查Android SDK环境变量
export ANDROID_HOME=/path/to/android-sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

### 2. 使用Gradle构建
```bash
# 进入项目目录
cd /data/data/com.termux/files/home/happy/android-apk

# 构建debug APK（推荐首次构建）
./gradlew assembleDebug --no-daemon -x test -x lint

# 或构建release APK
./gradlew assembleRelease --no-daemon -x test -x lint
```

## APK位置

构建完成后，APK将位于：
- Debug版本: `app/build/outputs/apk/debug/app-debug.apk`
- Release版本: `app/build/outputs/apk/release/app-release.apk`
- 复制版本: `apk/sandbox-meteor-debug.apk` 或 `apk/sandbox-meteor-release.apk`

## 签名Release APK (如果使用Release构建)

Release APK需要签名才能在设备上安装：

```bash
# 创建密钥库
keytool -genkey -v -keystore my-release-key.keystore -alias my-key-alias -keyalg RSA -keysize 2048 -validity 10000

# 使用jarsigner签名APK
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore my-release-key.keystore app-release-unsigned.apk my-key-alias

# 对齐APK
zipalign -v 4 app-release-unsigned.apk sandbox-meteor-agent-v3.2.0-60fps.apk
```

## 验证APK

使用apksigner验证APK签名：
```bash
apksigner verify --verbose app-debug.apk
```

## 安装到设备

```bash
# 确保设备已连接并启用USB调试
adb devices

# 安装APK到设备
adb install app-debug.apk
```

## 项目结构说明

- `app/src/main/AndroidManifest.xml` - 应用权限和组件声明
- `app/src/main/java/com/sandbox/radar/MainActivity.java` - 主活动
- `app/src/main/cpp/` - 原生代码（JNI接口、物理模拟等）
- `app/src/main/res/` - 资源文件（图标、字符串等）
- `app/build.gradle` - 应用构建配置
- `build.gradle` - 项目级构建配置
- `CMakeLists.txt` - C/C++构建配置

## 60 FPS功能特性

- 模拟步长：3秒（保持物理精度）
- 渲染帧率：60 FPS（视觉流畅）
- 双时钟架构：模拟与渲染线程解耦
- 插值系统：场数据、Agent位姿、音频参数平滑插值

## 详细构建指南

完整详细的构建方案说明请参见：`BUILD_FALLBACK_GUIDE.md`