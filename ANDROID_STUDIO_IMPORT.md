# Android Studio 导入和构建说明

## 导入项目

1. 打开 Android Studio
2. 选择 "Open an existing Android Studio project"
3. 导航到项目根目录并选择 `build.gradle` 文件
4. 等待项目同步完成

## 构建配置

### 项目设置
- 确保 Android Studio 使用 JDK 17 或更高版本
- 在 `File > Project Structure > SDK Location` 中设置正确的 Android SDK 路径

### 构建变体
- 选择 `debug` 或 `release` 构建变体
- 推荐首次构建使用 `debug` 变体以快速验证

### 构建步骤
1. 清理项目: `Build > Clean Project`
2. 构建APK: `Build > Build Bundle(s) / APK(s) > Build APK`
3. 查找生成的APK: `app/build/outputs/apk/debug/app-debug.apk`

## 常见问题解决

### NDK问题
如果遇到NDK相关错误：
1. 打开 SDK Manager
2. 在 `SDK Tools` 标签页中安装或更新 NDK (Side by side)
3. 确保版本与 `build.gradle` 中的 `ndkVersion` 匹配

### CMake问题
如果遇到CMake相关错误：
1. 确保在 SDK Manager 中安装了 CMake
2. 检查 `CMakeLists.txt` 文件路径是否正确
3. 验证 `app/build.gradle` 中的 CMake 配置

### 构建性能优化
在 `gradle.properties` 中添加以下配置以提高构建性能：
```
org.gradle.daemon=false
org.gradle.parallel=true
org.gradle.configureondemand=true
android.enableBuildCache=true
```