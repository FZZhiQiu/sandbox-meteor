#!/bin/bash

# AI CLI 环境测试脚本
# 测试所有已安装的 AI 工具的可用性

echo "=== AI CLI 环境测试 ===" 
echo "测试时间: $(date)"
echo ""

# 设置 PATH
export PATH="/data/data/com.termux/files/home/happy/bin:$PATH"

echo "1. 测试工具可执行性:"
echo "   LLM CLI: $(command -v llm && echo '✓' || echo '✗')"
echo "   ShellGPT: $(command -v sgpt && echo '✓' || echo '✗')"  
echo "   AI CLI: $(command -v ai-cli && echo '✓' || echo '✗')"
echo ""

echo "2. 工具版本信息:"
llm --version 2>/dev/null || echo "   LLM CLI: 无法获取版本"
echo "   ShellGPT: 自定义版本"
ai-cli --help | head -1 2>/dev/null || echo "   AI CLI: 无法获取信息"
echo ""

echo "3. 配置文件检查:"
if [ -f "/data/data/com.termux/files/home/happy/.ai-cli/config.json" ]; then
    echo "   ✓ 配置文件存在"
    echo "   内容预览:"
    head -5 /data/data/com.termux/files/home/happy/.ai-cli/config.json | sed 's/^/     /'
else
    echo "   ✗ 配置文件不存在"
fi
echo ""

echo "4. 网络连接测试:"
echo "   测试网络连接..."
ping -c 1 google.com >/dev/null 2>&1 && echo "   ✓ 网络连接正常" || echo "   ✗ 网络连接异常"
echo ""

echo "5. API 连接测试 (需要网络):"
echo "   测试 Gemini API..."
timeout 10 llm "test" --provider gemini >/dev/null 2>&1 && echo "   ✓ Gemini API 连接正常" || echo "   ✗ Gemini API 连接失败"
echo "   测试 Groq API..."  
timeout 10 llm "test" --provider groq >/dev/null 2>&1 && echo "   ✓ Groq API 连接正常" || echo "   ✗ Groq API 连接失败"
echo ""

echo "6. 功能测试:"
echo "   ShellGPT 命令生成测试..."
sgpt -s "列出当前目录文件" --provider gemini >/dev/null 2>&1 && echo "   ✓ ShellGPT 功能正常" || echo "   ✗ ShellGPT 功能异常"
echo ""

echo "=== 测试完成 ==="
echo "如有网络连接问题，请检查网络设置或使用代理"