# MCP Build System for Sandbox Meteor APK

## 概述
Sandbox Meteor 是一款高级3D天气模拟应用，支持60 FPS渲染，专注于实时气象数据处理与渲染。该应用基于Sandbox Radar技术，为用户提供沉浸式气象模拟体验。

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
- **版本号**: 321000 (v3.2.1.0)
- **版本名**: "3.2.0-60fps"
- **最低SDK**: 26 (Android 8.0+)
- **目标SDK**: 34 (Android 14)
- **NDK版本**: 25.2.9519653
- **CMake版本**: 3.22.1
- **架构**: arm64-v8a (仅64位，优化性能)
- **60 FPS**: 已启用解耦模拟架构
- **构建命令**: ./gradlew assembleRelease
- **产物路径**: app/build/outputs/apk/release/app-release.apk

## 输出文件

构建完成后，APK将保存在：
```
apk/sandbox-meteor-<version>.apk
```

## 构建特性

### 60 FPS优化
- 模拟步长: 3秒 (保持物理精度)
- 渲染帧率: 60 FPS (视觉流畅)
- 双时钟架构: 模拟与渲染线程解耦
- 插值系统: 场数据、Agent位姿、音频参数平滑插值

### 原生C++库
- **主库**: `sandbox_radar` (通过JNI调用)
- **主要模块**: 核心模拟引擎、插值系统
- **特殊模块**: 辐射模块、火山模块
- **编译选项**: 启用 `-O3` 优化和 `-ffast-math`

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
4. 确认NDK和CMake版本与项目要求匹配

### 网络问题
如果遇到网络超时：
1. 检查网络连接
2. 重新运行脚本（构建会从断点继续）

## 安全注意事项

1. 从不将密钥硬编码在代码中
2. 使用GitHub Secrets存储敏感信息
3. 定期轮换密钥
4. 限制Secrets的访问权限
5. 确保签名密钥的安全存储和备份

## 项目关系

此构建系统是 Happy Coder 生态系统的一部分，与主项目结构关系如下：
- `happy/sandbox-meteor`: Android原生高性能气象模拟应用 (当前项目)
- `happy/sandbox-radar`: C++核心库，提供模拟引擎
- `happy/sources`: React Native主应用，提供UI和业务逻辑