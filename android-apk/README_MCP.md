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
```
apk/sandbox-meteor-agent.apk
```

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