# Sandbox Radar — 高性能气象沙盘（C++ 核心 + Android + Web）

## 项目简介

Sandbox Radar 是一个高性能的气象仿真与可视化平台，支持实时雷暴模拟、生态影响评估和政策分析。项目采用C++核心引擎，支持Android移动端和Web端可视化。

## 构建步骤

### C++ 核心构建

```bash
cd sandbox-radar
mkdir build
cd build
cmake ..
make -j4
```

生成的主要产物：
- `libsandbox_radar.so` - JNI共享库
- `sandbox_radar_exe` - 可执行文件

### Android 构建

由于项目使用Expo框架，构建命令为：

```bash
# 预构建原生配置
npx expo prebuild --platform android

# 构建Android应用
npx expo run:android
```

或直接使用Gradle（需安装NDK）:

```bash
cd android
./gradlew assembleDebug
```

### Web 构建

```bash
cd web-meteor-visualizer
./build.sh
```

## 产物路径

- **C++ 核心库**: `sandbox-radar/build/libsandbox_radar.so`
- **C++ 可执行文件**: `sandbox-radar/build/sandbox_radar_exe`
- **Android APK**: `android/app/build/outputs/apk/debug/app-debug.apk`
- **Web 构建**: `web-meteor-visualizer/dist/`

## 常见故障与解决方法

### Android 构建失败
1. 确保已安装JDK 17+、Android SDK、NDK
2. 检查环境变量ANDROID_HOME是否设置正确
3. 确保已安装Expo CLI: `npm install -g @expo/cli`

### C++ 构建失败
1. 确保已安装CMake 3.10+
2. 确保已安装C++编译器（GCC或Clang）
3. 检查是否缺少依赖库

### Web 构建失败
1. 确保已安装Node.js
2. 检查是否有足够的磁盘空间