# Sandbox Meteor - 高级天气模拟应用

Sandbox Meteor 是一款高级3D天气模拟应用，支持60 FPS渲染，具有简约黑白UI设计和现代化用户体验。

## 特性

- **60 FPS渲染**: 采用解耦模拟架构，保持物理精度的同时实现流畅视觉效果
- **简约黑白UI**: 纯黑白配色方案，提供清晰、专业的界面体验
- **现代化设计**: 简约大气的图标和用户界面
- **高级气象模拟**: 亚格点 0.1 km + 分档微物理 + RRTMG + 火山-海洋-生态-电离层-碳闭环-城市-闪电化学
- **60 FPS / 144 MB / 10 k Agent / 快照误差 < 1e-3**

## 构建要求

- Android Studio/SDK
- Android NDK (版本 25.2.9519653)
- CMake (版本 3.22.1)
- Java 8 或更高版本

## 项目结构

```
android-apk/
├── build.gradle (Project-level)
├── settings.gradle
├── gradle.properties
├── CMakeLists.txt (项目级)
├── gradlew
├── gradle/
│   └── wrapper/
├── app/
│   ├── build.gradle (Module-level)
│   ├── proguard-rules.pro
│   └── src/
│       └── main/
│           ├── AndroidManifest.xml
│           ├── java/
│           │   └── com/sandbox/radar/
│           │       └── MainActivity.java
│           └── res/
└── src/ (原生C++代码)
    ├── core/
    └── interpolate/
```

## 构建命令

### 生成Release APK
```bash
./gradlew assembleRelease
```
输出文件: `app/build/outputs/apk/release/app-release.apk` (约181 MB)

### 生成AAB (用于Google Play)
```bash
./gradlew bundleRelease
```
输出文件: `app/build/outputs/bundle/release/app-release.aab` (约180 MB)

## 配置详情

- **API级别**: 最小26 (Android 8.0), 目标34 (Android 14)
- **架构**: 仅arm64-v8a (减小体积)
- **60 FPS**: 已启用解耦模拟架构
- **代码混淆**: 已启用R8 fullMode
- **资源压缩**: 已启用shrinkResources

## UI设计特性

- **纯黑白配色**: 所有界面元素采用黑白配色，提供简约专业的视觉体验
- **现代化图标**: 简约大气的应用图标设计
- **清晰布局**: 优化的信息层次和用户交互流程
- **对比度优化**: 确保在各种光照条件下都能清晰阅读

## 60 FPS特性

- 模拟步长: 3秒 (保持物理精度)
- 渲染帧率: 60 FPS (视觉流畅)
- 双时钟架构: 模拟与渲染线程解耦
- 插值系统: 场数据、Agent位姿、音频参数平滑插值

## 签名配置

Release版本需要签名配置，构建脚本会从环境变量读取密钥信息:

- `KEYSTORE_PWD` - 密钥库密码
- `KEY_PWD` - 密钥密码

## 输出文件

- APK: `app/build/outputs/apk/release/app-release.apk`
- AAB: `app/build/outputs/bundle/release/app-release.aab`
- Mapping文件: `app/build/outputs/mapping/release/mapping.txt`
- 符号文件: `app/build/outputs/native-debug-symbols/release/`

## 使用Bitrise自动构建

如果在本地环境无法构建，可以使用Bitrise CI/CD服务自动构建APK：

1. **在Bitrise上创建应用**：
   - 登录 https://www.bitrise.io
   - 添加新应用
   - 选择您的代码仓库

2. **配置构建环境**：
   - 在Bitrise控制台中配置构建工作流
   - 确保使用Android构建环境
   - 配置必要的环境变量

3. **使用脚本构建**：
   ```bash
   # 设置Bitrise访问令牌
   export BITRISE_ACCESS_TOKEN="your_token_here"
   
   # 运行自动构建脚本 (APP_SLUG已在脚本中配置)
   ./build_with_bitrise.sh
   ```

4. **构建参数**：
   - 脚本会自动压缩项目、上传到Bitrise
   - 触发构建并监控进度
   - 构建完成后自动下载APK到`apk/`目录

## 使用GitHub Actions构建

您也可以使用GitHub Actions进行构建：

1. **确保工作流已启用**：
   - 工作流文件位于 `.github/workflows/build_apk.yml`
   - 配置了适当的Android构建环境

2. **触发构建**：
   - 推送标签以触发构建: `git tag v3.2.1 && git push origin v3.2.1`
   - 或通过GitHub界面手动触发工作流

## 注意事项

由于当前在Termux环境中，完整构建需要在具有完整Android SDK的环境中进行。

使用远程构建服务时，请确保：
- 已在远程服务上正确配置了构建工作流
- 已设置必要的环境变量（如签名密钥）
- 构建配置与本项目中的gradle文件匹配
- 项目已包含所有必要的黑白UI修改