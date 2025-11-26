#!/bin/bash

# iFlow 和 MCP 服务器启动脚本
# 使用方法：运行此脚本后，iFlow 将启动并根据需要连接 MCP 服务器

echo "==========================================="
echo "启动 iFlow CLI 及 MCP 服务器连接系统"
echo "==========================================="
echo ""
echo "说明："
echo "- MCP 服务器会在需要时自动连接"
echo "- 无需预先启动所有服务器"
echo "- 在使用相应功能时，iFlow 会自动连接所需服务器"
echo ""
echo "启动 iFlow CLI..."

# 启动 iFlow
iflow