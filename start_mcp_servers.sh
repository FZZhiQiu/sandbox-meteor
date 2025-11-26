#!/bin/bash

# 启动所有 MCP 服务器的脚本

echo "正在启动 MCP 服务器..."

# 启动代码运行服务器
echo "启动 mcp-server-code-runner..."
npx -y @iflow-mcp/mcp-server-code-runner > /dev/null 2>&1 &

# 启动数据分析服务器
echo "启动 fastmcp-data-analysis-server..."
uvx --from iflow-mcp_fastmcp-data-analysis-server fastmcp-data-analysis-server > /dev/null 2>&1 &

# 启动文本工具包
echo "启动 text-toolkit..."
npx -y @iflow-mcp/text-toolkit > /dev/null 2>&1 &

# 启动 Lighthouse 服务器
echo "启动 lighthouse-mcp..."
npx -y @iflow-mcp/lighthouse-mcp > /dev/null 2>&1 &

# 启动 OpenCV 服务器
echo "启动 opencv-mcp-server..."
uvx --from iflow-mcp_opencv-mcp-server opencv-mcp-server > /dev/null 2>&1 &

# 启动 Chrome DevTools 服务器
echo "启动 chrome-devtools..."
npx -y @iflow-mcp/chrome-devtools-mcp > /dev/null 2>&1 &

# 启动 HAL 服务器
echo "启动 hal..."
npx -y @iflow-mcp/hal-mcp > /dev/null 2>&1 &

# 启动 PowerPoint 服务器
echo "启动 office-powerpoint-mcp-server..."
uvx --from iflow-mcp_office-powerpoint-mcp-server ppt_mcp_server > /dev/null 2>&1 &

# 启动 JVM 服务器
echo "启动 jvm-mcp-server..."
uvx --from iflow-mcp_jvm-mcp-server jvm-mcp-server > /dev/null 2>&1 &

# 启动桌面命令服务器
echo "启动 desktop-commander..."
npx -y @iflow-mcp/desktop-commander > /dev/null 2>&1 &

# 启动 Python 执行服务器
echo "启动 python-execute-server..."
uvx --python 3.12.7 iflow-mcp_python-execute-server@latest --workspace-path .python > /dev/null 2>&1 &

# 启动显示服务器
echo "启动 mcp-show2user..."
uvx --python 3.12.7 iflow-mcp_show2user@latest > /dev/null 2>&1 &

# 启动内存系统服务器
echo "启动 mcp-memory-system..."
uvx --python 3.12.7 iflow-mcp_memory-system@latest --workspace-path .jy > /dev/null 2>&1 &

# 启动 Xunlei 服务器
echo "启动 xunlei-net..."
# Xunlei 是 SSE 服务器，需要配置 API 密钥

# 启动 Puppeteer 服务器
echo "启动 server-puppeteer..."
npx -y @iflow-mcp/server-puppeteer@0.6.2 > /dev/null 2>&1 &

# 启动二维码服务器
echo "启动 qrcode-mcp..."
npx -y @iflow-mcp/qrcode-mcp > /dev/null 2>&1 &

# 启动 Docker 服务器
echo "启动 docker-mcp..."
uvx --from iflow-mcp_docker-mcp docker-mcp > /dev/null 2>&1 &

# 启动文件系统服务器
echo "启动 filesystem..."
npx -y @iflow-mcp/server-filesystem@0.6.2 ./workspace > /dev/null 2>&1 &

# 启动 Bing-CN 服务器
echo "启动 bing-cn-mcp..."
npx -y @iflow-mcp/bing-cn-mcp > /dev/null 2>&1 &

# 启动数学工具服务器
echo "启动 math-tools..."
npx -y @iflow-mcp/math-tools > /dev/null 2>&1 &

# 启动 GitHub 服务器
echo "启动 github..."
npx -y @iflow-mcp/server-github@0.6.2 > /dev/null 2>&1 &

# 启动 Bilibili 服务器
echo "启动 bilibili-mcp-server..."
uvx --from iflow-mcp-bilibili-mcp-server bilibili > /dev/null 2>&1 &

# 启动 Minimax 服务器
echo "启动 minimax-mcp..."
uvx --from iflow-mcp_minimax-mcp minimax-mcp > /dev/null 2>&1 &

# 启动图表服务器
echo "启动 mcp-server-chart..."
npx -y @antv/mcp-server-chart > /dev/null 2>&1 &

# 启动 Markmap 服务器
echo "启动 markmap..."
npx -y @iflow-mcp/markmap-mcp-server@0.1.1 > /dev/null 2>&1 &

# 启动 Mermaid 服务器
echo "启动 mcp-mermaid..."
npx -y @iflow-mcp/mcp-mermaid@0.1.3 > /dev/null 2>&1 &

# 启动 Excel 服务器
echo "启动 excel..."
uvx excel-mcp-server > /dev/null 2>&1 &

# 启动音乐分析服务器
echo "启动 mcp-music-analysis..."
uvx --from iflow-mcp_mcp-music-analysis mcp-music-analysis > /dev/null 2>&1 &

# 启动 Whois 服务器
echo "启动 whois..."
npx -y @iflow-mcp/whois-mcp@1.0.1 > /dev/null 2>&1 &

echo "所有 MCP 服务器已启动（后台运行）！"
echo "现在您可以启动 iflow 并使用这些服务器。"