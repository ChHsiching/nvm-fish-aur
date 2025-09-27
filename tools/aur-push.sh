#!/bin/bash
# AUR submission script - nvm-fish v1.0.0

set -e

echo "🚀 Starting nvm-fish submission to AUR..."
echo ""

# 检查是否在正确的目录
if [[ ! -f "PKGBUILD" ]] || [[ ! -f ".SRCINFO" ]]; then
    echo "❌ 错误：请在包含 PKGBUILD 和 .SRCINFO 的目录中运行此脚本"
    exit 1
fi

# 测试 SSH 连接
echo "🔑 测试 AUR SSH 连接..."
if ssh -T aur@aur.archlinux.org 2>&1 | grep -q "Interactive shell is disabled"; then
    echo "✅ SSH 连接正常"
else
    echo "❌ SSH 连接失败。请检查："
    echo "   1. SSH 公钥是否已添加到 AUR 账户"
    echo "   2. AUR 账户是否已激活"
    echo "   3. 网络连接是否正常"
    echo ""
    echo "   SSH 公钥位置: ~/.ssh/id_ed25519.pub"
    echo "   AUR 账户设置: https://aur.archlinux.org/account/"
    exit 1
fi

# 显示即将提交的内容
echo ""
echo "📦 即将提交的包："
echo "   名称: nvm-fish"
echo "   版本: 1.0.0-1"
echo "   维护者: ChHsich <hsichingchang@gmail.com>"
echo ""

# 确认提交
read -p "确认提交到 AUR？ [y/N]: " confirm
if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
    echo "❌ 取消提交"
    exit 0
fi

# 推送到 AUR
echo ""
echo "📤 推送到 AUR..."
git push -u origin main

echo ""
echo "🎉 成功提交到 AUR！"
echo ""
echo "📋 下一步："
echo "   1. 访问: https://aur.archlinux.org/packages/nvm-fish"
echo "   2. 验证包信息是否正确"
echo "   3. 测试用户安装: yay -S nvm-fish"
echo ""
echo "✅ nvm-fish 现已在 AUR 上可用！"