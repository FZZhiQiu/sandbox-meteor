# 如何构建Sandbox Radar 60 FPS APK

## 环境要求

1. Android SDK (包含build-tools, platform-tools)
2. Android NDK (可选，用于原生代码)
3. Java 8 或更高版本
4. Gradle 7.4+ 或使用项目自带的gradle wrapper

## 构建步骤

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

# 构建debug APK
./gradlew assembleDebug

# 或构建release APK
./gradlew assembleRelease
```

### 3. 或使用Android Studio
1. 打开Android Studio
2. 选择"Open an existing Android Studio project"
3. 导航到 `/data/data/com.termux/files/home/happy/android-apk`
4. 等待项目同步完成
5. 选择 "Build" → "Build Bundle(s) / APK(s)" → "Build APK(s)"

## APK位置

构建完成后，APK将位于：
- Debug版本: `app/build/outputs/apk/debug/app-debug.apk`
- Release版本: `app/build/outputs/apk/release/app-release.apk`

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
- `app/src/main/res/` - 资源文件（图标、字符串等）
- `app/build.gradle` - 应用构建配置
- `build.gradle` - 项目级构建配置

## 60 FPS功能特性

- 模拟步长：3秒（保持物理精度）
- 渲染帧率：60 FPS（视觉流畅）
- 双时钟架构：模拟与渲染线程解耦
- 插值系统：场数据、Agent位姿、音频参数平滑插值