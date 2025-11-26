#!/bin/bash

echo "正在下载 Gemini CLI..."

# 从正确的 GitHub 仓库下载
GEMINI_URL="https://github.com/google-gemini/gemini-cli/releases/latest/download/gemini.js"

# 检查是否有 wget
if command -v wget &> /dev/null; then
    echo "使用 wget 下载..."
    wget -O gemini.js "$GEMINI_URL"
elif command -v curl &> /dev/null; then
    echo "使用 curl 下载..."
    curl -L -o gemini.js "$GEMINI_URL"
else
    echo "错误: 需要 wget 或 curl 来下载文件"
    echo "请手动下载 Gemini CLI 或安装 wget/curl"
    exit 1
fi

# 检查下载是否成功
if [ -f "gemini.js" ]; then
    echo "下载成功！"
    echo "文件大小: $(ls -lh gemini.js | awk '{print $5}')"
    
    # 检查是否有 Node.js
    if command -v node &> /dev/null; then
        echo "检测到 Node.js，版本: $(node --version)"
        
        # 创建 gemini 命令脚本
        cat > gemini << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
node "$SCRIPT_DIR/gemini.js" "$@"
EOF
        
        chmod +x gemini
        
        # 尝试移动到系统路径
        if command -v sudo &> /dev/null; then
            sudo mv gemini /usr/local/bin/
            sudo cp gemini.js /usr/local/bin/
            echo "Gemini CLI 已安装到 /usr/local/bin/"
        else
            # 如果没有 sudo，移动到用户本地路径
            mkdir -p ~/bin
            mv gemini ~/bin/
            cp gemini.js ~/bin/
            echo "Gemini CLI 已安装到 ~/bin/"
            echo "请将 ~/bin 添加到 PATH: export PATH=\$PATH:~/bin"
        fi
        
        # 验证安装
        if command -v gemini &> /dev/null; then
            echo "安装成功！测试命令："
            gemini --help
        else
            echo "安装完成，但需要手动设置 PATH"
            echo "当前目录下的 gemini 命令可以使用："
            echo "./gemini --help"
        fi
    else
        echo "警告: 未检测到 Node.js"
        echo "Gemini CLI 需要 Node.js 运行"
        echo "请安装 Node.js: pkg install nodejs"
        echo "或者使用以下命令直接运行:"
        echo "node gemini.js --help"
    fi
else
    echo "错误: 下载失败"
    echo "请检查网络连接或手动下载 Gemini CLI"
    exit 1
fi

echo "Gemini CLI 安装完成！"