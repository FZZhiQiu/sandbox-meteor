#!/bin/bash

# 重启 MCP 服务器并确保它们连接的脚本

echo "正在启动 iflow 会话并尝试连接 MCP 服务器..."

# 启动一个 iflow 会话，这可能会自动连接配置的服务器
iflow -p "连接 MCP 服务器" &
IFLOW_PID=$!

# 给 iflow 一些时间来初始化
sleep 3

# 检查服务器状态
echo "检查 MCP 服务器连接状态..."
iflow mcp list

# 关闭临时的 iflow 会话
kill $IFLOW_PID 2>/dev/null

echo "完成服务器连接尝试。"