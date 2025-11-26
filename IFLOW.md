# Happy Coder 项目说明

## 项目概述

Happy Coder 是一个移动和 Web 客户端，用于访问 Claude Code 和 Codex。该项目允许用户从任何地方使用 Claude Code 或 Codex，具有端到端加密功能，实现了远程控制和设备切换功能。用户可以在手机上查看 AI 编码代理的进度，接收推送通知，并在设备间无缝切换。

## 项目架构

- **CLI 工具**: `happy` 命令行界面，替代 `claude` 或 `codex` 使用
- **移动客户端**: React Native 应用程序，支持 iOS 和 Android
- **Web 应用**: 基于 Expo Router 的 Web 界面
- **后端服务器**: 用于加密同步的服务器组件
- **Tauri 桌面应用**: 使用 Tauri 框架的桌面应用程序

## 技术栈

- **前端**: React Native, Expo (版本 54.0.0)
- **UI 库**: React Navigation, Expo UI, @react-native-unistyles, @expo/vector-icons
- **状态管理**: Zustand, 自定义存储系统
- **加密**: libsodium-wrappers, 自定义加密系统
- **实时通信**: Socket.IO 客户端, LiveKit (用于实时功能)
- **分析**: PostHog 用于跟踪和分析
- **推送通知**: Expo Notifications
- **内购**: RevenueCat

## 核心功能

1. **会话管理**: 管理多个 Claude Code/Codex 会话
2. **实时同步**: 通过 WebSocket 与服务器实时同步数据
3. **加密系统**: 端到端加密保护用户数据
4. **推送通知**: 通知用户权限请求和错误
5. **设备切换**: 在手机和电脑之间无缝切换控制
6. **文件管理**: 与 AI 代理的文件操作交互
7. **语音助手**: 集成语音控制功能

## 项目结构

- `sources/app`: 应用主入口和布局
- `sources/auth`: 认证系统
- `sources/sync`: 同步逻辑和服务器通信
- `sources/components`: UI 组件
- `sources/encryption`: 加密相关功能
- `sources/realtime`: 实时通信功能
- `sources/-session`: 会话相关功能
- `sources/-zen`: 任务管理功能
- `src-tauri`: Tauri 桌面应用配置
- `sandbox-radar`: C++ 核心库，提供模拟引擎
- `sandbox-meteor`: Android原生高性能气象模拟应用，支持60 FPS渲染

## 构建和运行

### 开发环境设置

```bash
# 安装 CLI 工具
npm install -g happy-coder

# 安装项目依赖
yarn install

# 启动开发服务器
yarn start

# 启动本地服务器
yarn start:local-server

# 构建 Android 应用
yarn android

# 构建 iOS 应用
yarn ios

# 构建 Web 应用
yarn web
```

### 环境变量

- `EXPO_PUBLIC_HAPPY_SERVER_URL`: 服务器 URL 配置
- `PUBLIC_EXPO_DANGEROUSLY_LOG_TO_SERVER_FOR_AI_AUTO_DEBUGGING`: 用于 AI 调试的日志记录

## 开发约定

- 使用 TypeScript 进行类型安全开发
- 使用 ESLint 和 Prettier 进行代码格式化
- 遵循 React Native 最佳实践
- 所有数据传输使用端到端加密
- 使用 Expo 模块和插件系统
- 使用 Unistyles 进行样式管理

## 重要组件

- `Sync` 类: 负责所有服务器同步和数据管理的核心组件
- `AuthProvider`: 认证状态管理
- `SidebarNavigator`: 应用导航结构
- `RealtimeProvider`: 实时通信功能
- `Encryption` 类: 加密系统实现

## 安全特性

- 所有数据在传输和存储时都经过端到端加密
- 使用基于令牌的认证系统
- 客户端和服务器之间的所有通信都经过加密
- 无数据在未加密状态下离开设备

## 部署

- 使用 EAS (Expo Application Services) 进行构建和部署
- 支持 OTA (Over-The-Air) 更新
- 包含推送通知和内购功能