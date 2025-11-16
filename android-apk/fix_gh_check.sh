#!/bin/bash

# 修复后的GitHub CLI检查脚本
# 当CI环境中没有gh时直接退出0，不打断流水线

if ! command -v gh &> /dev/null; then
  echo "⚠️  GitHub CLI 未安装，跳过 release 上传。"
  echo "APK 已生成：$(pwd)/app-release.apk"
  echo "请手动去 https://github.com/yourname/WeatherBox/releases 上传。"
  exit 0
fi

echo "GitHub CLI 已安装，继续执行后续操作..."