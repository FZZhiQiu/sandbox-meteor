# 使用Bitrise构建Sandbox Radar APK

## 第一步：在Bitrise上创建应用

1. 访问 https://www.bitrise.io 并登录
2. 点击 "Add new app"
3. 选择您的代码仓库（如果项目在GitHub/GitLab等上）
4. 或者选择 "Manually register a project" 如果项目在本地

## 第二步：配置构建环境

1. 在Bitrise控制台中设置构建工作流
2. 确保选择Android构建环境
3. 在App Settings > Secrets中添加以下环境变量：
   - `KEYSTORE_PWD`: 您的密钥库密码
   - `KEY_PWD`: 您的密钥密码
   - (如果需要) 其他构建所需的密钥

## 第三步：获取访问令牌和应用slug

1. **获取访问令牌**：
   - 访问 https://www.bitrise.io/me/profile
   - 点击 "User settings"
   - 复制 "Personal Access Tokens"

2. **获取应用slug**：
   - 在Bitrise应用页面URL中找到
   - 格式为: https://www.bitrise.io/app/your-app-slug

## 第四步：运行构建脚本

```bash
# 在android-apk目录中设置环境变量
export BITRISE_ACCESS_TOKEN="your_access_token_here"
export APP_SLUG="your_app_slug_here"

# 运行构建脚本
./build_with_bitrise.sh
```

## 注意事项

- 确保您的Bitrise工作流配置了正确的构建步骤
- 构建时间取决于项目的复杂度，通常需要2-10分钟
- 如果构建失败，请检查Bitrise构建日志获取错误详情
- APK文件将在构建完成后自动下载到apk/目录