# GitHub Codespaces 构建指南

## 在GitHub Codespaces中构建Sandbox Meteor APK

### 1. 访问GitHub Codespaces
1. 登录 GitHub (https://github.com)
2. 导航到您的仓库: https://github.com/FZZhiQiu/sandbox-meteor
3. 点击绿色的 "<> Code" 按钮
4. 选择 "Codespaces" 标签
5. 点击 "Create codespace on main" 按钮

### 2. Codespaces环境初始化
- Codespaces将自动创建开发环境
- 基于我们提供的 `.devcontainer.json` 配置
- 自动安装Android SDK、NDK、CMake等必要工具
- 自动克隆您的代码仓库

### 3. 等待环境配置完成
- 首次创建Codespaces可能需要几分钟
- 系统会自动安装和配置Android开发环境
- 您会在终端中看到进度提示

### 4. 验证环境配置
在Codespaces终端中运行以下命令验证环境：

```bash
# 检查Java版本
java -version

# 检查Android SDK工具
sdkmanager --version

# 检查Gradle
./gradlew --version
```

### 5. 构建APK
当环境配置完成后，运行以下命令构建APK：

```bash
# 确保在项目根目录
cd /workspaces/sandbox-meteor

# 构建Debug APK
./gradlew assembleDebug --no-daemon -x test -x lint

# 或构建Release APK
./gradlew assembleRelease --no-daemon -x test -x lint
```

### 6. 查找生成的APK
构建成功后，APK文件将位于：
- Debug版本: `app/build/outputs/apk/debug/app-debug.apk`
- Release版本: `app/build/outputs/apk/release/app-release.apk`

### 7. 下载APK文件
1. 在Codespaces的文件资源管理器中找到APK文件
2. 右键点击APK文件
3. 选择"Download"将文件下载到本地设备

### 8. 优势
- 无需在本地安装Android Studio
- 预配置的开发环境
- 与GitHub无缝集成
- 云端构建，不占用本地资源
- 自动配置所有构建依赖

### 9. 故障排除
如果遇到构建问题：
```bash
# 接受SDK许可证
yes | sdkmanager --licenses

# 清理构建缓存
./gradlew clean

# 重新尝试构建
./gradlew assembleDebug --stacktrace
```

构建完成后，您就可以下载APK并在Android设备上安装使用了。