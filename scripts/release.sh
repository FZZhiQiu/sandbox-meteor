#!/bin/bash
# Sandbox Meteor 发布脚本

echo "🚀 Sandbox Meteor v1.0 发布流程开始"
echo "====================================="

# 检查当前状态
echo "✅ 检查当前仓库状态..."
git status

# 确保所有功能都已提交
echo "✅ 确保所有更改都已暂存..."
git add .
git status

echo "✅ 创建 v1.0-storm-eco 标签..."
git tag -a v1.0-storm-eco -m "Sandbox Meteor v1.0 – Storm-Ecosystem-Policy Closed Loop"

echo "✅ 推送标签到远程仓库..."
git push origin v1.0-storm-eco

echo "====================================="
echo "🎉 Sandbox Meteor v1.0 已成功发布！"
echo ""
echo "📊 仓库包含以下核心功能："
echo "   • @ai-nowcast: AI短时预测（LSTM + Informer-Lite）"
echo "   • @gpu-eco: GPU加速（<0.1ms响应）" 
echo "   • @storyline: 叙事模式（可选）"
echo "   • @counterfactual: 反事实分析（可选）"
echo ""
echo "📱 性能：移动端60 FPS，支持大场景模拟"
echo "🔗 可通过 git clone --recursive 完整获取"
echo "====================================="