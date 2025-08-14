#!/bin/bash
echo "🧹 清理nvm-fish测试环境..."

# 1. 卸载包
if pacman -Q nvm-fish &>/dev/null; then
    echo "卸载nvm-fish包..."
    sudo pacman -R nvm-fish --noconfirm
fi

# 2. 清理用户配置文件
if test -f ~/.config/fish/config.fish; then
    echo "从Fish配置中移除nvm-fish集成..."
    sed -i '/# nvm-fish integration/d' ~/.config/fish/config.fish
    sed -i '/load_nvm/d' ~/.config/fish/config.fish
    # 移除空行
    sed -i '/^$/N;/^\n$/d' ~/.config/fish/config.fish
fi

# 3. 移除标记文件
if test -f ~/.config/nvm-fish-setup-done; then
    echo "移除设置标记文件..."
    rm -f ~/.config/nvm-fish-setup-done
fi

# 4. 检查bass状态（不自动删除，因为用户可能在其他地方使用）
if fish -c 'command -v bass' &>/dev/null; then
    echo "⚠️  bass仍然存在，如需删除请手动执行："
    echo "   fish -c 'fisher remove edc/bass'  # 如果是通过fisher安装的"
    echo "   fish -c 'omf remove bass'         # 如果是通过OMF安装的"
fi

echo "✅ 清理完成！"
