#!/bin/bash

# 清理 MCP 服务器配置的脚本
# 此脚本将帮助您管理 MCP 服务器，只保留可以在 Termux 中工作的服务器

echo "==========================================="
echo "MCP 服务器清理脚本"
echo "==========================================="
echo ""
echo "当前环境中，以下类型的服务器无法工作："
echo "- 使用 'uvx' 命令的服务器（因为 Termux 中没有 uvx）"
echo "- 需要特定 Python 环境的服务器"
echo ""
echo "可以工作的服务器类型："
echo "- 使用 'npx' 命令的 Node.js 服务器"
echo "- 内置工具"
echo ""

echo "要清理服务器配置，您需要手动编辑配置文件。"
echo "iFlow 通常从以下位置加载服务器配置："
echo "- 项目级: ./mcp-servers.json 或类似文件"
echo "- 用户级: ~/.iflow/ 目录下的配置文件"
echo "- 全局级: iFlow 内置的默认服务器"

echo ""
echo "推荐操作："
echo "1. 只使用 iFlow 的内置工具，它们已经可以正常工作"
echo "2. 如果需要特定功能，可以启动对应的 Node.js 服务器"
echo ""
echo "例如，要使用桌面命令功能，您可以运行："
echo "npx -y @iflow-mcp/desktop-commander &"
echo ""
echo "然后在 iFlow 中这个功能就可以使用了。"