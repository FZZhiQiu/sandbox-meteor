#!/bin/bash

# 用于启动 iflow 并确保 MCP 服务器连接的脚本

echo "启动 iflow 并尝试使用 MCP 服务器..."
echo "此脚本将启动一个 iflow 会话，并在会话期间尝试使用 MCP 服务器"

# 创建一个临时的 iflow 会话，使用 -i 选项让它能交互式地处理 MCP 服务器
iflow -i "请帮我检查并连接所有可用的 MCP 服务器" &
IFLOW_PID=$!

# 等待几秒让 iflow 初始化
sleep 5

# 检查 MCP 服务器状态
echo "检查 MCP 服务器状态："
iflow mcp list

# 保持 iflow 会话运行一段时间，以便 MCP 服务器有机会连接
sleep 10

# 再次检查服务器状态
echo "再次检查 MCP 服务器状态："
iflow mcp list

# 关闭 iflow 会话
kill $IFLOW_PID 2>/dev/null

echo "完成 MCP 服务器连接尝试。"