#!/bin/bash
# 设置 GitHub 仓库密钥的脚本

echo "设置 GitHub Actions 签名密钥"
echo "==========================="

# 检查是否安装了 gh CLI
if ! command -v gh &> /dev/null; then
    echo "错误: 未找到 GitHub CLI (gh)"
    echo "请先安装: pkg install gh"
    echo "或者从 https://cli.github.com/ 下载"
    exit 1
fi

# 检查是否已认证
if ! gh auth status &> /dev/null; then
    echo "错误: 未认证到 GitHub"
    echo "请先运行: gh auth login"
    exit 1
fi

echo "开始设置密钥..."
echo

# 提示用户输入密钥信息
read -p "请输入密钥库密码: " -s STORE_PASS
echo
read -p "请输入密钥别名 (默认: sandbox-meteor): " KEY_ALIAS
KEY_ALIAS=${KEY_ALIAS:-sandbox-meteor}
read -p "请输入密钥密码: " -s KEY_PASS
echo

# 设置密钥
echo "正在设置密钥..."
gh secret set RELEASE_STORE_PASSWORD -b"$STORE_PASS"
gh secret set RELEASE_KEY_ALIAS -b"$KEY_ALIAS"
gh secret set RELEASE_KEY_PASSWORD -b"$KEY_PASS"

# 对密钥库进行base64编码并设置
if [ -f "android-apk/release.keystore" ]; then
    echo "正在设置密钥库..."
    KEYSTORE_BASE64=$(base64 -w 0 android-apk/release.keystore)
    gh secret set KEYSTORE -b"$KEYSTORE_BASE64"
    echo "密钥库已设置"
else
    echo "警告: 未找到密钥库 android-apk/release.keystore"
    echo "请确保已生成密钥库，然后重新运行此脚本"
fi

echo
echo "密钥设置完成！"
echo "现在可以推送代码并打标签来触发构建了："
echo "  git add .github/workflows/release.yml"
echo "  git commit -m \"ci: add signed release workflow\""
echo "  git push origin main"
echo "  git tag v1.0"
echo "  git push origin v1.0"
