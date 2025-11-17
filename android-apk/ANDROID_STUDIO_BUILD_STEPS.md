# Android Studio 构建指南

## 导入项目
1. 打开 Android Studio
2. 选择 "Open an existing Android Studio project" 或 "Open"
3. 导航到 `/data/data/com.termux/files/home/happy/android-apk` 目录
4. 选择 `build.gradle` (Project) 文件并打开

## 等待同步完成
- Android Studio 将自动同步项目并下载必要的依赖
- 这可能需要几分钟时间，请耐心等待
- 查看底部状态栏以查看同步进度

## 构建 APK
1. 确保项目同步成功（没有错误信息）
2. 点击菜单栏中的 "Build"
3. 选择 "Build Bundle(s) / APK(s)"
4. 选择 "Build APK(s)"

## 查找生成的 APK
- 构建成功后，APK 文件将在以下位置生成：
  `app/build/outputs/apk/debug/app-debug.apk`
- Android Studio 右下角会显示通知，点击 "locate" 可以快速找到文件

## 注意事项
- 首次导入项目时，Android Studio 可能会提示更新或安装某些工具
- 确保有足够的磁盘空间和内存
- 如果遇到 Gradle 相关问题，可以尝试 File > Invalidate Caches and Restart

## 验证
- APK 生成后，您可以在设备上安装以验证构建是否成功
- 检查应用是否正常运行，特别是 60 FPS 模拟功能

构建成功后，您将获得一个包含所有功能的 APK 文件，该文件可以在 Android 设备上安装和运行。