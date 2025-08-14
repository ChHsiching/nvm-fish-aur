# nvm-fish

[![AUR version](https://img.shields.io/aur/version/nvm-fish?logo=arch-linux&logoColor=white)](https://aur.archlinux.org/packages/nvm-fish)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Fish shell integration for Node Version Manager (nvm) on Arch Linux.

## 概述

这个包为 Fish shell 提供了 nvm (Node Version Manager) 的集成支持。它允许你在 Fish shell 中使用 nvm 命令，并支持自动切换 Node.js 版本（通过 .nvmrc 文件）。

### ✨ 主要特性

- 🐟 **完全的 Fish shell 集成**：所有 nvm 命令在 Fish 中正常工作
- 🎯 **自动版本切换**：支持 .nvmrc 文件，进入目录自动切换 Node 版本
- 🔧 **智能依赖管理**：自动检测和安装 bass，无需手动配置
- 📦 **零污染安装**：不破坏用户现有的 Fish 环境配置
- ⚡ **即开即用**：安装后直接使用，无需任何配置

## 依赖

- `nvm` - Node Version Manager（Arch Linux extra 仓库）
- `fish` - Fish shell
- `bass` - Bash 到 Fish 的转换工具（自动管理，无需手动安装）

## 安装

### 从 AUR 安装

```bash
# 使用 yay 或其他 AUR helper
yay -S nvm-fish

# 或者手动构建
git clone https://aur.archlinux.org/nvm-fish.git
cd nvm-fish
makepkg -si
```

### 自动配置

安装完成后无需手动配置！第一次使用 nvm 命令时会自动：
- 检查和配置 bass 环境
- 设置 Fish shell 集成
- 添加自动版本切换功能

## 快速开始

安装完成后，直接在 Fish shell 中使用 nvm：

```fish
# 首次使用会自动配置环境（包括nvm和bass）
nvm --version

# 之后就可以正常使用所有nvm功能
nvm install node
nvm use node
```

**首次使用时自动处理：**
- ✅ nvm 环境检查和初始化
- ✅ bass 依赖检测和安装
- ✅ Fish shell 集成配置
- ✅ 自动版本切换功能启用

## 使用方法

安装完成后，直接使用 nvm 命令即可（无需任何配置步骤）：

```fish
# 检查 nvm 版本（首次使用会自动设置 bass 环境）
nvm --version

# 安装最新的 Node.js
nvm install node

# 安装特定版本
nvm install 18.17.0

# 切换版本
nvm use 18

# 设置默认版本
nvm alias default 18

# 查看已安装的版本
nvm ls

# 查看可安装的版本
nvm ls-remote

# 安装 LTS 版本
nvm install --lts
```

### 自动版本切换

创建 `.nvmrc` 文件来实现自动版本切换：

```bash
# 在项目根目录创建 .nvmrc
echo "18.17.0" > .nvmrc

# 当你进入这个目录时，nvm 会自动切换到指定版本
cd your-project
```

## 工作原理

这个包提供了四个主要 Fish 函数：

1. `nvm` - 使用 bass 调用原始的 bash nvm 命令（自动检测 bass 环境）
2. `nvm_find_nvmrc` - 查找当前或父目录中的 .nvmrc 文件
3. `load_nvm` - 当目录改变时自动加载适当的 Node.js 版本
4. `__nvm_setup_bass` 和相关辅助函数 - 智能 bass 环境管理

### Bass 自动管理

- **检测现有安装**：首先检查 bass 是否已安装
- **插件管理器支持**：自动检测并使用 fisher、Oh My Fish、fundle
- **本地回退**：如果没有插件管理器，从 GitHub 下载源码并本地配置
- **不破坏环境**：本地安装不会影响用户的全局 Fish 配置

## 许可证

MIT License - 与上游 nvm 项目保持一致。